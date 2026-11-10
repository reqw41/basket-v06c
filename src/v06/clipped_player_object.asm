; HL points to a changed staged object; PCC_RECT points to its rectangle.
; Return HL after the entire object, including clipped bytes.
; Clip once, then merge only the intersection into the complete player buffer.
; Scratch belongs to this non-reentrant, IRQ-disabled compositor.
PLAYER_COMPOSE_CLIPPED:
        push hl
        ld hl,(PCC_RECT)
        ld a,(hl)
        ld (pcc_rx),a
        inc hl
        ld a,(hl)
        ld (pcc_ry),a
        inc hl
        ld a,(hl)
        ld (pcc_rw),a
        inc hl
        ld a,(hl)
        ld (pcc_rh),a
        pop hl
        push hl
        push hl
        ld a,(pcc_rw)
        add a,a
        ld e,a
        ld d,0
        ld a,(pcc_rh)
        call MUL_DE_A           ; HL = 2w * h
        pop de
        add hl,de
        ex (sp),hl              ; full source end on stack, original HL restored
        ld (pcc_source),hl
        ld a,(pcc_rx)
        ld b,a
        ld a,(0x0F1A)
        cp b
        jp nc,pcc_left
        ld a,b
pcc_left:
        ld c,a                  ; first intersecting column
        sub b
        ld (pcc_left_skip),a
        ld a,(pcc_rw)
        add a,b
        ld b,a                  ; one past last source column
        ld a,(0x0F1A)
        ld hl,0x0F1C
        add a,(hl)
        cp b
        jp c,pcc_right
        ld a,b
pcc_right:
        sub c
        jp c,pcc_done
        jp z,pcc_done
        ld b,a
        add a,a
        ld (pcc_w2+1),a         ; row end offset (2 * width < 256)
        ld a,c
        ld hl,0x0F1A
        sub (hl)
        add a,a
        ld (pcc_dest_x),a
        ld a,(pcc_rw)
        sub b
        add a,a
        ld (pcc_spad+1),a
        or a
        ld hl,pcc_sx
        jp nz,pcc_sset
        ld hl,pcc_rdec          ; no source pad: skip its add
pcc_sset:
        ld (pcc_sj+1),hl
        ld a,(0x0F1C)
        sub b
        add a,a
        ld (pcc_dpad+1),a
        ld hl,pcc_row_loop      ; wider than 4 pairs: the row loop
        ld a,b
        cp 5
        jp nc,pcc_uset
        ld hl,pu_b4             ; up to 4 pairs: (4 - width) blocks in
        ld de,-PU_BLK
pcc_uloop:
        add hl,de
        dec b
        jp nz,pcc_uloop
pcc_uset:
        ld (pcc_row+1),hl
        ld (pcc_rjump+1),hl

        ld a,(pcc_ry)
        ld b,a
        ld a,(0x0F1B)
        cp b
        jp nc,pcc_top
        ld a,b
pcc_top:
        ld c,a                  ; first intersecting row
        sub b
        ld (pcc_top_skip),a
        ld a,(pcc_rh)
        add a,b
        ld b,a
        ld a,(0x0F1B)
        ld hl,0x0F1D
        add a,(hl)
        cp b
        jp c,pcc_bottom
        ld a,b
pcc_bottom:
        sub c
        jp c,pcc_done
        jp z,pcc_done
        ld (pcc_rdec+1),a
        ld a,c
        ld hl,0x0F1B
        sub (hl)
        ld b,a
        ld a,(0x0F1C)
        add a,a
        ld e,a
        ld d,0
        ld hl,(0x0F6D)
        call pcc_advance_rows
        ld a,(pcc_dest_x)
        ld e,a
        add hl,de
        ld (pcc_dest),hl

        ld a,(pcc_rw)
        add a,a
        ld e,a
        ld a,(pcc_top_skip)
        ld b,a
        ld hl,(pcc_source)
        call pcc_advance_rows
        ld a,(pcc_left_skip)
        add a,a
        ld e,a
        add hl,de
        ex de,hl                ; DE source, HL destination
        ld hl,(pcc_dest)
pcc_row:
        jp pcc_row_loop         ; patched: pcc_row_loop or a pu_b block
pcc_row_loop:
pcc_w2:
        ld a,0                  ; patched: 2 * width; the row ends when L
        add a,l                 ; reaches the patched end
        ld (pcc_row_end+1),a
pcc_col:
        ld a,(de)
        inc de
        ld c,a                  ; high destination colour bit
        ld a,(de)
        inc de
        ld b,a                  ; low destination colour bit
        or c
        jp z,pcc_clear          ; transparent pair: both bytes stay
        cpl
        and (hl)
        or b
        ld (hl),a
        inc hl
        ld a,b
        or c
        cpl
        and (hl)
        or c
        ld (hl),a
        inc hl
pcc_next:
        ld a,l
pcc_row_end:
        cp 0                    ; patched per row
        jp nz,pcc_col
pcc_dpad:
        ld bc,0                 ; patched: destination pad
        add hl,bc
pcc_sj:
        jp pcc_sx               ; patched: pcc_rdec when the source pad is 0
pcc_sx:
        ex de,hl
pcc_spad:
        ld bc,0                 ; patched: source pad
        add hl,bc
        ex de,hl
pcc_rdec:
        ld a,0                  ; patched: rows left
        dec a
        ld (pcc_rdec+1),a
pcc_rjump:
        jp nz,pcc_row           ; patched: the row entry itself
pcc_done:
        pop hl
        ret

pcc_clear:
        inc hl
        inc hl
        jp pcc_next

; Rows of up to 4 pairs (all the match sprites, <= 24 px): one block a pair,
; entered (4 - width) blocks in, no end test per pair (10.11).
pu_b0:
        ld a,(de)
        inc de
        ld c,a
        ld a,(de)
        inc de
        ld b,a
        or c
        jp z,pu_t0
        cpl
        and (hl)
        or b
        ld (hl),a
        inc hl
        ld a,b
        or c
        cpl
        and (hl)
        or c
        ld (hl),a
        inc hl
pu_b1:
        ld a,(de)
        inc de
        ld c,a
        ld a,(de)
        inc de
        ld b,a
        or c
        jp z,pu_t1
        cpl
        and (hl)
        or b
        ld (hl),a
        inc hl
        ld a,b
        or c
        cpl
        and (hl)
        or c
        ld (hl),a
        inc hl
pu_b2:
        ld a,(de)
        inc de
        ld c,a
        ld a,(de)
        inc de
        ld b,a
        or c
        jp z,pu_t2
        cpl
        and (hl)
        or b
        ld (hl),a
        inc hl
        ld a,b
        or c
        cpl
        and (hl)
        or c
        ld (hl),a
        inc hl
pu_b3:
        ld a,(de)
        inc de
        ld c,a
        ld a,(de)
        inc de
        ld b,a
        or c
        jp z,pu_t3
        cpl
        and (hl)
        or b
        ld (hl),a
        inc hl
        ld a,b
        or c
        cpl
        and (hl)
        or c
        ld (hl),a
        inc hl
pu_b4:
        jp pcc_dpad
pu_t0:
        inc hl
        inc hl
        jp pu_b1
pu_t1:
        inc hl
        inc hl
        jp pu_b2
pu_t2:
        inc hl
        inc hl
        jp pu_b3
pu_t3:
        inc hl
        inc hl
        jp pu_b4
PU_BLK  equ     pu_b1 - pu_b0
#assert pu_b4 - pu_b0 == 4 * PU_BLK

pcc_advance_rows:
        inc b
        dec b
        ret z
pcc_advance_loop:
        add hl,de
        dec b
        jp nz,pcc_advance_loop
        ret
PLAYER_CLIPPED_CODE_END:

; HL = DE * A (A = 0..255), unrolled from the top bit (10.11). Clobbers A;
; keeps BC, DE.
MUL_DE_A:
        ld hl,0
        REPT 8
        add hl,hl
        rla
        jp nc,$+4
        add hl,de
        ENDM
        ret
pcc_source:     dw 0
pcc_dest:       dw 0
pcc_left_skip:  db 0
pcc_top_skip:   db 0
pcc_dest_x:     db 0
pcc_rx:         db 0
pcc_ry:         db 0
pcc_rw:         db 0
pcc_rh:         db 0
PLAYER_CLIPPED_END:


; Fetch both CPC background bits. Match → court tiles @1800.
; Menu dirty restore: HL already points at TITLE_SRC — take low from (HL)
; and high:=0 (blue panel). MENU_PLANE_PAIR is far too heavy per pixel
; (oneFrame never finished, menu input starved).
; TITLE_SNAPPED (not COURT_SYNCED): match must never menu-invert stands.
PLAYER_BACKGROUND_ROW:
        ld a,(0x0FEF)
        or a
PBR_BG_SITE:
        jp z,BG_FETCH                     ; BG_FETCH (court or CPC stamp)
        xor a
        ld (0x0F59),a
        ld a,(hl)
        ret
PLAYER_BACKGROUND_ROW_END:

; ldir for the i8080: copy BC bytes (HL) -> (DE), none when BC = 0.
; Returns HL, DE past the bytes and BC = 0. Four bytes per loop pass.
MEM_COPY:
        ld a,c
        and 3
        jp z,mc_quads
        ld a,(hl)
        ld (de),a
        inc hl
        inc de
        dec bc
        jp MEM_COPY
mc_quads:
        ld a,b
        or c
        ret z
        ld a,b
        or a
        rra
        ld b,a
        ld a,c
        rra
        ld c,a
        ld a,b
        or a
        rra
        ld b,a
        ld a,c
        rra
        ld c,a                  ; BC = quads
mc_loop:
        ld a,(hl)
        ld (de),a
        inc hl
        inc de
        ld a,(hl)
        ld (de),a
        inc hl
        inc de
        ld a,(hl)
        ld (de),a
        inc hl
        inc de
        ld a,(hl)
        ld (de),a
        inc hl
        inc de
        dec bc
        ld a,b
        or c
        jp nz,mc_loop
        ret
MEM_COPY_END:
