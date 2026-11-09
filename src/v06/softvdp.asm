; ============================================================================
;  SOFT VDP: plane I/O + scene restore for Vector-06C
;
;  Memory map (see docs/v06-memory.md):
;    2000..24FF  shared gfx work: menu band 32x40 / replay 16x60
;    2500..32FF  Court source 32×112
;    C000..DFFF  Active high colour-bit plane
;    E000..FFFF  Active low colour-bit plane
;
;  Pattern I/O and sprites write the visible plane directly. FRAME_BEGIN
;  restores last frame's dirty rectangles before the next sprite pass.
; ============================================================================

#include "cells.inc"

; ============================================================================
;  VRAM_TO_PLANE: DE = VRAM 0000..17FF → HL = visible-plane byte.
;  col = E>>3, y = D*8+(E&7), addr = (E0+col)<<8 | (DF-y)
;  Clobbers A. Carry clear.
; ============================================================================
VRAM_TO_PLANE:
        ld      a,e
        and     7
        ld      l,a
        ld      a,d
        add     a,a
        add     a,a
        add     a,a
        add     a,l
        cpl
        sub     0x20
        ld      l,a
        ld      a,e
        rrca
        rrca
        rrca
        and     0x1F
        add     a,VISIBLE_PLANE >> 8
        ld      h,a
        ret

; VRAM_PTR: only the pattern table is backed (by the plane). Carry = drop.
VRAM_PTR:
        ld      a,d
        cp      0x18
        jp      nc,vp_none
        call    VRAM_TO_PLANE
        or      a
        ret
vp_none:
        scf
        ret

; Direct replacements for hot legacy pattern writers. These bypass the VDP
; latch/state machine and write the Vector plane in its native column layout.
; They are called by patched game routines whose address semantics are known.
NATIVE_PAIR_DIRECT:
        ; HL = tile coordinate pair used by 9F48, C = byte; preserves HL/DE.
        push    hl
        push    de
        ld      a,l
        rlca
        rlca
        rlca
        or      5
        ld      e,a
        ld      d,h
        call    VRAM_TO_PLANE
        jp      NATIVE_PAIR_TAIL

NATIVE_TEXT_GLYPH:
        ; HL = eight-byte glyph source. Screen tile lives in 4102/4103.
        ex      de,hl
        ld      a,(TEXT_COL)
        rlca
        rlca
        rlca
        ld      l,a
        ld      a,(TEXT_ROW)
        ld      h,a
        push    de
        ld      d,h
        ld      e,l
        call    VRAM_TO_PLANE
        pop     de
        ld      b,8
ntg_row:
        ld      a,(de)
        call    TEXT_GLYPH_PAIR
        dec    b
        jp    nz,ntg_row
        ret

NATIVE_FILL_DIRECT:
        ; D517 contract: A=value, HL=VRAM address, BC=count.
        ld      (V_FILL_BYTE),a
        push    hl
        push    de
        ld      d,h
        ld      e,l
nfd_loop:
        call    VRAM_PTR
        jp      c,nfd_skip
        ld      a,(V_FILL_BYTE)
        ld      (hl),a
nfd_skip:
        inc     de
        dec     bc
        ld      a,b
        or      c
        jp      nz,nfd_loop
        pop     de
        pop     hl
        ld      a,(V_FILL_BYTE)
        ld      e,a
        ret

NATIVE_FILL_INC:
        ; D529 contract: as above, increment the byte after every store.
        ld      (V_FILL_BYTE),a
        push    hl
        push    de
        ld      d,h
        ld      e,l
nfi_loop:
        call    VRAM_PTR
        jp      c,nfi_skip
        ld      a,(V_FILL_BYTE)
        ld      (hl),a
nfi_skip:
        ld      a,(V_FILL_BYTE)
        inc     a
        ld      (V_FILL_BYTE),a
        inc     de
        dec     bc
        ld      a,b
        or      c
        jp      nz,nfi_loop
        pop     de
        pop     hl
        ld      a,(V_FILL_BYTE)
        ld      e,a
        xor     a
        ret

; The MSX VDP port emulation (OUT 98h/99h, IN 98h/99h) is gone: no game
; path reaches it any more (tools/inventory_softvdp_v06.py fails if one
; does). Fixed entries below start at FRAME_END = 040B; the freed bytes are
; zero padding.



; ============================================================================
;  Match and menu both paint the plane. Shared gfx work holds menu background.
; ============================================================================
COURT_ROWS      equ     112
COURT_PLANE_Y   equ     0x68            ; DF-119

FRAME_END:
        jp      COLOR_FRAME_END

FRAME_RESET:
        call    HUD_DECOR
        ; HUD_DECOR STOREs over the band (multi-frame); put digits back.
        call    HUD_TEXT_REFRESH
        xor     a
        ; Size-neutral: do not clear COURT_SYNCED. Mid-match resets must keep
        ; tile-pair restore; wiping sync forces menu invert and kills pink.
        ld      (TITLE_SNAPPED),a
        ld      (DIRTY_COUNT),a
        ld      (DIRTY_OLD_COUNT),a
FRAME_BEGIN:
        jp      COLOR_MATCH_PREP

; Colour renderer preamble: keep the complete previous hardware frame visible
; while the next sprite set is converted into the staging cache.
COLOR_MATCH_PREP:
        push    af
        push    bc
        push    de
        push    hl
        call    DIRTY_SAVE_OLD
        xor     a
        ld      (DIRTY_COUNT),a
        ld      a,(COURT_SYNCED)
        or      a
        call    z,COURT_TO_PLANES
        ld      hl,0xB498
        ld      (CSPR_CACHE_PTR),hl
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

; 2500 (ROM image, row-major) → visible plane. No C298 shadow.
COURT_TO_PLANES:
        call    DP_SYNC                 ; a posted batch would land on top
        call    CPC_STAMP_OFF           ; seated fans again, then rows 0..7
        call    COURT_COLORIZE
        ld      a,1
        ld      (COURT_SYNCED),a
        ld      (PLANES_CLEAN),a        ; the next publish draws every object
        ret

COURT_BLIT:
C298_TO_PLANE:
        jp      COURT_TO_PLANES

; Retained symbol-only compatibility entries. B01C now jumps directly to
; COLOR_SPRITE, so the old strip loader/compositor is unreachable.
SPRITE_ROWS:
        ret

DIRTY_SAVE_OLD:
        ld      a,(DIRTY_COUNT)
        ld      (DIRTY_OLD_COUNT),a
        or      a
        ret     z
        add     a,a
        add     a,a
        ld      c,a
        ld      b,0
        push    bc
        ld      hl,CSPR_META            ; metas of the frame on screen
        ld      de,META_OLD
        call    MEM_COPY
        pop     bc
        ld      hl,DIRTY_LIST
        ld      de,DIRTY_OLD_LIST
        call    MEM_COPY
        ld      a,(DIRTY_OLD_COUNT)
        ld      b,a
        ld      hl,DIRTY_OLD_LIST+2
        ld      de,4
dso_unmark:
        ld      a,(hl)
        and     0x7F
        ld      (hl),a
        add     hl,de
        dec    b
        jp    nz,dso_unmark
        ret

PLANE_TO_COMPOSE:
        ; Compatibility entry: full-plane compose no longer exists.
        ret

DIRTY_ADD:
        push    af
        push    bc
        push    de
        push    hl
        ld      a,(DIRTY_COUNT)
        cp      DIRTY_MAX
        jp      nc,da_done
        ld      l,a
        inc     a
        ld      (DIRTY_COUNT),a
        ld      h,0
        add     hl,hl
        add     hl,hl
        ld      de,DIRTY_LIST
        add     hl,de
        ld      a,(B1_COL)
        ld      (hl),a
        inc     hl
        ld      a,(B1_ROW)
        ld      (hl),a
        inc     hl
        ld      a,(B1_WIDTH)
        ld      (hl),a
        inc     hl
        ld      a,(B1_HEIGHT)
        ld      (hl),a
da_done:
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

; ============================================================================
;  SPRITE_OR: one strip at B1E4+B1E2 directly onto the visible plane.
;  dest = already-composed byte (previous sprites this frame stay).
;  mask displacement is V_SPR_MASK (B180), not 3 and not B1_WIDTH.
; ============================================================================
        ret

; ============================================================================
;  MENU_FRAME_BEGIN: A4A8 — snapshot title once, then restore dirty rects
;  from the compact title band so menu players AND/OR onto the artwork.
; ============================================================================
MENU_FRAME_BEGIN:
        jp      COLOR_MENU_PREP

COLOR_MENU_PREP:
        push    af
        push    bc
        push    de
        push    hl
        call    TITLE_SNAP
        call    DIRTY_SAVE_OLD
        xor     a
        ld      (DIRTY_COUNT),a
        ld      hl,0xB498
        ld      (CSPR_CACHE_PTR),hl
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

TITLE_RELOAD:
        call    DP_SYNC                 ; the last match batch first
        jp      MENU_BG_RELOAD

TITLE_SNAP:                             ; the menu is on screen
        ld      a,1
        ld      (TITLE_SNAPPED),a
        ret

; Row 0 (y=0-7, E=D8-DF): leftover title above the stands. Do not
; touch E=00-67 — that is the HUD (rows 18-20).
CLEAR_OFFCOURT:
        ld      d,VISIBLE_PLANE >> 8
        ld      c,32
        xor     a
co_col:
        ld      e,0xD8
        ld      b,8
co_hi:
        xor     a
        ld      (de),a                  ; low plane 0
        ld      a,d
        sub     0x20
        ld      d,a
        ld      a,0xFF
        ld      (de),a                  ; high plane FF
        ld      a,d
        add     a,0x20
        ld      d,a
        inc     e
        dec    b
        jp    nz,co_hi
        inc     d
        dec     c
        jp      nz,co_col
        ret

; Power bar rows 5..6 of the HUD cell (9F48): set bits white, clear bits the
; blue strip, both planes. A low-plane-only write left pink dashes on blue
; and lost the rest of the bar.
NATIVE_PAIR_TAIL:
        ld      a,c                     ; MSX 3-px segments E0/EE -> solid
        rrca                            ; F0/FF like the CPC bar
        and     0x11
        or      c
        ld      e,a
        ld      (hl),a
        dec     l
        ld      (hl),a
        ld      a,h
        sub     0x20
        ld      h,a
        ld      a,e
        cpl
        ld      (hl),a
        inc     l
        ld      (hl),a
        pop     de
        pop     hl
        ld      a,c
        ret

; ============================================================================
;  VDP INIT: Initialize soft VDP state
; ============================================================================
SOFTVDP_INIT:
        push    af
        push    bc
        push    hl
        
        ; Clear the 0F00..0F0F adapter scratch (former VDP registers)
        ld      hl,0x0F00
        ld      b,16
vi_clear:
        ld      (hl),0
        inc     hl
        dec     b
        jp      nz,vi_clear
        
        xor     a
        ld      (DIRTY_COUNT),a
        ld      (DIRTY_OLD_COUNT),a
        ld      (COURT_SYNCED),a
        ld      (TITLE_SNAPPED),a
        ld      (0x0FED),a             ; MATCH_MODE (relocated from B206)
        ld      (V_SPR_MASK),a
        ld      (SPR_Y),a
        ld      (0x0F18),a             ; R_ARMED (replay pacing)
        
        ; Soft VRAM is already initialised in the ROM image.
        ; Visible plane cleared by ADAPTER_INIT / DEBUG pattern.
        
        pop     hl
        pop     bc
        pop     af
        ret

; Former SET_VBLANK body was 8 bytes here. The procedure lives at A524
; (absolute equ). Nothing in the adapter may depend on this address.
