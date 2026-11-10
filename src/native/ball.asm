; Ball per frame, the shot result, the baskets, hand i8080 (A2; model
; src/model/ball.js; Z80 8A23..8CF6).
; 8A23 ball step by state 93EB (bounce, flight 9A1B, rebound 9BF6) and the
;   possession icons (8CF7 contact, B455 HUD_ICON: HL = place, DE = 7750/7758);
; 8ADD ball and shadow, the shot result (chance 944D..9450 x random, A0B0);
; 8B26 hold point; 8BFE crowd "oh"; 8C16 made; 8C60 / 8C77 baskets.
; ix / iy cells are set where the Z80 sets them (9919, 8BFE, 8C16 read them).
; Contract: memory and the calls; no register outputs.
Z_8A23:
	ld a,(0x93EB)
	ld b,a
	and 5
	jp nz,bl_icons
	ld a,b
	and 2
	jp nz,bl_fly
	ld a,b
	and 8
	jp nz,bl_reb
	ld a,b
	and 0x10
	jp z,bl_icons
	ld hl,0x93F1
	ld (z80_ix),hl
	ld a,(0x93EF)
	rrca
	jp c,bl_down
	ld a,(hl)
	add a,6
	ld (hl),a
	ld b,a
	ld a,(0x93F3)
	ld c,a
	ld a,b
	cp c
	jp c,bl_icons
	ld (hl),c
	ld a,(0x93EF)
	or 1
	ld (0x93EF),a
	jp Z_8BFE
bl_down:
	ld a,(0x93F0)
	ld c,a
	ld a,(hl)
	cp c
	jp c,bl_d1
	sub 6
	ld (hl),a
	jp bl_icons
bl_d1:
	ld a,c
	add a,6
	ld c,a
	ld a,(0x93F3)
	ld b,a
	ld a,c
	cp b
	jp nc,bl_dead
	ld (0x93F0),a
	ld a,(0x93EF)
	and 0xFE
	ld (0x93EF),a
	jp bl_icons
bl_dead:
	xor a
	ld (0x93EB),a
	call Z_8BFE
	jp bl_icons
bl_reb:
	call Z_9BF6
	jp bl_icons
bl_fly:
	call Z_9A1B
bl_icons:
	ld hl,0x940B
	ld (z80_ix),hl
	ld hl,0x9425
	ld (z80_iy),hl
	ld hl,0x0690
	call bl_icon
	ld hl,0x9425
	ld (z80_ix),hl
	ld hl,0x940B
	ld (z80_iy),hl
	ld hl,0x1990
bl_icon:
	push hl
	call Z_8CF7
	ld de,0x7750
	ld hl,(z80_ix)
	inc hl
	ld a,(hl)
	jp nc,bl_i1
	or 0x40
	ld (hl),a
	pop hl
	jp HUD_ICON
bl_i1:
	and 0xBF
	ld (hl),a
	ld e,0x58
	pop hl
	jp HUD_ICON
Z_8ADD:
	ld hl,(0x93F3)
	ld a,l
	sub 4
	ld l,a
	ld (0x3300),hl
	ld a,0x49
	call Z_9E6F
	call Z_B01C
	ld hl,(0x93F3)
	ld a,(0x93EB)
	and 0x1A
	jp z,bl_b1
	ld hl,(0x93F1)
bl_b1:
	ld a,l
	sub 8
	ld l,a
	ld (0x3300),hl
	ld a,0x48
	call Z_9E6F
	call Z_B01C
	ld hl,0x93F5
	ld (z80_ix),hl
	ld a,(hl)
	and 2
	ret z
	ld (hl),0
	ld a,(0x93EB)
	ld b,a
	and 8
	jp z,bl_chance
	ld a,b
	and 0xE0
	or 0x10
	ld (0x93EB),a
Z_8B26:
	ld a,(0x93F1)
	add a,6
	ld (0x93F0),a
	xor a
	ld (0x93EF),a
	ld hl,0x93EF
	ret
bl_chance:
	ld a,(0x944F)
	ld bc,0x32
	ld de,0x46
	call bl_term
	push hl
	ld a,(0x9450)
	ld bc,0x23
	ld de,0x08
	call bl_term
	pop de
	add hl,de
	push hl
	ld a,(0x944E)
	cpl
	inc a
	add a,0x16
	ld bc,0x0A
	ld de,0x17
	call bl_term
	pop de
	add hl,de
	push hl
	ld a,(0x944D)
	cpl
	inc a
	add a,0x32
	ld bc,0x05
	ld de,0x32
	call bl_term
	pop de
	add hl,de
	call Z_A172
	add a,4
	ld c,l
	call Z_A0B0
	ld a,c
	rla
	ld c,a
	ld a,(0x93EB)
	and 0x80
	ld hl,0x9425
	ld de,0x940B
	jp z,bl_c1
	ex de,hl
bl_c1:
	ld (z80_ix),hl
	ex de,hl
	ld (z80_iy),hl
	ex de,hl
	ld a,(0x93D9)
	cp 3
	jp nz,bl_c2
	ld de,0x11
	call bl_inc
	jp bl_c4
bl_c2:
	cp 1
	jp nz,bl_c3
	ld de,0x0E
	call bl_inc
	jp bl_c4
bl_c3:
	ld de,0x0C
	add hl,de
	inc (hl)
	jp bl_c5
bl_c4:
	ld a,c
	rrca
	jp c,bl_c5
	inc hl
	inc (hl)
bl_c5:
	ld a,c
	rrca
	jp nc,Z_8C16
	ld a,(0x93EB)
	and 0xFD
	or 8
	ld (0x93EB),a
	ld hl,(z80_ix)
	dec hl
	dec hl
	dec hl
	ld a,(hl)
	sub 2
	jp nc,bl_c6
	xor a
bl_c6:
	ld (hl),a
	ld hl,(z80_iy)
	dec hl
	dec hl
	dec hl
	ld a,(hl)
	inc a
	cp 0x33
	jp z,bl_c7
	ld (hl),a
bl_c7:
	call Z_8BFE
	ld a,(0x93D6)
	and a
	ret z
	ld e,3
	jp Z_9919
; HL = A * BC / DE (398C, 39A3)
bl_term:
	ld l,a
	ld h,0
	push de
	call Z_398C
	pop bc
	jp Z_39A3
; (HL + DE)++ ; HL = that address
bl_inc:
	add hl,de
	inc (hl)
	ret
Z_8BFE:
	ld a,(0x93D8)
	and a
	ret nz
	inc a
	ld (0xAA83),a
	ld hl,2
	ld (0x3300),hl
	ld hl,0x8070
	ld (0x3302),hl
	jp Z_AA80
Z_8C16:
	ld a,(0x93D9)
	cp 2
	jp nz,bl_m1
	ld hl,(z80_ix)
	ld de,0x0D
	add hl,de
	inc (hl)
bl_m1:
	ld a,(0x93EB)
	and 0xFD
	or 4
	ld (0x93EB),a
	ld hl,0x93DC
	ld (0x93DA),hl
	ld hl,(z80_ix)
	dec hl
	dec hl
	dec hl
	ld a,(hl)
	add a,2
	cp 0x32
	jp c,bl_m2
	ld a,0x32
bl_m2:
	ld (hl),a
	ld hl,(z80_iy)
	dec hl
	dec hl
	dec hl
	ld a,(hl)
	and a
	jp z,bl_m3
	dec (hl)
bl_m3:
	ld hl,(z80_ix)
	ld a,(hl)
	and 0x20
	ret nz
	xor a
	ld (0xAA83),a
	ld hl,2
	ld (0x3300),hl
	ld hl,0x8039
	ld (0x3302),hl
	jp Z_AA80
Z_8C60:
	ld hl,0x9425
	ld (z80_ix),hl
	ld hl,0x0418
	ld de,0x9402
	call bl_bk
	ld hl,0x940B
	ld (z80_ix),hl
	ld hl,0x7018
	ld de,0x9401
bl_bk:
	push hl
	ld a,(0x93EB)
	ld b,a
	and 4
	ld a,0x3E
	jp z,bl_k9
	ld a,b
	rlca
	ld b,a
	ld hl,(z80_ix)
	inc hl
	ld a,(hl)
	xor b
	and 1
	ld a,0x3E
	jp nz,bl_k9
	ld hl,(0x93DA)
	ld a,(hl)
	inc hl
	ld (0x93DA),hl
	cp 0xFF
	jp nz,bl_k9
	ld a,0x2A
	ld (0x93F1),a
	add a,8
	ld (0x93F0),a
	xor a
	ld (0x93EF),a
	ld a,(0x93EB)
	and 0xFB
	or 0x10
	ld (0x93EB),a
	ld a,(0x9400)
	and a
	jp z,bl_k2
	and 0x80
	ld b,a
	ld a,(0x93EB)
	and 0x80
	xor b
	jp z,bl_k3
bl_k2:
	ld a,(0x93D9)
	ex de,hl
	add a,(hl)
	ld (hl),a
	ld a,(0x93D3)
	dec a
	call nz,Z_9FF2
	ld e,0x44
	call Z_9919
bl_k3:
	ld a,(0x93F4)
	ld h,a
	ld l,0x22
	ld (0x3300),hl
	ld a,0x48
	call Z_9E6F
	call Z_B01C
	ld a,0x42
bl_k9:
	pop hl
	ld (0x3300),hl
	ld b,a
	ld a,h
	and 0x40
	ld a,b
	jp z,bl_k10
	add a,5
bl_k10:
	call Z_9E6F
	jp Z_B01C
