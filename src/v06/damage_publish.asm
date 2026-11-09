; ============================================================================
;  Publish by damage (COLOR_FRAME_END, match and menu).
;
;  The game's COLOR_SPRITE calls only record the objects (meta and clipped
;  rectangle; slot order = the game's call order = depth order, as MSX
;  painted its C298 shadow). Damage is
;
;    * each old rectangle whose (record, X, Y) is not drawn again,
;    * each new rectangle whose (record, X, Y) was not drawn last frame,
;    * the stand stamp rectangle after CPC_STAMP_ON switched the background;
;    * every new rectangle after COURT_TO_PLANES repainted the court.
;
;  A byte outside the damage is covered by the same unchanged objects in
;  both frames, so it is already right. Damage boxes that touch merge while
;  the box fits the 1280-byte buffer at 2000. The boxes go at B498; then
;  STAGE_SLOTS stages, after them, only the objects some box touches (an
;  untouched one would be clipped out of every box). Each box is composed there
;  (court/stamp tiles, then every staged object clipped to the box, in slot
;  order) with IRQs on. The frame interrupt copies a batch of composed boxes
;  to both planes right after the keyboard poll (DP_ISR_COPY), while the
;  beam is still above the court: a batch holds only the boxes the copy can
;  finish ahead of the beam (dp_fits_beam), the rest wait for the next
;  vblank. The screen never shows an erased object or a torn box.
;  tools/frame_predict.js checks every court byte of every publish.
; ============================================================================

DP_BUF          equ     0x2000          ; shared graphics buffer, 1280 bytes
DP_BUF_END      equ     0x2500
DP_RECT         equ     0x0F1A          ; col,row,width,height (PCC reads it)
DP_BASE         equ     0x0F6D          ; PCC destination base
DP_CUR          equ     0x0F69          ; tile pointers of the band being filled (stream is done)
DP_ROWS         equ     0x0F5F
DP_COUNT        equ     0x0F6F

MATCH_PUBLISH:
        call    DP_SYNC                 ; the last batch reads B498.. and DP_BUF
        ld      hl,0xB498               ; boxes first, the staged stream after
        ld      (DMG_BASE),hl
        ld      (DMG_END),hl
        ld      a,(PLANES_CLEAN)        ; COURT_TO_PLANES (any caller) wiped
        or      a                       ; every object: none is on screen
        jp      z,dp_old
        xor     a
        ld      (PLANES_CLEAN),a
        ld      (DIRTY_OLD_COUNT),a
dp_old:
        ; Old rectangles not drawn again.
        ld      a,(DIRTY_COUNT)
        ld      (DMG_OCNT),a
        ld      a,(DIRTY_OLD_COUNT)
        ld      hl,DIRTY_OLD_LIST
        ld      de,META_OLD
        ld      bc,CSPR_META
        call    dp_gone
        ; New rectangles not drawn last frame.
        ld      a,(DIRTY_OLD_COUNT)
        ld      (DMG_OCNT),a
        ld      a,(DIRTY_COUNT)
        ld      hl,DIRTY_LIST
        ld      de,CSPR_META
        ld      bc,META_OLD
        call    dp_gone
        ld      a,(STAMP_DIRTY)
        or      a
        jp      z,dp_stage
        xor     a
        ld      (STAMP_DIRTY),a
        ld      hl,dp_stamp_rect
        call    DMG_ADD_RECT
dp_stage:
        ld      hl,(DMG_END)
        xor     a                       ; only the objects a box touches
        call    STAGE_SLOTS

dp_compose:
        ld      hl,(DMG_BASE)
        ld      (DMG_PUB),hl
        ld      hl,DP_BUF
        ld      (DP_BASE),hl
        ld      hl,(DP_START)
        ld      (DP_COST),hl
        ld      hl,(DMG_BASE)
dp_box:
        call    dp_at_end
        jp      z,dp_last
        push    hl
        call    dp_fits_beam            ; NC: ahead of the beam in this batch
        pop     hl
        push    hl
        jp      c,dp_full_beam
        call    SET_RECT                ; HL = bytes of this box
        ex      de,hl
        ld      hl,(DP_BASE)
        add     hl,de
        ld      a,h                     ; past DP_BUF_END: copy what is ready
        cp      DP_BUF_END >> 8
        jp      c,dp_fits
        jp      nz,dp_full
        ld      a,l
        or      a
        jp      z,dp_fits
        jp      dp_full
dp_full_beam:
        ld      hl,(DMG_PUB)            ; first box of a batch always goes
        pop     de
        push    de
        ld      a,l
        cp      e
        jp      nz,dp_full
        ld      a,h
        cp      d
        jp      nz,dp_full
        pop     hl
        push    hl
        call    dp_behind               ; copied behind the beam if it can be
        pop     hl
        push    hl
        call    SET_RECT
        ex      de,hl
        jp      dp_fits
dp_full:
        pop     hl
        push    hl
        call    DP_FLUSH                ; boxes before this one; RECT clobbered
        pop     hl
        jp      dp_box                  ; first of the next batch: check again
dp_fits:
        push    de
        call    COMPOSE_BOX
        pop     de
        ld      hl,(DP_BASE)
        add     hl,de
        ld      (DP_BASE),hl
        pop     hl
        push    hl
        call    dp_box_cost             ; DE = copy time of this box
        ld      hl,(DP_COST)
        add     hl,de
        ld      (DP_COST),hl
        pop     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        jp      dp_box
dp_last:
        call    DP_FLUSH_LAST           ; the IRQ copies it while the game runs
        jp      cfp_exit

; A = count, HL = rects, DE = their metas, BC = the other frame's metas
; (DMG_OCNT of them). Adds every rect whose meta is absent.
dp_gone:
        or      a
        ret     z
dg_rect:
        push    af
        push    bc
        push    hl
        push    de
        ld      a,(DMG_OCNT)
        ld      h,b
        ld      l,c
        call    META_FIND
        pop     de
        pop     hl
        call    nz,DMG_ADD_RECT
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        inc     de
        inc     de
        inc     de
        inc     de
        pop     bc
        pop     af
        dec     a
        jp      nz,dg_rect
        ret

; DE = 4-byte meta, HL = meta list, A = entries. Z when DE is in the list.
; Keeps DE.
META_FIND:
        or      a
        jp      z,mf_none
        ld      b,a
mf_entry:
        push    de
        push    hl
        ld      c,4
mf_cmp:
        ld      a,(de)
        cp      (hl)
        jp      nz,mf_diff
        inc     de
        inc     hl
        dec     c
        jp      nz,mf_cmp
        pop     hl
        pop     de
        ret                             ; Z
mf_diff:
        pop     hl
        pop     de
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        dec     b
        jp      nz,mf_entry
mf_none:
        or      1                       ; NZ
        ret

; HL = rect (col,row,width,height). Adds it as a box (c0,r0,c1,r1): a box
; it touches absorbs it while their bounding box fits DP_BUF, and the grown
; box is added again. Keeps BC, DE, HL.
DMG_ADD_RECT:
        push    hl
        push    de
        push    bc
        ld      a,(hl)
        ld      (DMG_NB),a
        ld      b,a
        inc     hl
        ld      a,(hl)
        ld      (DMG_NB+1),a
        ld      c,a
        inc     hl
        ld      a,(hl)
        and     0x7F
        add     a,b
        ld      (DMG_NB+2),a
        inc     hl
        ld      a,(hl)
        add     a,c
        ld      (DMG_NB+3),a
dar_scan:
        ld      hl,(DMG_BASE)
dar_next:
        call    dp_at_end
        jp      z,dar_append
        push    hl
        ; Touching: NB.c0 <= E.c1, E.c0 <= NB.c1, NB.r0 <= E.r1, E.r0 <= NB.r1.
        inc     hl
        inc     hl
        ld      a,(hl)                  ; E.c1
        ld      b,a
        ld      a,(DMG_NB)
        cp      b
        jp      z,dar_t1
        jp      nc,dar_skip
dar_t1:
        dec     hl
        dec     hl
        ld      a,(DMG_NB+2)
        cp      (hl)                    ; NB.c1 - E.c0
        jp      c,dar_skip
        inc     hl
        ld      a,(DMG_NB+3)
        cp      (hl)                    ; NB.r1 - E.r0
        jp      c,dar_skip
        inc     hl
        inc     hl
        ld      a,(hl)                  ; E.r1
        ld      b,a
        ld      a,(DMG_NB+1)
        cp      b
        jp      z,dar_t2
        jp      nc,dar_skip
dar_t2:
        ; Bounding box into DMG_TB: minima, then maxima.
        pop     hl
        push    hl
        ld      de,DMG_NB
        ld      bc,DMG_TB
        call    dar_min
        call    dar_min
        call    dar_max
        call    dar_max
        ld      hl,DMG_TB
        call    SET_RECT
        ld      a,h                     ; bytes <= 1280
        cp      5                       ; (DP_BUF_END - DP_BUF) / 256
        jp      c,dar_take
        jp      nz,dar_skip
        ld      a,l
        or      a
        jp      nz,dar_skip
dar_take:
        ld      hl,(DMG_TB)             ; NB = TB
        ld      (DMG_NB),hl
        ld      hl,(DMG_TB+2)
        ld      (DMG_NB+2),hl
        ld      hl,(DMG_END)            ; drop E: the last box takes its place
        dec     hl
        dec     hl
        dec     hl
        dec     hl
        ld      (DMG_END),hl
        ex      de,hl
        pop     hl
        ld      b,4
dar_move:
        ld      a,(de)
        ld      (hl),a
        inc     de
        inc     hl
        dec     b
        jp      nz,dar_move
        jp      dar_scan
dar_skip:
        pop     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        jp      dar_next
dar_append:
        ld      de,DMG_NB
        ld      b,4
dar_copy:
        ld      a,(de)
        ld      (hl),a
        inc     de
        inc     hl
        dec     b
        jp      nz,dar_copy
        ld      (DMG_END),hl
        pop     bc
        pop     de
        pop     hl
        ret

; (BC) = min/max((DE), (HL)); all three advance.
dar_min:
        ld      a,(de)
        cp      (hl)
        jp      c,dm_store
        ld      a,(hl)
        jp      dm_store
dar_max:
        ld      a,(de)
        cp      (hl)
        jp      nc,dm_store
        ld      a,(hl)
dm_store:
        ld      (bc),a
        inc     bc
        inc     de
        inc     hl
        ret

; Z when HL = DMG_END. Keeps HL, DE.
dp_at_end:
        ld      a,(DMG_END)
        cp      l
        ret     nz
        ld      a,(DMG_END+1)
        cp      h
        ret

; HL = box (c0,r0,c1,r1) → DP_RECT = col,row,width,height; HL = its bytes
; in the buffer (width * height * 2).
SET_RECT:
        call    RECT_FIELDS
        ld      a,b
        call    MUL_DE_A
        add     hl,hl
        ret

; DP_RECT from the box at HL. E = w, D = 0, B = h.
RECT_FIELDS:
        ld      a,(hl)
        ld      (DP_RECT),a
        ld      b,a
        inc     hl
        ld      a,(hl)
        ld      (DP_RECT+1),a
        ld      c,a
        inc     hl
        ld      a,(hl)
        sub     b
        ld      (DP_RECT+2),a
        ld      e,a
        ld      d,0
        inc     hl
        ld      a,(hl)
        sub     c
        ld      (DP_RECT+3),a
        ld      b,a
        ret

; Compose DP_RECT at (DP_BASE): background rows, then every staged object
; clipped to the box. IRQs stay on except inside the SP tile copier.
; The court address and the tile pointer table are set up once per tile band
; (8 rows); inside a band only the row offset in the tiles moves.
COMPOSE_BOX:
        ld      a,(DP_RECT+1)
        ld      (B1_ROW),a
        ld      a,(DP_RECT+3)
        ld      (DP_ROWS),a
        ld      a,(DP_RECT+2)           ; TILE_BAND_FILL: two columns a pass,
        or      a                       ; an odd width enters at the second
        rra
        ld      l,tbf_first & 255
        jp      nc,cb_even
        inc     a
        ld      l,tbf_second & 255      ; same page as tbf_first
