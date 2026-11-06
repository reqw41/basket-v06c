#!/bin/sh
# Launch the CPC original (tape) in windowed MAME.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CASS="$ROOT/ref/cpc/Fernando Martin Basket Master.cdt"
ROMS="${CPC_ROMPATH:-$HOME/projects/knightlore-research/cpc/roms}"
exec mame cpc6128 \
  -rompath "$ROMS" \
  -cass "$CASS" \
  -script "$ROOT/tools/cpc_boot.lua" \
  -skip_gameinfo \
  -window \
  "$@"
