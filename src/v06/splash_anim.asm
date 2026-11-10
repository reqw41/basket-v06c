; CPC title animation: the player spins the ball until Space.
;
; Lives in the replay ring and the shared graphics buffer (1B40..24FF), which
; are zero in the image and idle before the game starts. ADAPTER_INIT calls
; SPLASH_ANIM with interrupts on and clears 1B40..24FF afterwards, so the
; game finds the same memory as without the animation.
;
; The splash planes (C000/E000 in the image) hold step 0. Each step rewrites
; the pieces of the picture that move (tools/make_splash_anim.py): a piece
; is a list of byte runs on screen and, per step, the state to copy into them.
; i8080 code.
        include "labels_splash_anim.inc"
        org     0x1B40

SA_END          equ     0x2500          ; ADAPTER_INIT clears SPLASH_ANIM..SA_END-1
SA_STEPS        equ     24
SA_FRAMES       equ     5               ; 100 ms per step, as on the CPC

SPLASH_ANIM:
        ld      hl,PAL_TAB              ; keep the game palette, show the CPC one
        ld      de,sa_game_pal
        call    sa_copy16
        ld      hl,sa_pal
        ld      de,PAL_TAB
        call    sa_copy16
        ld      hl,SONG_MENU            ; the menu tune starts here; the boot
        ld      (BLIT_Y),hl             ; path no longer restarts it (8502),
        xor     a                       ; so it plays on into the menu
        ld      (MUSIC_LOOP),a
        call    MUSIC_START             ; ends with EI
sa_step:
        ld      hl,SA_PIECES
sa_piece:
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                  ; DE = runs of the piece
        inc     hl
        ld      a,d
        or      e
        jp      z,sa_wait
        ld      c,(hl)
        inc     hl
        ld      b,(hl)                  ; BC = its state per step
        inc     hl
        push    hl
        ld      a,(sa_index)            ; step * 2
        ld      l,a
        ld      h,0
        add     hl,bc
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a                     ; HL = state bytes
sa_run:
        ld      a,(de)                  ; run length, 0 ends the piece
        or      a
        jp      z,sa_piece_done
        ld      (sa_count),a
        inc     de
        ld      a,(de)
        ld      c,a
        inc     de
        ld      a,(de)
        ld      b,a                     ; BC = screen address
        inc     de
sa_byte:
        ld      a,(hl)
        ld      (bc),a
        inc     hl
        inc     bc
        ld      a,(sa_count)
        dec     a
        ld      (sa_count),a
        jp      nz,sa_byte
        jp      sa_run
sa_piece_done:
        pop     hl
        jp      sa_piece

sa_wait:
        ld      b,SA_FRAMES
sa_frame:
        halt
        call    sa_music
        ld      a,(0x0F21)              ; V_KANY: any key down (as brucelee-v06c)
        or      a
        jp      nz,sa_exit
        ld      a,(0x0F34)              ; V_KJOY: joysticks «П», 0 = pressed
        cpl
        ld      c,a
        and     0x30
        jp      nz,sa_nojoy             ; no joystick on the port
        ld      a,c
        and     0xC0                    ; fire
        jp      nz,sa_exit
sa_nojoy:
        dec     b
        jp      nz,sa_frame
        ld      a,(sa_index)
        add     a,2
        cp      SA_STEPS*2
        jp      nz,sa_next
        xor     a
sa_next:
        ld      (sa_index),a
        jp      sa_step

; The game ISR is not installed yet: one music step per frame as it does
; (CALL through MUSIC_SLOT, AB28 once MUSIC_START ran), interrupts off.
sa_music:
        push    bc
        di
        ld      hl,sa_music_done
        push    hl
        ld      hl,MUSIC_SLOT       ; CALL nn: the tick is its operand
        inc     hl                      ; (the label moves in the i8080 image,
        ld      a,(hl)                  ; label+1 is not remapped)
        inc     hl
        ld      h,(hl)
        ld      l,a
        jp      (hl)
sa_music_done:
        ei
        pop     bc
        ret

sa_exit:
        ld      hl,sa_game_pal
        ld      de,PAL_TAB
sa_copy16:
        ld      b,16
sa_c:
        ld      a,(hl)
        ld      (de),a
        inc     hl
        inc     de
        dec     b
        jp      nz,sa_c
        ret

; Colour index = E000 bit | C000 bit << 1; the border is entry 0.
; Byte = BB GGG RRR: the game palette (PAL_TAB) since 10.11 (owner): blue
; border, white, black background, the game's skin pen for the ball,
; outlines and skin (was orange 27).
sa_pal:
        db      0xC0,0xFF,0x00,0x5F,0xC0,0xFF,0x00,0x5F
        db      0xC0,0xFF,0x00,0x5F,0xC0,0xFF,0x00,0x5F
sa_game_pal:
        ds      16
sa_index:
        db      0
sa_count:
        db      0

        include "splash_anim_data.inc"

#assert $ <= SA_END                     ; ADAPTER_INIT clears only up to 24FF
