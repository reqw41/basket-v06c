; Computer opponent, hand i8080 (A2; model src/model/ai.js; Z80 869C..8A22).
; Player 2 (9425) against player 1 (940B): fixed addresses (the Z80 code sets
; ix = 9425, iy = 940B itself). Writes the stick byte AC4E every frame.
; State: 8696 last stick, 8697 hold, 8698 fire divider, 8699 shot choice,
; 869A/869B targets; ai_lvl = 3 - level (the Z80 kept it as the CP operand 88D7).
; Contract: memory and the calls (386E, 388A, A133, A160, A169, A172).
IX0	equ 0x9425
IX1	equ 0x9426
IX2	equ 0x9427
IX3	equ 0x9428
IXA	equ 0x942F
IXM1	equ 0x9424
IXM2	equ 0x9423
IXM7	equ 0x941E
IY0	equ 0x940B
IY2	equ 0x940D
IY3	equ 0x940E
IYM1	equ 0x940A
Z_869C:
	ld hl,0
	ld (0x8696),hl
	ld a,(0x93D2)
	and 3
	sub 4
	cpl
	inc a
	dec a
	ld (ai_lvl),a
	call Z_386E
	and 3
	ld c,0x0C
	jp z,ai_s1
	cp 2
	ld c,1
	jp c,ai_s1
	ld c,4
	jp z,ai_s1
	ld c,3
ai_s1:
	ld a,c
	ld (0x8699),a
	ld hl,IX0
	ld (z80_ix),hl
	ld hl,IY0
	ld (z80_iy),hl
Z_86D0:
	call Z_A160
	push af
	ld de,0x46
	ld hl,0x66
	jp c,ai_t1
	ld a,(IY2)
	ld b,a
	ld a,(IX2)
	cp b
	ld hl,0x4E
	jp c,ai_t1
	ld de,0x5E
	ld hl,0x68
ai_t1:
	call Z_388A
	ld h,0x14
	ld a,l
	and 0xFE
	ld l,a
	ld (0x869A),hl
	pop af
	ld de,0x18
	jp c,ai_t2
	ld de,0x0A
ai_t2:
	ld hl,0x22
	call Z_388A
	ld a,l
	and 0xFE
	ld (0x869B),a
	ret
Z_870E:
	ld hl,IX0
	ld (z80_ix),hl
	ld hl,IY0
	ld (z80_iy),hl
	ld a,(0x93D6)
	and a
	jp z,ai_72d
	ld a,(IX0)
	and 0x10
	jp z,ai_77f
	ld a,(IX0)
	rrca
	jp c,ai_776
	ld a,0x10
	jp ai_8e5
ai_72d:
	ld a,(0x9400)
	and a
	jp z,ai_749
	ld b,a
	and 0x80
	ret nz
	ld a,b
	and 7
	cp 4
	ret nz
	ld hl,0x6454
	ld a,(IX1)
	and 0xBF
	ld (IX1),a
	ld a,(IX2)
	and 0xFE
	ld (IX2),a
	jp ai_89f
ai_749:
	ld a,(IX0)
	and 0x10
	jp z,ai_873
	ld a,(IX0)
	rrca
	jp nc,ai_783
	ld a,(IX0)
	and 0x20
	ld a,(0x8699)
	jp nz,ai_8e5
	ld a,(IX0)
	and 8
	jp nz,ai_776
	ld a,(IX3)
	cp 0x20
	jp nc,ai_77f
	call Z_A169
	jp nz,ai_8c6
	jp ai_77f
ai_776:
	ld a,(IX0)
	and 2
	ld a,0x10
	jp nz,ai_8e5
ai_77f:
	xor a
	jp ai_8e5
ai_783:
	ld a,(0x8697)
	and a
	jp z,ai_78f
	dec a
	ld (0x8697),a
	jp nz,ai_7a2
ai_78f:
	ld a,(IXA)
	cp 4
	jp nc,ai_7fe
	ld c,a
	call Z_A172
	or 3
	add a,c
	rlca
	ld (0x8697),a
ai_7a2:
	ld a,(IY2)
	ld b,a
	ld a,(IX2)
	sub b
	ld e,1
	jp nc,ai_7af
	dec e
	cpl
	inc a
ai_7af:
	cp 6
	jp nc,ai_77f
	ld a,(IY3)
	ld b,a
	ld a,(IX3)
	add a,2
	sub b
	ld d,1
	jp nc,ai_7c2
	dec d
	cpl
	inc a
ai_7c2:
	cp 0x0E
	jp nc,ai_77f
	cp 6
	jp c,ai_7e3
	ld a,d
	and a
	ld a,(IXM1)
	jp z,ai_7da
	xor 0x0C
	jp z,ai_77f
	ld a,0x1C
	jp ai_8c6
ai_7da:
	xor 4
	jp z,ai_77f
	ld a,0x14
	jp ai_8c6
ai_7e3:
	ld a,e
	and a
	ld a,(IXM1)
	jp z,ai_7f4
	xor 3
	jp z,ai_77f
	ld a,0x13
	jp ai_8c6
ai_7f4:
	xor 1
	jp z,ai_77f
	ld a,0x11
	jp ai_8c6
ai_7fe:
	ld a,(IXM1)
	and 0x0C
	cp 4
	jp z,ai_813
	ld a,(0x8696)
	and 8
	jp nz,ai_813
	ld a,0x14
	jp ai_8c6
ai_813:
	ld hl,0x0754
	ld a,(IX2)
	cp l
	jp nz,ai_825
	ld a,(IX3)
	cp h
	ld a,0x10
	jp z,ai_8e5
ai_825:
	ld a,(ai_lvl)
	inc a
	cpl
	inc a
	ld e,a
	ld a,(IY3)
	add a,e
	cp 0x0E
	jp nc,ai_844
	cp 4
	jp c,ai_844
	ld a,(IY2)
	cp 0x51
	jp c,ai_844
	cp 0x58
	jp nc,ai_844
	ld hl,(0x869A)
ai_844:
	ld a,(ai_lvl)
	ld c,a
	ld b,a
	inc c
	cp 3
	jp c,ai_84f
	inc c
ai_84f:
	ld e,a
	ld a,(IX2)
	add a,e
	sub l
	jp c,ai_869
	cp c
	jp nc,ai_869
	ld a,(IX3)
	add a,b
	sub h
	jp c,ai_869
	cp c
	jp nc,ai_869
	call Z_86D0
	ld a,0x10
	jp ai_8e5
ai_869:
	call ai_attack
	and a
	jp nz,ai_8c6
	ld a,0x10
	jp ai_8c6
ai_873:
	ld hl,(0x93F3)
	ld a,(0x93EB)
	ld b,a
	and 4
	ret nz
	ld a,b
	and 0x10
	jp nz,ai_89f
	ld a,b
	and 8
	jp nz,ai_88c
	ld a,b
	and 2
	jp z,ai_89f
	ld a,b
	and 0x80
	jp z,ai_89f
ai_88c:
	ld a,(IX3)
	sub h
	ld e,4
	jp nc,ai_896
	cpl
	inc a
ai_896:
	cp 4
	jp nc,ai_89f
	ld a,0x10
	or e
	jp ai_8c6
ai_89f:
	call Z_A133
	jp nz,ai_8c6
	call ai_defend
	and a
	jp nz,ai_8be
	ld a,(IX3)
	xor 1
	ld (IX3),a
	ld a,(IX2)
	xor 1
	ld (IX2),a
	xor a
ai_8be:
	ld b,a
	ld a,(IX1)
	and 0x40
	ld a,b
	jp z,ai_8c6
	or 0x10
ai_8c6:
	ld c,a
	and a
	jp z,ai_8e5
	ld a,(0x93EB)
	rrca
	ld a,c
	jp nc,ai_8e5
	ld a,(ai_lvl)
	ld b,a
	ld a,(0x8698)
	inc a
	cp b
	jp c,ai_8db
	xor a
ai_8db:
	ld (0x8698),a
	and a
	ld a,c
	jp z,ai_8e5
	ld a,(0x8696)
ai_8e5:
	ld b,a
	ld a,(IXM2)
	and 0x80
	ld a,b
	jp z,ai_8ed
	and 0xEF
ai_8ed:
	ld (0xAC4E),a
	ld (0x8696),a
	ret
; 88F4: attack path to HL around the defender; A = stick
ai_attack:
	ld c,0x0C
	ld a,(IX2)
	cp 0x54
	jp nc,ai_906
	ld a,(IY2)
	cp 0x51
	jp nc,ai_906
	ld c,0x10
ai_906:
	ld a,(IY3)
	ld d,a
	ld a,h
	sub 6
	sub d
	jp nc,ai_a01
	cpl
	inc a
	ld b,a
	ld a,(IX3)
	add a,6
	sub d
	jp c,ai_a01
	ld a,b
	cp c
	jp nc,ai_944
	ld a,(IY2)
	ld d,a
	ld a,(IX2)
	sub d
	ld e,1
	jp nc,ai_92f
	dec e
ai_92f:
	ld a,d
	cp l
	ld a,1
	jp nc,ai_938
	dec a
ai_938:
	add a,e
	cp 1
	jp z,ai_a01
	ld a,0x0D
	ret nc
	ld a,0x0F
	ret
ai_944:
	ld e,1
	ld a,(IY2)
	ld d,a
	ld a,l
	sub d
	jp nc,ai_94f
	dec e
	cpl
	inc a
ai_94f:
	inc a
	and 0xFE
	cp 6
	jp nc,ai_a01
	add a,6
	dec e
	jp z,ai_95e
	cpl
	inc a
ai_95e:
	add a,l
	ld l,a
	jp ai_a01
; 8963: defence path to the ball HL; A = stick
ai_defend:
	ld c,8
	ld a,(IY0)
	and 0x10
	jp z,ai_96d
	ld c,0x0A
ai_96d:
	ld a,(IY3)
	ld e,a
	ld a,(IX3)
	sub e
	jp nc,ai_977
	cpl
	inc a
ai_977:
	cp c
	ld d,a
	jp nc,ai_a01
	ld a,(IY2)
	and 0xE0
	rrca
	rrca
	rrca
	rrca
	ld b,a
	ld a,(IY0)
	and 0x10
	jp z,ai_9ce
	ld a,(IYM1)
	and 4
	jp nz,ai_9ce
	ld a,(IX2)
	cp l
	sbc a,a
	ld e,a
	ld a,(IYM1)
	and 2
	jp z,ai_9b3
	inc l
	inc l
	ld a,e
	or a
	jp z,ai_a01
	ld a,d
	cp 6
	jp nc,ai_a01
	ld e,3
	ld a,0x14
	sub b
	ld b,a
ai_9ae:
	ld a,h
	sub b
	ld h,a
	jp ai_a0e
ai_9b3:
	ld a,e
	or a
	jp nz,ai_a01
	ld a,d
	cp 6
	jp c,ai_9be
	dec l
	dec l
	jp ai_a01
ai_9be:
	ld e,1
	ld a,(IY3)
	ld c,a
	ld a,0x62
	add a,b
	ld b,0x0F
	cp c
	jp c,ai_9ae
	inc h
	inc h
	jp ai_a0e
ai_9ce:
	ld a,(IY2)
	ld e,a
	ld a,(IX2)
	sub e
	jp nc,ai_9d8
	cpl
	inc a
ai_9d8:
	inc a
	and 0xFE
	cp 4
	jp nc,ai_a01
	ld a,(IY2)
	sub l
	ld e,1
	jp nc,ai_9ea
	dec e
	cpl
	inc a
ai_9ea:
	inc a
	and 0xFE
	cp 4
	jp nc,ai_a01
	and a
	jp nz,ai_9f8
	ld e,3
	jp ai_a0e
ai_9f8:
	dec e
	ld e,3
	jp nz,ai_a0e
	ld e,1
	jp ai_a0e
; 8A01 / 8A0E: stick from the target HL
ai_a01:
	ld a,(IX2)
	ld b,a
	ld a,l
	ld e,0
	cp b
	jp z,ai_a0e
	inc e
	jp c,ai_a0e
	ld e,3
ai_a0e:
	ld a,(IX3)
	cp h
	ld a,e
	jp z,ai_a1b
	ld a,0x0C
	jp c,ai_a1b
	ld a,4
ai_a1b:
	or e
	ld b,a
	ld a,(IXM7)
	rrca
	ld a,b
	ret nc
	ld a,e
	ret
ai_lvl:
	db 0
