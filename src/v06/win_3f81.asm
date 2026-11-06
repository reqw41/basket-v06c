; Slow row of the dirty high-plane restorer. Called only for menu rows and the
; crowd/stand bands whose high bit depends on geometry and the low plane.
        include "labels_win_3f81.inc"
        include "cells.inc"
        org     0x3F81

TITLE_SNAPPED   equ     0x0FEF
V_FILL_BYTE     equ     0x0F19

COLOR_CLEAR_ROW_COMPLEX:
        ld      a,(B1_ROW)
        ld      e,a
        ld      a,0xD7
        sub     e
        ld      e,a
        ld      a,(B1_COL)
        add     a,0xC0
        ld      d,a
        ld      a,(B1_WIDTH)
        ld      b,a
ccrc_col:
        ld      a,d
        add     a,0x20
        ld      h,a
        ld      l,e
        ld      a,(hl)
        ld      (V_FILL_BYTE),a
        ld      a,(TITLE_SNAPPED)
        or      a
        jp      nz,ccrc_menu
        call    DIRTY_COURT_HIGH_BYTE
        jp      ccrc_store
ccrc_menu:
        ld      a,(hl)
        cpl
ccrc_store:
        ld      (de),a
        inc     d
        dec    b
        jp    nz,ccrc_col
        ret

COLOR_CLEAR_ROW_COMPLEX_END:

