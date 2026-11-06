# Vector-06C Memory Map for Basket Master (native Z80)

Updated **2026-09-27** (`refactor/memory-four-color`). The main game window
stays at MSX addresses, while the former `D09C..DD17` system/HUD block and
the court resource are relocated below `4000`. Soft TMS VRAM is gone:
pattern I/O goes to the visible low-bit plane (`E000`).

Visual map: Cursor canvas `basket-memory-map.canvas.tsx`.

## Map

Полная побайтовая классификация и правила доказательства свободных областей:
[`current-memory-classification.md`](current-memory-classification.md).

| Range | Size | Contents |
|-------|------|----------|
| 0000..00FF | 256 | RST + BIOS stubs (copied from 0E00 at boot) |
| 0100..01FF | 256 | Boot + native entry stubs |
| 0200..0DFF | 3072 | Adapter code/tables (staged colour, kbd, VI53, two-plane replay/background) |
| 0E00..0EFF | 256 | Page-0 image (copy of 0000..00FF). Address is fixed |
| 0F00..0FFF | 256 | Adapter work RAM (see below) |
| 1000..131F | 800 | Dual LZ CPC text-menu chrome (font-built) |
| 1320..137A | 91 | Menu LZ expander body |
| 137B..15FF | 645 | Retained zero gap (not claimed free) |
| 1600..16EF | 240 | CPC court tile-bank tail (VECTOR boards) |
| 16F0..170F | 32 | Retained zero after shorter tile tail |
| 1710..18A6 | codecs | restore / LZ trampoline / tile cache / normalize / glyphs |
| 18CA..1B3F | helpers | menu/match player scene helpers (see full map) |
| 1B40..1FFF | 1.2K | Replay state/ring workspace; tail is live in traces |
| **2000..24FF** | **1.25K** | Shared menu band / replay staging / complete two-plane player union |
| 2500..32FF | 3.5K | Relocated court bitmap, 32×112 |
| 3300..3303 | 4 | Relocated D252 runtime pointers |
| 3304..3F7F | 3.1K | Relocated system/HUD code, tables and state |
| 3F80 | 1 | Relocated legacy setup sentinel |
| 3F81..3FFF | 127 | Renderer timing helpers |
| 4000..4159 | 0.3K | Work RAM (keys 4104..4110, ISR hook 4141) |
| 415A..6ED7 | 11.1K | Stage-1 CPC sprite records (h, w, top, keep, kept rows) |
| 6ED8..775F | 2181 | free (trimmed empty sprite rows; 7018/7750/7758 are false refs) |
| 7760..77F5 | 150 | sprite record offsets |
| 77F6..7A56 | 609 | CPC standing-fans stamp (mode 1, rows 2..30); 7A57..7AE7 free |
| 7AE8..7B9B | 180 | CPC-style court high-plane generator |
| 7B9C | 1 | Proven reclaimable zero byte |
| 7B9D..7FB9 | 1.0K | Music pointers and notes |
| 7FBA..8089 | 208 | SFX in VI53 divisors |
| 808A..810A | 129 | Packed white HUD decoration plane |
| 810B..8411 | 775 | Packed blue HUD decoration plane |
| 8412..84C9 | 184 | Streaming menu/HUD renderers and SP copier return |
| 84CA..84CF | 6 | Proven reclaimable zero padding |
| 84D0..B257 | 11.4K | Mixed game code/data/state; exact byte classes in full map |
| **B258..B2C4** | **109** | **DIRTY_OLD** list (permanent work RAM, not a code pocket) |
| **B2C5..B330** | **108** | **Previous-frame sprite metadata (27×4)** |
| B331..B337 | 7 | Proven reclaimable zero tail |
| B338..B454 | 285 | BG_FETCH gate + CPC stamp code (A521 → CPC_STAMP_ON); B455..B497 free |
| **B498..BBFF** | **1896** | **Lifetime-shared staged sprite stream / replay high-plane buffer** |
| BC00..BFFF | 1K | Stack, grows down from `C000` |
| **C000..DFFF** | **8K** | **Active high colour-bit video plane** (splash baked into ROM) |
| **E000..FFFF** | **8K** | **Active low colour-bit video plane** (splash baked into ROM) |

`C000..DFFF` is free of game code and ordinary objects. The ROM image contains
the initial splash high bits there; the colour renderer later writes it as data,
the replay reads it, and matching-ROM traces reject execution from the hardware
plane.

Earlier work called `2000..3FFF` “PAGE1”. That was the software COMPOSE
shadow. Direct rendering released it; this refactor now uses the range for
the compact shared buffer, court and relocated system/HUD block.

## Adapter cells `0F00..0FFF`

| Range | Role |
|-------|------|
| 0F00..0F0C | Soft VDP regs / latch / read-ahead |
| 0F0D..0F17 | Replay stamp scratch |
| 0F20..0F2F | MSX keyboard row mirror |
| 0F30..0F3F | Scroll / PPI C / border / last keyboard inputs 0F33..0F37 / Vector rows |
| 0F40..0F4F | AY register mirror |
| 0F50..0F58 | VI53 channel on + last divisors |
| 0F5A..0F5F | colour sprite source, stride, shift, width and row count |
| 0F60 | IRQ frame counter |
| 0F61..0F68 | saved high-plane bytes under the replay marker |
| 0F1A..0F1F | player union and clipped object row/column |
| 0F0D..0F0E | background-origin pointer during scene composition; replay aliases later |
| 0F6D..0F6E | pair buffer base: 2000 in match, B9F0 in menu |
| 0F6F | clipped-compositor object count |
| 0F70..0F7F | Debug (optional) |
| 0F80..0FEC | `DIRTY_COUNT` + current dirty list (27×4) |
| 0FEE / 0FEF | `COURT_SYNCED` / `TITLE_SNAPPED` |

