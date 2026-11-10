; Player actions with the ball, hand i8080 (A2; model src/model/action.js;
; Z80 8E5A..91B4). ix = player (z80_ix), iy = the other (z80_iy).
; 8E5A action start (take the ball / jump / shot setup, falls into 8F76),
; 8E73 take the ball, 8F76 action step (flight, landing 9179), 9009 after the
; step, 9041 shot release, 90EF the release (ball state 02, flight setup).
; B and C go into 98D9 (93BB push) as the Z80; E into 9919.
; Contract: memory and the calls; no register outputs.
Z_8E5A:
	ld a,0xFE
	call ac_at
	ld a,(hl)
	and 0xEF
	ld (hl),a
	inc hl
	inc hl
	ld a,(hl)
	and 0x10
	jp nz,ac_air
	inc hl
	ld a,(hl)
	and 0x40
	jp z,ac_f00
	ld a,(hl)
	and 8
	jp z,Z_8E73
ac_f00:
	ld hl,(z80_iy)
	ld a,(hl)
	and 0x10
	jp z,ac_f51
	ld hl,(z80_ix)
	inc hl
	ld a,(hl)
	and 0x20
	jp nz,Z_98B3
	jp ac_f51
ac_air:
	ld a,(hl)
	or 8
	ld (hl),a
	inc hl
	ld b,(hl)
	inc hl
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a
	cp 0x50
	jp c,ac_f51
	cp 0x5B
	jp nc,ac_f51
	ld a,b
	rrca
	ld a,h
	jp nc,ac_a1
	cp 0x68
	jp c,ac_f51
	jp ac_f33
ac_a1:
	cp 0x0D
	jp nc,ac_f51
ac_f33:
	ld a,0x0A
	call ac_at
	ld a,(hl)
	cp 3
	jp c,ac_f59
	ld hl,(z80_ix)
	ld a,(hl)
	or 0x20
	and 0xF7
	ld (hl),a
	ld b,9
	ld a,(0x9400)
	and a
	jp nz,ac_f5f
	ld a,2
	ld (0x93D3),a
	jp ac_f5f
ac_f51:
	ld a,0x0A
	call ac_at
	ld a,(hl)
	ld b,4
	and a
	jp nz,ac_f5f
ac_f59:
	ld b,2
	ld hl,(z80_ix)
	inc hl
	ld a,(hl)
	or 0x80
	ld (hl),a
ac_f5f:
	ld hl,(z80_ix)
	ld a,(hl)
	or 1
	ld (hl),a
	ld de,8
	add hl,de
	ld (hl),b
	ld de,0xFFF4
	add hl,de
	ld (hl),0
	ld de,6
	add hl,de
	ld a,(hl)
	inc hl
	ld b,(hl)
	inc hl
	ld (hl),a
	inc hl
	ld (hl),b
Z_8F76:
	ld a,0xFC
	call ac_at
	inc (hl)
	call Z_938E
	ld hl,(z80_ix)
	ld a,(hl)
	and 2
	jp nz,ac_land
	call Z_93A3
	call Z_93A3
	ld hl,(z80_ix)
	ld a,(hl)
	and 0x20
	jp z,ac_fe6
	dec hl
	ld a,(hl)
	and 4
	jp z,ac_faf
	ld b,(hl)
	inc hl
	ld a,(hl)
	and 0xBF
	ld (hl),a
	inc hl
	ld a,(hl)
	rrca
	ld e,8
	jp c,ac_fa3
	ld e,0
ac_fa3:
	ld a,b
	and 8
	xor e
	jp z,ac_faf
	dec hl
	ld a,(hl)
	or 0x40
	ld (hl),a
ac_faf:
	ld bc,0
	ld hl,(z80_ix)
	inc hl
	inc hl
	ld a,(hl)
	cp 0x54
	jp z,ac_fc3
	ld c,2
	jp c,ac_fbf
	ld c,0xFE
ac_fbf:
	add a,c
	ld (hl),a
ac_fc3:
	dec hl
	ld a,(hl)
	inc hl
	inc hl
	rrca
	ld e,9
	jp nc,ac_fcd
	ld e,0x6B
ac_fcd:
	ld a,(hl)
	cp e
	jp z,ac_fdd
	jp c,ac_fd5
	dec a
	ld b,0xFF
	jp ac_fdd
ac_fd5:
	inc a
	ld b,1
ac_fdd:
	ld (hl),a
	inc hl
	inc hl
	ld (hl),a
	call Z_938B
ac_fe6:
	ld hl,(z80_ix)
	inc hl
	inc hl
	inc hl
	inc hl
	ld a,(hl)
	sub 4
	ld (hl),a
	inc hl
	inc hl
	inc hl
	inc hl
	dec (hl)
	jp nz,Z_9009
	ld hl,(z80_ix)
	ld a,(hl)
	or 2
	ld (hl),a
	and 0x10
	jp z,Z_9009
	inc hl
	ld a,(hl)
	and 0x80
	jp z,Z_9009
	dec hl
	dec hl
	dec hl
	ld a,(hl)
	or 0x10
	ld (hl),a
	jp ac_rel
Z_9009:
	ld hl,(z80_ix)
	ld a,(hl)
	and 0x20
	ret nz
	ld a,(hl)
	and 0x80
	jp z,ac_19
	dec hl
	dec hl
	ld a,(hl)
	or 0x20
	ld (hl),a
	ret
ac_19:
	ld a,(hl)
	and 0x10
	jp nz,ac_rel
	inc hl
	ld a,(hl)
	and 8
	ret nz
	ld a,(0x93EB)
	and 2
	jp z,ac_34
	ld a,(hl)
	rrca
	ld b,a
	ld a,(0x93EB)
	xor b
	and 0x80
	ret z
ac_34:
	ld a,(hl)
	and 0x40
	ret z
	ld a,(hl)
	and 8
	ret nz
	jp Z_8E73
ac_rel:
	ld hl,(z80_ix)
	inc hl
	ld a,(hl)
	and 2
	jp nz,ac_b7
	ld a,(hl)
	and 4
	jp nz,ac_7e
	dec hl
	dec hl
	dec hl
	ld a,(hl)
	and 0x10
	ret z
	ld hl,(z80_ix)
	inc hl
	ld b,(hl)
	inc hl
	inc hl
	ld a,(hl)
	ld c,a
	ld a,b
	rrca
	ld a,c
	jp nc,ac_r1
	cp 0x60
	jp nc,ac_lo
	jp ac_r2
ac_r1:
	cp 0x14
	jp c,ac_lo
ac_r2:
	ld hl,(z80_ix)
	dec hl
	ld a,(hl)
	and 4
	jp nz,ac_hi
	inc hl
	ld a,(hl)
	or 0x80
	ld (hl),a
	dec hl
	dec hl
	ld a,(hl)
	or 0x20
	ld (hl),a
	xor a
	ld de,9
	add hl,de
	ld (hl),a
	jp Z_9DC2
ac_hi:
	inc hl
	inc hl
	ld a,(hl)
	or 4
	ld (hl),a
	jp ac_7e
ac_lo:
	ld hl,(z80_ix)
	inc hl
	ld a,(hl)
	or 2
	ld (hl),a
ac_b7:
	ld hl,(z80_ix)
	dec hl
	ld c,(hl)
	inc hl
	inc hl
	inc hl
	ld a,(hl)
	cp 0x55
	jp c,ac_b1
	ld a,c
	rrca
	ld a,1
	jp nc,ac_pose
	ld a,c
	and 2
	jp nz,ac_c9
	jp Z_90EF
ac_b1:
	ld a,c
	rrca
	ld a,3
	jp nc,ac_pose
	ld a,c
	and 2
	jp nz,Z_90EF
ac_c9:
	ld hl,(z80_ix)
	inc hl
	ld a,(hl)
	rrca
	ld a,4
	jp nc,ac_pose
	ld a,0x0C
	jp ac_pose
ac_7e:
	ld hl,(z80_ix)
	dec hl
	ld c,(hl)
	inc hl
	inc hl
	ld a,(hl)
	rrca
	jp nc,ac_7f
	ld a,c
	and 4
	ld a,0x0C
	jp z,ac_pose
	ld a,c
	and 8
	jp nz,Z_90EF
	ld a,1
	jp ac_pose
ac_7f:
	ld a,c
	and 4
	ld a,4
	jp z,ac_pose
	ld a,c
	and 8
	jp z,Z_90EF
	ld a,3
ac_pose:
	ld hl,(z80_ix)
	dec hl
	ld (hl),a
	jp Z_9DC2
Z_90EF:
	ld hl,(z80_ix)
	inc hl
	ld a,(hl)
	rrca
	ld a,2
	jp nc,ac_s1
	ld a,0x82
