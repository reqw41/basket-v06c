; CPC standing-fans stamp, written straight to the Vector planes.
;
; CPC 2182 copies 21x32 mode-1 bytes (264A) into its working court
; background A568 at byte offsets 0Bh and 20h, so the screen and every later
; erase show the standing fans until the court is rebuilt. Here the stamp is
; a background state, not a screen overlay:
;   CPC_STAMP_ON  (A521, called twice per game frame on a type-4 score):
;                 first call points the match background fetch (BG_FETCH)
;                 at STAMP_PAIR and sets STAMP_DIRTY: the next publish
;                 composes the stamped rectangle with every object on it
;                 (damage_publish.asm); later calls return at once.
;   CPC_STAMP_OFF (COURT_TO_PLANES): back to plain court tiles (1800).
;
; Stored rows are stamp rows 2..30 (court rows 10..38); rows 0, 1, 31 equal
; the seated court. CPC pen bits: high nibble = Vector high plane (C000),
; low nibble = Vector low plane (E000), leftmost pixel in bit 7 / bit 3.
; Stamp CPC byte k (0..63 in the row) covers pixels 4k..4k+3; stamp bytes
; are k = 11..31 (data j = k-11) and k = 32..52 (j = k-32), i.e. Vector
; columns 5 (right half) .. 26 (left half).

        include "labels_cpc_stamp.inc"
        include "cells.inc"
COURT_PAIR      equ     COURT_TILE_PAIR          ; A = low, (0F59) = high
PAIR_HIGH       equ     0x0F59
CSPR_ROWS       equ     0x0F5F
STAMP_COL       equ     5
STAMP_ROW       equ     10
STAMP_W         equ     22
STAMP_H         equ     29

STAMP_DATA      equ     0x77F6          ; 609 bytes, placed by the builder

        org     0xB338                  ; former MSX stamp bitmap
; Every match background fetch (1AC0 low/high pair, 7B1F high byte, A0BF
; wipe 184A) calls BG_FETCH; the stamp state is this JP's operand.
BG_FETCH:
        jp      COURT_PAIR
BG_GATE         equ     BG_FETCH + 1
CPC_STAMP_ON:
        push    af
        ld      a,(BG_GATE)
        cp      STAMP_PAIR & 255
        jp      z,cso_done
        push    bc
        push    de
        push    hl
        ld      hl,STAMP_PAIR
        ld      (BG_GATE),hl
        ld      a,1                     ; the next publish recomposes it
        ld      (STAMP_DIRTY),a
        pop     hl
        pop     de
        pop     bc
cso_done:
        pop     af
        ret

CPC_STAMP_OFF:
        ld      hl,COURT_PAIR
        ld      (BG_GATE),hl
        jp      CLEAR_OFFCOURT

STAMP_RECT:
        db      STAMP_COL, STAMP_ROW, STAMP_W, STAMP_H

; HL = court address 2500 + row*32 + col. Returns A = low, (0F59) = high.
; Keeps BC, DE, HL and the index registers (same contract as 1800).
STAMP_PAIR:
        ld      a,l
        and     31
        sub     STAMP_COL
        cp      STAMP_W
        jp      nc,COURT_PAIR
        ld      a,h
        sub     0x25
        cp      8
        jp      nc,COURT_PAIR           ; rows >= 64 are never stamped
        push    hl
        push    de
        push    bc
        ld      b,a
        ld      a,l
        and     0xE0
        or      b
        rlca
        rlca
        rlca                            ; A = court row
        sub     STAMP_ROW
        cp      STAMP_H
        jp      nc,sp_court
        ld      c,a                     ; C = stamp data row r
        call    COURT_PAIR              ; edge nibbles stay court
        ld      b,a                     ; B = low plane
        ld      a,l
        and     31
        push    af                      ; Vector column
        ld      l,c
        ld      h,0
        ld      d,h
        ld      e,l                     ; DE = r
        add     hl,hl
        add     hl,hl                   ; 4r
        add     hl,de                   ; 5r
        add     hl,hl
        add     hl,hl                   ; 20r
        add     hl,de                   ; 21r
        ld      de,STAMP_DATA
        add     hl,de
        pop     af
        ld      c,a                     ; C = column
        sub     16
        jp      nc,sp_right
        add     a,11                    ; column - 5
        add     a,a
        dec     a                       ; j0 = 2(col-5)-1 (-1 at col 5)
        jp      sp_at
sp_right:
        add     a,a                     ; j0 = 2(col-16)
sp_at:
        ld      e,a
        rla
        sbc     a,a
        ld      d,a                     ; DE = j0, sign-extended
        add     hl,de                   ; HL -> left CPC byte
        ld      a,(PAIR_HIGH)
        ld      e,a                     ; E = high plane
        ld      a,c
        cp      STAMP_COL
        jp      z,sp_b1
        ld      d,(hl)
        ld      a,e
        xor     d
        and     0x0F
        xor     d
        ld      e,a                     ; high: b0 high nibble on the left
        ld      a,d
        rlca
        rlca
        rlca
        rlca
        xor     b
        and     0xF0
        xor     b
        ld      b,a                     ; low: b0 low nibble on the left
sp_b1:
        inc     hl
        ld      a,c
        cp      STAMP_COL + STAMP_W - 1
        jp      z,sp_out
        ld      d,(hl)
        ld      a,d
        xor     b
        and     0x0F
        xor     b
        ld      b,a                     ; low: b1 low nibble on the right
        ld      a,d
        rrca
        rrca
        rrca
        rrca
        xor     e
        and     0x0F
        xor     e
        ld      e,a                     ; high: b1 high nibble on the right
sp_out:
        ld      a,e
        ld      (PAIR_HIGH),a
        ld      a,b
        pop     bc
        pop     de
        pop     hl
        ret
sp_court:
        pop     bc
        pop     de
        pop     hl
        jp      COURT_PAIR

; STAMP_ROW_FIX (COMPOSE_BOX stand rows) is in stamp_row.asm (glue).
CPC_STAMP_END:
