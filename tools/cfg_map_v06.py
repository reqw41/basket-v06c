#!/usr/bin/env python3
"""CFG occupancy map for consolidation budgeting.

Uses spirits z80dis (full Z80 decoder: length, flow, targets). Marks EVERY
byte of every reached instruction. Does not treat linear decode through
mixed memory as proof of instruction starts.

Seeds:
  - boot 0100, RST/BIOS stubs, native JP stubs
  - game entry 84D0 + jump table 84D0..84E7
  - known ISR / adapter symbols from glue.lst
  - CALL/JP targets discovered only from already-decoded instructions
  - optional xref_* JSON bound to baseline.json rom_sha256 (exec PCs only
    as additional seeds — never as sole live proof)

Unknown/indirect (JP HL, SMCed JP slots, etc.): containing block kept and
listed under uncertainty.

REVOKED: treating bytes after unconditional JP as proven_deletable. Those
regions include live strings (A798 menu), work RAM (93F6/9417), and xref
touches — never place code there from that heuristic alone.

Output: build/v06/cfg_map.json + stdout summary.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from collections import defaultdict, deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
B = ROOT / "build/v06"
sys.path.insert(0, str(Path(__file__).resolve().parent / "vendor"))
from z80dis import decode  # noqa: E402

WIN_LO, WIN_HI = 0x84D0, 0xB258
D_LO, D_HI = 0x3304, 0x3F80
ADAPT_LO, ADAPT_HI_CAP = 0x0200, 0x0E00
CAPACITY = WIN_HI - WIN_LO


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_mem() -> bytearray:
    full = B / "basket.full.bin"
    mem = bytearray(full.read_bytes()[:0x10000])
    if len(mem) < 0x10000:
        mem.extend(bytes(0x10000 - len(mem)))
    return mem


def load_syms() -> dict[str, int]:
    syms = {}
    for line in (B / "glue.lst").read_text(errors="replace").splitlines():
        m = re.match(r"([A-Za-z_][A-Za-z0-9_]*)\s+=\s+\$([0-9A-Fa-f]+)", line)
        if m:
            syms[m.group(1)] = int(m.group(2), 16)
    return syms


def load_baseline() -> dict | None:
    p = B / "baseline.json"
    return json.loads(p.read_text()) if p.exists() else None


def load_xref_seeds(rom_sha: str) -> tuple[set[int], list[dict]]:
    """Load exec PCs from xref files that declare matching rom_sha256."""
    seeds: set[int] = set()
    used = []
    for f in sorted(B.glob("xref_*.json")):
        if f.name.endswith(".meta.json") or ".meta." in f.name:
            continue
        meta_path = Path(str(f)[: -len(".json")] + ".meta.json")
        if not meta_path.exists():
            # also try xref_name.meta.json beside xref_name.json
            meta_path = f.with_name(f.stem + ".meta.json")
        if not meta_path.exists():
            used.append({"file": f.name, "status": "skipped_no_meta"})
            continue
        meta = json.loads(meta_path.read_text())
        if meta.get("rom_sha256") != rom_sha:
            used.append({"file": f.name, "status": "skipped_sha_mismatch",
                         "meta_sha": meta.get("rom_sha256")})
            continue
        x = json.loads(f.read_text())
        for pc in x.get("exec", []):
            seeds.add(int(pc))
        used.append({"file": f.name, "status": "ok", "scenario": meta.get("scenario"),
                     "exec": len(x.get("exec", []))})
    return seeds, used


def cfg_reach(mem: bytearray, seeds: set[int], lo: int, hi: int) -> dict:
    """Reachability inside [lo,hi). Marks EVERY byte of each reached insn.

    Flow handling (z80dis):
      jump     — unconditional JP/JR: stop fall-through
      ret      — unconditional RET (fmt=='ret'): stop; conditional RET
                 (fmt starts with 'ret ') continues (cret)
      halt     — continue after HALT (IRQ can resume)
      dyn      — JP (HL)/etc: record uncertainty, stop fall-through
      call     — follow target; also fall through (incl. CALL cc)
      cjump    — follow target; also fall through
      cont     — fall through
    """
    code_bytes: set[int] = set()
    insns: dict[int, dict] = {}
    dyn: list[int] = []
    cret: list[int] = []
    halt_sites: list[int] = []
    pending: deque[int] = deque(sorted(s for s in seeds if lo <= s < hi))
    seen_entry: set[int] = set()

    while pending:
        pc = pending.popleft()
        if pc in seen_entry:
            continue
        if not (lo <= pc < hi):
            continue
        seen_entry.add(pc)

        while lo <= pc < hi and pc not in code_bytes:
            try:
                ins = decode(mem[pc:], pc)
            except Exception:
                break
            if ins.length <= 0 or pc + ins.length > hi:
                break
            if any((pc + k) in code_bytes for k in range(ins.length)):
                break
            for k in range(ins.length):
                code_bytes.add(pc + k)

            flow = ins.flow
            fmt = ins.fmt or ""
            # z80dis labels both RET and RET cc as flow='ret'; distinguish by fmt.
            is_cret = flow == "ret" and fmt.startswith("ret ")
            is_uret = flow == "ret" and fmt == "ret"

            insns[pc] = {
                "len": ins.length,
                "flow": "cret" if is_cret else flow,
                "fmt": fmt,
                "targets": list(ins.targets or []),
            }
            for t in ins.targets or []:
                if lo <= t < hi:
                    pending.append(t)

            if flow == "dyn":
                dyn.append(pc)
                break
            if flow == "halt":
                halt_sites.append(pc)
                pc += ins.length
                continue
            if is_uret or flow == "jump":
                break
            if is_cret:
                cret.append(pc)
                pc += ins.length
                continue
            # call, cjump, cont — fall through
            pc += ins.length

    return {
        "code_bytes": code_bytes,
        "insns": insns,
        "dyn": dyn,
        "cret": cret,
        "halt": halt_sites,
        "entries": sorted(seen_entry),
    }


def collect_seeds(mem: bytearray, syms: dict[str, int], xref_seeds: set[int]) -> set[int]:
    seeds = set()
    # Boot / RST / BIOS / native stubs
    for a in (
        0x0000, 0x0008, 0x0010, 0x0018, 0x0020, 0x0028, 0x0038,
        0x0100, 0x01E0, 0x01E3, 0x01E6, 0x01E9, 0x01EC, 0x01EF,
        0x01F2, 0x01F5, 0x01F8, 0x01FB,
    ):
        seeds.add(a)
    for name in (
        "ADAPTER_INIT", "IRQ_HANDLER", "SOFTVDP_OUT98", "SOFTVDP_OUT99",
        "SOFTVDP_IN98", "SOFTVDP_IN99", "FRAME_BEGIN", "FRAME_END",
        "FRAME_RESET", "SPRITE_ROWS", "SPRITE_OR",
        "MENU_FRAME_BEGIN", "TITLE_RELOAD", "V_KBD_POLL", "V_SND_TICK",
        "REPLAY_ZOOM", "REPLAY_STAMP", "REPLAY_DONE", "SKIP_OLD_GO",
        "BIOS_SNSMAT", "BIOS_GTSTCK", "BIOS_GTTRIG", "BIOS_WRTPSG",
        "BIOS_OUTDO",
    ):
        if name in syms:
            seeds.add(syms[name])
    # Game
    seeds.add(0x84D0)
    seeds.add(0x84E8)
    seeds.add(0x8508)
    # Jump table at 84D0: sequence of JP nn (C3 lo hi)
    a = 0x84D0
    while a < 0x84E8 and mem[a] == 0xC3:
        t = mem[a + 1] | mem[a + 2] << 8
        seeds.add(a)
        seeds.add(t)
        a += 3
    # D-region common entries (static known)
    for a in (0x35C0, 0x36F3, 0x3846, 0x3B53, 0x34BA, 0x37CC, 0x3811, 0x398C, 0x39A3):
        seeds.add(a)
    seeds |= xref_seeds
    return seeds


def expand_seeds_from_code(mem: bytearray, code_regions: list[tuple[int, int]], seeds: set[int]) -> set[int]:
    """After a CFG pass, harvest CALL/JP targets into any region as new seeds."""
    more = set()
    for lo, hi in code_regions:
        pc = lo
        # Only walk at known insn starts inside already-built maps — caller passes
        # insn PCs via seeds iteration instead.
        pass
    return more


def data_refs_from_insns(mem: bytearray, insns: dict[int, dict], code: set[int]) -> set[int]:
    """Absolute mem operands → data keep set (full object cells, not single bytes).

    LD A,(nn) / LD (nn),A  → nn
    LD HL,(nn) / LD (nn),HL / LD rr,(nn) / LD (nn),rr → nn and nn+1
    LD rr,nn immediate used as address-like (≥0x4000) → nn (base; caller may expand)
    """
    data = set()
    for pc, info in insns.items():
        op = mem[pc]
        if op in (0x3A, 0x32) and info["len"] >= 3:  # LD A,(nn) / LD (nn),A
            imm = mem[pc + 1] | mem[pc + 2] << 8
            data.add(imm)
        if op in (0x2A, 0x22) and info["len"] >= 3:  # LD HL,(nn) / LD (nn),HL
            imm = mem[pc + 1] | mem[pc + 2] << 8
            data.add(imm)
            data.add((imm + 1) & 0xFFFF)
        if op in (0x01, 0x11, 0x21, 0x31) and info["len"] >= 3:  # LD rr,nn
            imm = mem[pc + 1] | mem[pc + 2] << 8
            if imm >= 0x4000:  # likely pointer/table, not a small counter
                data.add(imm)
        if op == 0xED and info["len"] >= 4:
            ed = mem[pc + 1]
            if ed in (0x43, 0x53, 0x63, 0x73, 0x4B, 0x5B, 0x6B, 0x7B):
                imm = mem[pc + 2] | mem[pc + 3] << 8
                data.add(imm)
                data.add((imm + 1) & 0xFFFF)
    return data


def expand_string_objects(mem: bytearray, seeds: set[int], lo: int, hi: int) -> set[int]:
    """Grow printable / menu-text objects from any seed byte inside [lo,hi)."""
    keep = set()
    for s in seeds:
        if not (lo <= s < hi):
            continue
        # scan left to object start
        a = s
        while a > lo and _is_textish(mem[a - 1]):
            a -= 1
        b = s
        while b < hi and _is_textish(mem[b]):
            b += 1
        # include a trailing 0xFF menu separator if present (MSX menu encoding)
        if b < hi and mem[b] == 0xFF:
            b += 1
        for x in range(a, b):
            keep.add(x)
    return keep


def _is_textish(b: int) -> bool:
    return b in (0x20, 0xFF) or 0x30 <= b <= 0x39 or 0x41 <= b <= 0x5A or 0x61 <= b <= 0x7A


def load_xref_data_addrs(rom_sha: str) -> tuple[set[int], set[int], list[dict]]:
    """Collect rd/wr addresses from SHA-matched xref traces (not proof of unused)."""
    rd: set[int] = set()
    wr: set[int] = set()
    used = []
    for f in sorted(B.glob("xref_*.json")):
        if f.name.endswith(".meta.json") or "summary" in f.name:
            continue
        meta_path = f.with_name(f.stem + ".meta.json")
        if not meta_path.exists():
            used.append({"file": f.name, "status": "skipped_no_meta"})
            continue
        meta = json.loads(meta_path.read_text())
        if meta.get("rom_sha256") != rom_sha:
            used.append({"file": f.name, "status": "skipped_sha_mismatch"})
            continue
        x = json.loads(f.read_text())
        for a in x.get("rd", {}):
            rd.add(int(a))
        for a in x.get("wr", {}):
            wr.add(int(a))
        used.append({
            "file": f.name,
            "status": "ok",
            "rd": len(x.get("rd", {})),
            "wr": len(x.get("wr", {})),
        })
    return rd, wr, used


def find_smc_sites(mem: bytearray, insns: dict[int, dict], code: set[int]) -> list[dict]:
    """Absolute stores whose target overlaps CFG code bytes → SMC uncertainty."""
    sites = []
    for pc, info in insns.items():
        op = mem[pc]
        targets: list[int] = []
        if op in (0x32, 0x22) and info["len"] >= 3:  # LD (nn),A / LD (nn),HL
            imm = mem[pc + 1] | mem[pc + 2] << 8
            targets = [imm] if op == 0x32 else [imm, imm + 1]
        elif op == 0xED and info["len"] >= 4:
            ed = mem[pc + 1]
            if ed in (0x43, 0x53, 0x63, 0x73):  # LD (nn),rp
                imm = mem[pc + 2] | mem[pc + 3] << 8
                targets = [imm, imm + 1]
        for t in targets:
            if t in code:
                sites.append({
                    "pc": pc,
                    "target": t,
                    "fmt": info.get("fmt"),
                    "kind": "abs_store_into_code",
                })
    return sites


def unsafe_after_jp_candidates(
    win_insns: dict[int, dict],
    code: set[int],
    lo: int,
    hi: int,
) -> set[int]:
    """REVOKED heuristic — retained only to audit false positives.

    Bytes after unconditional JP are NOT proven deletable: they may be
    strings, tables, work RAM, or pointer targets (see A798 menu text).
    """
    cand: set[int] = set()
    for pc, info in win_insns.items():
        if info["flow"] != "jump":
            continue
        a = pc + info["len"]
        while a < hi and a not in code and a not in win_insns:
            cand.add(a)
            a += 1
    return cand


def adapter_module_sizes(syms: dict[str, int]) -> dict:
    """Assembled module spans from glue symbols (approximate entity costs)."""
    def span(lo_name, hi_name, hi_extra=0):
        if lo_name not in syms or hi_name not in syms:
            return None
        return syms[hi_name] + hi_extra - syms[lo_name]

    # Order in glue includes: softvdp, kbd, snd, replay
    soft_lo = syms.get("SOFTVDP_OUT99") or syms.get("SOFTVDP_OUT98")
    kbd_lo = syms.get("V_KBD_INIT") or syms.get("V_KBD_POLL")
    snd_lo = syms.get("BIOS_GICINI") or syms.get("BIOS_WRTPSG")
    rep_lo = syms.get("REPLAY_ZOOM")
    rep_hi = (syms.get("REPLAY_X2") or 0) + 16
    out = {
        "softvdp_approx": (kbd_lo - soft_lo) if soft_lo and kbd_lo else None,
        "kbd_approx": (snd_lo - kbd_lo) if kbd_lo and snd_lo else None,
        "snd_approx": (rep_lo - snd_lo) if snd_lo and rep_lo else None,
        "replay": (rep_hi - rep_lo) if rep_lo else None,
        "full_adapter_0200": None,
    }
    return out


def runs_of(byteset: set[int], lo: int, hi: int) -> list[dict]:
    out = []
    a = lo
    while a < hi:
        if a in byteset:
            s = a
            while a < hi and a in byteset:
                a += 1
            out.append({"start": s, "end": a - 1, "size": a - s})
        else:
            a += 1
    out.sort(key=lambda r: -r["size"])
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--require-baseline", action="store_true")
    args = ap.parse_args()

    if not (B / "basket.full.bin").exists():
        print("missing basket.full.bin", file=sys.stderr)
        return 1

    rom_sha = sha256(B / "basket.rom")
    baseline = load_baseline()
    if args.require_baseline:
        if not baseline:
            print("missing baseline.json — run tools/baseline_v06.py", file=sys.stderr)
            return 1
        if baseline["rom_sha256"] != rom_sha:
            print("ROM sha mismatch vs baseline.json", file=sys.stderr)
            return 1

    mem = load_mem()
    syms = load_syms()
    xref_seeds, xref_used = load_xref_seeds(rom_sha)

    seeds = collect_seeds(mem, syms, xref_seeds)

    # Iterative CFG: start with seeds, then add CALL/JP targets found in decoded
    # instructions that point into adapter/window/D (may need multiple rounds).
    adapt_hi = syms.get("REPLAY_X2", ADAPT_HI_CAP - 1) + 16
    regions = [
        ("low", 0x0000, 0x0200),
        ("adapter", ADAPT_LO, min(adapt_hi, ADAPT_HI_CAP)),
        ("window", WIN_LO, WIN_HI),
        ("d_region", D_LO, D_HI),
    ]

    all_code: set[int] = set()
    all_insns: dict[int, dict] = {}
    all_dyn: list[int] = []
    all_cret: list[int] = []
    all_halt: list[int] = []
    region_stats = {}
    win_part_final = None

    # Grow seeds until fixpoint (targets into other regions become seeds)
    for _round in range(8):
        before = len(seeds)
        for name, lo, hi in regions:
            part = cfg_reach(mem, seeds, lo, hi)
            all_code |= part["code_bytes"]
            all_insns.update({pc: {**info, "region": name} for pc, info in part["insns"].items()})
            all_dyn.extend(part["dyn"])
            all_cret.extend(part["cret"])
            all_halt.extend(part["halt"])
            for pc, info in part["insns"].items():
                for t in info["targets"]:
                    seeds.add(t)
                # Absolute CALL/JP operand even if targets list empty edge case
                op = mem[pc]
                if op in (0xCD, 0xC3) or (op & 0xC7) in (0xC2, 0xC4):
                    if info["len"] >= 3:
                        seeds.add(mem[pc + 1] | mem[pc + 2] << 8)
        if len(seeds) == before:
            break

    # Per-region recount with final seeds
    for name, lo, hi in regions:
        part = cfg_reach(mem, seeds, lo, hi)
        region_stats[name] = {
            "lo": lo,
            "hi": hi,
            "size": hi - lo,
            "code_bytes": len(part["code_bytes"]),
            "insns": len(part["insns"]),
            "dyn_sites": [f"{p:04X}" for p in part["dyn"]],
            "cret_sites": len(part["cret"]),
            "halt_sites": len(part["halt"]),
            "entries": len(part["entries"]),
        }
        all_code |= part["code_bytes"]
        all_insns.update({pc: {**info, "region": name} for pc, info in part["insns"].items()})
        if name == "window":
            win_part_final = part

    data_addrs = data_refs_from_insns(mem, all_insns, all_code)
    smc_sites = find_smc_sites(mem, all_insns, all_code)
    xref_rd, xref_wr, xref_data_used = load_xref_data_addrs(rom_sha)

    # Window classification
    win_code = {a for a in all_code if WIN_LO <= a < WIN_HI}
    # Full keep set for non-code: insn data refs (word-aware), abs imms,
    # xref rd/wr, expanded string/menu objects, SMC targets.
    abs_imms = set()
    for pc, info in all_insns.items():
        if info["len"] >= 3:
            op = mem[pc]
            if op in (
                0xCD, 0xC3, 0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA,
                0xC4, 0xCC, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC,
                0x01, 0x11, 0x21, 0x31, 0x3A, 0x32, 0x2A, 0x22,
            ):
                abs_imms.add(mem[pc + 1] | mem[pc + 2] << 8)

    smc_targets = {s["target"] for s in smc_sites}
    xref_touch = (xref_rd | xref_wr) & set(range(WIN_LO, WIN_HI))
    string_keep = expand_string_objects(
        mem, (data_addrs | abs_imms | xref_touch | {0xA798, 0xA79A}), WIN_LO, WIN_HI
    )
    # Word immediates: keep both bytes when abs_imm points at a cell
    word_keep = set()
    for a in list(data_addrs | abs_imms):
        if WIN_LO <= a < WIN_HI:
            word_keep.add(a)
            word_keep.add((a + 1) & 0xFFFF)

    win_data = {
        a for a in (data_addrs | word_keep | string_keep | xref_touch | smc_targets)
        if WIN_LO <= a < WIN_HI and a not in win_code
    }

    # Conservative: every non-code byte in the window is KEEP until a *verified
    # whole entity* is proven reclaimable. After-JP heuristic is REVOKED.
    keep_unknown = set(range(WIN_LO, WIN_HI)) - win_code
    candidate_after_jp = unsafe_after_jp_candidates(
        win_part_final["insns"] if win_part_final else {},
        win_code,
        WIN_LO,
        WIN_HI,
    )
    after_jp_xref_rd = sorted(candidate_after_jp & xref_rd)
    after_jp_xref_wr = sorted(candidate_after_jp & xref_wr)

    proven_dead: set[int] = set()  # revoked — nothing from after-JP
    candidate_pad = {
        a for a in keep_unknown
        if a not in win_data and a not in abs_imms
    }
    # cold CFG code is still occupancy, not free
    deletable = 0

    d_code = {a for a in all_code if D_LO <= a < D_HI}
    adapt_code = {a for a in all_code if ADAPT_LO <= a < adapt_hi}

    proven_code_win = len(win_code)
    unknown_win = len(keep_unknown)
    candidate_pad_n = len(candidate_pad)

    adapter_size = adapt_hi - ADAPT_LO
    d_code_n = len(d_code)
    occupied = proven_code_win + unknown_win  # == CAPACITY
    avail = 0  # no proven free

    # Module size breakdown for transfer / reduction options
    mod = adapter_module_sizes(syms)
    softvdp_n = mod.get("softvdp_approx") or 0
    kbd_n = mod.get("kbd_approx") or 0
    snd_n = mod.get("snd_approx") or 0
    replay_n = mod.get("replay") or 0
    # Fixed low entries that stay even after adapter move
    fixed_low = 0x100  # 0000..00FF page0 + boot/stubs region policy
    native_stubs = 0x01FC - 0x01E0  # 01E0..01FB

    dirty_span = "B258..B2C4"
    dirty_bytes = 1 + 27 * 4

    free_upper = CAPACITY - proven_code_win  # if all unknown reclaimed (NOT proven)

    budget = {
        "capacity_84D0_B257": CAPACITY,
        "proven_code_in_window": proven_code_win,
        "proven_data_keep_bytes_in_window": len(win_data),
        "keep_unknown_in_window": unknown_win,
        "candidate_pad_not_proven_deletable": candidate_pad_n,
        "proven_deletable": deletable,
        "proven_deletable_runs": [],
        "occupied_code_plus_unknown": occupied,
        "available_proven_free": avail,
        "free_upper_bound_if_all_unknown_reclaimed": free_upper,
        "after_jp_heuristic": {
            "status": "REVOKED",
            "candidate_bytes": len(candidate_after_jp),
            "xref_rd_hits": len(after_jp_xref_rd),
            "xref_wr_hits": len(after_jp_xref_wr),
            "example_hits": [f"{a:04X}" for a in (after_jp_xref_rd[:8] + [0xA798] if 0xA798 in candidate_after_jp else after_jp_xref_rd[:8])],
            "note": (
                "Do not place code on after-JP candidates. Menu text at A798 and "
                "work cells (93F6, 9417, …) were false positives."
            ),
        },
        "DIRTY_OLD_span": dirty_span,
        "DIRTY_OLD_bytes": dirty_bytes,
        "DIRTY_OLD_inside_code_window": False,
        "DIRTY_OLD_inside_freed_0100_0EFF": False,
        "B258_B337_status": (
            "DIRTY_OLD work RAM at B258..B2C4 (permanent); B2C5..B330 is "
            "previous-frame sprite metadata; B331..B337 is the free zero tail"
        ),
        "transfer_cost_as_is": {
            "adapter_body_assembled": adapter_size,
            "adapter_cfg_code": len(adapt_code),
            "d_cfg_code": d_code_n,
            "gap_adapter": adapter_size - avail,
            "gap_adapter_plus_d_cfg": adapter_size + d_code_n - avail,
            "gap_vs_unknown_upper_bound_adapter": adapter_size - free_upper,
        },
        "transfer_cost_reduction_options": {
            "modules_approx": {
                "softvdp": softvdp_n,
                "kbd": kbd_n,
                "snd": snd_n,
                "replay": replay_n,
            },
            "option_keep_softvdp_in_low": {
                "move_kbd_snd_replay": (kbd_n + snd_n + replay_n) or None,
                "note": "softVDP stays in 0200..; only smaller modules to window",
            },
            "option_native_replace_msx_dupes": {
                "note": (
                    "MSX bodies already JP'd to native (A521/A4A8/B15F/A8xx) are "
                    "cold but NOT counted dead; reclaim only as verified whole "
                    "entities after xref+object audit"
                ),
            },
            "option_shrink_softvdp": {
                "note": (
                    "Reduce compose/dirty/title paths only with behavioral tests; "
                    "not assumed free in this budget"
                ),
            },
        },
        "cold_code_policy": "CFG-reachable or xref-touched code is occupancy; cold ≠ dead",
        "note": (
            "proven_deletable is 0: after-JP heuristic revoked. "
            "available_proven_free is 0. "
            "free_upper_bound_if_all_unknown_reclaimed is a ceiling, not free space. "
            "Absence of xref touch does not prove unused. "
            "Do not place code using revoked candidate lists."
        ),
        "transfer_overhead": "per verified entity (align, trampolines, SMC)",
    }

    out = {
        "rom_sha256": rom_sha,
        "baseline_match": baseline is not None and baseline.get("rom_sha256") == rom_sha,
        "xref_used": xref_used,
        "xref_data_traces": xref_data_used,
        "regions": region_stats,
        "dyn_sites_total": sorted(set(f"{p:04X}" for p in all_dyn)),
        "cret_sites_total": len(set(all_cret)),
        "halt_sites_total": len(set(all_halt)),
        "window_code_runs": runs_of(win_code, WIN_LO, WIN_HI)[:30],
        "window_unknown_runs": runs_of(keep_unknown, WIN_LO, WIN_HI)[:30],
        "window_data_keep_runs": runs_of(win_data, WIN_LO, WIN_HI)[:30],
        "candidate_pad_runs": runs_of(candidate_pad, WIN_LO, WIN_HI)[:30],
        "proven_deletable_runs": [],
        "unsafe_after_jp_candidate_runs": runs_of(candidate_after_jp, WIN_LO, WIN_HI)[:20],
        "d_code_runs": runs_of(d_code, D_LO, D_HI)[:20],
        "adapter_code_bytes": len(adapt_code),
        "budget": budget,
        "uncertainty": {
            "dyn_jp_hl_etc": sorted(set(f"{p:04X}" for p in all_dyn)),
            "smc_abs_store_into_code": [
                {"pc": f"{s['pc']:04X}", "target": f"{s['target']:04X}", "fmt": s["fmt"]}
                for s in smc_sites[:40]
            ],
            "smc_count": len(smc_sites),
            "policy": (
                "dyn/SMC keep blocks; unknown kept; after-JP not deletable; "
                "xref absence is not unused proof; cold code is not dead"
            ),
        },
    }
    (B / "cfg_map.json").write_text(json.dumps(out, indent=2) + "\n")

    print(f"rom {rom_sha[:16]}… baseline_match={out['baseline_match']}")
    print(f"xref: {xref_used}")
    for name, st in region_stats.items():
        print(f"  {name:8s} code={st['code_bytes']:5d}/{st['size']} insns={st['insns']:4d} "
              f"dyn={len(st['dyn_sites'])} cret={st['cret_sites']} halt={st['halt_sites']}")
    b = budget
    print("--- budget window 84D0..B257 ---")
    print(f"  proven code:     {b['proven_code_in_window']}")
    print(f"  data keep:       {b['proven_data_keep_bytes_in_window']}")
    print(f"  keep unknown:    {b['keep_unknown_in_window']}")
    print(f"  candidate pad:   {b['candidate_pad_not_proven_deletable']} (NOT free)")
    print(f"  proven deletable:{b['proven_deletable']}  [after-JP REVOKED]")
    print(f"  avail proven:    {b['available_proven_free']}")
    print(f"  free upper (unk):{b['free_upper_bound_if_all_unknown_reclaimed']}")
    aj = b["after_jp_heuristic"]
    print(f"  after-JP audit:  cand={aj['candidate_bytes']} xref_rd={aj['xref_rd_hits']} "
          f"xref_wr={aj['xref_wr_hits']} ex={aj['example_hits']}")
    t = b["transfer_cost_as_is"]
    print(f"  adapter as-is:   {t['adapter_body_assembled']} gap={t['gap_adapter']:+d} "
          f"(vs unk upper {t['gap_vs_unknown_upper_bound_adapter']:+d})")
    print(f"  D cfg code:      {t['d_cfg_code']}  gap adapter+D={t['gap_adapter_plus_d_cfg']:+d}")
    print(f"  modules approx:  {b['transfer_cost_reduction_options']['modules_approx']}")
    print(f"  uncertainty: dyn={out['uncertainty']['dyn_jp_hl_etc']} "
          f"smc={out['uncertainty']['smc_count']}")
    print(f"DIRTY_OLD {b['DIRTY_OLD_span']} = {b['DIRTY_OLD_bytes']}B; {b['B258_B337_status']}")
    print(f"wrote {B / 'cfg_map.json'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
