; Direct background helpers in the former 808A..84CF pre-entry slot.
; These replace pictures formerly published through the full-screen COMPOSE.
        include "labels_win_840e.inc"
        org     0x8412

MENU_PACKED    equ     0x1000          ; dw hi_addr, then low LZ, then high LZ
HUD_LOW_PACKED equ     0x808A
HUD_HIGH_PACKED equ    0x810B
TITLE_SNAPPED  equ     0x0FEF
DP_CUR         equ     0x0F69          ; TILE_BAND_FILL: tile pointers of the band

MENU_BG_RELOAD:
        push    bc
        push    de
        push    hl
        ; Dual LZ: exact CPC-coloured text chrome from the game font.
        ld      hl,MENU_PACKED + 2
        ld      de,0xE000
        call    MENU_LZ_BODY
        ld      hl,(MENU_PACKED)
        ld      de,0xC000
        call    MENU_LZ_BODY
        call    MENU_CHROME_DONE        ; TITLE_SNAPPED, copyright line
        xor     a
        ld      (0x0FEE),a              ; COURT_SYNCED: menu colour restore
        pop     hl
        pop     de
        pop     bc
        ret

; Stream both 32x72 HUD decoration planes directly into their hardware
; columns.  This deliberately uses no 2000 scratch: a 2304-byte unpack there
; would cross 24FF and overwrite the court source at 2500.
HUD_DECOR:
        push    bc
        push    de
        push    hl
        ld      hl,HUD_LOW_PACKED
        ld      d,0xE0
        call    HUD_RLE_APPLY
        ld      hl,HUD_HIGH_PACKED
        ld      d,0xC0
        call    HUD_RLE_APPLY
        ; Stored decoration uses the old role indices.  Preserve its low bit
        ; and map high := ~(low XOR high) for blue/white/black/salmon.
        ld      h,0xE0
        ld      d,0xC0
        ld      c,32
hdc_col:
        ld      l,0x20
        ld      e,0x20
        ld      b,72
hdc_row:
        ld      a,(de)
        xor     (hl)
        cpl
        ld      (de),a
        inc     l
        inc     e
        dec    b
        jp    nz,hdc_row
        inc     h
        inc     d
        dec     c
        jp      nz,hdc_col
        pop     hl
        pop     de
        pop     bc
        ret

; Stream format: 01..7F literal count + bytes, 80..FF run count + byte, 00 end.
HUD_RLE_APPLY:
        ld      e,0x20
hra_next:
        ld      a,(hl)
        inc     hl
        or      a
        ret     z
        jp      m,hra_run
        ld      c,a
hra_literal:
        ld      a,(hl)
        inc     hl
        call    hra_put
        dec     c
        jp      nz,hra_literal
        jp      hra_next
hra_run:
        and     0x7F
        ld      c,a
        ld      a,(hl)
        inc     hl
        ld      b,a
hra_repeat:
        ld      a,b
        call    hra_put
        dec     c
        jp      nz,hra_repeat
        jp      hra_next
hra_put:
        ; STORE: wipe menu residue in frame holes. Match text is reprinted
        ; after HUD_DECOR returns (HUD_TEXT_REFRESH) — OR left chrome bits
        ; that fail the post-remap pen check, and scores are drawn before
        ; this multi-frame unpack finishes anyway.
        ld      (de),a
        inc     e
        ld      a,e
        cp      0x68
        ret     nz
        ld      e,0x20
        inc     d
        ret

; TILE_BAND_FILL (COMPOSE_BOX tile band copier) is in tile_band.asm (glue).
