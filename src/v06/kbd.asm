; ============================================================================
;  KEYBOARD: Vector-06C matrix -> MSX BIOS stubs (simplified for Basket)
;  
;  MSX Input BIOS calls used by Basket:
;    GTSTCK (00D5h) - Get joystick direction
;    GTTRIG (00D8h) - Get trigger button status
;    SNSMAT (0141h) - Sense keyboard matrix (if used)
;
;  Vector-06C keyboard via PPI (port 0x00-0x03):
;    Port 0x00 = control word
;    Port 0x01 = Port C (modifiers in high nibble)
;    Port 0x02 = Port B (8 bits of selected row)
;    Port 0x03 = Port A (row select) / also scroll register!
;
;  Joystick «П» (second 8255, port 6): src/v06/joy_p.asm, merged into the
;  MSX shadow as the current player 1 keys. Port 0Eh is never read.
; ============================================================================

; Shadow MSX keyboard matrix (9 rows, row 0..8)
V_MSXROW        equ     0x0F20          ; 16 bytes, align 16 for fast lookup

; PPI state save
V_SCROLL        equ     0x0F30          ; scroll register value
V_PPI_C         equ     0x0F31          ; PPI port C value
V_BORDER        equ     0x0F32          ; border/mode value

; Game key cells (written by the game ISR from SNSMAT)

; ============================================================================
;  V_KBD_INIT - Initialize keyboard shadow
; ============================================================================
V_KBD_INIT:
        push    hl
        push    bc
        
        ; Fill shadow with 0xFF (all released)
        ld      hl,V_MSXROW
        ld      b,16
vki_loop:
        ld      (hl),0xFF
        inc     hl
        dec    b
        jp    nz,vki_loop

        ld      a,1
        ld      (V_KFORCE),a            ; first poll builds the MSX rows

        ; Game waits on (A10F)==0xFF (no key) before title blit
        ld      a,0xFF
        ld      (G_KEY_CODE),a
        ld      (G_KEY_ASCII),a
        
        pop     bc
        pop     hl
        ret

; ============================================================================
;  V_KBD_POLL - Scan keyboard once per frame (call in vblank)
;
;  Vector matrix (row = port 03 select, port 02 active-low bits 0..7):
;    0: TAB ПС ВК ЗБ ← ↑ → ↓      1: F7 F8 АР2 F1 F2 F3 F4 F5
;    2: 0..7                       3: 8 9 ' ; , = . /
;    4: @ A..G   5: H..O   6: P..W   7: X Y Z [ \ ] ` SPACE
;  MSX matrix: 0: 0..7  1: 8 9 ..  2: .. A B  3: C..J  4: K..R  5: S..Z
;    6: SHIFT CTRL .. F1 F2 F3  7: F4 F5 ESC TAB STOP BS SEL RET
;    8: SPACE HOME INS DEL ← ↑ ↓ →
;  Letters are contiguous on both: MSX pos = Vector pos - 11.
;  MUST be called in blanking interval (port 03 is also the scroll register).
; ============================================================================
V_VROW          equ     0x0F38          ; 8 raw Vector rows
; Last inputs the MSX rows were built from: rebuild only when one changes.
V_KPORTC        equ     0x0F33          ; port C modifiers (bits 5, 6)
V_KJOY          equ     0x0F34          ; joystick «П» port 6 (0 outside a match)
V_KMODE         equ     0x0F35          ; MATCH_MODE
V_KFORCE        equ     0x0F36          ; 1 = rebuild on the next poll
V_KONE          equ     0x0F37          ; ONE_PLAYER
K_MATCH_MODE    equ     0x0FED
K_JOY_READY     equ     0x0F62

V_KBD_POLL:
        push    af
        push    bc
        push    de
        push    hl

        ld      a,0x8A                  ; A out, B in, C high in
        out     (0x00),a
        ld      hl,V_VROW
        ld      a,(V_KFORCE)
        ld      c,a                     ; C <> 0: inputs changed
        ld      a,0xFE
vkp_scan:
        out     (0x03),a
        ld      b,a
        in      a,(0x02)
        cp      (hl)
        jp      z,vkp_same
        ld      (hl),a
        ld      c,h
vkp_same:
        inc     hl
        ld      a,b
        rlca
        jp      c,vkp_scan
        in      a,(0x01)
        and     0x60                    ; СС, УС
        ld      hl,V_KPORTC
        call    vkp_sig
        ld      a,(K_MATCH_MODE)
        ld      b,a
        inc     hl
        inc     hl                      ; V_KMODE
        call    vkp_sig
        xor     a                       ; no joystick outside a match
        dec     b
        jp      nz,vkp_joy
        ld      a,(K_JOY_READY)
        or      a
        jp      z,vkp_joy               ; JOY_MERGE programs the port first
        in      a,(0x06)
vkp_joy:
        dec     hl                      ; V_KJOY
        call    vkp_sig
        ld      a,(ONE_PLAYER)
        ld      hl,V_KONE
        call    vkp_sig
        ld      a,c
        or      a
        jp      z,vkp_restore           ; same inputs: the MSX rows stand
        xor     a
        ld      (V_KFORCE),a

        ld      a,(V_VROW+2)            ; digits 0..7
        ld      (V_MSXROW+0),a
        ld      a,(V_VROW+3)            ; 8 9
        or      0xFC
        ld      (V_MSXROW+1),a

        ; Letters: rrca×3 of a Vector row = its bits 0..2 at 5..7 and bits
        ; 3..7 at 0..4; 1-bits (released) fill the unused half.
        ld      hl,V_VROW+4
        ld      a,(hl)
        rrca
        rrca
        rrca
        ld      c,a
        or      0x3F                    ; A B at bits 6,7
        ld      (V_MSXROW+2),a
        ld      de,V_MSXROW+3
        ld      b,3
vkp_letters:
        ld      a,c
        or      0xE0
        ld      c,a                     ; low part from this row
        inc     hl
        ld      a,(hl)
        rrca
        rrca
        rrca
        push    af
        or      0x1F
        and     c
        ld      (de),a
        inc     de
        pop     af
        ld      c,a
        dec    b
        jp    nz,vkp_letters

        ; Vector modifiers live on PPI port C (active low), outside the
        ; eight matrix rows.  Basket checks SHIFT+CTRL+ESC to leave a match.
        in      a,(0x01)
        ld      d,a
        ld      a,(V_VROW+1)            ; F1 F2 F3 → MSX row 6 bits 5..7
        rlca
        rlca
        or      0x1F
        ld      c,a
        ld      a,d
        ld      hl,KM_ROW6
        ld      b,2
        call    km_map                  ; СС → SHIFT, УС → CTRL
        ld      a,c
        ld      (V_MSXROW+6),a

        ld      c,0xFF                  ; MSX row 7
        ld      a,(V_VROW+1)
        ld      hl,KM_ROW7A
        ld      b,3
        call    km_map                  ; F4, F5, АР2 → ESC
        ld      a,(V_VROW+0)
        ld      b,3
        call    km_map                  ; TAB, ЗБ → BS, ВК → RETURN (KM_ROW7B)
        ld      a,c
        ld      (V_MSXROW+7),a

        ld      a,(V_VROW+0)            ; MSX row 8: ← ↑ same bits, ↓ → swapped
        ld      b,a
        and     0x30
        or      0x0F
        ld      c,a
        ld      a,b
        and     0x80
        rrca
        or      c
        ld      c,a
        ld      a,b
        and     0x40
        rlca
        or      c
        ld      c,a
        ld      a,(V_VROW+7)            ; SPACE bit 7 → bit 0
        or      0x7F
        rlca
        and     c
        ld      (V_MSXROW+8),a
        call    JOY_MERGE                  ; JOY_MERGE: joystick «П», cursor keys (joy_p.asm)

        ; --- Restore PPI state ---
vkp_restore:
        ld      a,0x88
        out     (0x00),a
        ld      a,(V_PPI_C)
        out     (0x01),a
        ld      a,(V_SCROLL)
        out     (0x03),a
        ld      a,(V_BORDER)
        out     (0x02),a

        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

; A = input, HL = its last value: store it; C = H when it changed.
vkp_sig:
        cp      (hl)
        ret     z
        ld      (hl),a
        ld      c,h
        ret

; ============================================================================
;  BIOS_GTSTCK - Get joystick direction (MSX BIOS 00D5h replacement)
;  A = 0 (cursor keys) and A = 1 (joystick 1): Vector cursor keys.
;  A = 2 (joystick 2): none. Exit: A = 0 none, 1 up, 2 up-right ... 8 up-left
; ============================================================================
BIOS_GTSTCK:
        cp      2
        jp      c,gs_kbd
        xor     a
        ret
gs_kbd:
        push    hl
        ld      a,(V_MSXROW+8)
        cpl
        rrca
        rrca
        rrca
        rrca
        and     0x0F                    ; b0 ← b1 ↑ b2 ↓ b3 →
        ld      hl,GS_TAB
        add     a,l
        ld      l,a
        jp      nc,gs_nc
        inc     h
gs_nc:
        ld      a,(hl)
        pop     hl
        ret
GS_TAB:
        db      0,7,1,8,5,6,0,7,3,0,2,1,4,5,3,0

; ============================================================================
;  BIOS_GTTRIG - Get trigger button status (MSX BIOS 00D8h replacement)
; ============================================================================
BIOS_GTTRIG:
;  Entry: A = trigger number (0=space, 1=joy1 A, 2=joy2 A, 3=joy1 B, 4=joy2 B)
;  Exit: A = 0xFF if pressed, 0 if not. Space serves triggers 0 and 1.
        cp      2
        jp      c,gt_space
        xor     a
        ret
gt_space:
        push    hl
        
        ; Check MSX row 8 bit 0 (space)
        ld      a,(V_MSXROW+8)
        and     0x01
        jp      nz,gt_notpressed        ; bit=1 means released (active low shadow)
        ld      a,0xFF
        pop     hl
        ret
gt_notpressed:
        xor     a
        pop     hl
        ret

; ============================================================================
;  NATIVE_KEYSNAP - the game ISR key snapshot (MSX D56A, port 37D2; JP from
;  build_v06_rom.py). Same result as the MSX loop over SNSMAT rows 0..8 and
;  the two GTSTCK/GTTRIG reads: KEY_SNAP+0..8 = MSX rows, +9 = KEY_DIR_TAB
;  [GTSTCK(1)] with bit 0 cleared while trigger 1 (SPACE) is down, +10 = the
;  same for trigger 2 (none on the Vector), KEY_TRIG_NO = 2. Keeps BC, DE.
; ============================================================================
NATIVE_KEYSNAP:
        push    bc
        push    de
        ld      hl,V_MSXROW
        ld      de,KEY_SNAP
        ld      b,9
nks_row:
        ld      a,(hl)
        ld      (de),a
        inc     hl
        inc     de
        dec     b
        jp      nz,nks_row
        ld      a,1
        call    BIOS_GTSTCK             ; A = direction 0..8
        ld      l,a
        ld      h,0
        ld      bc,KEY_DIR_TAB
        add     hl,bc
        ld      a,(hl)
        ld      (de),a                  ; +10: trigger 2 never down
        inc     de
        ld      (de),a
        ld      a,(V_MSXROW+8)          ; trigger 1: SPACE (BIOS_GTTRIG)
        rrca
        jp      c,nks_trig
nks_fire:                               ; trigger 1 down (xref 1p_throw)
        dec     de
        ld      a,(de)
        and     0xFE
        ld      (de),a
nks_trig:
        ld      a,2
        ld      (KEY_TRIG_NO),a
        pop     de
        pop     bc
        ret

; ============================================================================
;  BIOS_SNSMAT - Sense keyboard matrix row (MSX BIOS 0141h replacement)
; ============================================================================
BIOS_SNSMAT:
;  Entry: A = row number (0-10)
;  Exit: A = row data (active low)
        push    hl
        and     0x0F
        add     a,V_MSXROW & 0xFF
        ld      l,a
        ld      h,V_MSXROW >> 8
        ld      a,(hl)
        pop     hl
        ret

; A = Vector bits (0 = pressed), HL = B pairs (source mask, MSX keep mask):
; a pressed source clears its MSX bit in C. HL ends after the pairs.
km_map:
        ld      e,a
km_pair:
        ld      a,e
        and     (hl)
        inc     hl
        jp      nz,km_next
        ld      a,c
        and     (hl)
        ld      c,a
km_next:
        inc     hl
        dec     b
        jp      nz,km_pair
        ret
KM_ROW6:
        db      0x20, 0xFE, 0x40, 0xFD  ; port C: СС → SHIFT (b0), УС → CTRL (b1)
KM_ROW7A:
        db      0x40, 0xFE, 0x80, 0xFD, 0x04, 0xFB      ; F4 b0, F5 b1, АР2 → ESC b2
KM_ROW7B:
        db      0x01, 0xF7, 0x08, 0xDF, 0x04, 0x7F      ; TAB b3, ЗБ → BS b5, ВК → RETURN b7
