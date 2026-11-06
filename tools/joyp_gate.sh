#!/bin/sh
# Joystick «П» gate (headless vector06js): port 6 and the Vector cursor keys
# press the player 1 keys and walk the player; port 0Eh is never read.
# Negative control: with port 6 silent (JOYDEAD=1) the test must fail.
#   tools/joyp_gate.sh [rom]
cd "$(dirname "$0")/.." || exit 1
ROM=${1:-build/v06/basket.rom}
ok=0
if node tools/test_joy_p.js "$ROM" >/dev/null 2>&1; then echo "ok   joystick «П» and cursor keys"; else
  node tools/test_joy_p.js "$ROM" 2>&1 | grep FAIL; ok=1; fi
if grep -inE 'in +a, *\((0x0?e|0?eh)\)' src/v06/*.asm >/dev/null 2>&1; then echo "FAIL port 0Eh is read"; ok=1
else echo "ok   port 0Eh is not read"; fi
if JOYDEAD=1 node tools/test_joy_p.js "$ROM" >/dev/null 2>&1; then echo "FAIL negative control: silent port 6 passes"; ok=1
else echo "ok   negative control: silent port 6 fails"; fi
[ $ok = 0 ] && echo JOYP_GATE_PASS || { echo JOYP_GATE_FAIL; exit 1; }
