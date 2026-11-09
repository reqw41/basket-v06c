; Controls as in brucelee-v06c (09.11). One player: player 1 = cursor keys +
; SPACE and both joysticks «П». Two players: player 1 = cursor keys + SPACE
; and joystick «П» B, player 2 = joystick «П» A. ВК pauses (kbd.asm).
;
; The game's own reader (AF05) called D5DE once per control on the MSX
; snapshot: five redefinable player 1 codes (default 1 Q D F Z) and the MSX
; cursor keys + RETURN for player 2. AF0B now jumps to NATIVE_PADS, which
; builds the same two bytes from the Vector inputs directly:
;   PAD_P1 (AC4D) / PAD_P2 (AC4E): b0 up, b0|b1 down, b2 left, b2|b3 right,
;   b4 fire; opposite directions cancel (as AF05 did).
; With one player PAD_P2 stays 0 for the AI, as on the MSX. Letters and
; digits no longer steer anyone; menu item 5 (SELECT CONTROL) is gone.

V_VROW          equ     0x0F38          ; raw Vector rows (frame IRQ poll)
V_KJOY          equ     0x0F34          ; port 6 as polled: both sticks / B (kbd.asm)

NATIVE_PADS:
        ld      a,(V_KJOY)
        call    joy_bits                ; C = joystick of player 1
        ld      a,(V_VROW)              ; row 0: b2 ВК, b4 ← b5 ↑ b6 → b7 ↓
        cpl                             ; 1 = down
        ld      hl,CURSOR_DIRS
        call    jm_map
        ld      a,(V_VROW+7)            ; SPACE, bit 7, 0 = down
        rlca
        jp      c,np_p1
        ld      a,c
        or      0x10
        ld      c,a
np_p1:
        ld      a,c
        call    np_code
        ld      (PAD_P1),a
        ld      c,0
        ld      a,(ONE_PLAYER)          ; one player: player 2 is the AI,
        or      a                       ; its keys stay up (as on the MSX
        jp      nz,np_p2                ; with only 1 Q D F Z pressed)
        ld      a,(V_KJOY2)             ; joystick A (kbd.asm)
        call    joy_bits
np_p2:
        ld      a,c
        call    np_code
        ld      (PAD_P2),a
        ret

; A = port 6 (0 = pressed: b0 right, b1 left, b2 up, b3 down, b6/b7 fire;
; b4 and b5 read 1 when a joystick is there) -> C = b0 up b1 down b2 left
; b3 right b4 fire, 0 without a joystick.
joy_bits:
        ld      c,0
        cpl
        ld      b,a
        and     0x30
        ret     nz                      ; nothing on the port
        ld      a,b
        and     0xC0
        jp      z,jb_dirs
        ld      c,0x10
jb_dirs:
        ld      a,b
        ld      hl,JOY_DIRS
        jp      jm_map

; A = b0 up b1 down b2 left b3 right b4 fire -> the game's control byte.
np_code:
        ld      b,a
        and     0x0F
        ld      e,a
        ld      d,0
        ld      hl,PAD_CODE
        add     hl,de
        ld      a,b
        and     0x10
        or      (hl)
        ret

; A = pressed bits, HL = four masks (up, down, left, right) -> C bits 0..3.
jm_map:
        ld      b,4
        ld      d,1
        ld      e,a
jmm_dir:
        ld      a,e
        and     (hl)
        jp      z,jmm_next
        ld      a,c
        or      d
        ld      c,a
jmm_next:
        inc     hl
        ld      a,d
        add     a,a
        ld      d,a
        dec     b
        jp      nz,jmm_dir
        ret

JOY_DIRS:
        db      0x04, 0x08, 0x02, 0x01  ; port 6: up b2, down b3, left b1, right b0
CURSOR_DIRS:
        db      0x20, 0x80, 0x10, 0x40  ; Vector row 0: ↑ b5, ↓ b7, ← b4, → b6
PAD_CODE:                               ; up/down and left/right pairs, as AF05
        db      0x00, 0x01, 0x03, 0x00, 0x04, 0x05, 0x07, 0x04, 0x0C, 0x0D, 0x0F, 0x0C, 0x00, 0x01, 0x03, 0x00
JOY_P_END:
