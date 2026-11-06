#!/usr/bin/env python3
"""Write the real addresses of adapter labels back into cfg/labels.json.

  python3 tools/link_labels.py           # update, regenerate includes
  python3 tools/link_labels.py --check   # fail if an address is out of date

A unit that owns labels (tools/gen_labels.py) is assembled on its own; the
listing gives each owned label's address. Changed addresses go into
cfg/labels.json, the includes are regenerated, and the units are assembled
again until nothing moves (label values never change instruction sizes, so
this settles in two rounds). tools/build_v06_rom.py runs it first, so an
adapter routine may grow and push the next entry along: every other module
follows through labels.inc. Signatures (`sig`) of moved labels are cleared
here and refreshed from the built ROM (tools/build_v06_rom.py).
"""
from __future__ import annotations

import shutil
import os
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import gen_labels  # noqa: E402

SJASM = Path(os.environ.get("ZASM") or shutil.which("zasm") or str(Path.home() / "projects/kvalley-v06c/tools/bin/sjasm"))
CFG = ROOT / "cfg/labels.json"


def assemble(unit: str, tmp: Path) -> dict[str, int]:
    src = gen_labels.SRCDIR / f"{unit}.asm"
    lst, out = tmp / f"{unit}.lst", tmp / f"{unit}.bin"
    r = subprocess.run([str(SJASM), "--8080", "-b", "-w", str(src), str(lst), str(out)],
                       capture_output=True, text=True, cwd=gen_labels.SRCDIR)
    text = r.stdout + r.stderr
    if "error" in text.lower() and "no errors" not in text.lower():
        raise SystemExit(f"link: {unit}.asm does not assemble:\n{text[-1500:]}")
    syms = {}
    for line in lst.read_text(errors="replace").splitlines():
        m = re.match(r"([A-Za-z_]\w*)\s+=\s+\$([0-9A-Fa-f]+)", line)
        if m:
            syms[m.group(1)] = int(m.group(2), 16)
    return syms


def link(check: bool = False) -> list[str]:
    moved: list[str] = []
    if not check:
        gen_labels.main()
    for _ in range(4):
        cfg = json.loads(CFG.read_text())
        labels = cfg["labels"]
        own = gen_labels.owners(labels)
        changed = []
        with tempfile.TemporaryDirectory() as t:
            for unit in sorted(set(own.values())):
                syms = assemble(unit, Path(t))
                for name, u in own.items():
                    if u != unit:
                        continue
                    if name not in syms:
                        raise SystemExit(f"link: {name} not in {unit}.lst")
                    want = f"{syms[name]:04X}"
                    if labels[name]["addr"] != want:
                        changed.append(f"{name} {labels[name]['addr']} -> {want}")
                        labels[name]["addr"] = want
                        labels[name].pop("sig", None)
        if not changed:
            return moved
        if check:
            return changed
        moved += changed
        CFG.write_text(json.dumps(cfg, indent=2, ensure_ascii=False) + "\n")
        gen_labels.main()
    raise SystemExit("link: addresses do not settle: " + "; ".join(changed))


def refresh_sigs(mem: bytes, base: int = 0) -> int:
    """Signature = first 3 bytes at the address in the built image, for every
    adapter-owned code label (its bytes change when a call target moves)."""
    cfg = json.loads(CFG.read_text())
    labels = cfg["labels"]
    own = gen_labels.owners(labels)
    n = 0
    for name in own:
        e = labels[name]
        if e["kind"].endswith("_code"):
            a = int(e["addr"], 16) - base
            sig = bytes(mem[a:a + 3]).hex()
            if e.get("sig") != sig:
                e["sig"] = sig
                n += 1
    if n:
        CFG.write_text(json.dumps(cfg, indent=2, ensure_ascii=False) + "\n")
    return n


def main() -> int:
    check = "--check" in sys.argv
    res = link(check)
    if check:
        if res:
            print("labels out of date: " + "; ".join(res))
            return 1
        print("adapter label addresses up to date")
        return 0
    print("\n".join(res) if res else "no label moved")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