ac_s1:
	ld (0x93EB),a
	dec hl
	ld a,(hl)
	and 0xE3
	ld (hl),a
	call Z_9391
	ld a,0xFD
	call ac_at
	ld a,(hl)
	ld (0x944D),a
	dec hl
	ld e,(hl)
	dec e
	ld d,0
	ld a,0x0A
	call ac_at2
	ld a,(hl)
	ld (0x944E),a
	ld hl,0x943A
	add hl,de
	ld a,(hl)
	ld (0x9450),a
	ld hl,(z80_ix)
	inc hl
	ld b,(hl)
	inc hl
	ld a,(hl)
	sub 0x58
	jp nc,ac_s2
	cpl
	inc a
ac_s2:
	ld c,a
	inc hl
	ld a,(hl)
	ld d,a
	ld a,b
	rrca
	ld a,d
	jp nc,ac_s3
	cpl
	inc a
	add a,0x74
ac_s3:
	add a,c
	or a
	rra
	ld (0x944F),a
	inc hl
	ld a,(hl)
	sub 0x1A
	ld e,a
	inc hl
	ld d,(hl)
	ld hl,(z80_ix)
	dec hl
	ld c,(hl)
	ld a,b
	rrca
	jp nc,ac_s5
	inc d
	ld a,c
	rrca
	jp c,ac_s6
	ld a,d
	add a,8
	ld d,a
	jp ac_s7
ac_s5:
	dec d
	ld a,c
	rrca
	jp nc,ac_s7
ac_s6:
	inc d
	inc d
ac_s7:
	ex de,hl
	ld (0x93F1),hl
	ex de,hl
	inc hl
	inc hl
	inc hl
	ld a,(hl)
	ld e,a
	ex de,hl
	ld (0x93F3),hl
	ex de,hl
	dec hl
	dec hl
	dec hl
	dec hl
	ld a,(hl)
	or 0x40
	ld (hl),a
	inc hl
	inc hl
	inc hl
	ld a,(hl)
	or 0x10
	ld (hl),a
	ret
Z_8E73:
	ld a,(0x93EB)
	ld c,a
	and 8
	jp z,ac_t1
	ld a,0x10
	call ac_at
	inc (hl)
ac_t1:
	ld hl,(z80_ix)
	inc hl
	ld a,(hl)
	rrca
	ld a,0x21
	jp nc,ac_t2
	ld a,0xA1
ac_t2:
	ld (0x93EB),a
	xor a
	ld (0x93F5),a
	ld hl,(z80_iy)
	dec hl
	dec hl
	ld a,(hl)
	and 0xDF
	ld (hl),a
	inc hl
	inc hl
	ld a,(hl)
	ld b,a
	and 0x43
	ld (hl),a
	inc hl
	ld a,(hl)
	and 0xA9
	ld (hl),a
	ld hl,(z80_ix)
	ld a,(hl)
	or 0x10
	ld (hl),a
	dec hl
	dec hl
	ld a,(hl)
	and 0xEF
	ld (hl),a
	ld de,8
	add hl,de
	ld (hl),3
	ld a,c
	rrca
	jp c,ac_t3
	ld hl,(z80_ix)
	ld a,(hl)
	rrca
	jp c,ac_t3
	ld a,(0x93F1)
	ld c,a
	ld a,(0x93F3)
	sub c
	cp 0x14
	jp c,ac_t3
	dec hl
	dec hl
	ld a,(hl)
	or 0x40
	ld (hl),a
	inc hl
	inc hl
	inc hl
	inc hl
	ld a,(hl)
	sub 2
	inc hl
	ld c,(hl)
	inc hl
	ld (hl),a
	inc hl
	ld (hl),c
ac_t3:
	ld a,b
	and 0x20
	jp z,Z_9DC2
	ld hl,(z80_iy)
	ld de,8
	add hl,de
	ld (hl),4
	xor a
	ld (0x93D3),a
	jp Z_9DC2
ac_land:
	call Z_9009
	ld hl,(z80_ix)
	inc hl
	inc hl
	ld b,(hl)
	inc hl
	inc hl
	ld a,(hl)
	add a,4
	ld (hl),a
	cp b
	ret c
	ld hl,(z80_ix)
	ld a,(hl)
	ld b,a
	and 0x10
	ld (hl),a
	inc hl
	ld a,(hl)
	and 0x71
	ld (hl),a
	ld de,5
	add hl,de
	ld (hl),0
	ld a,b
	and 8
	ret z
	ld a,(0x93D6)
	and a
	ret nz
	ld e,1
	jp Z_9919
; HL = ix + A (signed); ac_at2 keeps DE
ac_at:
	ld hl,(z80_ix)
	ld e,a
	add a,a
	sbc a,a
	ld d,a
	add hl,de
	ret
ac_at2:
	push de
	call ac_at
	pop de
	ret
