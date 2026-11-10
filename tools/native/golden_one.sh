#!/bin/sh
# Record one golden scenario: golden_one.sh <scenario.json> <out-dir>
n=$(basename "$1" .json)
node "$(dirname "$0")/golden.js" "$1" "$2/$n.json.gz" 2>/dev/null | python3 -c '
import json, sys
d = json.loads([l for l in sys.stdin if l.startswith("{")][-1])
print(d["name"], "frames", d["frames"], "iters", d["iters"], "events", d["events"], "forced", d["forced"],
      "step", d["step"], "cover", d["cover"], "secs", d["secs"])'
