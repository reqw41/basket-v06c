#!/usr/bin/env python3
"""Reproducible pack/unpack experiment on real Basket resources.

Measures simple codecs against title, court, stamp, and stage-1 blob.
Verifies exact round-trip of source bytes. Reports packed size, decoder
overhead estimate, and a scaled projection for dual-plane color data.

Does not produce final art. Does not modify the working ROM.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ROM = ROOT / "build/v06/basket.rom"


def rle_encode(data: bytes) -> bytes:
    """Byte RLE: [literal_len|0x80+run_len] payloads. Good baseline, not final."""
    out = bytearray()
    i = 0
    n = len(data)
    while i < n:
        run = 1
        while i + run < n and data[i + run] == data[i] and run < 127:
            run += 1
        if run >= 3:
            out.append(0x80 | run)
            out.append(data[i])
            i += run
            continue
        j = i
        while j < n:
            run2 = 1
            while j + run2 < n and data[j + run2] == data[j] and run2 < 127:
                run2 += 1
            if run2 >= 3:
                break
            j += 1
            if j - i >= 127:
                break
        lit = data[i:j]
        out.append(len(lit))
        out.extend(lit)
        i = j
    return bytes(out)


def rle_decode(data: bytes) -> bytes:
    out = bytearray()
    i = 0
    while i < len(data):
        ctrl = data[i]
        i += 1
        if ctrl & 0x80:
            run = ctrl & 0x7F
            out.extend([data[i]] * run)
            i += 1
        else:
            out.extend(data[i : i + ctrl])
            i += ctrl
    return bytes(out)


def load_slices(mem: bytes) -> dict[str, bytes]:
    # SFX used region measured earlier: 7FBA..8089 inclusive-ish (208 bytes)
    return {
        "title_1000": bytes(mem[0x1000:0x1B40]),
        "court_2500": bytes(mem[0x2500:0x3300]),
        "stamp_B338": bytes(mem[0xB338:0xB498]),
        "stage1_gfx_415A": bytes(mem[0x415A:0x7AE8]),
        "music_7B9D": bytes(mem[0x7B9D:0x7FBA]),
        "sfx_used": bytes(mem[0x7FBA:0x7FBA + 208]),
    }


def pack_report(name: str, raw: bytes) -> dict:
    rle = rle_encode(raw)
    if rle_decode(rle) != raw:
        raise RuntimeError(f"RLE round-trip failed for {name}")
    z = zlib.compress(raw, 9)
    if zlib.decompress(z) != raw:
        raise RuntimeError(f"zlib round-trip failed for {name}")
    return {
        "name": name,
        "raw": len(raw),
        "sha256": hashlib.sha256(raw).hexdigest(),
        "rle": len(rle),
        "rle_ratio": round(len(rle) / len(raw), 4),
        "zlib": len(z),
        "zlib_ratio": round(len(z) / len(raw), 4),
        "round_trip": True,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--json", type=Path)
    args = ap.parse_args()
    if not ROM.exists():
        print(f"missing {ROM}", file=sys.stderr)
        return 2
    mem = bytearray(0x10000)
    img = ROM.read_bytes()
    mem[0x100 : 0x100 + len(img)] = img
    slices = load_slices(mem)
    rows = [pack_report(k, v) for k, v in slices.items()]
    selected = ["title_1000", "court_2500", "stamp_B338", "stage1_gfx_415A", "music_7B9D", "sfx_used"]
    sel = [r for r in rows if r["name"] in selected]
    raw_sum = sum(r["raw"] for r in sel)
    rle_sum = sum(r["rle"] for r in sel)
    zlib_sum = sum(r["zlib"] for r in sel)
    # Each independently addressable stream gets a 00 terminator. The actual
    # decoder lives in code, not in the 20K resource section.
    stream_terminators = len(sel)
    stored_rle = rle_sum + stream_terminators
    decoder_rle_bytes = None
    lst = ROOT / "build/v06/glue.lst"
    if lst.exists():
        import re
        syms = {}
        for line in lst.read_text(errors="replace").splitlines():
            m = re.match(r"(RLE_UNPACK(?:_END)?)\s+=\s+\$([0-9A-Fa-f]+)", line)
            if m: syms[m.group(1)] = int(m.group(2), 16)
        if {"RLE_UNPACK", "RLE_UNPACK_END"} <= syms.keys():
            decoder_rle_bytes = syms["RLE_UNPACK_END"] - syms["RLE_UNPACK"]
    scratch_est = 1280  # shared gfx work is available for on-demand decode
    dual_plane_scaled_rle = int(stored_rle * 2)
    report = {
        "rom_sha256": hashlib.sha256(img).hexdigest(),
        "slices": rows,
        "selected_mono": {
            "raw": raw_sum,
            "rle": rle_sum,
            "zlib": zlib_sum,
            "stream_terminators": stream_terminators,
            "stored_rle": stored_rle,
            "decoder_rle_bytes_in_code": decoder_rle_bytes,
            "scratch_est": scratch_est,
            "resources_capacity": 20480,
            "rle_fits_capacity": stored_rle <= 20480,
            "zlib_fits_capacity": zlib_sum + stream_terminators <= 20480,
        },
        "four_color_projection": {
            "method": "scale mono RLE by ×2 for dual planes (no mask); not measured color art",
            "dual_plane_rle_est": dual_plane_scaled_rle,
            "plus_scratch": dual_plane_scaled_rle + scratch_est,
            "fits_20k": dual_plane_scaled_rle <= 20480,
            "attr_on_blit_note": (
                "Preferred path keeps 1-bit bitmaps + small attribute maps; "
                "then packed size stays near mono RLE, not ×2."
            ),
        },
        "limitations": [
            "Codecs are experimental; not wired into the game.",
            "zlib is host-side reference only (no 8080 decoder budgeted).",
            "Color projection is scaled, not authored CPC/2+2 assets.",
            "HUD font (1852) not included in selected_mono pack sum.",
        ],
    }
    text = json.dumps(report, indent=2)
    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(text + "\n")
    print(f"rom={report['rom_sha256'][:16]}…")
    for r in rows:
        print(
            f"  {r['name']:14s} raw={r['raw']:5d} rle={r['rle']:5d} "
            f"({r['rle_ratio']:.2f}) zlib={r['zlib']:5d} ({r['zlib_ratio']:.2f})"
        )
    s = report["selected_mono"]
    print(
        f"selected mono raw={s['raw']} stored_rle={s['stored_rle']} "
        f"decoder_code={s['decoder_rle_bytes_in_code']} fits20k={s['rle_fits_capacity']}"
    )
    f = report["four_color_projection"]
    print(
        f"dual-plane RLE est={f['dual_plane_rle_est']} "
        f"+scratch={f['plus_scratch']} fits20k={f['fits_20k']}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
