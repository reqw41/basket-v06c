; Direct high-plane court background generator in the proven free 7AE8..7B9C
; tail.  The low plane remains the exact MSX court bitmap at 2500; this code
; assigns CPC-style pens without storing another 3584-byte court copy.
        include "labels_win_7ae8.inc"
        include "cells.inc"
        org     0x7AE8

COURT_SRC       equ     0x2500
CH_COL          equ     0x0F5C          ; court column scratch (not B1_COL)
CH_ROW          equ     0x0F5D          ; court row scratch (not B1_ROW)
V_FILL_BYTE     equ     0x0F19

; Rebuild both planes of court rows 8..119: court_fill.asm (adapter_hi).
COURT_COLORIZE:
        jp COURT_FILL

COURT_HIGH_BYTE:
        push bc
        push hl
        ld a,(CH_ROW)
        sub 8
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld a,(CH_COL)
        ld c,a
        ld b,0
        add hl,bc
        ld bc,COURT_SRC
        add hl,bc
CHB_BG_SITE:
        call BG_FETCH             ; BG_FETCH (court or CPC stamp)
        ld a,(0x0F59)
        pop hl
        pop bc
        ret

; Menu player pairs sit on the filled blue panel only. Solid pen 0 replaces
; MENU_BUFFER_ROW_COLOR so the DI fill finishes inside one frame.
MENU_BUFFER_ROW:
        xor     a
mbr_blue:
        ld      (de),a
        inc     de
        ld      (de),a
        inc     de
        dec    b
        jp    nz,mbr_blue
        ret
COURT_HELPERS_END:


; Translate renderer restore coordinates, preserving player bytes under balls.
DIRTY_COURT_HIGH_BYTE:
        call    PLAYER_BYTE_PROTECTED
        ret     nz
dch_background:
        ld      a,d
        sub     0xC0
        ld      (CH_COL),a
        ld      a,(B1_ROW)
        add     a,8
        ld      (CH_ROW),a
        jp      COURT_HIGH_BYTE
