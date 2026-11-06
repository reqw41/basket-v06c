#!/usr/bin/env python3
"""Build an exhaustive, hash-bound classification of the current 64 KiB image."""
from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from cfg_map_v06 import (  # noqa: E402
    cfg_reach, collect_seeds, data_refs_from_insns, find_smc_sites,
    load_mem, load_syms, load_xref_data_addrs, load_xref_seeds, sha256,
)

B = ROOT / "build/v06"
CFG = ROOT / "cfg/current_memory_map.json"
CONTROL_OPS = {
    0xCD, 0xC3, 0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA,
    0xC4, 0xCC, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC,
}


def hx(value: str | int) -> int:
    return value if isinstance(value, int) else int(value, 16)


def matching_xref_exec(rom_sha: str) -> tuple[set[int], list[str]]:
    out: set[int] = set()
    files = []
    for path in sorted(B.glob("xref_*.json")):
        if path.name.endswith(".meta.json") or "summary" in path.name:
            continue
        meta_path = path.with_name(path.stem + ".meta.json")
        if not meta_path.exists():
            continue
        meta = json.loads(meta_path.read_text())
        if meta.get("rom_sha256") != rom_sha:
            continue
        out.update(map(int, json.loads(path.read_text()).get("exec", [])))
        files.append(path.name)
    return out, files


def build_evidence(mem: bytearray, rom_sha: str) -> dict:
    syms = load_syms()
    xref_seeds, _ = load_xref_seeds(rom_sha)
    seeds = collect_seeds(mem, syms, xref_seeds)
    adapter_hi = min(syms.get("REPLAY_X2", 0x0DF0) + 16, 0x0E00)
    regions = [(0, 0x200), (0x200, adapter_hi), (0x3304, 0x3F80), (0x84D0, 0xB258)]
    all_code: set[int] = set()
    all_insns: dict[int, dict] = {}
    for _ in range(8):
        before = len(seeds)
        for lo, hi in regions:
            part = cfg_reach(mem, seeds, lo, hi)
            all_code |= part["code_bytes"]
            all_insns.update(part["insns"])
            for pc, info in part["insns"].items():
                seeds.update(info["targets"])
                if info["len"] >= 3 and mem[pc] in CONTROL_OPS:
                    seeds.add(mem[pc + 1] | mem[pc + 2] << 8)
        if len(seeds) == before:
            break

    # data_refs_from_insns deliberately treats LD rr,nn as a pointer only for
    # addresses >=4000. Low immediates such as 0C00/0B07 are game coordinate
    # pairs, not references into the adapter's FF padding.
    static_refs = data_refs_from_insns(mem, all_insns, all_code)
    control_targets: set[int] = set()
    for pc, info in all_insns.items():
        if info["len"] < 3 or mem[pc] not in CONTROL_OPS:
            continue
        target = mem[pc + 1] | mem[pc + 2] << 8
        control_targets.add(target)
    smc_sites = find_smc_sites(mem, all_insns, all_code)
    smc_targets = {item["target"] for item in smc_sites}
    xref_rd, xref_wr, xref_data_files = load_xref_data_addrs(rom_sha)
    xref_exec, xref_exec_files = matching_xref_exec(rom_sha)
    return {
        "code": all_code,
        "static_refs": static_refs | control_targets,
        "smc_targets": smc_targets,
        "xref_rd": xref_rd,
        "xref_wr": xref_wr,
        "xref_exec": xref_exec,
        "xref_files": sorted(set(xref_exec_files + [x["file"] for x in xref_data_files if x.get("status") == "ok"])),
        "smc_sites": smc_sites,
        "adapter_hi": adapter_hi,
    }


def validate_regions(raw: dict) -> list[dict]:
    regions = []
    cursor = 0
    for item in raw["regions"]:
        region = dict(item, lo=hx(item["lo"]), hi=hx(item["hi"]))
        if region["lo"] != cursor:
            raise ValueError(f"gap/overlap before {region['id']}: {cursor:04X} != {region['lo']:04X}")
        if region["hi"] <= region["lo"]:
            raise ValueError(f"empty region {region['id']}")
        cursor = region["hi"]
        regions.append(region)
    if cursor != 0x10000:
        raise ValueError(f"map ends at {cursor:04X}, expected 10000")
    return regions


def compress(classes: list[str], regions_by_addr: list[str]) -> list[dict]:
    runs = []
    lo = 0
    while lo < 0x10000:
        cls, rid = classes[lo], regions_by_addr[lo]
        hi = lo + 1
        while hi < 0x10000 and classes[hi] == cls and regions_by_addr[hi] == rid:
            hi += 1
        runs.append({"lo": lo, "hi": hi, "size": hi - lo, "class": cls, "region": rid})
        lo = hi
    return runs


def classify(config: dict, mem: bytearray, evidence: dict) -> dict:
    regions = validate_regions(config)
    classes = [""] * 0x10000
    region_ids = [""] * 0x10000
    padding_proofs = []
    # Known false references: a 16-bit immediate that equals the address but
    # is used as a value (cfg "false_references", with the site and why).
    # Only the static-reference evidence is waived; traces still block.
    false_refs = set()
    for fr in config.get("false_references", []):
        addr, site, want = hx(fr["addr"]), hx(fr["site"]), bytes.fromhex(fr["bytes"])
        if bytes(mem[site:site + len(want)]) != want:
            raise ValueError(f"false reference {fr['addr']}: site {fr['site']} is not {fr['bytes']}")
        false_refs.add(addr)
    live = (evidence["code"] | (evidence["static_refs"] - false_refs) | evidence["smc_targets"] |
            evidence["xref_rd"] | evidence["xref_wr"] | evidence["xref_exec"])

    for region in regions:
        lo, hi = region["lo"], region["hi"]
        for addr in range(lo, hi):
            region_ids[addr] = region["id"]
            if region["class"] != "mixed":
                classes[addr] = region["class"]
            elif addr in evidence["code"]:
                classes[addr] = "self_modifying_code" if addr in evidence["smc_targets"] else "code"
            elif addr in evidence["xref_wr"]:
                classes[addr] = "mutable_state"
            elif addr in evidence["xref_rd"] or addr in evidence["static_refs"]:
                classes[addr] = "referenced_data"
            else:
                classes[addr] = "opaque_retained"

        if region.get("prove_free") or region.get("audit_padding"):
            expected = int(region["expected_fill"], 16)
            wrong_fill = [a for a in range(lo, hi) if mem[a] != expected]
            blockers = sorted(set(range(lo, hi)) & live)
            reclaimable = bool(region.get("prove_free"))
            status = ("PASS" if not wrong_fill and not blockers else "FAIL") if reclaimable else "RETAINED"
            padding_proofs.append({
                "region": region["id"], "lo": lo, "hi": hi, "size": hi - lo,
                "expected_fill": expected, "wrong_fill_count": len(wrong_fill),
                "reference_or_trace_blockers": len(blockers),
                "blocker_examples": blockers[:16], "reclaimable_claim": reclaimable,
                "status": status,
            })

    if any(not value for value in classes) or any(not value for value in region_ids):
        raise ValueError("internal error: unclassified address")
    runs = compress(classes, region_ids)
    mixed = {}
    for region in regions:
        if region["class"] == "mixed":
            counts = Counter(classes[region["lo"]:region["hi"]])
            mixed[region["id"]] = {"lo": region["lo"], "hi": region["hi"], "size": region["hi"] - region["lo"], "counts": dict(sorted(counts.items()))}
    return {
        "schema": 1,
        "rom_sha256": sha256(B / "basket.rom"),
        "address_space_bytes": 0x10000,
        "coverage": {"classified_bytes": len(classes), "unclassified_bytes": 0, "overlap_bytes": 0},
        "class_counts": dict(sorted(Counter(classes).items())),
        "mixed_regions": mixed,
        "padding_proofs": padding_proofs,
        "reclaimable_bytes": sum(p["size"] for p in padding_proofs if p["reclaimable_claim"] and p["status"] == "PASS"),
        "xref_files": evidence["xref_files"],
        "cfg_code_bytes": len(evidence["code"]),
        "smc_target_bytes": len(evidence["smc_targets"]),
        "semantic_regions": [{**r, "lo": r["lo"], "hi": r["hi"], "size": r["hi"] - r["lo"]} for r in regions],
        "classification_runs": runs,
        "policy": config["policy"],
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--json", type=Path, default=B / "memory_classification.json")
    args = ap.parse_args()
    config = json.loads(CFG.read_text())
    actual_sha = sha256(B / "basket.rom")
    if actual_sha != config["rom_sha256"]:
        print(f"ROM hash mismatch: {actual_sha} != {config['rom_sha256']}", file=sys.stderr)
        return 1
    mem = load_mem()
    report = classify(config, mem, build_evidence(mem, actual_sha))
    args.json.parent.mkdir(parents=True, exist_ok=True)
    args.json.write_text(json.dumps(report, indent=2) + "\n")
    failed = [p for p in report["padding_proofs"] if p["reclaimable_claim"] and p["status"] != "PASS"]
    print(f"classified={report['coverage']['classified_bytes']} unclassified=0 reclaimable={report['reclaimable_bytes']}")
    for name, item in report["mixed_regions"].items():
        print(name, " ".join(f"{k}={v}" for k, v in item["counts"].items()))
    for proof in report["padding_proofs"]:
        print(f"padding {proof['region']}: {proof['status']} size={proof['size']} blockers={proof['reference_or_trace_blockers']}")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
