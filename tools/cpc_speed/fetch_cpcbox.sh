#!/bin/sh
# Fetch CPCBox (amstrad.retrogamecoders.com) into build/cpcbox and wire in
# cdt.js (CDT/TZX tape support). CPCBox itself is third-party and not in git.
set -e
ROOT="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
DST="$ROOT/build/cpcbox"
URL="https://amstrad.retrogamecoders.com"
mkdir -p "$DST/libs" "$DST/css"
for f in index.html cpcbox.js cpcbox.sysroms.js autostart-config.js favicon.ico \
         libs/jquery-1.8.3.min.js libs/jquerytools.rangeinput.js libs/inflate.js \
         css/cpcbox.style.css css/volume-slider.css; do
  [ -s "$DST/$f" ] || curl -sfL -A "Mozilla/5.0" "$URL/$f" -o "$DST/$f"
done
cp "$ROOT/tools/cpc_speed/cdt.js" "$DST/cdt.js"
# site autostart reboots the machine 2 s after load - off
sed -i '' 's/var AUTO_START_ENABLED = true;/var AUTO_START_ENABLED = false;/' "$DST/autostart-config.js"
grep -q 'src="cdt.js"' "$DST/index.html" || \
  sed -i '' 's#\(<script type="text/javascript" src="cpcbox.js[^"]*"></script>\)#\1<script type="text/javascript" src="cdt.js"></script>#' "$DST/index.html"
grep -q 'src="cdt.js"' "$DST/index.html" && grep -q 'AUTO_START_ENABLED = false' "$DST/autostart-config.js"
echo "CPCBox in $DST"
