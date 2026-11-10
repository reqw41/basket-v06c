; Pushing, events, steering, shot value, hand i8080 (A2; model src/model/move.js;
; Z80 98B3..9A1A). ix = player (z80_ix), iy = the other (z80_iy).
; 98B3 push iy by ix's stick; 98D9 bump when overlapping; 98F7 move iy by
; (C, B) and raise event 2 through 9919; 9919 event E (bit 7 = ix side),
; fouls count in ix+0B and print (9FC0); 994A stick -> pose; 99BC 93D9 = 1/2/3.
; Contract: memory and the calls; no register outputs.
Z_98B3:
	ld hl,(z80_iy)
	inc hl
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl)
	ld bc,0
	ld hl,(z80_ix)
	dec hl
	ld l,(hl)
	ld a,l
	and 1
	jp z,mv_p1
	ld c,0xFE
	ld a,l
	and 2
	jp z,mv_p1
	ld c,2
mv_p1:
	ld a,l
	and 4
	jp z,Z_98F7
	ld b,0xFF
	ld a,l
	and 8
	jp z,Z_98F7
	ld b,1
	jp Z_98F7
Z_98D9:
	ld hl,(z80_iy)
	inc hl
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl)
	ld hl,(z80_ix)
	inc hl
	inc hl
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a
	ld a,h
	sub d
	jp nc,mv_b1
	cpl
	inc a
mv_b1:
	cp 6
	ret nc
	ld a,l
	sub e
	jp nc,mv_b2
	cpl
	inc a
mv_b2:
	cp 3
	ret nc
Z_98F7:
	ld hl,(z80_iy)
	inc hl
	inc hl
	ld a,e
	add a,c
	ld (hl),a
	inc hl
	ld a,d
	add a,b
	ld (hl),a
	inc hl
	inc hl
	ld (hl),a
	ld e,2
	ld hl,(z80_iy)
	ld a,(hl)
	rrca
	jp c,Z_9919
	dec hl
	dec hl
	ld a,(hl)
	and 0x1F
	jp nz,Z_9919
	inc hl
	ld a,(hl)
	dec hl
	ld (hl),a
Z_9919:
	ld a,(0x9400)
	and a
	ret nz
	ld hl,(z80_ix)
	inc hl
	ld a,(hl)
	rrca
	jp nc,mv_e1
	ld a,e
	or 0x80
	ld e,a
mv_e1:
	ld a,e
	ld (0x9400),a
	ld a,0x14
	ld (0x9451),a
	ld a,e
	and 0x7F
	cp 2
	ret nz
	ld hl,(z80_ix)
	ld de,0x0B
	add hl,de
	ld a,(hl)
	cp 5
	ret z
	inc (hl)
	ld hl,(z80_ix)
	push hl
	ld hl,(z80_iy)
	push hl
	call Z_9FC0
	pop hl
	ld (z80_iy),hl
	pop hl
	ld (z80_ix),hl
	ret
Z_994A:
	ld hl,(z80_ix)
	inc hl
	ld a,(hl)
	and 0x0E
	ret nz
	dec hl
	dec hl
	dec hl
	ld a,(hl)
	and 0x0F
	ret z
	ld d,a
	inc hl
	ld c,(hl)
	ld a,d
	and 4
	jp z,mv_s8c
	ld a,c
	rrca
	jp nc,mv_s70
	ld a,d
	and 8
	jp z,mv_sae
	jp mv_s9d
mv_s70:
	ld a,d
	and 8
	jp nz,mv_s80
	ld a,c
	and 8
	ret z
	jp mv_s77
mv_s80:
	ld a,c
	and 8
	ret nz
	jp mv_s83
mv_s8c:
	ld a,c
	and 4
	jp z,mv_s96
	ld a,d
	and 2
	jp z,mv_s83
	jp mv_s77
mv_s96:
	ld a,d
	and 2
	jp nz,mv_sab
	ld a,c
	and 2
	ret z
	jp mv_s9d
mv_sab:
	ld a,c
	and 2
	ret nz
	jp mv_sae
mv_s77:
	ld (hl),3
	inc hl
	jp mv_r6
mv_s83:
	ld (hl),1
	inc hl
	jp mv_r6
mv_s9d:
	ld (hl),0x0C
	inc hl
	inc hl
	ld a,(hl)
	dec hl
	rrca
	ret nc
	jp mv_r6
mv_sae:
	ld (hl),4
	inc hl
	inc hl
	ld a,(hl)
	dec hl
	rrca
	ret c
mv_r6:
	ld a,(hl)
	and 0xBF
	ld (hl),a
	ret
Z_99BC:
	ld a,(0x93D6)
	ld c,1
	and a
	jp nz,mv_vf2
	ld c,3
	ld hl,(z80_ix)
	inc hl
	ld b,(hl)
	inc hl
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a
	cp 0x48
	jp c,mv_vf2
	cp 0x66
	jp nc,mv_vf2
	ld a,b
	rrca
	ld a,h
	jp nc,mv_vfd
	cp 0x52
	jp c,mv_vf2
	cp 0x58
	jp nc,mv_vf0
	ld a,l
	cp 0x4C
	jp nc,mv_vf7
	ld a,h
	cp 0x56
	jp c,mv_vf2
	jp mv_vf0
mv_vf7:
	cp 0x5E
	jp c,mv_vf0
	jp mv_vf2
mv_vfd:
	cp 0x24
	jp nc,mv_vf2
	cp 0x1E
	jp c,mv_vf0
	ld a,l
	cp 0x4C
	jp nc,mv_vf7
	ld a,h
	cp 0x22
	jp c,mv_vf0
	jp mv_vf2
mv_vf0:
	ld a,c
	and 0xFE
	ld c,a
mv_vf2:
	ld a,c
	ld (0x93D9),a
	ret
