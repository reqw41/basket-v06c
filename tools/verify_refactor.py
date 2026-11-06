#!/usr/bin/env python3
"""Isolated, hash-bound checks. Never rebuild or replace the working ROM.

Default full profile returns nonzero for unconfirmed integration scenarios.
Baseline profile deliberately excludes these scenarios; it is not acceptance.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[1]
INPUT_DIRS = ("src", "tools", "ref", "cfg", "disasm")
MODES = ("1p", "2p", "1p_throw", "1p_esc", "replay")
RELOCATION_REFERENCE_SHA = "54d6ee2ddcbb89afc641e41accc0b42f61f4e5a3d00a962f98002a535dfb71e0"


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def inventory(root):
    return {str(p.relative_to(root)): sha(p)
            for name in INPUT_DIRS for p in sorted((root / name).rglob("*"))
            if p.is_file() and "__pycache__" not in p.parts and p.suffix != ".pyc"}


def execute(command, cwd, log, timeout):
    start = time.monotonic()
    result = {"command": list(map(str, command)), "log": str(log)}
    try:
        with log.open("w") as stream:
            proc = subprocess.run(command, cwd=cwd, stdout=stream,
                                  stderr=subprocess.STDOUT, timeout=timeout,
                                  env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"})
        result.update(returncode=proc.returncode,
                      status="PASS" if proc.returncode == 0 else "FAIL")
    except subprocess.TimeoutExpired:
        result.update(status="ERROR", reason="timeout", returncode=None)
    except OSError as exc:
        result.update(status="ERROR", reason=str(exc), returncode=None)
    result["seconds"] = round(time.monotonic() - start, 3)
    return result


def validate_match(meta, mode, rom_sha):
    errors = []
    if meta.get("rom_sha256") != rom_sha:
        errors.append("stale or wrong ROM hash")
    if meta.get("mode") != mode:
        errors.append("wrong scenario")
    if meta.get("missing_required") != []:
        errors.append("missing required outcomes")
    if meta.get("procedure_check") or meta.get("replayForced"):
        errors.append("procedure invocation is not an integration scenario")
    if mode in ("1p", "2p", "1p_throw"):
        if meta.get("phase") != "ready":
            errors.append("match not ready")
        if meta.get("playersMode") != (2 if mode == "2p" else 1):
            errors.append("wrong players mode")
    if mode == "1p_esc" and meta.get("phase") != "menu_returned":
        errors.append("menu return not observed")
    # The legacy replay harness proves entry only. Do not claim completion/HUD.
    if mode == "replay":
        if not meta.get("expect_hits", {}).get("REPLAY_ZOOM", {}).get("hit"):
            errors.append("natural replay entry not observed")
    return errors


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--profile", choices=("baseline", "full"), default="full")
    ap.add_argument("--timeout", type=int, default=180, help="seconds per command")
    ap.add_argument("--output", type=Path, help="new directory; must not exist")
    args = ap.parse_args()
    if args.timeout <= 0:
        ap.error("timeout must be positive")
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    out = (args.output or ROOT / "build/verification" / stamp).resolve()
    out.mkdir(parents=True, exist_ok=False)
    (out / "logs").mkdir()
    report = {"schema": 1, "started_utc": stamp, "profile": args.profile,
              "status": "RUNNING", "checks": [], "memory_layout": "NOT_CHECKED",
              "coverage_limits": [
                  "Current Z80 four-colour layout only; not 8080-recompile acceptance.",
                  "memory_budget check validates cfg/memory_budget.json only; "
                  "PASS/DEFICIT does not mean the ROM uses the target map.",
                  "Sprite Python model is supplemental; ROM tests cover shifts, clipping and overlap.",
                  "Replay procedure tests cover both planes; keyboard scenario checks entry only.",
                  "No visual/audio quality assessment or full gameplay equivalence proof.",
              ]}

    def save():
        (out / "report.json").write_text(json.dumps(report, indent=2) + "\n")

    def check(name, category, command, cwd):
        print(f"RUN {name}", flush=True)
        r = {"name": name, "category": category,
             **execute(command, cwd, out / "logs" / (name + ".log"), args.timeout)}
        report["checks"].append(r)
        print(f"{r['status']} {name} ({r['seconds']}s)", flush=True)
        save()
        return r

    before = None
    rom = ROOT / "build/v06/basket.rom"
    try:
        before = inventory(ROOT)
        report["source_files"] = before
        report["working_rom_sha256"] = sha(rom)
        # Capture the image before any build; retain it beside the report.
        shutil.copy2(rom, out / "working-before.rom")
        git = subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT,
                             capture_output=True, text=True)
        report["git_head"] = git.stdout.strip() if git.returncode == 0 else None
        report["python"] = sys.version
        node = subprocess.run(["node", "--version"], capture_output=True, text=True, check=True)
        report["node"] = node.stdout.strip()
        deps = [ROOT / "tools/vendor/z80dis.py"]
        deps.append(Path(os.environ.get("ZASM") or shutil.which("zasm")
                         or str(Path.home() / "projects/kvalley-v06c/tools/bin/sjasm")))
        v06 = Path(os.environ.get("V06", str(Path.home() / "projects/vector06js")))
        for sub in ("i8080-js", "src"):
            deps.extend(sorted((v06 / sub).glob("*.js")))
        deps.extend([v06 / "Z80_v06.js", v06 / "z80_adapter.js"])
        report["dependency_files"] = {str(p): sha(p) for p in deps}

        work1, work2 = out / "work-1", out / "work-2"
        for work in (work1, work2):
            for name in INPUT_DIRS:
                shutil.copytree(ROOT / name, work / name,
                                ignore=shutil.ignore_patterns("__pycache__", "*.pyc"))
            if inventory(work) != before:
                raise RuntimeError("source snapshot changed while copying")
        build1 = check("clean_build_1", "build", [sys.executable, "tools/build_v06_rom.py"], work1)
        build2 = check("clean_build_2", "build", [sys.executable, "tools/build_v06_rom.py"], work2)
        if any(r["status"] != "PASS" for r in (build1, build2)):
            raise RuntimeError("clean build failed; ROM tests not run")
        image1, image2 = (w / "build/v06/basket.rom" for w in (work1, work2))
        h1, h2 = sha(image1), sha(image2)
        report["tested_rom_sha256"] = h1
        report["second_clean_rom_sha256"] = h2
        report["artifact_hashes"] = {p.name: sha(p) for p in (work1 / "build/v06").iterdir()
                                     if p.is_file()}
        same = h1 == h2 == report["working_rom_sha256"]
        report["checks"].append({"name": "reproducible_current_rom", "category": "build",
                                  "status": "PASS" if same else "FAIL",
                                  "reason": "both clean builds must match the saved working image"})
        # This reference is used only by the explicit relocation regression.
        old = ROOT / "build/v06/basket-etalon-54d6ee2d.rom"
        copied_old = work1 / "build/v06" / old.name
        shutil.copy2(old, copied_old)
        report["relocation_reference_sha256"] = sha(copied_old)
        if report["relocation_reference_sha256"] != RELOCATION_REFERENCE_SHA:
            raise RuntimeError("relocation reference differs from its pinned SHA-256")
        check("verification_harness", "tool_regression", [sys.executable, "tools/test_verify_refactor.py"], work1)
        check("cfg", "tool_regression", [sys.executable, "tools/test_cfg_map_v06.py"], work1)
        check("memory_classification_tests", "tool_regression",
              [sys.executable, "tools/test_classify_memory_v06.py"], work1)
        # Target budget declaration only; does not relocate ROM or flip memory_layout.
        check("memory_budget", "budget_declaration", [sys.executable, "tools/test_memory_budget_v06.py"], work1)
        check("cpc_palette", "graphics_contract",
              [sys.executable, "tools/test_cpc_palette_v06.py"], work1)
        budget_report = work1 / "build/v06/memory_budget_report.json"
        budget_check = check(
            "memory_budget_declaration", "budget_declaration",
            [sys.executable, "tools/memory_budget_v06.py", "--rom", str(image1),
             "--json", str(budget_report)], work1)
        if budget_report.exists():
            budget = json.loads(budget_report.read_text())
            budget_check["declaration"] = {
                key: budget.get(key) for key in (
                    "status", "structure_status", "capacity_status",
                    "evidence_status", "memory_layout_claim"
                )
            }
            report["memory_budget"] = budget
            save()
        check("clipped_player", "rom_procedure", ["node", "tools/test_clipped_player.js", str(image1)], work1)
        check("visual_regressions", "graphics_regression",
              [sys.executable, "tools/test_visual_regressions.py"], work1)
        check("game_speed", "performance_regression", ["node", "tools/bench_game_speed.js", str(image1), "--min-hz", "5.5"], work1)
        check("sprite_model", "model_only", [sys.executable, "tools/test_b01c_sprite.py"], work1)
        check("relocation", "rom_procedure_and_irq", ["node", "tools/test_set_vblank_xfer.js"], work1)
        check("replay_graphics", "rom_procedures_and_live_match", ["node", "tools/test_replay_zoom.js", str(image1)], work1)
        if args.profile == "full":
            check("game_flow", "keyboard_integration", ["node", "tools/test_game_flow.js", str(image1)], work1)
            check("player_motion", "graphics_timing_regression",
                  ["node", "tools/test_player_motion.js", str(image1)], work1)
            check("joystick_p", "input_integration", ["sh", "tools/joyp_gate.sh", str(image1)], work1)
            # Every court byte of every match publish against the frame built
            # from the game's draw calls (tools/frame_predict.js). Supersedes
            # court_clean (court outside the sprites only); 1, 2, 6 left old
            # player rects after a 7-object frame (05.11).
            check("frame_predict", "graphics_regression",
                  ["sh", "-c", 'for s in 777 1 2 6; do SEED=$s NF=3000 node tools/frame_predict.js "$0" || exit 1; done; '
                   'MENU=1500 NF=4000 SEED=3 node tools/frame_predict.js "$0"',
                   str(image1)], work1)
        check("xref_fixed_scenarios", "trace_coverage",
              [sys.executable, "tools/run_xref_scenarios.py", "--fixed-only"], work1)
        for mode in MODES:
            name = "match_" + mode
            if args.profile == "baseline" and mode in ("1p_esc", "replay"):
                report["checks"].append({"name": name, "category": "keyboard_integration",
                                          "status": "NOT_RUN", "reason": "excluded by baseline profile"})
                continue
            r = check(name, "keyboard_integration", ["node", "tools/run_xref_match.js", mode, str(image1)], work1)
            meta_path = work1 / "build/v06" / ("xref_" + name + ".meta.json")
            if not meta_path.exists():
                r.update(status="ERROR", reason="missing scenario metadata")
                continue
            meta = json.loads(meta_path.read_text())
            r["scenario"] = meta
            errors = validate_match(meta, mode, h1)
            if errors:
                r["validation_errors"] = errors
                if r["status"] != "ERROR":
                    r["status"] = "FAIL"
            save()
        check("color_plane_safety", "memory_layout_integration",
              [sys.executable, "tools/test_color_plane_v06.py"], work1)
        check("softvdp_inventory", "trace_coverage",
              [sys.executable, "tools/inventory_softvdp_v06.py"], work1)
        check("labels", "address_contract",
              [sys.executable, "tools/test_labels.py"], work1)
        check("disasm_roundtrip", "recompile_input",
              [sys.executable, "tools/disasm_v06.py", "--verify"], work1)
        # Plan E: the i8080 image (recompiled game + i8080 adapter).
        check("i8080_build", "recompile",
              ["sh", "-c", f"{sys.executable} tools/recompile_i8080.py && {sys.executable} tools/build_i8080_rom.py"], work1)
        check("i8080_run", "recompile",
              ["node", "tools/run_i8080.js"], work1)
        check("game_speed_i8080", "performance_regression",
              ["sh", "-c", "CPU=i8080 node tools/bench_game_speed.js build/i8080/basket-i8080.rom --min-hz 4.8"], work1)
        check("block_equiv", "recompile",
              ["sh", "-c", "NF=1200 K=2 node tools/block_equiv.js"], work1)
        check("frame_predict_i8080", "graphics_regression",
              ["sh", "-c", "CPU=i8080 SEED=5 NF=4000 node tools/frame_predict.js build/i8080/basket-i8080.rom && "
               "CPU=i8080 MENU=1500 NF=4000 SEED=2 node tools/frame_predict.js build/i8080/basket-i8080.rom"], work1)
        # MSX original (deterministic RNG) against both ports, game state per iteration.
        check("msx_lockstep", "msx_equivalence",
              ["sh", "-c", f"{sys.executable} tools/build_exec_rom.py --deterministic && "
                           f"{sys.executable} tools/msx_lockstep.py --iters 400 --cpu both"], work1)
        addresses = check(
            "address_contract", "relocation_inventory",
            [sys.executable, "tools/annotate_window_v06.py"], work1)
        address_report = work1 / "build/v06/window_entities.json"
        if address_report.exists():
            address_data = json.loads(address_report.read_text())
            addresses["inventory"] = {
                key: address_data.get(key) for key in (
                    "rom_sha256", "cfg_code_bytes", "data_keep_bytes",
                    "smc_count", "absolute_operand_count",
                    "absolute_operand_classes", "residual_unmarked_bytes"
                )
            }
            if address_data.get("rom_sha256") != h1:
                addresses.update(status="FAIL", reason="address inventory bound to wrong ROM")
            report["address_contract"] = address_data
            save()
        memory_map = work1 / "build/v06/memory_classification.json"
        classification = check(
            "memory_classification", "memory_layout_inventory",
            [sys.executable, "tools/classify_memory_v06.py", "--json", str(memory_map)], work1)
        if memory_map.exists():
            memory_data = json.loads(memory_map.read_text())
            classification["inventory"] = {
                "rom_sha256": memory_data.get("rom_sha256"),
                "coverage": memory_data.get("coverage"),
                "reclaimable_bytes": memory_data.get("reclaimable_bytes"),
                "mixed_regions": memory_data.get("mixed_regions"),
            }
            if memory_data.get("rom_sha256") != h1:
                classification.update(status="FAIL", reason="memory classification bound to wrong ROM")
            if memory_data.get("coverage", {}).get("unclassified_bytes") != 0:
                classification.update(status="FAIL", reason="memory classification has uncovered bytes")
            report["memory_classification"] = memory_data
            save()
        if sha(image1) != h1:
            raise RuntimeError("tested ROM changed during checks")
        if any(not Path(p).exists() or sha(p) != h for p, h in report["dependency_files"].items()):
            raise RuntimeError("external test dependency changed during checks")
    except Exception as exc:
        report["checks"].append({"name": "verification_environment", "category": "infrastructure",
                                  "status": "ERROR", "reason": str(exc)})
    finally:
        if before is not None:
            unchanged = (inventory(ROOT) == before and rom.exists()
                         and sha(rom) == report.get("working_rom_sha256"))
            report["checks"].append({"name": "working_tree_unchanged", "category": "integrity",
                                      "status": "PASS" if unchanged else "ERROR"})
        statuses = {r["status"] for r in report["checks"]}
        report["status"] = ("ERROR" if "ERROR" in statuses else "FAIL" if "FAIL" in statuses
                            else "BASELINE_PASS" if args.profile == "baseline" else "CHECKS_PASS")
        save()
        lines = ["# Verification report", "", f"Status: **{report['status']}**",
                 f"Profile: `{args.profile}`", f"Tested ROM: `{report.get('tested_rom_sha256', 'not built')}`", "",
                 "| Check | Kind | Status |", "|---|---|---|"]
        lines.extend(f"| {r['name']} | {r['category']} | {r['status']} |" for r in report["checks"])
        lines += ["", "## Coverage limits", ""] + ["- " + x for x in report["coverage_limits"]]
        lines += ["", "Commands, hashes, timings, errors and raw logs: report.json and logs/."]
        (out / "report.md").write_text("\n".join(lines) + "\n")
        print(f"{report['status']}: {out / 'report.md'}", flush=True)
    return 2 if report["status"] == "ERROR" else 1 if report["status"] == "FAIL" else 0


if __name__ == "__main__":
    sys.exit(main())
