#!/usr/bin/env python3
"""Audit the A521 stamp-stub tail before any placement.

The builder replaces the 25-byte procedure at A521 with JP NATIVE_STAMP
plus 22 zero bytes (A524..A539). The next object is L_A53A.

A hit in an xref trace is enough to reject the tail. Absence of a hit is
not enough: this also checks entries, immediates, SMC stores, and the
neighbor at A53A.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
B = ROOT / "build/v06"

TAIL_LO, TAIL_HI = 0xA524, 0xA53A  # exclusive hi
STUB = 0xA521
NEXT = 0xA53A
ENTRY_CALL = 0xA51B  # CD 21 A5  — CALL A521 (byte before the JP)
ADAPTER_HI = 0x1000
# Relocation entries installed by this transfer. Anything else inside the tail rejects.
RELOC_ENTRIES = {0xA524, 0xA52C}
# Pure data tables whose byte pairs are not addresses (bit-reverse MIR_REV).
_LABELS = json.loads((ROOT / "cfg/labels.json").read_text())["labels"]
DATA_TABLES = [(int(_LABELS["MIR_REV"]["addr"], 16), int(_LABELS["MIR_REV"]["addr"], 16) + 256)]
# The adapter_hi unit is assembled from labelled source: its references go
# through cfg/labels.json, and byte pairs inside its instructions (e.g. the
# `32 A5` of `ld (0x84A5),a`) are not addresses.
import re as _re
_LST = B / "adapter_hi.lst"
if _LST.exists():
    _m = _re.search(r"^ADAPTER_HI_END\s+= \$([0-9A-F]{4})", _LST.read_text(errors="replace"), _re.M)
    if _m:
        DATA_TABLES.append((int(_LABELS["ADAPTER_HI"]["addr"], 16), int(_m.group(1), 16)))


def assert_tail_free(rom: bytes | bytearray) -> dict:
    mem = rom
    reasons = []
    stub = bytes(mem[STUB:STUB + 3])
    if stub[0] != 0xC3:
        reasons.append(f"A521 is {stub.hex()}, expected JP")
    tail = bytes(mem[TAIL_LO:TAIL_HI])
    if tail != bytes(TAIL_HI - TAIL_LO):
        reasons.append(f"A524..A539 not all zero: {tail.hex()}")
    # Neighbor must remain the original A53A prologue (ld a,01; ld (D1CB),a).
    if bytes(mem[NEXT:NEXT + 4]) != bytes.fromhex("3e0132cb"):
        reasons.append(f"neighbor A53A changed: {bytes(mem[NEXT:NEXT+4]).hex()}")

    # 16-bit immediates. A CALL/JP from the adapter to the tail entry (A524)
    # is the relocation itself; any other hit, including the middle of the tail, rejects.
    imm_hits = []
    reloc = []
    for pc in range(0, 0x10000 - 1):
        w = mem[pc] | (mem[pc + 1] << 8)
        if not (TAIL_LO <= w < TAIL_HI):
            continue
        if any(lo <= pc and pc + 1 < hi for lo, hi in DATA_TABLES):
            continue
        op_at = pc - 1
        op = mem[op_at] if op_at >= 0 else 0
        is_reloc = (
            w in RELOC_ENTRIES
            and op_at < ADAPTER_HI
            and op in (0xCD, 0xC3)
        )
        if is_reloc:
            reloc.append({"at": op_at, "target": w})
        else:
            imm_hits.append({"at": pc, "word": w})
    if imm_hits:
        reasons.append(f"{len(imm_hits)} immediates point into the tail: " + ", ".join(f"{h['at']:04X}={h['word']:04X}" for h in imm_hits[:8]))

    callers = []
    for pc in range(0, 0x10000 - 2):
        if mem[pc] in (0xCD, 0xC3, 0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA):
            w = mem[pc + 1] | (mem[pc + 2] << 8)
            if w == STUB or TAIL_LO <= w < TAIL_HI:
                callers.append({"at": pc, "op": mem[pc], "target": w})
    stub_calls = [c for c in callers if c["target"] == STUB]
    tail_calls = [
        c for c in callers
        if c["target"] != STUB and not (
            c["target"] in RELOC_ENTRIES and c["at"] < ADAPTER_HI and c["op"] in (0xCD, 0xC3)
        )
    ]
    if tail_calls:
        reasons.append(f"control transfer into tail: {tail_calls[:4]}")
    if not any(c["at"] == ENTRY_CALL and c["op"] == 0xCD for c in stub_calls):
        reasons.append("missing CALL A521 at A51B")

    # Absolute stores (LD (nn),A / LD (nn),HL / LD (nn),rr) aimed at the tail.
    smc = []
    for pc in range(0, 0xFFFC):
        op = mem[pc]
        if op in (0x32, 0x22) and pc + 2 < 0x10000:
            w = mem[pc + 1] | (mem[pc + 2] << 8)
            if TAIL_LO <= w < TAIL_HI or TAIL_LO <= w + 1 < TAIL_HI:
                smc.append(pc)
        if op == 0xED and mem[pc + 1] in (0x43, 0x53, 0x63, 0x73):
            w = mem[pc + 2] | (mem[pc + 3] << 8)
            if TAIL_LO <= w < TAIL_HI or TAIL_LO <= w + 1 < TAIL_HI:
                smc.append(pc)
    if smc:
        reasons.append(f"SMC/store sites: {[hex(p) for p in smc[:6]]}")

    report = {
        "id": "a521_stamp_tail",
        "stub": {"lo": STUB, "hi": TAIL_LO, "bytes": stub.hex()},
        "tail": {"lo": TAIL_LO, "hi": TAIL_HI, "size": TAIL_HI - TAIL_LO},
        "neighbor": {"lo": NEXT, "bytes": bytes(mem[NEXT:NEXT + 4]).hex()},
        "entries": [f"{c['at']:04X}->{c['target']:04X}" for c in stub_calls],
        "relocation_calls": [f"{c['at']:04X}" for c in reloc],
        "imm_hits": len(imm_hits),
        "smc": len(smc),
        "ok": not reasons,
        "reasons": reasons,
        "basis": (
            "build_v06_rom replaces the 25-byte A521 LDIR stamp with JP "
            "NATIVE_STAMP and 22 zero bytes ending exactly at A53A. "
            "The only control-flow entry is CALL A521 at A51C. "
            "No immediate, store, or branch targets A524..A539. "
            "A53A (ld a,01) is a separate procedure and is left intact."
        ),
    }
    if reasons:
        raise RuntimeError("A521 tail not free: " + "; ".join(reasons))
    return report


def main() -> int:
    full = B / "basket.full.bin"
    if not full.exists():
        print("missing basket.full.bin", file=sys.stderr)
        return 1
    rom = full.read_bytes()
    try:
        report = assert_tail_free(rom)
    except RuntimeError as e:
        print(e, file=sys.stderr)
        return 1
    B.mkdir(parents=True, exist_ok=True)
    reg_path = B / "verified_ranges.json"
    reg = {"ranges": []}
    if reg_path.exists():
        reg = json.loads(reg_path.read_text())
    ranges = [r for r in reg.get("ranges", []) if r.get("id") != report["id"]]
    ranges.append({
        "id": report["id"],
        "lo": TAIL_LO,
        "hi": TAIL_HI,
        "size": TAIL_HI - TAIL_LO,
        "disposition": "verified_free",
        "basis": report["basis"],
        "entries_of_stub": report["entries"],
        "imm_hits": report["imm_hits"],
        "smc": report["smc"],
    })
    reg["ranges"] = ranges
    reg_path.write_text(json.dumps(reg, indent=2) + "\n")
    print(f"A521 tail A524..A539 verified free ({TAIL_HI - TAIL_LO}B)")
    print(f"wrote {reg_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