## Draw path (current)

1. The initial splash is stored directly in both hardware planes; menu reload
   expands the packed full background at `1000` directly into `E000` and clears
   its high plane.
2. **FRAME_BEGIN** — save dirty→`B258`, reset the staged stream, and leave the
   previous complete hardware frame visible during conversion.
3. Court once per possession: `2500` → `E000`; `7AE8` generates its blue and
   salmon high plane. **FRAME_RESET** streams both HUD planes from `808A`,
   while scores and labels remain direct. No temporary unpack crosses `24FF`.
4. **COLOR_SPRITE** — decode the CPC row pair into the shared staged stream at
   `B498..BBFF`. Unchanged menu objects stay resident and are not reconverted.
5. **FRAME_END** — the last four slots in the match list (six or eight objects),
   or all four objects in the menu list are the two player body/head pairs. `B01F..B1DB` replaces the bypassed
   monochrome renderer body, while `B1DC..` keeps its live variables. Menu uses the same compositor,
   with its background retained at `2000` and a pair buffer at `B9F0..BBFF`. For each
   pair, build its old/new union in `2000..24FF`: restore the court, then clip
   and compose every staged object intersecting it. After IRQ, copy only final
   low/high bytes to the hardware planes using a DI-only POP copier; SP is
   saved at `0F16`, and `84C3` restores it before interrupts are enabled. Non-player restore writes preserve
   the already completed player rectangles. Dirty rows are Y-8; the court
   colour classifier receives screen Y, so restore adds eight explicitly.
   This uses the existing shared buffer and adds no video plane.
   `tools/test_player_motion.js` checks the actual raster, every consecutive
   frame in both movement directions, against staged complete body/head poses.
6. Replay captures both selected 16×60 halves into `2000..23BF` and
   `B498..BBFF`, then doubles both colour bits; HUD stays intact.

Native entries: `01E0` ROWREAD, `01E3` ROWWRITE, `01E6` COURT, `01E9`
COLOR_SPRITE, `01EC` STAMP, `01EF` FRAME_END, `01F2` RESET, `01F5` DIRTY,
`01F8` MENU_FRAME_BEGIN, `01FB` TITLE_RELOAD.

## Free pockets (sum)

| Hole | Size | Notes |
|------|------|-------|
| 7B9C | 1 | Byte before music bundle |
| 84CA..84CF | 6 | Remaining zero tail before game entry |
| B331..B337 | 7 | Zero tail after sprite metadata |
| **Total proven reclaimable** | **22 B** | Bound to the current ROM hash |

Not free (often mistaken for holes):

| Range | Size | Why occupied |
|-------|------|--------------|
| 2000..24FF | 1.25K | Shared menu/replay work buffer |
| B258..B2C4 | 109 | DIRTY_OLD |
| B2C5..B330 | 108 | Previous-frame sprite metadata |
| 2500..32FF | 3.5K | Sole court source in image |
| 3304..3F7F | 3.1K | Relocated system/HUD block |

The colour stage now owns `C000..DFFF`. **i8080 recompile** still wants roughly
**+2…4K** net code room (Spirits-style packing; Basket is denser in IX/IY).

## Speed vs MSX (2026-09-25)

| | MSX | Vector |
|---|---|---|
| CPU | 3.58 MHz | 3.00 MHz |
| IRQ / clock 93E7 | 50 Hz | 50 Hz (same match timer) |
| Match tick 8554 | ≈8.5 Hz (est.) | **7.2 Hz** (42 ticks / 293 frames) |
| Dunk replay A93C | ≈9 s | ≈9 s (IRQ-paced) |

Logic is free-running. Full-court blit is once per possession start.
Replay is still byte-wise RST.

### Run speed (2P, hold F + cursor LEFT, frames 680–853)

Coords `940D`/`940E` (P1), `9427`/`9428` (P2). Y = long axis of the court.
Each 8554 tick steps **2** units.

| | Sprint | Step | Cadence | Speed |
|---|---|---|---|---|
| P1 (keys 1 Q D F Z) | 84,16 → 84,56 | +2 Y | 8.65 frames | **11.6 u/s** |
| P2 (cursors) | 84,100 → 84,62 | −2 Y | 8.58 frames | **11.7 u/s** |
| P2 AI (1P) | 84,96 → 87,47 | 1–2 | same tick | ~9.5 u/s |
| MSX (same step × 8.5 Hz) | — | 2 | ~5.9 frames | **~17 u/s** |

## VDP port patches

| Original | Patched | Handler |
|----------|---------|---------|
| OUT (98h),A | RST 08 | plane write |
| OUT (99h),A | RST 10 | address / register |
| IN A,(99h) | RST 20 | status |
| IN A,(98h) | RST 28 | plane read (read-ahead) |


Residual compatibility calls and their observed coverage are tracked in [softvdp-inventory.md](softvdp-inventory.md).
