; ============================================================================
;  SOUND: MSX PSG (AY-3-8910) -> Vector-06C КР580ВИ53 timer
;
;  The game drives the PSG only through BIOS WRTPSG (one call site, AC00) from
;  a per-frame sound driver: tone periods R0..R5, volumes R8..R10, mixer R7
;  (A8/B8), noise period R6. Envelope registers R11..R13 are never written.
;  WRTPSG only updates a mirror; V_SND_TICK (frame IRQ) loads the 16-bit
;  tone value as a ВИ53 divisor. Periods are baked at build
;  (tools/pack_v06_snd.py): D = 13P + P/4 + P/8, no runtime scale.
;
;  Rules (King's Valley / spirits-v06c):
;   * a control word restarts the counter — send it only when a channel
;     switches on or off, not for every note;
;   * silence = control word without a divisor (the counter stops);
;   * on stop, reset the cached divisor so the same note after a pause is
;     reloaded.
;  Lost against AY: volume (threshold 4/15; 0x10 "envelope" counts as on),
;  divisors < 64. Noise (10.11, as brucelee-v06c): random bits on the
;  counter of the noisy voice (menu_color_bg.asm SND_NOISE_SCAN/BURST).
;
;  Vector ВИ53 ports are swapped against the 8253 datasheet:
;    control word = 0x08, counter 0/1/2 = 0x0B/0x0A/0x09
; ============================================================================

V_AYREG         equ     0x0F40          ; 16 bytes, R0..R15 mirror
V_AYREG_VOL     equ     0x48            ; low byte of V_AYREG+8
V_SND_ON        equ     0x0F50          ; 3 bytes: counter running
V_SND_DIV       equ     0x0F53          ; 3 words: divisor last loaded
SND_THR         equ     4               ; AY level from which a voice sounds (menu_color_bg.asm too)

; ============================================================================
;  BIOS_GICINI - Initialize PSG (MSX BIOS 0090h replacement)
; ============================================================================
BIOS_GICINI:
        push    af
        push    bc
        push    hl
        ld      hl,V_AYREG
        ld      b,16
gi_clr:
        ld      (hl),0
        inc     hl
        dec    b
        jp    nz,gi_clr
        ld      a,0xB8                  ; MSX GICINI: tones on, noise off
        ld      (V_AYREG+7),a
        ld      c,0
gi_ch:
        call    snd_off
        inc     c
        ld      a,c
        cp      3
        jp      c,gi_ch
        pop     hl
        pop     bc
        pop     af
        ret

; ============================================================================
;  BIOS_WRTPSG - Write PSG register (MSX BIOS 0093h replacement)
;  A = register, E = value. Preserves all registers.
; ============================================================================
BIOS_WRTPSG:
        push    af
        push    hl
        and     0x0F
        add     a,V_AYREG & 0xFF
        ld      l,a
        ld      h,V_AYREG >> 8
        ld      (hl),e
        pop     hl
        pop     af
        ret

; ============================================================================
;  MUSIC_TICK - the game's music channel step (MSX AB28..AB82 with ABDB and
;  ABE7, CALLed from the patched AB28 in the frame IRQ). Three channels, 8
;  bytes each from MUSIC_CHANNELS (AC09): +0 envelope step, +1 duration, +2/+3 note pointer
;  (0 = channel off), +4/+5 envelope table, +6 tone register, +7 volume
;  register. A note is: duration, fine, coarse; FF ends the pattern. Same
;  PSG writes in the same order as the IY loop. Returns Z when a pattern
;  ended (AB28 then loads the next one through AA8F and skips the remaining
;  channels, as the MSX loop does), NZ otherwise. Clobbers AF, BC, DE, HL.
; ============================================================================
MT_END          equ     MUSIC_CHANNELS + 3 * 8
MUSIC_TICK:
        ld      hl,MUSIC_CHANNELS
mt_ch:
        push    hl                      ; channel base
        inc     hl
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                  ; DE = note pointer
        ld      a,d
        or      e
        jp      z,mt_next
        dec     hl
        dec     hl                      ; +1 duration
        ld      a,(hl)
        or      a
        jp      z,mt_note
        dec     (hl)
        dec     hl
        jp      mt_env
mt_note:
        ld      a,(de)
        dec     a
        ld      (hl),a                  ; duration - 1
        dec     hl
        ld      (hl),0xFF               ; envelope restarts (step 0 below)
        ld      bc,6
        add     hl,bc
        ld      c,(hl)                  ; tone register
        ex      de,hl                   ; HL = note
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      a,c
        call    BIOS_WRTPSG             ; fine period
        ld      e,(hl)
        inc     hl
        inc     a
        call    BIOS_WRTPSG             ; coarse period
        ld      a,(hl)
        cp      0xFF
        jp      z,mt_end
        ex      de,hl                   ; DE = next note
        pop     hl
        push    hl
        inc     hl
        inc     hl
        ld      (hl),e
        inc     hl
        ld      (hl),d
        dec     hl
        dec     hl
        dec     hl
mt_env:                                 ; HL = +0
        ld      a,(hl)
        cp      9
        jp      z,mt_step
        inc     a
        ld      (hl),a
