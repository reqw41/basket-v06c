; Court background, both planes, tile by tile (COURT_COLORIZE, win_7ae8.asm,
; jumps here: the 7AE8 window has no room). Unit adapter_hi.asm.
CF_SRC          equ     0x2500          ; tile indices, 32 per tile row
; Rebuild both planes of court rows 8..119 tile by tile: the tile pointer once
; (26C0 + 16 * index, tiles from 3300 at COURT_TAIL 1600, as COURT_TILE_CACHE),
; then its 8 rows of (low, high) pairs straight into the column. Same bytes as
; the former per-byte COURT_TILE_PAIR loop, ~7x faster. IRQs stay on.
COURT_FILL:
        ld hl,CF_SRC
        ld (cf_idx+1),hl
        ld a,0xD7
        ld (cf_row+1),a
cf_trow:
        ld a,0xE0
        ld (cf_col+1),a
cf_idx:
        ld hl,0                 ; patched: tile index
        ld a,(hl)
        inc hl
        ld (cf_idx+1),hl
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,0x26C0
        add hl,de
        ld a,h
        cp 0x33
        jp c,cf_col
        sub 0x33-0x16           ; COURT_TAIL
        ld h,a
cf_col:
        ld a,0                  ; patched: low-plane column page
        ld d,a
        sub 0x20
        ld b,a
cf_row:
        ld a,0                  ; patched: first plane row of the tile row
        ld e,a
        ld c,a
        REPT 8
        ld a,(hl)
        ld (de),a
        inc l                   ; tiles are 16-aligned
        ld a,(hl)
        ld (bc),a
        inc l
        dec e
        dec c
        ENDM
        inc d
        ld a,d
        ld (cf_col+1),a
        jp nz,cf_idx            ; columns E0..FF
        ld a,(cf_row+1)
        sub 8
        ld (cf_row+1),a
        cp 0xD7-112
        jp nz,cf_trow
        ld (0x17B4),a           ; 67: COURT_TILE_PAIR rebuilds its row cache
        ret

