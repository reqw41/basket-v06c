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
        ; the control lines (y150/161/172) were dropped 10.11 (owner)
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
        jp      NOISE_SPEAKER
nw_halt:
        halt
        di
        ret
REPLAY_HELPERS_END:

; AY noise as in brucelee-v06c (10.11): random bits on the ВИ53 counter of
; the noisy voice (its tone is silent meanwhile), so the noise plays in the
; same path and loudness as the tones. Bits come in a ~3 ms burst at every
; frame IRQ (V_SND_TICK -> SND_NOISE_BURST) and all through the vblank waits
; (NOISE_WAIT). SND_NOISE_SCAN (each IRQ) picks the first loud channel with
; noise on (level >= SND_NZTHR or envelope) and the bit time from AY R6.
SND_THR         equ     4               ; AY level from which a tone sounds (brucelee-v06c THR)
SND_NZTHR       equ     6               ; noise: level 5 holds for seconds in a match (a hiss the AY barely plays)
V_NOISE         equ     0x0F7C          ; 0 = quiet, else the noisy channel + 1
V_NZDLY         equ     0x0F7D          ; bit delay loop count
V_RND           equ     0x0F7E          ; word: Galois LFSR (16 bits)
SND_NOISE_SCAN:
        ld      a,(V_MUTE)              ; УС: no noise either
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
        ld      de,0x0301               ; D = channels, E = channel + 1
sns_lp:
        ld      a,b
        rra
        ld      b,a
        jp      c,sns_next
        ld      a,(hl)
        cp      SND_NZTHR               ; level >= SND_NZTHR or envelope (0x10+)
        jp      nc,sns_hit
sns_next:
        inc     hl
        inc     e
        dec     d
        jp      nz,sns_lp
        xor     a
        ld      (V_NOISE),a
        ret
sns_hit:
        ld      a,e
        ld      (V_NOISE),a
        dec     a
        rrca
        rrca                            ; counter select = channel << 6
        ld      (nz_sel+1),a
        ld      a,0x0C                  ; counter port: 0B - channel (ports swapped)
        sub     e
        ld      (nz_port+1),a
        ld      (nzt_p0+1),a
        ld      (nzt_p1+1),a
        ; bit time: AY 1.79 MHz noise N -> a bit each 26.8 N Vector cycles;
        ; nz_bit costs ~150 + 20 per delay step. Bits go ~3x as fast as
        ; the AY's (a tighter, denser hiss, 10.11 owner's ear; the burst
        ; stays ~3 ms): delay = 0.44 N - 7, >= 1
        ld      a,(0x0F46)              ; R6
        and     0x1F
        or      a
        rra
        or      a
        rra
        ld      c,a                     ; N/4
        or      a
        rra
        ld      b,a                     ; N/8
        or      a
        rra                             ; N/16
        add     a,b
        add     a,c
        sub     8
        jp      nc,sns_dly
        xor     a
sns_dly:
        inc     a
        ld      (V_NZDLY),a
        ; burst bits: ~8000 cycles (2.7 ms) / (200 + 20 delay) = 400 / (delay + 10) (measured ~280 at delay 4)
        add     a,10
        ld      e,a
        ld      d,0
        ld      hl,400                  ; ~8000 cycles: the old burst plus the tone code
        ld      c,0
sns_div:
        ld      a,l
        sub     e
        ld      l,a
        ld      a,h
        sbc     a,d
        ld      h,a
        jp      c,sns_cnt
        inc     c
        jp      sns_div
sns_cnt:
        ld      a,c
        or      a
        jp      nz,sns_c1
        inc     a
sns_c1:
        ld      (nzb_cnt+1),a
        ret

; IRQ (end of V_SND_TICK): a burst of noise bits while a voice is noisy.
SND_NOISE_BURST:
        ld      a,(V_NOISE)
        or      a
        ret     z
        call    nz_seed
nzb_cnt:
        ld      c,1                     ; patched: bits in the burst
nzb_lp:
        call    nz_bit
        dec     c
        jp      nz,nzb_lp
        ld      (V_RND),hl
        ; AY ANDs tone and noise on one voice (the ball: tone ~150 Hz plus
        ; noise on B). Till the next IRQ the counter plays the voice's tone
        ; (mode 3, divisor from the mirror) if its tone is on, so the bursts
        ; alternate with the tone instead of silence. snd_off stops it when
        ; the noise ends (counter marked running, no divisor cached).
        ld      a,(V_NOISE)
        ld      e,a                     ; E = channel + 1
        ld      b,a
        ld      a,(0x0F47)              ; R7: bit channel = 0 -> tone on
nzt_mix:
        rrca
        dec     b
        jp      nz,nzt_mix
        ret     c
        ld      d,0
        ld      hl,0x0F40-2             ; V_AYREG: tone R(2c), R(2c+1)
        add     hl,de
        add     hl,de
        ld      c,(hl)
        inc     hl
        ld      b,(hl)                  ; BC = ВИ53 divisor (baked)
        ld      a,b
        or      a
        jp      nz,nzt_ok
        ld      a,c
        cp      64
        ret     c
nzt_ok:
        ld      a,(nz_sel+1)
        or      0x36                    ; LSB+MSB, mode 3
        out     (0x08),a
        ld      a,c
nzt_p0:
        out     (0x0A),a                ; patched: the counter's port
        ld      a,b
nzt_p1:
        out     (0x0A),a
        ld      hl,0x0F50-1             ; V_SND_ON (snd.asm)
        add     hl,de
        ld      (hl),1
        ld      hl,0x0F53-2             ; V_SND_DIV (snd.asm)
        add     hl,de
        add     hl,de
        ld      (hl),0xFF
        inc     hl
        ld      (hl),0xFF
        ret

; HL = the LFSR, never 0.
nz_seed:
        ld      hl,(V_RND)
        ld      a,h
        or      l
        ret     nz
        inc     hl
        ret

; One noise bit (Galois 16 in HL) on the noisy counter, then the bit delay.
; Mode 0 with the LSB only and count 1 raises the output a clock later; mode
; 0 with no count loaded drops it (brucelee-v06c nz_bit). Clobbers A.
nz_bit:
        ld      a,h
        or      a
        rra
        ld      h,a
        ld      a,l
        rra
        ld      l,a
nz_sel:
        ld      a,0                     ; patched: counter select bits
        jp      nc,nz_low
        or      0x10                    ; mode 0, LSB only
        out     (0x08),a
        ld      a,1
nz_port:
        out     (0x0A),a                ; patched: the counter's port
        ld      a,h
        xor     0xB4
        ld      h,a
        jp      nz_dly
nz_low:
        or      0x30                    ; mode 0, no count: output low
        out     (0x08),a
nz_dly:
        ld      a,(V_NZDLY)
nz_dl:
        dec     a
        jp      nz,nz_dl
        ret

; NOISE_WAIT with a noisy voice: noise bits until the next frame IRQ.
; IN: BC, HL pushed by NOISE_WAIT. Returns with DI.
NOISE_SPEAKER:
        ld      a,(0x0F60)              ; IRQ_FRAME_COUNT
        ld      c,a
        call    nz_seed
ns_lp:
        call    nz_bit
        ld      a,(0x0F60)
        cp      c
        jp      z,ns_lp
        ld      (V_RND),hl
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
