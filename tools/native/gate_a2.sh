#!/bin/sh
# A2 gate: build with all hand modules, each module against the model, then the
# i8080 image checks of verify_refactor (run, block_equiv, frame_predict, MSX lockstep).
set -e
cd "$(dirname "$0")/../.."
python3 tools/recompile_i8080.py | grep -a "запас"
python3 tools/build_i8080_rom.py >/dev/null
for m in $(node -e "console.log(Object.keys(require('./cfg/native_modules.json')).filter(k=>k[0]!=='_').join(' '))"); do
  node tools/native/unit.js "$m" "${K:-10}" 2>/dev/null | tail -1
done
node tools/run_i8080.js 2>/dev/null | tail -1
NF=1200 K=2 node tools/block_equiv.js 2>/dev/null | tail -1
CPU=i8080 SEED=5 NF=4000 node tools/frame_predict.js build/i8080/basket-i8080.rom 2>/dev/null | tail -1
CPU=i8080 MENU=1500 NF=4000 SEED=2 node tools/frame_predict.js build/i8080/basket-i8080.rom 2>/dev/null | tail -1
python3 tools/build_exec_rom.py --deterministic >/dev/null 2>&1
python3 tools/msx_lockstep.py --iters 400 --cpu i8080 2>&1 | tail -1
# the same scene as the release build (seed fixed at the match start), and the tempo
CPU=i8080 node tools/bench_play.js 2>/dev/null | tail -1 | grep -o '"iterations":[0-9]*\|"cyclesPerIter":[0-9]*\|"hz":[0-9.]*\|"state":"[0-9a-f]*"' | tr '\n' ' '; echo "(release scene 629cfa4d83d863e4)"
shasum build/i8080/basket-i8080.rom
