; ============================================================================
;  Zoomed dunk replay. Replaces A8F4 and the A8C8 stamp (A93C is only
;  called from the replaced A8F4 body).
;
;  Original A8F4 sampled C398, which is court row 8, and a 16-byte-wide
;  window (A8F9 = 0 left, 0010 right) for 96 rows. Here the window is court
;  rows 8..103 like MSX, columns 0..15 or 16..31. Each source bit is doubled
;  and each source row is written twice, filling E000/C000 y=0..191: the
;  replay covers the HUD as on MSX, and REPLAY_DONE draws it back.
;
;  MSX zoomed its composed C298 shadow. Vector has no hidden plane, so a
;  state is never published to the screen: REPLAY_SCENE only stages it
;  (9385) and REPLAY_ZOOM composes each 8x48 eighth of the window (court
;  tiles + every staged object, the BUFFER_PLAYERS path) into 2000 and
;  blits that quarter enlarged. The plain court never shows.
;
;  A8C8, on odd states, stamped the complement of MSX BIOS 1E4F (glyph 'r')
;  onto court rows 8..15, column 3 or 28. The glyph is baked here and goes
;  into the composed quarter before the blit.
;
;  Tempo: one state per REPLAY_PACE_N IRQs counted from the previous
;  displayed state, so composition time is inside the slot.
;  Blit/stamp/pace are i8080. The composer drives the Z80 match helpers
;  (0D99, 1950, 1AD0) and so uses IX like them. Nothing here runs under DI:
;  Vector drops a vblank that arrives while IRQs are off.
; ============================================================================

R_LAST          equ     0x0F0F          ; IRQ count when the last state showed
R_STAMPED       equ     0x0F15          ; 1 = this state carries the marker
R_SP            equ     0x0F16          ; blit source pointer (word)
R_ARMED         equ     0x0F18          ; 0 = first state: show at once
R_PAGE          equ     0x0F10          ; blit: first low-plane column page
REPLAY_X2       equ     REPLAY_X2_TABLE ; menu_color_bg.asm, 16-aligned
REPLAY_BUF      equ     0x2000          ; shared pair buffer; 8 * 60 * 2 = 960
REPLAY_ROWS     equ     48              ; half of the 96-row MSX window
RQ_RECT         equ     0x0F1A          ; col,row,width,height (1950 reads it)
RQ_BUF_BASE     equ     0x0F6D          ; 1950 destination base
RQ_CUR          equ     0x0F69
RQ_ROWS         equ     0x0F5F
RQ_SRC          equ     0x0F11          ; court address of the next row (word)
RQ_COUNT        equ     0x0F6F

; A8F4 entry. A8F9 (the old LD DE immediate) stays the half selector.
REPLAY_ZOOM:
        push    af
        push    bc
        push    de
        push    hl
        ld      hl,0xB498               ; every object of the state
        ld      a,1
        call    STAGE_SLOTS
        ld      a,(REPLAY_HALF_SELECT)
        and     0x10
        ld      b,a
        ld      e,8                     ; court rows 8..55
        push    bc
        call    REPLAY_COMPOSE
        call    REPLAY_PACE
        ld      de,0xE0DF
        call    REPLAY_BLIT
        pop     bc
        ld      a,b
        ld      e,8+REPLAY_ROWS         ; court rows 56..103
        push    bc
        call    REPLAY_COMPOSE
        ld      de,0xE0DF-2*REPLAY_ROWS
        call    REPLAY_BLIT
        pop     bc
        ld      a,b
        add     a,8
        ld      b,a
        ld      e,8
        push    bc
        call    REPLAY_COMPOSE
        ld      de,0xF0DF
        call    REPLAY_BLIT
        pop     bc
        ld      a,b
        ld      e,8+REPLAY_ROWS
        call    REPLAY_COMPOSE
        ld      de,0xF0DF-2*REPLAY_ROWS
        call    REPLAY_BLIT
        xor     a
        ld      (R_STAMPED),a
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

; Replaces CALL D7C4 at the replay epilogue. The last state keeps its full
; slot, then the original delay, then the match court and the HUD come back.
REPLAY_DONE:
        push    af
        push    bc
        push    de
        push    hl
        call    REPLAY_PACE
        call    SYS_DELAY                 ; relocated original D7C4 delay
        call    COURT_TO_PLANES
        call    HUD_DECOR               ; the zoom covered the HUD
        call    HUD_TEXT_REFRESH
        xor     a
        ld      (DIRTY_COUNT),a
        ld      (DIRTY_OLD_COUNT),a
        ld      (R_STAMPED),a
        ld      (R_ARMED),a
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

; A8C8: odd states carry the marker.
REPLAY_STAMP:
        ld      a,(SYS_D0CA)             ; relocated original D0CA state
        inc     a
        and     0x01
        ld      (SYS_D0CA),a
        ld      (R_STAMPED),a
        ret

; A = first court column, E = first court row. Builds 8x48 (low,high) pairs,
; row-major, at REPLAY_BUF: court tiles, then every staged object in list
; order, then the marker. IRQs stay enabled between rows and objects.
REPLAY_COMPOSE:
        ld      (RQ_RECT),a
        ld      c,a
        ld      a,e
        ld      (RQ_RECT+1),a          ; first court row
        rrca
        rrca
        rrca
        ld      b,a
        and     0xE0
        add     a,c
        ld      l,a
        ld      a,b
        and     0x1F
        add     a,0x25
        ld      h,a                    ; 2500 + row*32 + col
        ld      (RQ_SRC),hl
        ld      a,8
        ld      (RQ_RECT+2),a          ; width 8
        ld      a,REPLAY_ROWS
        ld      (RQ_RECT+3),a
        ld      (RQ_ROWS),a
        ld      hl,REPLAY_BUF
        ld      (RQ_BUF_BASE),hl
        ld      (RQ_CUR),hl
rq_bg:
        ld      hl,(RQ_SRC)
        ld      a,l
        and     31
        add     a,a
        ld      c,a
        ld      b,0
        call    COURT_TILE_ROW_POINTER                 ; COURT_TILE_ROW_POINTER
        push    hl
        ld      hl,(RQ_CUR)
        ex      de,hl
        pop     hl
        call    REPLAY_TILE_ROW        ; 8 pairs, IRQs on
        ex      de,hl
        ld      (RQ_CUR),hl
        ld      hl,(RQ_SRC)
        ld      de,32
        add     hl,de
        ld      (RQ_SRC),hl
        ld      hl,RQ_ROWS
        dec     (hl)
        jp      nz,rq_bg

        ld      a,(DIRTY_COUNT)
        or      a
        jp      z,rq_stamp
        ld      (RQ_COUNT),a
        ld      hl,DIRTY_LIST
        ld      (PCC_RECT),hl
        ld      hl,0xB498
rq_obj:
        call    PLAYER_COMPOSE_CLIPPED                 ; PLAYER_COMPOSE_CLIPPED (ISR-safe)
        push    hl
        ld      hl,(PCC_RECT)
        ld      de,4
        add     hl,de
        ld      (PCC_RECT),hl
        pop     hl
        ld      a,(RQ_COUNT)
        dec     a
        ld      (RQ_COUNT),a
        jp      nz,rq_obj

rq_stamp:
        ld      a,(RQ_RECT+1)
        cp      8                      ; the marker sits on rows 8..15
        ret     nz
        ld      a,(R_STAMPED)
        or      a
        ret     z
        ld      a,(SYS_D0CB)             ; relocated original D0CB side
        and     0x80
        ld      a,3
        jp      z,rq_col
        ld      a,28
rq_col:
        ld      hl,RQ_RECT
        sub     (hl)
        ret     c
        cp      8
        ret     nc
        add     a,a
        ld      l,a
        ld      h,REPLAY_BUF >> 8
        ld      de,REPLAY_GLYPH
        ld      b,8
rq_glyph:
        ld      a,(de)                 ; white pen: low = glyph, high = 0
        ld      (hl),a
        inc     hl
        xor     a
        ld      (hl),a
        ld      a,l
        add     a,15
        ld      l,a
        inc     de
        dec     b
        jp      nz,rq_glyph
        ret

; 64x48 composed pairs → 128x96 at low-plane page D (E0 or F0), from plane
; row E down.
; Each nibble doubles via REPLAY_X2 into two bytes on two scanlines.
; IRQs stay enabled: Vector drops a vblank that arrives under DI.
REPLAY_BLIT:
        ld      a,e
        sub     2*REPLAY_ROWS
        ld      (rb_end+1),a
        ld      a,d
        ld      (R_PAGE),a
        ld      hl,REPLAY_BUF
        ld      (R_SP),hl              ; source pointer
rb_row:
        ld      a,(R_PAGE)
        ld      d,a
rb_col:
        ld      hl,(R_SP)
        ld      c,(hl)                 ; low plane
        inc     hl
        ld      b,(hl)                 ; high plane
        inc     hl
        ld      (R_SP),hl
        ld      h,REPLAY_X2 >> 8
        ld      a,c
        call    rb_byte
        ld      a,d
        sub     0x21                   ; high plane, same column
        ld      d,a
        ld      a,b
        call    rb_byte
        ld      a,d
        add     a,0x21                 ; next low-plane column pair
        ld      d,a
        and     0x0F
        jp      nz,rb_col
        ld      a,e
        sub     2
        ld      e,a
rb_end:
        cp      0                      ; patched: first plane row below
        jp      nz,rb_row
        ret

; A = one plane byte → (D,E),(D,E-1) high nibble, (D+1,E),(D+1,E-1) low.
; Leaves D+1, E unchanged. Clobbers C, L (H = table page).
rb_byte:
        ld      c,a
        rrca
        rrca
        rrca
        rrca
        and     0x0F
        add     a,REPLAY_X2 & 0xFF
        ld      l,a
        ld      a,(hl)
        ld      (de),a
        dec     e
        ld      (de),a
        inc     d
        ld      a,c
        and     0x0F
        add     a,REPLAY_X2 & 0xFF
        ld      l,a
        ld      a,(hl)
        ld      (de),a
        inc     e
        ld      (de),a
        ret

; How many 50 Hz IRQs one displayed state occupies, composition included.
; 32/50 s × 14 recorded states ≈ 9.0 s, the MSX replay length.
; 00 skips the wait (tests). Poked, not a constant buried in the loop.
REPLAY_PACE_N:
        db      32

; Wait until REPLAY_PACE_N IRQs have passed since the previous state was
; shown, then mark now. The first state of a replay shows at once.
REPLAY_PACE:
        ld      a,(R_ARMED)
        or      a
        jp      z,rp_mark
        ld      a,(REPLAY_PACE_N)
        or      a
        jp      z,rp_mark
        ld      c,a
rp_wait:
        ld      a,(R_LAST)
        ld      b,a
        ld      a,(IRQ_FRAME_COUNT)
        sub     b
        cp      c
        jp      nc,rp_mark
        ei
        halt
        jp      rp_wait
rp_mark:
        ld      a,(IRQ_FRAME_COUNT)
        ld      (R_LAST),a
        ld      a,1
        ld      (R_ARMED),a
        ret

; CPL of MSX BIOS 1E4F..1E56 (font glyph 'r').
REPLAY_GLYPH:
        db      0x0F,0x77,0x77,0x0F,0x5F,0x6F,0x77,0xFF

; 4 source bits → 8 doubled bits: REPLAY_X2 table at 1590 (menu_color_bg.asm,
; 16-aligned so `add a,l` never carries). color_sprite.asm's two JP entries
; follow; they must end at or before COLOR_FRAME_END (0A16).
REPLAY_CODE_END:
