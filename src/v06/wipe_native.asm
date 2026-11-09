; Post-score court wipe (A0BF), written straight to the planes.
;
; A0BF steps C = 31h..01h, one per frame (HALT), calling A0D0 then A132.
; MSX A0D0 re-sent one court column from the C298 shadow through OUT 99h /
; OUT 98h (pattern, rows 8..119) plus a TMS colour column; A132 painted a
; colour-table "curtain" only. The Vector has no colour table, so A132 is a
; RET and A0D0 copies the column from the match background (BG_FETCH: court
; tiles or the CPC stamp) into both planes. Installed in place after the
; high-memory relocation; nothing outside A0BF jumps into A0D0..A1A9.
; The column wipes the objects too: PLANES_CLEAN makes the next match
; publish (damage_publish.asm) draw every object again.

        include "labels.inc"
        include "cells.inc"
PAIR_HIGH       equ     0x0F59
COURT_SRC_HI    equ     0x25            ; court row 0 = 2500

        org     0xA0D0
WIPE_COLUMN:                            ; C = step; A0BF points IX at WIPE_DIR
        call    DP_SYNC                 ; the last match batch first
        ld      a,(WIPE_DIR)            ; read it directly: no IX on the i8080
        or      a
        jp      p,wc_right
        ld      a,0x31
        sub     c
        cp      0x20
        ret     nc
        jp      wc_go
wc_right:
        ld      a,c
        sub     0x12                    ; MSX: C < 12h draws nothing
        ret     c
wc_go:                                  ; A = column 0..31
        push    bc
        ld      b,a
        ld      a,1                     ; objects under the column are gone:
        ld      (PLANES_CLEAN),a        ; the next publish draws all of them
        ld      a,b
        ld      l,a
        ld      h,COURT_SRC_HI
        add     a,0xE0
        ld      d,a
        ld      e,0xD7                  ; screen y 8 = court row 0
        ld      b,112
wc_row:
        call    BG_FETCH
        ld      (de),a
        ld      a,d
        sub     0x20
        ld      d,a
        ld      a,(PAIR_HIGH)
        ld      (de),a
        ld      a,d
        add     a,0x20
        ld      d,a
        dec     e
        ld      a,l
        add     a,32
        ld      l,a
        jp      nc,wc_next
        inc     h
wc_next:
        dec    b
        jp    nz,wc_row
        pop     bc
        ret
WIPE_COLUMN_END:

#assert $ <= 0xA132               ; the code above must not run into this org
        org     0xA132
WIPE_COLOUR:                            ; MSX colour-table curtain: nothing here
        ret
WIPE_COLOUR_END:
