; Ball-possession icon (MSX 8AAE → CPC 07F9), drawn straight to the planes.
;
; MSX blitted an 8x8 mono cell from 7750 (ball) or 7758 (blank) through D252;
; in this port those bytes are CPC sprite data and the pattern writes never
; reached the plane. The CPC draws its own sprites 48h (ball) / 49h (dash).
; Here: CPC bank sprites 72 / 73 (8x8, rows low/high plane) at the MSX cell,
; with blue and white swapped like the rest of the Vector HUD (blue panels,
; white ink; CPC: white panels, blue ink). Pen 0 becomes the blue panel, so
; the ball is erased when the blank sprite follows.
;
; Entry (replaces the D252 tail at 8AC2 after POP HL): HL = col:y (H = cell
; column, L = pixel row), DE = 7750 ball / 7758 blank. Clobbers AF BC DE HL.

        include "labels_hud_icon.inc"
SPR_BASE        equ     0x415A
SPR_TABLE       equ     0x7760

        org     0xB455                  ; free tail after cpc_stamp.asm
HUD_ICON:
        ld      a,e
        cp      0x50
        ex      de,hl
        ld      hl,(SPR_TABLE + 2 * 72)
        jp      z,hi_spr
        ld      hl,(SPR_TABLE + 2 * 73)
hi_spr:
        ex      de,hl
        ld      a,h
        add     a,0xE0
        ld      h,a
        ld      a,0xDF
        sub     l
        ld      l,a                     ; HL = low plane, top row
        push    hl
        ld      hl,SPR_BASE + 4         ; skip height, width, top 0, keep 8
        add     hl,de
        ex      de,hl                   ; DE = first row (low, high)
        pop     hl
        ld      b,8
hi_row:
        ld      a,(de)                  ; low = white ink
        inc     de
        ld      c,a
        ld      a,(de)                  ; high = blue ink
        inc     de
        ld      (hl),a                  ; swapped: blue ink -> white (low)
        or      c
        cpl                             ; pen 0 -> panel blue (high)
        or      c                       ; white ink -> blue (high)
        ld      c,a
        ld      a,h
        sub     0x20
        ld      h,a
        ld      (hl),c
        add     a,0x20
        ld      h,a
        dec     l
        dec    b
        jp    nz,hi_row
        ret

; Clock caption, as on the CPC (and the retired MSX scoreboard art).
TIME_TEXT:
        db      "TIME", 0xFF
HUD_ICON_END:
