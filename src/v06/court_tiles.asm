        include "labels_court_tiles.inc"
COURT_TAIL equ 0x1600
; Lossless menu decoder; expands directly to E000..FFFF, no extra RAM.
        org 0x1710
RESTORE_BACKGROUND_PAIR:
        call PLAYER_BACKGROUND_ROW
        ld (de),a
        ld a,d
        sub 0x20
        ld d,a
        ld a,(0x0F59)
        ld (de),a
        ld a,d
        add a,0x20
        ld d,a
        ret
PAIR_BUFFER_OK:
        ld      a,(0x0F1C)
        ld      e,a
        ld      d,0
        ld      a,(0x0F1D)
        ld      b,a
        ld      hl,0
        or      a
        ret     z               ; height 0 → OK
pbo_mul:
        add     hl,de
        dec    b
        jp    nz,pbo_mul
        add     hl,hl           ; two planes
        ld      de,0x0501       ; 1281
        ld      a,l
        sub     e
        ld      a,h
        sbc     a,d             ; C if bytes < 1281
        sbc     a,a             ; FFh if OK, 00h if overflow
        cpl                     ; 00h if OK, FFh if overflow
        or      a               ; Z if OK
        ret
PAIR_BUFFER_OK_END:
#assert $ <= 0x1764               ; COURT_TILE_CACHE pointer table follows

; 1748..1763 free (former COURT_PAIR_OUT: wipe writer through RST 08).
; 1764..17B3 = COURT_TILE_CACHE pointer table (must stay free of code).

#assert $ <= 0x17B4               ; 17B4: COURT_TILE_ROW_POINTER cache cell
; 17B5..17EF free (former pair normalizer; 17B4, 17F5/17F6 are
; COURT_TILE_ROW_POINTER cache cells).

#assert $ <= 0x1800               ; the code above must not run into this org
        org 0x1800
; HL is the original virtual row-major court address 2500..32FF.
; Return low in A, high in F59. Preserve BC, DE, HL and index registers.
COURT_TILE_PAIR:
        push bc
        push de
        push hl
        ld a,l
        and 31
        add a,a
        ld c,a
        ld b,0
        ld a,l
        and 0xE0
        rrca
        rrca
        rrca
        rrca
        ld e,a
        ld d,h
        ld a,h
        ld hl,0x17B4
        cp (hl)
        jp nz,ct_rebuild
        ld a,c
        rrca
        ld hl,0x17F5
        sub (hl)
        jp c,ct_rebuild
        inc hl
        cp (hl)
        jp c,ct_ready
ct_rebuild:
        xor a
        ld (0x17F5),a
        ld a,32
        ld (0x17F6),a
        ld a,d
        call COURT_TILE_CACHE
ct_ready:
        ld d,0
        ld hl,0x1774
        add hl,bc
        ld c,(hl)
        inc hl
        ld b,(hl)
        ld h,b
        ld l,c
        add hl,de
        ld c,(hl)
        inc hl
        ld a,(hl)
        ld (0x0F59),a
        ld a,c
        pop hl
        pop de
        pop bc
        ret
; 1844..1850 free (former COURT_TILE_WRITE; A0BF wipe is wipe_native.asm).
#assert $ <= 0x1851               ; the code above must not run into this org
        org 0x1851
COURT_TILE_CACHE:
        push bc
        push de
        ld (0x17B4),a
        sub 0x25
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld a,(0x17F5)
        ld e,a
        ld d,0
        add hl,de
        ld bc,0x2500
        add hl,bc
        ld a,e
        add a,a
        add a,0x74
        ld e,a
        ld d,0x17
        ld a,(0x17F6)
        ld b,a
; Tile pointer = 26C0 + 16 * index (tiles from 3300 live at COURT_TAIL).
; The nibble swap of the index gives both bytes: low = (index << 4) + C0,
; high = 26 + (index >> 4) + carry (index < D3, so the carry stays in the
; low nibble). ~190 Vector cycles a tile (the 16-bit shifts: ~290).
ctc_next:
        ld a,(hl)
        rlca
        rlca
        rlca
        rlca
        ld c,a
        and 0xF0
        add a,0xC0
        ld (de),a
        inc de
        ld a,c
        adc a,0
        and 0x0F
        add a,0x26
        cp 0x33
        jp c,ctc_write
        sub 0x33-(COURT_TAIL>>8)
ctc_write:
        ld (de),a
        inc de
        inc hl
        dec b
        jp nz,ctc_next
        pop de
        pop bc
        ld hl,0x1774
        ret
COURT_TILES_CODE_END:

; Text glyph row on a blue HUD cell: refresh both bits as digits change.
; Preserve the glyph stream and screen column for the native caller.
; MSX text colour (D1BC, relocated 3424) 91h = light red: lit foul digits
; (9FC0) and score messages. MSX coloured them through the TMS colour table,
; which this port drops; here ink 91h is pink (both planes), else white.
TEXT_GLYPH_PAIR:
        ld (hl),a
        ld c,a
        ld a,(TEXT_COLOUR)
        cp 0x91
        ld a,0xFF
        jp z,tgp_high
        ld a,c
        cpl
tgp_high:
        ld c,a                  ; high-plane byte
        ld a,h
        sub 0x20                ; C000 plane (H bit 5 clear)
        ld h,a
        ld (hl),c
        add a,0x20
        ld h,a
        inc de
        dec l
        ret
TEXT_GLYPH_PAIR_END:
