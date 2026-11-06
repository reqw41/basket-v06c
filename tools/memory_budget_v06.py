#!/usr/bin/env python3
"""Machine-checkable target memory budget (stage 1).

Distinguishes:
  - current factual map (object current_lo/hi)
  - proposed target_region placement
  - estimated future sizes (size_kind=estimated / four_color_estimate)

Does NOT claim the working ROM memory_layout is relocated. verify_refactor
must keep memory_layout=NOT_CHECKED.

Exit codes:
  0 — structural OK (PASS or DEFICIT documented)
  1 — structural failure (bad map, reserve occupied, inconsistent declaration)

Usage:
  python3 tools/memory_budget_v06.py
  python3 tools/memory_budget_v06.py --json build/v06/memory_budget_report.json
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CFG = ROOT / "cfg" / "memory_budget.json"


def load(path: Path) -> dict:
    return json.loads(path.read_text())


def region_map(cfg: dict) -> dict[str, dict]:
    return {r["id"]: r for r in cfg["target_regions"]}


def check_regions(cfg: dict) -> list[str]:
    errors: list[str] = []
    regions = sorted(cfg["target_regions"], key=lambda r: r["lo"])
    for r in regions:
        span = r["hi"] - r["lo"]
        if span != r["capacity"]:
            errors.append(
                f"region {r['id']}: hi-lo={span} != capacity={r['capacity']}"
            )
        if r["lo"] < 0 or r["hi"] > 0x10000 or r["lo"] >= r["hi"]:
            errors.append(f"region {r['id']}: invalid bounds")
    for a, b in zip(regions, regions[1:]):
        if a["hi"] > b["lo"]:
            errors.append(f"overlap {a['id']}..{b['id']}")
        elif a["hi"] < b["lo"]:
            errors.append(
                f"gap between {a['id']} and {b['id']}: "
                f"{a['hi']:04X}..{b['lo'] - 1:04X}"
            )
    if regions and regions[0]["lo"] != 0:
        errors.append("map must start at 0000")
    if regions and regions[-1]["hi"] != 0x10000:
        errors.append("map must end at 10000")
    return errors


def budget_objects(cfg: dict) -> list[dict]:
    """Objects charged to the future layout.

    Current containment and future accounting are independent.  A child moved
    to another target region must set budget_count=true; a duplicate image or
    descriptive sub-object must set it false explicitly.
    """
    return [o for o in cfg["objects"] if o.get("budget_count", not o.get("nest_of") and not o.get("covers"))]


def check_objects(cfg: dict) -> list[str]:
    errors: list[str] = []
    names: dict[str, dict] = {}
    for o in cfg["objects"]:
        name = o.get("name")
        if not name or name in names:
            errors.append(f"duplicate or missing object name: {name!r}")
            continue
        names[name] = o
        lo, hi, size = o.get("current_lo"), o.get("current_hi"), o.get("size")
        if not all(isinstance(v, int) for v in (lo, hi, size)):
            errors.append(f"{name}: bounds and size must be integers")
        elif not (0 <= lo < hi <= 0x10000):
            errors.append(f"{name}: invalid bounds")
        elif (hi - lo != size and not (o.get("aggregate") and size <= hi - lo)):
            errors.append(f"{name}: invalid bounds/size")

    for name, o in names.items():
        parent = o.get("nest_of")
        if parent:
            if parent not in names:
                errors.append(f"{name}: missing parent {parent}")
            else:
                p = names[parent]
                if not (p["current_lo"] <= o["current_lo"] and o["current_hi"] <= p["current_hi"]):
                    errors.append(f"{name}: not contained in parent {parent}")
        duplicate = o.get("duplicate_of")
        if duplicate and duplicate not in names:
            errors.append(f"{name}: missing duplicate_of {duplicate}")

        seen = {name}
        cursor = parent
        while cursor:
            if cursor in seen:
                errors.append(f"{name}: containment cycle")
                break
            seen.add(cursor)
            cursor = names.get(cursor, {}).get("nest_of")
    return errors


def check_current_overlaps(cfg: dict) -> list[str]:
    errors: list[str] = []
    objs = sorted([o for o in cfg["objects"] if not o.get("nest_of") and not o.get("covers")], key=lambda o: o["current_lo"])
    for a, b in zip(objs, objs[1:]):
        if a["current_hi"] > b["current_lo"]:
            errors.append(
                f"current overlap {a['name']} ({a['current_lo']:04X}..{a['current_hi'] - 1:04X}) "
                f"vs {b['name']} ({b['current_lo']:04X}..{b['current_hi'] - 1:04X})"
            )
    return errors


def uncovered_current(cfg: dict) -> list[tuple[int, int]]:
    covered = [False] * 0x10000
    for o in cfg["objects"]:
        if o.get("nest_of"):
            continue
        for a in range(o["current_lo"], o["current_hi"]):
            covered[a] = True
    gaps = []
    i = 0
    while i < 0x10000:
        if covered[i]:
            i += 1
            continue
        j = i
        while j < 0x10000 and not covered[j]:
            j += 1
        gaps.append((i, j))
        i = j
    return gaps


def region_loads(cfg: dict) -> dict[str, dict]:
    loads: dict[str, dict] = {
        rid: {
            "measured": 0,
            "estimated": 0,
            "objects_measured": [],
            "objects_estimated": [],
        }
        for rid in region_map(cfg)
    }
    for o in budget_objects(cfg):
        rid = o.get("target_region")
        if rid is None:
            continue
        if rid not in loads:
            raise KeyError(f"unknown target_region {rid} on {o['name']}")
        kind = o.get("size_kind", "measured")
        if kind == "measured":
            loads[rid]["measured"] += o["size"]
            loads[rid]["objects_measured"].append(o["name"])
        else:
            loads[rid]["estimated"] += o["size"]
            loads[rid]["objects_estimated"].append(o["name"])
    return loads


def check_reserves_overflow(cfg: dict, loads: dict) -> tuple[list[str], list[str], list[str]]:
    """Returns (errors, measured deficits, estimated deficits)."""
    errors: list[str] = []
    deficits: list[str] = []
    estimated_deficits: list[str] = []
    regions = region_map(cfg)
    for rid, r in regions.items():
        m = loads[rid]["measured"]
        e = loads[rid]["estimated"]
        cap = r["capacity"]
        assigned = [o["name"] for o in cfg["objects"] if o.get("target_region") == rid]
        if r.get("reserve"):
            if assigned:
                errors.append(
                    f"reserve {rid} occupied: measured={m} estimated={e} "
                    f"objects={assigned}"
                )
            continue
        if m > cap:
            deficits.append(
                f"{rid}: measured need {m} > capacity {cap} (deficit {m - cap}); "
                f"objects={loads[rid]['objects_measured']}"
            )
        elif m + e > cap:
            estimated_deficits.append(
                f"{rid}: measured {m} + estimated {e} = {m + e} > capacity {cap}"
            )
    return errors, deficits, estimated_deficits


def unplaced(cfg: dict) -> list[str]:
    out = []
    for o in budget_objects(cfg):
        if o.get("target_region") is None:
            out.append(f"{o['name']} [{o['category']}]")
    return out


def summarize(cfg: dict, loads: dict) -> list[dict]:
    rows = []
    for r in cfg["target_regions"]:
        rid = r["id"]
        m = loads[rid]["measured"]
        e = loads[rid]["estimated"]
        cap = r["capacity"]
        est_need = None
        if rid == "code":
            est_need = cfg["code_budget"]["classification_range"]
        elif rid == "resources":
            est_need = cfg["resource_budget"]["measured_mono_sum"]
        elif rid == "gfx_buffers":
            est_need = max(cfg["gfx_buffer_budget"]["peak_estimates_bytes"].values())
        elif rid == "state":
            est_need = cfg["state_budget"]["sum_approx"]
        elif rid == "stack":
            est_need = cfg["stack_budget"]["current_region_size"]
        rows.append(
            {
                "id": rid,
                "capacity": cap,
                "measured_assigned": m,
                "estimated_assigned": e,
                "section_estimate": est_need,
                "reserve": bool(r.get("reserve")),
                "slack_vs_measured": None if r.get("reserve") else cap - m,
                "objects": loads[rid]["objects_measured"],
            }
        )
    return rows


def validate(cfg: dict, rom_sha256: str | None = None) -> dict:
    errors = check_regions(cfg)
    errors.extend(check_objects(cfg))
    by = {o["name"]: o for o in cfg["objects"]}
    for name, parent in (
        ("adapter_boot_irq", "adapter_body_total"),
        ("dirty_list_current", "adapter_work_ram_0F00"),
        ("ff_strings_in_game_window", "game_overlay_window"),
        ("music_notes_embedded", "music_bundle"),
        ("game_match_vars_93xx", "game_overlay_window"),
    ):
        if name in by and by[name].get("nest_of") != parent:
            errors.append(f"{name} must set nest_of={parent}")

    errors.extend(check_current_overlaps(cfg))
    loads = region_loads(cfg)
    e2, deficits, estimated_deficits = check_reserves_overflow(cfg, loads)
    errors.extend(e2)

    expected_sha = cfg.get("rom_sha256_baseline")
    if rom_sha256 is not None and expected_sha != rom_sha256:
        errors.append(f"ROM SHA-256 mismatch: declaration={expected_sha} actual={rom_sha256}")

    evidence_gaps = list(cfg.get("evidence_gaps", []))
    evidence_gaps.extend(unplaced(cfg))

    gaps = uncovered_current(cfg)
    structure_status = "FAIL" if errors else "PASS"
    if deficits:
        capacity_status = "MEASURED_DEFICIT"
    elif estimated_deficits:
        capacity_status = "ESTIMATED_DEFICIT"
    elif evidence_gaps:
        capacity_status = "UNPROVEN"
    else:
        capacity_status = "FIT"
    evidence_status = "INCOMPLETE" if evidence_gaps else "COMPLETE"
    status = "FAIL" if errors else capacity_status

    return {
        "status": status,
        "structure_status": structure_status,
        "capacity_status": capacity_status,
        "evidence_status": evidence_status,
        "errors": errors,
        "deficits": deficits,
        "estimated_deficits": estimated_deficits,
        "evidence_gaps": evidence_gaps,
        "regions": summarize(cfg, loads),
        "unplaced": unplaced(cfg),
        "uncovered_ranges": [
            {"lo": a, "hi": b, "size": b - a} for a, b in gaps if b - a
        ],
        "memory_layout_claim": "NOT_CHECKED",
        "note": (
            "Structure, capacity, and evidence are independent. FIT requires "
            "complete evidence and no measured or estimated overflow. None of "
            "these statuses relocates the ROM; memory_layout stays NOT_CHECKED."
        ),
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--config", type=Path, default=DEFAULT_CFG)
    ap.add_argument("--rom", type=Path, help="verify declaration against this ROM SHA-256")
    ap.add_argument("--json", type=Path, help="write machine report JSON")
    ap.add_argument("--quiet", action="store_true")
    ap.add_argument(
        "--strict-capacity",
        action="store_true",
        help="treat measured capacity deficits as hard failure (exit 1)",
    )
    args = ap.parse_args()
    cfg = load(args.config)
    rom_sha = None
    if args.rom:
        import hashlib
        rom_sha = hashlib.sha256(args.rom.read_bytes()).hexdigest()
    report = validate(cfg, rom_sha)
    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(report, indent=2) + "\n")
    if not args.quiet:
        print(
            f"status: {report['status']} structure={report['structure_status']} "
            f"capacity={report['capacity_status']} evidence={report['evidence_status']} "
            "(memory_layout claim: NOT_CHECKED)"
        )
        for row in report["regions"]:
            flag = "RESERVE" if row["reserve"] else f"slack={row['slack_vs_measured']}"
            print(
                f"  {row['id']:16s} cap={row['capacity']:5d} "
                f"measured={row['measured_assigned']:5d} "
                f"est_obj={row['estimated_assigned']:5d} {flag}"
            )
        for label in ("errors", "deficits", "estimated_deficits", "evidence_gaps"):
            items = report[label]
            if items:
                print(f"{label}:")
                for x in items:
                    print(" ", x)
        if report["unplaced"]:
            print("unplaced:", ", ".join(report["unplaced"]))
    if report["structure_status"] == "FAIL":
        return 1
    if args.strict_capacity and report["capacity_status"] != "FIT":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
