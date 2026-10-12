#!/usr/bin/env bash
# Build a self-contained, installable PWA bundle from any results folder.
# Usage:
#   ./build.sh --src <results-dir> --out <deploy-dir> [--title "..."] [--subtitle "..."]
# Output: <deploy-dir>/ with index.html, manifest.json, sw.js, config.js, icons/, data/manifest.json
set -euo pipefail
SRC=""; OUT=""; TITLE="Results Viewer"; SUBTITLE="Backtest results bundle"
while [ $# -gt 0 ]; do
  case "$1" in
    --src) SRC="$2"; shift 2;;
    --out) OUT="$2"; shift 2;;
    --title) TITLE="$2"; shift 2;;
    --subtitle) SUBTITLE="$2"; shift 2;;
    *) echo "unknown arg $1"; exit 1;;
  esac
done
[ -z "$SRC" ] || [ -z "$OUT" ] && { echo "need --src and --out"; exit 1; }
HERE="$(cd "$(dirname "$0")" && pwd)"
rm -rf "$OUT"
mkdir -p "$OUT"
cp "$HERE/app/index.html" "$HERE/app/manifest.json" "$HERE/app/sw.js" "$HERE/app/config.js" "$OUT/"
cp -r "$HERE/app/icons" "$OUT/"
mkdir -p "$OUT/data"
# copy results, excluding any previous pwa bundle dirs
(cd "$SRC" && tar cf - --exclude='./pwa' .) | (cd "$OUT/data" && tar xf -)
python3 - "$OUT" "$TITLE" "$SUBTITLE" << 'PYEOF'
import json, os, sys, datetime
out, title, subtitle = sys.argv[1], sys.argv[2], sys.argv[3]
datadir = os.path.join(out, "data")
IMG = {".png",".jpg",".jpeg",".gif",".webp",".svg"}
TXT = {".md",".txt",".log",".csv",".json"}
files = []
for root, _, names in os.walk(datadir):
    for nm in sorted(names):
        p = os.path.join(root, nm)
        rel = os.path.relpath(p, out).replace(os.sep, "/")
        ext = os.path.splitext(nm)[1].lower()
        kind = "image" if ext in IMG else ("text" if ext in TXT else "other")
        files.append({"path": rel, "name": nm,
                      "dir": os.path.dirname(rel.replace("data/","",1)) or ".",
                      "size": os.path.getsize(p), "ext": ext, "kind": kind})
files.sort(key=lambda f: (f["dir"], f["name"]))
total = sum(f["size"] for f in files)
with open(os.path.join(datadir, "manifest.json"), "w") as fh:
    json.dump({"title": title, "subtitle": subtitle,
               "generated": datetime.datetime.now().isoformat(timespec="seconds"),
               "count": len(files), "bytes": total, "files": files}, fh, indent=1)
cfg = os.path.join(out, "config.js")
s = open(cfg).read().replace("__TITLE__", title).replace("__SUBTITLE__", subtitle)
open(cfg, "w").write(s)
mf = os.path.join(out, "manifest.json")
m = json.load(open(mf)); m["name"] = title; m["short_name"] = title[:24] or "Results"
json.dump(m, open(mf, "w"), indent=2)
print(f"bundled {len(files)} files ({total/1048576:.1f} MB) -> {out}")
PYEOF
