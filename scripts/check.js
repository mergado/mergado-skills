#!/usr/bin/env node
// Content check for the mergado-skills marketplace repository.
// `claude plugin validate` only checks manifest syntax and schema; this covers what it does not:
// versions in sync, names, descriptions, links, line endings, dangling skill references.
//
// Usage:  node scripts/check.js [path-to-repo-root]      (defaults to the current directory)
// Run `git add -A` first: line endings are read from the git index, not from the working tree.
// Set GIT=<full path to git> when git is not on PATH.
// Exit code: 1 when any ERROR was found, 0 otherwise. WARN lines never fail the run.
const fs = require("fs");
const path = require("path");

const root = path.resolve(process.argv[2] || ".");
const errors = [];
const warns = [];
const err = (m) => errors.push(m);
const warn = (m) => warns.push(m);
const exists = (...p) => fs.existsSync(path.join(root, ...p));
const read = (...p) => fs.readFileSync(path.join(root, ...p), "utf8");
const json = (...p) => {
  try { const s = read(...p); return JSON.parse(s.charCodeAt(0) === 65279 ? s.slice(1) : s); }
  catch (e) { err(`${p.join("/")}: invalid JSON (${e.message})`); return null; }
};
const walk = (dir) => fs.readdirSync(dir, { withFileTypes: true }).flatMap((d) => {
  const f = path.join(dir, d.name);
  return d.isDirectory() ? [f, ...walk(f)] : [f];
});
const rel = (f) => path.relative(root, f).split(path.sep).join("/");

const market = json(".claude-plugin", "marketplace.json");
const c7 = json("context7.json");
const readme = exists("README.md") ? read("README.md") : "";
const entries = (market && market.plugins) || [];
const dirs = exists("plugins") ? fs.readdirSync(path.join(root, "plugins"), { withFileTypes: true }).filter((d) => d.isDirectory()).map((d) => d.name) : [];
const names = new Set(entries.map((e) => e.name));

for (const d of dirs) if (!names.has(d)) err(`plugins/${d} is not listed in marketplace.json`);
for (const e of entries) if (!dirs.includes(e.name)) err(`marketplace.json lists ${e.name} but plugins/${e.name} does not exist`);

for (const e of entries) {
  const n = e.name;
  const src = (e.source || "").replace(/^\.\//, "");
  if (src !== `plugins/${n}`) warn(`${n}: source is "${e.source}", expected "./plugins/${n}"`);
  const pj = exists("plugins", n, ".claude-plugin", "plugin.json") ? json("plugins", n, ".claude-plugin", "plugin.json") : (err(`${n}: plugin.json is missing`), null);
  if (pj) {
    if (pj.name !== n) err(`${n}: plugin.json name is "${pj.name}"`);
    if (pj.version !== e.version) err(`${n}: version in plugin.json (${pj.version}) differs from marketplace.json (${e.version})`);
  }
  const row = readme.match(new RegExp("\\*\\*" + n.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "\\*\\* v(\\d+\\.\\d+\\.\\d+)"));
  if (!row) err(`${n}: no row in the README plugin table`);
  else if (row[1] !== e.version) err(`${n}: version in README (${row[1]}) differs from marketplace.json (${e.version})`);
  const folder = `plugins/${n}/skills/${n}`;
  if (c7 && !(c7.folders || []).includes(folder)) err(`${n}: ${folder} is missing from context7.json folders`);
  const skillFile = path.join(root, folder, "SKILL.md");
  if (!fs.existsSync(skillFile)) { err(`${n}: ${folder}/SKILL.md is missing`); continue; }

  const text = fs.readFileSync(skillFile, "utf8");
  const lines = text.replace(/\r\n/g, "\n").split("\n");
  if (lines[0] !== "---") { err(`${n}: SKILL.md does not start with frontmatter`); continue; }
  const end = lines.indexOf("---", 1);
  const fm = lines.slice(1, end);
  const nameLine = fm.find((l) => /^name:/.test(l));
  const fmName = nameLine ? nameLine.replace(/^name:\s*/, "").trim().replace(/^["']|["']$/g, "") : "";
  if (fmName !== n) err(`${n}: frontmatter name is "${fmName}"`);
  if (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(fmName)) err(`${n}: name is not kebab-case (lowercase letters, digits, hyphens)`);
  // Outside Claude Code (claude.ai and Claude Desktop uploads, the Skills API) only these keys are allowed; others are a hard error.
  const portable = new Set(["name", "description", "license", "compatibility", "metadata", "allowed-tools"]);
  for (const l of fm) { const k = (l.match(/^([A-Za-z_][\w-]*):/) || [])[1]; if (k && !portable.has(k)) warn(`${n}: frontmatter key "${k}" only works in Claude Code, uploading the skill to claude.ai or Claude Desktop fails on it`); }
  const di = fm.findIndex((l) => /^description:/.test(l));
  if (di < 0) err(`${n}: description is missing`);
  else {
    let desc = fm[di].replace(/^description:\s*/, "").replace(/^[>|][+-]?\s*$/, "");
    for (let i = di + 1; i < fm.length && /^\s/.test(fm[i]); i++) desc += " " + fm[i].trim();
    desc = desc.replace(/\s+/g, " ").trim();
    // Limits of the Agent Skills format (Anthropic skill authoring best practices): description at most 1024
    // characters and no XML tags. Claude Code itself only shows the first 1536 characters in its skill listing.
    if (desc.length > 1024) err(`${n}: description is ${desc.length} characters, the Agent Skills limit is 1024`);
    if (/[<>]/.test(desc)) err(`${n}: description contains < or > (counts as an XML tag, upload to Claude Desktop is rejected)`);
    if (desc.length < 80) warn(`${n}: description is only ${desc.length} characters, the skill will trigger less reliably`);
  }
  if (Buffer.byteLength(text) > 20000) warn(`${n}: SKILL.md is ${Math.round(Buffer.byteLength(text) / 1024)} KB and is loaded in full on every use, consider moving detail to references/`);
  if (lines.length > 500) warn(`${n}: SKILL.md has ${lines.length} lines (500 recommended)`);

  const skillDir = path.join(root, folder);
  for (const f of walk(skillDir).filter((x) => x.endsWith(".md"))) {
    const t = fs.readFileSync(f, "utf8");
    const refs = new Set();
    for (const m of t.matchAll(/\]\(([^)\s#]+)(?:#[^)]*)?\)/g)) if (!/^(https?:|mailto:|\/)/.test(m[1])) refs.add(m[1]);
    for (const m of t.matchAll(/`((?:references|reference|scripts|examples|assets)\/[A-Za-z0-9._\/-]+)`/g)) refs.add(m[1]);
    for (const r of refs) {
      if (/[<>*{}]/.test(r)) continue;
      if (!fs.existsSync(path.resolve(skillDir, r)) && !fs.existsSync(path.resolve(path.dirname(f), r))) err(`${rel(f)}: link to a file that does not exist: ${r}`);
    }
  }
  for (const m of text.matchAll(/`(mergado-[a-z0-9-]+)`/g)) {
    if (!names.has(m[1]) && !exists("plugins", n, "skills", n, "references", m[1])) warn(`${n}: the text mentions \`${m[1]}\` but no such plugin exists (reference to a skill that does not exist, or a product name?)`);
  }
}

// Line endings: on Windows with core.autocrlf=true the working tree has CRLF while the commit stores LF,
// so the working tree is the wrong place to look. Ask git what is in the index (what will be committed).
const { spawnSync } = require("child_process");
const git = spawnSync(process.env.GIT || "git", ["ls-files", "--eol"], { cwd: root, encoding: "utf8" });
const inGit = !git.error && git.status === 0;
if (inGit) {
  for (const l of git.stdout.split("\n")) {
    const m = l.match(/^i\/(\S+)\s+w\/\S+\s+attr\/\S*\s+(.+)$/);
    if (m && (m[1] === "crlf" || m[1] === "mixed") && /^(plugins\/|\.claude-plugin\/|scripts\/|README\.md|context7\.json)/.test(m[2]) && /\.(md|json|py|sh|js|xml|rng|txt)$/.test(m[2])) err(`${m[2]}: line endings in the git index are ${m[1].toUpperCase()}, the repository uses LF`);
  }
  const st = spawnSync(process.env.GIT || "git", ["status", "--porcelain", "--", "plugins"], { cwd: root, encoding: "utf8" });
  if (st.stdout && /^\?\?/m.test(st.stdout)) warn("untracked files under plugins/ are not checked for line endings, run `git add -A` first");
} else {
  warn("git is not available or this is not a git clone, line endings cannot be checked (set GIT=<path to git>)");
}

if (exists("plugins")) {
  for (const f of walk(path.join(root, "plugins"))) {
    const r = rel(f);
    const base = path.basename(f);
    if (/(^|\/)__MACOSX(\/|$)|\.DS_Store$|Thumbs\.db$/.test(r)) err(`${r}: leftover from an archive or the file manager`);
    if (fs.statSync(f).isDirectory()) { if (base === "reference") err(`${r}: directory is named "reference", the convention is "references"`); continue; }
    if (/\.(md|json|py|sh|js|xml|rng|txt)$/.test(base)) {
      const buf = fs.readFileSync(f);
      if (buf.length >= 3 && buf[0] === 0xef && buf[1] === 0xbb && buf[2] === 0xbf) err(`${r}: contains a BOM`);
    }
  }
}

for (const w of warns) console.log("WARN ", w);
for (const e of errors) console.log("ERROR", e);
console.log(errors.length ? `ERROR ${errors.length} error(s), ${warns.length} warning(s)` : `OK    no errors, ${warns.length} warning(s), ${entries.length} plugins checked`);
process.exit(errors.length ? 1 : 0);
