#!/usr/bin/env python3
"""Round-trip Z80 disassembly of the game code in the Vector layout (plan E1).

  python3 tools/disasm_v06.py            # -> disasm/v06/game.asm + build/v06/disasm_v06.json
  python3 tools/disasm_v06.py --verify   # also reassemble and compare byte for byte

Input: build/v06/basket.full.bin (the live Z80 reference image).
Regions: the relocated MSX system block 3304..3F7F and the game window
84D0..B257. Adapter modules that the builder installs inside those ranges
(ADAPTER_HOLES) are not game code: they stay out of the listing and are
skipped by the round-trip check; game code reaches them by labels.inc names.

Code is found by recursive descent from: every executed PC of the coverage
runs (build/v06/cov/*.bin, tools/collect_exec_v06.js) and of the matching
xref traces, the 84D0 jump table, the game-code labels of cfg/labels.json,
and tools/disasm_v06_entries.json. Everything not reached is `db`.

Output format follows the Spirits recompiler input: a label line `Z_XXXX:` on
every instruction, then `\tinsn\t; XXXX bb bb ..`. Operands are numeric in
this first stage (E1); symbolisation is E1b.
"""
from __future__ import annotations

import shutil
import os
import argparse
import glob
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(__file__).resolve().parent / "vendor"))
from z80dis import decode  # noqa: E402

SJASM = Path(os.environ.get("ZASM") or shutil.which("zasm") or str(Path.home() / "projects/kvalley-v06c/tools/bin/sjasm"))
FULL = ROOT / "build/v06/basket.full.bin"
OUT = ROOT / "disasm/v06/game.asm"
REPORT = ROOT / "build/v06/disasm_v06.json"
ENTRIES = ROOT / "tools/disasm_v06_entries.json"

REGIONS = ((0x3304, 0x3F80, "system block (MSX D09C..DD17, relocated)"),
           (0x84D0, 0xB258, "game window (MSX 84D0..B257)"))
# Adapter code/data the builder writes over game ranges (src/v06/*.asm).
ADAPTER_HOLES = (
    (0x34BD, 0x352B, "blit_native.asm"),
    (0xA0D0, 0xA133, "wipe_native.asm (A0D0 column, A132 RET)"),
    (0xA521, 0xA535, "A521 JP NATIVE_STAMP + win_a524.asm"),
)


def in_regions(a: int) -> bool:
    return any(lo <= a < hi for lo, hi, _ in REGIONS) and not in_hole(a)


def in_hole(a: int) -> bool:
    return any(lo <= a < hi for lo, hi, _ in ADAPTER_HOLES)


COV_BITS = ROOT / "cfg/recompile/exec_v06.bits"   # 8 KiB bitset of executed PCs


def live_coverage() -> set[int]:
    """Executed PCs of the coverage runs (build/v06/cov) and same-SHA xref traces."""
    s: set[int] = set()
    for f in glob.glob(str(ROOT / "build/v06/cov/*.bin")):
        b = Path(f).read_bytes()
        s |= {a for a in range(0x10000) if b[a]}
    import hashlib
    sha = hashlib.sha256((ROOT / "build/v06/basket.rom").read_bytes()).hexdigest()
    for f in glob.glob(str(ROOT / "build/v06/xref_*.meta.json")):
        try:
            if json.loads(Path(f).read_text()).get("rom_sha256") != sha:
                continue                          # traces of another image lie
            s |= set(json.loads(Path(f.replace(".meta.json", ".json")).read_text()).get("exec", []))
        except (ValueError, OSError):
            pass
    return s


def seeds(mem: bytes) -> set[int]:
    # The committed coverage keeps the listing reproducible in a clean tree
    # (--save-cov merges the live runs into it).
    b = COV_BITS.read_bytes()
    s: set[int] = {a for a in range(0x10000) if b[a >> 3] >> (a & 7) & 1}
    for a in range(0x84D0, 0x84E8, 3):            # game jump table
        if mem[a] == 0xC3:
            s.add(a)
    labels = json.loads((ROOT / "cfg/labels.json").read_text())["labels"]
    s |= {int(e["addr"], 16) for e in labels.values() if e["kind"] in ("game_code", "sys_code")}
    if ENTRIES.exists():
        s |= {int(x, 16) for x in json.loads(ENTRIES.read_text()).get("code", [])}
    return {a for a in s if in_regions(a)}


def walk(mem: bytes, start: set[int]):
    insns: dict[int, object] = {}
    owner: dict[int, int] = {}
    overlaps: list[tuple[int, int]] = []
    work = sorted(start)
    while work:
        a = work.pop()
        while in_regions(a) and a not in insns:
            if a in owner:                         # lands inside another instruction
                overlaps.append((a, owner[a]))
                break
            ins = decode(mem[a:a + 8], a)
            if any(not in_regions(a + k) or (a + k) in insns or (a + k) in owner
                   for k in range(1, ins.length)):
                overlaps.append((a, a))
                break
            insns[a] = ins
            for k in range(ins.length):
                owner[a + k] = a
            for t in ins.targets:
                if in_regions(t) and t not in insns:
                    work.append(t)
            f = ins.flow
            if f in ("jump", "dyn") or (f == "ret" and ins.fmt in ("ret", "retn", "reti")):
                break
            a += ins.length
    return insns, owner, overlaps


def plan_symbols(mem: bytes, insns, owner):
    """Operand text per instruction, the data labels to create, and a report."""
    labels = json.loads((ROOT / "cfg/labels.json").read_text())["labels"]
    ext = {int(e["addr"], 16): n for n, e in labels.items()}
    data_labels: set[int] = set()
    used_ext: dict[str, int] = {}
    text: dict[int, str] = {}
    report = {"pointer_imm16": [], "smc_refs": [], "ext": []}

    def ref(t: int, kind: str, at: int) -> str | None:
        if in_regions(t):
            if t in insns:
                return f"Z_{t:04X}"
            if t in owner:                         # inside an instruction: SMC operand
                o = owner[t]
                report["smc_refs"].append(f"{at:04X}->{o:04X}+{t - o}")
                return f"Z_{o:04X}+{t - o}"
            data_labels.add(t)
            return f"D_{t:04X}"
        if t in ext and kind != "imm16":
            used_ext[ext[t]] = t
            report["ext"].append(f"{at:04X}->{ext[t]}")
            return ext[t]
        return None

    extra = json.loads(ENTRIES.read_text()) if ENTRIES.exists() else {}
    consts = {int(x, 16) for x in extra.get("const_imm16", [])}
    for a, ins in insns.items():
        if ins.operand is None or ins.opkind not in ("abs16", "imm16", "rel8") or a in consts:
            continue
        sym = ref(ins.operand, ins.opkind, a)
        if sym is None:
            continue
        if ins.opkind == "imm16":
            report["pointer_imm16"].append(f"{a:04X} {ins.text()} -> {sym}")
        text[a] = ins.text(sym)
    words = {}
    for x in extra.get("data_words", []):
        w = int(x, 16)
        t = mem[w] | mem[w + 1] << 8
        sym = ref(t, "abs16", w)
        if sym:
            words[w] = sym
            data_labels.add(w)
    report["data_words"] = {f"{w:04X}": s for w, s in words.items()}
    return text, data_labels, used_ext, report, words


def emit(mem: bytes, insns, owner, text, data_labels, used_ext, words) -> str:
    out = ["; Basket Master (MSX Executive) — game code in the Vector-06C layout.",
           "; GENERATED by tools/disasm_v06.py from build/v06/basket.full.bin — do not edit.",
           "; Z_XXXX: every instruction, D_XXXX: referenced data (Vector addresses).",
           "; Operands into the game are symbols; adapter/game names come from cfg/labels.json.",
           "; Adapter holes (src/v06 modules) are skipped by ORG.", ""]
    for n, v in sorted(used_ext.items(), key=lambda kv: kv[1]):
        out.append(f"{n}:\tequ\t0x{v:04X}")
    out.append("")
    for lo, hi, what in REGIONS:
        out.append(f"; ---- {lo:04X}..{hi - 1:04X} {what}")
        a = lo
        out.append(f"        org     0x{a:04X}")
        while a < hi:
            hole = next(((h0, h1, w) for h0, h1, w in ADAPTER_HOLES if h0 <= a < h1), None)
            if hole:
                out.append(f"; adapter hole {hole[0]:04X}..{hole[1] - 1:04X}: {hole[2]}")
                a = hole[1]
                if a < hi:
                    out.append(f"        org     0x{a:04X}")
                continue
            if a in insns:
                ins = insns[a]
                by = " ".join(f"{mem[a + k]:02X}" for k in range(ins.length))
                out.append(f"Z_{a:04X}:")
                out.append(f"\t{text.get(a, ins.text())}\t; {a:04X} {by}")
                a += ins.length
                continue
            if a in words:
                out.append(f"D_{a:04X}:")
                out.append(f"\tdw\t{words[a]}\t; {a:04X} {mem[a]:02X} {mem[a + 1]:02X}")
                a += 2
                continue
            j = a + 1
            while (j < hi and j not in insns and not in_hole(j) and j - a < 16
                   and j not in data_labels and j not in words):
                j += 1
            by = ", ".join(f"0x{mem[k]:02X}" for k in range(a, j))
            out.append(f"D_{a:04X}:")
            out.append(f"\tdb\t{by}\t; {a:04X}")
            a = j
    return "\n".join(out) + "\n"


def verify(mem: bytes, text: str) -> list[str]:
    tmp = ROOT / "build/v06/disasm_v06_rt"
    tmp.mkdir(parents=True, exist_ok=True)
    src = tmp / "game.asm"
    src.write_text(text)
    r = subprocess.run([str(SJASM), "-b", str(src), str(tmp / "game.lst"), str(tmp / "game.bin")],
                       capture_output=True, text=True)
    if "no errors" not in (r.stdout + r.stderr).lower():
        return [f"assembly failed: {(r.stdout + r.stderr)[-600:]}"]
    got = (tmp / "game.bin").read_bytes()
    base = REGIONS[0][0]
    errors = []
    for lo, hi, _ in REGIONS:
        for a in range(lo, hi):
            if in_hole(a):
                continue
            g = got[a - base] if a - base < len(got) else None
            if g != mem[a]:
                errors.append(f"byte {a:04X}: got {g}, want {mem[a]:02X}")
                if len(errors) > 20:
                    return errors
    return errors


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--verify", action="store_true")
    ap.add_argument("--save-cov", action="store_true", help="merge build/v06/cov runs into cfg/recompile/exec_v06.bits")
    args = ap.parse_args()
    mem = FULL.read_bytes()
    if args.save_cov:
        # Replace, not merge: PCs of an older image (patched sites) would seed
        # decoding in the middle of today's instructions.
        bits = bytearray(8192)
        for a in live_coverage():
            bits[a >> 3] |= 1 << (a & 7)
        COV_BITS.parent.mkdir(parents=True, exist_ok=True)
        COV_BITS.write_bytes(bytes(bits))
        print(f"{COV_BITS}: {sum(bin(x).count('1') for x in bits)} PCs")
    sd = seeds(mem)
    insns, owner, overlaps = walk(mem, sd)
    sym_text, data_labels, used_ext, symrep, words = plan_symbols(mem, insns, owner)
    text = emit(mem, insns, owner, sym_text, data_labels, used_ext, words)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(text)
    code = sum(i.length for i in insns.values())
    total = sum(hi - lo for lo, hi, _ in REGIONS) - sum(h1 - h0 for h0, h1, _ in ADAPTER_HOLES)
    rep = {"seeds": len(sd), "instructions": len(insns), "code_bytes": code, "game_bytes": total,
           "overlaps": [f"{a:04X}<-{o:04X}" for a, o in overlaps],
           "symbols": {"operands": len(sym_text), "data_labels": len(data_labels),
                       "external": sorted(used_ext)}, **symrep}
    REPORT.write_text(json.dumps(rep, indent=2) + "\n")
    (REPORT.parent / "disasm_v06_code.json").write_text(
        json.dumps(sorted([a, i.length] for a, i in insns.items())) + "\n")
    print(f"{OUT}: {len(insns)} instructions, {code} code bytes of {total}, "
          f"seeds {len(sd)}, overlaps {len(overlaps)}")
    if args.verify:
        errs = verify(mem, text)
        if overlaps:
            errs.append(f"{len(overlaps)} decoding overlaps (stale seeds?): " +
                        ", ".join(f"{a:04X}<-{o:04X}" for a, o in overlaps[:8]))
        for e in errs:
            print("FAIL", e)
        print("DISASM_ROUNDTRIP_FAIL" if errs else "DISASM_ROUNDTRIP_PASS")
        return 1 if errs else 0
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
