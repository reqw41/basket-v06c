; Player walk step and ball follow, hand i8080 (A2; model src/model/walk.js;
; Z80 9C7C..9E6E). ix = player (z80_ix), iy = the other (z80_iy).
; Z_9C83: stick (ix-2) -> pose (ix-1), jump/shot -> 8E5A, action -> 8F76,
;   x/y step inside the court and around the other player, then 9ED4, 9DC2.
; Z_9DC2: the ball in hand follows the player (93F3); out = event 3,
;   back court = event 5 (9919).
; Contract: memory and the calls; no register outputs (callers 93BB/93BE
; go on with fresh registers). Clobbers everything.
Z_9C83:
	ld hl,(z80_ix)
	ld de,0xFFF9
	add hl,de
	ld (wk_p7),hl
	ld a,(hl)
	and 0xFE
	ld (hl),a
	ld hl,(z80_ix)
	ld a,(hl)
	rrca
	jp c,Z_8F76
	dec hl
	dec hl
	ld a,(hl)
	and 0x1F
	jp z,wk_idle
	inc hl
	ld b,(hl)
	cp 0x10
	jp z,Z_8E5A
	ld c,a
	inc hl
	ld a,(hl)
	and 0x10
	jp z,wk_gnd
	ld a,c
	and 0x10
	jp z,wk_pos
	ld a,c
	and 0xEF
	cp b
	jp z,Z_8E5A
	jp wk_st
wk_gnd:
	ld a,c
	and 0x10
	jp nz,Z_8E5A
	ld a,c
wk_st:
	ld c,a
	dec hl
	ld (hl),a
	inc hl
wk_pos:
	inc hl
	ld a,(hl)
	and 0xDF
	ld (hl),a
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl)
	ld hl,(z80_iy)
	inc hl
	inc hl
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a
	ex de,hl
	ld a,c
	rrca
	jp nc,wk_edge
	ld a,c
	and 2
	jp nz,wk_right
	ld a,l
	cp 0x41
	jp c,wk_edge
	call wk_neary
	jp nc,wk_lmov
	ld a,l
	inc a
	cp e
	jp c,wk_lmov
	sub 6
	cp e
	jp c,wk_xblk
wk_lmov:
	dec l
	call wk_rate
	jp nz,wk_edge
	dec l
	jp wk_edge
wk_right:
	ld a,l
	cp 0x6E
	jp nc,wk_edge
	call wk_neary
	jp nc,wk_rmov
	ld a,e
	inc a
	cp l
	jp c,wk_rmov
	sub 6
	cp l
	jp c,wk_xblk
wk_rmov:
	inc l
	call wk_rate
	jp nz,wk_edge
	inc l
	jp wk_edge
wk_xblk:
	call wk_set5
wk_edge:
	ld a,0x70
	ld c,a
	sub l
	or a
	rra
	or a
	rra
	inc a
	ld b,a
	cp h
	jp c,wk_e1
	ld a,h
	inc a
	cp b
	jp nc,wk_y
	ld a,0x0C
	jp wk_e2
wk_e1:
	cpl
	inc a
	add a,0x73
	ld c,a
	cp h
	jp nc,wk_y
	ld a,h
	dec a
	dec a
	cp c
	jp c,wk_y
	jp z,wk_y
	ld a,4
wk_e2:
	push hl
	ld hl,(z80_ix)
	dec hl
	dec hl
	ld (hl),a
	pop hl
wk_y:
	push hl
	ld hl,(z80_ix)
	dec hl
	dec hl
	ld a,(hl)
	pop hl
	ld (wk_t),a
	and 4
	jp z,wk_end
	ld a,(wk_t)
	and 8
	jp nz,wk_down
	ld a,b
	cp h
	jp nc,wk_set0
	call wk_nearx
	jp nc,wk_umov
	ld a,h
	cp d
	jp c,wk_umov
	sub 8
	cp d
	jp c,wk_yblk
wk_umov:
	dec h
	call wk_rate
	jp nz,wk_end
	dec h
	jp wk_end
wk_down:
	ld a,c
	cp h
	jp c,wk_set0
	call wk_nearx
	jp nc,wk_dmov
	ld a,d
	cp h
	jp c,wk_dmov
	sub 8
	cp h
	jp c,wk_yblk
wk_dmov:
	inc h
	call wk_rate
	jp nz,wk_end
	inc h
	jp wk_end
wk_yblk:
	call wk_set5
	jp wk_end
wk_set0:
	push hl
	ld hl,(wk_p7)
	ld a,(hl)
	or 1
	ld (hl),a
	pop hl
wk_end:
	ex de,hl
	ld hl,(z80_ix)
	inc hl
	inc hl
	ld (hl),e
	inc hl
	ld (hl),d
	call Z_9ED4
Z_9DC2:
	ld hl,(z80_ix)
	ld a,(hl)
	and 0x10
	ret z
	dec hl
	ld c,(hl)
	inc hl
	inc hl
	ld a,(hl)
	ld (wk_t),a
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl)
	ld b,d
	ex de,hl
	ld a,c
	and 4
	jp z,wk_f1
	ld a,c
	and 8
	jp z,wk_f3
	ld a,h
	add a,9
	ld h,a
	jp wk_f3
wk_f1:
	ld a,c
	and 2
	ld c,2
	jp nz,wk_f2
	ld c,0xFE
	ld a,h
	add a,9
	ld h,a
wk_f2:
	ld a,l
	add a,c
	ld l,a
wk_f3:
	ld (0x93F3),hl
	ld a,l
	cp 0x41
	jp c,wk_out
	cp 0x6E
	jp c,wk_in
wk_out:
	ld e,3
	jp Z_9919
wk_in:
	ld a,(wk_t)
	ld c,a
	and 0x10
	jp nz,wk_cr
	ld a,c
	rrca
	ld a,b
	jp nc,wk_i2
	cp 0x3E
	ret c
	jp wk_set4
wk_i2:
	cp 0x38
	ret nc
wk_set4:
	ld hl,(z80_ix)
	inc hl
	ld a,(hl)
	or 0x10
	ld (hl),a
	ret
wk_cr:
	ld a,c
	rrca
	ld a,b
	jp nc,wk_c2
	cp 0x3E
	ret nc
	jp wk_c3
wk_c2:
	cp 0x38
	ret c
wk_c3:
	ld e,5
	call Z_9919
	ld hl,(z80_ix)
	inc hl
	ld a,(hl)
	and 0xEF
	ld (hl),a
	ret
wk_idle:
	ld hl,(z80_ix)
	inc hl
	ld a,(hl)
	and 0xDF
	ld (hl),a
	jp Z_9E82
; CY = |d - h| < 6 (keeps BC DE HL)
wk_neary:
	ld a,d
	sub h
	jp nc,wk_ny1
	cpl
	inc a
wk_ny1:
	cp 6
	ret
; CY = |l - e| < 3
wk_nearx:
	ld a,l
	sub e
	jp nc,wk_nx1
	cpl
	inc a
wk_nx1:
	cp 3
	ret
; (ix+1) bit 5: blocked by the other player
wk_set5:
	push hl
	ld hl,(z80_ix)
	inc hl
	ld a,(hl)
	or 0x20
	ld (hl),a
	pop hl
	ret
; 9E47: NZ = no second pixel this step (keeps BC DE HL)
wk_rate:
	push hl
	push bc
	ld hl,(z80_ix)
	ld bc,0x0A
	add hl,bc
	ld a,(hl)
	and a
	jp nz,wk_r1
	ld bc,0xFFF1
	add hl,bc
	ld a,(hl)
	inc a
	and 1
	ld (hl),a
	pop bc
	pop hl
	ret
wk_r1:
	ld bc,0xFFF6
	add hl,bc
	ld a,(hl)
	and 0x10
	jp z,wk_rx
	ld a,(0x93EB)
	and 0x40
	jp z,wk_rx
	ld bc,0xFFFA
	add hl,bc
	dec (hl)
	jp nz,wk_rx
	ld a,(0x93EB)
	and 0xBF
	ld (0x93EB),a
	xor a
wk_rx:
	pop bc
	pop hl
	ret
wk_p7:
	dw 0
wk_t:
	db 0
