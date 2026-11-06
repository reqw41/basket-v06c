#!/bin/sh
# Launch Executive cartridge ROM in openMSX (no RUN"CAS:").
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ROM=${1:-"$ROOT/ref/msx/executive/executive.rom"}
BIN=${OPENMSX_BIN:-/opt/homebrew/Cellar/openmsx/21.0_2/openMSX.app/Contents/MacOS/openmsx}
MACHINE=${OPENMSX_MACHINE:-SpiritsMSX}

if [ ! -f "$ROM" ]; then
  echo "missing ROM: $ROM (python3 tools/build_exec_rom.py)" >&2
  exit 1
fi
if [ ! -x "$BIN" ]; then
  echo "openMSX not found: $BIN" >&2
  exit 1
fi

exec "$BIN" -machine "$MACHINE" -cart "$ROM" -romtype ASCII16
