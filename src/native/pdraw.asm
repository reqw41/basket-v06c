; Player update and draw, hand i8080 (A2; model src/model/pdraw.js;
; Z80 958F..98B2, 9E6F..9E81). ix = player (z80_ix), iy = the other.
; Frames: 9E6F sets BLIT_SRC 3302 from the frame in A (table 7760, base 415A);
; BLIT_Y 3300 = position; B01C draws (01E9 reads 3300..3303 only).
; Contract: memory and the calls; no register outputs.
Z_958F:
	ld hl,0x9425
	ld (z80_ix),hl
	ld hl,0x940B
	ld (z80_iy),hl
	jp Z_95A1
Z_9599:
	ld hl,0x940B
	ld (z80_ix),hl
	ld hl,0x9425
	ld (z80_iy),hl
Z_95A1:
	call pd_pose
	ld a,(pd_x0)
	and 0x20
	jp nz,pd_jump
	ld a,e
	and 0x20
	jp nz,pd_shot
	ld a,(pd_x0)
	and 0x80
	jp nz,pd_shot
	ld a,e
	and 0x40
	jp nz,pd_ball
	ld a,(pd_x0)
	rrca
	jp c,pd_ball
	ld hl,(z80_ix)
	ld de,0x9442
	ld a,1
	ld (pd_e),a
	ld a,(pd_m2)
	and 0x1F
	jp nz,pd_w1
	ld a,(pd_x0)
	and 0x10
	ld a,0
	jp z,pd_w3
	ld a,(hl)
	or 4
	ld (hl),a
	ld de,0x9446
	xor a
	ld (pd_e),a
	jp pd_w2
pd_w1:
	ld a,(pd_x0)
	and 4
	jp z,pd_w2
	ld a,(hl)
	and 0xFB
	ld (hl),a
	call pd_ix6
	ld a,(hl)
	dec a
	or 1
	jp pd_w4
pd_w2:
	call pd_ix6
	ld a,(hl)
	jp pd_w4
pd_w3:
	call pd_ix6
pd_w4:
	inc a
	and 3
	ld (hl),a
	inc hl
	ex de,hl
	add a,l
	ld l,a
	ld a,h
	adc a,0
	ld h,a
	ld a,(hl)
	ld (de),a
	ld hl,0x944A
	add a,l
	ld l,a
	ld a,h
	adc a,0
	ld h,a
	ld b,(hl)
	ld hl,(z80_ix)
	inc hl
	inc hl
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a
	ld a,(pd_e)
	or a
	ld a,b
	jp nz,pd_w5
	ld a,0xDB
pd_w5:
	add a,l
	ld l,a
	push hl
	call pd_body
	call pd_pose
	pop hl
	ld a,b
	and 4
	jp z,pd_w6
	ld a,0x0A
	call pd_b3c
	jp pd_w7
pd_w6:
	ld a,0x22
	call pd_nb1c
pd_w7:
	call pd_side
	ld b,a
	ld a,(pd_x0)
	and 0x10
	ld a,b
	call nz,pd_cpose
	jp pd_blit
; 9652: body/legs frame and the head-in-hand check (94A7)
pd_body:
	call pd_pose
	ld hl,(z80_ix)
	inc hl
	inc hl
	ld a,(hl)
	sub 0x1C
	inc hl
	ld h,(hl)
	ld l,a
	ld (0x3300),hl
	ld hl,(z80_ix)
	ld de,7
	add hl,de
	ld a,(hl)
	ld d,a
	ld a,(pd_x0)
	and 0x10
	ld a,d
	jp z,pd_b1
	add a,3
pd_b1:
	ld d,a
	ld a,b
	and 4
	ld a,d
	jp z,pd_b2
	call pd_b3c
	jp pd_b4
pd_b2:
	add a,0x18
	call pd_nb1c
pd_b4:
	ld (pd_fr),a
	call Z_9E6F
	call Z_B01C
	ld a,(pd_fr)
	ld d,a
	ld hl,0x94A7
pd_b5:
	ld a,(hl)
	inc hl
	and a
	ret z
	cp d
	jp nz,pd_b5
	ld a,(0x93EB)
	or 0x40
	ld (0x93EB),a
	ld hl,(z80_ix)
	ld de,0xFFFA
	add hl,de
	ld (hl),3
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
; 96BC: contact pose; A = frame in/out, may take one from L
pd_cpose:
	ld c,a
	ld a,(pd_x0)
	and 4
	ld a,c
	ret nz
	push hl
	ld hl,(z80_ix)
	inc hl
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl)
	ld hl,(z80_iy)
	inc hl
	inc hl
	inc hl
	ld a,d
	sub (hl)
	ld b,0x0A
	jp nc,pd_c1
	ld b,0x16
	cpl
	inc a
pd_c1:
	cp 6
	jp nc,pd_c9
	dec hl
	ld a,e
	sub (hl)
	jp nc,pd_c2
	cpl
	inc a
pd_c2:
	cp 0x0A
	jp nc,pd_c9
	pop hl
	ld a,(pd_x1)
	rrca
	jp nc,pd_c3
	inc b
pd_c3:
	ld a,b
	cp c
	ret z
	ld a,(pd_px)
	and 4
	ld a,b
	ret nz
	ld a,(pd_px)
	and 2
	ld a,c
	ret z
	ld a,(pd_x1)
	rrca
	ld a,b
	ret nc
	dec l
	ret
pd_c9:
	pop hl
	ld a,c
	ret
; 9705: with the ball: arm and the ball in hand, in pose order
pd_ball:
	ld a,b
	and 6
	jp z,pd_bl1
	call pd_hand
	jp pd_arm
pd_bl1:
	call pd_arm
pd_hand:
	call pd_pose
	ld hl,(z80_ix)
	inc hl
	inc hl
	inc hl
	inc hl
	ld a,(hl)
	sub 0x25
	inc hl
	ld h,(hl)
	ld l,a
	ld a,b
	and 4
	ld a,0x0A
	jp z,pd_h1
	call pd_b3c
	jp pd_h2
pd_h1:
	add a,0x18
	call pd_nb1c
pd_h2:
	call pd_side
	jp pd_blit
pd_arm:
	call pd_pose
	ld hl,(z80_ix)
	inc hl
	inc hl
	inc hl
	inc hl
	ld a,(hl)
	sub 0x24
	inc hl
	ld h,(hl)
	ld l,a
	ld a,(pd_x0)
	and 0x10
	ld a,9
	jp z,pd_a1
	dec a
pd_a1:
	ld d,a
	ld a,b
	and 4
	ld a,d
	jp z,pd_a2
	ld a,b
	and 8
	ld a,d
	jp z,pd_blit
	add a,0x0C
	inc h
	jp pd_blit
pd_a2:
	add a,0x24
	ld d,a
	ld a,b
	and 2
	ld a,d
	jp z,pd_blit
	sub 0x0C
	jp pd_blit
; 978A: shot pose; the second frame releases the ball (90EF)
pd_shot:
	ld hl,(z80_ix)
	inc hl
	inc hl
	inc hl
	inc hl
	ld a,(hl)
	sub 0x24
	inc hl
	ld h,(hl)
	ld l,a
	ld a,(pd_x1)
	rrca
	jp nc,pd_s1
	dec h
	dec h
pd_s1:
	ld (0x3300),hl
	ld hl,(z80_ix)
	ld de,7
	add hl,de
	ld a,(hl)
	add a,0x36
	ld d,a
	ld a,b
	and 2
	ld a,d
	jp nz,pd_s2
	add a,2
pd_s2:
	ld d,a
	ld a,(pd_x1)
	rrca
	ld a,d
	jp nc,pd_s3
	add a,4
pd_s3:
	call Z_9E6F
	call Z_B01C
	ld hl,(z80_ix)
	ld de,7
	add hl,de
	ld a,(hl)
	inc a
	and 1
	ret z
	ld (hl),a
	jp Z_90EF
; 97D6: the ball goes loose (84DC -> 8C16)
pd_loose:
	ld a,(pd_x1)
	rrca
	ld a,0
	jp nc,pd_l1
	ld a,0x80
pd_l1:
	ld (0x93EB),a
	ld a,(0x9400)
	and a
	ld a,0
	jp nz,pd_l2
	ld hl,(z80_ix)
	ld de,0x0C
	add hl,de
	inc (hl)
	ld a,2
pd_l2:
	ld (0x93D9),a
	jp Z_8C16
; 97F5: jump / dunk frames (C is the Z80 counter: after 97D6 it is what 8C16 leaves)
pd_jump:
	ld hl,(z80_ix)
	inc hl
	inc hl
	inc hl
	inc hl
	ld a,(hl)
	sub 0x24
	inc hl
	ld h,(hl)
	dec h
	ld l,a
	ld (0x3300),hl
	ld c,2
	ld a,(pd_x0)
	and 0x40
	jp nz,pd_j1
	dec c
pd_j1:
	ld a,(pd_x0)
	and 2
	jp nz,pd_j5
	dec c
	ld a,(0x93EB)
	and 4
	jp nz,pd_dunk
	ld a,(pd_x0)
	and 0x40
	ld a,l
	jp z,pd_j2
	cp 0x22
	jp nc,pd_ball
	call pd_loose
	call pd_pose
	jp pd_ball
pd_j2:
	cp 0x22
	jp nc,pd_ball
	ld d,a
	ld hl,(z80_ix)
	inc hl
	ld a,(hl)
	or 8
	ld (hl),a
	ld a,d
	cp 0x1D
	jp nc,pd_j5
	call pd_loose
	call pd_pose
	jp pd_j5
pd_dunk:
	ld hl,(z80_ix)
	ld a,(hl)
	or 2
	and 0xE7
	ld (hl),a
	inc hl
	ld a,(hl)
	or 8
	ld (hl),a
	ld hl,0x084C
	ld a,(pd_x1)
	rrca
	jp nc,pd_d1
	ld h,0x74
pd_d1:
	ld (0x93F3),hl
	ld l,0x21
	ld (0x93F1),hl
	inc c
	push bc
	ld hl,(0x3300)
	push hl
	xor a
	ld (0xAA83),a
	ld hl,2
	ld (0x3300),hl
	ld hl,0x8039
	ld (0x3302),hl
	call Z_AA80
	pop hl
	ld (0x3300),hl
	call pd_pose
	pop bc
pd_j5:
	ld a,0x30
	add a,c
	ld c,1
	ld e,a
	ld a,b
	and 4
	ld a,e
	jp nz,pd_j8
	ld hl,0x3301
	ld a,(pd_x1)
	rrca
	jp nc,pd_j6
	ld a,b
	and 2
	ld a,e
	jp nz,pd_j7
	add a,2
	inc (hl)
pd_j7:
	dec c
	add a,8
	jp pd_j8
pd_j6:
	inc (hl)
	ld a,e
	add a,6
	ld e,a
	ld a,b
	and 2
	ld a,e
	jp nz,pd_j8
	add a,2
	jp pd_j9
pd_j8:
	ld e,a
	ld a,(pd_x1)
	rrca
	ld a,e
	jp nc,pd_j9
	add a,2
	add a,c
pd_j9:
	call Z_9E6F
	jp Z_B01C
; ---- helpers -------------------------------------------------------------------------
; pose bits: B = (ix-1), E = (ix-2); cells pd_px pd_x0 (ix+0) pd_x1 (ix+1) pd_m2 (keeps C D)
pd_pose:
	ld hl,(z80_ix)
	dec hl
	dec hl
	ld e,(hl)
	ld a,e
	ld (pd_m2),a
	inc hl
	ld b,(hl)
	ld a,b
	ld (pd_px),a
	inc hl
	ld a,(hl)
	ld (pd_x0),a
	inc hl
	ld a,(hl)
	ld (pd_x1),a
	ret
; HL = ix+6 (keeps A)
pd_ix6:
	ld hl,(z80_ix)
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	ret
; A += 0C when (ix-1) bit 3 (B)
pd_b3c:
	ld d,a
	ld a,b
	and 8
	ld a,d
	ret z
	add a,0x0C
	ret
; A += 0C when (ix-1) bit 1 clear
pd_nb1c:
	ld d,a
	ld a,b
	and 2
	ld a,d
	ret nz
	add a,0x0C
	ret
; A += 1 when (ix+1) bit 0
pd_side:
	ld d,a
	ld a,(pd_x1)
	rrca
	ld a,d
	ret nc
	inc a
	ret
pd_blit:
	ld (0x3300),hl
	call Z_9E6F
	jp Z_B01C
Z_9E6F:
	add a,a
	ld l,a
	ld h,0
	ld de,0x7760
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	ld hl,0x415A
	add hl,de
	ld (0x3302),hl
	ret
pd_e:
	db 0
pd_fr:
	db 0
pd_px:
	db 0
pd_x0:
	db 0
pd_x1:
	db 0
pd_m2:
	db 0