mt_step:
        ld      c,a                     ; C = envelope step
        inc     hl
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl                      ; +4
        dec     de
        ld      a,(de)
        dec     de
        ex      de,hl
        or      (hl)                    ; period 0: a rest
        ex      de,hl
        ld      e,0                     ; rest: volume 0
        jp      z,mt_rest
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                  ; DE = envelope table, HL = +5
        ex      de,hl
        ld      b,0
        add     hl,bc
        ld      a,(hl)
        ex      de,hl
        ld      e,a                     ; volume from the table
        dec     hl
mt_rest:
        inc     hl
        inc     hl
        inc     hl                      ; +7 volume register
        ld      a,(hl)
        call    BIOS_WRTPSG
mt_next:
        pop     hl
        ld      de,8
        add     hl,de
        ld      a,l
        cp      MT_END & 0xFF
        jp      nz,mt_ch
        or      a                       ; NZ
        ret
mt_end:
        pop     hl
        xor     a                       ; Z: pattern ended
        ret


V_SND_INIT:
        jp      BIOS_GICINI

; ============================================================================
;  V_SND_TICK - once per frame from the IRQ handler. Clobbers AF, BC, DE, HL.
; ============================================================================
V_SND_TICK:
        call    SND_NOISE_SCAN
        ld      c,0
st_ch:
        call    snd_channel
        inc     c
        ld      a,c
        cp      3
        jp      c,st_ch
        jp      SND_NOISE_BURST         ; the noisy voice: bits on its counter

; C = channel 0..2
snd_channel:
        ld      a,(V_MUTE)              ; УС: sound off
        or      a
        jp      nz,snd_off
        ld      a,(V_NOISE)             ; the noisy voice: its counter plays
        dec     a                       ; the noise bits (SND_NOISE_BURST)
        cp      c
        jp      z,snd_off
        ; tone enabled? (R7 bit c = 0)
        ld      a,(V_AYREG+7)
        ld      b,c
        inc     b
sc_mix:
        rrca
        dec    b
        jp    nz,sc_mix
        jp      c,snd_off               ; bit shifted into carry = 1 → off
        ; volume R8+c: envelope bit or level >= 6
        ld      a,c
        add     a,V_AYREG_VOL
        ld      l,a
        ld      h,V_AYREG >> 8
        ld      a,(hl)
        and     0x10                    ; envelope
        jp      nz,sc_loud
        ld      a,(hl)
        and     0x0F
        cp      SND_THR                 ; 4, as brucelee-v06c (was 6)
        jp      c,snd_off
sc_loud:
        ; D already a ВИ53 divisor (16-bit) in R(2c)/R(2c+1).
        ld      a,c
        add     a,a
        add     a,V_AYREG & 0xFF
        ld      l,a
        ld      e,(hl)
        inc     l
        ld      d,(hl)
        ld      a,d
        or      e
        jp      z,snd_off
        ld      a,d
        or      a
        jp      nz,sc_ok
        ld      a,e
        cp      64
        jp      c,snd_off
sc_ok:
        ld      hl,V_SND_ON
        ld      b,0
        add     hl,bc
        ld      a,(hl)
        or      a
        jp      nz,sc_running
        ld      (hl),1
        call    snd_ctl
        or      0x36                    ; LSB+MSB, mode 3
        out     (0x08),a
        jp      sc_load
sc_running:
        ; same divisor as last time? then nothing to do
        ld      hl,V_SND_DIV
        add     hl,bc
        add     hl,bc
        ld      a,(hl)
        cp      e
        jp      nz,sc_load
        inc     hl
        ld      a,(hl)
        cp      d
        ret     z
sc_load:
        ld      hl,V_SND_DIV
        ld      b,0
        add     hl,bc
        add     hl,bc
        ld      (hl),e
        inc     hl
        ld      (hl),d
        ld      a,c
        or      a
        jp      z,sl_c0
        dec     a
        jp      z,sl_c1
        ld      a,e
        out     (0x09),a
        ld      a,d
        out     (0x09),a
        ret
sl_c1:
        ld      a,e
        out     (0x0A),a
        ld      a,d
        out     (0x0A),a
        ret
sl_c0:
        ld      a,e
        out     (0x0B),a
        ld      a,d
        out     (0x0B),a
        ret

; AY noise: SND_NOISE_SCAN / SND_NOISE_BURST / NOISE_WAIT in
; menu_color_bg.asm play it as bits on the noisy voice's counter.
; C = channel: stop the counter (control word only) if it was running
snd_off:
        ld      hl,V_SND_ON
        ld      b,0
        add     hl,bc
        ld      a,(hl)
        or      a
        ret     z
        ld      (hl),0
        call    snd_ctl
        or      0x30                    ; LSB+MSB, mode 0, no count loaded
        out     (0x08),a
        ld      hl,V_SND_DIV
        add     hl,bc
        add     hl,bc
        ld      (hl),0xFF
        inc     hl
        ld      (hl),0xFF
        ret

; C = channel → A = counter select bits (c << 6)
snd_ctl:
        ld      a,c
        rrca
        rrca
        ret
