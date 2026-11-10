; The game's IRQ handler and the key parse, hand i8080 (A2; model src/model/sys.js;
; Z80 36F3..3727, 372C..3731, 3811..3845, A186..A192).
; Z_36F3: entered by JP from the IRQ hook 4141. Saves the registers, ix/iy and
;   the translation's runtime cells (the hooks may run translated code: the
;   same ISR_SAVE as tools/recompile_i8080.py), then the music hook (Z_3702:
;   CALL operand set by AA8F), the clock hook (Z_3705: CALL operand set by
;   9F60/9F67), the keys (Z_372C: 063F, the adapter, drops the return into
;   372C itself when no key changed and comes back to 370B directly).
; Z_3715: frame counter 4111 (+4113), then A186 (outside a match the RNG seed 4114++).
; Z_3811: key matrix 4104..410E -> G_KEY_CODE 410F / G_KEY_ASCII 4110 (table 3436).
; Uses no cells of its own (it interrupts the hand modules).
Z_36F3:
	di
	push af
	ld a,0x80
	and a
	push bc
	push hl
	push de
	ld hl,(il_tmp)
	push hl
	ld hl,(il_tmp2)
	push hl
	ld hl,(il_f)
	push hl
	ld hl,(il_a)
	push hl
	ld hl,(z80_ix)
	push hl
	ld hl,(z80_iy)
	push hl
Z_3702:
	call Z_3714
Z_3705:
	call Z_3715
	call Z_372C
	pop hl
	ld (z80_iy),hl
	pop hl
	ld (z80_ix),hl
	pop hl
	ld (il_a),hl
	pop hl
	ld (il_f),hl
	pop hl
	ld (il_tmp2),hl
	pop hl
	ld (il_tmp),hl
	pop de
	pop hl
	pop bc
	pop af
	ei
Z_3714:
	ret
Z_3715:
	ld hl,(0x4111)
	inc hl
	ld (0x4111),hl
	ld a,h
	or l
	jp nz,Z_A186
	ld hl,0x4113
	inc (hl)
Z_A186:
	ld a,(0x0FED)
	dec a
	ret z
	ld hl,(0x4114)
	inc hl
	ld (0x4114),hl
	ret
Z_372C:
	call 0x063F
Z_3811:
	ld hl,0x4104
	ld b,0x0B
is_k1:
	ld a,(hl)
	cp 0xFF
	jp nz,is_k2
	inc hl
	dec b
	jp nz,is_k1
	ld (0x410F),a
	ld (0x4110),a
	ret
is_k2:
	ld c,0
is_k3:
	rrca
	jp nc,is_k4
	inc c
	jp is_k3
is_k4:
	ld a,0x0B
	sub b
	rlca
	rlca
	rlca
	add a,c
	ld (0x410F),a
	ld e,a
	ld d,0
	ld hl,(0x3436)
	add hl,de
	ld a,(hl)
	cp 5
	jp z,Z_36D7
	ld (0x4110),a
	ret
