; Convert an aligned source row directly to the interleaved staged stream.
; Source advances by two full plane strides even when the visible row clips.
; i8080: HL plane 0, BC plane 1, DE stream; the row ends when L reaches the
; patched end (width < 256). Unit adapter_hi.asm.
STAGE_ALIGNED_ROW:
        ld hl,(CSPR_SRC)
        ld a,(CSPR_STRIDE)
        ld c,a
        ld b,0
        ex de,hl                ; DE = plane 0 row
        ld h,b
        ld l,c
        add hl,hl
        add hl,de
        ld (CSPR_SRC),hl        ; next row: two full plane strides
        ld a,(B1_SKIP)
        ld l,a
        ld h,b
        add hl,de               ; HL = plane 0 + skip
        push hl
        add hl,bc
        ld b,h
        ld c,l                  ; BC = plane 1 + skip
        pop hl
        ld a,(B1_WIDTH)
        add a,l
        ld (sar_end+1),a        ; L after the last byte
        ex de,hl
        ld hl,(CSPR_CACHE_PTR)
        ex de,hl                ; DE = staged stream
sar_byte:
        ld a,(hl)
        ld (de),a
        inc de
        ld a,(bc)
        ld (de),a
        inc de
        inc hl
        inc bc
        ld a,l
sar_end:
        cp 0                    ; patched per row
        jp nz,sar_byte
        ex de,hl
        ld (CSPR_CACHE_PTR),hl
        ret
STAGE_ALIGNED_ROW_END:

