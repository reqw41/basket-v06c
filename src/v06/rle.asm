; Compact resource RLE decoder.
; Stream: 01..7F literal count + bytes, 83..FF run count + byte, 00 end.
; Entry HL=packed source, DE=destination. Returns after the terminator.
RLE_UNPACK:
rle_next:
        ld      a,(hl)
        inc     hl
        or      a
        ret     z
        jp      m,rle_run
        ld      c,a
        ld      b,0
        call    MEM_COPY
        jp      rle_next
rle_run:
        and     0x7F
        ld      c,a
        ld      a,(hl)
        inc     hl
rle_run_byte:
        ld      (de),a
        inc     de
        dec     c
        jp      nz,rle_run_byte
        jp      rle_next
RLE_UNPACK_END:
