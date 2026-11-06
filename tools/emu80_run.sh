#!/bin/sh
# Basket Master Z80 ROM in Emu80 (Вектор-06Ц, platform vector.z80).
#   tools/emu80_run.sh              — rebuild if needed + launch --run
#   tools/emu80_run.sh --no-build   — launch existing build/v06/basket.rom
set -e
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
APP="${EMU80_APP:-/Users/boris/projects/emu80v4/Emu80qt-mcp.app}"
ROM="$ROOT/build/v06/basket.rom"
PORT="${EMU80_MCP_PORT:-19787}"

if [ "${1:-}" != "--no-build" ]; then
  python3 "$ROOT/tools/build_v06_rom.py"
fi
[ -f "$ROM" ] || { echo "missing $ROM" >&2; exit 1; }

pkill -f "Emu80qt.*vector" 2>/dev/null || true
pkill -f "Emu80qt-mcp" 2>/dev/null || true
sleep 0.3

export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-cocoa}"
export QT_PLUGIN_PATH="${QT_PLUGIN_PATH:-/opt/homebrew/share/qt/plugins}"
export EMU80_MCP_PORT="$PORT"

# Vector-native .rom (file[0] → mem[0100]) — штатный --run
open -n -a "$APP" --args --platform vector.z80 --run "$ROM"
echo "Emu80: --platform vector.z80 --run $ROM (MCP $PORT)"
echo "size $(wc -c < "$ROM") bytes (expect ≤65280, starts with DI)"
