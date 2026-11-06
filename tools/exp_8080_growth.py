#!/usr/bin/env python3
"""Assemble Z80/8080 size sketches without claiming semantic equivalence.

Runs outside the game ROM. Uses sjasm. Reports growth factors for:
  - (IX+d)/(IY+d) load/store
  - LDIR block copy
  - CB bit test/shift
  - short helper call pattern

The fragments expose likely lowering costs, but they do not preserve every
register/flag contract and are not accepted as a growth projection.  A numeric
reserve claim requires representative game routines plus equivalence tests.
"""
from __future__ import annotations

import shutil
import os
import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SJASM = Path(os.environ.get("ZASM") or shutil.which("zasm") or str(Path.home() / "projects/kvalley-v06c/tools/bin/sjasm"))

CASES = {
    "ix_load": {
        "z80": "  org 100h\n  ld a,(ix+2)\n  ret\n",
        "i8080": (
            "  org 100h\n"
            "  push h\n"
            "  push b\n"
            "  ; hl = ix (simulated in DE for demo)\n"
            "  xchg\n"
            "  lxi b,2\n"
            "  dad b\n"
            "  mov a,m\n"
            "  pop b\n"
            "  pop h\n"
            "  ret\n"
        ),
        "note": "cold (ix+d) → expand/helper; Spirits uses call+db (~4B) vs 3B",
        "contract": "size sketch only; simulated index base and clobbers differ",
    },
    "iy_store": {
        "z80": "  org 100h\n  ld (iy-1),a\n  ret\n",
        "i8080": (
            "  org 100h\n"
            "  push h\n"
            "  push b\n"
            "  xchg\n"
            "  lxi b,-1\n"
            "  dad b\n"
            "  mov m,a\n"
            "  pop b\n"
            "  pop h\n"
            "  ret\n"
        ),
        "note": "store (iy+d)",
        "contract": "size sketch only; simulated index base and clobbers differ",
    },
    "ldir_32": {
        "z80": "  org 100h\n  ld bc,32\n  ldir\n  ret\n",
        "i8080": (
            "  org 100h\n"
            "  lxi b,32\n"
            "  call il_ldir\n"
            "  ret\n"
            "il_ldir:\n"
            "  mov a,b\n"
            "  ora c\n"
            "  rz\n"
            "  mov a,m\n"
            "  xchg\n"
            "  mov m,a\n"
            "  xchg\n"
            "  inx h\n"
            "  inx d\n"
            "  dcx b\n"
            "  jmp il_ldir\n"
        ),
        "note": "LDIR → helper; shared helper amortized across call sites",
        "contract": "copy direction matches HL→DE; flags/timing still differ",
    },
    "bit_cb": {
        "z80": "  org 100h\n  bit 7,a\n  ret nz\n  ret\n",
        "i8080": (
            "  org 100h\n"
            "  ani 80h\n"
            "  rnz\n"
            "  ret\n"
        ),
        "note": "simple BIT often shrinks; complex CB rotations grow",
        "contract": "size sketch only; ANI changes A unlike BIT",
    },
    "hot_ix_chain": {
        "z80": (
            "  org 100h\n"
            "  ld a,(ix+0)\n"
            "  ld b,(ix+1)\n"
            "  ld c,(ix+2)\n"
            "  ld d,(ix+3)\n"
            "  ret\n"
        ),
        "i8080": (
            "  org 100h\n"
            "  ; shared hl=ix base once\n"
            "  xchg\n"
            "  mov a,m\n"
            "  inx h\n"
            "  mov b,m\n"
            "  inx h\n"
            "  mov c,m\n"
            "  inx h\n"
            "  mov d,m\n"
            "  ret\n"
        ),
        "note": "hot path can share base pointer and beat naive per-access helpers",
        "contract": "size sketch only; base and register preservation differ",
    },
}


def assemble(source: str, out_bin: Path, cpu: str) -> int:
    asm = out_bin.with_suffix(".asm")
    asm.write_text(source)
    cmd = [str(SJASM)]
    if cpu == "8080":
        cmd.append("--asm8080")
    cmd += [str(asm), str(out_bin)]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0 or not out_bin.exists():
        raise RuntimeError(f"sjasm failed ({cpu}): {r.stdout}\n{r.stderr}")
    return out_bin.stat().st_size


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--json", type=Path)
    args = ap.parse_args()
    if not SJASM.exists():
        print(f"sjasm not found: {SJASM}", file=sys.stderr)
        return 2
    rows = []
    with tempfile.TemporaryDirectory() as td:
        td = Path(td)
        for name, case in CASES.items():
            zpath = td / f"{name}_z80.bin"
            ipath = td / f"{name}_8080.bin"
            z = assemble(case["z80"], zpath, "z80")
            i = assemble(case["i8080"], ipath, "8080")
            rows.append(
                {
                    "name": name,
                    "z80_bytes": z,
                    "i8080_bytes": i,
                    "delta": i - z,
                    "factor": round(i / z, 3) if z else None,
                    "note": case["note"],
                    "semantic_contract": case["contract"],
                    "behavior_equivalent": False,
                }
            )
    # Census context only.  These sketches cannot support a numeric projection.
    game_ix = 673
    report = {
        "sjasm": str(SJASM),
        "cases": rows,
        "projection": {
            "ix_iy_prefixes_in_game_window": game_ix,
            "ldir_sites_game_approx": 16,
            "shared_il_ldir_helper_bytes": next(
                r["i8080_bytes"] - 3 for r in rows if r["name"] == "ldir_32"
            ),
            "growth_status": "UNPROVEN",
            "estimated_extra_range_bytes": None,
            "recomp_reserve": 4096,
            "reserve_proven_sufficient": False,
            "limitations": [
                "Fragments are size sketches, not behavior-equivalent replacements.",
                "Hot-path lowering can reduce growth; SMC/PIN can increase it.",
                "Adapter already closer to 8080; game overlay dominates risk.",
                "4KiB reserve is a project budget, not a measured fit.",
            ],
        },
    }
    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(report, indent=2) + "\n")
    print("8080 growth microbenches:")
    for r in rows:
        print(
            f"  {r['name']:12s} Z80={r['z80_bytes']:3d} 8080={r['i8080_bytes']:3d} "
            f"Δ={r['delta']:+3d} ×{r['factor']}"
        )
    p = report["projection"]
    print(
        f"projection={p['growth_status']} vs reserve {p['recomp_reserve']} "
        f"(proven={p['reserve_proven_sufficient']})"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
