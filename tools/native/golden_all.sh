#!/bin/sh
# A0: record every golden scenario (parallel), then the coverage report.
#   tools/native/golden_all.sh [out-dir]     default research/golden
# Determinism: run twice into two dirs and compare (tools/native/golden_all.sh /tmp/x; cmp).
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
OUT="${1:-research/golden}"
mkdir -p "$OUT"
ls research/golden/scenarios/*.json | xargs -P "${JOBS:-6}" -n 1 -I{} tools/native/golden_one.sh {} "$OUT"
[ "$OUT" = research/golden ] && node tools/native/golden_cover.js || true
