; Stamina bars and the match clock, hand i8080 (A2; model src/model/stamina.js;
; Z80 9E82..9F47, 9F60..9F99). ix = player (z80_ix).
; 9E82 / 9ED4: stamina back / down, one bar cell redrawn through 9F48 (02CE:
;   HL = row/col, C = tile); 9F25 both bars; 9F36 one bar of A half-cells
;   (the loop relies on 02CE keeping A B C HL, as the Z80 code does).
; 9F60 / 9F67: clock on / off (the ISR hook operand at Z_3705+1);
; 9F6E: the ISR clock, 50 frames = 1 s off 93E7..93E9, at 0:00 93E5 = 1.
; Contract: memory and the 02CE calls (HL, C); no register outputs.
Z_9E82:
	ld a,(0x93D6)
	and a
	ret nz
	ld a,(0x93D3)
	dec a
	ret z
	ld hl,(z80_ix)
	ld de,0x0A
	add hl,de
	ld a,(hl)
	cp 0x16
	ret nc
	dec hl
	ld b,1
	ld c,(hl)
	ld a,c
	and 0x80
	ld a,b
	jp z,su1
	ld a,c
	and 0x7F
	ld c,a
	ld a,b
	sub c
	jp nc,su0
	xor a
su0:
	ld c,a
	ld a,b
su1:
	inc c
	cp c
	jp nc,su2
	ld c,0
su2:
	ld (hl),c
	ret nc
	inc hl
	ld a,(hl)
	ld c,a
	inc a
	ld (hl),a
	ld e,0xEE
	jp st_cell
Z_9ED4:
	ld a,(0x93D6)
	and a
	ret nz
	ld a,(0x93D3)
	dec a
	ret z
	ld hl,(z80_ix)
	ld de,0x0A
	add hl,de
	ld a,(hl)
	and a
	ret z
	dec hl
	ld b,7
	ld c,(hl)
	ld a,c
	and 0x80
	ld a,b
	jp nz,sd1
	sub c
	jp nc,sd0
	xor a
sd0:
	ld c,a
	ld a,b
sd1:
	ld e,a
	ld a,c
	and 0x7F
	inc a
	ld c,a
	ld a,e
	cp c
	jp c,sd2
	ld a,c
	or 0x80
	ld (hl),a
	ret
sd2:
	ld (hl),0x80
	inc hl
	ld a,(hl)
	dec a
	ld (hl),a
	inc a
	ld c,a
	ld e,0
; bar cell: C = level (before the change), E = tile for an odd level
; (EE up / 00 down); even: E0 (down: one cell to the left)
st_cell:
	ld hl,(z80_ix)
	inc hl
	ld a,(hl)
	ld hl,0x1001
	rrca
	jp c,st_c1
	ld l,0x14
st_c1:
	ld a,c
	or a
	rra
	add a,l
	ld l,a
	ld a,c
	ld c,e
	rrca
	jp c,st_c2
	ld c,0xE0
	ld a,e
	or a
	jp z,st_c3
	inc l
st_c3:
	dec l
st_c2:
	jp Z_9F48
Z_9F25:
	ld hl,0x1001
	ld a,(0x9415)
	ld c,0xEE
	call Z_9F36
	ld hl,0x1014
	ld a,(0x942F)
Z_9F36:
	and a
	ret z
	ld b,a
	ld a,b
	or a
	rra
	ld e,a
	ld a,b
	ld b,e
	inc b
	dec b
	jp z,st_b2
st_b1:
	call Z_9F48
	inc l
	dec b
	jp nz,st_b1
st_b2:
	rrca
	ret nc
	ld c,0xE0
	jp Z_9F48
Z_9F60:
	ld hl,Z_9F6E
	ld (Z_3705+1),hl
	ret
Z_9F67:
	ld hl,Z_9F6D
	ld (Z_3705+1),hl
Z_9F6D:
	ret
Z_9F6E:
	call Z_3715
	ld a,(0x93E6)
	inc a
	cp 0x32
	jp c,st_k1
	xor a
st_k1:
	ld (0x93E6),a
	ret c
	ld a,0x2F
	ld hl,0x93E9
	dec (hl)
	cp (hl)
	ret nz
	ld (hl),0x39
	dec hl
	dec (hl)
	cp (hl)
	ret nz
	ld (hl),0x35
	dec hl
	dec (hl)
	cp (hl)
	ret nz
	ld a,1
	ld (0x93E5),a
	jp Z_9F67
