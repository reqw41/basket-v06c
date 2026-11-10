#!/bin/sh
# T-states of a hand module against its translation: tools/native/cmp_t.sh <module> [mutations]
set -e
cd "$(dirname "$0")/../.."
M=$1; K=${2:-3}
ALL=$(node -e "console.log(Object.keys(require('./cfg/native_modules.json')).filter(k=>k[0]!=='_').join(','))")
REST=$(node -e "console.log('$ALL'.split(',').filter(k=>k!=='$M').join(',')||'0')")
NATIVE=$REST python3 tools/recompile_i8080.py >/dev/null && python3 tools/build_i8080_rom.py >/dev/null
printf 'translated: '; node tools/native/unit.js "$M" "$K" 2>/dev/null | tail -1
python3 tools/recompile_i8080.py >/dev/null && python3 tools/build_i8080_rom.py >/dev/null
printf 'hand:       '; node tools/native/unit.js "$M" "$K" 2>/dev/null | tail -1
