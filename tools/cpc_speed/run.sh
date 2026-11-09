#!/bin/sh
# Headless, silent CPC tempo bench: tools/cpc_speed/run.sh [still|motion] [out.json]
set -e
ROOT="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
[ -s "$ROOT/build/cpcbox/cdt.js" ] || "$ROOT/tools/cpc_speed/fetch_cpcbox.sh"
cp "$ROOT/tools/cpc_speed/cdt.js" "$ROOT/build/cpcbox/cdt.js"
CDT="${CPC_CDT:-$ROOT/ref/cpc/Fernando Martin Basket Master.cdt}"
NODE_PATH="${NODE_PATH:-$(npm root -g)}" exec node "$ROOT/tools/cpc_speed/bench.js" \
  "$ROOT/build/cpcbox" "$CDT" "${1:-still}" "${2:-$ROOT/build/cpcbox/${1:-still}.json}"
