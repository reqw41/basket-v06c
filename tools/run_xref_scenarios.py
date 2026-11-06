#!/usr/bin/env python3
"""Run smoke xref scenarios bound to the current basket.rom SHA-256.

Writes:
  build/v06/xref_<scenario>.json       — exec/fetch/rd/wr
  build/v06/xref_<scenario>.meta.json  — rom_sha256, scenario, frames, cmd,
                                         expect_hit (procedure PCs to verify)

Fixed-press: boot_title, menu_input.
Adaptive match: tools/run_xref_match.js (title→menu→1P/2P→move/throw/esc/replay).

Absence of an address in a trace is NOT proof of dead code.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
B = ROOT / "build/v06"
ROM = B / "basket.rom"
SMOKE = ROOT / "tools/smoke_v06js.js"
MATCH = ROOT / "tools/run_xref_match.js"

SCENARIOS = {
    "boot_title": {
        "frames": 80,
        "args": [],
        "expect_syms": ["ADAPTER_INIT", "IRQ_HANDLER"],
        "expect_addrs": [],
    },
    "menu_input": {
        "frames": 400,
        "args": ["--input"],
        "expect_syms": ["V_KBD_POLL", "BIOS_SNSMAT"],
        "expect_addrs": [],
    },
}

MATCH_MODES = ["1p", "2p", "1p_throw", "1p_esc", "replay"]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_syms() -> dict[str, int]:
    syms = {}
    lst = B / "glue.lst"
    if not lst.exists():
        return syms
    for line in lst.read_text(errors="replace").splitlines():
        m = re.match(r"([A-Za-z_][A-Za-z0-9_]*)\s+=\s+\$([0-9A-Fa-f]+)", line)
        if m:
            syms[m.group(1)] = int(m.group(2), 16)
    return syms


def run_fixed(name: str, cfg: dict, rom_sha: str, syms: dict[str, int]) -> dict:
    out_xref = B / "xref.json"
    if out_xref.exists():
        # Truncate in place: managed workspaces may permit updates while denying unlink.
        out_xref.write_bytes(b"")
    cmd = ["node", str(SMOKE), str(ROM), str(cfg["frames"]), "--xref", *cfg["args"]]
    print("run", name, f"frames={cfg['frames']}")
    r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stdout[-500:] if r.stdout else "", r.stderr[-500:] if r.stderr else "")
        raise SystemExit(r.returncode)
    if not out_xref.exists():
        raise SystemExit(f"no xref.json after {name}")
    dest = B / f"xref_{name}.json"
    dest.write_bytes(out_xref.read_bytes())
    x = json.loads(dest.read_text())
    exec_set = set(int(p) for p in x.get("exec", []))

    hits = {}
    missing = []
    for s in cfg.get("expect_syms", []):
        addr = syms.get(s)
        ok = addr is not None and addr in exec_set
        hits[s] = {"addr": addr, "hit": ok}
        if not ok:
            missing.append(s)
    for a in cfg.get("expect_addrs", []):
        ok = a in exec_set
        hits[f"@{a:04X}"] = {"addr": a, "hit": ok}
        if not ok:
            missing.append(f"@{a:04X}")

    meta = {
        "scenario": name,
        "rom_sha256": rom_sha,
        "rom": str(ROM),
        "frames": cfg["frames"],
        "args": cfg["args"],
        "cmd": cmd,
        "expect_hits": hits,
        "missing_required": missing,
        "note": "absence of an address is not dead-code proof",
    }
    (B / f"xref_{name}.meta.json").write_text(json.dumps(meta, indent=2) + "\n")
    status = "OK" if not missing else f"MISSING {missing}"
    print(f"  {name}: exec={len(exec_set)} {status}")
    return {"scenario": name, "exec": len(exec_set), "missing": missing}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--fixed-only", action="store_true",
                    help="run boot_title and menu_input only")
    args = ap.parse_args()
    if not ROM.exists():
        print("missing basket.rom", file=sys.stderr)
        return 1
    rom_sha = sha256(ROM)
    B.mkdir(parents=True, exist_ok=True)
    syms = load_syms()
    summary = []

    for name, cfg in SCENARIOS.items():
        summary.append(run_fixed(name, cfg, rom_sha, syms))

    if args.fixed_only:
        (B / "xref_scenarios_summary.json").write_text(
            json.dumps({"rom_sha256": rom_sha, "scenarios": summary}, indent=2) + "\n"
        )
        print(f"rom_sha256={rom_sha}")
        return 0

    for mode in MATCH_MODES:
        print("run adaptive match", mode)
        r = subprocess.run(
            ["node", str(MATCH), mode, str(ROM)],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        print(r.stdout.strip()[-500:] if r.stdout else "")
        if r.stderr:
            print(r.stderr[-300:], file=sys.stderr)
        meta_path = B / f"xref_match_{mode}.meta.json"
        if meta_path.exists():
            meta = json.loads(meta_path.read_text())
            summary.append({
                "scenario": meta["scenario"],
                "phase": meta.get("phase"),
                "playersMode": meta.get("playersMode"),
                "missing": meta.get("missing_required", []),
            })
        if r.returncode != 0:
            print(f"scenario match_{mode} FAILED rc={r.returncode}", file=sys.stderr)
            (B / "xref_scenarios_summary.json").write_text(
                json.dumps({"rom_sha256": rom_sha, "scenarios": summary, "failed": mode}, indent=2)
                + "\n"
            )
            return r.returncode

    (B / "xref_scenarios_summary.json").write_text(
        json.dumps({"rom_sha256": rom_sha, "scenarios": summary}, indent=2) + "\n"
    )
    print(f"rom_sha256={rom_sha}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
