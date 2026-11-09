; Stand rows of COMPOSE_BOX while the fans stand (CPC stamp, cpc_stamp.asm).
; In the low adapter (glue): it outgrew the cpc_stamp slot B338..B454.
STAMP_DATA_ROWS equ     0x77F6          ; cpc_stamp.asm STAMP_DATA: 29 rows x 21 CPC bytes
SRF_COL         equ     5               ; cpc_stamp.asm STAMP_COL, _ROW, _W, _H
SRF_ROW         equ     10
SRF_W           equ     22
SRF_H           equ     29

; COMPOSE_BOX stand rows: the SP tile copier cannot see the stamp, so a
; stamped row is patched cell by cell after it. DE = end of the buffer row
; (kept), B1_ROW = its court row. IRQs stay on. Clobbers A, BC.
; The buffer row already holds the court pairs, so a cell is built straight
; from its two CPC bytes (the edge columns keep their court nibbles from the
; buffer); no STAMP_PAIR / COURT_PAIR per cell (09.11: the standing fans
; were ~25 frames a toggle, half of it here).
STAMP_ROW_FIX:
        ld      a,(BG_FETCH+1)       ; stamp state: the gate JP operand
        cp      STAMP_PAIR & 255
        ret     nz
        ld      a,(B1_ROW)              ; BROW: court row of this buffer row
        sub     SRF_ROW
        cp      SRF_H
        ret     nc
        push    de
        push    hl
        ld      l,a
        ld      h,0
        ld      c,l
        ld      b,h                     ; BC = r
        add     hl,hl
        add     hl,hl                   ; 4r
        add     hl,bc                   ; 5r
        add     hl,hl
        add     hl,hl                   ; 20r
        add     hl,bc                   ; 21r
        ld      bc,STAMP_DATA_ROWS
        add     hl,bc
        ld      (srf_base),hl           ; this stamp row
        ld      a,(0x0F1C)              ; RECT width
        ld      b,a
        add     a,a
        ld      c,a
        ld      a,e
        sub     c
        ld      e,a
        jp      nc,sfr_de
        dec     d                       ; DE = start of this buffer row
sfr_de:
        ld      a,(0x0F1A)              ; RECT column
        ld      c,a
sfr_col:                                ; B = cells left, C = column, DE = cell
        ld      a,c
        sub     SRF_COL
        cp      SRF_W
        jp      nc,sfr_skip             ; outside the stamp: the court stays
        ld      hl,(srf_base)
        cp      11
        jp      nc,sfr_r
        add     a,a                     ; left copy: j0 = 2(col-5)-1
        jp      z,sfr_c5                ; col 5: only b1 = j 0
        dec     a
        jp      sfr_add
sfr_r:
        sub     11
        add     a,a                     ; right copy: j0 = 2(col-16)
sfr_add:
        add     a,l
        ld      l,a
        jp      nc,sfr_hl
        inc     h                       ; HL -> b0
sfr_hl:
        push    bc
        ld      b,(hl)                  ; b0: left pixel pair
        ld      a,c
        cp      SRF_COL + SRF_W - 1
        jp      z,sfr_c26
        inc     hl
        ld      c,(hl)                  ; b1: right pixel pair
        ld      a,b
        rlca
        rlca
        rlca
        rlca
        and     0xF0
        ld      h,a
        ld      a,c
        and     0x0F
        or      h
        ld      (de),a                  ; low: b0 low nibble left, b1 right
        inc     de
        ld      a,b
        and     0xF0
        ld      h,a
        ld      a,c
        rrca
        rrca
        rrca
        rrca
        and     0x0F
        or      h
        ld      (de),a                  ; high: b0 high nibble left, b1 right
        inc     de
        pop     bc
        jp      sfr_next
sfr_c26:                                ; last column: left half only
        ld      a,(de)
        and     0x0F
        ld      h,a
        ld      a,b
        rlca
        rlca
        rlca
        rlca
        and     0xF0
        or      h
        ld      (de),a
        inc     de
        ld      a,(de)
        and     0x0F
        ld      h,a
        ld      a,b
        and     0xF0
        or      h
        ld      (de),a
        inc     de
        pop     bc
        jp      sfr_next
sfr_c5:                                 ; first column: right half only
        push    bc
        ld      c,(hl)                  ; b1 = j 0
        ld      a,(de)
        and     0xF0
        ld      h,a
        ld      a,c
        and     0x0F
        or      h
        ld      (de),a
        inc     de
        ld      a,(de)
        and     0xF0
        ld      h,a
        ld      a,c
        rrca
        rrca
        rrca
        rrca
        and     0x0F
        or      h
        ld      (de),a
        inc     de
        pop     bc
        jp      sfr_next
sfr_skip:
        inc     de
        inc     de
sfr_next:
        inc     c
        dec     b
        jp      nz,sfr_col
        pop     hl
        pop     de
        ret
srf_base:
        dw      0
