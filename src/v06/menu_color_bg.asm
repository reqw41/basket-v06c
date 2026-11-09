; Menu chrome helpers, replay helpers and AY noise, in the retained zero
; gap after MENU_LZ_BODY (137B..15FF).
        include "labels_menu_color_bg.inc"
        org     0x137B

;  CPC footer and the controls — not in the LZ chrome (the slot is full).
; Records: column, plane Y (0xDF - y), high-plane mask, text, 0; column 0
; ends the list. Mask 00: white on paper, FF: pink on paper.
MENU_DRAW_COPYRIGHT:
        ld      hl,mdc_str
mdc_rec:
        ld      a,(hl)
        or      a
        ret     z
        ld      c,a                     ; column
        inc     hl
        ld      a,(hl)
        ld      (mdc_y+1),a
        inc     hl
        ld      a,(hl)
        ld      (mdc_m+1),a
        inc     hl
mdc_ch:
        ld      a,(hl)
        inc     hl
        or      a
        jp      z,mdc_rec
        push    hl
        push    bc
        ld      l,a
        ld      h,0
        add     hl,hl
        add     hl,hl
        add     hl,hl
        ld      de,GAME_FONT
        add     hl,de
        ld      a,c
        add     a,0xE0
        ld      d,a
mdc_y:
        ld      e,0                     ; patched: plane Y of the record
        ld      b,8
mdc_row:
        ld      a,(hl)
        ld      (de),a                  ; low = glyph
        cpl
mdc_m:
        or      0                       ; patched: FF makes the glyph pink
        ld      c,a
        ld      a,d
        sub     0x20
        ld      d,a
        ld      a,c
        ld      (de),a                  ; high = paper (and pink)
        ld      a,d
        add     a,0x20
        ld      d,a
        inc     hl
        dec     e
        dec     b
        jp      nz,mdc_row
        pop     bc
        pop     hl
        inc     c
        jp      mdc_ch
mdc_str:
        db      3, 0xDF - 150, 0xFF, "1 PLAYER:", 0
        db      13, 0xDF - 150, 0, "KEYS OR JOYSTICK", 0
        db      1, 0xDF - 161, 0xFF, "2 PLAYERS:", 0
        db      12, 0xDF - 161, 0, "KEYS+JOY B VS JOY A", 0
        db      4, 0xDF - 172, 0xFF, "KEYS:", 0
        db      10, 0xDF - 172, 0, "ARROWS, FIRE SPACE", 0
        db      1, 0xDF - 184, 0, "COPYRIGHT DINAMIC SOFTWARE 1987", 0
        db      0

; Replay helpers (replay.asm has no room before COLOR_FRAME_BEGIN).
; A887/A89E: a recorded state starts like a frame (every object is staged).
REPLAY_STATE_BEGIN:
        jp      FRAME_BEGIN                  ; FRAME_BEGIN
; A88A/A8A1: stage the state only. Nothing is published: REPLAY_ZOOM
; composes the window off screen from the staged stream (replay.asm).
REPLAY_SCENE:
        jp      GAME_STATE_QUEUE
; REPLAY_COMPOSE row fill: TILE_FAST_FILL (8495) without borrowing SP, so
; IRQs stay on (a vblank under DI is lost). HL = tile pointer table from
; COURT_TILE_ROW_POINTER, A = displacement, DE = destination; 8 pairs.
REPLAY_TILE_ROW:
        ld      c,a
        ld      b,8
rtr_lp:
        ld      a,(hl)
        inc     hl
        push    hl
        ld      h,(hl)
        add     a,c                     ; tile banks are 16-aligned
        ld      l,a
        ld      a,(hl)
        ld      (de),a
        inc     de
        inc     hl
        ld      a,(hl)
        ld      (de),a
        inc     de
        pop     hl
        inc     hl
        dec    b
        jp    nz,rtr_lp
        ret
; Replaces `ei / halt / di` before the vblank publish (BUFFER_PLAYERS B182,
; COLOR_FRAME_END). With AY noise on a loud channel the wait plays speaker
; noise instead of halting. Preserves BC, DE, HL; returns with DI.
NOISE_WAIT:
        ei
        ld      a,(V_NOISE)
        or      a
        jp      z,nw_halt
        push    bc
        push    hl
        ld      a,(V_RND)
        or      1
        ld      b,a
        jp      NOISE_SPEAKER
nw_halt:
        halt
        di
        ret
REPLAY_HELPERS_END:

; AY noise (ball bounce: B tone + noise period 31). The ВИ53 keeps the tone;
; SND_NOISE_SCAN (each IRQ) flags noise on a loud channel and
; NOISE_WAIT turns the vblank wait into speaker noise.
V_NOISE         equ     0x0F7C          ; former DBG_CALLER (unused)
V_RND           equ     0x0F7E          ; former DBG_DE_ENTER: speaker LFSR
SND_NOISE_SCAN:
        ld      a,(V_MUTE)              ; УС: no speaker noise either
        or      a
        jp      z,sns_on
        xor     a
        ld      (V_NOISE),a
        ret
sns_on:
        ld      a,(0x0F47)              ; AY mixer R7
        rrca
        rrca
        rrca
        ld      b,a                     ; bits 0..2: 0 = noise on A/B/C
        ld      hl,0x0F48               ; volumes R8..R10
        ld      de,0x0300               ; D = channels, E = result
sns_lp:
        ld      a,b
        rra
        ld      b,a
        jp      c,sns_next
        ld      a,(hl)
        cp      6                       ; level >= 6 or envelope (0x10+)
        jp      c,sns_next
        ld      e,1
sns_next:
        inc     hl
        dec     d
        jp      nz,sns_lp
        ld      a,e
        ld      (V_NOISE),a
        ret
; Speaker noise (bit 0 of PPI port C, set by BSR on port 00). NOISE_WAIT
; enters here when V_NOISE is set; it replaces the vblank HALT of the
; sprite publishers, so the noise costs no frame time. An 8-bit Galois LFSR
; steps at ~3.6 kHz (AY noise period 31 at 1.79 MHz) until the next IRQ.
; IN: B = LFSR seed (non-zero); BC, HL pushed by NOISE_WAIT.
NOISE_SPEAKER:
        ld      hl,0x0F60               ; IRQ_FRAME_COUNT
        ld      c,(hl)
ns_lp:
        ld      a,b
        or      a
        rra
        jp      nc,ns_nc
        xor     0xB8                    ; x^8+x^6+x^5+x^4+1
ns_nc:
        ld      b,a
        and     1
        out     (0),a                   ; BSR: PC0 = speaker bit
        ld      a,46
ns_dl:
        dec     a
        jp      nz,ns_dl
        ld      a,c
        cp      (hl)
        jp      z,ns_lp
        ld      a,b
        ld      (V_RND),a
        xor     a
        out     (0),a                   ; speaker low
        pop     hl
        pop     bc
        di
        ret
SND_NOISE_END:

; Replay zoom: 4 source bits → 8 doubled bits (replay.asm REPLAY_X2).
        ds      (0x10 - ($ & 0x0F)) & 0x0F, 0   ; REPLAY_X2 must be 16-aligned
REPLAY_X2_TABLE:
        db      0x00,0x03,0x0C,0x0F,0x30,0x33,0x3C,0x3F
        db      0xC0,0xC3,0xCC,0xCF,0xF0,0xF3,0xFC,0xFF

; MENU_BG_RELOAD tail: the chrome is on both planes; menu publishes put
; the players on the blue panel (damage_publish.asm, TITLE_SNAPPED).
MENU_CHROME_DONE:
        ld      a,1
        ld      (0x0FEF),a              ; TITLE_SNAPPED
        jp      MENU_DRAW_COPYRIGHT

MENU_COLOR_BG_END:
