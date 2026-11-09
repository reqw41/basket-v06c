; COMPOSE_BOX tile fill: rows of one tile band in a single call.
; In the low adapter (glue) since 09.11: it outgrew its slot before 84D0.
; C = tile row offset (even), DE = buffer row, (DP_CUR) = the band's tile
; pointers (2 bytes a column). Patched by COMPOSE_BOX: TBF_WIDTH+1 = 2 x width
; (table bytes), TBF_ENTRY+1 = tbf_first (even width) or tbf_second (odd,
; low byte only); by cb_row: TBF_END+1 = offset after the last row.
; IRQs stay on (09.11): HL walks the table, BC is the tile pointer, the row
; offset is written into the two ADD A,n. The former SP walk under DI lost
; ~7% of the frame IRQs in a match (match clock, music).
; Returns DE past the rows, C = TBF_END. Clobbers A, B, HL.
DP_CUR_TBF      equ     0x0F69          ; damage_publish DP_CUR: tile pointers of the band
TILE_BAND_FILL:
        ld hl,(DP_CUR_TBF)
        ld a,l
TBF_WIDTH:
        add a,0                 ; patched: table bytes of the box width
        ld (tbf_stop+1),a       ; low byte just past the table
        ld a,c
tbf_row:
        ld (tbf_off1+1),a
        ld (tbf_off2+1),a
        ld hl,(DP_CUR_TBF)
TBF_ENTRY:
        jp tbf_first            ; patched: tbf_second for an odd width
tbf_first:
        ld a,(hl)
tbf_off1:
        add a,0                 ; row offset; tile banks are 16-aligned
        ld c,a
        inc hl
        ld b,(hl)
        inc hl
        ld a,(bc)
        ld (de),a
        inc de
        inc c
        ld a,(bc)
        ld (de),a
        inc de
tbf_second:
        ld a,(hl)
tbf_off2:
        add a,0
        ld c,a
        inc hl
        ld b,(hl)
        inc hl
        ld a,(bc)
        ld (de),a
        inc de
        inc c
        ld a,(bc)
        ld (de),a
        inc de
        ld a,l
tbf_stop:
        cp 0                    ; patched: end of the table
        jp nz,tbf_first
        ld a,(tbf_off1+1)
        add a,2
TBF_END:
        cp 0                    ; patched per call
        jp nz,tbf_row
        ld c,a
        ret
#assert (tbf_first >> 8) == (tbf_second >> 8)   ; COMPOSE_BOX patches the low byte only