cb_even:
        ld      (TBF_WIDTH+1),a
        ld      a,l
        ld      (TBF_ENTRY+1),a
        ld      hl,(DP_BASE)
        ex      de,hl                   ; DE = buffer row
        ld      a,(TITLE_SNAPPED)       ; menu: players on the blue panel
        or      a
        jp      nz,cb_menu
cb_band:
        ld      a,(B1_ROW)
        ld      l,a
        ld      h,0
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        ld      a,(DP_RECT)
        add     a,l
        ld      l,a
        ld      a,h
        add     a,COURT_SRC >> 8
        ld      h,a                     ; HL = COURT_SRC + row*32 + col
        ld      a,l
        and     31
        add     a,a
        ld      c,a
        ld      b,0
        push    de
        call    COURT_TILE_ROW_POINTER  ; A = row offset in the tiles
        pop     de
        ld      (DP_CUR),hl             ; this band's tile pointers
cb_row:                                 ; A = tile row offset of this row
        ld      c,a
        ld      a,16
        sub     c
        rrca
        ld      b,a                     ; rows left in the band
        ld      a,(DP_ROWS)
        cp      b
        jp      nc,cbr_band
        ld      b,a                     ; the box ends inside the band
cbr_band:
        ld      a,(BG_FETCH+1)          ; stand on: one row a call, then
        cp      COURT_TILE_PAIR & 255   ; STAMP_ROW_FIX patches its cells
        jp      z,cbr_fill
        ld      b,1
cbr_fill:
        ld      a,b
        add     a,a
        add     a,c
        ld      (TBF_END+1),a
        push    bc                      ; B = rows of this call
        call    TILE_BAND_FILL          ; SP copier, IRQs on between rows
        call    STAMP_ROW_FIX           ; returns at once off the stand
        pop     bc
        ld      hl,B1_ROW
        ld      a,(hl)
        add     a,b
        ld      (hl),a
        ld      hl,DP_ROWS
        ld      a,(hl)
        sub     b
        ld      (hl),a
        jp      z,cb_objects
        ld      a,(TBF_END+1)
        cp      16
        jp      c,cb_row                ; same band (stand rows)
        jp      cb_band
cb_objects:
        ld      a,(DIRTY_COUNT)
        or      a
        ret     z
        ld      (DP_COUNT),a
        ld      hl,DIRTY_LIST
        ld      (PCC_RECT),hl
        ld      hl,(SS_BASE)
cb_object:
        push    hl
        ld      hl,(PCC_RECT)
        inc     hl
        inc     hl
        ld      a,(hl)                  ; width, bit 7: not staged
        pop     hl
        or      a
        call    p,PLAYER_COMPOSE_CLIPPED ; HL past the object
        push    hl
        ld      hl,(PCC_RECT)
        ld      de,4
        add     hl,de
        ld      (PCC_RECT),hl
        pop     hl
        ld      a,(DP_COUNT)
        dec     a
        ld      (DP_COUNT),a
        jp      nz,cb_object
        ret

; Stage this frame's objects (DIRTY_COUNT slots: CSPR_META, DIRTY_LIST)
; into the stream at HL, a new hoop-cache pass. A = 0: only the objects whose
; rectangle touches a damage box (DMG_BASE..DMG_END); the others get bit 7
; of their rectangle width (cb_objects skips them; DMG_ADD_RECT and the
; byte guard mask it). A != 0: every object (the replay). BLIT_Y, BLIT_X,
; BLIT_SRC are kept.
STAGE_SLOTS:
        ld      (SS_ALL),a
        ld      (SS_BASE),hl
        ld      (CSPR_CACHE_PTR),hl
        ld      hl,(HC_GEN)
        inc     hl
        ld      (HC_GEN),hl
        ld      a,(DIRTY_COUNT)
        or      a
        ret     z
        ld      (SS_LEFT),a
        ld      hl,(BLIT_Y)             ; BLIT_Y, BLIT_X
        push    hl
        ld      hl,(BLIT_SRC)
        push    hl
        ld      hl,DIRTY_LIST
ss_slot:
        inc     hl
        inc     hl
        ld      a,(hl)
        and     0x7F
        ld      (hl),a                  ; staged unless skipped below
        dec     hl
        dec     hl
        ld      a,(SS_ALL)
        or      a
        jp      nz,ss_take
        push    hl
        call    ss_touch
        pop     hl
        jp      nz,ss_take
        inc     hl
        inc     hl
        ld      a,(hl)
        or      0x80
        ld      (hl),a
        inc     hl
        inc     hl
        jp      ss_next
ss_take:
        push    hl
        ld      de,CSPR_META - DIRTY_LIST
        add     hl,de                   ; this slot's meta
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ex      de,hl
        ld      (BLIT_SRC),hl
        ex      de,hl
        ld      a,(hl)
        ld      (BLIT_X),a
        inc     hl
        ld      a,(hl)
        ld      (BLIT_Y),a
        call    CS_STAGE_SLOT
        pop     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
ss_next:
        ld      a,(SS_LEFT)
        dec     a
        ld      (SS_LEFT),a
        jp      nz,ss_slot
        pop     hl
        ld      (BLIT_SRC),hl
        pop     hl
        ld      (BLIT_Y),hl
        ret

; HL = rectangle (col,row,width,height). NZ when a damage box overlaps it
; (the same test as PLAYER_COMPOSE_CLIPPED's clip).
ss_touch:
        ld      b,(hl)                  ; c
        inc     hl
        ld      c,(hl)                  ; r
        inc     hl
        ld      a,(hl)
        and     0x7F
        add     a,b
        ld      d,a                     ; c + w
        inc     hl
        ld      a,(hl)
        add     a,c
        ld      e,a                     ; r + h
        ld      hl,(DMG_BASE)
st_box:
        call    dp_at_end
        ret     z
        ld      a,(hl)                  ; c0 < c + w
        cp      d
        jp      nc,st_no0
        inc     hl
        ld      a,(hl)                  ; r0 < r + h
        cp      e
        jp      nc,st_no1
        inc     hl
        ld      a,b                     ; c < c1
        cp      (hl)
        jp      nc,st_no2
        inc     hl
        ld      a,c                     ; r < r1
        cp      (hl)
        jp      nc,st_no3
        or      0xFF                    ; NZ
        ret
st_no0:
        inc     hl
st_no1:
        inc     hl
st_no2:
        inc     hl
st_no3:
        inc     hl
        jp      st_box

; Menu row: solid blue (pen 0 in both planes), as the menu always drew
; its players.
cb_menu:
        ld      a,(DP_RECT+2)
        ld      b,a
        call    MENU_BUFFER_ROW
        ld      hl,B1_ROW
        inc     (hl)
        ld      hl,DP_ROWS
        dec     (hl)
        jp      nz,cb_menu
        jp      cb_objects

; Hand the composed boxes DMG_PUB..HL (exclusive) to the frame interrupt
; and wait until it has copied them; then start the buffer again.
DP_FLUSH:
        call    DP_POST
        ret     z                       ; nothing composed: no vblank wait
        call    DP_SYNC
        ld      hl,(DP_STOP)
        ld      (DMG_PUB),hl
        ld      hl,DP_BUF
        ld      (DP_BASE),hl
        ld      hl,(DP_START)
        ld      (DP_COST),hl
        ret

; The last batch of a publish (07.11): handed to the frame IRQ without a
; wait, the game goes on while it is copied. Whoever next writes the box
; list B498.., DP_BUF or the court on screen calls DP_SYNC first
; (MATCH_PUBLISH, REPLAY_ZOOM, COURT_TO_PLANES, WIPE_COLUMN, TITLE_RELOAD).
; The copy in the IRQ touches only DP_RECT, DP_BASE and 0F16, which only
; that code uses. With the ball's AY noise the wait stays: the speaker
; noise plays in it (NOISE_WAIT).
DP_FLUSH_LAST:
        ld      a,(V_NOISE)
        or      a
        jp      nz,DP_FLUSH
        call    DP_POST
        ld      hl,(DP_START)           ; as after a waited flush (the IRQ
        ld      (DP_COST),hl            ; does not read it)
        ret
; HL = one past the last box: post DMG_PUB..HL to the IRQ. Z: nothing to post.
DP_POST:
        ex      de,hl
        ld      hl,(DMG_PUB)
        ld      a,l
        cp      e
        jp      nz,dpo_some
        ld      a,h
        cp      d
        ret     z
dpo_some:
        ex      de,hl
        ld      (DP_STOP),hl
        ld      a,1
        ld      (DP_READY),a            ; NZ
        ret

; Wait until the frame IRQ has copied the posted batch. Returns with EI.
DP_SYNC:
        ld      a,(DP_READY)
        or      a
        ret     z
        di
ds_wait:
        ld      a,(DP_READY)
        or      a
        jp      z,ds_done
        call    NOISE_WAIT              ; the IRQ copies the batch (DP_ISR_COPY)
        jp      ds_wait
ds_done:
        ei
        ret

; IRQ_HANDLER, right after the keyboard poll (the beam is above the court):
; copy the ready batch DMG_PUB..DP_STOP from DP_BUF to the planes. The
; handler has saved AF, BC, DE, HL; interrupts are off.
DP_ISR_COPY:
        ld      a,(DP_READY)
        or      a
        ret     z
        ld      a,(DP_WAIT)             ; a box behind the beam: wait W lines
        or      a
        jp      z,dic_now
        ld      c,a
dic_line:
        ld      a,(DP_BEHIND+1)
        ld      b,a
dic_spin:
        dec     b
        jp      nz,dic_spin
        dec     c
        jp      nz,dic_line
        xor     a
        ld      (DP_WAIT),a
dic_now:
        ld      hl,DP_BUF
        ld      (DP_BASE),hl
        ld      hl,(DMG_PUB)
dic_box:
        ld      a,(DP_STOP)
        cp      l
        jp      nz,dic_go
        ld      a,(DP_STOP+1)
        cp      h
        jp      z,dic_done
dic_go:
        push    hl
        call    RECT_FIELDS
        call    PUBLISH_RECT            ; DP_BASE moves past the box
        pop     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        jp      dic_box
dic_done:
        xor     a
        ld      (DP_READY),a
        ret

; Copy timing in units of 4 Vector cycles (a raster line = 48), measured
; with tools/frame_predict.js BEAM=2 (vector06js): a box row of w pairs
; costs A*w + B, a box C more (setup), the first box starts at DP_START:
;   Z80   37w + 66 cycles -> 10w + 17, C 3.7 lines, start line 22;
;   i8080 52w + 100       -> 13w + 25, C 4.5 lines, start line 28
; (tools/build_i8080_rom.py writes the i8080 values). The copy runs after
; the keyboard poll (IRQ at line 0, palette every 4th frame; the poll must
; end before the scroll latch at line 40). Court row r is shown at line
; 80 + r and must be written before. A box fits when its first and its
; last row do (the copy is slower than the beam from w = 4 on); a box that
; misses even alone goes first in its own batch (torn).
DP_TIMING:
        db      10, 17, 176             ; Z80: A, B, C
DP_START:
        dw      48 * 22                 ; Z80: copy of the first box from line 22
DP_BEHIND:
        db      65, 12                  ; Z80: K, spins of the wait loop a line

; HL = box. DE = A*w + B, B = h, C = r0. Keeps HL.
dp_row_cost:
        push    hl
        ld      a,(hl)
        ld      b,a                     ; c0
        inc     hl
        ld      c,(hl)                  ; r0
        inc     hl
        ld      a,(hl)
        sub     b
        ld      b,a                     ; w
        inc     hl
        ld      a,(hl)
        sub     c
        push    af                      ; h
        ld      a,(DP_TIMING)
        ld      e,a
        ld      d,0
        ld      a,(DP_TIMING+1)
        ld      l,a
        ld      h,d
drc_w:
        add     hl,de
        dec     b
        jp      nz,drc_w
        ex      de,hl
        pop     af
        ld      b,a
        pop     hl
        ret

; HL = box. DE = h * (A*w + B) + C, the copy time of the box. Keeps HL.
dp_box_cost:
        call    dp_row_cost
; DE = B * DE + C (C: per-box setup). Keeps HL.
dp_times:
        push    hl
        ld      a,b
        call    MUL_DE_A                ; HL = B * DE
        ld      a,(DP_TIMING+2)
        ld      e,a
        ld      d,0
        add     hl,de
        ex      de,hl
        pop     hl
        ret

; DE = time a row is done, A = its court row. C when the beam shows the row
; first (48 * (80 + A) < DE). Keeps DE.
dp_late:
        add     a,80
        ld      l,a
        ld      h,0
        call    dp_x48
        ld      a,l
        sub     e
        ld      a,h
        sbc     a,d
        ret

; HL = 48 * HL. Clobbers BC.
dp_x48:
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        ld      b,h
        ld      c,l
        add     hl,hl
        add     hl,bc
        ret

; HL = box that misses the beam even alone (first of its batch). A box
; slower than the beam (a row >= 1 line) is copied behind it instead: the
; IRQ waits W = r0 + K lines (DP_BEHIND: K from the earliest first row of a
; batch, so the beam has shown row r0 when row r0 is written) and every row
; is written after the beam showed it; the box shows whole next frame. Only
; when the copy ends by line 300 (the next IRQ must not meet DI). Sets
; DP_WAIT and moves DP_COST past the wait. Keeps nothing.
DP_LAST         equ     48 * 300
dp_behind:
        push    hl
        call    dp_row_cost             ; DE = row, C = r0
        ld      a,d
        or      a
        jp      nz,dbh_slow
        ld      a,e
        cp      48
        jp      c,dbh_none              ; faster than the beam
dbh_slow:
        ld      a,(DP_BEHIND)
        add     a,c                     ; W
        push    af
        ld      l,a
        ld      h,0
        call    dp_x48
        ex      de,hl
        ld      hl,(DP_COST)
        add     hl,de                   ; start after the wait
        pop     af
        pop     de                      ; box
        push    de
        push    af
        push    hl
        ex      de,hl
        call    dp_box_cost             ; DE = copy time
        pop     hl
        push    hl
        add     hl,de                   ; end
        ld      a,l
        sub     DP_LAST & 255
        ld      a,h
        sbc     a,DP_LAST >> 8          ; C: ends before line 300
        pop     hl
        jp      nc,dbh_late
        ld      (DP_COST),hl
        pop     af
        ld      (DP_WAIT),a
        pop     hl
        ret
dbh_late:
        pop     af
dbh_none:
        pop     hl
        ret

; HL = box. C when its first or last row, copied after DP_COST, passes the
; beam. Keeps HL.
dp_fits_beam:
        call    dp_row_cost
        ld      b,1
        push    bc                      ; C = first row
        call    dp_times
        push    hl
        ld      hl,(DP_COST)
        add     hl,de
        ex      de,hl
        pop     hl
        pop     bc
        ld      a,c
        push    hl
        call    dp_late
        pop     hl
        ret     c
        call    dp_box_cost
        push    hl
        ld      hl,(DP_COST)
        add     hl,de
        ex      de,hl
        pop     hl
        push    hl
        inc     hl
        inc     hl
        inc     hl
        ld      a,(hl)
        dec     a                       ; last row
        call    dp_late
        pop     hl
        ret

; DP_RECT from (DP_BASE), (low, high) pairs row-major, onto both planes.
; Under DI: SP walks the buffer. A row is 8 columns unrolled, entered at
; the step that leaves a multiple of 8 (Duff): 52 Vector cycles a column
; on the i8080 (the old loop: 80). The patched operands are set up once.
; DP_BASE ends past the box.
PUBLISH_RECT:
        ld      a,(DP_RECT+2)           ; w
        dec     a
        and     7                       ; (w - 1) mod 8
        ld      b,a
        add     a,a
        add     a,b
        add     a,a                     ; 6 bytes a column
        ld      b,a
        ld      hl,pr_blk + 42
        ld      a,l
        sub     b
        ld      l,a
        ld      a,h
        sbc     a,0
        ld      h,a
        ld      (pr_jmp+1),hl           ; entry: the last (w - 1) mod 8 + 1 steps
        ld      a,(DP_RECT)
        add     a,0xC0
        ld      (pr_hi+1),a             ; high-plane page of the first column
        add     a,0x20
        ld      (pr_lo+1),a             ; low-plane page
        ld      a,(DP_RECT+2)
        ld      hl,DP_RECT
        add     a,(hl)
        add     a,0xC0
        ld      (pr_end+1),a            ; high-plane page after the last column
        ld      a,(DP_RECT+1)
        ld      c,a
        ld      a,0xD7
        sub     c
        ld      e,a                     ; first row byte
        ld      hl,DP_RECT+3
        sub     (hl)
        ld      (pr_last+1),a           ; row byte after the last row
        ld      hl,0
        add     hl,sp
        ld      (0x0F16),hl             ; real SP
        ld      hl,(DP_BASE)
        ld      sp,hl
        ld      l,e
pr_row:
pr_hi:  ld      h,0                     ; patched
pr_lo:  ld      d,0                     ; patched
pr_jmp: jp      0                       ; patched
pr_blk:
        REPT    8
        pop     bc
        ld      a,c
        ld      (de),a                  ; low plane
        ld      (hl),b                  ; high plane
        inc     d
        inc     h
        ENDM
        ld      a,h
pr_end:
        cp      0                       ; patched: end page
        jp      nz,pr_blk
        dec     e
        dec     l
        ld      a,l
pr_last:
        cp      0                       ; patched: past the last row
        jp      nz,pr_row
        ld      hl,0
        add     hl,sp
        ld      (DP_BASE),hl
        ld      hl,(0x0F16)
        ld      sp,hl
        ret

; The stand stamp (cpc_stamp.asm: STAMP_COL, STAMP_ROW, STAMP_W, STAMP_H).
dp_stamp_rect:
        db      5, 10, 22, 29

; Jumping fans after a basket. While a basket is celebrated (9400 low nibble
; 4) the game counts SCORE_FANS (9451) down once per game frame, 13h..0; the
; MSX drew the standing fans on its even steps (A502 tests bit 0) but never
; sat them down, so the port showed them standing until the court was
; rebuilt, and only for the baskets whose countdown started even. As on the
; CPC they now jump: standing on even steps, seated on odd ones and once the
; countdown is over. A502 (once per game frame) CALLs this in place of its
; LD A,(9400) and gets that value back; A521 no longer switches the stamp
; (glue NATIVE_STAMP = RET), the MSX test after it still draws its random
; number as before.
CROWD_TICK:
        ld      hl,COURT_TILE_PAIR      ; seated
        ld      a,(SCORE_TYPE)
        and     0x0F
        cp      4
        jp      nz,ct_gate
        ld      a,(SCORE_FANS)
        or      a
        jp      z,ct_gate
        rrca
        jp      c,ct_gate
        ld      hl,STAMP_PAIR           ; standing
ct_gate:
        ld      a,(BG_FETCH+1)
        cp      l                       ; 1800 vs STAMP_PAIR: low bytes differ
        jp      z,ct_done
        ld      (BG_FETCH+1),hl
        ld      a,1
        ld      (STAMP_DIRTY),a         ; the next publish recomposes the stand
ct_done:
        ld      a,(SCORE_TYPE)
        ret
MATCH_PUBLISH_END:
