#!/usr/bin/env python3
"""Validate a Shoptet feed against the bundled RNG schemas.

Usage:
    python validate.py <feed.xml> [--schema complete|supplier|/path/to.rng]

Exit codes: 0 = valid, 1 = invalid (errors printed), 2 = could not validate.

Prefers Python lxml (works everywhere, no extra binaries). Falls back to
xmllint if lxml is unavailable. The three RNG files must stay together in
references/ — their includes are relative.
"""
import argparse
import shutil
import subprocess
import sys
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
REFERENCE = HERE.parent / "reference"
SCHEMAS = {
    "complete": REFERENCE / "products-complete-v10.rng",
    "supplier": REFERENCE / "products-supplier-v10.rng",
}
# Shoptet changes these silently; bundled copies are a snapshot (see SKILL.md).
SCHEMA_URLS = {
    "products-complete-v10.rng": "https://www.shoptet.cz/export/schema/products-complete-v10.rng",
    "products-supplier-v10.rng": "https://www.shoptet.cz/export/schema/products-supplier-v10.rng",
    "products-datatype-v10.rng": "https://www.shoptet.cz/export/schema/products-datatype-v10.rng",
}


def check_schema(update: bool = False) -> int:
    """Compare bundled RNG snapshots with the live schemas on shoptet.cz.

    Exit codes: 0 = all identical, 3 = at least one differs (details printed),
    2 = download failed. With update=True, differing files are overwritten
    (previous copy kept as .bak) so future validations use the live schema.
    """
    changed = 0
    for name, url in SCHEMA_URLS.items():
        local = REFERENCE / name
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "shoptet-feed-doctor/1.0"})
            with urllib.request.urlopen(req, timeout=30) as resp:
                live = resp.read()
        except Exception as e:
            print(f"DOWNLOAD FAILED: {url} ({e})", file=sys.stderr)
            return 2
        bundled = local.read_bytes() if local.exists() else b""
        if live == bundled:
            print(f"UNCHANGED: {name} ({len(live)} B)")
        else:
            changed += 1
            print(f"CHANGED:   {name} (bundled {len(bundled)} B -> live {len(live)} B)")
            if update:
                if local.exists():
                    local.replace(local.with_suffix(".rng.bak"))
                local.write_bytes(live)
                print(f"           updated (previous copy: {name}.bak)")
    if changed and not update:
        print("\nLive schema differs from the bundled snapshot. Re-run with --update-schema"
              " to refresh, then re-validate the feed.")
    return 3 if changed and not update else 0


def validate_lxml(schema: Path, feed: Path) -> int:
    from lxml import etree

    try:
        doc = etree.parse(str(feed))
    except etree.XMLSyntaxError as e:
        print(f"INVALID (not well-formed XML): {feed}")
        print(f"  {e}")
        return 1

    rng = etree.RelaxNG(etree.parse(str(schema)))
    if rng.validate(doc):
        print(f"VALID: {feed} conforms to {schema.name}")
        return 0

    print(f"INVALID: {feed} fails {schema.name} — {len(rng.error_log)} error(s):")
    for err in rng.error_log:
        print(f"  line {err.line}: {err.message}")
    print(
        "\n" +
        "Interpret messages via references/error-message-decoder.md, section A2"
        " (lxml/libxml2 dialect) — 'Extra element … in interleave' with line 0:"
        " the culprit's line number is in the accompanying 'SHOPITEM failed to validate'"
        " message; for variant errors the real culprit is usually one level UP"
        " ('viník je výš')."
    )
    return 1


def validate_xmllint(schema: Path, feed: Path) -> int:
    proc = subprocess.run(
        ["xmllint", "--noout", "--relaxng", str(schema), str(feed)],
        capture_output=True,
        text=True,
    )
    out = (proc.stdout + proc.stderr).strip()
    if out:
        print(out)
    return 0 if proc.returncode == 0 else 1


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("feed", type=Path, nargs="?")
    ap.add_argument("--schema", default="complete")
    ap.add_argument("--check-schema", action="store_true",
                    help="compare bundled RNG snapshots with live schemas on shoptet.cz")
    ap.add_argument("--update-schema", action="store_true",
                    help="like --check-schema, but overwrite bundled copies with the live ones")
    args = ap.parse_args()

    if args.check_schema or args.update_schema:
        return check_schema(update=args.update_schema)
    if args.feed is None:
        ap.error("feed path is required unless --check-schema/--update-schema is used")

    schema = SCHEMAS.get(args.schema, Path(args.schema))
    if not schema.exists():
        print(f"Schema not found: {schema}", file=sys.stderr)
        return 2
    if not args.feed.exists():
        print(f"Feed not found: {args.feed}", file=sys.stderr)
        return 2

    try:
        return validate_lxml(schema, args.feed)
    except ImportError:
        pass

    if shutil.which("xmllint"):
        return validate_xmllint(schema, args.feed)

    print(
        "Neither Python lxml nor xmllint is available.\n"
        "Install one of them:  pip install lxml   (recommended, cross-platform)\n"
        "or use the web validator: https://www.shoptet.cz/xml-validace/",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    sys.exit(main())
