; ============================================================================
; CPC two-plane sprite renderer (unit adapter_hi.asm, freed sprite space).
; Entries used by other units are labels (cfg/labels.json, linked by
; tools/link_labels.py); nothing here is pinned.
; ============================================================================

COLOR_FRAME_BEGIN:
        jp      COLOR_MATCH_PREP

COLOR_MENU_BEGIN:
        jp      COLOR_MENU_PREP

COLOR_ENTRIES_END:

; Publish one completed logical frame, match and menu: MATCH_PUBLISH
; (damage_publish.asm) composes the damage and ends at cfp_exit. Until then
; both planes still show the previous complete frame.
COLOR_FRAME_END:
        push    af
        push    bc
        push    de
        push    hl
        jp      MATCH_PUBLISH
cfp_done:
cfp_exit:
        ei
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

; Menu no longer needs a high-plane
; wipe here: MENU_BG_RELOAD / COURT_TO_PLANES publish complete frames.
; NATIVE_RESET is a terminal jp, so BC/DE/HL need not be preserved.
COLOR_FRAME_RESET:
        jp      FRAME_RESET


; ============================================================================
;  COLOR_SPRITE: convert a CPC sprite into the staged two-plane stream.
;
;  Former B01C contract: (3300)=Y, (3301)=X in two-pixel units,
;  (3302)=sprite record. Record: height,width_pixels; then each row contains
;  plane0[stride],plane1[stride]. Pen 0 is transparent.
;
;  The game's call only records the object: its meta (record, X, Y) and its
;  clipped rectangle. The rows are staged at publish time by STAGE_SLOTS
;  (damage_publish.asm) through CS_STAGE_SLOT, and only for objects that a
;  damage box touches (the replay stages all of them).
; ============================================================================
COLOR_SPRITE:
        push    af
        push    bc
        push    de
        push    hl
        xor     a
cs_entry:
        ld      (CS_STAGE),a

        call    CS_HEADER               ; B1_HEIGHT = canvas, A = width
        add     a,7
        rrca
        rrca
        rrca
        and     0x1F
        ld      (CSPR_STRIDE),a

        ld      a,(BLIT_X)
        ld      d,a
        and     3
        add     a,a
        ld      (CSPR_SHIFT),a
        ld      a,(CSPR_STRIDE)
        ld      c,a
        ld      a,(CSPR_SHIFT)
        or      a
        jp      z,cs_width_ready
        inc     c
cs_width_ready:
        ld      a,c
        ld      (CSPR_OUT_WIDTH),a

        ; Signed X/4 gives the byte column. The remainder is a 0/2/4/6 shift.
        ld      a,d
        rrca
        rrca
        and     0x3F
        inc     d
        dec     d                       ; S = sign of X
        jp      p,cs_col_pos
        or      0xC0                    ; arithmetic X >> 2
        jp      cs_clip_left
cs_col_pos:
        cp      32
        jp      nc,cs_done
        ld      (B1_COL),a
        xor     a
        ld      (B1_SKIP),a
        ld      a,(B1_COL)
        ld      b,a
        ld      a,32
        sub     b
        ld      b,a
        ld      a,(CSPR_OUT_WIDTH)
        cp      b
        jp      c,cs_store_width
        jp      z,cs_store_width
        ld      a,b
cs_store_width:
        ld      (B1_WIDTH),a
        jp      cs_clip_y

cs_clip_left:
        cpl
        inc     a
        ld      b,a
        ld      a,(CSPR_OUT_WIDTH)
        cp      b
        jp      c,cs_done
        jp      z,cs_done
        sub     b
        ld      (B1_WIDTH),a
        xor     a
        ld      (B1_COL),a
        ld      a,b
        ld      (B1_SKIP),a

cs_clip_y:
        ld      a,(BLIT_Y)
        ; Menu (COURT_SYNCED=0): drop 7px so body/head sit in the CPC
        ; blue bar (skin ≈ y80..108), matching the original chrome.
        ld      b,a
        ld      a,(0x0FEE)
        or      a
        ld      a,b
        jp      nz,cs_y_ready
        sub     7
cs_y_ready:
        or      a
        jp      m,cs_clip_top
        cp      112
        jp      nc,cs_done
        ld      (B1_ROW),a
        ld      b,a
        ld      a,112
        sub     b
        ld      b,a
        ld      a,(B1_HEIGHT)
        cp      b
        jp      c,cs_store_height
        jp      z,cs_store_height
        ld      a,b
cs_store_height:
        ld      (B1_HEIGHT),a
        jp      cs_draw

cs_clip_top:
        cpl
        inc     a
        ld      b,a
        ld      a,(B1_HEIGHT)
        cp      b
        jp      c,cs_done
        jp      z,cs_done
        sub     b
        ld      (B1_HEIGHT),a
        xor     a
        ld      (B1_ROW),a
        call    CS_SKIP_ROWS            ; B clipped canvas rows

cs_draw:
        ld      a,(CS_STAGE)
        or      a
        jp      nz,cs_stage
        call    CSPR_META_STAGE         ; the game's call: record only
        jp      cs_done
cs_stage:
        call    CS_CACHE_FETCH          ; Z: a hoop as staged last time
        jp      z,cs_done
        ; Unclipped columns (no left skip, full width): shifted rows go
        ; straight into the stream (cs_row_direct), else through the lanes.
        ld      hl,cs_row_lanes
        ld      a,(B1_SKIP)
        or      a
        jp      nz,csd_set
        ld      a,(CSPR_STRIDE)
        inc     a
        ld      b,a
        ld      a,(B1_WIDTH)
        cp      b
        jp      nz,csd_set
        ld      hl,cs_row_direct
csd_set:
        ld      (cs_row_shifted+1),hl
        ld      a,(B1_HEIGHT)
        ld      (CSPR_ROWS),a
cs_row:
        ld      a,(CSPR_PRE)
        or      a
        jp      nz,CS_PRE_ROW           ; empty row above the stored ones
        ld      hl,CSPR_KEEP
        dec     (hl)
        jp      m,CS_ZERO_ROW           ; empty row below them
cs_mirror:
        ld      hl,MIR_ROW              ; CS_HEADER: CALL MIR_ROW for a mirror
        ld      a,(CSPR_SHIFT)
        or      a
        jp      nz,cs_row_shifted
        call    STAGE_ALIGNED_ROW
        jp      cs_row_advance
cs_row_shifted:
        jp      cs_row_lanes            ; patched by cs_draw
cs_row_lanes:
        ld      hl,(CSPR_SRC)
        ld      de,SPR_STRIP
        call    CSPR_BUILD_PLANE
        ld      de,SPR_STRIP+4
        call    CSPR_BUILD_PLANE
        ld      (CSPR_SRC),hl

        ; SPR_STRIP..+7 sits in one page: E walks it, plane 1 is E+4.
        ld      a,(B1_SKIP)
        add     a,SPR_STRIP & 255
        ld      e,a
        ld      d,SPR_STRIP >> 8
        ld      hl,(CSPR_CACHE_PTR)
        ld      a,(B1_WIDTH)
        ld      b,a
cs_blit:
        ld      a,(de)
        ld      (hl),a
        inc     hl
        ld      a,e
        add     a,4
        ld      e,a
        ld      a,(de)
        ld      (hl),a
        inc     hl
        ld      a,e
        sub     3
        ld      e,a
        dec     b
        jp      nz,cs_blit
        ld      (CSPR_CACHE_PTR),hl

cs_row_advance:
        ld      hl,B1_ROW
        inc     (hl)
        ld      hl,CSPR_ROWS
        dec     (hl)
        jp      nz,cs_row
        call    CS_CACHE_STORE

cs_done:
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

; Stage the rows of the object in BLIT_Y, BLIT_X, BLIT_SRC into the stream
; at CSPR_CACHE_PTR (no meta, no rectangle). Keeps all registers.
CS_STAGE_SLOT:
        push    af
        push    bc
        push    de
        push    hl
        ld      a,1
        jp      cs_entry

; Record the draw slot's (record, X, Y) and add its dirty rectangle: the
; match publisher (damage_publish.asm) finds what changed from these metas
; and stages the objects a damage box touches.
CSPR_META_STAGE:
        ld      a,(DIRTY_COUNT)
        ld      l,a
        ld      h,0
        add     hl,hl
        add     hl,hl
        ld      de,CSPR_META
        add     hl,de                   ; HL = this draw slot's meta
        ex      de,hl
        ld      hl,(BLIT_SRC)
        ex      de,hl
        ld      (hl),e
        inc     hl
        ld      (hl),d
        inc     hl
        ld      a,(BLIT_X)
        ld      (hl),a
        inc     hl
        ld      a,(BLIT_Y)
        ld      (hl),a
        jp      DIRTY_ADD

; Expand a source plane row (HL, CSPR_STRIDE bytes) into a shifted scratch
; lane at DE (stride + 1 bytes). C carries the bits shifted out.
CSPR_BUILD_PLANE:
        ld      a,(CSPR_STRIDE)
        ld      (CBP_LEFT),a
        ld      c,0
        ld      a,(CSPR_SHIFT)
        cp      4
        jp      z,cbp_four
        jp      c,cbp_two
cbp_six_l:
        ld      a,(hl)
        rlca
        rlca
        ld      b,a
        and     0x03
        or      c
        ld      (de),a
        inc     de
        ld      a,b
        and     0xFC
        ld      c,a
        inc     hl
        ld      a,(CBP_LEFT)
        dec     a
        ld      (CBP_LEFT),a
        jp      nz,cbp_six_l
        jp      cbp_last
cbp_four:
        ld      a,(hl)
        rrca
        rrca
        rrca
        rrca
        ld      b,a
        and     0x0F
        or      c
        ld      (de),a
        inc     de
        ld      a,b
        and     0xF0
        ld      c,a
        inc     hl
        ld      a,(CBP_LEFT)
        dec     a
        ld      (CBP_LEFT),a
        jp      nz,cbp_four
        jp      cbp_last
cbp_two:
        ld      a,(hl)
        rrca
        rrca
        ld      b,a
        and     0x3F
        or      c
        ld      (de),a
        inc     de
        ld      a,b
        and     0xC0
        ld      c,a
        inc     hl
        ld      a,(CBP_LEFT)
        dec     a
        ld      (CBP_LEFT),a
        jp      nz,cbp_two
cbp_last:
        ld      a,c
        ld      (de),a
        ret
; Shifted row straight into the staged stream (no left/right clip: B1_SKIP
; = 0, B1_WIDTH = stride + 1): each plane is shifted into every other byte
; of the stream (p0 at even, p1 at odd), no SPR_STRIP lane and no blit.
; HL = CSPR_SRC (plane 0 then plane 1, stride bytes each). The loop ends
; when L reaches the patched end (stride < 256).
cs_row_direct:
        ld      hl,(CSPR_CACHE_PTR)
        ex      de,hl
        ld      hl,(CSPR_SRC)
        push    de
        call    CSPR_PAIRS              ; plane 0 -> DE, DE+2, ...
        pop     de
        inc     de
        call    CSPR_PAIRS              ; plane 1 -> DE+1, DE+3, ...
        ld      (CSPR_SRC),hl
        ex      de,hl
        dec     hl                      ; DE stepped past the last pair
        ld      (CSPR_CACHE_PTR),hl
        jp      cs_row_advance

; One plane row (HL, CSPR_STRIDE bytes) shifted right by CSPR_SHIFT into
; DE, DE+2, ... (stride + 1 bytes). HL, DE end past the row.
CSPR_PAIRS:
        ld      a,(CSPR_STRIDE)
        add     a,l
        ld      c,a                     ; end of the plane row (low byte)
        ld      a,(CSPR_SHIFT)
        cp      4
        ld      a,c
        jp      z,cp_four
        jp      c,cp_two
        ld      (cp6_end+1),a
        ld      c,0
cp_six:
        ld      a,(hl)
        rlca
        rlca
        ld      b,a
        and     0x03
        or      c
        ld      (de),a
        inc     de
        inc     de
        ld      a,b
        and     0xFC
        ld      c,a
        inc     hl
        ld      a,l
cp6_end:
        cp      0                       ; patched
        jp      nz,cp_six
        jp      cp_last
cp_four:
        ld      (cp4_end+1),a
        ld      c,0
cp4_lp:
        ld      a,(hl)
        rrca
        rrca
        rrca
        rrca
        ld      b,a
        and     0x0F
        or      c
        ld      (de),a
        inc     de
        inc     de
        ld      a,b
        and     0xF0
        ld      c,a
        inc     hl
        ld      a,l
cp4_end:
        cp      0                       ; patched
        jp      nz,cp4_lp
        jp      cp_last
cp_two:
        ld      (cp2_end+1),a
        ld      c,0
cp2_lp:
        ld      a,(hl)
        rrca
        rrca
        ld      b,a
        and     0x3F
        or      c
        ld      (de),a
        inc     de
        inc     de
        ld      a,b
        and     0xC0
        ld      c,a
        inc     hl
        ld      a,l
cp2_end:
        cp      0                       ; patched
        jp      nz,cp2_lp
cp_last:
        ld      a,c
        ld      (de),a
        inc     de
        inc     de
        ret


; Hoop cache. The two hoops stand still and are staged into the same bytes
; frame after frame (~26k cycles each on the i8080). A hoop in the match
; keeps its staged rows in HOOP_CACHE (slot by X: left / right); the next
; call with the same record, X and Y copies them instead. The rectangle and
; the meta are made as always (CSPR_META_STAGE ran before). When the
; previous staging pass (HC_GEN - 1) left the same rows at the same stream
; address, they are still there: nothing is copied.
HC_SLOT         equ     202             ; record 2, X, Y, size 2, at 2, gen 2, rows 192
HC_ROWS         equ     192
SPR_TABLE       equ     0x7760          ; sprite record offsets from SPR_BASE
SPR_BASE        equ     0x415A

; Z and HL = this sprite's cache slot when it is a hoop in the match.
cs_cache_slot:
        ld      a,(COURT_SYNCED)
        or      a
        jp      z,ccs_no
        ld      hl,(SPR_TABLE + 2 * 62) ; first hoop record
        ld      de,SPR_BASE
        add     hl,de
        ex      de,hl
        ld      hl,(BLIT_SRC)
        ld      a,l
        sub     e
        ld      a,h
        sbc     a,d
        jp      c,ccs_no
        ld      hl,(SPR_TABLE + 2 * 72) ; first ball record
        ld      de,SPR_BASE
        add     hl,de
        ex      de,hl
        ld      hl,(BLIT_SRC)
        ld      a,l
        sub     e
        ld      a,h
        sbc     a,d
        jp      nc,ccs_no
        ld      hl,HOOP_CACHE
        ld      a,(BLIT_X)
        cp      64
        jp      c,ccs_yes
        ld      hl,HOOP_CACHE + HC_SLOT
ccs_yes:
        xor     a
        ret
ccs_no:
        ld      a,1
        or      a
        ret

; Z: the staged rows came from the cache (CSPR_CACHE_PTR moved past them).
CS_CACHE_FETCH:
        ld      hl,(CSPR_CACHE_PTR)
        ld      (CS_START),hl
        call    cs_cache_slot
        ret     nz
        ex      de,hl                   ; DE = slot
        ld      hl,(BLIT_SRC)
        ld      a,(de)
        cp      l
        ret     nz
        inc     de
        ld      a,(de)
        cp      h
        ret     nz
        inc     de
        ld      a,(BLIT_X)
        ld      b,a
        ld      a,(de)
        cp      b
        ret     nz
        inc     de
        ld      a,(BLIT_Y)
        ld      b,a
        ld      a,(de)
        cp      b
        ret     nz
        inc     de
        ex      de,hl
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        inc     hl                      ; HL = at, BC = size
        ld      a,(CSPR_CACHE_PTR)
        cp      (hl)
        jp      nz,ccf_copy
        inc     hl
        ld      a,(CSPR_CACHE_PTR+1)
        cp      (hl)
        jp      nz,ccf_copy1
        inc     hl                      ; same stream address: last pass?
        push    hl
        ld      hl,(HC_GEN)
        dec     hl
        ex      de,hl                   ; DE = HC_GEN - 1
        pop     hl
        ld      a,(hl)
        cp      e
        jp      nz,ccf_copy2
        inc     hl
        ld      a,(hl)
        cp      d
        jp      nz,ccf_copy3
        inc     de
        ld      (hl),d                  ; this pass keeps them
        dec     hl
        ld      (hl),e
        ld      hl,(CSPR_CACHE_PTR)
        add     hl,bc
        ld      (CSPR_CACHE_PTR),hl
        xor     a
        ret
ccf_copy:
        inc     hl
ccf_copy1:
        inc     hl
ccf_copy2:
        inc     hl
ccf_copy3:
        inc     hl                      ; HL = rows
        push    hl
        dec     hl
        dec     hl
        dec     hl
        dec     hl                      ; HL = at
        ex      de,hl
        ld      hl,(CSPR_CACHE_PTR)
        ex      de,hl
        call    hc_tag                  ; keeps DE = stream
        pop     hl                      ; HL = rows
        call    MEM_COPY
        ex      de,hl
        ld      (CSPR_CACHE_PTR),hl
        xor     a
        ret

; HL = a slot's at/gen tag <- DE (stream address) and this pass. Keeps DE.
hc_tag:
        ld      (hl),e
        inc     hl
        ld      (hl),d
        inc     hl
        ld      a,(HC_GEN)
        ld      (hl),a
        inc     hl
        ld      a,(HC_GEN+1)
        ld      (hl),a
        ret

; After staging rows: keep a hoop's rows for the next call.
CS_CACHE_STORE:
        call    cs_cache_slot
        ret     nz
        push    hl
        ld      hl,(CS_START)
        ld      a,(CSPR_CACHE_PTR)
        sub     l
        ld      c,a
        ld      a,(CSPR_CACHE_PTR+1)
        sbc     a,h
        ld      b,a                     ; BC = staged bytes
        pop     de                      ; DE = slot
        or      a
        ret     nz                      ; > 255: not kept
        ld      a,c
        cp      HC_ROWS + 1
        ret     nc
        ld      hl,(BLIT_SRC)
        ex      de,hl
        ld      (hl),e
        inc     hl
        ld      (hl),d
        inc     hl
        ld      a,(BLIT_X)
        ld      (hl),a
        inc     hl
        ld      a,(BLIT_Y)
        ld      (hl),a
        inc     hl
        ld      (hl),c
        inc     hl
        ld      (hl),b
        inc     hl
        ex      de,hl
        ld      hl,(CS_START)
        ex      de,hl                   ; DE = where the rows were staged
        call    hc_tag
        inc     hl
        ex      de,hl                   ; DE = rows, HL = staged rows
        jp      MEM_COPY

COLOR_SPRITE_CODE_END:

; Prepare one tile-row lookup; A returns byte displacement within the tile.
COURT_TILE_ROW_POINTER:
        ld a,l
        and 0xE0
        rrca
        rrca
        rrca
        rrca
        push af
        ld a,(0x0F1C)
        ld e,a
        ld d,h
        ld a,h
        ld hl,0x17B4
        cp (hl)
        jp nz,ctr_rebuild
        ld a,c
        rrca
        ld l,0xF5
        cp (hl)
        jp nz,ctr_rebuild
        ld a,e
        inc hl
        cp (hl)
        jp z,ctr_ready
ctr_rebuild:
        ld a,c
        rrca
        ld (0x17F5),a
        ld a,e
        ld (0x17F6),a
        ld a,d
        call COURT_TILE_CACHE
ctr_ready:
        ld l,0x74
        add hl,bc
        pop af
        ret
COLOR_CORE_END:
; DE = visible-plane byte (D = E0 + column, E = D7 - row). NZ when a current
; sprite rectangle covers it (players and static height-24 hoops: skipping
; only player slots let ball restores punch holes in unchanged rims). The
; slot whose remaining count equals PROTECT_SELF (written at
; PROTECT_SELF_OP+1, 0 = none) does not protect: its old rectangle is being
; erased. Returns A = (DE); keeps BC, DE, HL. Called for every restored byte.
PLAYER_BYTE_PROTECTED:
        ld      a,(DIRTY_COUNT)
        or      a
        jp      z,pbp_none
        push    bc
        push    hl
        push    de
        ld      a,d
        and     31
        ld      b,a                     ; B = column
        ld      a,0xD7
        sub     e
        ld      c,a                     ; C = row
        ld      a,(DIRTY_COUNT)
        ld      d,a                     ; D = slots left (count .. 1)
        ld      hl,DIRTY_LIST
pbp_rect:
        ld      a,d
PROTECT_SELF_OP:
        cp      0                       ; PROTECT_SELF immediate
        jp      z,pbp_skip0
        ld      a,b
        sub     (hl)                    ; dx = column - x
        jp      c,pbp_skip0
        inc     a
        ld      e,a                     ; E = dx + 1
        inc     hl
        inc     hl
        ld      a,(hl)
        and     0x7F                    ; width (bit 7 = unchanged mark)
        cp      e
        jp      c,pbp_skip2             ; width <= dx
        dec     hl
        ld      a,c
        sub     (hl)                    ; dy = row - y
        jp      c,pbp_skip1
        inc     hl
        inc     hl
        cp      (hl)
        jp      c,pbp_hit               ; dy < height
        jp      pbp_skip3
pbp_skip0:
        inc     hl
pbp_skip1:
        inc     hl
pbp_skip2:
        inc     hl
pbp_skip3:
        inc     hl
        dec     d
        jp      nz,pbp_rect
        pop     de
        pop     hl
        pop     bc
        xor     a                       ; Z: not covered
        ld      a,(de)
        ret
pbp_hit:
        pop     de
        pop     hl
        pop     bc
        or      0xFF                    ; NZ: covered
        ld      a,(de)
        ret
pbp_none:
        xor     a
        ld      a,(de)
        ret
; ============================================================================
;  Sprite records (tools/prepare_cpc_sprite_bank.py): canvas height, width,
;  top, kept rows, then only the kept rows. COLOR_SPRITE keeps the canvas
;  rectangle; ROW_SRC hands it a zero row above and below the kept ones.
; ============================================================================

CS_HEADER:
        ld      hl,(BLIT_SRC)
        ld      a,(hl)
        ld      (B1_HEIGHT),a
        inc     hl
        ld      a,(hl)                  ; width, returned in A
        inc     hl
        push    af
        ld      a,(hl)
        inc     hl
        ld      b,0x21                  ; LD HL,nn: plain rows
        or      a
        jp      p,csh_plain
        and     0x7F                    ; bit 7: mirror of the rows at the pointer
        ld      b,0xCD                  ; CALL MIR_ROW
csh_plain:
        ld      (CSPR_PRE),a
        ld      a,b
        ld      (cs_mirror),a
        ld      a,(hl)
        ld      (CSPR_KEEP),a
        inc     hl
        ld      a,b
        cp      0xCD
        jp      nz,csh_src
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a
csh_src:
        ld      (CSPR_SRC),hl           ; stored rows advance it themselves
        ld      hl,0
        ld      (CSPR_MNEXT),hl
        pop     af
        ret

; Row of a mirrored sprite: bit-reverse both stride-3 planes of the stored
; row into MIR_BUF and hand MIR_BUF to the row stage as CSPR_SRC. The
; stored cursor lives in CSPR_MNEXT (0 before the first row: CSPR_SRC,
; already advanced by a top clip).
MIR_ROW:
        ld      hl,(CSPR_MNEXT)
        ld      a,h
        or      l
        jp      nz,mr_go
        ld      hl,(CSPR_SRC)
mr_go:
        ld      b,MIR_REV >> 8
        ld      de,MIR_BUF+3            ; plane 0 backwards into MIR_BUF+2..0
        ld      c,(hl)
        inc     hl
        ld      a,(bc)
        dec     de
        ld      (de),a
        ld      c,(hl)
        inc     hl
        ld      a,(bc)
        dec     de
        ld      (de),a
        ld      c,(hl)
        inc     hl
        ld      a,(bc)
        dec     de
        ld      (de),a
        ld      de,MIR_BUF+6            ; plane 1 into MIR_BUF+5..3
        ld      c,(hl)
        inc     hl
        ld      a,(bc)
        dec     de
        ld      (de),a
        ld      c,(hl)
        inc     hl
        ld      a,(bc)
        dec     de
        ld      (de),a
        ld      c,(hl)
        inc     hl
        ld      a,(bc)
        dec     de
        ld      (de),a
        ld      (CSPR_MNEXT),hl
        ld      hl,MIR_BUF
        ld      (CSPR_SRC),hl
        ret

; Top clip: skip B canvas rows (stored ones advance the source by a row).
; Same counters as the COLOR_SPRITE row loop: CSPR_PRE first, then
; CSPR_KEEP going negative below the stored rows.
CS_SKIP_ROWS:
        ld      a,(CSPR_PRE)
        or      a
        jp      z,csk_kept
        dec     a
        ld      (CSPR_PRE),a
        jp      csk_next
csk_kept:
        ld      hl,CSPR_KEEP
        dec     (hl)
        jp      m,csk_next
        push    de
        ld      a,(CSPR_STRIDE)
        add     a,a
        ld      e,a
        ld      d,0
        ld      hl,(CSPR_SRC)
        add     hl,de
        ld      (CSPR_SRC),hl
        pop     de
csk_next:
        dec    b
        jp    nz,CS_SKIP_ROWS
        ret

CS_PRE_ROW:
        dec     a
        ld      (CSPR_PRE),a
; An empty canvas row: B1_WIDTH transparent (0,0) pairs into the stream.
CS_ZERO_ROW:
        ld      hl,(CSPR_CACHE_PTR)
        ld      a,(B1_WIDTH)
        ld      b,a
        xor     a
czr_pair:
        ld      (hl),a
        inc     hl
        ld      (hl),a
        inc     hl
        dec    b
        jp    nz,czr_pair
        ld      (CSPR_CACHE_PTR),hl
        jp      cs_row_advance

COLOR_CODE_END:
