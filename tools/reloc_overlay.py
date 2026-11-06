#!/usr/bin/env python3
"""Relocate the MSX Executive overlay for Vector-06C.

Takes the full overlay (84D0..DD18) and relocates absolute addresses by a
fixed delta (-0x74D0 for 1000 target), producing a binary suitable for the
V06 memory map:
  1000..6848  game overlay (relocated from 84D0..DD18)
  8000..BFFF  soft VRAM 16KB
  E000..FFFF  visible Vector plane (mono)

APPROACH: We use the Z80 disassembler to identify code vs. data regions,
then patch:
  - JP/CALL/JR targets within overlay range
  - 16-bit immediate loads (LD HL/DE/BC/SP,nn) pointing into overlay
  - Direct memory refs (LD A,(nn) / LD (nn),A / LD HL,(nn) / etc.)

OUT 98/99 and IN A,(99) are separately handled by the adapter (port hooks).
"""

from __future__ import annotations
import argparse
import json
import os
import sys
from pathlib import Path
from dataclasses import dataclass, field
from typing import Optional

ROOT = Path(__file__).resolve().parents[1]
SPIRITS = Path(os.environ.get("SPIRITS_V06C", str(Path.home() / "projects/spirits-v06c")))
sys.path.insert(0, str(SPIRITS / "tools" / "vendor"))
from z80dis import decode  # noqa: E402

# Original overlay range
ORIG_BASE = 0x84D0
ORIG_END = 0xDD18  # inclusive last byte is DD17, length 22601

# Target base for relocation
TARGET_BASE = 0x1000
DELTA = TARGET_BASE - ORIG_BASE  # -0x74D0 = -29904


@dataclass
class Patch:
    offset: int      # offset in overlay
    orig_addr: int   # original 16-bit address
    new_addr: int    # relocated address
    kind: str        # 'jp', 'call', 'ld16', 'mem', etc.


def in_overlay(addr: int) -> bool:
    """Check if address is within original overlay range."""
    return ORIG_BASE <= addr <= ORIG_END


def relocate_if_needed(addr: int) -> int:
    """Relocate address if it points into overlay range."""
    if in_overlay(addr):
        return addr + DELTA
    return addr


def find_reachable_code(mem: bytearray, base: int, end: int, entry: int) -> dict[int, object]:
    """Find reachable instructions via CFG, seeded with jump table + CALL/JP targets."""
    code: dict[int, object] = {}
    covered: set[int] = set()  # all bytes belonging to decoded insns
    pending = [entry]

    for offset in range(0, 0x30, 3):
        addr = base + offset
        if addr + 2 < end and mem[addr] == 0xC3:
            target = mem[addr + 1] | (mem[addr + 2] << 8)
            if in_overlay(target):
                pending.append(target)

    # Seed CALL/JP targets (not call sites — sites are reached via flow)
    for addr in range(base, end - 2):
        op = mem[addr]
        if op in (0xCD, 0xC3, 0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA):
            target = mem[addr + 1] | (mem[addr + 2] << 8)
            if in_overlay(target):
                pending.append(target)

    for abs_addr in (0xCF08, 0xD358, 0xD241, 0xA0A1, 0x84E8, 0x84F0):
        if in_overlay(abs_addr):
            pending.append(abs_addr)

    while pending:
        pc = pending.pop()
        if pc in code or pc in covered or not base <= pc < end:
            continue
        while base <= pc < end and pc not in code and pc not in covered:
            try:
                ins = decode(mem[pc:], pc)
            except Exception:
                break
            if pc + ins.length > end:
                break
            # Reject if any byte already covered (mid-insn alias)
            if any((pc + k) in covered for k in range(ins.length)):
                break
            code[pc] = ins
            for k in range(ins.length):
                covered.add(pc + k)
            for target in getattr(ins, "targets", []) or []:
                if base <= target < end:
                    pending.append(target)
            if hasattr(ins, "operand") and ins.operand is not None:
                if base <= ins.operand < end:
                    pending.append(ins.operand)

            # Stop fall-through on unconditional transfers
            op = mem[pc]
            if op in (0xC9, 0xC3, 0x18, 0xE9, 0x76):  # ret, jp nn, jr d, jp (hl), halt
                break
            pc += ins.length
    return code


def linear_patch_abs_ops(out: bytearray, protected: set[int], patches: list[Patch]) -> None:
    """Brute-force patch absolute address operands for common Z80 opcodes.

    This catches code the CFG missed (data-looking tails that are still code).
    Skips I/O-protected offsets.
    """
    i = 0
    n = len(out)
    while i < n - 2:
        if i in protected or (i + 1) in protected:
            i += 1
            continue
        op = out[i]

        def patch_at(imm_off: int, kind: str) -> None:
            if imm_off in protected or (imm_off + 1) in protected:
                return
            imm = out[imm_off] | (out[imm_off + 1] << 8)
            if in_overlay(imm):
                new_addr = relocate_if_needed(imm)
                if new_addr != imm:
                    patches.append(Patch(imm_off, imm, new_addr, kind))
                    out[imm_off] = new_addr & 0xFF
                    out[imm_off + 1] = (new_addr >> 8) & 0xFF

        # CALL nn / JP nn / conditional JP nn
        if op in (0xCD, 0xC3, 0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA):
            patch_at(i + 1, "lin_jpcall")
            i += 3
            continue
        # LD BC/DE/HL/SP,nn
        if op in (0x01, 0x11, 0x21, 0x31):
            patch_at(i + 1, "lin_ld16")
            i += 3
            continue
        # LD A,(nn) / LD (nn),A / LD HL,(nn) / LD (nn),HL
        if op in (0x3A, 0x32, 0x2A, 0x22):
            patch_at(i + 1, "lin_mem")
            i += 3
            continue
        # ED-prefixed 16-bit mem
        if op == 0xED and i + 3 < n:
            ed = out[i + 1]
            if ed in (0x43, 0x53, 0x63, 0x73, 0x4B, 0x5B, 0x6B, 0x7B):
                patch_at(i + 2, "lin_ed")
                i += 4
                continue
        i += 1


def find_io_protected_offsets(payload: bytes) -> set[int]:
    """Protect only VDP port I/O: OUT/IN 98h and 99h.

    Do NOT protect every 0xD3/0xDB — those appear as high bytes of overlay
    addresses (CALL D358 = CD 58 D3) and must stay relocatable.
    """
    protected: set[int] = set()
    for i in range(len(payload) - 1):
        if payload[i] in (0xD3, 0xDB) and payload[i + 1] in (0x98, 0x99):
            protected.add(i)
            protected.add(i + 1)
    return protected


# MSX work/system RAM below the overlay; on Vector it collides with relocated game.
# Include 4000..4159 (Dinamic cursor/vars just below the 415A block).
WORK_OLD_LO, WORK_OLD_HI = 0x4000, 0x7FBF
WORK_NEW_BASE = 0xA000
WORK_DELTA = WORK_NEW_BASE - WORK_OLD_LO  # +0x6000


def remap_work_ram(out: bytearray, patches: list[Patch], code: dict[int, object]) -> int:
    """Remap 4000..7FBF → A000.. on the ORIGINAL overlay (before 84D0→1000).

    Must run before overlay reloc: after reloc, game code lives at 1000..6848
    which overlaps 4000..7FBF and would be mistaken for work RAM.
    """
    abs_ops = {
        0xCD, 0xC3, 0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA,
        0x01, 0x11, 0x21, 0x31, 0x3A, 0x32, 0x2A, 0x22,
    }
    done: set[int] = set()
    n = 0

    def patch_imm(imm_off: int, imm: int) -> None:
        nonlocal n
        if imm_off in done:
            return
        if not (WORK_OLD_LO <= imm <= WORK_OLD_HI):
            return
        new_addr = imm + WORK_DELTA
        out[imm_off] = new_addr & 0xFF
        out[imm_off + 1] = (new_addr >> 8) & 0xFF
        patches.append(Patch(imm_off, imm, new_addr, "work_ram"))
        done.add(imm_off)
        n += 1

    # Prefer CFG instruction boundaries
    for pc, ins in code.items():
        offset = pc - ORIG_BASE
        if offset < 0 or offset >= len(out):
            continue
        op = out[offset]
        if op in abs_ops and offset + 2 < len(out):
            imm = out[offset + 1] | (out[offset + 2] << 8)
            patch_imm(offset + 1, imm)
        elif op == 0xED and offset + 3 < len(out):
            ed = out[offset + 1]
            if ed in (0x43, 0x53, 0x63, 0x73, 0x4B, 0x5B, 0x6B, 0x7B):
                imm = out[offset + 2] | (out[offset + 3] << 8)
                patch_imm(offset + 2, imm)

    # Linear sweep for LD/mem only (not CALL/JP — those to 5xxx after reloc
    # are game code; on original CALL into work RAM is rare and CFG catches it)
    i = 0
    while i < len(out) - 2:
        if i + 1 in done:
            i += 1
            continue
        op = out[i]
        if op in (0x01, 0x11, 0x21, 0x31, 0x3A, 0x32, 0x2A, 0x22):
            imm = out[i + 1] | (out[i + 2] << 8)
            patch_imm(i + 1, imm)
            i += 3
            continue
        if op == 0xED and i + 3 < len(out):
            ed = out[i + 1]
            if ed in (0x43, 0x53, 0x63, 0x73, 0x4B, 0x5B, 0x6B, 0x7B):
                imm = out[i + 2] | (out[i + 3] << 8)
                patch_imm(i + 2, imm)
                i += 4
                continue
        i += 1

    if n:
        print(f"  Work RAM remap 4000..7FBF → A000.. (+{WORK_DELTA:04X}): {n} patches")
    return n


def analyze_and_patch(payload: bytes, verbose: bool = False) -> tuple[bytes, list[Patch]]:
    """Analyze overlay and create relocated version."""
    mem = bytearray(0x10000)
    mem[ORIG_BASE:ORIG_BASE + len(payload)] = payload
    
    end_addr = ORIG_BASE + len(payload)
    entry = ORIG_BASE
    
    io_protected = find_io_protected_offsets(payload)
    if verbose:
        print(f"Protected I/O offsets: {len(io_protected)} bytes")
    
    code = find_reachable_code(mem, ORIG_BASE, end_addr, entry)
    if verbose:
        print(f"Found {len(code)} reachable instructions")
    
    patches: list[Patch] = []
    out = bytearray(payload)

    # BEFORE overlay reloc — unambiguous 415A..7FBF vs game at 84D0+
    remap_work_ram(out, patches, code)

    patched_ops: set[int] = set()
    # Work-RAM targets land in A000.. (inside original overlay span 84D0..DD18).
    # Freeze those immediates so overlay reloc does not apply DELTA again
    # (A000+DELTA = 2B30 would destroy the remap).
    for p in patches:
        if p.kind == "work_ram":
            patched_ops.add(p.offset)
            patched_ops.add(p.offset + 1)

    occupied: set[int] = set(io_protected)

    # Mark every byte of every CFG-decoded instruction as occupied for linear sweep
    # (prevents mid-instruction aliases like CA inside LD (nn),A)
    for pc, ins in code.items():
        offset = pc - ORIG_BASE
        for k in range(ins.length):
            occupied.add(offset + k)

    def try_patch(imm_off: int, imm: int, kind: str) -> bool:
        if not in_overlay(imm):
            return False
        if imm_off in patched_ops or (imm_off + 1) in patched_ops:
            return False
        if imm_off in io_protected or (imm_off + 1) in io_protected:
            return False
        new_addr = relocate_if_needed(imm)
        if new_addr == imm:
            return False
        patches.append(Patch(imm_off, imm, new_addr, kind))
        out[imm_off] = new_addr & 0xFF
        out[imm_off + 1] = (new_addr >> 8) & 0xFF
        patched_ops.add(imm_off)
        patched_ops.add(imm_off + 1)
        return True

    # Pass 1: absolute JP/CALL only (highest confidence)
    for pc, ins in sorted(code.items()):
        offset = pc - ORIG_BASE
        opcode = out[offset]
        if opcode in (0xC3, 0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA, 0xCD):
            if ins.operand is not None:
                try_patch(offset + 1, ins.operand, ins.flow)

    # Pass 2: LD rr,nn and direct mem ops — verify opcode still matches
    for pc, ins in sorted(code.items()):
        offset = pc - ORIG_BASE
        opcode = out[offset]
        if opcode in (0x01, 0x11, 0x21, 0x31):
            imm = out[offset + 1] | (out[offset + 2] << 8)
            try_patch(offset + 1, imm, "ld16")
        elif opcode in (0x3A, 0x32, 0x2A, 0x22):
            imm = out[offset + 1] | (out[offset + 2] << 8)
            try_patch(offset + 1, imm, "mem")
        elif opcode == 0xED and offset + 3 < len(out):
            ed_op = out[offset + 1]
            if ed_op in (0x43, 0x53, 0x63, 0x73, 0x4B, 0x5B, 0x6B, 0x7B):
                imm = out[offset + 2] | (out[offset + 3] << 8)
                try_patch(offset + 2, imm, "ed_mem")

    # Pass 3: linear sweep for JP/CALL/LD the CFG missed — skip occupied
    before = len(patches)
    i = 0
    n = len(out)
    while i < n - 2:
        if i in occupied:
            i += 1
            continue
        op = out[i]
        if op in (0xC3, 0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA, 0xCD):
            imm = out[i + 1] | (out[i + 2] << 8)
            if try_patch(i + 1, imm, "lin_jpcall"):
                i += 3
                continue
        elif op in (0x01, 0x11, 0x21, 0x31):
            imm = out[i + 1] | (out[i + 2] << 8)
            if try_patch(i + 1, imm, "lin_ld16"):
                i += 3
                continue
        elif op in (0x3A, 0x32, 0x2A, 0x22):
            imm = out[i + 1] | (out[i + 2] << 8)
            if try_patch(i + 1, imm, "lin_mem"):
                i += 3
                continue
        elif op == 0xED and i + 3 < n:
            ed = out[i + 1]
            if ed in (0x43, 0x53, 0x63, 0x73, 0x4B, 0x5B, 0x6B, 0x7B):
                imm = out[i + 2] | (out[i + 3] << 8)
                if try_patch(i + 2, imm, "lin_ed"):
                    i += 4
                    continue
        i += 1
    if verbose:
        print(f"Linear sweep added {len(patches) - before} patches")

    patch_cf08_scratch(out, patches, occupied, patched_ops)

    if verbose:
        print(f"Total patches: {len(patches)}")

    return bytes(out), patches


def patch_cf08_scratch(
    out: bytearray,
    patches: list[Patch],
    occupied: set[int],
    patched_ops: set[int] | None = None,
) -> None:
    """Fix CF08 staging routine: relocate any leftover abs addrs + scratch 0007→6900.

    Staging buffer is 0x0B40 bytes; 6900..7440 sits after the relocated game
    (ends ~6848) and below the stack at 7F00 / soft VRAM at 8000. Do NOT use
    C000 — that overlaps work RAM remapped to A000..DE5F.
    """
    if patched_ops is None:
        patched_ops = set()
    SCRATCH = 0x6900
    cf08_off = 0xCF08 - ORIG_BASE
    end = min(cf08_off + 0xA0, len(out) - 2)
    i = cf08_off
    while i < end:
        op = out[i]
        if op in (0xCD, 0xC3, 0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA,
                  0x01, 0x11, 0x21, 0x31, 0x3A, 0x32, 0x2A, 0x22):
            imm_off = i + 1
            imm = out[i + 1] | (out[i + 2] << 8)
            # Skip only immediates already remapped to work RAM (by offset),
            # NOT by numeric range — A000..DE5F overlaps overlay code (e.g. CF46).
            if imm_off in patched_ops:
                i += 3
                continue
            if in_overlay(imm):
                new_addr = imm + DELTA
                out[i + 1] = new_addr & 0xFF
                out[i + 2] = (new_addr >> 8) & 0xFF
                patches.append(Patch(i + 1, imm, new_addr, "cf08_force"))
                print(f"  CF08 force: {ORIG_BASE + i:04X} {imm:04X} → {new_addr:04X}")
            elif imm == 0x0007 and op in (0x11, 0x21):
                out[i + 1] = SCRATCH & 0xFF
                out[i + 2] = (SCRATCH >> 8) & 0xFF
                patches.append(Patch(i + 1, 0x0007, SCRATCH, "cf08_scratch"))
                print(f"  CF08 scratch: LD {'DE' if op == 0x11 else 'HL'},0007 → {SCRATCH:04X}")
            elif imm == 0xC000 and op in (0x11, 0x21):
                out[i + 1] = SCRATCH & 0xFF
                out[i + 2] = (SCRATCH >> 8) & 0xFF
                patches.append(Patch(i + 1, 0xC000, SCRATCH, "cf08_scratch"))
                print(f"  CF08 scratch: LD {'DE' if op == 0x11 else 'HL'},C000 → {SCRATCH:04X}")
            i += 3
            continue
        i += 1

    # D358: LD SP,F55C → 7F00 (outside CF08 window)
    for i in range(len(out) - 2):
        if out[i] == 0x31 and out[i + 1] == 0x5C and out[i + 2] == 0xF5:
            out[i + 1] = 0x00
            out[i + 2] = 0x7F
            patches.append(Patch(i + 1, 0xF55C, 0x7F00, "stack_reloc"))
            print(f"  LD SP,F55C → 7F00 at off {i:04X}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Relocate MSX overlay for V06")
    parser.add_argument("-i", "--input", type=Path, 
                        default=ROOT / "ref/msx/executive/executive.overlay.bin")
    parser.add_argument("-o", "--output", type=Path,
                        default=ROOT / "build/v06/game.bin")
    parser.add_argument("-m", "--map", type=Path,
                        default=ROOT / "build/v06/reloc_map.json")
    parser.add_argument("-v", "--verbose", action="store_true")
    args = parser.parse_args()
    
    payload = args.input.read_bytes()
    print(f"Input: {args.input} ({len(payload)} bytes)")
    print(f"Original range: {ORIG_BASE:04X}..{ORIG_BASE + len(payload) - 1:04X}")
    print(f"Target range: {TARGET_BASE:04X}..{TARGET_BASE + len(payload) - 1:04X}")
    print(f"Delta: {DELTA:+d} (0x{DELTA & 0xFFFF:04X})")
    
    relocated, patches = analyze_and_patch(payload, args.verbose)
    
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(relocated)
    print(f"Output: {args.output} ({len(relocated)} bytes)")
    
    # Write relocation map
    map_data = {
        "orig_base": ORIG_BASE,
        "target_base": TARGET_BASE,
        "delta": DELTA,
        "size": len(payload),
        "patches": [
            {"offset": p.offset, "orig": p.orig_addr, "new": p.new_addr, "kind": p.kind}
            for p in patches
        ],
        "key_addresses": {
            "GAME_ENTRY": TARGET_BASE,  # was 84D0
            "D358_relocated": 0xD358 + DELTA,  # VDP status check routine
            "CF08_relocated": 0xCF08 + DELTA,  # VDP upload routine
        }
    }
    args.map.write_text(json.dumps(map_data, indent=2))
    print(f"Relocation map: {args.map}")
    
    # Summary
    by_kind = {}
    for p in patches:
        by_kind[p.kind] = by_kind.get(p.kind, 0) + 1
    print(f"Patches by type: {by_kind}")
    
    # Verify I/O instruction preservation
    def count_io(data: bytes) -> dict:
        counts = {"out98": 0, "out99": 0, "in98": 0, "in99": 0}
        for i in range(len(data) - 1):
            if data[i] == 0xD3 and data[i + 1] == 0x98:
                counts["out98"] += 1
            elif data[i] == 0xD3 and data[i + 1] == 0x99:
                counts["out99"] += 1
            elif data[i] == 0xDB and data[i + 1] == 0x98:
                counts["in98"] += 1
            elif data[i] == 0xDB and data[i + 1] == 0x99:
                counts["in99"] += 1
        return counts
    
    orig_io = count_io(payload)
    reloc_io = count_io(relocated)
    print(f"I/O instruction verification:")
    print(f"  Original: OUT98={orig_io['out98']} OUT99={orig_io['out99']} IN98={orig_io['in98']} IN99={orig_io['in99']}")
    print(f"  Relocated: OUT98={reloc_io['out98']} OUT99={reloc_io['out99']} IN98={reloc_io['in98']} IN99={reloc_io['in99']}")
    
    if orig_io != reloc_io:
        print("  ERROR: I/O instruction counts do not match!")
        return 1
    else:
        print("  OK: All I/O instructions preserved")
    
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
