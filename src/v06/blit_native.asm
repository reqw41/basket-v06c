; MSX D252 VRAM blitter (relocated 34BD..352A) without the VDP.
;
; D241 / D247 / D24C / D252 all reach 34BD for a VRAM rectangle: pattern
; pass (OUT 99h / 98h) then a colour-table pass. In this port every one of
; those writes lands in dropped VRAM (>= 1800h) — the title panels and
; dunk-time colour boxes are drawn natively — so only the RAM effect stays:
; per pass 3302 += (width >> 3) * ((height * 8) & FFh). A75F skips the
; pattern pass by writing JR (18h) over 34DF; it restores CD 88h afterwards
; (an unrelocated MSX word: the old body then called 3488 and executed the
; "DiNaMiC" string as code). 34DF..34E1 is only that flag cell now.
; The RAM-buffer branches (3530..) are untouched.

        include "labels.inc"
SRC_PTR         equ     BLIT_SRC
PASS_FLAG       equ     BLIT_PASS_FLAG
        org     0x34BD
        jp      BLIT_ADVANCE
        ds      PASS_FLAG - $, 0
        db      0xCD, 0xF0, 0x34        ; A75F flag cell (JR = colour pass only)
BLIT_ADVANCE:
        ld      a,(BLIT_W)
        rrca
        rrca
        rrca
        and     0x1F
        ld      b,a                     ; columns (0 = 256, as DJNZ)
        ld      a,(BLIT_H)
        rlca
        rlca
        rlca
        ld      e,a
        ld      d,0                     ; per-column advance
        ld      a,(PASS_FLAG)
        cp      0x18
        ld      c,2
        jp      nz,ba_pass
        dec     c
ba_pass:
        ld      hl,(SRC_PTR)
ba_loop:
        push    bc
ba_col:
        add     hl,de
        dec    b
        jp    nz,ba_col
        pop     bc
        dec     c
        jp      nz,ba_loop
        ld      (SRC_PTR),hl
        ret
BLIT_NATIVE_END:
