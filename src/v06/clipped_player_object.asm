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
        ld a,(0x0F1C)
        sub b
        add a,a
        ld (pcc_dpad+1),a

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
        ld (pcc_rows),a
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
        ex de,hl
pcc_spad:
        ld bc,0                 ; patched: source pad
        add hl,bc
        ex de,hl
        ld a,(pcc_rows)
        dec a
        ld (pcc_rows),a
        jp nz,pcc_row
pcc_done:
        pop hl
        ret

pcc_clear:
        inc hl
        inc hl
        jp pcc_next

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

; HL = DE * A by shifts (A = 0..255). Clobbers A, DE.
MUL_DE_A:
        ld hl,0
mda_loop:
        or a
        ret z
        rra                     ; CY = low bit (CY was 0: OR A)
        jp nc,mda_skip
        add hl,de
mda_skip:
        ex de,hl
        add hl,hl
        ex de,hl
        jp mda_loop
pcc_source:     dw 0
pcc_dest:       dw 0
pcc_left_skip:  db 0
pcc_top_skip:   db 0
pcc_dest_x:     db 0
pcc_rows:       db 0
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
