; Adapter RAM cells and constants shared by glue (softvdp) and color_sprite.
; Identical equ redefinitions are legal in sjasm, so units may include it twice.

; --- Constants ---
SOFT_VRAM       equ     0x2000          ; legacy VRAM-coordinate base
SPGEN_LO        equ     0x8000
VISIBLE_PLANE   equ     0xE000          ; 8KB low colour-bit plane
PAGE1           equ     0x2000          ; compact replay staging starts here
DIRTY_COUNT     equ     0x0F80
DIRTY_LIST      equ     0x0F81          ; 11 × (col,row,w,h); a match draws 8
DIRTY_MAX       equ     11
; Damage publish (damage_publish.asm), after the dirty list.
META_OLD        equ     0x0FAD          ; 11 × (record, X, Y) of the last frame
DMG_BASE        equ     0x0FD9          ; word: first damage box (B498; the stream follows the boxes)
DMG_END         equ     0x0FDB          ; word: one past the last box
DMG_PUB         equ     0x0FDD          ; word: first box not yet copied to the planes
STAMP_DIRTY     equ     0x0FDF          ; 1 = CPC_STAMP_ON switched the stand background
DMG_NB          equ     0x0FE0          ; 4: box being added (c0,r0,c1,r1)
DMG_TB          equ     0x0FE4          ; 4: bounding box candidate
DMG_OCNT        equ     0x0FE8          ; object count of the other frame
PLANES_CLEAN    equ     0x0FE9          ; 1 = court repainted: no object on the planes
DP_READY        equ     0x0FEA          ; 1 = a composed batch waits for the frame IRQ
DP_STOP         equ     0x0FEB          ; word: one past the batch's last box
DP_COST         equ     DMG_TB          ; word: copy time of the batch (TB is done by then)
COURT_SYNCED    equ     0x0FEE
TITLE_SNAPPED   equ     0x0FEF
TITLE_SRC       equ     0x2000          ; shared gfx work: 32×40 menu band
TITLE_FIRST_ROW equ     80              ; matches TITLE_SNAP (COURT_PLANE_Y → y80..119)
TITLE_ROWS      equ     40              ; rows 80..119, 1280 bytes
V_FILL_BYTE     equ     0x0F19          ; native D517/D529 fill scratch
CSPR_SRC        equ     0x0F5A          ; current two-plane source row
CSPR_STRIDE     equ     0x0F5C          ; bytes per source plane row (1..3)
CSPR_SHIFT      equ     0x0F5D          ; horizontal shift: 0,2,4,6 pixels
CSPR_OUT_WIDTH  equ     0x0F5E          ; shifted width in plane bytes
CSPR_ROWS       equ     0x0F5F          ; remaining visible rows
CSPR_CACHE_PTR  equ     0x0F69          ; staged p0,p1 stream pointer
CSPR_UNCHANGED  equ     0x0F6B          ; current sprite matches prior frame
CS_STAGE        equ     0x0F6C          ; COLOR_SPRITE: 0 = the game's call (record), 1 = stage rows
SS_ALL          equ     0x0F67          ; STAGE_SLOTS: 1 = stage every object (replay)
SS_LEFT         equ     0x0F68          ; STAGE_SLOTS: slots left
SS_BASE         equ     0x0F76          ; word: first staged byte of this pass
V_SPR_LOAD      equ     CSPR_SRC        ; dead mono compatibility body
V_SPR_MASK      equ     CSPR_STRIDE
SPR_Y           equ     CSPR_SHIFT
; Previous-frame dirty rects. Work RAM — NOT free code space.
; Permanent home: B258..B2C4 (109 bytes), outside 84D0..B257 and outside
; the ranges relocated out of the hardware planes. Original MSX pointer
; table at B258 is unused after native sprite/menu patches.
COURT_SRC       equ     0x2500

; Mirrored sprite rows (tools/pack_sprite_mirrors.py)
CSPR_MNEXT      equ     0x0F65          ; stored row cursor of a mirrored sprite (0 = CSPR_SRC)
MIR_BUF         equ     0x0F70          ; 6 bytes: the current row, bit-reversed
CSPR_PRE        equ     0x0F63          ; empty canvas rows still to come above
CSPR_KEEP       equ     0x0F64          ; stored rows still to come

; i8080 adapter cursors (former IX/IY uses), in the cleared 0F00..0F0F block
RING_LEFT       equ     0x0F03          ; replay playback: records left (ring.asm)
RING_WRAPPED    equ     0x0F04          ; 1 = the replay ring has wrapped since the recording started
CS_START        equ     0x0F05          ; COLOR_SPRITE: stream pointer at the first row (word)
HOOP_CACHE      equ     0xB020          ; 2 x (record, X, Y, size, stream at, pass, 192 staged bytes): hoops (color_sprite.asm)
HC_GEN          equ     0x0F07          ; word: staging pass, +1 per STAGE_SLOTS (hoop cache tag)
DP_WAIT         equ     0x0F01          ; lines the frame IRQ waits before a box copied behind the beam
PCC_RECT        equ     0x0FF6          ; PLAYER_COMPOSE_CLIPPED: object rect (word)
NRM_RECT        equ     0x0F7A          ; STAGED_RECT_ADVANCE: rect cursor (word)
V_NOISE         equ     0x0F7C          ; ball noise flag (menu_color_bg.asm SND_NOISE_SCAN)
