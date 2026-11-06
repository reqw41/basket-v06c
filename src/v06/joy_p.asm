; Fixed controls (06.11): player 1 = joystick «П», player 2 = Vector cursor
; keys. With one player the cursor keys and SPACE steer player 1 as well.
;
; The game's own reader (AF05) called D5DE once per control on the MSX
; snapshot: five redefinable player 1 codes (default 1 Q D F Z) and the MSX
; cursor keys + RETURN for player 2. AF0B now jumps to NATIVE_PADS, which
; builds the same two bytes from the Vector inputs directly:
;   PAD_P1 (AC4D) / PAD_P2 (AC4E): b0 up, b0|b1 down, b2 left, b2|b3 right,
;   b4 fire; opposite directions cancel (as AF05 did).
; Player 2 (two players only) fires with ВК or SPACE; with one player its
; byte stays 0 for the AI, as on the MSX. Letters
; and digits no longer steer anyone; menu item 5 (SELECT CONTROL) is gone.

V_MSXROW        equ     0x0F20
V_VROW          equ     0x0F38          ; raw Vector rows (frame IRQ poll)
V_KJOY          equ     0x0F34          ; port 6 as polled (0 outside a match)
JOY_IDLE        equ     0x0F61          ; port 6 value at rest
JOY_READY       equ     0x0F62          ; 1 = second 8255 programmed
MATCH_MODE      equ     0x0FED          ; 1 = live match

; Called at the end of V_KBD_POLL when an input changed: programs the
; second 8255 once per match so the poll can read port 6.
JOY_MERGE:
        ld      a,(MATCH_MODE)
        dec     a
        ret     nz
        ld      a,(JOY_READY)
        or      a
        ret     nz
        ld      a,0x83                  ; as ironclad/tankwars: both devices
        out     (0x04),a
        ld      a,0x9F
        out     (0x05),a
        in      a,(0x06)
        ld      (JOY_IDLE),a
        ld      a,1
        ld      (JOY_READY),a
        ret

NATIVE_PADS:
        ld      c,0                     ; b0 up b1 down b2 left b3 right b4 fire
        ld      a,(MATCH_MODE)
        dec     a
        jp      nz,np_keys
        ld      a,(JOY_READY)
        or      a
        jp      z,np_keys
        ld      a,(V_KJOY)
        ld      hl,JOY_IDLE
        xor     (hl)                    ; 1 = away from rest
        cp      0x40                    ; b6 or b7: fire 1 / fire 2
        jp      c,np_jdirs
        ld      c,0x10
np_jdirs:
        ld      hl,JOY_DIRS
        call    jm_map
np_keys:
        ld      a,(V_VROW)              ; row 0: b2 ВК, b4 ← b5 ↑ b6 → b7 ↓
        cpl                             ; 1 = down
        push    af
        ld      a,(ONE_PLAYER)
        or      a
        jp      z,np_p1
        ld      a,(V_VROW+7)            ; SPACE, bit 7, 0 = down
        rlca
        jp      c,np_p1cur
        ld      a,c
        or      0x10
        ld      c,a
np_p1cur:
        pop     af
        push    af
        ld      hl,CURSOR_DIRS
        call    jm_map
np_p1:
        ld      a,c
        call    np_code
        ld      (PAD_P1),a
        pop     af
        ld      c,0
        ld      b,a
        ld      a,(ONE_PLAYER)          ; one player: player 2 is the AI,
        or      a                       ; its keys stay up (as on the MSX
        jp      nz,np_p2                ; with only 1 Q D F Z pressed)
        ld      a,b
        and     0x04                    ; ВК
        jp      nz,np_p2fire
        ld      a,(V_VROW+7)            ; SPACE fires too
        rlca
        jp      c,np_p2dirs
np_p2fire:
        ld      c,0x10
np_p2dirs:
        ld      a,b
        ld      hl,CURSOR_DIRS
        call    jm_map
np_p2:
        ld      a,c
        call    np_code
        ld      (PAD_P2),a
        ret

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
