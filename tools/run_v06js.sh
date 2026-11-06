#!/bin/bash
# Run Basket Master in vector06js (Z80 mode)
set -e
ROM="${1:-build/v06/basket.rom}"
V06JS="${HOME}/projects/vector06js"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
[[ "$ROM" = /* ]] || ROM="$ROOT/$ROM"

if [ ! -f "$ROM" ]; then
  echo "ROM not found: $ROM — run: python3 tools/build_v06_rom.py"
  exit 1
fi
if [ ! -d "$V06JS" ]; then
  echo "vector06js not found at $V06JS"
  exit 1
fi

cp "$ROM" "$V06JS/basket.rom"
# Keep a working Z80 page next to the ROM
if [ -f "$ROOT/tools/basket_page.html" ]; then
  cp "$ROOT/tools/basket_page.html" "$V06JS/basket.html"
fi

echo "ROM → $V06JS/basket.rom ($(wc -c < "$V06JS/basket.rom") bytes)"
echo ""
echo "  cd $V06JS && python3 -m http.server 8080"
echo "  open http://localhost:8080/basket.html?rom=basket.rom"
echo ""
echo "Controls: arrows / space. Click canvas for focus+audio."
echo "Smoke: node tools/smoke_v06js.js build/v06/basket.rom 300"
