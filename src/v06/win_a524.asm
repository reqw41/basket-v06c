; A521 is JP NATIVE_STAMP (3 bytes). A524..A52B held SET_VBLANK (MSX VDP
; status emulation), removed with the soft VDP: zero padding now.
        include "labels_win_a524.inc"
        org     0xA524
SLOT_A524:
        ds      8, 0

; CHGSND body: A = 0 -> click off, else on (bit 0 of port 00, BSR).
BIOS_CLICK:
        cp      1                       ; CY = (A == 0)
        sbc     a,a                     ; FF / 00
        inc     a                       ; 0 / 1
        out     (0x00),a
        ret
        ds      17 - ($ - SLOT_A524), 0    ; the slot is 17 bytes
