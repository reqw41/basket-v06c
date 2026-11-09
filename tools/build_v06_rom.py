#!/usr/bin/env python3
"""Build the Vector-06C Basket Master ROM.

Usage:
    python3 tools/build_v06_rom.py

Output:
    build/v06/basket.rom  - Vector-native image (0100..FFFF, 65280 bytes)
                            Loads at 0x0100 under Emu80 --run / vector06js

The main game stays at `84D0..B257`. The court and former `D09C..DD17`
system/HUD block are relocated below `4000`, and all decoded absolute
operands are checked through `cfg/high_memory_relocation.json`.

In-memory map after boot (page0 installed from PAGE0_BLOB@0E00):
    0000..00FF  RST vectors and BIOS stubs (copied at boot)
    0100..0EFF  Boot + native colour adapter, kbd, snd
    0F00..0FFF  Adapter work RAM
    1000..1B3F  Menu LZ, court tile tail, native helpers and tile cache
    1B40..1FFF  Replay state/ring workspace (mapped records end at 1FE0)
    2000..24FF  Shared gfx work: menu 32×40 or replay 16×60
    2500..32FF  CPC court tile map and interleaved two-plane tiles
    3300..3303  Relocated D252 pointers
    3304..3F7F  Relocated system/HUD block
    3F80         Relocated legacy sentinel
    7AE8..7FB9  CPC AY SFX+music (src/assets/cpc_snd_ay.bin), then packed
    7FBA..8089  Packed VI53 sound effects (SFX moved here; 7AE8 ← court helpers)
    7AE8..7B95  Direct CPC-style court colour helpers (after snd pack)
    808A..8411  Packed low/high HUD decoration
    8412..84CF  Streaming menu/HUD background helpers + COMPOSE_BOX tile band copier
    B258..B2C4  DIRTY_OLD; B2C5..B330 previous sprite metadata
    B498..BBFF  Staged sprite stream (replay composes from it in place)
    4000..7FBF  Game work RAM + stage-1 data (415A..7FB9)
    84D0..B257  Main game overlay
    BC00..BFFF  Stack (SP=C000)
    C000..DFFF  Active high colour-bit plane (splash pre-rendered here)
    E000..FFFF  Active low colour-bit plane (splash pre-rendered here)

The CPC four-pen target table is defined in cfg/cpc_palette.json. PAL_WRITE
installs it during IRQ; direct sprites and replay use E000 as bit 0 and C000
as bit 1.

Port patching (in game binary):
    D3 98 (OUT 98,A) -> CF 00 (RST 08; NOP)
    D3 99 (OUT 99,A) -> D7 00 (RST 10; NOP)
    DB 99 (IN A,99)  -> E7 00 (RST 20; NOP)
    DB 98 (IN A,98)  -> EF 00 (RST 28; NOP)
All 61 occurrences in the overlay are real VDP I/O (checked by
tools/scan_native.py).
"""

import shutil
import os
import hashlib
import json
import re
import subprocess
import sys
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SJASM = Path(os.environ.get("ZASM") or shutil.which("zasm") or str(Path.home() / "projects/kvalley-v06c/tools/bin/sjasm"))

MSX = ROOT / "ref/msx/executive"
OUTDIR = ROOT / "build/v06"
OUTROM = OUTDIR / "basket.rom"

GAME_BASE = 0x84D0
PAGE0_BLOB = 0x0E00
ADAPTER_END = 0x0F00

# MSX high-RAM blocks that sit in the Vector visible plane
TITLE_MSX, TITLE_V06, TITLE_LEN = 0xE740, 0x1000, 0x0B40
RING_MSX, RING_V06 = 0xDE44, 0x1B40
REPLAY_STAGE = 0x2000       # shared menu/replay work buffer
HOOK_SCRATCH = 0x0FF0      # MSX hook FEE4..FEE6 (never called on Vector)
GAME_STACK = 0xC000        # stack grows into BC00..BFFF, below plane 0
COURT_OLD, COURT_NEW, COURT_SIZE = 0xB498, 0x2500, 0x0E00
D_PTR_OLD, D_PTR_NEW, D_PTR_SIZE = 0xD098, 0x3300, 4
D_CODE_OLD, D_CODE_NEW, D_CODE_END = 0xD09C, 0x3304, 0xDD18
LEGACY_SENTINEL_OLD, LEGACY_SENTINEL_NEW = 0xC854, 0x3F80
NATIVE_ROWREAD = 0x01E0    # glue.asm fixed entries
NATIVE_ROWWRITE = 0x01E3
NATIVE_COURT = 0x01E6
NATIVE_SPRITE = 0x01E9
NATIVE_STAMP = 0x01EC
NATIVE_FRAME = 0x01EF
NATIVE_RESET = 0x01F2
NATIVE_DIRTY = 0x01F5
NATIVE_BOXES = 0x01F8
NATIVE_TITLE = 0x01FB
CPC_SPRITES = ROOT / "src/assets/cpc_sprites_v06_2plane.bin"
CPC_SPRITE_BASE = 0x415A
LABELS = {n: int(e["addr"], 16) for n, e in
          json.loads((ROOT / "cfg/labels.json").read_text())["labels"].items()}
CPC_SPRITE_COUNT = 75
CPC_SPRITE_POINTER_BYTES = CPC_SPRITE_COUNT * 2
CPC_SPRITE_SHA256 = "aaa70a457986d3605567bdcf65b1ea0299f623f444100a218c4d8215f6f69aa1"
CPC_SND = ROOT / "src/assets/cpc_snd_ay.bin"
CPC_SND_ADDR = 0x7AE8  # SFX 7AE8..7B9C + music 7B9D..7FB9
CPC_SND_SHA256 = "15112d772ba6f9947109e75d301d030784765227270b6e356823275c42fa1d5b"
COURT_BG = ROOT / "src/assets/court_bg_v06.bin"
HUD_DECOR_RLE = ROOT / "src/assets/hud_decor_v06.rle"
HUD_COLOR_HI_RLE = ROOT / "src/assets/hud_color_hi_v06.rle"
SPLASH_PLANES_Z = ROOT / "src/assets/splash_planes_v06.z"
HUD_PACKED_ADDR = 0x808A
HUD_HIGH_PACKED_ADDR = 0x810B
BG_HELPERS_ADDR = 0x8412
COURT_HELPERS_ADDR = 0x7AE8


def splash_plane_pair() -> tuple[bytes, bytes]:
    """Decompress CPC loading splash (Vector pens already applied)."""
    planes = zlib.decompress(SPLASH_PLANES_Z.read_bytes())
    if len(planes) != 0x4000:
        raise RuntimeError(f"splash planes unpack to {len(planes)}, want 16384")
    low, high = bytearray(planes[:0x2000]), bytearray(planes[0x2000:])
    return bytes(low), bytes(high)


def patch_ports(data: bytearray) -> dict:
    stats = {"out98": 0, "out99": 0, "in99": 0, "in98": 0}
    table = {
        (0xD3, 0x98): (0xCF, "out98"),
        (0xD3, 0x99): (0xD7, "out99"),
        (0xDB, 0x99): (0xE7, "in99"),
        (0xDB, 0x98): (0xEF, "in98"),
    }
    for i in range(len(data) - 1):
        hit = table.get((data[i], data[i + 1]))
        if hit:
            data[i], data[i + 1] = hit[0], 0x00
            stats[hit[1]] += 1
    return stats


def pin(name: str, address: int) -> int:
    """Fixed address of an adapter entry: the linked label when it has one
    (tools/link_labels.py moves it with the code), else the old constant."""
    return LABELS.get(name, address)


def load_syms(lst: Path) -> dict:
    syms = {}
    for line in lst.read_text(errors="replace").splitlines():
        m = re.match(r"([A-Za-z_][A-Za-z0-9_]*)\s+=\s+\$([0-9A-Fa-f]+)", line)
        if m:
            syms[m.group(1)] = int(m.group(2), 16)
    return syms


def assemble_glue() -> bytes:
    src = ROOT / "src/v06/glue.asm"
    out = OUTDIR / "glue.bin"
    lst = OUTDIR / "glue.lst"
    if out.exists():
        out.unlink()
    result = subprocess.run(
        [str(SJASM), "--8080", "-b", "-w", str(src), str(lst), str(out)],
        capture_output=True, text=True, cwd=ROOT / "src/v06"
    )
    output = result.stdout + result.stderr
    if not out.exists() or ("error" in output.lower() and "no errors" not in output.lower()):
        print(f"Assembly failed:\n{output}")
        sys.exit(1)
    syms = load_syms(lst)
    # Glue entries float (tools/link_labels.py); only the page-0 image is fixed.
    if syms.get("GLUE_END", 0x10000) > PAGE0_BLOB:
        raise RuntimeError(f"glue ends at {syms.get('GLUE_END', 0):04X}, past the page-0 image {PAGE0_BLOB:04X}")
    return out.read_bytes()


def install_adapter_hi(rom: bytearray) -> None:
    """Adapter unit at ADAPTER_HI (freed sprite space): colour sprites, joystick."""
    src, lst, out = ROOT / "src/v06/adapter_hi.asm", OUTDIR / "adapter_hi.lst", OUTDIR / "adapter_hi.bin"
    if out.exists():
        out.unlink()
    r = subprocess.run([str(SJASM), "--8080", "-b", "-w", str(src), str(lst), str(out)],
                       capture_output=True, text=True, cwd=ROOT / "src/v06")
    text = r.stdout + r.stderr
    if not out.exists() or ("error" in text.lower() and "no errors" not in text.lower()):
        raise RuntimeError(f"adapter_hi assembly failed:\n{text}")
    syms = load_syms(lst)
    lo, hi = LABELS["ADAPTER_HI"], syms["ADAPTER_HI_END"]
    if hi > 0x7760:  # sprite pointer table
        raise RuntimeError(f"adapter_hi unit {lo:04X}..{hi:04X} runs into the sprite table at 7760")
    rom[lo:hi] = out.read_bytes()[:hi - lo]
    print(f"[3] adapter_hi unit {lo:04X}..{hi - 1:04X} ({hi - lo} bytes)")


def assemble_window_slot() -> bytes:
    """Zero A524..A52B (former SET_VBLANK) + BIOS_CLICK (9) from ORG A524."""
    src = ROOT / "src/v06/win_a524.asm"
    out = OUTDIR / "win_a524.bin"
    lst = OUTDIR / "win_a524.lst"
    if out.exists():
        out.unlink()
    result = subprocess.run(
        [str(SJASM), "--8080", "-b", "-w", str(src), str(lst), str(out)],
        capture_output=True, text=True, cwd=ROOT / "src/v06",
    )
    output = result.stdout + result.stderr
    if not out.exists() or ("error" in output.lower() and "no errors" not in output.lower()):
        print(f"win_a524 assembly failed:\n{output}")
        sys.exit(1)
    raw = out.read_bytes()
    if len(raw) == 17:
        blob = raw
    elif len(raw) >= 0xA524 + 17:
        blob = raw[0xA524:0xA524 + 17]
    else:
        raise RuntimeError(f"win_a524.bin is {len(raw)} bytes, want 17")
    if any(blob[:8]) or blob[8] != 0xFE:  # cp 1 (BIOS_CLICK)
        raise RuntimeError(f"window slot bytes unexpected: {blob.hex()}")
    return blob


def assemble_background_helpers() -> bytes:
    """Direct menu/HUD renderers for the free pre-entry slot."""
    src = ROOT / "src/v06/win_840e.asm"
    out = OUTDIR / "win_840e.bin"
    lst = OUTDIR / "win_840e.lst"
    if out.exists():
        out.unlink()
    result = subprocess.run(
        [str(SJASM), "--8080", "-b", "-w", str(src), str(lst), str(out)],
        capture_output=True, text=True, cwd=ROOT / "src/v06",
    )
    output = result.stdout + result.stderr
    if not out.exists() or ("error" in output.lower() and "no errors" not in output.lower()):
        raise RuntimeError(f"win_840e assembly failed:\n{output}")
    raw = out.read_bytes()
    syms = load_syms(lst)
    if syms.get("MENU_BG_RELOAD") != BG_HELPERS_ADDR:
        raise RuntimeError("MENU_BG_RELOAD moved")
    if syms.get("HUD_DECOR") != pin("HUD_DECOR", 0x8432):
        raise RuntimeError(f"HUD_DECOR moved to {syms.get('HUD_DECOR', 0):04X}")
    if BG_HELPERS_ADDR + len(raw) > GAME_BASE:
        raise RuntimeError("background helpers overlap game entry")
    return raw


def assemble_player_scene_helpers() -> bytes:
    src = ROOT / "src/v06/menu_player_helpers.asm"
    out = OUTDIR / "menu_player_helpers.bin"
    lst = OUTDIR / "menu_player_helpers.lst"
    out.unlink(missing_ok=True)
    result = subprocess.run([str(SJASM), "--8080", "-b", "-w", str(src), str(lst), str(out)],
                            capture_output=True, text=True, cwd=ROOT / "src/v06")
    if result.returncode or not out.exists():
        raise RuntimeError(f"scene helper assembly failed: {result.stdout}{result.stderr}")
    syms = load_syms(lst)
    for name, address in {"HUD_TEXT_REFRESH": 0x190A,
                          "PLAYER_BACKGROUND_HIGH": 0x1930,
                          "PLAYER_COMPOSE_CLIPPED": 0x1950,
                          "PLAYER_BACKGROUND_ROW": 0x1AC0}.items():
        if syms.get(name) != pin(name, address):
            raise RuntimeError(f"scene helper {name} moved")
    raw = out.read_bytes()
    if 0x18CA + len(raw) > RING_V06:
        raise RuntimeError("scene helpers overlap replay ring")
    return raw


def assemble_fast_clear() -> bytes:
    """Timing-safe dirty high-plane restorer in the free 3F81 tail."""
    src = ROOT / "src/v06/win_3f81.asm"
    out = OUTDIR / "win_3f81.bin"
    lst = OUTDIR / "win_3f81.lst"
    if out.exists():
        out.unlink()
    result = subprocess.run(
        [str(SJASM), "--8080", "-b", "-w", str(src), str(lst), str(out)],
        capture_output=True, text=True, cwd=ROOT / "src/v06",
    )
    output = result.stdout + result.stderr
    if not out.exists() or ("error" in output.lower() and "no errors" not in output.lower()):
        raise RuntimeError(f"win_3f81 assembly failed:\n{output}")
    raw = out.read_bytes()
    syms = load_syms(lst)
    if syms.get("COLOR_CLEAR_ROW_COMPLEX") != pin("COLOR_CLEAR_ROW_COMPLEX", 0x3F81):
        raise RuntimeError("COLOR_CLEAR_ROW_COMPLEX moved")
    if 0x3F81 + len(raw) > 0x4000:
        raise RuntimeError("fast clear overlaps 4000 reserve")
    return raw


CPC_STAMP_ASSET = ROOT / "src/assets/cpc_stand_stamp_mode1.bin"
CPC_STAMP_SHA256 = "611ca3b79619d3513b19798ddf5e3b993a3a656ac10fda4b82830640ce8595fa"
CPC_STAMP_DATA = 0x77F6   # former MSX scoreboard art (only AFC8 read it)


def install_joy_p(rom: bytearray) -> None:
    """JOY_MERGE / NATIVE_PADS live in adapter_hi.asm; 7A57..7AE7 after the
    stamp data is free."""
    if CPC_STAMP_DATA + CPC_STAMP_ASSET.stat().st_size != 0x7A57:
        raise RuntimeError("CPC stamp data no longer ends at 7A56")
    rom[0x7A57:0x7AE8] = bytes(0x7AE8 - 0x7A57)


DEAD_VDP_BODIES = (
    # (lo, hi, why) — unreachable procedures that still held RST 08/10/20/28
    (0x359C, 0x35C0, "MSX VPOKE/VPEEK helpers (D334/D347): no callers"),
    (0xA8FB, 0xA95E, "old A8F4 replay doubling + A93C: A8F4 jumps to REPLAY_ZOOM"),
    (0xB201, 0xB234, "old B1FE row copier: B1FE jumps to NATIVE_FRAME"),
)
DEAD_CODE = (
    # (lo, hi, why) — no CALL/JP/JR/LD-immediate reaches them (checked below)
    (0xAFC8, 0xB01C, "AFC8 MSX scoreboard blit + B004 helper: 92B5 call removed"),
    (0xA54A, 0xA5FD, "A54A MSX title panels via D252: A605 calls NATIVE_TITLE"),
    (0x352B, 0x35C0, "D2C3 RAM-buffer blit branch: flag 341C is never written"),
    (0x9300, 0x932A, "92E8 tail: TMS colour boxes via A0AD after the RET at 92FE"),
)
JUMP_OPS = {0xCD, 0xC3, 0xCA, 0xC2, 0xDA, 0xD2, 0xCC, 0xC4, 0xDC, 0xD4,
            0xF2, 0xFA, 0xE2, 0xEA, 0xF4, 0xFC, 0xE4, 0xEC,
            0x21, 0x11, 0x01, 0x31, 0x22, 0x2A, 0x32, 0x3A}
# LD rr,nn immediates that only look like pointers (data bytes / coordinates)
FALSE_REFS = {0x7A22}
# Adapter sites whose immediate + the next opcode read as such a pointer
# (the scan is not instruction-aligned): (glue symbol, byte offset).
FALSE_REF_SITES = (
    ("mt_next", 7),           # `cp MT_END & 0xFF` = FE 21, `jp nz,mt_ch` = C2 A5 06
    ("PAUSE_EXIT_TEST", 7),   # `cp 3Ah / ret / xor a` = FE 3A C9 AF: "ld a,(AFC9)"
)


def code_refs_into(rom: bytearray, lo: int, hi: int) -> list[str]:
    out = []
    for i in range(0x100, 0xC000 - 2):
        if lo <= i < hi or i in FALSE_REFS:
            continue
        op, t = rom[i], rom[i + 1] | rom[i + 2] << 8
        if op in JUMP_OPS and lo <= t < hi:
            out.append(f"{i:04X}")
        if op in (0x18, 0x20, 0x28, 0x30, 0x38, 0x10):
            d = rom[i + 1] - 256 if rom[i + 1] > 127 else rom[i + 1]
            if lo <= i + 2 + d < hi:
                out.append(f"{i:04X}jr")
    return out


def fix_unrelocated(rom: bytearray) -> None:
    """Operands the relocation manifest missed (DD-prefixed forms)."""
    # 3A21 (MSX D789) LD (D1BA),IX: D1BA is the C000 video plane here; the
    # D-block copy of D1BA is 3422 (as the 2A loads at D30E/D8D7 already use).
    if rom[0x3A21:0x3A25] != bytes.fromhex("dd22bad1"):
        raise RuntimeError(f"3A21: {rom[0x3A21:0x3A25].hex()}, want DD22BAD1")
    rom[0x3A23:0x3A25] = (0x3422).to_bytes(2, "little")


def zero_dead_code(rom: bytearray) -> None:
    """After relocation: clear MSX procedures nothing can reach any more."""
    # D241 tested the never-written 341C to branch into the RAM blit; D24C
    # (no callers) tested unrelocated D1B4 (now the C000 video plane).
    if rom[0x34AC:0x34BA] != bytes.fromhex("b7207c213e0018093ab4d1b72076"):
        raise RuntimeError("34AC: D241/D24C heads moved")
    rom[0x34AD:0x34AF] = bytes(2)            # OR A / (no JR NZ)
    rom[0x34B4:0x34BA] = bytes(6)            # D24C falls into the D252 copy
    for lo, hi, why in DEAD_CODE:
        refs = code_refs_into(rom, lo, hi)
        if refs:
            raise RuntimeError(f"{lo:04X}..{hi - 1:04X} ({why}) is referenced from {refs[:8]}")
        rom[lo:hi] = bytes(hi - lo)


DEAD_VDP_SHA = {
    0x359C: "2a9ad07df3d7007cf640d700fb3a98d0cf00c92a9ad07df3d7007cd700fbef003298d0c9",
    0xB201: "2214b2210001112000060ec5e57df3cd23b2210000010001092214b2e124c110eac9d7007cf640d700fbf620672a14b2cde301",
}


def zero_dead_vdp_bodies(rom: bytearray) -> None:
    """After relocation: clear the dead MSX VDP procedures (no RST 08..28 left)."""
    for lo, hi, why in DEAD_VDP_BODIES:
        want = DEAD_VDP_SHA.get(lo)
        if want and rom[lo:hi].hex() != want:
            raise RuntimeError(f"{lo:04X}: not the expected dead body ({why})")
        if lo == 0xA8FB and (rom[0xA8F4] != 0xC3 or rom[0xA93C:0xA93E] != bytes.fromhex("f57c")):
            raise RuntimeError("A8F4 no longer jumps away / A93C moved")
        if lo == 0xB201 and rom[0xB1FE] != 0xC3:
            raise RuntimeError("B1FE no longer jumps away")
        rom[lo:hi] = bytes(hi - lo)


def install_no_vdp_status(rom: bytearray) -> None:
    """VDP status reads and register writes (after relocation).

    36F3 game ISR: DI / PUSH AF / IN A,(99h) / AND A / JP P,skip. The Vector
    only enters it from the frame IRQ, so the status is always "vblank".
    35C1 init read clears a status nobody keeps. 3760 wrote VDP R1 (display
    on/off shadow kept in 342D); the Vector display is always on.
    """
    sites = (
        (0x36F5, "e700", "3e80", "game ISR: status → frame IRQ (LD A,80h)"),
        (0x35C1, "e700", "0000", "init status read dropped"),
        (0x3760, "78d70079f680d700c9", "c9" + "00" * 8, "VDP R1 write → RET"),
    )
    for site, old, new, _ in sites:
        old_b, new_b = bytes.fromhex(old), bytes.fromhex(new)
        if rom[site:site + len(old_b)] != old_b:
            raise RuntimeError(f"{site:04X}: {rom[site:site + len(old_b)].hex()}, want {old}")
        rom[site:site + len(old_b)] = new_b


def install_native_blit(rom: bytearray) -> None:
    """34BD..352A: MSX VRAM blitter body → pointer advance only (after relocation)."""
    src = ROOT / "src/v06/blit_native.asm"
    out = OUTDIR / "blit_native.bin"
    lst = OUTDIR / "blit_native.lst"
    out.unlink(missing_ok=True)
    result = subprocess.run(
        [str(SJASM), "--8080", "-b", "-w", str(src), str(lst), str(out)],
        capture_output=True, text=True, cwd=ROOT / "src/v06",
    )
    output = result.stdout + result.stderr
    if not out.exists() or ("error" in output.lower() and "no errors" not in output.lower()):
        raise RuntimeError(f"blit_native assembly failed:\n{output}")
    code = out.read_bytes()
    syms = load_syms(lst)
    if syms.get("BLIT_NATIVE_END", 0xFFFF) > 0x352B or syms.get("BLIT_ADVANCE") != pin("BLIT_ADVANCE", 0x34E2):
        raise RuntimeError("native blit stub must fit 34BD..352A")
    body = bytes.fromhex(
        "220f353a01330707076f3a0033cb3fcb3fcb3ff64067ed5b0a337b070707321f35e5cdf034"
        "3a2434672e3e220f35e17cf620673a0833cb3fcb3fcb3f47c5e57df3d7007cd700fb2a0233"
        "3a0a3347c5e506087e00cf001910f9e123c110f02a023301000009220233e124c110d0c9")
    if rom[0x34BD:0x352B] != body:
        raise RuntimeError("34BD is not the relocated MSX VRAM blitter")
    rom[0x34BD:0x352B] = code + bytes(0x352B - 0x34BD - len(code))


def install_native_wipe(rom: bytearray) -> None:
    """A0BF post-score wipe: A0D0 column copy and A132 colour curtain, native."""
    src = ROOT / "src/v06/wipe_native.asm"
    out = OUTDIR / "wipe_native.bin"
    lst = OUTDIR / "wipe_native.lst"
    out.unlink(missing_ok=True)
    result = subprocess.run(
        [str(SJASM), "--8080", "-b", "-w", str(src), str(lst), str(out)],
        capture_output=True, text=True, cwd=ROOT / "src/v06",
    )
    output = result.stdout + result.stderr
    if not out.exists() or ("error" in output.lower() and "no errors" not in output.lower()):
        raise RuntimeError(f"wipe_native assembly failed:\n{output}")
    code = out.read_bytes()
    syms = load_syms(lst)
    if syms.get("WIPE_COLUMN") != pin("WIPE_COLUMN", 0xA0D0) or syms.get("WIPE_COLUMN_END", 0xFFFF) > 0xA132:
        raise RuntimeError("WIPE_COLUMN must fit A0D0..A131")
    if syms.get("WIPE_COLOUR") != pin("WIPE_COLOUR", 0xA132):
        raise RuntimeError("WIPE_COLOUR must sit at A132")
    # A0BF: LD IX,(dir) / LD C,31h / CALL A0D0 / CALL A132 / HALT / DEC C / JR NZ / RET
    if rom[0xA0C3:0xA0D0] != bytes.fromhex("0e31cdd0a0cd32a1760d20f6c9"):
        raise RuntimeError(f"A0BF loop {rom[0xA0BF:0xA0D0].hex()}")
    if rom[0xA0D0:0xA0D2] != bytes.fromhex("060f") or rom[0xA132:0xA134] != bytes.fromhex("060f"):
        raise RuntimeError("A0D0/A132 are not the MSX wipe bodies")
    rom[0xA0D0:0xA1AA] = bytes(0xA1AA - 0xA0D0)
    rom[0xA0D0:0xA0D0 + len(code)] = code


def install_hud_icon(rom: bytearray) -> None:
    """8AAE possession icon: D252 mono blit → CPC sprites 72/73 (after relocation)."""
    src = ROOT / "src/v06/hud_icon.asm"
    out = OUTDIR / "hud_icon.bin"
    lst = OUTDIR / "hud_icon.lst"
    out.unlink(missing_ok=True)
    result = subprocess.run(
        [str(SJASM), "--8080", "-b", "-w", str(src), str(lst), str(out)],
        capture_output=True, text=True, cwd=ROOT / "src/v06",
    )
    output = result.stdout + result.stderr
    if not out.exists() or ("error" in output.lower() and "no errors" not in output.lower()):
        raise RuntimeError(f"hud_icon assembly failed:\n{output}")
    code = out.read_bytes()
    syms = load_syms(lst)
    if (syms.get("HUD_ICON") != pin("HUD_ICON", 0xB455) or syms.get("TIME_TEXT") != pin("TIME_TEXT", 0xB485)
            or 0xB455 + len(code) > 0xB498):
        raise RuntimeError("HUD_ICON must fit B455..B497")
    if any(rom[0xB455:0xB498]):
        raise RuntimeError("B455..B497 is not free for HUD_ICON")
    rom[0xB455:0xB455 + len(code)] = code
    for index in (72, 73):
        ptr = int.from_bytes(rom[0x7760 + 2 * index:0x7762 + 2 * index], "little")
        if rom[0x415A + ptr:0x415E + ptr] != bytes((8, 8, 0, 8)):
            raise RuntimeError(f"CPC sprite {index} is not a whole 8x8 record")
    tail = bytes.fromhex("e1220033ed5302332108002208332e01220a333ea1322434c3ba34")
    if rom[0x8AC2:0x8AC2 + len(tail)] != tail:
        raise RuntimeError(f"8AC2 tail {rom[0x8AC2:0x8AC2 + len(tail)].hex()}")
    rom[0x8AC2:0x8AC2 + len(tail)] = bytes.fromhex("e1c355b4") + bytes(len(tail) - 4)


def install_cpc_stamp(rom: bytearray, p) -> None:
    """CPC standing-fans stamp: data 77F6.., code B338.. (former MSX stamp)."""
    data = CPC_STAMP_ASSET.read_bytes()
    if hashlib.sha256(data).hexdigest() != CPC_STAMP_SHA256:
        raise RuntimeError("cpc_stand_stamp_mode1.bin SHA-256 mismatch")
    if CPC_STAMP_DATA + len(data) > 0x7AE8:
        raise RuntimeError("CPC stamp data overlaps court helpers at 7AE8")
    rom[CPC_STAMP_DATA:0x7AE8] = data + bytes(0x7AE8 - CPC_STAMP_DATA - len(data))
    src = ROOT / "src/v06/cpc_stamp.asm"
    out = OUTDIR / "cpc_stamp.bin"
    lst = OUTDIR / "cpc_stamp.lst"
    out.unlink(missing_ok=True)
    result = subprocess.run(
        [str(SJASM), "--8080", "-b", "-w", str(src), str(lst), str(out)],
        capture_output=True, text=True, cwd=ROOT / "src/v06",
    )
    output = result.stdout + result.stderr
    if not out.exists() or ("error" in output.lower() and "no errors" not in output.lower()):
        raise RuntimeError(f"cpc_stamp assembly failed:\n{output}")
    code = out.read_bytes()
    syms = load_syms(lst)
    if syms.get("BG_FETCH") != pin("BG_FETCH", 0xB338):  # entries after it are linked labels
        raise RuntimeError("BG_FETCH moved from B338")
    if syms["CPC_STAMP_END"] > LABELS["HUD_ICON"]:
        raise RuntimeError(f"CPC stamp code ends at {syms['CPC_STAMP_END']:04X}, past HUD_ICON")
    if syms["STAMP_PAIR"] & 0xFF == 0x00:
        raise RuntimeError("STAMP_PAIR low byte must differ from 1800's")
    if 0xB338 + len(code) > 0xB498:
        raise RuntimeError("CPC stamp code overlaps the staged sprite stream")
    rom[0xB338:0xB498] = code + bytes(0xB498 - 0xB338 - len(code))
    # MSX scoreboard art: AFC8 blits it through D252 over the menu, then
    # HUD_DECOR paints the CPC scoreboard. Drop the MSX pass.
    p.put(0x92B5, bytes.fromhex("cdc8af"), bytes(3), "92AA: no MSX scoreboard blit (AFC8)")
    install_joy_p(rom)
    print(f"[4a+] CPC stamp data {CPC_STAMP_DATA:04X}..{CPC_STAMP_DATA + len(data) - 1:04X}, "
          f"code B338..{0xB338 + len(code) - 1:04X}")


def assemble_court_helpers() -> bytes:
    """CPC-style high-plane court generator for the former AY slot."""
    src = ROOT / "src/v06/win_7ae8.asm"
    out = OUTDIR / "win_7ae8.bin"
    lst = OUTDIR / "win_7ae8.lst"
    if out.exists():
        out.unlink()
    result = subprocess.run(
        [str(SJASM), "--8080", "-b", "-w", str(src), str(lst), str(out)],
        capture_output=True, text=True, cwd=ROOT / "src/v06",
    )
    output = result.stdout + result.stderr
    if not out.exists() or ("error" in output.lower() and "no errors" not in output.lower()):
        raise RuntimeError(f"win_7ae8 assembly failed:\n{output}")
    raw = out.read_bytes()
    syms = load_syms(lst)
    if syms.get("COURT_COLORIZE") != COURT_HELPERS_ADDR:
        raise RuntimeError("COURT_COLORIZE moved")
    if syms.get("DIRTY_COURT_HIGH_BYTE") != pin("DIRTY_COURT_HIGH_BYTE", 0x7B87):
        raise RuntimeError("dirty court classifier entry moved")
    if syms.get("COURT_HIGH_BYTE") != pin("COURT_HIGH_BYTE", 0x7B1F):
        raise RuntimeError(f"COURT_HIGH_BYTE moved to {syms.get('COURT_HIGH_BYTE', 0):04X}")
    if COURT_HELPERS_ADDR + len(raw) > 0x7B9D:
        raise RuntimeError("court helpers overlap music")
    return raw


def install_background_assets(rom: bytearray) -> None:
    from pack_cpc_court import expected_court_pairs, expected_stamped_court_pairs, pack_court
    from gen_text_screens import font_from_overlay, pack_menu_planes, render_screen

    font = font_from_overlay()
    menu_raw_lo, menu_raw_hi = render_screen(font, splash=False)
    menu_lo, menu_hi = pack_menu_planes(font)
    tiles = pack_court()
    tail = tiles[COURT_SIZE:]
    hud_low = HUD_DECOR_RLE.read_bytes()
    hud_high = HUD_COLOR_HI_RLE.read_bytes()
    helpers = assemble_background_helpers()
    # dw hi_addr, low LZ, high LZ — must stay below the court tile tail.
    menu_blob = bytearray(2)
    menu_blob.extend(menu_lo)
    hi_addr = TITLE_V06 + len(menu_blob)
    menu_blob.extend(menu_hi)
    menu_blob[0:2] = hi_addr.to_bytes(2, "little")
    if TITLE_V06 + len(menu_blob) > 0x1320 or 0x1600 + len(tail) > 0x1710:
        raise RuntimeError(
            f"packed text menu {len(menu_blob)} overlaps LZ body at 1320, "
            f"or court tail {len(tail)} exceeds slot before 1710"
        )
    OUTDIR.mkdir(parents=True, exist_ok=True)
    (OUTDIR / "expected_court_pairs.bin").write_bytes(expected_court_pairs())
    (OUTDIR / "expected_stamped_court_pairs.bin").write_bytes(expected_stamped_court_pairs())
    (OUTDIR / "menu_text_lo.bin").write_bytes(menu_raw_lo)
    (OUTDIR / "menu_text_hi.bin").write_bytes(menu_raw_hi)
    print(
        f"[3a+] court tiles {len(tiles)} bytes "
        f"({(len(tiles) - 448) // 16} unique) with VECTOR boards"
    )
    if HUD_PACKED_ADDR + len(hud_low) != HUD_HIGH_PACKED_ADDR:
        raise RuntimeError(
            f"HUD low asset ends at {HUD_PACKED_ADDR + len(hud_low):04X}, "
            f"want {HUD_HIGH_PACKED_ADDR:04X}"
        )
    if HUD_HIGH_PACKED_ADDR + len(hud_high) != BG_HELPERS_ADDR:
        raise RuntimeError(
            f"HUD high asset ends at {HUD_HIGH_PACKED_ADDR + len(hud_high):04X}, "
            f"want {BG_HELPERS_ADDR:04X}"
        )
    rom[TITLE_V06:TITLE_V06 + TITLE_LEN] = bytes(TITLE_LEN)
    rom[TITLE_V06:TITLE_V06 + len(menu_blob)] = menu_blob
    rom[0x1600:0x1600 + len(tail)] = tail
    lz_out = OUTDIR / "menu_lz.bin"
    lz_lst = OUTDIR / "menu_lz.lst"
    lz_out.unlink(missing_ok=True)
    lz_result = subprocess.run(
        [str(SJASM), "--8080", "-b", "-w", str(ROOT / "src/v06/menu_lz.asm"),
         str(lz_lst), str(lz_out)],
        capture_output=True, text=True, cwd=ROOT / "src/v06",
    )
    if lz_result.returncode or not lz_out.exists() or (
        "error" in (lz_result.stdout + lz_result.stderr).lower()
        and "no errors" not in (lz_result.stdout + lz_result.stderr).lower()
    ):
        raise RuntimeError(lz_result.stdout + lz_result.stderr)
    lz_body = lz_out.read_bytes()
    if 0x1320 + len(lz_body) > 0x137B:
        raise RuntimeError("menu LZ body overlaps colour menu restore at 137B")
    rom[0x1320:0x1320 + len(lz_body)] = lz_body
    color_bg_out = OUTDIR / "menu_color_bg.bin"
    color_bg_lst = OUTDIR / "menu_color_bg.lst"
    color_bg_out.unlink(missing_ok=True)
    color_bg_result = subprocess.run(
        [str(SJASM), "--8080", "-b", "-w", str(ROOT / "src/v06/menu_color_bg.asm"),
         str(color_bg_lst), str(color_bg_out)],
        capture_output=True, text=True, cwd=ROOT / "src/v06",
    )
    if color_bg_result.returncode or not color_bg_out.exists() or (
        "error" in (color_bg_result.stdout + color_bg_result.stderr).lower()
        and "no errors" not in (color_bg_result.stdout + color_bg_result.stderr).lower()
    ):
        raise RuntimeError(color_bg_result.stdout + color_bg_result.stderr)
    color_bg = color_bg_out.read_bytes()
    color_syms = load_syms(color_bg_lst)
    # Entries float inside 137B..15FF (tools/link_labels.py); REPLAY_X2 is
    # 16-aligned by a ds in the source.
    if color_syms["REPLAY_X2_TABLE"] & 0x0F:
        raise RuntimeError(f"REPLAY_X2_TABLE at {color_syms['REPLAY_X2_TABLE']:04X}, want 16-aligned")
    if 0x137B + len(color_bg) > 0x1600:
        raise RuntimeError("menu colour restore overlaps court tile tail")
    rom[0x137B:0x137B + len(color_bg)] = color_bg
    extra_out = OUTDIR / "court_tiles.bin"
    extra_lst = OUTDIR / "court_tiles.lst"
    extra_out.unlink(missing_ok=True)
    result = subprocess.run(
        [str(SJASM), "--8080", "-b", "-w", str(ROOT / "src/v06/court_tiles.asm"),
         str(extra_lst), str(extra_out)],
        capture_output=True, text=True, cwd=ROOT / "src/v06",
    )
    if result.returncode or not extra_out.exists() or (
        "error" in (result.stdout + result.stderr).lower()
        and "no errors" not in (result.stdout + result.stderr).lower()
    ):
        raise RuntimeError(result.stdout + result.stderr)
    extra = extra_out.read_bytes()
    if 0x1710 + len(extra) > 0x18CA:
        raise RuntimeError("court/menu codecs overlap player helpers")
    rom[0x1710:0x1710 + len(extra)] = extra
    tile_early = load_syms(extra_lst)
    if tile_early.get("RESTORE_OLD_PROPS_END", 0x1774) > 0x1774:
        raise RuntimeError("RESTORE_OLD_PROPS overlaps COURT_TILE_CACHE table")
    rom[HUD_PACKED_ADDR:HUD_PACKED_ADDR + len(hud_low)] = hud_low
    rom[HUD_HIGH_PACKED_ADDR:HUD_HIGH_PACKED_ADDR + len(hud_high)] = hud_high
    rom[BG_HELPERS_ADDR:BG_HELPERS_ADDR + len(helpers)] = helpers
    print(
        f"[3a] text menu LZ {TITLE_V06:04X}..{TITLE_V06 + len(menu_blob) - 1:04X} "
        f"({len(menu_lo)}+{len(menu_hi)} payload), decoder "
        f"1320..{0x1320 + len(lz_body) - 1:04X}; "
        f"HUD low/high RLE {HUD_PACKED_ADDR:04X}..{BG_HELPERS_ADDR - 1:04X}; "
        f"helpers {BG_HELPERS_ADDR:04X}..{BG_HELPERS_ADDR + len(helpers) - 1:04X}"
    )


def install_splash_planes(rom: bytearray) -> None:
    low, high = splash_plane_pair()
    rom[0xE000:0x10000] = low
    rom[0xC000:0xE000] = high


SPLASH_ANIM_ADDR, SPLASH_ANIM_END = 0x1B40, 0x2500   # replay ring + DP_BUF, idle before the game


def install_splash_anim(rom: bytearray) -> None:
    """CPC title animation in the (zero, idle) replay ring and DP_BUF; cleared on Space."""
    src, lst, out = ROOT / "src/v06/splash_anim.asm", OUTDIR / "splash_anim.lst", OUTDIR / "splash_anim.bin"
    out.unlink(missing_ok=True)
    r = subprocess.run([str(SJASM), "--8080", "-b", "-w", str(src), str(lst), str(out)],
                       capture_output=True, text=True, cwd=ROOT / "src/v06")
    text = r.stdout + r.stderr
    if r.returncode or not out.exists() or ("error" in text.lower() and "no errors" not in text.lower()):
        raise RuntimeError(f"splash_anim assembly failed:\n{text}")
    raw = out.read_bytes()
    blob = raw[SPLASH_ANIM_ADDR:] if len(raw) > SPLASH_ANIM_END - SPLASH_ANIM_ADDR else raw
    if SPLASH_ANIM_ADDR + len(blob) > SPLASH_ANIM_END:
        raise RuntimeError(f"splash animation {len(blob)} B does not fit 1B40..24FF")
    if any(rom[SPLASH_ANIM_ADDR:SPLASH_ANIM_END]):
        raise RuntimeError("1B40..24FF is not zero before the splash animation goes in")
    rom[SPLASH_ANIM_ADDR:SPLASH_ANIM_ADDR + len(blob)] = blob
    print(f"[4d] splash animation 1B40..{SPLASH_ANIM_ADDR + len(blob) - 1:04X} ({len(blob)} B)")


def install_window_slots(rom: bytearray) -> None:
    """Place verified procedures in the A521 tail. Does not widen 84D0..B257."""
    sys.path.insert(0, str(ROOT / "tools"))
    from verify_a521_tail import assert_tail_free
    assert_tail_free(rom)
    blob = assemble_window_slot()
    if 0xA524 + len(blob) > 0xA53A:
        raise RuntimeError("window slot exceeds verified tail A524..A539")
    rom[0xA524:0xA524 + len(blob)] = blob
    print(f"[4a] window slot A524..{0xA524 + len(blob) - 1:04X} ({len(blob)}B) "
          f"SET_VBLANK+BIOS_CLICK; tail through A539")


# Game code replaced by adapter routines before the relocation: its CALL
# D5DE operands are gone (the range must be zero there).
RELOC_REPLACED = (
    (0xAF0E, 0xAF9A, "control reader key tests → NATIVE_PADS"),
)


def relocate_high_memory(rom: bytearray) -> None:
    """Move every ordinary C000..DFFF object below 4000 and clear the colour plane."""
    manifest = json.loads((ROOT / "cfg/high_memory_relocation.json").read_text())
    entries = manifest["operands"]
    if len(entries) != manifest["operand_count"]:
        raise RuntimeError("high-memory relocation operand count mismatch")

    for entry in entries:
        pc = int(entry["pc"], 16)
        if any(lo <= pc < hi for lo, hi, _ in RELOC_REPLACED):
            if any(rom[pc:pc + 3]):
                raise RuntimeError(f"high-memory relocation @{pc:04X}: replaced range not cleared")
            continue
        opcode = bytes.fromhex(entry["opcode"])
        operand_offset = entry.get("operand_offset", 1)
        old = int(entry["old_target"], 16)
        new = int(entry["new_target"], 16)
        if bytes(rom[pc:pc + len(opcode)]) != opcode:
            raise RuntimeError(
                f"high-memory relocation @{pc:04X}: opcode "
                f"{bytes(rom[pc:pc + len(opcode)]).hex()}, want {opcode.hex()}"
            )
        at = pc + operand_offset
        current = int.from_bytes(rom[at:at + 2], "little")
        if current != old:
            raise RuntimeError(
                f"high-memory relocation @{pc:04X}: target {current:04X}, want {old:04X}"
            )
        rom[at:at + 2] = new.to_bytes(2, "little")

    for entry in manifest.get("data_words", []):
        at = int(entry["address"], 16)
        old = int(entry["old_target"], 16)
        new = int(entry["new_target"], 16)
        current = int.from_bytes(rom[at:at + 2], "little")
        if current != old:
            raise RuntimeError(
                f"high-memory pointer @{at:04X}: target {current:04X}, want {old:04X}"
            )
        rom[at:at + 2] = new.to_bytes(2, "little")

    from pack_cpc_court import pack_court
    court = pack_court()[:COURT_SIZE]
    if len(court) != COURT_SIZE:
        raise RuntimeError(f"court background is {len(court)} bytes, want {COURT_SIZE}")
    pointers = bytes(rom[D_PTR_OLD:D_PTR_OLD + D_PTR_SIZE])
    system_hud = bytes(rom[D_CODE_OLD:D_CODE_END])
    sentinel = rom[LEGACY_SENTINEL_OLD]

    rom[COURT_NEW:COURT_NEW + COURT_SIZE] = court
    rom[D_PTR_NEW:D_PTR_NEW + D_PTR_SIZE] = pointers
    rom[D_CODE_NEW:D_CODE_NEW + len(system_hud)] = system_hud
    rom[LEGACY_SENTINEL_NEW] = sentinel

    # Old court storage now backs replay staging and the stack below C000.
    # The physical colour plane starts zero in the image and is runtime data.
    rom[COURT_OLD:0xE000] = bytes(0xE000 - COURT_OLD)
    print(
        f"[4b] high memory relocated: court {COURT_NEW:04X}..{COURT_NEW + COURT_SIZE - 1:04X}, "
        f"pointers {D_PTR_NEW:04X}..{D_PTR_NEW + 3:04X}, "
        f"system/HUD {D_CODE_NEW:04X}..{D_CODE_NEW + len(system_hud) - 1:04X}; "
        "C000..DFFF cleared"
    )


class Patcher:
    def __init__(self, rom: bytearray):
        self.rom = rom
        self.count = 0

    def put(self, addr: int, old: bytes, new: bytes, label: str) -> None:
        cur = bytes(self.rom[addr:addr + len(old)])
        if cur != old:
            raise RuntimeError(f"patch {label}@{addr:04X}: expected {old.hex()} got {cur.hex()}")
        self.rom[addr:addr + len(new)] = new
        self.count += 1
        print(f"    {addr:04X} {label}")

    def word(self, addr: int, old: int, new: int, label: str) -> None:
        """Remap the 16-bit operand of the instruction at addr."""
        op_len = 2 if self.rom[addr] in (0xED, 0xDD, 0xFD) else 1
        at = addr + op_len
        self.put(at, old.to_bytes(2, "little"), new.to_bytes(2, "little"),
                 f"{old:04X}→{new:04X} {label}")


def build_rom() -> None:
    OUTDIR.mkdir(parents=True, exist_ok=True)
    rom = bytearray(0x10000)

    adapter = assemble_glue()
    syms = load_syms(OUTDIR / "glue.lst")
    if len(adapter) > ADAPTER_END:
        raise RuntimeError(f"adapter {len(adapter):#x} bytes overlaps work RAM at {ADAPTER_END:04X}")
    rom[:len(adapter)] = adapter
    print(f"[1] adapter: {len(adapter)} bytes")

    overlay = bytearray((MSX / "executive.overlay.bin").read_bytes())
    stats = patch_ports(overlay)
    rom[GAME_BASE:GAME_BASE + len(overlay)] = overlay
    print(f"[2] game: {GAME_BASE:04X}..{GAME_BASE + len(overlay) - 1:04X}  ports {stats}")

    block1 = (MSX / "executive.block1.bin").read_bytes()
    # 2000..24FF is shared menu/replay work RAM; the image stays zero.
    # Stage 1 support data at native addresses; replace the mono sprite bank
    # with the directly extracted CPC two-plane resource.
    rom[0x415A:0x415A + 0x3E60] = block1[:0x3E60]
    cpc_sprites = CPC_SPRITES.read_bytes()
    actual_sprite_sha = hashlib.sha256(cpc_sprites).hexdigest()
    if actual_sprite_sha != CPC_SPRITE_SHA256:
        raise RuntimeError(
            f"CPC sprite SHA-256 {actual_sprite_sha}, want {CPC_SPRITE_SHA256}"
        )
    sys.path.insert(0, str(ROOT / "tools"))
    from prepare_cpc_sprite_bank import prepare_bank
    cpc_sprites = prepare_bank(cpc_sprites)
    (OUTDIR / "cpc_sprites_msx_layout.bin").write_bytes(cpc_sprites)
    # Mirrored frames become references (tools/pack_sprite_mirrors.py).
    # Records from 415A, the bit-reverse table MIR_REV, zero gaps, the
    # 75-word pointer table at 7760.
    from pack_sprite_mirrors import pack_mirrors, REV
    from prepare_cpc_sprite_bank import UNTRIMMED
    runtime_sprites, mirrors = pack_mirrors(cpc_sprites, CPC_SPRITE_COUNT, frozenset(UNTRIMMED))
    (OUTDIR / "cpc_sprites_runtime.bin").write_bytes(runtime_sprites)
    cpc_pointer = 0x7760
    mir_rev = LABELS["MIR_REV"]
    records = runtime_sprites[:-CPC_SPRITE_POINTER_BYTES]
    if CPC_SPRITE_BASE + len(records) > mir_rev or mir_rev & 0xFF:
        raise RuntimeError(f"CPC sprite records overlap MIR_REV {mir_rev:04X}")
    rom[CPC_SPRITE_BASE:0x77F6] = bytes(0x77F6 - CPC_SPRITE_BASE)
    rom[CPC_SPRITE_BASE:CPC_SPRITE_BASE + len(records)] = records
    rom[mir_rev:mir_rev + 256] = REV
    rom[cpc_pointer:cpc_pointer + CPC_SPRITE_POINTER_BYTES] = runtime_sprites[-CPC_SPRITE_POINTER_BYTES:]
    print(f"[3] CPC sprite records 415A..{CPC_SPRITE_BASE + len(records) - 1:04X} "
          f"({len(mirrors)} mirror references), MIR_REV {mir_rev:04X}, "
          f"free {CPC_SPRITE_BASE + len(records):04X}..{mir_rev - 1:04X} and "
          f"{mir_rev + 256:04X}..775F ({cpc_pointer - CPC_SPRITE_BASE - len(records) - 256} bytes)")
    install_adapter_hi(rom)
    install_background_assets(rom)
    cpc_snd = CPC_SND.read_bytes()
    actual_snd_sha = hashlib.sha256(cpc_snd).hexdigest()
    if actual_snd_sha != CPC_SND_SHA256:
        raise RuntimeError(
            f"CPC sound SHA-256 {actual_snd_sha}, want {CPC_SND_SHA256}"
        )
    if CPC_SND_ADDR + len(cpc_snd) != 0x7FBA:
        raise RuntimeError(
            f"CPC sound covers {CPC_SND_ADDR:04X}..{CPC_SND_ADDR + len(cpc_snd):04X}, "
            "want 7AE8..7FBA"
        )
    rom[CPC_SND_ADDR:CPC_SND_ADDR + len(cpc_snd)] = cpc_snd
    sys.path.insert(0, str(ROOT / "tools"))
    from pack_v06_snd import pack_v06_snd, SFX_SITES
    snd_notes, sfx_map = pack_v06_snd(rom)
    court_helpers = assemble_court_helpers()
    rom[COURT_HELPERS_ADDR:0x7B9C] = court_helpers + bytes(0x7B9C - COURT_HELPERS_ADDR - len(court_helpers))
    print("[3] shared gfx work 2000..24FF (blank in image), 415A ← CPC sprites, "
          f"{TITLE_V06:04X} ← packed text menu, C000/E000 ← CPC splash, "
          f"7AE8 ← CPC AY snd, {snd_notes} notes + {len(sfx_map)} SFX → VI53")

    print("[4] patches:")
    p = Patcher(rom)
    p.word(0x9E73, 0x7760, cpc_pointer, "CPC sprite pointer table")
    # Interrupts: Vector only delivers RST 38 (IM 1); IRQ_HANDLER chains to
    # the game's IM2 entry at 4141.
    p.put(0xD3AD, b"\xED\x5E", b"\xED\x56", "IM 2 → IM 1")
    # Game stack
    p.word(0xD360, 0xF55C, GAME_STACK, "LD SP")
    # MSX hook FEE4 (JP D8DF / RET) → scratch
    p.word(0xD38A, 0xFEE4, HOOK_SCRATCH, "hook")
    p.word(0xD390, 0xFEE5, HOOK_SCRATCH + 1, "hook")
    p.word(0xD472, 0xFEE4, HOOK_SCRATCH, "hook")
    # Slot handling: no slots on Vector, page 1 is always RAM
    p.put(0xD3CC, b"\xCD\x38\x01", b"\xAF\xC9\x00", "slot read → XOR A; RET")
    p.put(0xD3FA, b"\xAF\x32\x23\xD2", b"\xAF\xC9\x00\x00", "RAM search → found")
    p.put(0xCF80, b"\xDB\xA8", b"\xC9\x00", "slot switch → RET")
    # A4A8 VRAM→bitmap copy: inner 32×8 IN 98 loop → native VDP_ROWREAD
    p.put(0xA4CC, bytes.fromhex("0620c5e50608ef007719"),
          bytes([0xCD, NATIVE_ROWREAD & 0xFF, NATIVE_ROWREAD >> 8]) + bytes(7),
          "VRAM row read → CALL NATIVE_ROWREAD")
    p.put(0xA4D6, bytes.fromhex("10fae1c12310f1"), bytes(7), "  (rest of loop → NOP)")
    # Menu A77F: ld hl,(B205); INC L started the capture at VRAM 0101, so each
    # round-trip shifted the menu 1px. Read from 0100.
    p.put(0xA4AB, b"\x2c", b"\x00", "A4A8 INC L → NOP")
    p.put(0xA4E2, bytes.fromhex("af3298c2"), bytes(4), "A4A8 xor C298 → NOP")
    p.put(0xA4A8, b"\x2a\x05\xb2",
          bytes([0xC3, NATIVE_BOXES & 0xFF, NATIVE_BOXES >> 8]),
          "A4A8 capture → MENU_FRAME_BEGIN")
    a493 = bytes.fromhex("2198c219111b0006280e0536ff230d20fa1910f5c9")
    p.put(0xA493, a493, b"\xc9" + bytes(len(a493) - 1),
          "A493 FF boxes → RET")
    p.put(0xA605, bytes.fromhex("cd4aa5"),
          bytes([0xCD, NATIVE_TITLE & 0xFF, NATIVE_TITLE >> 8]),
          "A5FD A54A → TITLE_RELOAD")
    # Menu item rows 13/15/17/19/21 → 8/10/12/14/16 so the five options sit
    # inside the CPC well (y56..136), vertically centred with the players.
    p.put(0xA65E, bytes.fromhex("210d08"), bytes.fromhex("210808"),
          "menu row 13 → 8 (y64)")
    p.put(0xA664, bytes.fromhex("2e0f"), bytes.fromhex("2e0a"),
          "menu row 15 → 10 (y80)")
    p.put(0xA669, bytes.fromhex("211108"), bytes.fromhex("210c08"),
          "menu row 17 → 12 (y96)")
    p.put(0xA68A, bytes.fromhex("2e13"), bytes.fromhex("2e0e"),
          "menu row 19 → 14 (y112)")
    p.put(0xA68F, bytes.fromhex("2e15"), bytes.fromhex("2e10"),
          "menu row 21 → 16 (y128)")
    p.put(0xB1FE, bytes.fromhex("2198c2"),
          bytes([0xC3, NATIVE_FRAME & 0xFF, NATIVE_FRAME >> 8]),
          "B1FE present → FRAME_END")
    # The mono direct renderer intentionally drops TMS9918 colour-table writes
    # (VRAM >= 1800). Remove three live loops whose only effect was therefore
    # RST/SoftVDP overhead. Keep register/status traffic for game timing.
    color_init = bytes.fromhex("0620f33e2090070707d7003e4fd700fb3effcf0010ec")
    p.put(0x92E8, color_init, bytes(len(color_init)),
          "dead TMS colour-table fill → NOP")
    # Four legacy pattern fills ran after the first native FRAME_END. Their
    # MSX addresses map onto the already-published stands on Vector and replace
    # spectators with horizontal bars. The court resource already has the art.
    p.put(0x92FE, bytes.fromhex("210800"), bytes.fromhex("c90000"),
          "obsolete post-publish pattern fills → RET")
    color_rows = bytes.fromhex("060bf33e0b9085070707f605d7003e70d700fb3e71cf00f5f1cf0010e5c9")
    p.put(0x932A, color_rows, bytes.fromhex("c9") + bytes(len(color_rows) - 1),
          "dead TMS colour-row writer → RET")
    color_glyph = bytes.fromhex("7df3d7007cc620d700fb11bcd106081acf000010fac9")
    p.put(0xD8C1, color_glyph, bytes.fromhex("c9") + bytes(len(color_glyph) - 1),
          "dead TMS glyph-colour writer → RET")
    # Two remaining hot pattern writers have stable native semantics.
    pair_writer = bytes.fromhex("e5f37d070707f605d7007cf640d700fb79cf0029cf00e1c9")
    p.put(0x9F48, pair_writer,
          bytes([0xC3, syms["NATIVE_PAIR_DIRECT"] & 0xFF,
                 syms["NATIVE_PAIR_DIRECT"] >> 8]) + bytes(len(pair_writer) - 3),
          "two-byte pattern writer → native plane")
    # Game ISR key snapshot (port 37D2): 9 SNSMAT rows + 2 stick/trigger
    # reads → one native copy of the shadow rows (kbd.asm NATIVE_KEYSNAP).
    p.put(0xD56A, bytes.fromhex("210441"),
          bytes([0xC3, syms["NATIVE_KEYSNAP"] & 0xFF, syms["NATIVE_KEYSNAP"] >> 8]),
          "ISR key snapshot → JP NATIVE_KEYSNAP")
    # Jumping fans after a basket: A502 calls CROWD_TICK instead of
    # LD A,(9400); it returns that value, so the MSX test that follows still
    # runs (and still draws its random number) but A521 is a RET now.
    crowd = LABELS["CROWD_TICK"]
    p.put(0xA502, bytes.fromhex("3a0094"), bytes([0xCD, crowd & 0xFF, crowd >> 8]),
          "score fans → CALL CROWD_TICK")
    # Fixed controls: the ten D5DE key tests of the control reader (AF0B..
    # AF99) → joy_p.asm NATIVE_PADS (joystick «П» / cursor keys), and menu
    # item 5 (SELECT CONTROL, redefinable keys) is gone.
    pads_old = bytes.fromhex(  # CALL D5DE: the MSX key test, before relocation
        "1e003e01cdded52002cbc33e26cdded5200ccbcbcb43cbc32804cb83cb8b3e19cdded5"
        "2002cbd33e1bcdded5200ccbdbcb53cbd32804cb93cb9b3e2fcdded52002cbe37b324d"
        "ac1e003e45cdded52002cbc33e46cdded5200ccbcbcb43cbc32804cb83cb8b3e44cdde"
        "d52002cbd33e47cdded5200ccbdbcb53cbd32804cb93cb9b3e3fcdded52002cbe37b32"
        "4eacc9")
    pads = LABELS["NATIVE_PADS"]
    p.put(0xAF0B, pads_old, bytes([0xC3, pads & 0xFF, pads >> 8]) + bytes(len(pads_old) - 3),
          "control reader key tests → JP NATIVE_PADS")
    p.put(0xA69A, bytes.fromhex("fe35ca59a7"), bytes(5),
          "menu key 5 (SELECT CONTROL) → ignored")
    p.put(0xA7C8, b"5 SELECT CONTROL ", b" " * 17, "menu line 5 → blank")
    # Music channel step (IRQ hook AB28): the IY loop AB28..AB82 and its
    # ABDB/ABE7 helpers → snd.asm MUSIC_TICK. The stub keeps the game's own
    # pattern change (AA8F with the ei at AB21 patched out) and the AB83 tail.
    music_loop = bytes.fromhex(
        "fd2109ac0603c5fd6e02fd66037cb52842fd7e01b72805fd3501182a7e3dfd7701"
        "fd3600ff23fd5606cddbab7efeff200faf3221abcd8faa3efb3221abc1181bfd75"
        "02fd7403fd7e00fe092803fd3400cde7ab110800fd19c110ab")
    tick = syms["MUSIC_TICK"]
    stub = bytes([0xCD, tick & 0xFF, tick >> 8,   # call MUSIC_TICK
                  0x20, 0x56,                     # jr nz,AB83
                  0xAF,                           # xor a
                  0x32, 0x21, 0xAB,               # ld (AB21),a  (ei → nop)
                  0xCD, 0x8F, 0xAA,               # call AA8F
                  0x3E, 0xFB,                     # ld a,0xFB
                  0x32, 0x21, 0xAB,               # ld (AB21),a
                  0x18, 0x48])                    # jr AB83
    p.put(0xAB28, music_loop, stub + bytes(len(music_loop) - len(stub)),
          "music channel loop → CALL MUSIC_TICK")
    music_helpers = bytes.fromhex("7a4e23cdffab7a3c4e2318180e002b7e2bb6280d"
                                  "fd5e001600fd6e04fd6605194efd7e07")
    p.put(0xABDB, music_helpers, bytes(len(music_helpers)),
          "music tone/volume helpers (ABDB, ABE7) → MUSIC_TICK")
    text_writer = bytes.fromhex("eb3a03410707076ff3d7003a0241f64067d700fb06081acf001310facdc1d81825")
    p.put(0xD914, text_writer,
          bytes([0xCD, syms["NATIVE_TEXT_GLYPH"] & 0xFF,
                 syms["NATIVE_TEXT_GLYPH"] >> 8,
                 0xC3, 0x5A, 0xD9]) + bytes(len(text_writer) - 6),
          "text glyph pattern writer → native plane")
    fill_writer = bytes.fromhex("5f7dd7007cf640d7007bcf000b78b120f8c9")
    # Gate: match + HL=0 is the full pattern-table wipe (relocated twin of
    # the 92FE RET). It maps onto CPC stands; skip it. Other fills proceed.
    fill_lo = syms["NATIVE_FILL_DIRECT"] & 0xFF
    fill_hi = syms["NATIVE_FILL_DIRECT"] >> 8
    fill_gate = bytes([
        0xF5,                   # push af
        0x7C, 0xB5,             # ld a,h / or l
        0x20, 0x08,             # jr nz, do_fill
        0x3A, 0xEE, 0x0F,       # ld a,(COURT_SYNCED)
        0xB7,                   # or a
        0x28, 0x02,             # jr z, do_fill (menu)
        0xF1, 0xC9,             # pop af / ret  — skip stand wipe
        0xF1,                   # do_fill: pop af
        0xC3, fill_lo, fill_hi, # jp NATIVE_FILL_DIRECT
        0x00,                   # pad to original fill_writer length
    ])
    if len(fill_gate) != len(fill_writer):
        raise RuntimeError(f"fill gate length {len(fill_gate)} != {len(fill_writer)}")
    p.put(0xD517, fill_writer, fill_gate,
          "constant VRAM fill → gated native plane")
    fill_inc = bytes.fromhex("5f7dd7007cf640d7007bcf001c0b78b120f7c9")
    p.put(0xD529, fill_inc,
          bytes([0xC3, syms["NATIVE_FILL_INC"] & 0xFF,
                 syms["NATIVE_FILL_INC"] >> 8]) + bytes(len(fill_inc) - 3),
          "incrementing VRAM fill → native plane")
    # B1FE bitmap compose → VRAM rows 1..14 (menu overlays only)
    loop = bytes.fromhex("0620e5") + bytes.fromhex("7ecf0019") * 7 + bytes.fromhex("7ecf00e12310dc")
    p.put(0xB231, loop, bytes([0xCD, NATIVE_ROWWRITE & 0xFF, NATIVE_ROWWRITE >> 8])
          + bytes(len(loop) - 3), "bitmap row blit → CALL NATIVE_ROWWRITE")
    # Match: court once + dirty restore; present is a no-op (sprites already on plane).
    p.put(0x8587, bytes.fromhex("cdfeb1"),
          bytes([0xCD, NATIVE_FRAME & 0xFF, NATIVE_FRAME >> 8]),
          "main B1FE → FRAME_END")
    p.put(0x92E5, bytes.fromhex("cdfeb1"),
          bytes([0xCD, NATIVE_FRAME & 0xFF, NATIVE_FRAME >> 8]),
          "setup B1FE → FRAME_END")
    p.put(0xB1F2, bytes.fromhex("2198b41198c201000eedb0c9"),
          bytes([0xC3, NATIVE_COURT & 0xFF, NATIVE_COURT >> 8]) + bytes(9),
          "B1F2 LDIR → JP FRAME_BEGIN")
    p.put(0x853B, bytes.fromhex("cdf2b1"),
          bytes([0xCD, NATIVE_RESET & 0xFF, NATIVE_RESET >> 8]),
          "match-enter B1F2 → FRAME_RESET")
    p.put(0x92DF, bytes.fromhex("cdf2b1"),
          bytes([0xCD, NATIVE_RESET & 0xFF, NATIVE_RESET >> 8]),
          "setup B1F2 → FRAME_RESET")
    # Dunk replay loop still called B1F2 (= FRAME_BEGIN only). Without
    # FRAME_RESET/HUD_DECOR each state, zoom left menu residue in the HUD.
    # Each replay state: forget sprite metadata, then FRAME_BEGIN. The zoom
    # never reaches the HUD (stops at y=120), so no HUD_DECOR per state.
    # Replay ring in a circle (ring.asm): no 1106-byte shift per iteration.
    p.put(0xA96E, bytes.fromhex("ed5bd49321eb93014f00edb021e5e2ed52300b1193de21e2de015204edb0ed53d493c9"),
          bytes([0xC3]) + LABELS["RING_PUSH"].to_bytes(2, "little") + bytes(32), "replay ring write A96E → RING_PUSH")
    p.put(0xA991, bytes.fromhex("2ad49311eb93014f00edb022d493eb21e5e237ed52d03e0132d393c9"),
          bytes([0xC3]) + LABELS["RING_PULL"].to_bytes(2, "little") + bytes(25), "replay ring read A991 → RING_PULL")
    p.put(0xA962, bytes.fromhex("2193de22d493c9"),
          bytes([0xC3]) + LABELS["RING_RESET"].to_bytes(2, "little") + bytes(4), "replay ring reset A962 → RING_RESET")
    p.put(0xA859, bytes.fromhex("2193de22d493"),
          bytes([0xCD]) + LABELS["RING_REPLAY"].to_bytes(2, "little") + bytes(3), "replay start A859 → RING_REPLAY")
    p.put(0xA887, bytes.fromhex("cdf2b1"), bytes([0xCD]) + LABELS["REPLAY_STATE_BEGIN"].to_bytes(2, "little"),
          "replay B1F2 → REPLAY_STATE_BEGIN")
    p.put(0xA89E, bytes.fromhex("cdf2b1"), bytes([0xCD]) + LABELS["REPLAY_STATE_BEGIN"].to_bytes(2, "little"),
          "replay loop B1F2 → REPLAY_STATE_BEGIN")
    p.put(0xA88A, bytes.fromhex("cd8593"), bytes([0xCD]) + LABELS["REPLAY_SCENE"].to_bytes(2, "little"),
          "replay 9385 → REPLAY_SCENE (stage only; zoom composes off screen)")
    p.put(0xA8A1, bytes.fromhex("cd8593"), bytes([0xCD]) + LABELS["REPLAY_SCENE"].to_bytes(2, "little"),
          "replay loop 9385 → REPLAY_SCENE")
    # MSX B206 sits inside BUFFER_PLAYERS (B01F..). Relocate the match-mode
    # flag so menu/match transitions do not smash staged-sprite code.
    # 0FF0..0FF2 hold a JP hook stub; keep the flag clear of that.
    MATCH_MODE = 0x0FED
    p.put(0xA60A, bytes.fromhex("3206b2"),
          bytes([0x32, MATCH_MODE & 0xFF, MATCH_MODE >> 8]),
          "menu mode flag B206 → 0FED")
    p.put(0xA6C9, bytes.fromhex("3206b2"),
          bytes([0x32, MATCH_MODE & 0xFF, MATCH_MODE >> 8]),
          "match mode flag B206 → 0FED")
    old_spr = bytes.fromhex(
        "3adfb1b7c847c5cdcdb1dd6e00dd23dd6600dd2311000019"
        "fd21e4b106047efda603fdb60077fd232310f3c110d8c9"
    )  # 47 bytes B15F..B18D; B18E is the shifted-sprite path
    new_spr = bytes.fromhex("3adfb1b7c847") + bytes(
        [0xC3, NATIVE_DIRTY & 0xFF, NATIVE_DIRTY >> 8]
    )
    new_spr += bytes(len(old_spr) - len(new_spr))
    p.put(0xB15F, old_spr, new_spr, "B01C AND/OR → DIRTY_ADD+SPRITE_OR")
    tile_syms = load_syms(OUTDIR / "court_tiles.lst")
    # Standing-fans stamp: C298 LDIR → CPC stamp as background state. Dead tail NOP'd.
    a521 = bytes.fromhex("1198c2191138b3eb06003e200e0bedb0eb0e1509eb3d20f4c9")
    p.put(0xA521, a521,
          bytes([0xC3, NATIVE_STAMP & 0xFF, NATIVE_STAMP >> 8]) + bytes(len(a521) - 3),
          "A521 stamp → CPC_STAMP_ON")
    install_window_slots(rom)
    # B113 used to patch call B1CD/B18E at B167. That slot is now the
    # high byte of `jp SPRITE_ROWS` and became `jp CDF5` (hang CE6C).
    p.put(0xB113, bytes.fromhex("2267b1"), bytes.fromhex("225a0f"),
          "B113 loader → V_SPR_LOAD")
    p.put(0xB117, bytes.fromhex("3280b1"), bytes.fromhex("325c0f"),
          "B180 mask → V_SPR_MASK")
    # Splash is baked into E000. Skip CC76 dancers (live inside C298).
    p.put(0x8505, bytes.fromhex("cd76cc"), bytes(3), "call CC76 → NOP")
    p.put(0xA544, bytes.fromhex("cd36cf"), bytes(3),
          "obsolete CF36 copy call → NOP")
    wipe = bytes.fromhex("2198c21199c2360001ff0dedb0")
    snap_clr = bytes.fromhex("af32ef0f") + bytes(len(wipe) - 4)
    p.put(0xA1D1, wipe, snap_clr, "A1C3 wipe C298 → TITLE_SNAPPED=0")
    p.put(0xA4F0, wipe, snap_clr, "A4E7 wipe C298 → TITLE_SNAPPED=0")
    # Replay staging at 2000 stays blank in the image.
    # Title graphics block E740.. (read-only blit source)
    for site in (0xA555, 0xA57F, 0xA5B4, 0xA5E9):
        old = int.from_bytes(rom[site + 1:site + 3], "little")
        p.word(site, old, old - TITLE_MSX + TITLE_V06, "title gfx")
    # Zoomed replay: A8F4 reads the composed column plane, not C398.
    # A8F9 (half select) is the old LD DE immediate and is left in place.
    syms = load_syms(OUTDIR / "glue.lst")
    for name in ("REPLAY_ZOOM", "REPLAY_STAMP", "REPLAY_DONE",
                 "REPLAY_X2", "REPLAY_BLIT", "REPLAY_PACE_N"):
        if name not in syms:
            raise RuntimeError(f"missing symbol {name}")
    # REPLAY_X2 must be 16-aligned so nibble index via add a,l never carries.
    if syms["REPLAY_X2"] & 0x0F:
        raise RuntimeError(f"REPLAY_X2 at {syms['REPLAY_X2']:04X}, want 16-aligned")
    p.put(0xA8F4, bytes.fromhex("fd2198"),
          bytes([0xC3, syms["REPLAY_ZOOM"] & 0xFF, syms["REPLAY_ZOOM"] >> 8]),
          "A8F4 zoom → REPLAY_ZOOM")
    p.put(0xA8C8, bytes.fromhex("3acad0"),
          bytes([0xC3, syms["REPLAY_STAMP"] & 0xFF, syms["REPLAY_STAMP"] >> 8]),
          "A8C8 stamp → REPLAY_STAMP")
    p.put(0xA8C0, bytes.fromhex("cdc4d7"),
          bytes([0xCD, syms["REPLAY_DONE"] & 0xFF, syms["REPLAY_DONE"] >> 8]),
          "replay exit → REPLAY_DONE")
    # A93C is only called from the replaced A8F4 body (A923/A927): dead.
    # Replay buffer DE44..E2E4 (79-byte game-state frames from 93EB)
    # (A859, A962, A97A, A981, A984, A9A0 are replaced by ring.asm calls.)
    for site in (0xA862, 0xA8B5, 0xA9D8, 0xA9DF, 0xA9E2):
        old = int.from_bytes(rom[site + 1:site + 3], "little")
        p.word(site, old, old - RING_MSX + RING_V06, "record buffer")
    for old, new in sfx_map.items():
        for site in SFX_SITES[old]:
            p.word(site, old, new, "SFX → 7FBA VI53")
    sfx_wr = bytes.fromhex("234e232223ac3e02f5cdffab7ae6034ff13ccdffab")
    sfx_new = bytes.fromhex("234e23e53e02cdffabe14e232223ac3e03cdffab")
    p.put(0xABB9, sfx_wr, sfx_new + bytes(len(sfx_wr) - len(sfx_new)),
          "SFX period 10-bit AY → 16-bit VI53")
    # B258..B2C4: DIRTY_OLD; B2C5..B330: runtime sprite metadata. The whole
    # range starts zero in the ROM image; B331..B337 is the remaining tail.
    rom[0xB258:0xB338] = bytes(0xB338 - 0xB258)
    install_cpc_stamp(rom, p)
    rom[0xA4AB:0xA4E6] = bytes(0xA4E6 - 0xA4AB)   # former pair bounds helper (old menu)
    relocate_high_memory(rom)
    # The ISR's `call 37D2` at 372C (then `jp 3811`, the key parse): the
    # relocation manifest owns that operand, so the patch follows it.
    # NATIVE_ISR_KEYS skips both unless an input changed (kbd.asm).
    if rom[0x372C:0x372F] != bytes.fromhex("cdd237"):
        raise RuntimeError(f"372C: {rom[0x372C:0x372F].hex()}, want cdd237")
    rom[0x372C:0x372F] = bytes([0xCD, syms["NATIVE_ISR_KEYS"] & 0xFF, syms["NATIVE_ISR_KEYS"] >> 8])
    print("    372C ISR snapshot+parse → CALL NATIVE_ISR_KEYS")
    def le(a: int) -> str:
        return a.to_bytes(2, "little").hex()
    # Pause on ВК, leave the match with АР2 in the pause (kbd.asm PAUSE_END).
    # AE5C: the pause key of the control table AE57 (AE40 copies it to AC4F,
    # 8521 patches it into `cp n` at 8679 each match): MSX key 6 → code 3Fh
    # (RETURN = ВК). The game's wait 3A2F stays; 8682 (`jp 937C`, resume)
    # → PAUSE_END; 8685: the SHIFT+CTRL+ESC exit test → PAUSE_EXIT_TEST.
    # Relocated operands nearby: after relocate_high_memory.
    for site, old, new, why in (
        (0xAE57, "0126191b2f06", "0126191b2f3f", "pause key 6 → ВК (RETURN), table AE57"),
        (0x8682, "c37c93", "c3" + le(syms['PAUSE_END']),
         "pause resume → PAUSE_END (remember the key, wait for its release)"),
        # Only the call targets change: the instruction boundaries stay for
        # the disassembler seeds, and no zero run joins the zero data cells
        # 8696..869B (recompile_i8080 would lay code over them).
        (0x8685, "3e30cd4638c03e31cd4638c03e3ac34638",
         "3e30cd" + le(syms['PAUSE_EXIT_TEST']) + "c03e31cd" + le(syms['PAUSE_EXIT_Z'])
         + "c03e3ac3" + le(syms['PAUSE_EXIT_Z']),
         "exit chord → PAUSE_EXIT_TEST / PAUSE_EXIT_Z"),
    ):
        o, n = bytes.fromhex(old), bytes.fromhex(new)
        if rom[site:site + len(o)] != o:
            raise RuntimeError(f"{site:04X}: {rom[site:site + len(o)].hex()}, want {old} ({why})")
        rom[site:site + len(n)] = n
        print(f"    {site:04X} {why}")
    # Music: runtime `ld (3703),HL` turns GAME_ISR `call 3714` into `call AB28`
    # (or AB83). Keep that classic hook — a side MUSIC_FN broke Emu80 audio.
    if rom[0xAAE6:0xAAE9] != bytes.fromhex("220337"):
        raise RuntimeError(
            f"music ptr not ISR hook: {rom[0xAAE6:0xAAE9].hex()}"
        )
    if rom[0x3702:0x3705] != bytes.fromhex("cd1437"):
        raise RuntimeError(f"GAME_ISR music slot unexpected: {rom[0x3702:0x3705].hex()}")
    print("    AAE6 music player ptr → 3703 (ISR call patch)")
    fast_clear = assemble_fast_clear()
    rom[0x3F81:0x4000] = fast_clear + bytes(0x4000 - 0x3F81 - len(fast_clear))
    print(f"[4b+] fast dirty clear 3F81..{0x3F81 + len(fast_clear) - 1:04X}")
    scene_helpers = assemble_player_scene_helpers()
    rom[0x18CA:0x18CA + len(scene_helpers)] = scene_helpers
    rom[0xB01F:0xB1DC] = bytes(0xB1DC - 0xB01F)   # former menu pair buffer code
    install_splash_planes(rom)
    install_splash_anim(rom)
    p.put(0x8502, bytes.fromhex("cd7caa"), bytes.fromhex("c31585"),
          "boot: the menu tune plays on from the splash (no restart at 8502/8512)")
    p.put(0xB01C, bytes.fromhex("2a0233"),
          bytes([0xC3, NATIVE_SPRITE & 0xFF, NATIVE_SPRITE >> 8]),
          "B01C → staged CPC two-plane sprite")
    print(f"    {p.count} patches")
    print("[4c] B258..B337 zeroed (DIRTY_OLD + sprite metadata at runtime)")

    sys.path.insert(0, str(ROOT / "tools"))
    from pack_v06_gfx import pack_court_columns
    packed = pack_court_columns(rom, COURT_NEW)
    (OUTDIR / "court_v06.bin").write_bytes(packed)
    print(f"[5] court_v06.bin {len(packed)} bytes (packed, not installed — match uses dirty-rect)")

    rom[PAGE0_BLOB:PAGE0_BLOB + 0x100] = rom[0:0x100]

    install_hud_icon(rom)
    install_native_wipe(rom)
    import rng_patch
    n = rng_patch.apply(rom, **rng_patch.PORT)
    import ease_patch
    ne = ease_patch.apply(rom, **ease_patch.PORT)
    print(f"[4] easier steals on ROOKIE/AMATEUR: stub {ease_patch.PORT['base']:04X}..{ease_patch.PORT['base'] + ne - 1:04X}, "
          f"call at {ease_patch.SITE:04X}")
    print(f"[4] deterministic RNG: stubs {rng_patch.PORT['base']:04X}..{rng_patch.PORT['base'] + n - 1:04X}, "
          f"{len(rng_patch.SITES)} LD A,R sites, IRQ seed bump only outside a match")
    install_native_blit(rom)
    install_no_vdp_status(rom)
    zero_dead_vdp_bodies(rom)
    for name, off in FALSE_REF_SITES:
        FALSE_REFS.add(syms[name] + off)
    zero_dead_code(rom)
    fix_unrelocated(rom)
    # Match background fetchers go through BG_FETCH (B338), the stamp gate.
    fetch_sites = (
        (load_syms(OUTDIR / "adapter_hi.lst")["PBR_BG_SITE"], 0xCA),
        (load_syms(OUTDIR / "win_7ae8.lst")["CHB_BG_SITE"], 0xCD))
    for site, op in fetch_sites:
        if rom[site:site + 3] != bytes([op, 0x38, 0xB3]):
            raise RuntimeError(f"{site:04X} {rom[site:site + 3].hex()}: not via BG_FETCH B338")
    if rom[0xB338:0xB33B] != bytes.fromhex("c30018"):
        raise RuntimeError("BG_FETCH must start as JP 1800")
    OUTROM.write_bytes(bytes(rom[0x100:]))
    (OUTDIR / "basket.full.bin").write_bytes(rom)
    import link_labels
    if link_labels.refresh_sigs(rom):
        print("[5] label signatures refreshed (cfg/labels.json)")
    import sync_memory_map
    for line in sync_memory_map.sync():
        print(f"[5] memory map: {line}")
    replay_rom = OUTDIR / "basket-replay.rom"
    replay_rom.write_bytes(bytes(rom[0x100:]))
    print(f"\nOutput: {OUTROM} ({0x10000 - 0x100} bytes, loads at 0100)")
    print(f"Replay: {replay_rom}")


def main() -> int:
    try:
        sys.path.insert(0, str(ROOT / "tools"))
        import link_labels
        for line in link_labels.link():
            print(f"[0] link: {line}")
        global LABELS
        LABELS = {n: int(e["addr"], 16) for n, e in
                  json.loads((ROOT / "cfg/labels.json").read_text())["labels"].items()}
        build_rom()
        return 0
    except Exception as e:
        print(f"Build failed: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
