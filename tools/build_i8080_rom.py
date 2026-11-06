#!/usr/bin/env python3
"""Compose the i8080 image: recompiled game code + the (i8080) adapter.

  python3 tools/build_i8080_rom.py      # after build_v06_rom.py, disasm_v06.py, recompile_i8080.py

Inputs: build/v06/basket.full.bin (Z80 reference image), build/i8080/game.bin
with build/i8080/labels.json (Z80 -> i8080 address map, placed spans, RST
helpers) and src/i8080/game.asm.

1. Adapter references into game code (cfg/labels.json names of game code
   and game operands) get their i8080 addresses: every adapter unit is
   assembled twice (Z80 and i8080 label values, BASKET_LABEL_OVERRIDES) and
   only the differing bytes are written, each checked to be such an operand.
2. Every Z80 instruction byte of the game is cleared; the recompiled spans
   are written over the image (data stays in place).
3. Numeric reference: the BIOS_OUTDO call to the relocated glyph printer
   (3B53, relocation manifest) is remapped.
4. RST 00/08/10/20/28/30 jump to the compact (ix+d) helpers, in page 0 and
   in its boot image at 0E00.

Output: build/i8080/basket-i8080.rom (loads at 0100) and .full.bin.
"""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
B, I = ROOT / "build/v06", ROOT / "build/i8080"
SJASM = Path(os.environ.get("ZASM") or shutil.which("zasm") or str(Path.home() / "projects/kvalley-v06c/tools/bin/sjasm"))
GAME_KINDS = ("game_code", "sys_code", "game_operand")
sys.path.insert(0, str(ROOT / "tools"))


def amap() -> dict[int, int]:
    return {int(a, 16): int(b, 16) for a, b in json.loads((I / "labels.json").read_text())["map"].items()}


def overrides(m: dict[int, int]) -> dict[str, str]:
    labels = json.loads((ROOT / "cfg/labels.json").read_text())["labels"]
    out = {}
    for n, e in labels.items():
        a = int(e["addr"], 16)
        if e["kind"] in GAME_KINDS and a in m and m[a] != a:
            out[n] = f"{m[a]:04X}"
        elif e["kind"] in GAME_KINDS and 0x84D0 <= a < 0xB258 and a not in m:
            raise SystemExit(f"{n} {e['addr']}: no i8080 address")
    return out


def assemble_units(srcdir: Path, env: dict) -> dict[str, tuple[int, bytes]]:
    subprocess.run([sys.executable, str(ROOT / "tools/gen_labels.py")], env=env, check=True,
                   capture_output=True)
    import gen_labels
    labels = json.loads((ROOT / "cfg/labels.json").read_text())["labels"]
    out = {}
    os.environ["BASKET_SRCDIR"] = str(srcdir)
    import importlib
    importlib.reload(gen_labels)
    for unit, files in gen_labels.units().items():
        src = srcdir / f"{unit}.asm"
        text = src.read_text(errors="replace")
        m = re.search(r"^\s+org\s+(\S+)", text, re.M)
        if not m:
            continue
        org = m.group(1)
        base = int(org, 16) if org.startswith("0x") else int(labels[org]["addr"], 16)
        lst, binf = srcdir / f"{unit}.lst", srcdir / f"{unit}.bin"
        r = subprocess.run([str(SJASM), "--8080", "-b", "-w", src.name, lst.name, binf.name],
                           cwd=srcdir, capture_output=True, text=True)
        t = r.stdout + r.stderr
        if "error" in t.lower() and "no errors" not in t.lower():
            raise SystemExit(f"{unit}: {t[-800:]}")
        out[unit] = (base, binf.read_bytes())
    return out


def main() -> int:
    m = amap()
    meta = json.loads((I / "labels.json").read_text())
    over = overrides(m)
    (I / "label_overrides.json").write_text(json.dumps(over, indent=1) + "\n")
    print(f"[1] {len(over)} game labels move: " + ", ".join(f"{k} {v}" for k, v in sorted(over.items())))

    # 1. adapter operands
    work = I / "adapter_src"
    for tag in ("z80", "i8080"):
        d = work / tag
        if d.exists():
            shutil.rmtree(d)
        shutil.copytree(ROOT / "src/v06", d)
    env0 = dict(os.environ, BASKET_SRCDIR=str(work / "z80"))
    env0.pop("BASKET_LABEL_OVERRIDES", None)
    env1 = dict(os.environ, BASKET_SRCDIR=str(work / "i8080"),
                BASKET_LABEL_OVERRIDES=str(I / "label_overrides.json"))
    old = assemble_units(work / "z80", env0)
    new = assemble_units(work / "i8080", env1)
    img = bytearray((B / "basket.full.bin").read_bytes())
    pairs = {int(k, 16): int(v, 16) for k, v in
             ((json.loads((ROOT / "cfg/labels.json").read_text())["labels"][n]["addr"], a)
              for n, a in over.items())}
    patched = 0
    for unit, (base, a) in old.items():
        b = new[unit][1]
        if len(a) != len(b):
            raise SystemExit(f"{unit}: size differs with i8080 labels")
        k = 0
        while k < len(a):
            if a[k] == b[k]:
                k += 1
                continue
            w0, w1 = a[k] | a[k + 1] << 8, b[k] | b[k + 1] << 8
            # the operand may start one byte earlier (only its high byte moved)
            if w0 not in pairs and k:
                w0p, w1p = a[k - 1] | a[k] << 8, b[k - 1] | b[k] << 8
                if pairs.get(w0p) == w1p:
                    k -= 1
                    w0, w1 = w0p, w1p
            if pairs.get(w0) != w1:
                raise SystemExit(f"{unit} {base + k:04X}: {w0:04X} -> {w1:04X} is not a label move")
            at = base + k
            if img[at] | img[at + 1] << 8 != w0:
                raise SystemExit(f"{unit} {at:04X}: image holds {img[at] | img[at + 1] << 8:04X}, want {w0:04X}")
            img[at], img[at + 1] = b[k], b[k + 1]
            patched += 1
            k += 2
    print(f"[1] adapter: {patched} operands moved to i8080 game code")
    # copy timing of the damage publisher (damage_publish.asm DP_TIMING,
    # DP_START): on the i8080 a box row of w pairs costs 52w + 100 Vector
    # cycles, a box 4.5 lines more, the first box starts at line 28
    lst = (work / "i8080" / "adapter_hi.lst").read_text(errors="replace")
    at = int(re.search(r"^DP_TIMING\s+= \$([0-9A-F]{4})", lst, re.M).group(1), 16)
    # DP_BEHIND: K = 83 - earliest first row of a batch (line 24), 8 spins a
    # line of the IRQ wait loop (44 + 20 * 8 = 204 cycles)
    z80 = bytes((10, 17, 176)) + (48 * 22).to_bytes(2, "little") + bytes((65, 12))
    i80 = bytes((13, 25, 216)) + (48 * 28).to_bytes(2, "little") + bytes((59, 8))
    if bytes(img[at:at + 7]) != z80:
        raise SystemExit(f"DP_TIMING {at:04X}: {bytes(img[at:at + 7]).hex()}, want {z80.hex()}")
    img[at:at + 7] = i80
    print(f"[1] DP_TIMING {at:04X}: i8080 13w + 25, C 216, start line 28, behind K 59")

    # 2. game code
    spec = __import__("importlib.util").util.spec_from_file_location("rc", ROOT / "tools/recompile_i8080.py")
    rc = __import__("importlib.util").util.module_from_spec(spec)
    spec.loader.exec_module(rc)
    _, items = rc.parse("game")
    cleared = 0
    for it in items:
        if it.kind == "code" and it.addr is not None:
            for x in range(it.addr, it.addr + it.nbytes):
                img[x] = 0
                cleared += 1
    gtext = (ROOT / "src/i8080/game.asm").read_text()
    gbase = min(int(x, 16) for x in re.findall(r"^\torg\t0x([0-9A-F]+)", gtext, re.M))
    gbin = (I / "game.bin").read_bytes()
    placed = 0
    for lo, hi in meta["used"]:
        lo, hi = int(lo, 16), int(hi, 16) + 1
        img[lo:hi] = gbin[lo - gbase:hi - gbase]
        placed += hi - lo
    print(f"[2] game: {cleared} Z80 code bytes cleared, {placed} i8080 bytes in {len(meta['used'])} spans")

    # 3. BIOS_OUTDO -> relocated glyph printer
    site = 0x029E
    if img[site:site + 3] != bytes((0xCD, 0x53, 0x3B)):
        raise SystemExit(f"029E: {img[site:site + 3].hex()}, want call 3B53")
    t = m[0x3B53]
    img[site + 1:site + 3] = bytes((t & 0xFF, t >> 8))
    print(f"[3] 029E call 3B53 -> {t:04X}")

    # 4. RST slots
    for slot, (name, addr) in meta["rst"].items():
        s, a = int(slot, 16), int(addr, 16)
        for base in (0x0000, 0x0E00):
            img[base + s:base + s + 3] = bytes((0xC3, a & 0xFF, a >> 8))
        print(f"[4] RST {slot}: JP {name} {addr}")

    I.mkdir(parents=True, exist_ok=True)
    (I / "basket-i8080.full.bin").write_bytes(img)
    (I / "basket-i8080.rom").write_bytes(bytes(img[0x100:]))
    print(f"Output: {I / 'basket-i8080.rom'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
