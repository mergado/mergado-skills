#!/usr/bin/env bash
# AI Visibility Audit — live technical probe
#
# Usage:
#   audit.sh <domain-or-url> [path-1] [path-2] ...
#
# If no extra paths are given, the script fetches sitemap.xml and picks a small
# automatic sample. This script only performs read-only GET requests against a
# small, bounded number of public URLs (never the whole catalog) and respects
# robots.txt Disallow rules when auto-sampling from the sitemap.
#
# Output is raw, deterministic findings — no interpretation. The skill (not
# this script) is responsible for judging what the findings mean.

set -uo pipefail

UA="Mozilla/5.0 (compatible; MergadoAIVisibilityAudit/1.0; +https://www.mergado.com)"
MAXTIME=15
# -L: many stores redirect bare-domain <-> www, or http -> https. We want the checks
# below to land on wherever the site actually lives, not bounce off a 30x every time.
CURL_OPTS=(--compressed -L -A "$UA" --max-time "$MAXTIME")
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [ "$#" -lt 1 ]; then
  echo "Usage: audit.sh <domain-or-url> [path-1] [path-2] ..." >&2
  exit 1
fi

RAW_INPUT="$1"; shift
EXTRA_PATHS=("$@")

# Normalize to https://host with no trailing slash
DOMAIN="$RAW_INPUT"
DOMAIN="${DOMAIN#http://}"
DOMAIN="${DOMAIN#https://}"
DOMAIN="${DOMAIN%%/*}"
BASE="https://${DOMAIN}"

hr() { printf '\n=== %s ===\n' "$1"; }

hr "TARGET"
echo "$BASE"

# ---------------------------------------------------------------------------
hr "HTTP HEADERS (homepage, redirect not followed here — shown as-is)"
curl -sI --compressed -A "$UA" --max-time "$MAXTIME" "$BASE/" || echo "(request failed)"

# ---------------------------------------------------------------------------
hr "EFFECTIVE HOST"
EFFECTIVE_URL=$(curl -s -o /dev/null -w '%{url_effective}' -L -A "$UA" --max-time "$MAXTIME" "$BASE/")
EFF_HOST=$(echo "$EFFECTIVE_URL" | sed -E 's#^(https?://[^/]+).*#\1#')
if [ -n "$EFF_HOST" ] && [ "$EFF_HOST" != "$BASE" ]; then
  echo "$BASE redirects to $EFF_HOST — using that as the base for every check below."
  BASE="$EFF_HOST"
else
  echo "$BASE (no redirect)"
fi

# ---------------------------------------------------------------------------
hr "ROBOTS.TXT"
ROBOTS_FILE="$TMP/robots.txt"
curl -s "${CURL_OPTS[@]}" "$BASE/robots.txt" -o "$ROBOTS_FILE"
cat "$ROBOTS_FILE" 2>/dev/null
echo ""
echo "--- AI bot rule check (explicit rule found = TRUE, else falls under default '*') ---"
for bot in GPTBot OAI-SearchBot ChatGPT-User OAI-AdsBot ClaudeBot Claude-SearchBot Claude-User \
           PerplexityBot Google-Extended Applebot-Extended Bytespider Amazonbot; do
  if grep -qi "$bot" "$ROBOTS_FILE" 2>/dev/null; then
    echo "  $bot: explicit rule present (inspect above for Allow/Disallow)"
  else
    echo "  $bot: no explicit rule (falls under default 'User-agent: *')"
  fi
done

# Collect Disallow rules so auto-sampling avoids them
DISALLOWED=$(grep -i '^Disallow:' "$ROBOTS_FILE" 2>/dev/null | sed 's/^[Dd]isallow:[[:space:]]*//' | tr -d '\r')

is_disallowed() {
  # robots-style PREFIX match against the URL path (not substring — "Disallow: /search"
  # must not exclude "/kategorie/search-foo"). Globs inside the rule (*, ?) stay active.
  local url="$1" path dis
  path="/${url#*://*/}"
  [ "$path" = "/$url" ] && path="/"   # URL had no path component at all
  while IFS= read -r dis; do
    [ -z "$dis" ] && continue
    case "$path" in $dis*) return 0 ;; esac
  done <<< "$DISALLOWED"
  return 1
}

# ---------------------------------------------------------------------------
hr "LLMS.TXT"
LLMS_FILE="$TMP/llms.txt"
LLMS_STATUS=$(curl -s "${CURL_OPTS[@]}" -o "$LLMS_FILE" -w "%{http_code}" "$BASE/llms.txt")
LLMS_SIZE=$(wc -c < "$LLMS_FILE" 2>/dev/null | tr -d ' ')
echo "status=$LLMS_STATUS size=${LLMS_SIZE:-0} bytes"
if [ "$LLMS_STATUS" = "200" ] && [ "${LLMS_SIZE:-0}" -eq 0 ]; then
  echo "WARNING: llms.txt exists but is EMPTY — likely an auto-generated platform stub, provides no value."
elif [ "$LLMS_STATUS" = "200" ]; then
  echo "--- first 20 lines ---"
  head -20 "$LLMS_FILE"
fi

# ---------------------------------------------------------------------------
hr "UCP / MCP DISCOVERY PROBES (heuristic, best-effort)"
for path in "/.well-known/ucp" "/api/mcp" "/mcp" "/.well-known/mcp.json"; do
  code=$(curl -s --compressed -A "$UA" -o /dev/null -w "%{http_code}" "$BASE$path" --max-time 10)
  echo "$path -> status=$code"
done
echo "Note: absence of these is normal/expected for most stores today (2026). Only Shopify"
echo "and a handful of UCP-integrated platforms expose these by default."

# ---------------------------------------------------------------------------
hr "SITEMAP DISCOVERY"
URLS_FILE="$TMP/urls.txt"
: > "$URLS_FILE"

# Prefer Sitemap: directives from robots.txt — WP/Shoptet installs commonly use
# sitemap_index.xml or another non-default name, so hardcoding /sitemap.xml misses them.
SITEMAP_SOURCES=$(grep -i '^sitemap:' "$ROBOTS_FILE" 2>/dev/null | sed 's/^[Ss]itemap:[[:space:]]*//' | tr -d '\r' | head -3)
if [ -z "$SITEMAP_SOURCES" ]; then
  SITEMAP_SOURCES="$BASE/sitemap.xml"
  echo "robots.txt lists no Sitemap: directive — falling back to $BASE/sitemap.xml"
else
  echo "sitemap source(s) from robots.txt:"
  echo "$SITEMAP_SOURCES"
fi

collect_sitemap() {
  # $1 = sitemap URL, $2 = recursion depth (index nesting followed one level deep)
  local sm_url="$1" depth="$2" f="$TMP/sm_${RANDOM}.xml" n=0 sub
  curl -s "${CURL_OPTS[@]}" "$sm_url" -o "$f" 2>/dev/null || return 0
  if grep -qE '<sitemapindex|<sitemap>' "$f" 2>/dev/null; then
    [ "$depth" -ge 1 ] && return 0
    echo "  $sm_url is a sitemap INDEX — following up to 4 sub-sitemaps"
    while IFS= read -r sub && [ "$n" -lt 4 ]; do
      [ -z "$sub" ] && continue
      collect_sitemap "$sub" 1
      n=$((n + 1))
    done < <(grep -oE '<loc>[^<]*</loc>' "$f" | sed -E 's/<\/?loc>//g')
  else
    grep -oE '<loc>[^<]*</loc>' "$f" 2>/dev/null | sed -E 's/<\/?loc>//g' >> "$URLS_FILE"
  fi
  return 0
}

while IFS= read -r sm; do
  [ -z "$sm" ] && continue
  collect_sitemap "$sm" 0
done <<< "$SITEMAP_SOURCES"

# Dedupe while preserving sitemap order (priority pages tend to come first)
awk '!seen[$0]++' "$URLS_FILE" > "$URLS_FILE.dedup" && mv "$URLS_FILE.dedup" "$URLS_FILE"
TOTAL_URLS=$(wc -l < "$URLS_FILE" 2>/dev/null | tr -d ' ')
echo "found ${TOTAL_URLS:-0} candidate URLs (robots Sitemap: directives + one level of index, deduped)"

# ---------------------------------------------------------------------------
hr "PAGE SAMPLE"

inspect_page() {
  local url="$1"
  local f="$TMP/page.html"
  local code
  code=$(curl -s "${CURL_OPTS[@]}" -o "$f" -w "%{http_code}" "$url")
  echo ""
  echo "--- $url [HTTP $code] ---"
  if [ "$code" != "200" ]; then
    echo "  (skipped content checks, non-200 response)"
    return
  fi
  local bytes
  bytes=$(wc -c < "$f" | tr -d ' ')
  echo "  size: ${bytes} bytes"

  local title desc
  title=$(grep -oE '<title>[^<]*</title>' "$f" | head -1 | sed -E 's/<\/?title>//g')
  desc=$(grep -oE '<meta[^>]*name="description"[^>]*content="[^"]*"' "$f" | head -1)
  echo "  title: ${title:-<none found>}"
  echo "  meta description: $([ -n "$desc" ] && echo present || echo MISSING)"

  local ldjson_types
  ldjson_types=$(grep -oE '"@type"[[:space:]]*:[[:space:]]*"[A-Za-z]+"' "$f" | sort -u | sed -E 's/.*"([A-Za-z]+)"$/\1/' | paste -sd, -)
  echo "  JSON-LD @type values found: ${ldjson_types:-none}"

  local microdata_types
  microdata_types=$(grep -oE 'itemtype="https?://schema\.org/[A-Za-z]+"' "$f" | sort -u | sed -E 's#.*schema\.org/([A-Za-z]+)"#\1#' | paste -sd, -)
  echo "  microdata itemtype values found: ${microdata_types:-none}"

  echo "  AggregateRating or Review present: $(grep -qiE 'AggregateRating|"Review"|itemtype="https?://schema\.org/Review"' "$f" && echo yes || echo no)"
  echo "  GTIN/MPN present: $(grep -qiE '\bgtin\b|\bmpn\b' "$f" && echo yes || echo no)"
  echo "  FAQPage / Q&A structure present: $(grep -qiE 'FAQPage|"Question"' "$f" && echo yes || echo no)"
}

inspect_page "$BASE/"

if [ "${#EXTRA_PATHS[@]}" -gt 0 ]; then
  for p in "${EXTRA_PATHS[@]}"; do
    case "$p" in
      http*) inspect_page "$p" ;;
      *) inspect_page "$BASE/${p#/}" ;;
    esac
  done
else
  echo ""
  echo "(no explicit sample paths given — auto-sampling up to 6 URLs from the sitemap:"
  echo " pass 1 prefers distinct site sections, pass 2 fills remaining slots so flat"
  echo " URL structures still yield a full sample; robots.txt Disallow rules respected)"
  SEGMENTS_SEEN="$TMP/segments_seen.txt"
  INSPECTED="$TMP/inspected_urls.txt"
  echo "root" > "$SEGMENTS_SEEN"  # homepage was already inspected above, don't repeat it
  printf '%s\n' "$BASE/" "$BASE" > "$INSPECTED"
  count=0
  # Pass 1: at most one URL per distinct first path segment, for diversity across
  # categories/sections rather than several pages from the same branch.
  while IFS= read -r u && [ "$count" -lt 6 ]; do
    [ -z "$u" ] && continue
    is_disallowed "$u" && continue
    seg=$(echo "$u" | sed -E 's#https?://[^/]+/##' | cut -d/ -f1)
    seg="${seg:-root}"
    if ! grep -Fxq "$seg" "$SEGMENTS_SEEN" 2>/dev/null; then
      echo "$seg" >> "$SEGMENTS_SEEN"
      echo "$u" >> "$INSPECTED"
      inspect_page "$u"
      count=$((count + 1))
    fi
  done < "$URLS_FILE"
  # Pass 2: flat stores (every product under one /shop/ prefix) produce few distinct
  # segments — fill the remaining slots with further unsampled URLs so the sample never
  # collapses to a single product page.
  if [ "$count" -lt 6 ]; then
    while IFS= read -r u && [ "$count" -lt 6 ]; do
      [ -z "$u" ] && continue
      is_disallowed "$u" && continue
      grep -Fxq "$u" "$INSPECTED" 2>/dev/null && continue
      echo "$u" >> "$INSPECTED"
      inspect_page "$u"
      count=$((count + 1))
    done < "$URLS_FILE"
  fi
fi

hr "DONE"
echo "Reminder: this is a bounded sample, not a full-catalog crawl. Extrapolate carefully."
