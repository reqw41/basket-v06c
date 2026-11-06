; Dual-plane menu LZ body. Lives in the freed menu-slot gap after the packed
; chrome streams (ends at 131F). Entry remains CALL 1720 → JP here.
        include "labels.inc"
        org     0x1320

MENU_LZ_END_PAGE equ 0x0FED

; HL = packed stream, DE = destination; stops when D reaches start + 20h.
; Flag byte LSB first: 1 = literal byte; 0 = match: lo offset, then
; (hi offset << 4 | len), len 15 -> extra byte + 18, else len + 3.
; i8080 code: B = flags, C = tokens left (pushed over a match);
; match copies (HL = DE - offset) -> (DE), BC bytes; stream on the stack.
MENU_LZ_BODY:
        ld      a,d
        add     a,0x20
        ld      (MENU_LZ_END_PAGE),a
ml_flags:
        ld      b,(hl)
        inc     hl
        ld      c,8
ml_token:
        ld      a,b
        rra                             ; CY = next flag bit
        ld      b,a
        push    bc
        jp      nc,ml_match
        ld      a,(hl)
        inc     hl
        ld      (de),a
        inc     de
ml_done:
        pop     bc
        ld      a,(MENU_LZ_END_PAGE)
        cp      d
        ret     z
        dec     c
        jp      nz,ml_token
        jp      ml_flags
ml_match:
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        inc     hl
        push    hl
        ld      a,b
        rrca
        rrca
        rrca
        rrca
        and     0x0F
        ld      h,a
        ld      a,e
        sub     c
        ld      l,a
        ld      a,d
        sbc     a,h
        ld      h,a                     ; HL = DE - offset
        ld      a,b
        and     15
        cp      15
        jp      z,ml_long
        add     a,3                     ; CY = 0
ml_len:
        ld      c,a
        ld      a,0
        adc     a,a
        ld      b,a                     ; BC = length (3..273)
ml_copy:
        ld      a,(hl)
        ld      (de),a
        inc     hl
        inc     de
        dec     bc
        ld      a,b
        or      c
        jp      nz,ml_copy
        pop     hl
        jp      ml_done
ml_long:
        ex      (sp),hl
        ld      a,(hl)
        inc     hl
        ex      (sp),hl
        add     a,18
        jp      ml_len
MENU_LZ_BODY_END:
