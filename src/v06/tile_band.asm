; COMPOSE_BOX tile fill: rows of one tile band in a single call.
; In the low adapter (glue) since 09.11: it outgrew its slot before 84D0.
; C = tile row offset (even), DE = buffer row, (DP_CUR) = the band's tile
; pointers (2 bytes a column). Patched by COMPOSE_BOX: TBF_WIDTH+1 = 2 x width
; (table bytes = buffer row bytes); by cb_row: TBF_END+1 = offset after the
; last row.
; Column by column (10.11): a column's tile pointer is read once, its rows go
; down the buffer through an unrolled 8-row block entered at (8 - rows); a
; pair costs 68 cycles against ~140 row by row. IRQs stay on, no SP walk.
; Returns DE past the rows, C = TBF_END. Clobbers A, B, HL.
DP_CUR_TBF      equ     0x0F69          ; damage_publish DP_CUR: tile pointers of the band
TILE_BAND_FILL:
        ld a,c
        ld (tbf_off+1),a
TBF_END:
        ld a,0                  ; patched per call: offset after the last row
        sub c                   ; 2 x rows (2..16)
        ld b,a
        ld a,16
        sub b
        add a,a
        add a,a                 ; (8 - rows) x 8 bytes of the row block
        add a,tbf_r8 & 255
        ld (tbf_jmp+1),a
        ld hl,(DP_CUR_TBF)
        ld (tbf_tab+1),hl
TBF_WIDTH:
        ld a,0                  ; patched: 2 x width
        add a,l
        ld (tbf_stop+1),a       ; low byte just past the table
        ld a,e                  ; delta = buffer row - table - 2: the
        sub l                   ; column's buffer address from the table
        ld l,a                  ; cursor past its entry
        ld a,d
        sbc a,h
        ld h,a
        dec hl
        dec hl
        ld (tbf_delta+1),hl
        ld a,(TBF_WIDTH+1)
        dec a
        ld l,a
        ld h,0
        ld (tbf_stride+1),hl    ; 2 x width - 1: next row, same column
tbf_col:
tbf_tab:
        ld hl,0                 ; table cursor
        ld a,(hl)
tbf_off:
        add a,0                 ; row offset; tile banks are 16-aligned
        ld c,a
        inc hl
        ld b,(hl)
        inc hl
        ld (tbf_tab+1),hl
tbf_delta:
        ld de,0
        add hl,de               ; HL = this column's first buffer pair
tbf_stride:
        ld de,0
tbf_jmp:
        jp tbf_r8               ; patched low byte: the first row
tbf_r8:
        REPT 8
        ld a,(bc)
        ld (hl),a
        inc c
        inc hl
        ld a,(bc)
        ld (hl),a
        inc c
        add hl,de
        ENDM
        ld a,(tbf_tab+1)
tbf_stop:
        cp 0                    ; patched: end of the table
        jp nz,tbf_col
        ld a,l                  ; HL = row + rows x 2w + (2w - 2):
        sub e                   ; DE = HL - (2w - 1) + 1
        ld e,a
        ld a,h
        sbc a,d
        ld d,a
        inc de
        ld a,(TBF_END+1)
        ld c,a
        ret
#assert ((tbf_r8 + 56) >> 8) == (tbf_r8 >> 8)   ; tbf_jmp patches the low byte only
#assert (tbf_r8 & 255) + 56 < 256
