# Baseline: text menu + VECTOR banner

Control ROM before this work: `build/v06/basket-control-pre-menu-vector-54f34fc.rom`  
SHA-256 `1245bdac7e1c57df06d2d203c99d23ab82fd152aceb8d1b410eee05765794499`  
Branch tip at measurement: `54f34fc`. Working tree was clean.

## Resource inventory (before)

| Object | Source | ROM / size | Consumers |
|---|---|---:|---|
| Splash planes | `src/assets/splash_planes_v06.z` (1261 → 16384) | baked `C000`/`E000` | boot `title_wait`; replaced by menu reload |
| Menu background | `src/assets/menu_bg_v06.rle` (2249 → 8192) → LZ **1530** | `1000..15F9` | `MENU_BG_RELOAD` `8412` → `MENU_LZ_UNPACK` `1720`; `TITLE_RELOAD` |
| Court tiles | `cpc_court_mode1.bin` + hoop rows | **3856** (`2500..32FF` + `1600..170F`, 213 tiles) | match publish / dirty restore |
| Font | relocated glyph bank | base `(3434)=3B80`, blit `3B53` | menu 4/5, scores, `NATIVE_TEXT_GLYPH` |
| AMSTRAD ads | inside CPC court rows (~48..55 → court y 56..63) | tile row 6–7; **15 tiles only there** (120..134) | static court; restored with background |

Shared (must keep): `2000..24FF` TITLE_SRC band / replay / player union; `B498..BBFF` staged sprites; hoop rows 0..7; stamp `B338`; HUD RLE; stage-1 sprites.

## Deletable after replacement

| Data | Rule |
|---|---|
| Executive menu bitmap + RLE/LZ payload | fully unused once menu is drawn from font |
| Splash zlib asset | replace with generated text splash |
| `MENU_LZ_UNPACK` | only menu consumer; remove with packed menu |
| AMSTRAD-only tiles 120..134 | after VECTOR rewrite + full court re-dedupe |

Not free without proof: codec/helpers `1710..18A7`, player helpers `18CA..1B3F`, reserves, stack, replay workspace, video planes.

## Live menu commands (do not invent)

From ROM strings at `A797` / poll `A694` (`4110` digits `1..5`):

1. `1 PLAYER`
2. `2 PLAYERS`
3. `3 LEVEL` → `ROOKIE` / `AMATEUR` / `NBA`
4. `4 CHANGE NAMES`
5. `5 SELECT CONTROL`

Control redefine UI keeps `0 MENU` and key labels. Splash dismiss: Space. Match→menu: SHIFT+CTRL+ESC.

## Working state (before)

| Region | Bytes | Role |
|---|---:|---|
| TITLE_SRC `2000..24FF` | 1280 | menu dirty restore band (rows 72..111) |
| Replay `1B40..1FFF` | 1216 | record ring |
| Staged `B498..BBFF` | 1896 | sprite / replay high |
| Stack `BC00..BFFF` | 1024 | unchanged |
| Planes | 2×8192 | splash then live frame |

## CPC menu reference

Current Executive art is monochrome logo + the five commands above (see `menu_bg_v06.rle`, `build/v06/emu80-menu-final.png`). CPC match HUD uses blue/white/pink (`build/cpc/cpc-match-screen.png`); court ads are three **AMSTRAD** boards. Target chrome: black field, **BASKET MASTER**, same five commands drawn by game code, CPC frame accents, existing 8×8 font with programmatic 2× title.
