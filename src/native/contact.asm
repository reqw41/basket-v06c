; Contact tests, hand i8080 (A2; model src/model/contact.js; Z80 8CF7..8E59).
; Z_8CF7: ix = mover (z80_ix), iy = the other (z80_iy), ball state 93EB.
; Out: CY = contact. Clobbers A BC DE HL; memory: only the ct_ cells.
; (Callers: 8AAE reads CY only.)
Z_8CF7:
	ld hl,(z80_ix)
	ld a,(hl)
	ld (ct_x0),a
	inc hl
	ld a,(hl)
	ld (ct_x1),a
	dec hl
	dec hl
	ld a,(hl)
	ld (ct_px),a
	ld hl,(z80_iy)
	ld a,(hl)
	ld (ct_y0),a
	dec hl
	ld a,(hl)
	ld (ct_py),a
	ld a,(0x93EB)
	ld b,a
	and 0x20
	jp nz,ct_held
	ld a,b
	rrca
	jp c,ct_loose
	ld a,b
	and 0x04
	jp nz,ct_held
	ld a,b
	and 0x02
	jp nz,ct_e2
	ld a,b
	and 0x08
	jp z,ct_n8
	ld c,0xE6
	ld a,(ct_x0)
	rrca
	jp nc,ct_hand
	jp ct_e2
ct_n8:
	ld a,b
	and 0x10
	jp z,ct_ball
	ld a,(ct_x0)
	rrca
	jp nc,ct_ball
ct_e2:
	ld c,0xE2
ct_hand:
	ld hl,(0x93F1)
	jp ct_with
ct_held:
	ld a,(ct_x0)
	and 0x10
	add a,0xF0
	ret
ct_loose:
	ld a,(ct_x0)
	and 0x10
	jp z,ct_l1
	scf
	ret
ct_l1:
	ld hl,(0x93F3)
	ld c,0
	ld a,(ct_y0)
	rrca
	jp nc,ct_with
	push hl
	ld hl,(z80_iy)
	inc hl
	inc hl
	inc hl
	inc hl
	ld a,(hl)
	pop hl
	ld l,a
ct_with:
	push hl
	push bc
	call ct_ball
	pop bc
	pop hl
	ret nc
	ex de,hl
	ld hl,(z80_ix)
	inc hl
	inc hl
	ld a,(ct_x0)
	rrca
	jp nc,ct_w1
	inc hl
	inc hl
ct_w1:
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a
	ex de,hl
	ld a,(ct_y0)
	rrca
	jp nc,ct_box
	ld a,l
	sub e
	jp nc,ct_w2
	cpl
	inc a
	add a,a
ct_w2:
	cpl
	inc a
	add a,c
	ld c,a
	jp ct_box
ct_ball:
	ld hl,(z80_ix)
	inc hl
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl)
	ld hl,(0x93F3)
	ld c,0
ct_box:
	ld a,e
	add a,c
	ld e,a
	ld a,(ct_px)
	and 0x04
	jp z,ct_low
	ld c,8
	ld b,4
	ld a,(ct_y0)
	and 0x10
	jp z,ct_hi2
	ld c,6
	ld a,(ct_py)
	and 0x04
	jp z,ct_hib
	ld b,3
	ld a,(ct_py)
	and 0x08
	jp nz,ct_hia
	ld b,6
	ld a,(ct_px)
	and 0x08
	jp nz,ct_hi2
	dec b
	jp ct_hi2
ct_hia:
	ld a,(ct_px)
	and 0x08
	jp z,ct_hi2
	inc b
	jp ct_hi2
ct_hib:
	ld b,6
	ld c,b
	ld a,(ct_py)
	and 0x02
	jp nz,ct_hi2
	ld b,4
	inc c
ct_hi2:
	ld a,d
	add a,b
	ld d,a
	ld a,(ct_px)
	and 0x08
	jp z,ct_hi3
	ld a,d
	ld d,h
	ld h,a
ct_hi3:
	ld a,d
	sub h
	cp c
	ret nc
	ld a,e
	add a,4
	sub l
	cp 9
	ret
ct_low:
	ld c,6
	ld a,e
	ld b,a
	ld a,(ct_y0)
	and 0x10
	ld a,b
	jp z,ct_l37
	ld a,(ct_py)
	and 0x04
	jp z,ct_lo2
	ld a,b
	dec a
	dec c
	ld b,a
	ld a,(ct_px)
	and 0x02
	ld a,b
	jp z,ct_l30
	dec a
ct_l30:
	ld b,a
	ld a,(ct_x1)
	rrca
	ld a,b
	jp c,ct_l37
	inc a
	jp ct_l37
ct_lo2:
	ld a,(ct_py)
	and 0x02
	jp z,ct_lo3
	ld c,3
	ld a,b
	add a,4
	ld e,a
	ld a,(ct_px)
	and 0x02
	jp nz,ct_l27
	ld a,e
	add a,4
	ld e,a
	ld c,4
	ld a,(ct_x1)
	rrca
	ld a,e
	jp c,ct_l40
	inc c
	jp ct_l40
ct_lo3:
	ld c,5
	ld a,b
	add a,2
	ld e,a
	ld a,(ct_px)
	and 0x02
	jp nz,ct_l27
	ld a,e
	add a,4
	ld e,a
	ld c,2
	ld a,(ct_x1)
	rrca
	ld a,e
	jp c,ct_l40
	inc c
	jp ct_l40
ct_l27:
	ld a,(ct_x1)
	rrca
	jp c,ct_l44
	dec c
	jp ct_l44
ct_l37:
	add a,6
	ld e,a
	ld b,a
	ld a,(ct_px)
	and 0x02
	ld a,b
	jp nz,ct_l44
ct_l40:
	sub 0x0A
	ld e,l
	ld l,a
ct_l44:
	ld a,e
	sub l
	cp c
	ret nc
	ld a,d
	add a,0x0D
	ld b,a
	ld c,0x10
	ld a,(ct_px)
	and 0x02
	ld a,b
	jp z,ct_l57
	ld c,0x0E
	sub 2
ct_l57:
	sub h
	cp c
	ret
ct_x0:
	db 0
ct_x1:
	db 0
ct_px:
	db 0
ct_y0:
	db 0
ct_py:
	db 0
