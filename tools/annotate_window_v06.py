#!/usr/bin/env python3
"""Annotate window 84D0..B257 by whole procedures and data objects.

Output: build/v06/window_entities.json

Each entity: bounds, size, entries, refs, addr deps, smc, keep/delete basis.
Unmarked bytes are listed as residual runs — their total size is NOT a proof
that placement is impossible.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(Path(__file__).resolve().parent / "vendor"))

from cfg_map_v06 import (  # noqa: E402
    WIN_HI,
    WIN_LO,
    cfg_reach,
    collect_seeds,
    data_refs_from_insns,
    expand_string_objects,
    find_smc_sites,
    load_mem,
    load_syms,
    load_xref_data_addrs,
    load_xref_seeds,
    runs_of,
    sha256,
    unsafe_after_jp_candidates,
)

B = ROOT / "build/v06"

# Known whole entities (game + native stubs) with manual disposition.
# Disposition is the *basis* for keep/delete — not a silent reclaim.
KNOWN = [
    {
        "id": "jump_table_84D0",
        "lo": 0x84D0,
        "hi": 0x84E8,
        "kind": "code_table",
        "entries": ["0x84D0"],
        "disposition": "keep",
        "basis": "game entry jump table; fixed addresses",
    },
    {
        "id": "native_jp_A521_stamp",
        "lo": 0xA521,
        "hi": 0xA53A,
        "kind": "stub_plus_dead_tail",
        "entries": ["0xA521"],
        "disposition": "keep_stub_reclaim_tail",
        "basis": "JP STAMP_B338 at A521..A523. Tail A524..A534 holds SET_VBLANK and BIOS_CLICK; A535..A539 still zero. Not an after-JP free list.",
    },
    {
        "id": "native_jp_A4A8_menu",
        "lo": 0xA4A8,
        "hi": 0xA4E7,
        "kind": "stub_plus_dead_tail",
        "entries": ["0xA4A8"],
        "disposition": "keep_stub_reclaim_tail",
        "basis": "JP MENU_FRAME_BEGIN; old body after JP unreachable",
    },
    {
        "id": "native_jp_B15F_sprite",
        "lo": 0xB15F,
        "hi": 0xB18E,
        "kind": "stub_plus_dead_tail",
        "entries": ["0xB15F"],
        "disposition": "keep_stub_reclaim_tail",
        "basis": "partial rewrite + JP DIRTY; NOP pad reclaimable",
    },
    {
        "id": "native_jp_B1F2_frame",
        "lo": 0xB1F2,
        "hi": 0xB1FE,
        "kind": "stub_plus_dead_tail",
        "entries": ["0xB1F2"],
        "disposition": "keep_stub_reclaim_tail",
        "basis": "JP FRAME_BEGIN + pad",
    },
    {
        "id": "msx_replay_entries",
        "lo": 0xA8C0,
        "hi": 0xA9C7,
        "kind": "mixed_stub_data_dead",
        "entries": ["0xA8C0", "0xA8C8", "0xA8F4", "0xA93C", "0xA8F9"],
        "disposition": "keep_entries_and_half_select",
        "basis": (
            "A8C8/A8F4/A93C are JP stubs to native replay; A8C0 CALL REPLAY_DONE; "
            "A8F9 half-select word is live data. Intervening old MSX body is "
            "CFG-unreachable but only the proven_dead_after_jumps subset is "
            "reclaimable without further xref proof."
        ),
    },
    {
        "id": "sprite_vars_B1DE",
        "lo": 0xB1DE,
        "hi": 0xB1E5,
        "kind": "data",
        "entries": [],
        "disposition": "keep",
        "basis": "B1_ROW/HEIGHT/COL/WIDTH/SKIP/STRIP work cells",
    },
]


def proc_entities_from_cfg(
    insns: dict[int, dict],
    code: set[int],
    call_entries: set[int],
) -> list[dict]:
    """Whole procedures: start at CALL/JP targets (and table seeds), follow
    fall-through until unconditional exit. Do not split on every internal label.
    """
    entries = sorted(e for e in call_entries if e in insns)
    used_insn: set[int] = set()
    procs: list[dict] = []

    for entry in entries:
        if entry in used_insn:
            continue
        pc = entry
        lo = entry
        hi = entry
        while pc in insns and WIN_LO <= pc < WIN_HI:
            info = insns[pc]
            used_insn.add(pc)
            hi = pc + info["len"]
            flow = info["flow"]
            if flow in ("jump", "ret", "dyn"):
                break
            pc = hi
            if pc in used_insn:
                break
        size = hi - lo
        if size <= 0:
            continue
        procs.append({
            "id": f"proc_{lo:04X}",
            "lo": lo,
            "hi": hi,
            "size": size,
            "kind": "procedure",
            "entries": [f"0x{lo:04X}"],
            "disposition": "keep",
            "basis": "CFG procedure from call/jp entry through fall-through",
        })

    # Contiguous CFG code runs not covered by a procedure → keep as code_run
    covered = set()
    for p in procs:
        covered.update(range(p["lo"], p["hi"]))
    for r in runs_of(code - covered, WIN_LO, WIN_HI):
        if r["size"] < 4:
            continue
        procs.append({
            "id": f"code_run_{r['start']:04X}",
            "lo": r["start"],
            "hi": r["end"] + 1,
            "size": r["size"],
            "kind": "code_run",
            "entries": [],
            "disposition": "keep",
            "basis": "CFG-reachable bytes not assigned to a call-entry procedure",
        })
    return procs


def main() -> int:
    if not (B / "basket.full.bin").exists():
        print("missing basket.full.bin", file=sys.stderr)
        return 1
    mem = load_mem()
    syms = load_syms()
    rom_sha = sha256(B / "basket.rom")
    xref_seeds, xref_used = load_xref_seeds(rom_sha)
    seeds = collect_seeds(mem, syms, xref_seeds)
    regions = [(0, 0x200), (0x200, 0xE00), (0x3304, 0x3F80), (WIN_LO, WIN_HI)]
    all_insns: dict[int, dict] = {}
    all_code: set[int] = set()
    for _ in range(8):
        before = len(seeds)
        for lo, hi in regions:
            part = cfg_reach(mem, seeds, lo, hi)
            all_code |= part["code_bytes"]
            all_insns.update(part["insns"])
            for pc, info in part["insns"].items():
                for t in info["targets"]:
                    seeds.add(t)
                if info["len"] >= 3 and mem[pc] in (0xCD, 0xC3):
                    seeds.add(mem[pc + 1] | mem[pc + 2] << 8)
        if len(seeds) == before:
            break

    win = cfg_reach(mem, seeds, WIN_LO, WIN_HI)
    win_code = win["code_bytes"]
    smc = find_smc_sites(mem, all_insns, all_code)
    abs_imms = set()
    absolute_operands = []
    call_entries: set[int] = set()
    for pc, info in all_insns.items():
        if info["len"] >= 3 and mem[pc] in (
            0xCD, 0xC3, 0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA,
            0xC4, 0xCC, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC,
            0x01, 0x11, 0x21, 0x31, 0x3A, 0x32, 0x2A, 0x22,
        ):
            imm = mem[pc + 1] | mem[pc + 2] << 8
            abs_imms.add(imm)
            opcode = mem[pc]
            if opcode in (0xCD, 0xC4, 0xCC, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC):
                kind = "call"
            elif opcode in (0xC3, 0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA):
                kind = "jump"
            elif opcode == 0x31:
                kind = "stack_pointer"
            else:
                kind = "data_address"
            if imm < 0x0200:
                target_class = "system"
            elif imm < 0x0E00:
                target_class = "adapter"
            elif 0x3304 <= imm < 0x3F80:
                target_class = "system_hud_region"
            elif imm < WIN_LO:
                target_class = "low_data_or_state"
            elif imm < WIN_HI:
                target_class = "game_window"
            elif imm < 0xC000:
                target_class = "gfx_or_runtime_buffer"
            elif imm < 0xE000:
                target_class = "video_plane_0"
            else:
                target_class = "visible_plane"
            absolute_operands.append({
                "pc": pc, "opcode": opcode, "target": imm,
                "kind": kind, "target_class": target_class,
            })
            if mem[pc] in (
                0xCD, 0xC3, 0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA,
                0xC4, 0xCC, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC,
            ):
                if WIN_LO <= imm < WIN_HI:
                    call_entries.add(imm)
    # Jump table + known game entry
    call_entries.add(0x84D0)
    call_entries |= {s for s in seeds if WIN_LO <= s < WIN_HI and s in win["insns"]}

    keep = set(abs_imms) | {s["target"] for s in smc} | {
        s for s in seeds if WIN_LO <= s < WIN_HI
    }
    data = data_refs_from_insns(mem, all_insns, all_code)
    keep |= data
    for a in list(data | abs_imms):
        if WIN_LO <= a < WIN_HI:
            keep.add(a)
            keep.add((a + 1) & 0xFFFF)
    xref_rd, xref_wr, xref_data_used = load_xref_data_addrs(rom_sha)
    keep |= (xref_rd | xref_wr) & set(range(WIN_LO, WIN_HI))
    keep |= expand_string_objects(mem, keep | {0xA798}, WIN_LO, WIN_HI)

    # After-JP heuristic REVOKED — audit only, never placeable.
    unsafe_jp = unsafe_after_jp_candidates(win["insns"], win_code, WIN_LO, WIN_HI)
    proven_dead: set[int] = set()

    entities = []
    for k in KNOWN:
        ent = dict(k)
        ent["size"] = ent["hi"] - ent["lo"]
        # Stubs: keep entry; tails are NOT proven free
        if ent.get("disposition") == "keep_stub_reclaim_tail":
            ent["disposition"] = "keep_stub_tail_unproven"
            ent["basis"] = (
                ent.get("basis", "")
                + " | after-JP reclaim REVOKED (xref may touch tails)"
            )
        ent["smc"] = [
            {"pc": f"{s['pc']:04X}", "target": f"{s['target']:04X}"}
            for s in smc
            if ent["lo"] <= s["pc"] < ent["hi"] or ent["lo"] <= s["target"] < ent["hi"]
        ]
        ent["unsafe_after_jp_bytes_inside"] = sum(
            1 for a in range(ent["lo"], ent["hi"]) if a in unsafe_jp
        )
        entities.append(ent)

    # Explicit menu-text entity (was false-positive "free")
    entities.append({
        "id": "menu_text_A795",
        "lo": 0xA795,
        "hi": 0xA7F2,
        "size": 0xA7F2 - 0xA795,
        "kind": "data_string",
        "entries": [],
        "disposition": "keep",
        "basis": "Menu ASCII at A798 ('1 PLAYER'/'2 PLAYERS'); after-JP false positive",
        "smc": [],
    })

    for p in proc_entities_from_cfg(win["insns"], win_code, call_entries):
        if p["size"] < 8:
            continue
        if any(k["lo"] <= p["lo"] and p["hi"] <= k["hi"] for k in KNOWN):
            continue
        p["smc"] = [
            {"pc": f"{s['pc']:04X}", "target": f"{s['target']:04X}"}
            for s in smc
            if p["lo"] <= s["pc"] < p["hi"] or p["lo"] <= s["target"] < p["hi"]
        ]
        entities.append(p)

    marked = set()
    for e in entities:
        for a in range(e["lo"], min(e["hi"], WIN_HI)):
            if a >= WIN_LO:
                marked.add(a)
    for a in win_code:
        marked.add(a)
    for a in keep:
        if WIN_LO <= a < WIN_HI:
            marked.add(a)

    residual = runs_of(set(range(WIN_LO, WIN_HI)) - marked, WIN_LO, WIN_HI)
    for r in residual:
        if r["size"] < 16:
            continue
        entities.append({
            "id": f"unknown_{r['start']:04X}",
            "lo": r["start"],
            "hi": r["end"] + 1,
            "size": r["size"],
            "kind": "unknown",
            "entries": [],
            "disposition": "keep_until_proven",
            "basis": "Not CFG code; cold ≠ dead; xref absence ≠ unused",
            "smc": [],
        })

    out = {
        "rom_sha256": rom_sha,
        "window": {"lo": WIN_LO, "hi": WIN_HI, "size": WIN_HI - WIN_LO},
        "xref_used": xref_used,
        "xref_data_traces": xref_data_used,
        "cfg_code_bytes": len(win_code),
        "data_keep_bytes": len([a for a in keep if WIN_LO <= a < WIN_HI and a not in win_code]),
        "proven_dead_bytes": 0,
        "proven_dead_runs": [],
        "unsafe_after_jp_bytes": len(unsafe_jp),
        "unsafe_after_jp_xref_rd": len(unsafe_jp & xref_rd),
        "unsafe_after_jp_xref_wr": len(unsafe_jp & xref_wr),
        "smc_count": len(smc),
        "absolute_operand_count": len(absolute_operands),
        "absolute_operands": absolute_operands,
        "absolute_operand_classes": {
            cls: sum(1 for ref in absolute_operands if ref["target_class"] == cls)
            for cls in sorted({ref["target_class"] for ref in absolute_operands})
        },
        "entity_count": len(entities),
        "entities": entities,
        "residual_unmarked_runs": [r for r in residual if r["size"] < 16][:40],
        "residual_unmarked_bytes": sum(r["size"] for r in residual),
        "note": (
            "proven_deletable revoked (after-JP). Place code only on verified "
            "whole entities. residual unmarked is incomplete markup, not free."
        ),
    }
    B.mkdir(parents=True, exist_ok=True)
    (B / "window_entities.json").write_text(json.dumps(out, indent=2) + "\n")
    print(f"entities={len(entities)} cfg_code={len(win_code)} "
          f"data_keep={out['data_keep_bytes']} proven_dead=0 "
          f"unsafe_jp={out['unsafe_after_jp_bytes']} "
          f"(xref_rd={out['unsafe_after_jp_xref_rd']}) residual={out['residual_unmarked_bytes']}")
    print(f"wrote {B / 'window_entities.json'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
