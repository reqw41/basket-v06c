#!/usr/bin/env python3
"""Game-logic lockstep: MSX original (deterministic RNG) against the port.

  python3 tools/msx_lockstep.py [--iters N] [--seed S] [--cpu z80|i8080|both]

Both machines run title -> menu "1" -> a 1P match. From the first match
iteration (8554 with the match flag: MSX B206, port 0FED) every iteration
gets the same player-1 keys from a SEED plan (held a random 5..30 iterations
like the other stands) and dumps the game state:

  4000..4159  game work RAM
  84D0..B257  game window (same addresses on MSX and port)
  D098..DD17  system/HUD block (port 3300..3F7F, relocated)

The RNG is deterministic on both sides (tools/rng_patch.py,
executive-det.rom); the menu time differs, so the port takes the MSX seed
4114 at the first match iteration. Compared per iteration: every byte that
is not Z80 code (disasm) and not statically different between the MSX
image and the port image (patches, relocated operands). The first
differing iteration is reported with the bytes and their D_ labels.
Exclusions with reasons are in IGNORE.
"""
from __future__ import annotations

import argparse
import json
import random
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "build/lockstep"
MSX_ROM = ROOT / "ref/msx/executive/executive-det.rom"
OPENMSX = "/opt/homebrew/bin/openmsx"
MSX_REGIONS = ((0x4000, 0x15A), (0x84D0, 0xB258 - 0x84D0), (0xD098, 0xDD18 - 0xD098))
PORT_REGIONS = ((0x4000, 0x15A), (0x84D0, 0xB258 - 0x84D0), (0x3300, 0xDD18 - 0xD098))
KEYS_MSX = {"up": (0, 0x02), "down": (4, 0x40), "left": (3, 0x02), "right": (3, 0x08), "fire": (5, 0x80)}
# MSX address -> reason; reviewed platform differences, not errors.
IGNORE: dict[int, str] = {
    0x4111: "IRQ frame counter (real time: machines run at different speeds)",
    0x4112: "IRQ frame counter high byte",
    0x4113: "IRQ counter carry (seconds of the match clock)",
    0x4102: "text cursor row: the port HUD (CPC layout, TIME, HUD_TEXT_REFRESH) prints elsewhere",
    0x4103: "text cursor column",
    0x410D: "stick byte of the IRQ key snapshot: the port's GTSTCK(1) reads the Vector cursor keys, which steer the port here (MSX: 1 Q D F Z, stick idle)",
    0x410E: "second stick byte of the IRQ key snapshot (same as 410D)",
    0x410F: "last key code from the IRQ key scan (event timing; menus/name entry)",
    0x4110: "last key ASCII from the IRQ key scan",
    0x4141: "JP to the game ISR: a code address, MSX D4AB vs relocated port",
    0x4142: "game ISR vector low byte",
    0x4143: "game ISR vector high byte",
    0x93D4: "replay ring pointer: the port keeps the ring at 1B40..1FFF",
    0x93D5: "replay ring pointer high byte",
    0x93E6: "match clock 1/50 s, driven by the frame IRQ (3705 -> 9F6E): real time",
    0x93E7: "match clock digit (IRQ time)",
    0x93E8: "match clock digit (IRQ time)",
    0x93E9: "match clock digit (IRQ time)",
    0xD09A: "BLIT_SRC: sprite record pointer, MSX bank vs CPC bank (port renderer)",
    0xD09B: "BLIT_SRC high byte",
}
# Renderer scratch of the MSX blitter that the port renders natively.
for _a in range(0xB01C, 0xB1F0):
    IGNORE[_a] = "B01C..B1EF: MSX sprite blitter code and scratch (port: native colour renderer, buffered_players)"
# Music/SFX player state: runs in the frame IRQ (AB28) and points into the
# relocated sound data (port: 7AE8.., VI53 SFX at 7FBA).
for _a in range(0xAC05, 0xAC44):
    IGNORE[_a] = "AC05..AC43: sound player state (IRQ time, relocated sound data)"
for _a in (0xD0A0, 0xD0A1, 0xD0A2, 0xD0A3, 0xD2B7):
    IGNORE[_a] = "MSX blitter internals (D0A0..D0A3, D2B7): not used by the port renderer"


def plan(iters: int, seed: int) -> list[list[str]]:
    rnd = random.Random(seed)
    out, hold, cur = [], 0, []
    names = list(KEYS_MSX)
    for _ in range(iters):
        if hold <= 0:
            hold = rnd.randint(5, 30)
            r = rnd.random()
            cur = [] if r < 0.15 else [rnd.choice(names)] + (["fire"] if rnd.random() < 0.2 else [])
        out.append(sorted(set(cur)))
        hold -= 1
    return out


def run_msx(keys: list[list[str]], dump: Path) -> dict:
    tcl = OUT / "msx_lockstep.tcl"
    plan_tcl = "\n".join(
        "set ::plan(%d) {%s}" % (i, " ".join(f"{r} {m}" for r, m in (KEYS_MSX[n] for n in ks)))
        for i, ks in enumerate(keys))
    regions = " ".join(f"{lo} {n}" for lo, n in MSX_REGIONS)
    tcl.write_text(f"""set renderer none
set mute on
set throttle off
{plan_tcl}
set ::k -1
set ::n {len(keys)}
set ::out [open "{dump}" w]
fconfigure $::out -translation binary
proc tap {{row mask secs}} {{
    keymatrixdown $row $mask
    after time $secs "keymatrixup $row $mask"
}}
after time 12 {{ tap 8 0x01 0.3 }}
after time 18 {{ tap 0 0x02 0.3 }}
after time 22 {{ tap 0 0x02 0.3 }}
proc iter {{}} {{
    if {{[peek 0xB206] != 1}} return
    incr ::k
    if {{$::k == 0}} {{ set ::seed [peek16 0x4114] }}
    if {{$::k >= $::n}} {{
        close $::out
        set f [open "{dump}.meta" w]; puts $f "$::seed"; close $f
        exit
    }}
    foreach r {{0 1 2 3 4 5 6 7 8}} {{ keymatrixup $r 0xFF }}
    foreach {{r m}} $::plan($::k) {{ keymatrixdown $r $m }}
    # the game's own key snapshot (4104+row, written by its IRQ scan): set it
    # now, so the keys count from this iteration on both machines
    foreach r {{0 1 2 3 4 5 6 7 8}} {{ poke [expr {{0x4104 + $r}}] 0xFF }}
    foreach {{r m}} $::plan($::k) {{ poke [expr {{0x4104 + $r}}] [expr {{[peek [expr {{0x4104 + $r}}]] & ~$m & 0xFF}}] }}
    foreach {{lo n}} {{{regions}}} {{ puts -nonewline $::out [debug read_block memory $lo $n] }}
}}
debug set_bp 0x8554 {{}} {{ iter }}
after time 3000 {{ exit }}
""")
    r = subprocess.run([OPENMSX, "-machine", "BasketMSX", "-cart", str(MSX_ROM), "-romtype", "ASCII16",
                        "-script", str(tcl)], capture_output=True, text=True, timeout=900)
    meta = Path(str(dump) + ".meta")
    if not meta.exists():
        raise SystemExit("openMSX did not reach the match:\n" + (r.stdout + r.stderr)[-1500:])
    return {"seed": int(meta.read_text().split()[0])}


def transplant(msx_dump: Path, cpu: str) -> list[list[int]]:
    """[port address, MSX value] of every compared byte at match iteration 0:
    the port starts the match in the MSX state (menu time and the BIOS leave
    different leftovers)."""
    addrs, _ = compare_mask(cpu)
    first = msx_dump.read_bytes()[:len(addrs)]
    out = []
    i = 0
    for (mlo, n), (plo, _) in zip(MSX_REGIONS, PORT_REGIONS):
        for j in range(n):
            if addrs[i] is not None:
                out.append([plo + j, first[i]])
            i += 1
    return out


def run_port(keys, seed: int, cpu: str, dump: Path, state) -> None:
    rom = ROOT / ("build/v06/basket.rom" if cpu == "z80" else "build/i8080/basket-i8080.rom")
    planf = OUT / "plan.json"
    planf.write_text(json.dumps({"keys": keys, "seed": seed, "port_regions": PORT_REGIONS, "state": state}))
    r = subprocess.run(["node", str(ROOT / "tools/port_lockstep.js"), str(rom), str(planf), str(dump)],
                       capture_output=True, text=True, timeout=1800, env={**__import__("os").environ, "CPU": cpu})
    if r.returncode or not dump.exists():
        raise SystemExit(f"port ({cpu}) failed:\n" + (r.stdout + r.stderr)[-1500:])


def compare_mask(cpu: str = "z80") -> tuple[list[int], dict[int, str]]:
    """MSX addresses of the dump layout that are compared, and labels. On the
    i8080 the bytes that differ from the Z80 image are recompiled code laid
    over former game code or proven-free zeros: not state."""
    full = (ROOT / "build/v06/basket.full.bin").read_bytes()
    full80 = (ROOT / "build/i8080/basket-i8080.full.bin").read_bytes() if cpu == "i8080" else full
    msx = bytearray(0x10000)
    ov = (ROOT / "ref/msx/executive/executive.overlay.bin").read_bytes()
    msx[0x84D0:0x84D0 + len(ov)] = ov
    code = set()
    for lo, n in json.loads((ROOT / "build/v06/disasm_v06_code.json").read_text()):
        for a in range(lo, lo + n):
            code.add(a + 0x9D98 if 0x3300 <= a < 0x3F80 else a)
    addrs = []
    for (mlo, n), (plo, _) in zip(MSX_REGIONS, PORT_REGIONS):
        for i in range(n):
            ma, pa = mlo + i, plo + i
            static_diff = mlo != 0x4000 and (full[pa] != msx[ma] or full80[pa] != full[pa])
            addrs.append(None if (ma in code or static_diff or ma in IGNORE) else ma)
    labels = {}
    for m in re.finditer(r"^D_([0-9A-F]{4}):", (ROOT / "disasm/v06/game.asm").read_text(), re.M):
        a = int(m.group(1), 16)
        labels[a + 0x9D98 if 0x3300 <= a < 0x3F80 else a] = "D_" + m.group(1)
    return addrs, labels


def name(a: int, labels: dict[int, str]) -> str:
    base = max((x for x in labels if x <= a and a - x < 16), default=None)
    return f"{a:04X}" + (f" ({labels[base]}+{a - base})" if base is not None else "")


def pointer_slots(cpu: str) -> dict[int, dict[int, int]]:
    """MSX address of a code-pointer word -> {Z80 port address: i8080 address}.
    The 3C1E dispatch list (flag, procedure) is rebuilt by 94B0 every
    iteration with the procedures' addresses: on the i8080 they are the
    recompiled ones."""
    if cpu != "i8080":
        return {}
    amap = {int(z, 16): int(i, 16) for z, i in
            json.loads((ROOT / "build/i8080/labels.json").read_text())["map"].items()}
    slots = {0x3C1F + 0x9D98 + 3 * k: amap for k in range(16)}
    words = json.loads((ROOT / "tools/disasm_v06_entries.json").read_text()).get("data_words", [])
    for w in words:                          # pointers into code found by the disasm (key operands)
        slots[int(w, 16)] = amap
    return slots


def compare(msx_dump: Path, port_dump: Path, iters: int, tag: str) -> int:
    addrs, labels = compare_mask(tag)
    slots = pointer_slots(tag)
    if tag == "i8080":                       # recompiler runtime cells RT_VARS
        addrs = [None if a is not None and 0x9300 <= a < 0x9320 else a for a in addrs]
    pos = {a: i for i, a in enumerate(addrs) if a is not None}
    size = len(addrs)
    m, p = msx_dump.read_bytes(), port_dump.read_bytes()
    n = min(len(m), len(p)) // size
    print(f"[{tag}] {n} iterations compared ({len(m) // size} MSX, {len(p) // size} port), "
          f"{sum(a is not None for a in addrs)} bytes per iteration")
    if n < iters:
        print(f"[{tag}] LOCKSTEP_FAIL: the port reached {len(p) // size} of {iters} iterations")
        return 1
    for k in range(n):
        mm, pp = m[k * size:(k + 1) * size], p[k * size:(k + 1) * size]
        same = set()
        for a, amap in slots.items():
            if a in pos and a + 1 in pos:
                i = pos[a]
                w = mm[i] | mm[i + 1] << 8
                w = w - 0x9D98 if 0xD09C <= w < 0xDD18 else w
                if amap.get(w) == (pp[i] | pp[i + 1] << 8):
                    same |= {i, i + 1}
        diff = [(addrs[i], mm[i], pp[i]) for i in range(size)
                if addrs[i] is not None and mm[i] != pp[i] and i not in same]
        if diff:
            print(f"[{tag}] FIRST DIFFERENCE at match iteration {k}: {len(diff)} bytes")
            for a, x, y in diff[:24]:
                print(f"    {name(a, labels)}  msx {x:02X}  port {y:02X}")
            return 1
    print(f"[{tag}] LOCKSTEP_PASS")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--iters", type=int, default=200)
    ap.add_argument("--seed", type=int, default=12345)
    ap.add_argument("--cpu", default="z80", choices=("z80", "i8080", "both"))
    args = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    keys = plan(args.iters, args.seed)
    msx_dump = OUT / "msx.bin"
    meta = run_msx(keys, msx_dump)
    print(f"[msx] seed 4114 at match start: {meta['seed']:04X}")
    rc = 0
    for cpu in (("z80", "i8080") if args.cpu == "both" else (args.cpu,)):
        dump = OUT / f"port_{cpu}.bin"
        run_port(keys, meta["seed"], cpu, dump, transplant(msx_dump, cpu))
        rc |= compare(msx_dump, dump, args.iters, cpu)
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
