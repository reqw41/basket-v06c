; Object scheduler and the input merge, hand i8080 (A2; model src/model/setup.js;
; Z80 94B0..958E).
; Z_94B0: list at 3C1E of (y, routine): ball 84D3, its shadow 84D6 (unless the
;   ball is loose or in the basket), player 1 9599, player 2 958F; bubble
;   passes as the Z80 (B counts the swaps), then each routine in order.
;   The routine words are i8080 addresses (the labels), like the translation.
; Z_9543: controls (AC4A), then the stick bytes 9409 / 9423 from AC4D / AC4E
;   (fire held: bit 7, a new press keeps bit 4), the computer player (84DF),
;   restarts mask the stick.
; Contract: memory and the calls; no register outputs.
Z_94B0:
	ld hl,0x3C1E
	ld a,0x53
	ld de,Z_84D3
	call sc_put
	ld a,(0x93EB)
	and 5
	jp nz,sc_1
	ld a,(0x93F3)
	ld de,Z_84D6
	call sc_put
sc_1:
	ld a,(0x940D)
	ld de,Z_9599
	call sc_put
	ld a,(0x9427)
	ld de,Z_958F
	call sc_put
	ld (hl),0
	ld b,1
sc_pass:
	ld hl,0x3C1E
sc_cmp:
	ld a,(hl)
	and a
	jp z,sc_next
	ld d,a
	push hl
	inc hl
	inc hl
	inc hl
	ld c,(hl)
	pop hl
	cp c
	jp z,sc_skip
	jp c,sc_skip
	ld a,c
	and a
	jp z,sc_next
	ld (hl),c
	inc hl
	ld e,(hl)
	inc hl
	ld c,(hl)
	inc hl
	ld (hl),d
	inc hl
	ld a,(hl)
	ld (hl),e
	inc hl
	ld d,(hl)
	ld (hl),c
	dec hl
	dec hl
	dec hl
	ld (hl),d
	dec hl
	ld (hl),a
	inc hl
	inc hl
	inc b
	jp sc_cmp
sc_skip:
	inc hl
	inc hl
	inc hl
	jp sc_cmp
sc_next:
	dec b
	jp nz,sc_pass
	ld hl,0x3C1E
sc_call:
	ld a,(hl)
	and a
	ret z
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	push hl
	ex de,hl
	call sc_jp
	pop hl
	jp sc_call
sc_jp:
	jp (hl)
sc_put:
	ld (hl),a
	inc hl
	ld (hl),e
	inc hl
	ld (hl),d
	inc hl
	ret
Z_9543:
	call Z_AC4A
	ld hl,0x9409
	ld a,(0xAC4D)
	call sc_stick
	ld a,(0x93EA)
	and a
	call nz,Z_84DF
	ld hl,0x9423
	ld a,(0xAC4E)
	call sc_stick
	ld a,(0x93D6)
	and a
	ret z
	ld hl,0x9409
	ld a,(hl)
	and 0xF0
	ld (hl),a
	ld hl,0x9423
	ld a,(hl)
	and 0xF0
	ld (hl),a
	ret
; (HL) = A, with fire: bit 7 set, bit 4 only on a new press
sc_stick:
	ld c,a
	and 0x10
	ld a,c
	jp z,sc_s1
	or 0x80
	ld c,a
	ld a,(hl)
	and 0x80
	ld a,c
	jp z,sc_s1
	and 0xEF
sc_s1:
	ld (hl),a
	ret
