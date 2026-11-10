; Ball flight and rebound, hand i8080 (A2; model src/model/flight.js;
; Z80 9A1B..9C7B). The flight block: 93EB state, 93EC..93EE height table
; pointer and count, 93EF..93F0, 93F1 height, 93F2..93F4 position, 93F5 flags
; (ix of the Z80), 93F6..93FF the line state. The Z80 kept the step
; direction on the stack and in the alternate registers; here it lives where
; the Z80 leaves it in the end (93FE x, 93FF y; the straight step 93FC/93FD).
; Contract: memory and the calls (386E, 398C, 39A3); no register outputs.
Z_9A1B:
	ld hl,0x93F5
	ld (z80_ix),hl
	ld a,(hl)
	rrca
	jp nc,fl_new
	ld a,(hl)
	and 4
	jp z,fl_res
	ld a,(0x93EB)
	and 0x80
	ld a,1
	jp nz,fl_d1
	ld a,0xFF
fl_d1:
	ld hl,0x93F4
	add a,(hl)
	ld (hl),a
	ld (0x93F2),a
	ld a,(0x93F1)
	add a,4
	ld (0x93F1),a
	ld hl,0x93F5
	ld a,(hl)
	or 2
	ld (hl),a
	ret
fl_res:
	ld a,(0x93FC)
	ld e,a
	ld a,(0x93FD)
	ld d,a
	ld hl,(0x93F8)
	ld a,(0x93FB)
	ld b,a
	ld a,(0x93FA)
	ld c,a
	call fl_step
	jp fl_hgt
fl_new:
	ld (hl),1
	ld a,1
	ld (0x93F0),a
	ld hl,D_9B69
	ld (0x93ED),hl
	ld hl,(0x93F3)
	ld a,(0x93F1)
	ld (0x93F6),a
	sub 0x1E
	jp nc,fl_n1
	cpl
	inc a
	ld b,a
	ld a,(0x93F5)
	or 0x80
	ld (0x93F5),a
	ld a,b
fl_n1:
	ld (0x93F7),a
	ld de,0x0554
	ld a,(0x93EB)
	and 0x80
	jp z,fl_n2
	ld d,0x39
fl_n2:
	ld a,h
	or a
	rra
	ld h,a
	ld a,d
	sub h
	ld d,2
	jp nc,fl_n3
	cpl
	inc a
	ld d,0xFE
fl_n3:
	ld b,a
	ld a,e
	sub l
	ld e,2
	jp nc,fl_n4
	cpl
	inc a
	ld e,0xFE
fl_n4:
	or a
	rra
	ld c,a
	ld a,b
	cp c
	jp nc,fl_n5
	ld a,c
fl_n5:
	ld (0x93EF),a
	or a
	rra
	ld (0x93EC),a
	call fl_setup
fl_hgt:
	ld hl,(0x93ED)
	ld c,(hl)
	ld a,(0x93EC)
	and a
	jp z,fl_h1
	dec a
	ld (0x93EC),a
	inc hl
	jp fl_h2
fl_h1:
	dec hl
fl_h2:
	ld (0x93ED),hl
	ld a,(0x93F4)
	ld (0x93F2),a
	push bc
	ld a,(0x93F0)
	ld c,a
	inc a
	ld (0x93F0),a
	ld a,(0x93F7)
	ld l,a
	ld h,0
	ld b,h
	call Z_398C
	ld b,0
	ld a,(0x93EF)
	ld c,a
	call Z_39A3
	ld a,(0x93F5)
	and 0x80
	jp z,fl_h3
	ld a,l
	cpl
	inc a
	ld l,a
fl_h3:
	ld a,(0x93F6)
	sub l
	pop bc
	sub c
	ld (0x93F1),a
	ret
; 9AF6: B = |dy|, C = |dx|/2, D/E = the step signs
fl_setup:
	ld a,c
	cp b
	jp nc,fl_s2
	ld l,c
	ld a,e
	ld (0x93FE),a
	ld a,d
	ld (0x93FF),a
	ld e,0
	jp fl_s3
fl_s2:
	or c
	jp z,fl_end
	ld l,b
	ld b,c
	ld a,e
	ld (0x93FE),a
	ld a,d
	ld (0x93FF),a
	ld d,0
fl_s3:
	ld h,b
	ld a,b
	or a
	rra
; 9B0B: A = error, L = short, H = long, B = steps left, DE = straight step
fl_step:
	add a,l
	jp c,fl_dg
	cp h
	jp nc,fl_dg
	ld c,a
	ld a,d
	ld (fl_dy),a
	ld a,e
	ld (fl_dx),a
	jp fl_mv
fl_dg:
	sub h
	ld c,a
	ld a,(0x93FF)
	ld (fl_dy),a
	ld a,(0x93FE)
	ld (fl_dx),a
fl_mv:
	push hl
	ld hl,0x93F4
	ld a,(fl_dy)
	add a,(hl)
	ld (hl),a
	dec hl
	ld a,(fl_dx)
	add a,(hl)
	ld (hl),a
	pop hl
	dec b
	ld a,l
	ld (0x93F8),a
	ld a,h
	ld (0x93F9),a
	ld a,c
	ld (0x93FA),a
	ld a,b
	ld (0x93FB),a
	ld a,e
	ld (0x93FC),a
	ld a,d
	ld (0x93FD),a
	ld a,b
	or a
	ret nz
fl_end:
	ld hl,0x93F5
	ld a,(hl)
	or 4
	ld (hl),a
	ret
Z_9BF6:
	ld hl,0x93F5
	ld (z80_ix),hl
	ld a,(hl)
	rrca
	jp c,fl_r2
	ld (hl),0x41
	call Z_386E
	push af
	call Z_386E
	and 3
	ld hl,D_9B89
	jp z,fl_r1
	ld hl,D_9B9F
	dec a
	jp z,fl_r1
	ld hl,D_9BBB
	dec a
	jp z,fl_r1
	ld hl,D_9BD7
fl_r1:
	ld (0x93ED),hl
	pop af
	and 3
	jp z,fl_r2
	ld hl,0x93F5
	ld b,a
	ld a,(hl)
	and 0xBF
	ld (hl),a
	ld a,b
	rrca
	jp nc,fl_r2
	ld a,(hl)
	or 0x80
	ld (hl),a
fl_r2:
	ld hl,(0x93ED)
	ld a,(0x93D6)
	and a
	jp nz,fl_r3
	ld a,(0x93F5)
	and 0x40
	jp nz,fl_r4
fl_r3:
	ld a,(0x93F5)
	and 0x80
	ld a,(hl)
	jp z,fl_r5
	cpl
	inc a
fl_r5:
	push hl
	ld hl,0x93F3
	add a,(hl)
	ld (hl),a
	pop hl
fl_r4:
	inc hl
	ld a,(0x93EB)
	and 0x80
	ld a,(hl)
	jp z,fl_r6
	cpl
	inc a
fl_r6:
	push hl
	ld hl,0x93F4
	add a,(hl)
	ld (hl),a
	ld (0x93F2),a
	pop hl
	inc hl
	ld a,(hl)
	push hl
	ld hl,0x93F1
	add a,(hl)
	ld (hl),a
	pop hl
	inc hl
	ld (0x93ED),hl
	ld a,(hl)
	inc a
	ret nz
	ld a,(0x93F5)
	or 2
	ld (0x93F5),a
	ret
fl_dy:
	db 0
fl_dx:
	db 0
