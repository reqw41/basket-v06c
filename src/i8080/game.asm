; СГЕНЕРИРОВАНО tools/recompile_i8080.py — правки вносить ТУДА.
; Код игры Basket Master, перекомпилированный Z80 -> i8080 (Вектор-06Ц, ВМ80А).
; Эталон — disasm/v06/game.asm (раскладка Вектора, гейт tools/disasm_v06.py --verify).
; Метод, врезки, гейты и такты — docs/recompilation.md.


BLIT_PASS_FLAG:	equ	0x34DF
BLIT_SRC:	equ	0x3302
BLIT_Y:	equ	0x3300
CROWD_TICK:	equ	0x74BA
GAME_ISR_HOOK:	equ	0x4141
G_KEY_ASCII:	equ	0x4110
G_KEY_CODE:	equ	0x410F
HUD_ICON:	equ	0xB455
MENU_BOX_CLEAR:	equ	0x18F6
MENU_KEY:	equ	0x06BB
NATIVE_PADS:	equ	0x6CD0
REPLAY_SCENE:	equ	0x144F
REPLAY_STATE_BEGIN:	equ	0x144C
RING_PULL:	equ	0x752D
RING_PUSH:	equ	0x74E8
RING_REPLAY:	equ	0x751C
RING_RESET:	equ	0x7511
TEXT_COL:	equ	0x4103
TEXT_ROW:	equ	0x4102
RT_VARS:	equ	0x9300	; ячейки рантайма (мёртвая зона 92FF..9329)
z80_ix:	equ	RT_VARS+0
z80_iy:	equ	RT_VARS+2
il_tmp:	equ	RT_VARS+4
il_tmp2:	equ	RT_VARS+6
il_f:	equ	RT_VARS+8
z80_af_alt:	equ	RT_VARS+10
z80_bc2:	equ	RT_VARS+12
z80_de2:	equ	RT_VARS+14
z80_hl2:	equ	RT_VARS+16
il_a:	equ	RT_VARS+18
il_d:	equ	RT_VARS+19
z80_r:	equ	RT_VARS+20
RT_VARS_END:	equ	RT_VARS+21

	org	0x0B63
Z_8871:
	jp Z_88C6	; 8871 18 53
Z_8873:
	ld hl,(D_93F3)	; 8873 2A F3 93
Z_8876:
	ld a,(D_93EB)	; 8876 3A EB 93
Z_8879:
	ld (il_a),a	; 8879 CB 57
	and 0x04
	ld a,(il_a)
Z_887B:
	ret nz	; 887B C0
Z_887C:
	ld (il_a),a	; 887C CB 67
	and 0x10
	ld a,(il_a)
Z_887E:
	jp nz,Z_889F	; 887E 20 1F
Z_8880:
	ld (il_a),a	; 8880 CB 5F
	and 0x08
	ld a,(il_a)
Z_8882:
	jp nz,Z_888C	; 8882 20 08
Z_8884:
	ld (il_a),a	; 8884 CB 4F
	and 0x02
	ld a,(il_a)
Z_8886:
	jp z,Z_889F	; 8886 28 17
Z_8888:
	ld (il_a),a	; 8888 CB 7F
	and 0x80
	ld a,(il_a)
Z_888A:
	jp z,Z_889F	; 888A 28 13
Z_888C:
	rst 0x10	; 888C DD 7E 03
	db 0x03
Z_888F:
	sub h	; 888F 94
Z_8890:
	ld e,0x04	; 8890 1E 04
Z_8892:
	jp nc,Z_8896	; 8892 30 02
Z_8894:
	cpl	; 8894 ED 44
	inc a
Z_8896:
	cp 0x04	; 8896 FE 04
Z_8898:
	jp nc,Z_889F	; 8898 30 05
Z_889A:
	ld a,0x10	; 889A 3E 10
Z_889C:
	or e	; 889C B3
Z_889D:
	jp Z_88C6	; 889D 18 27
Z_889F:
	call Z_A133	; 889F CD 33 A1
Z_88A2:
	nop	; 88A2 00
Z_88A3:
	nop	; 88A3 00
Z_88A4:
	nop	; 88A4 00
Z_88A5:
	jp nz,Z_88C6	; 88A5 20 1F
Z_88A7:
	call Z_8963	; 88A7 CD 63 89
Z_88AA:
	and a	; 88AA A7
Z_88AB:
	jp nz,Z_88BE	; 88AB 20 11
Z_88AD:
	rst 0x10	; 88AD DD 7E 03
	db 0x03
Z_88B0:
	xor 0x01	; 88B0 EE 01
Z_88B2:
	rst 0x20	; 88B2 DD 77 03
	db 0x03
Z_88B5:
	rst 0x10	; 88B5 DD 7E 02
	db 0x02
Z_88B8:
	xor 0x01	; 88B8 EE 01
Z_88BA:
	rst 0x20	; 88BA DD 77 02
	db 0x02
Z_88BD:
	xor a	; 88BD AF
Z_88BE:
	rst 0x08	; 88BE DD CB 01 76
	db 0x01, 0x40
Z_88C2:
	jp z,Z_88C6	; 88C2 28 02
Z_88C4:
	or 0x10	; 88C4 F6 10
Z_88C6:
	ld c,a	; 88C6 4F
Z_88C7:
	and a	; 88C7 A7
Z_88C8:
	jp z,Z_88E5	; 88C8 28 1B
Z_88CA:
	ld a,(D_93EB)	; 88CA 3A EB 93
Z_88CD:
	ld (il_a),a	; 88CD CB 47
	and 0x01
	ld a,(il_a)
Z_88CF:
	ld a,c	; 88CF 79
Z_88D0:
	jp z,Z_88E5	; 88D0 28 13
Z_88D2:
	ld a,(D_8698)	; 88D2 3A 98 86
Z_88D5:
	inc a	; 88D5 3C
Z_88D6:
	cp 0x01	; 88D6 FE 01
Z_88D8:
	jp c,Z_88DB	; 88D8 38 01
Z_88DA:
	xor a	; 88DA AF
Z_88DB:
	ld (D_8698),a	; 88DB 32 98 86
Z_88DE:
	and a	; 88DE A7
Z_88DF:
	ld a,c	; 88DF 79
Z_88E0:
	jp z,Z_88E5	; 88E0 28 03
Z_88E2:
	ld a,(D_8696)	; 88E2 3A 96 86
Z_88E5:
	rst 0x08	; 88E5 DD CB FE 7E
	db 0xFE, 0x80
Z_88E9:
	jp z,Z_88ED	; 88E9 28 02
Z_88EB:
	push af	; 88EB CB A7
	and 0xEF
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_88ED:
	ld (D_AC4E),a	; 88ED 32 4E AC
Z_88F0:
	ld (D_8696),a	; 88F0 32 96 86
Z_88F3:
	ret	; 88F3 C9
Z_88F4:
	ld c,0x0C	; 88F4 0E 0C
Z_88F6:
	rst 0x10	; 88F6 DD 7E 02
	db 0x02
Z_88F9:
	cp 0x54	; 88F9 FE 54
Z_88FB:
	jp nc,Z_8906	; 88FB 30 09
Z_88FD:
	call il_iy_lda	; 88FD FD 7E 02
	db 0x02
Z_8900:
	cp 0x51	; 8900 FE 51
Z_8902:
	jp nc,Z_8906	; 8902 30 02
Z_8904:
	ld c,0x10	; 8904 0E 10
Z_8906:
	ld a,h	; 8906 7C
Z_8907:
	sub 0x06	; 8907 D6 06
Z_8909:
	call il_iy_sub	; 8909 FD 96 03
	db 0x03
Z_890C:
	jp nc,Z_8A01	; 890C D2 01 8A
Z_890F:
	cpl	; 890F ED 44
	inc a
Z_8911:
	ld b,a	; 8911 47
Z_8912:
	rst 0x10	; 8912 DD 7E 03
	db 0x03
Z_8915:
	add a,0x06	; 8915 C6 06
Z_8917:
	call il_iy_sub	; 8917 FD 96 03
	db 0x03
Z_891A:
	jp c,Z_8A01	; 891A DA 01 8A
Z_891D:
	ld a,b	; 891D 78
Z_891E:
	cp c	; 891E B9
Z_891F:
	jp nc,Z_8944	; 891F D2 44 89
Z_8922:
	rst 0x10	; 8922 DD 7E 02
	db 0x02
Z_8925:
	call il_iy_sub	; 8925 FD 96 02
	db 0x02
Z_8928:
	ld e,0x01	; 8928 1E 01
Z_892A:
	jp nc,Z_892F	; 892A 30 03
Z_892C:
	dec e	; 892C 1D
Z_892D:
	cpl	; 892D ED 44
	inc a
Z_892F:
	call il_iy_lda	; 892F FD 7E 02
	db 0x02
Z_8932:
	cp l	; 8932 BD
Z_8933:
	ld a,0x01	; 8933 3E 01
Z_8935:
	jp nc,Z_8938	; 8935 30 01
Z_8937:
	dec a	; 8937 3D
Z_8938:
	add a,e	; 8938 83
Z_8939:
	cp 0x01	; 8939 FE 01
Z_893B:
	jp z,Z_8A01	; 893B CA 01 8A
Z_893E:
	ld a,0x0D	; 893E 3E 0D
Z_8940:
	ret nc	; 8940 D0
Z_8941:
	ld a,0x0F	; 8941 3E 0F
Z_8943:
	ret	; 8943 C9
Z_8944:
	ld e,0x01	; 8944 1E 01
Z_8946:
	ld a,l	; 8946 7D
Z_8947:
	call il_iy_sub	; 8947 FD 96 02
	db 0x02
Z_894A:
	jp nc,Z_894F	; 894A 30 03
Z_894C:
	dec e	; 894C 1D
Z_894D:
	cpl	; 894D ED 44
	inc a
Z_894F:
	inc a	; 894F 3C
Z_8950:
	push af	; 8950 CB 87
	and 0xFE
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_8952:
	cp 0x06	; 8952 FE 06
Z_8954:
	jp nc,Z_8A01	; 8954 D2 01 8A
Z_8957:
	add a,0x06	; 8957 C6 06
Z_8959:
	dec e	; 8959 1D
Z_895A:
	jp z,Z_895E	; 895A 28 02
Z_895C:
	cpl	; 895C ED 44
	inc a
Z_895E:
	add a,l	; 895E 85
Z_895F:
	ld l,a	; 895F 6F
Z_8960:
	jp Z_8A01	; 8960 C3 01 8A
Z_8963:
	ld c,0x08	; 8963 0E 08
Z_8965:
	call il_iy_bit	; 8965 FD CB 00 66
	db 0x00, 0x10
Z_8969:
	jp z,Z_896D	; 8969 28 02
Z_896B:
	ld c,0x0A	; 896B 0E 0A
Z_896D:
	rst 0x10	; 896D DD 7E 03
	db 0x03
Z_8970:
	call il_iy_sub	; 8970 FD 96 03
	db 0x03
Z_8973:
	jp nc,Z_8977	; 8973 30 02
Z_8975:
	cpl	; 8975 ED 44
	inc a
Z_8977:
	cp c	; 8977 B9
Z_8978:
	ld d,a	; 8978 57
Z_8979:
	jp nc,Z_8A01	; 8979 D2 01 8A
Z_897C:
	call il_iy_ldb	; 897C FD 46 02
	db 0x02
Z_897F:
	push af	; 897F CB A0
	ld a,b
	and 0xEF
	ld b,a
	pop af
Z_8981:
	ld (il_a),a	; 8981 CB 38
	ld a,b
	or a
	rra
	ld b,a
	ld a,(il_a)
Z_8983:
	ld (il_a),a	; 8983 CB 38
	ld a,b
	or a
	rra
	ld b,a
	ld a,(il_a)
Z_8985:
	ld (il_a),a	; 8985 CB 38
	ld a,b
	or a
	rra
	ld b,a
	ld a,(il_a)
Z_8987:
	ld (il_a),a	; 8987 CB 38
	ld a,b
	or a
	rra
	ld b,a
	ld a,(il_a)
Z_8989:
	call il_iy_bit	; 8989 FD CB 00 66
	db 0x00, 0x10
Z_898D:
	jp z,Z_89CE	; 898D 28 3F
Z_898F:
	call il_iy_bit	; 898F FD CB FF 56
	db 0xFF, 0x04
Z_8993:
	jp nz,Z_89CE	; 8993 20 39
Z_8995:
	rst 0x10	; 8995 DD 7E 02
	db 0x02
Z_8998:
	cp l	; 8998 BD
Z_8999:
	call il_iy_bit	; 8999 FD CB FF 4E
	db 0xFF, 0x02
Z_899D:
	jp z,Z_89B3	; 899D 28 14
Z_899F:
	inc l	; 899F 2C
Z_89A0:
	inc l	; 89A0 2C
Z_89A1:
	jp nc,Z_8A01	; 89A1 30 5E
Z_89A3:
	ld a,d	; 89A3 7A
Z_89A4:
	cp 0x06	; 89A4 FE 06
Z_89A6:
	jp nc,Z_8A01	; 89A6 30 59
Z_89A8:
	ld e,0x03	; 89A8 1E 03
Z_89AA:
	ld a,0x14	; 89AA 3E 14
Z_89AC:
	sub b	; 89AC 90
Z_89AD:
	ld b,a	; 89AD 47
Z_89AE:
	ld a,h	; 89AE 7C
Z_89AF:
	sub b	; 89AF 90
Z_89B0:
	ld h,a	; 89B0 67
Z_89B1:
	jp Z_8A0E	; 89B1 18 5B
Z_89B3:
	jp c,Z_8A01	; 89B3 38 4C
Z_89B5:
	ld a,d	; 89B5 7A
Z_89B6:
	cp 0x06	; 89B6 FE 06
Z_89B8:
	jp c,Z_89BE	; 89B8 38 04
Z_89BA:
	dec l	; 89BA 2D
Z_89BB:
	dec l	; 89BB 2D
Z_89BC:
	jp Z_8A01	; 89BC 18 43
Z_89BE:
	ld e,0x01	; 89BE 1E 01
Z_89C0:
	ld a,0x62	; 89C0 3E 62
Z_89C2:
	add a,b	; 89C2 80
Z_89C3:
	ld b,0x0F	; 89C3 06 0F
Z_89C5:
	call il_iy_cp	; 89C5 FD BE 03
	db 0x03
Z_89C8:
	jp c,Z_89AE	; 89C8 38 E4
Z_89CA:
	inc h	; 89CA 24
Z_89CB:
	inc h	; 89CB 24
Z_89CC:
	jp Z_8A0E	; 89CC 18 40
Z_89CE:
	rst 0x10	; 89CE DD 7E 02
	db 0x02
Z_89D1:
	call il_iy_sub	; 89D1 FD 96 02
	db 0x02
Z_89D4:
	jp nc,Z_89D8	; 89D4 30 02
Z_89D6:
	cpl	; 89D6 ED 44
	inc a
Z_89D8:
	inc a	; 89D8 3C
Z_89D9:
	push af	; 89D9 CB 87
	and 0xFE
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_89DB:
	cp 0x04	; 89DB FE 04
Z_89DD:
	jp nc,Z_8A01	; 89DD 30 22
Z_89DF:
	call il_iy_lda	; 89DF FD 7E 02
	db 0x02
Z_89E2:
	sub l	; 89E2 95
Z_89E3:
	ld e,0x01	; 89E3 1E 01
Z_89E5:
	jp nc,Z_89EA	; 89E5 30 03
Z_89E7:
	dec e	; 89E7 1D
Z_89E8:
	cpl	; 89E8 ED 44
	inc a
Z_89EA:
	inc a	; 89EA 3C
Z_89EB:
	push af	; 89EB CB 87
	and 0xFE
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_89ED:
	cp 0x04	; 89ED FE 04
Z_89EF:
	jp nc,Z_8A01	; 89EF 30 10
Z_89F1:
	and a	; 89F1 A7
Z_89F2:
	jp nz,Z_89F8	; 89F2 20 04
Z_89F4:
	ld e,0x03	; 89F4 1E 03
Z_89F6:
	jp Z_8A0E	; 89F6 18 16
Z_89F8:
	dec e	; 89F8 1D
Z_89F9:
	ld e,0x03	; 89F9 1E 03
Z_89FB:
	jp nz,Z_8A0E	; 89FB 20 11
Z_89FD:
	ld e,0x01	; 89FD 1E 01
Z_89FF:
	jp Z_8A0E	; 89FF 18 0D
Z_8A01:
	ld a,l	; 8A01 7D
Z_8A02:
	ld e,0x00	; 8A02 1E 00
Z_8A04:
	call il_ix_cp	; 8A04 DD BE 02
	db 0x02
Z_8A07:
	jp z,Z_8A0E	; 8A07 28 05
Z_8A09:
	inc e	; 8A09 1C
Z_8A0A:
	jp c,Z_8A0E	; 8A0A 38 02
Z_8A0C:
	ld e,0x03	; 8A0C 1E 03
Z_8A0E:
	rst 0x10	; 8A0E DD 7E 03
	db 0x03
Z_8A11:
	cp h	; 8A11 BC
Z_8A12:
	ld a,e	; 8A12 7B
Z_8A13:
	jp z,Z_8A1B	; 8A13 28 06
Z_8A15:
	ld a,0x0C	; 8A15 3E 0C
Z_8A17:
	jp c,Z_8A1B	; 8A17 38 02
Z_8A19:
	ld a,0x04	; 8A19 3E 04
Z_8A1B:
	or e	; 8A1B B3
Z_8A1C:
	rst 0x08	; 8A1C DD CB F9 46
	db 0xF9, 0x01
Z_8A20:
	ret z	; 8A20 C8
Z_8A21:
	ld a,e	; 8A21 7B
Z_8A22:
	ret	; 8A22 C9
Z_8A23:
	ld a,(D_93EB)	; 8A23 3A EB 93
Z_8A26:
	ld (il_a),a	; 8A26 CB 47
	and 0x01
	ld a,(il_a)
Z_8A28:
	jp nz,Z_8A95	; 8A28 20 6B
Z_8A2A:
	ld (il_a),a	; 8A2A CB 57
	and 0x04
	ld a,(il_a)
Z_8A2C:
	jp nz,Z_8A95	; 8A2C 20 67
Z_8A2E:
	ld (il_a),a	; 8A2E CB 4F
	and 0x02
	ld a,(il_a)
Z_8A30:
	jp nz,Z_8A8E	; 8A30 20 5C
Z_8A32:
	ld (il_a),a	; 8A32 CB 5F
	and 0x08
	ld a,(il_a)
Z_8A34:
	jp nz,Z_8A89	; 8A34 20 53
Z_8A36:
	ld (il_a),a	; 8A36 CB 67
	and 0x10
	ld a,(il_a)
Z_8A38:
	jp z,Z_8A95	; 8A38 28 5B
Z_8A3A:
	ld (il_tmp),hl	; 8A3A DD 21 F1 93
	ld hl,D_93F1
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_8A3E:
	rst 0x08	; 8A3E DD CB FE 46
	db 0xFE, 0x01
Z_8A42:
	jp nz,Z_8A67	; 8A42 20 23
Z_8A44:
	rst 0x10	; 8A44 DD 7E 00
	db 0x00
Z_8A47:
	add a,0x06	; 8A47 C6 06
	jp	Z_8A49	; мост в следующий кусок
	org	0x14F8
Z_8A49:
	rst 0x20	; 8A49 DD 77 00
	db 0x00
Z_8A4C:
	call il_ix_cp	; 8A4C DD BE 02
	db 0x02
Z_8A4F:
	jp c,Z_8A95	; 8A4F 38 44
Z_8A51:
	rst 0x10	; 8A51 DD 7E 02
	db 0x02
Z_8A54:
	rst 0x20	; 8A54 DD 77 00
	db 0x00
Z_8A57:
	rst 0x28	; 8A57 DD CB FE C6
	db 0xFE, 0x01
Z_8A5B:
	jp Z_8BFE	; 8A5B C3 FE 8B
Z_8A5E:
	xor a	; 8A5E AF
Z_8A5F:
	ld (D_93EB),a	; 8A5F 32 EB 93
Z_8A62:
	call Z_8BFE	; 8A62 CD FE 8B
Z_8A65:
	jp Z_8A95	; 8A65 18 2E
Z_8A67:
	rst 0x10	; 8A67 DD 7E 00
	db 0x00
Z_8A6A:
	call il_ix_cp	; 8A6A DD BE FF
	db 0xFF
Z_8A6D:
	jp c,Z_8A76	; 8A6D 38 07
Z_8A6F:
	sub 0x06	; 8A6F D6 06
Z_8A71:
	rst 0x20	; 8A71 DD 77 00
	db 0x00
Z_8A74:
	jp Z_8A95	; 8A74 18 1F
Z_8A76:
	rst 0x10	; 8A76 DD 7E FF
	db 0xFF
Z_8A79:
	add a,0x06	; 8A79 C6 06
Z_8A7B:
	call il_ix_cp	; 8A7B DD BE 02
	db 0x02
Z_8A7E:
	jp nc,Z_8A5E	; 8A7E 30 DE
Z_8A80:
	rst 0x20	; 8A80 DD 77 FF
	db 0xFF
Z_8A83:
	rst 0x30	; 8A83 DD CB FE 86
	db 0xFE, 0xFE
Z_8A87:
	jp Z_8A95	; 8A87 18 0C
Z_8A89:
	call Z_93B5	; 8A89 CD B5 93
Z_8A8C:
	jp Z_8A95	; 8A8C 18 07
Z_8A8E:
	call il_exx	; 8A8E D9
Z_8A8F:
	push bc	; 8A8F C5
Z_8A90:
	call Z_9388	; 8A90 CD 88 93
Z_8A93:
	pop bc	; 8A93 C1
Z_8A94:
	call il_exx	; 8A94 D9
Z_8A95:
	ld (il_tmp),hl	; 8A95 DD 21 0B 94
	ld hl,D_940B
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_8A99:
	ld (il_tmp),hl	; 8A99 FD 21 25 94
	ld hl,D_9425
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_8A9D:
	ld hl,0x0690	; 8A9D 21 90 06
Z_8AA0:
	call Z_8AAE	; 8AA0 CD AE 8A
Z_8AA3:
	ld (il_tmp),hl	; 8AA3 DD 21 25 94
	ld hl,D_9425
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_8AA7:
	ld (il_tmp),hl	; 8AA7 FD 21 0B 94
	ld hl,D_940B
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_8AAB:
	ld hl,0x1990	; 8AAB 21 90 19
Z_8AAE:
	push hl	; 8AAE E5
Z_8AAF:
	call Z_8CF7	; 8AAF CD F7 8C
Z_8AB2:
	ld de,0x7750	; 8AB2 11 50 77
Z_8AB5:
	push af	; 8AB5 DD CB 01 F6
	ld (il_tmp2),hl
	ld hl,(z80_ix)
	inc hl
	ld a,(hl)
	or 0x40
	ld (hl),a
	ld hl,(il_tmp2)
	pop af
Z_8AB9:
	jp c,Z_8AC2	; 8AB9 38 07
Z_8ABB:
	rst 0x30	; 8ABB DD CB 01 B6
	db 0x01, 0xBF
Z_8ABF:
	ld de,0x7758	; 8ABF 11 58 77
Z_8AC2:
	pop hl	; 8AC2 E1
Z_8AC3:
	jp HUD_ICON	; 8AC3 C3 55 B4
Z_8ADD:
	ld hl,(D_93F3)	; 8ADD 2A F3 93
Z_8AE0:
	ld a,l	; 8AE0 7D
Z_8AE1:
	sub 0x04	; 8AE1 D6 04
Z_8AE3:
	ld l,a	; 8AE3 6F
Z_8AE4:
	ld (BLIT_Y),hl	; 8AE4 22 00 33
Z_8AE7:
	ld a,0x49	; 8AE7 3E 49
Z_8AE9:
	call Z_9394	; 8AE9 CD 94 93
Z_8AEC:
	call Z_B01C	; 8AEC CD 1C B0
Z_8AEF:
	ld hl,(D_93F3)	; 8AEF 2A F3 93
Z_8AF2:
	ld a,(D_93EB)	; 8AF2 3A EB 93
Z_8AF5:
	and 0x1A	; 8AF5 E6 1A
Z_8AF7:
	jp z,Z_8AFC	; 8AF7 28 03
Z_8AF9:
	ld hl,(D_93F1)	; 8AF9 2A F1 93
Z_8AFC:
	ld a,l	; 8AFC 7D
Z_8AFD:
	sub 0x08	; 8AFD D6 08
Z_8AFF:
	ld l,a	; 8AFF 6F
Z_8B00:
	ld (BLIT_Y),hl	; 8B00 22 00 33
Z_8B03:
	ld a,0x48	; 8B03 3E 48
Z_8B05:
	call Z_9394	; 8B05 CD 94 93
Z_8B08:
	call Z_B01C	; 8B08 CD 1C B0
Z_8B0B:
	ld (il_tmp),hl	; 8B0B DD 21 F5 93
	ld hl,D_93F5
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_8B0F:
	rst 0x08	; 8B0F DD CB 00 4E
	db 0x00, 0x02
Z_8B13:
	ret z	; 8B13 C8
Z_8B14:
	rst 0x00	; 8B14 DD 36 00 00
	db 0x00, 0x00
Z_8B18:
	ld a,(D_93EB)	; 8B18 3A EB 93
Z_8B1B:
	ld (il_a),a	; 8B1B CB 5F
	and 0x08
	ld a,(il_a)
Z_8B1D:
	jp z,Z_8B32	; 8B1D 28 13
Z_8B1F:
	and 0xE0	; 8B1F E6 E0
	jp	Z_8B21	; мост в следующий кусок
	org	0x1748
Z_8B21:
	push af	; 8B21 CB E7
	or 0x10
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_8B23:
	ld (D_93EB),a	; 8B23 32 EB 93
Z_8B26:
	ld hl,D_93F1	; 8B26 21 F1 93
Z_8B29:
	ld a,(hl)	; 8B29 7E
Z_8B2A:
	dec hl	; 8B2A 2B
Z_8B2B:
	add a,0x06	; 8B2B C6 06
Z_8B2D:
	ld (hl),a	; 8B2D 77
Z_8B2E:
	dec hl	; 8B2E 2B
Z_8B2F:
	ld (hl),0x00	; 8B2F 36 00
Z_8B31:
	ret	; 8B31 C9
	org	0x18B7
Z_8B32:
	ld a,(D_944F)	; 8B32 3A 4F 94
Z_8B35:
	ld bc,0x32	; 8B35 01 32 00
Z_8B38:
	ld l,a	; 8B38 6F
Z_8B39:
	ld h,b	; 8B39 60
Z_8B3A:
	call Z_398C	; 8B3A CD 8C 39
Z_8B3D:
	ld bc,0x46	; 8B3D 01 46 00
	jp	Z_8B40	; мост в следующий кусок
	org	0x190A
Z_8B40:
	call Z_39A3	; 8B40 CD A3 39
Z_8B43:
	ex de,hl	; 8B43 EB
Z_8B44:
	ld a,(D_9450)	; 8B44 3A 50 94
Z_8B47:
	ld bc,0x23	; 8B47 01 23 00
Z_8B4A:
	ld l,a	; 8B4A 6F
Z_8B4B:
	ld h,b	; 8B4B 60
Z_8B4C:
	call Z_398C	; 8B4C CD 8C 39
Z_8B4F:
	ld bc,0x08	; 8B4F 01 08 00
Z_8B52:
	call Z_39A3	; 8B52 CD A3 39
Z_8B55:
	add hl,de	; 8B55 19
Z_8B56:
	ex de,hl	; 8B56 EB
Z_8B57:
	ld a,(D_944E)	; 8B57 3A 4E 94
Z_8B5A:
	ld bc,0x0A	; 8B5A 01 0A 00
Z_8B5D:
	cpl	; 8B5D ED 44
	inc a
Z_8B5F:
	add a,0x16	; 8B5F C6 16
Z_8B61:
	ld l,a	; 8B61 6F
Z_8B62:
	ld h,b	; 8B62 60
Z_8B63:
	call Z_398C	; 8B63 CD 8C 39
Z_8B66:
	ld bc,0x17	; 8B66 01 17 00
Z_8B69:
	call Z_39A3	; 8B69 CD A3 39
Z_8B6C:
	add hl,de	; 8B6C 19
Z_8B6D:
	ex de,hl	; 8B6D EB
Z_8B6E:
	ld a,(D_944D)	; 8B6E 3A 4D 94
Z_8B71:
	ld bc,0x05	; 8B71 01 05 00
Z_8B74:
	cpl	; 8B74 ED 44
	inc a
Z_8B76:
	add a,0x32	; 8B76 C6 32
Z_8B78:
	ld l,a	; 8B78 6F
Z_8B79:
	ld h,b	; 8B79 60
Z_8B7A:
	call Z_398C	; 8B7A CD 8C 39
Z_8B7D:
	ld bc,0x32	; 8B7D 01 32 00
Z_8B80:
	call Z_39A3	; 8B80 CD A3 39
Z_8B83:
	add hl,de	; 8B83 19
Z_8B84:
	call Z_A172	; 8B84 CD 72 A1
Z_8B87:
	nop	; 8B87 00
Z_8B88:
	add a,0x04	; 8B88 C6 04
Z_8B8A:
	ld c,l	; 8B8A 4D
Z_8B8B:
	call Z_A0AA	; 8B8B CD AA A0
Z_8B8E:
	ld (il_a),a	; 8B8E CB 11
	ld a,c
	rla
	ld c,a
	ld a,(il_a)
Z_8B90:
	ld a,(D_93EB)	; 8B90 3A EB 93
Z_8B93:
	ld (il_a),a	; 8B93 CB 7F
	and 0x80
	ld a,(il_a)
Z_8B95:
	ld (il_tmp),hl	; 8B95 DD 21 25 94
	ld hl,D_9425
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_8B99:
	ld (il_tmp),hl	; 8B99 FD 21 0B 94
	ld hl,D_940B
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_8B9D:
	jp z,Z_8BA7	; 8B9D 28 08
Z_8B9F:
	ld (il_tmp),hl	; 8B9F DD 21 0B 94
	ld hl,D_940B
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_8BA3:
	ld (il_tmp),hl	; 8BA3 FD 21 25 94
	ld hl,D_9425
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_8BA7:
	ld a,(D_93D9)	; 8BA7 3A D9 93
Z_8BAA:
	cp 0x03	; 8BAA FE 03
Z_8BAC:
	jp nz,Z_8BBA	; 8BAC 20 0C
Z_8BAE:
	call il_ix_inc	; 8BAE DD 34 11
	db 0x11
Z_8BB1:
	ld (il_a),a	; 8BB1 CB 41
	ld a,c
	and 0x01
	ld a,(il_a)
Z_8BB3:
	jp nz,Z_8BCD	; 8BB3 20 18
Z_8BB5:
	call il_ix_inc	; 8BB5 DD 34 12
	db 0x12
Z_8BB8:
	jp Z_8BCD	; 8BB8 18 13
Z_8BBA:
	cp 0x01	; 8BBA FE 01
Z_8BBC:
	jp nz,Z_8BCA	; 8BBC 20 0C
Z_8BBE:
	call il_ix_inc	; 8BBE DD 34 0E
	db 0x0E
Z_8BC1:
	ld (il_a),a	; 8BC1 CB 41
	ld a,c
	and 0x01
	ld a,(il_a)
Z_8BC3:
	jp nz,Z_8BCD	; 8BC3 20 08
Z_8BC5:
	call il_ix_inc	; 8BC5 DD 34 0F
	db 0x0F
Z_8BC8:
	jp Z_8BCD	; 8BC8 18 03
Z_8BCA:
	call il_ix_inc	; 8BCA DD 34 0C
	db 0x0C
Z_8BCD:
	ld (il_a),a	; 8BCD CB 41
	ld a,c
	and 0x01
	ld a,(il_a)
Z_8BCF:
	jp z,Z_8C16	; 8BCF 28 45
Z_8BD1:
	ld a,(D_93EB)	; 8BD1 3A EB 93
Z_8BD4:
	push af	; 8BD4 CB 8F
	and 0xFD
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_8BD6:
	push af	; 8BD6 CB DF
	or 0x08
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_8BD8:
	ld (D_93EB),a	; 8BD8 32 EB 93
Z_8BDB:
	rst 0x10	; 8BDB DD 7E FD
	db 0xFD
Z_8BDE:
	sub 0x02	; 8BDE D6 02
Z_8BE0:
	jp nc,Z_8BE3	; 8BE0 30 01
Z_8BE2:
	xor a	; 8BE2 AF
Z_8BE3:
	rst 0x20	; 8BE3 DD 77 FD
	db 0xFD
Z_8BE6:
	call il_iy_lda	; 8BE6 FD 7E FD
	db 0xFD
Z_8BE9:
	inc a	; 8BE9 3C
Z_8BEA:
	cp 0x33	; 8BEA FE 33
Z_8BEC:
	jp z,Z_8BF1	; 8BEC 28 03
Z_8BEE:
	call il_iy_sta	; 8BEE FD 77 FD
	db 0xFD
Z_8BF1:
	call Z_8BFE	; 8BF1 CD FE 8B
Z_8BF4:
	ld a,(D_93D6)	; 8BF4 3A D6 93
Z_8BF7:
	and a	; 8BF7 A7
Z_8BF8:
	ret z	; 8BF8 C8
Z_8BF9:
	ld e,0x03	; 8BF9 1E 03
Z_8BFB:
	jp Z_93B2	; 8BFB C3 B2 93
Z_8BFE:
	ld a,(D_93D8)	; 8BFE 3A D8 93
Z_8C01:
	and a	; 8C01 A7
Z_8C02:
	ret nz	; 8C02 C0
Z_8C03:
	inc a	; 8C03 3C
Z_8C04:
	ld (D_AA83),a	; 8C04 32 83 AA
Z_8C07:
	ld hl,0x02	; 8C07 21 02 00
Z_8C0A:
	ld (BLIT_Y),hl	; 8C0A 22 00 33
Z_8C0D:
	ld hl,0x8070	; 8C0D 21 70 80
Z_8C10:
	ld (BLIT_SRC),hl	; 8C10 22 02 33
Z_8C13:
	jp Z_AA80	; 8C13 C3 80 AA
Z_8C16:
	ld a,(D_93D9)	; 8C16 3A D9 93
Z_8C19:
	cp 0x02	; 8C19 FE 02
Z_8C1B:
	jp nz,Z_8C20	; 8C1B 20 03
Z_8C1D:
	call il_ix_inc	; 8C1D DD 34 0D
	db 0x0D
Z_8C20:
	ld a,(D_93EB)	; 8C20 3A EB 93
Z_8C23:
	push af	; 8C23 CB 8F
	and 0xFD
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_8C25:
	push af	; 8C25 CB D7
	or 0x04
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_8C27:
	ld (D_93EB),a	; 8C27 32 EB 93
Z_8C2A:
	ld de,D_93DC	; 8C2A 11 DC 93
Z_8C2D:
	push hl	; 8C2D ED 53 DA 93
	ld h,d
	ld l,e
	ld (D_93DA),hl
	pop hl
Z_8C31:
	rst 0x10	; 8C31 DD 7E FD
	db 0xFD
Z_8C34:
	add a,0x02	; 8C34 C6 02
Z_8C36:
	cp 0x32	; 8C36 FE 32
Z_8C38:
	jp c,Z_8C3C	; 8C38 38 02
Z_8C3A:
	ld a,0x32	; 8C3A 3E 32
Z_8C3C:
	rst 0x20	; 8C3C DD 77 FD
	db 0xFD
Z_8C3F:
	call il_iy_lda	; 8C3F FD 7E FD
	db 0xFD
Z_8C42:
	and a	; 8C42 A7
Z_8C43:
	jp z,Z_8C48	; 8C43 28 03
Z_8C45:
	call il_iy_dec	; 8C45 FD 35 FD
	db 0xFD
Z_8C48:
	rst 0x08	; 8C48 DD CB 00 6E
	db 0x00, 0x20
Z_8C4C:
	ret nz	; 8C4C C0
Z_8C4D:
	xor a	; 8C4D AF
Z_8C4E:
	ld (D_AA83),a	; 8C4E 32 83 AA
Z_8C51:
	ld hl,0x02	; 8C51 21 02 00
Z_8C54:
	ld (BLIT_Y),hl	; 8C54 22 00 33
Z_8C57:
	ld hl,0x8039	; 8C57 21 39 80
Z_8C5A:
	ld (BLIT_SRC),hl	; 8C5A 22 02 33
Z_8C5D:
	jp Z_AA80	; 8C5D C3 80 AA
Z_8C60:
	ld hl,0x0418	; 8C60 21 18 04
Z_8C63:
	ld de,D_9402	; 8C63 11 02 94
Z_8C66:
	ld (il_tmp),hl	; 8C66 DD 21 25 94
	ld hl,D_9425
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_8C6A:
	call Z_8C77	; 8C6A CD 77 8C
Z_8C6D:
	ld hl,0x7018	; 8C6D 21 18 70
Z_8C70:
	ld de,D_9401	; 8C70 11 01 94
Z_8C73:
	ld (il_tmp),hl	; 8C73 DD 21 0B 94
	ld hl,D_940B
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_8C77:
	push hl	; 8C77 E5
Z_8C78:
	ld a,(D_93EB)	; 8C78 3A EB 93
Z_8C7B:
	ld c,a	; 8C7B 4F
Z_8C7C:
	ld (il_a),a	; 8C7C CB 57
	and 0x04
	ld a,(il_a)
Z_8C7E:
	ld a,0x3E	; 8C7E 3E 3E
Z_8C80:
	jp z,Z_8CE7	; 8C80 28 65
Z_8C82:
	ld (il_a),a	; 8C82 CB 01
	ld a,c
	rlca
	ld c,a
	ld a,(il_a)
Z_8C84:
	rst 0x10	; 8C84 DD 7E 01
	db 0x01
Z_8C87:
	xor c	; 8C87 A9
Z_8C88:
	and 0x01	; 8C88 E6 01
Z_8C8A:
	ld a,0x3E	; 8C8A 3E 3E
Z_8C8C:
	jp nz,Z_8CE7	; 8C8C 20 59
Z_8C8E:
	ld hl,(D_93DA)	; 8C8E 2A DA 93
Z_8C91:
	ld a,(hl)	; 8C91 7E
Z_8C92:
	inc hl	; 8C92 23
Z_8C93:
	ld (D_93DA),hl	; 8C93 22 DA 93
Z_8C96:
	cp 0xFF	; 8C96 FE FF
Z_8C98:
	jp nz,Z_8CE7	; 8C98 20 4D
Z_8C9A:
	ld hl,D_93F1	; 8C9A 21 F1 93
Z_8C9D:
	ld a,0x2A	; 8C9D 3E 2A
Z_8C9F:
	ld (hl),a	; 8C9F 77
Z_8CA0:
	dec hl	; 8CA0 2B
Z_8CA1:
	add a,0x08	; 8CA1 C6 08
Z_8CA3:
	ld (hl),a	; 8CA3 77
Z_8CA4:
	dec hl	; 8CA4 2B
Z_8CA5:
	ld (hl),0x00	; 8CA5 36 00
Z_8CA7:
	ld a,(D_93EB)	; 8CA7 3A EB 93
Z_8CAA:
	push af	; 8CAA CB 97
	and 0xFB
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_8CAC:
	push af	; 8CAC CB E7
	or 0x10
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_8CAE:
	ld (D_93EB),a	; 8CAE 32 EB 93
Z_8CB1:
	ld a,(D_9400)	; 8CB1 3A 00 94
Z_8CB4:
	and a	; 8CB4 A7
Z_8CB5:
	jp z,Z_8CC2	; 8CB5 28 0B
Z_8CB7:
	and 0x80	; 8CB7 E6 80
Z_8CB9:
	ld c,a	; 8CB9 4F
Z_8CBA:
	ld a,(D_93EB)	; 8CBA 3A EB 93
Z_8CBD:
	and 0x80	; 8CBD E6 80
Z_8CBF:
	xor c	; 8CBF A9
Z_8CC0:
	jp z,Z_8CD4	; 8CC0 28 12
Z_8CC2:
	ld a,(D_93D9)	; 8CC2 3A D9 93
Z_8CC5:
	ex de,hl	; 8CC5 EB
Z_8CC6:
	add a,(hl)	; 8CC6 86
Z_8CC7:
	ld (hl),a	; 8CC7 77
	jp	Z_8CC8	; мост в следующий кусок
	org	0x3304
D_3304:
Z_3304:
	db	0x04, 0xCA, 0x84, 0x4A	; 3304
	org	0x3308
D_3308:
Z_3308:
	db	0x84, 0x4A	; 3308
	org	0x330A
D_330A:
Z_330A:
	db	0x04, 0x4A, 0x04, 0xCA, 0x14, 0x4A, 0x04, 0x4A, 0x94, 0x4A	; 330A
	org	0x3314
D_3314:
Z_3314:
	db	0x14, 0xC2, 0x14, 0x4A, 0x04, 0x42, 0x04, 0xCA, 0x04, 0x42, 0x16, 0x4A, 0x16, 0x42, 0x14, 0x4A	; 3314
	org	0x3324
D_3324:
Z_3324:
	db	0x04, 0x42, 0x14, 0xCA, 0x04, 0x4A, 0x04, 0xCA, 0x04, 0x4A, 0x04, 0xCA, 0x04, 0x4A	; 3324
	org	0x3332
D_3332:
Z_3332:
	db	0x04	; 3332
	org	0x3333
D_3333:
Z_3333:
	db	0xCA, 0x04, 0x48, 0x04, 0xCA, 0x04, 0x4A, 0x04, 0xCA, 0x94, 0x4A, 0x04, 0xCA, 0x04, 0x4A, 0x14	; 3333
	org	0x3343
D_3343:
Z_3343:
	db	0xCA, 0x04, 0x4A, 0x94, 0xCA, 0x14, 0x4A, 0x04, 0xCA, 0x04, 0x4A, 0x04, 0xCA, 0x04, 0x4A, 0x04	; 3343
	org	0x3353
D_3353:
Z_3353:
	db	0xCA, 0x14, 0x4A, 0x04, 0xCA, 0x14, 0x48, 0x14, 0xCA, 0x16, 0x48, 0x14, 0xCA, 0x14, 0x48, 0x15	; 3353
	org	0x3363
D_3363:
Z_3363:
	db	0xCA, 0x16, 0xC8, 0x17, 0xCA, 0x03, 0xB9, 0x4B, 0x35, 0x6B, 0x11, 0x6B, 0x11, 0x6B, 0x90, 0x6B	; 3363
	org	0x3373
D_3373:
Z_3373:
	db	0x15, 0x6B, 0x10, 0x6B, 0x95, 0x6B, 0x90, 0x6B, 0x15, 0x6B, 0x10, 0x6B, 0x11, 0x7B, 0x91, 0x6B	; 3373
	org	0x3383
D_3383:
Z_3383:
	db	0x95, 0x7B, 0x10, 0x6B, 0x95, 0x7B, 0x10, 0x6B, 0x11, 0x7B, 0x10, 0x6B, 0x90, 0x6B, 0x10, 0x6B	; 3383
	org	0x3393
D_3393:
Z_3393:
	db	0x10, 0x6B, 0x90, 0x6B, 0x90, 0x7B, 0x90, 0x6B, 0x10, 0x6B, 0x10, 0x6B, 0x10, 0x7B, 0x10, 0x6B	; 3393
	org	0x33A3
D_33A3:
Z_33A3:
	db	0x90, 0x7B, 0x10, 0x6B, 0x15, 0x6B, 0x15, 0x6B, 0x35, 0x7B, 0x15, 0x7B, 0x31, 0x7F, 0x11, 0x7B	; 33A3
	org	0x33B3
D_33B3:
Z_33B3:
	db	0x11, 0x7F, 0x11, 0x7B, 0x11, 0x6B, 0x95, 0x6B, 0x90, 0x6B, 0x10, 0x6B, 0x10, 0x6B, 0x15, 0x6B	; 33B3
	org	0x33C3
D_33C3:
Z_33C3:
	db	0x90, 0x6B, 0x91, 0x6B, 0x90, 0xC3, 0x58, 0xD3, 0xC3, 0x1B, 0xD6, 0xC3, 0x80, 0xD6, 0xC3, 0xC7	; 33C3
	org	0x33D3
D_33D3:
Z_33D3:
	db	0xD7, 0xC3, 0x24, 0xD7, 0xC3, 0x5B, 0xD7, 0xC3, 0x3B, 0xD7, 0xC3, 0x69, 0xD7, 0xC3, 0x6F, 0xD4	; 33D3
	org	0x33E3
D_33E3:
Z_33E3:
	db	0xC3, 0xF8, 0xD5, 0xC3, 0x06, 0xD6, 0xC3, 0x45, 0xD5, 0xC3, 0x3C, 0xD5, 0xC3, 0xCA, 0xD4, 0xC3	; 33E3
	org	0x33F3
D_33F3:
Z_33F3:
	db	0x55, 0xD5, 0xC3, 0x6C, 0xD6, 0xC3, 0x4D, 0xD5, 0xC3, 0x3C, 0xD6, 0xC3, 0xC4, 0xD7, 0xC3, 0xB8	; 33F3
	org	0x3403
D_3403:
Z_3403:
	db	0xD8, 0xC3, 0xFC, 0xD7, 0xC3, 0xF9, 0xD7, 0xC3, 0x64, 0xD5, 0xC3, 0xDE, 0xD5, 0xC3, 0x41, 0xD2	; 3403
	org	0x3413
D_3413:
Z_3413:
	db	0xC3, 0x4C, 0xD2, 0xC3, 0x7E, 0xD7, 0x00, 0x00	; 3413
	org	0x341B
D_341B:
Z_341B:
	db	0x08	; 341B
	org	0x341C
D_341C:
Z_341C:
	db	0x00	; 341C
	org	0x341D
D_341D:
Z_341D:
	db	0x20	; 341D
	org	0x341E
D_341E:
Z_341E:
	db	0x28, 0xA0	; 341E
	org	0x3420
D_3420:
Z_3420:
	db	0xE0, 0xAB	; 3420
	org	0x3422
D_3422:
Z_3422:
	db	0x00, 0x00	; 3422
	org	0x3424
D_3424:
Z_3424:
	db	0xF1, 0xF1, 0xF1, 0xF1, 0xF1, 0xF1, 0xF1, 0xF1, 0x02	; 3424
	org	0x342D
D_342D:
Z_342D:
	db	0xE0, 0x06, 0xFF, 0x03, 0x36, 0x07	; 342D
	org	0x3433
D_3433:
Z_3433:
	db	0x04	; 3433
	org	0x3434
D_3434:
Z_3434:
	db	0x80, 0x3B	; 3434
	org	0x3436
D_3436:
Z_3436:
	db	0x38, 0x34, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x2D, 0x3D, 0x5C, 0x28	; 3436
	org	0x3446
D_3446:
Z_3446:
	db	0x29, 0x3A, 0x2C, 0x3B, 0x2C, 0x26, 0x2F, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48	; 3446
	org	0x3456
D_3456:
Z_3456:
	db	0x49, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58	; 3456
	org	0x3466
D_3466:
Z_3466:
	db	0x59, 0x5A, 0x01, 0x02, 0x03, 0x04, 0x06, 0x31, 0x32, 0x33, 0x34, 0x35, 0x00, 0x09, 0x0A, 0x10	; 3466
	org	0x3476
D_3476:
Z_3476:
	db	0x0B, 0x0D, 0x20, 0x14, 0x15, 0x16, 0x10, 0x02, 0x01, 0x09, 0xFF, 0xDF, 0x5F, 0x7F, 0x3F, 0xBF	; 3476
	org	0x3486
D_3486:
Z_3486:
	db	0xAF, 0xEF, 0xCF	; 3486
	org	0x3489
D_3489:
Z_3489:
	db	0x00	; 3489
	org	0x348A
D_348A:
Z_348A:
	db	0x00, 0x00, 0x00	; 348A
	org	0x348D
D_348D:
Z_348D:
	db	0x00	; 348D
	org	0x348E
D_348E:
Z_348E:
	db	0x00	; 348E
	org	0x348F
D_348F:
Z_348F:
	db	0x00, 0x00, 0x44, 0x69, 0x4E, 0x61, 0x4D, 0x69, 0x43	; 348F
	org	0x3498
D_3498:
Z_3498:
	db	0x49, 0x6E, 0x73, 0x75, 0x66, 0x69, 0x63, 0x69, 0x65, 0x6E, 0x74, 0x65, 0x20, 0x52, 0x61, 0x6D	; 3498
	org	0x34A8
D_34A8:
Z_34A8:
	db	0x2B, 0x3A, 0x1C, 0x34, 0xB7, 0x00, 0x00	; 34A8
	org	0x34B4
D_34B4:
Z_34B4:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 34B4
	org	0x352B
Z_8CC8:
	ld a,(D_93D3)	; 8CC8 3A D3 93
Z_8CCB:
	dec a	; 8CCB 3D
Z_8CCC:
	call nz,Z_93AC	; 8CCC C4 AC 93
Z_8CCF:
	ld e,0x44	; 8CCF 1E 44
Z_8CD1:
	call Z_93B2	; 8CD1 CD B2 93
Z_8CD4:
	ld a,(D_93F4)	; 8CD4 3A F4 93
Z_8CD7:
	ld h,a	; 8CD7 67
Z_8CD8:
	ld l,0x22	; 8CD8 2E 22
Z_8CDA:
	ld (BLIT_Y),hl	; 8CDA 22 00 33
Z_8CDD:
	ld a,0x48	; 8CDD 3E 48
Z_8CDF:
	call Z_9394	; 8CDF CD 94 93
Z_8CE2:
	call Z_B01C	; 8CE2 CD 1C B0
Z_8CE5:
	ld a,0x42	; 8CE5 3E 42
Z_8CE7:
	pop hl	; 8CE7 E1
Z_8CE8:
	ld (BLIT_Y),hl	; 8CE8 22 00 33
Z_8CEB:
	ld (il_a),a	; 8CEB CB 74
	ld a,h
	and 0x40
	ld a,(il_a)
Z_8CED:
	jp z,Z_8CF1	; 8CED 28 02
Z_8CEF:
	add a,0x05	; 8CEF C6 05
Z_8CF1:
	call Z_9394	; 8CF1 CD 94 93
Z_8CF4:
	jp Z_B01C	; 8CF4 C3 1C B0
Z_8CF7:
	ld c,0x00	; 8CF7 0E 00
Z_8CF9:
	ld a,(D_93EB)	; 8CF9 3A EB 93
Z_8CFC:
	ld (il_a),a	; 8CFC CB 6F
	and 0x20
	ld a,(il_a)
Z_8CFE:
	jp nz,Z_8D08	; 8CFE 20 08
Z_8D00:
	ld (il_a),a	; 8D00 CB 47
	and 0x01
	ld a,(il_a)
Z_8D02:
	jp nz,Z_8D33	; 8D02 20 2F
Z_8D04:
	ld (il_a),a	; 8D04 CB 57
	and 0x04
	ld a,(il_a)
Z_8D06:
	jp z,Z_8D10	; 8D06 28 08
Z_8D08:
	and a	; 8D08 A7
Z_8D09:
	rst 0x08	; 8D09 DD CB 00 66
	db 0x00, 0x10
Z_8D0D:
	ret z	; 8D0D C8
Z_8D0E:
	scf	; 8D0E 37
Z_8D0F:
	ret	; 8D0F C9
Z_8D10:
	ld (il_a),a	; 8D10 CB 4F
	and 0x02
	ld a,(il_a)
Z_8D12:
	jp nz,Z_8D2C	; 8D12 20 18
Z_8D14:
	ld (il_a),a	; 8D14 CB 5F
	and 0x08
	ld a,(il_a)
Z_8D16:
	jp z,Z_8D22	; 8D16 28 0A
Z_8D18:
	ld c,0xE6	; 8D18 0E E6
Z_8D1A:
	rst 0x08	; 8D1A DD CB 00 46
	db 0x00, 0x01
Z_8D1E:
	jp z,Z_8D2E	; 8D1E 28 0E
Z_8D20:
	jp Z_8D2C	; 8D20 18 0A
Z_8D22:
	ld (il_a),a	; 8D22 CB 67
	and 0x10
	ld a,(il_a)
Z_8D24:
	jp z,Z_8D72	; 8D24 28 4C
Z_8D26:
	rst 0x08	; 8D26 DD CB 00 46
	db 0x00, 0x01
Z_8D2A:
	jp z,Z_8D72	; 8D2A 28 46
Z_8D2C:
	ld c,0xE2	; 8D2C 0E E2
Z_8D2E:
	ld hl,(D_93F1)	; 8D2E 2A F1 93
Z_8D31:
	jp Z_8D45	; 8D31 18 12
Z_8D33:
	scf	; 8D33 37
Z_8D34:
	rst 0x08	; 8D34 DD CB 00 66
	db 0x00, 0x10
Z_8D38:
	ret nz	; 8D38 C0
Z_8D39:
	ld hl,(D_93F3)	; 8D39 2A F3 93
Z_8D3C:
	call il_iy_bit	; 8D3C FD CB 00 46
	db 0x00, 0x01
Z_8D40:
	jp z,Z_8D45	; 8D40 28 03
Z_8D42:
	call il_iy_ldl	; 8D42 FD 6E 04
	db 0x04
Z_8D45:
	push hl	; 8D45 E5
Z_8D46:
	push bc	; 8D46 C5
Z_8D47:
	call Z_8D72	; 8D47 CD 72 8D
Z_8D4A:
	pop bc	; 8D4A C1
Z_8D4B:
	pop hl	; 8D4B E1
Z_8D4C:
	ret nc	; 8D4C D0
Z_8D4D:
	call il_ix_lde	; 8D4D DD 5E 02
	db 0x02
Z_8D50:
	call il_ix_ldd	; 8D50 DD 56 03
	db 0x03
Z_8D53:
	rst 0x08	; 8D53 DD CB 00 46
	db 0x00, 0x01
Z_8D57:
	jp z,Z_8D5F	; 8D57 28 06
Z_8D59:
	call il_ix_lde	; 8D59 DD 5E 04
	db 0x04
Z_8D5C:
	call il_ix_ldd	; 8D5C DD 56 05
	db 0x05
Z_8D5F:
	call il_iy_bit	; 8D5F FD CB 00 46
	db 0x00, 0x01
Z_8D63:
	jp z,Z_8D7D	; 8D63 28 18
Z_8D65:
	ld a,l	; 8D65 7D
Z_8D66:
	sub e	; 8D66 93
Z_8D67:
	jp nc,Z_8D6C	; 8D67 30 03
Z_8D69:
	cpl	; 8D69 ED 44
	inc a
Z_8D6B:
	add a,a	; 8D6B 87
Z_8D6C:
	cpl	; 8D6C ED 44
	inc a
Z_8D6E:
	add a,c	; 8D6E 81
Z_8D6F:
	ld c,a	; 8D6F 4F
Z_8D70:
	jp Z_8D7D	; 8D70 18 0B
Z_8D72:
	ld hl,(D_93F3)	; 8D72 2A F3 93
Z_8D75:
	call il_ix_lde	; 8D75 DD 5E 02
	db 0x02
Z_8D78:
	call il_ix_ldd	; 8D78 DD 56 03
	db 0x03
Z_8D7B:
	ld c,0x00	; 8D7B 0E 00
Z_8D7D:
	ld a,e	; 8D7D 7B
Z_8D7E:
	add a,c	; 8D7E 81
Z_8D7F:
	ld e,a	; 8D7F 5F
Z_8D80:
	rst 0x08	; 8D80 DD CB FF 56
	db 0xFF, 0x04
Z_8D84:
	jp z,Z_8DD6	; 8D84 28 50
Z_8D86:
	ld c,0x08	; 8D86 0E 08
Z_8D88:
	ld b,0x04	; 8D88 06 04
Z_8D8A:
	call il_iy_bit	; 8D8A FD CB 00 66
	db 0x00, 0x10
	jp	Z_8D8E	; мост в следующий кусок
	org	0x3636
D_3636:
Z_3636:
	db	0x00, 0x04, 0xC5, 0x05, 0x28, 0x04, 0x0F, 0x0F, 0x18, 0xF9, 0xE6, 0x03, 0x5F, 0x16, 0x00, 0x21	; 3636
	org	0x3646
D_3646:
Z_3646:
	db	0xC1, 0xFC, 0x19, 0x5F, 0x7E, 0xE6, 0x80, 0xB3, 0x5F, 0x23, 0x23, 0x23, 0x23, 0x7E	; 3646
	org	0x3654
D_3654:
Z_3654:
	db	0xC1, 0x05, 0x28, 0x04, 0x0F, 0x0F, 0x18, 0xF9, 0x07, 0x07, 0xE6, 0x0C, 0xB3, 0xC9	; 3654
	org	0x3664
D_3664:
Z_3664:
	db	0x00, 0x00, 0x5F, 0x16, 0x00, 0x21, 0xC1, 0xFC, 0x19, 0xCB, 0x7E, 0x20, 0x1E, 0x3A, 0x25, 0xD2	; 3664
	org	0x3674
D_3674:
Z_3674:
	db	0x67, 0x3A, 0x23, 0xD2, 0x32, 0x26, 0xD2, 0xCD, 0x24, 0x00, 0xCD, 0x53, 0xD4, 0x20, 0x02, 0xAF	; 3674
	org	0x3684
D_3684:
Z_3684:
	db	0xC9, 0x3A, 0x23, 0xD2, 0x3C, 0xFE, 0x04, 0x38, 0xD6, 0x37, 0xC9, 0xAF, 0x32, 0x24, 0xD2, 0x07	; 3684
	org	0x3694
D_3694:
Z_3694:
	db	0x07, 0xE6, 0x0C, 0xCB, 0xFF, 0x5F, 0x3A, 0x23, 0xD2, 0xB3, 0x5F, 0x3A, 0x25, 0xD2, 0x67, 0x7B	; 3694
	org	0x36A4
D_36A4:
Z_36A4:
	db	0x32, 0x26, 0xD2, 0xCD, 0x24, 0x00, 0xCD, 0x53, 0xD4, 0x20, 0x02, 0xAF, 0xC9, 0x3A, 0x24, 0xD2	; 36A4
	org	0x36B4
D_36B4:
Z_36B4:
	db	0x3C, 0xFE, 0x04, 0x38, 0xD7, 0x18, 0xCA, 0x3A, 0x25, 0xD2, 0x57, 0x1E, 0x00, 0x21, 0x29, 0xD2	; 36B4
	org	0x36C4
D_36C4:
Z_36C4:
	db	0xD5, 0xE5, 0x01, 0x07, 0x00, 0xED, 0xB0, 0xE1, 0xD1, 0x06, 0x07, 0x1A, 0xBE, 0xC0, 0x13, 0x23	; 36C4
	org	0x36D4
D_36D4:
Z_36D4:
	db	0x10, 0xF9, 0xC9	; 36D4
	org	0x36D7
Z_8D8E:
	jp z,Z_8DC0	; 8D8E 28 30
Z_8D90:
	ld c,0x06	; 8D90 0E 06
Z_8D92:
	call il_iy_bit	; 8D92 FD CB FF 56
	db 0xFF, 0x04
Z_8D96:
	jp z,Z_8DB4	; 8D96 28 1C
Z_8D98:
	ld b,0x03	; 8D98 06 03
Z_8D9A:
	call il_iy_bit	; 8D9A FD CB FF 5E
	db 0xFF, 0x08
	jp	Z_8D9E	; мост в следующий кусок
	org	0x36F0
D_36F0:
Z_36F0:
	db	0xC3, 0x9B, 0x40	; 36F0
	org	0x36F3
Z_8D9E:
	jp nz,Z_8DAB	; 8D9E 20 0B
Z_8DA0:
	ld b,0x06	; 8DA0 06 06
Z_8DA2:
	rst 0x08	; 8DA2 DD CB FF 5E
	db 0xFF, 0x08
Z_8DA6:
	jp nz,Z_8DC0	; 8DA6 20 18
Z_8DA8:
	dec b	; 8DA8 05
Z_8DA9:
	jp Z_8DC0	; 8DA9 18 15
Z_8DAB:
	rst 0x08	; 8DAB DD CB FF 5E
	db 0xFF, 0x08
Z_8DAF:
	jp z,Z_8DC0	; 8DAF 28 0F
Z_8DB1:
	inc b	; 8DB1 04
Z_8DB2:
	jp Z_8DC0	; 8DB2 18 0C
Z_8DB4:
	ld b,0x06	; 8DB4 06 06
Z_8DB6:
	ld c,b	; 8DB6 48
Z_8DB7:
	call il_iy_bit	; 8DB7 FD CB FF 4E
	db 0xFF, 0x02
Z_8DBB:
	jp nz,Z_8DC0	; 8DBB 20 03
Z_8DBD:
	ld b,0x04	; 8DBD 06 04
Z_8DBF:
	inc c	; 8DBF 0C
Z_8DC0:
	ld a,d	; 8DC0 7A
Z_8DC1:
	add a,b	; 8DC1 80
Z_8DC2:
	ld d,a	; 8DC2 57
Z_8DC3:
	rst 0x08	; 8DC3 DD CB FF 5E
	db 0xFF, 0x08
Z_8DC7:
	jp z,Z_8DCB	; 8DC7 28 02
Z_8DC9:
	ld d,h	; 8DC9 54
	jp	Z_8DCA	; мост в следующий кусок
	org	0x3727
D_3727:
Z_3727:
	db	0x00, 0x00, 0x00, 0x00, 0xC9	; 3727
	org	0x372C
Z_8DCA:
	ld h,a	; 8DCA 67
Z_8DCB:
	ld a,d	; 8DCB 7A
Z_8DCC:
	sub h	; 8DCC 94
Z_8DCD:
	cp c	; 8DCD B9
Z_8DCE:
	ret nc	; 8DCE D0
Z_8DCF:
	ld a,e	; 8DCF 7B
Z_8DD0:
	add a,0x04	; 8DD0 C6 04
Z_8DD2:
	sub l	; 8DD2 95
Z_8DD3:
	cp 0x09	; 8DD3 FE 09
Z_8DD5:
	ret	; 8DD5 C9
Z_8DD6:
	ld c,0x06	; 8DD6 0E 06
Z_8DD8:
	ld a,e	; 8DD8 7B
Z_8DD9:
	call il_iy_bit	; 8DD9 FD CB 00 66
	db 0x00, 0x10
Z_8DDD:
	jp z,Z_8E37	; 8DDD 28 58
Z_8DDF:
	call il_iy_bit	; 8DDF FD CB FF 56
	db 0xFF, 0x04
Z_8DE3:
	jp z,Z_8DF0	; 8DE3 28 0B
Z_8DE5:
	dec a	; 8DE5 3D
Z_8DE6:
	dec c	; 8DE6 0D
Z_8DE7:
	rst 0x08	; 8DE7 DD CB FF 4E
	db 0xFF, 0x02
Z_8DEB:
	jp z,Z_8E30	; 8DEB 28 43
Z_8DED:
	dec a	; 8DED 3D
Z_8DEE:
	jp Z_8E30	; 8DEE 18 40
Z_8DF0:
	call il_iy_bit	; 8DF0 FD CB FF 4E
	db 0xFF, 0x02
	jp	Z_8DF4	; мост в следующий кусок
	org	0x3761
D_3761:
Z_3761:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 3761
	org	0x3769
Z_8DF4:
	jp z,Z_8E0E	; 8DF4 28 18
Z_8DF6:
	ld c,0x03	; 8DF6 0E 03
Z_8DF8:
	add a,0x04	; 8DF8 C6 04
Z_8DFA:
	ld e,a	; 8DFA 5F
Z_8DFB:
	rst 0x08	; 8DFB DD CB FF 4E
	db 0xFF, 0x02
Z_8DFF:
	jp nz,Z_8E27	; 8DFF 20 26
Z_8E01:
	add a,0x04	; 8E01 C6 04
Z_8E03:
	ld e,a	; 8E03 5F
Z_8E04:
	inc c	; 8E04 0C
Z_8E05:
	rst 0x08	; 8E05 DD CB 01 46
	db 0x01, 0x01
Z_8E09:
	jp nz,Z_8E40	; 8E09 20 35
Z_8E0B:
	inc c	; 8E0B 0C
Z_8E0C:
	jp Z_8E40	; 8E0C 18 32
Z_8E0E:
	ld c,0x05	; 8E0E 0E 05
Z_8E10:
	add a,0x02	; 8E10 C6 02
Z_8E12:
	ld e,a	; 8E12 5F
Z_8E13:
	rst 0x08	; 8E13 DD CB FF 4E
	db 0xFF, 0x02
	jp	Z_8E17	; мост в следующий кусок
	org	0x3790
D_3790:
Z_3790:
	db	0x00	; 3790
	org	0x3791
Z_8E17:
	jp nz,Z_8E27	; 8E17 20 0E
Z_8E19:
	add a,0x04	; 8E19 C6 04
Z_8E1B:
	ld e,a	; 8E1B 5F
Z_8E1C:
	ld c,0x02	; 8E1C 0E 02
Z_8E1E:
	rst 0x08	; 8E1E DD CB 01 46
	db 0x01, 0x01
Z_8E22:
	jp nz,Z_8E40	; 8E22 20 1C
Z_8E24:
	inc c	; 8E24 0C
Z_8E25:
	jp Z_8E40	; 8E25 18 19
Z_8E27:
	rst 0x08	; 8E27 DD CB 01 46
	db 0x01, 0x01
Z_8E2B:
	jp nz,Z_8E44	; 8E2B 20 17
Z_8E2D:
	dec c	; 8E2D 0D
	jp	Z_8E2E	; мост в следующий кусок
	org	0x37AD
D_37AD:
Z_37AD:
	db	0x32, 0xCB, 0xD1, 0x47, 0x0E, 0x07, 0x18, 0xAB, 0x47, 0x3A, 0xBC, 0xD1, 0xE6, 0xF0, 0x18, 0x0A	; 37AD
	org	0x37BD
Z_8E2E:
	jp Z_8E44	; 8E2E 18 14
Z_8E30:
	rst 0x08	; 8E30 DD CB 01 46
	db 0x01, 0x01
Z_8E34:
	jp nz,Z_8E37	; 8E34 20 01
Z_8E36:
	inc a	; 8E36 3C
Z_8E37:
	add a,0x06	; 8E37 C6 06
Z_8E39:
	ld e,a	; 8E39 5F
Z_8E3A:
	rst 0x08	; 8E3A DD CB FF 4E
	db 0xFF, 0x02
Z_8E3E:
	jp nz,Z_8E44	; 8E3E 20 04
Z_8E40:
	sub 0x0A	; 8E40 D6 0A
	jp	Z_8E42	; мост в следующий кусок
	org	0x37D5
D_37D5:
Z_37D5:
	db	0xAF, 0xF5, 0xCD, 0x41, 0x01, 0xF3, 0x77, 0x23, 0xF1, 0x3C, 0xFE, 0x09, 0x38, 0xF3, 0x3E, 0x01	; 37D5
	org	0x37E5
D_37E5:
Z_37E5:
	db	0x32, 0x21, 0x41, 0xCD, 0xF1, 0x37, 0x3E, 0x02, 0x32, 0x21, 0x41, 0x3D, 0xE5, 0xCD, 0xD5, 0x00	; 37E5
	org	0x37F5
D_37F5:
Z_37F5:
	db	0xF3, 0x21, 0x80, 0x34, 0x5F, 0x16, 0x00, 0x19, 0x7E, 0xE1, 0x77, 0xE5, 0x3A, 0x21, 0x41, 0xCD	; 37F5
	org	0x3805
D_3805:
Z_3805:
	db	0xD8, 0x00, 0xF3, 0xE1, 0xFE, 0xFF, 0x20, 0x02, 0xCB, 0x86, 0x23, 0xC9	; 3805
	org	0x3811
Z_8E42:
	ld e,l	; 8E42 5D
Z_8E43:
	ld l,a	; 8E43 6F
Z_8E44:
	ld a,e	; 8E44 7B
Z_8E45:
	sub l	; 8E45 95
Z_8E46:
	cp c	; 8E46 B9
Z_8E47:
	ret nc	; 8E47 D0
Z_8E48:
	ld a,d	; 8E48 7A
Z_8E49:
	add a,0x0D	; 8E49 C6 0D
Z_8E4B:
	rst 0x08	; 8E4B DD CB FF 4E
	db 0xFF, 0x02
Z_8E4F:
	ld c,0x10	; 8E4F 0E 10
Z_8E51:
	jp z,Z_8E57	; 8E51 28 04
Z_8E53:
	dec c	; 8E53 0D
Z_8E54:
	dec c	; 8E54 0D
Z_8E55:
	dec a	; 8E55 3D
Z_8E56:
	dec a	; 8E56 3D
Z_8E57:
	sub h	; 8E57 94
Z_8E58:
	cp c	; 8E58 B9
Z_8E59:
	ret	; 8E59 C9
Z_8E5A:
	rst 0x30	; 8E5A DD CB FE A6
	db 0xFE, 0xEF
Z_8E5E:
	rst 0x08	; 8E5E DD CB 00 66
	db 0x00, 0x10
Z_8E62:
	jp nz,Z_8F0F	; 8E62 C2 0F 8F
Z_8E65:
	rst 0x08	; 8E65 DD CB 01 76
	db 0x01, 0x40
Z_8E69:
	jp z,Z_8F00	; 8E69 CA 00 8F
Z_8E6C:
	rst 0x08	; 8E6C DD CB 01 5E
	db 0x01, 0x08
Z_8E70:
	jp nz,Z_8F00	; 8E70 C2 00 8F
Z_8E73:
	ld a,(D_93EB)	; 8E73 3A EB 93
Z_8E76:
	ld (il_a),a	; 8E76 CB 5F
	and 0x08
	ld a,(il_a)
Z_8E78:
	jp z,Z_8E7D	; 8E78 28 03
Z_8E7A:
	call il_ix_inc	; 8E7A DD 34 10
	db 0x10
Z_8E7D:
	ld a,(D_93EB)	; 8E7D 3A EB 93
Z_8E80:
	ld c,a	; 8E80 4F
Z_8E81:
	ld a,0x21	; 8E81 3E 21
Z_8E83:
	rst 0x08	; 8E83 DD CB 01 46
	db 0x01, 0x01
Z_8E87:
	jp z,Z_8E8B	; 8E87 28 02
	jp	Z_8E89	; мост в следующий кусок
	org	0x3860
D_3860:
Z_3860:
	db	0xCD, 0xDE, 0xD5, 0x26, 0x00, 0x28, 0x04, 0x3E, 0xFF, 0x6F, 0xC9, 0xAF, 0x6F, 0xC9	; 3860
	org	0x386E
Z_8E89:
	push af	; 8E89 CB FF
	or 0x80
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_8E8B:
	ld (D_93EB),a	; 8E8B 32 EB 93
Z_8E8E:
	xor a	; 8E8E AF
Z_8E8F:
	ld (D_93F5),a	; 8E8F 32 F5 93
	jp	Z_8E92	; мост в следующий кусок
	org	0x3883
D_3883:
Z_3883:
	db	0xED, 0x5B, 0x00, 0x33, 0x2A, 0x9A, 0xD0	; 3883
	org	0x388A
Z_8E92:
	call il_iy_res	; 8E92 FD CB 00 96
	db 0x00, 0xFB
Z_8E96:
	rst 0x30	; 8E96 DD CB FE A6
	db 0xFE, 0xEF
Z_8E9A:
	call il_iy_res	; 8E9A FD CB 01 B6
	db 0x01, 0xBF
Z_8E9E:
	rst 0x28	; 8E9E DD CB 00 E6
	db 0x00, 0x10
Z_8EA2:
	call il_iy_res	; 8EA2 FD CB 00 A6
	db 0x00, 0xEF
	jp	Z_8EA6	; мост в следующий кусок
	org	0x38A4
D_38A4:
Z_38A4:
	db	0xEB, 0x73, 0x23, 0x72, 0x23, 0xEB, 0xC9, 0xFE, 0x30, 0x38, 0x5B, 0xFE, 0x3A, 0x38, 0x1C, 0xFE	; 38A4
	org	0x38B4
D_38B4:
Z_38B4:
	db	0x41, 0x38, 0x53, 0xFE, 0x47, 0x30, 0x4F, 0xDF, 0xD6, 0x37, 0x18, 0x65, 0xFE, 0x26, 0x20, 0x03	; 38B4
	org	0x38C4
D_38C4:
Z_38C4:
	db	0xDF, 0x18, 0x17, 0xFE, 0x30, 0x38, 0x3F, 0xFE, 0x3A, 0x30, 0x3B, 0xDF, 0xD6, 0x30, 0x18, 0x51	; 38C4
	org	0x38D4
D_38D4:
Z_38D4:
	db	0x01, 0x0A, 0x00, 0x3E, 0x05, 0x11, 0x58, 0xD6, 0x18, 0x13, 0x01, 0x10, 0x00, 0x3E, 0x04, 0x11	; 38D4
	org	0x38E4
D_38E4:
Z_38E4:
	db	0x43, 0xD6, 0x18, 0x09	; 38E4
	org	0x38E8
Z_8EA6:
	call il_iy_res	; 8EA6 FD CB 01 A6
	db 0x01, 0xEF
Z_8EAA:
	call il_iy_res	; 8EAA FD CB 00 9E
	db 0x00, 0xF7
Z_8EAE:
	call il_iy_res	; 8EAE FD CB 00 BE
	db 0x00, 0x7F
Z_8EB2:
	call il_iy_res	; 8EB2 FD CB FE AE
	db 0xFE, 0xDF
Z_8EB6:
	call il_iy_res	; 8EB6 FD CB 01 8E
	db 0x01, 0xFD
Z_8EBA:
	call il_iy_res	; 8EBA FD CB 01 96
	db 0x01, 0xFB
Z_8EBE:
	rst 0x00	; 8EBE DD 36 06 03
	db 0x06, 0x03
Z_8EC2:
	ld (il_a),a	; 8EC2 CB 41
	ld a,c
	and 0x01
	ld a,(il_a)
Z_8EC4:
	jp nz,Z_8EEA	; 8EC4 20 24
Z_8EC6:
	rst 0x08	; 8EC6 DD CB 00 46
	db 0x00, 0x01
Z_8ECA:
	jp nz,Z_8EEA	; 8ECA 20 1E
Z_8ECC:
	ld a,(D_93F1)	; 8ECC 3A F1 93
Z_8ECF:
	ld c,a	; 8ECF 4F
Z_8ED0:
	ld a,(D_93F3)	; 8ED0 3A F3 93
Z_8ED3:
	sub c	; 8ED3 91
Z_8ED4:
	cp 0x14	; 8ED4 FE 14
Z_8ED6:
	jp c,Z_8EEA	; 8ED6 38 12
Z_8ED8:
	rst 0x28	; 8ED8 DD CB FE F6
	db 0xFE, 0x40
Z_8EDC:
	call il_ix_ldl	; 8EDC DD 6E 02
	db 0x02
Z_8EDF:
	dec l	; 8EDF 2D
Z_8EE0:
	dec l	; 8EE0 2D
Z_8EE1:
	call il_ix_ldh	; 8EE1 DD 66 03
	db 0x03
Z_8EE4:
	call il_ix_stl	; 8EE4 DD 75 04
	db 0x04
Z_8EE7:
	call il_ix_sth	; 8EE7 DD 74 05
	db 0x05
Z_8EEA:
	call il_iy_bit	; 8EEA FD CB 00 6E
	db 0x00, 0x20
Z_8EEE:
	call il_iy_res	; 8EEE FD CB 00 AE
	db 0x00, 0xDF
Z_8EF2:
	jp z,Z_93BE	; 8EF2 CA BE 93
Z_8EF5:
	call il_iy_stn	; 8EF5 FD 36 08 04
	db 0x08, 0x04
Z_8EF9:
	xor a	; 8EF9 AF
Z_8EFA:
	ld (D_93D3),a	; 8EFA 32 D3 93
Z_8EFD:
	jp Z_93BE	; 8EFD C3 BE 93
Z_8F00:
	call il_iy_bit	; 8F00 FD CB 00 66
	db 0x00, 0x10
Z_8F04:
	jp z,Z_8F51	; 8F04 28 4B
Z_8F06:
	rst 0x08	; 8F06 DD CB 01 6E
	db 0x01, 0x20
Z_8F0A:
	jp z,Z_8F51	; 8F0A 28 45
Z_8F0C:
	jp Z_93B8	; 8F0C C3 B8 93
Z_8F0F:
	rst 0x28	; 8F0F DD CB 00 DE
	db 0x00, 0x08
Z_8F13:
	call il_ix_ldl	; 8F13 DD 6E 02
	db 0x02
Z_8F16:
	call il_ix_ldh	; 8F16 DD 66 03
	db 0x03
Z_8F19:
	ld a,l	; 8F19 7D
Z_8F1A:
	cp 0x50	; 8F1A FE 50
Z_8F1C:
	jp c,Z_8F51	; 8F1C 38 33
Z_8F1E:
	cp 0x5B	; 8F1E FE 5B
Z_8F20:
	jp nc,Z_8F51	; 8F20 30 2F
Z_8F22:
	ld a,h	; 8F22 7C
Z_8F23:
	rst 0x08	; 8F23 DD CB 01 46
	db 0x01, 0x01
Z_8F27:
	jp nz,Z_8F2F	; 8F27 20 06
Z_8F29:
	cp 0x0D	; 8F29 FE 0D
Z_8F2B:
	jp nc,Z_8F51	; 8F2B 30 24
Z_8F2D:
	jp Z_8F33	; 8F2D 18 04
Z_8F2F:
	cp 0x68	; 8F2F FE 68
Z_8F31:
	jp c,Z_8F51	; 8F31 38 1E
Z_8F33:
	rst 0x10	; 8F33 DD 7E 0A
	db 0x0A
Z_8F36:
	cp 0x03	; 8F36 FE 03
Z_8F38:
	jp c,Z_8F59	; 8F38 38 1F
Z_8F3A:
	rst 0x28	; 8F3A DD CB 00 EE
	db 0x00, 0x20
Z_8F3E:
	rst 0x30	; 8F3E DD CB 00 9E
	db 0x00, 0xF7
Z_8F42:
	ld b,0x09	; 8F42 06 09
Z_8F44:
	ld a,(D_9400)	; 8F44 3A 00 94
Z_8F47:
	and a	; 8F47 A7
Z_8F48:
	jp nz,Z_8F5F	; 8F48 20 15
Z_8F4A:
	ld a,0x02	; 8F4A 3E 02
Z_8F4C:
	ld (D_93D3),a	; 8F4C 32 D3 93
Z_8F4F:
	jp Z_8F5F	; 8F4F 18 0E
Z_8F51:
	rst 0x10	; 8F51 DD 7E 0A
	db 0x0A
Z_8F54:
	ld b,0x04	; 8F54 06 04
Z_8F56:
	and a	; 8F56 A7
Z_8F57:
	jp nz,Z_8F5F	; 8F57 20 06
Z_8F59:
	ld b,0x02	; 8F59 06 02
Z_8F5B:
	rst 0x28	; 8F5B DD CB 01 FE
	db 0x01, 0x80
Z_8F5F:
	call il_ix_stb	; 8F5F DD 70 08
	db 0x08
	jp	Z_8F62	; мост в следующий кусок
	org	0x39C3
D_39C3:
Z_39C3:
	db	0x6F, 0x06, 0x08, 0xAF, 0xCB, 0x39, 0x30, 0x01, 0x85, 0xCB, 0x25, 0x10, 0xF7, 0xC9, 0x6F, 0xAF	; 39C3
	org	0x39D3
D_39D3:
Z_39D3:
	db	0x06, 0x08, 0xCB, 0x15, 0x8F, 0x99, 0x30, 0x01, 0x81, 0x3F, 0x10, 0xF6, 0xCB, 0x15, 0x32, 0x1A	; 39D3
	org	0x39E3
D_39E3:
Z_39E3:
	db	0x41, 0x7D, 0xC9	; 39E3
	org	0x39E6
Z_8F62:
	rst 0x28	; 8F62 DD CB 00 C6
	db 0x00, 0x01
Z_8F66:
	rst 0x00	; 8F66 DD 36 FC 00
	db 0xFC, 0x00
Z_8F6A:
	call il_ix_ldl	; 8F6A DD 6E 02
	db 0x02
Z_8F6D:
	call il_ix_ldh	; 8F6D DD 66 03
	db 0x03
Z_8F70:
	call il_ix_stl	; 8F70 DD 75 04
	db 0x04
Z_8F73:
	call il_ix_sth	; 8F73 DD 74 05
	db 0x05
Z_8F76:
	call il_ix_inc	; 8F76 DD 34 FC
	db 0xFC
Z_8F79:
	call Z_938E	; 8F79 CD 8E 93
Z_8F7C:
	rst 0x08	; 8F7C DD CB 00 4E
	db 0x00, 0x02
Z_8F80:
	jp nz,Z_9179	; 8F80 C2 79 91
Z_8F83:
	call Z_93A3	; 8F83 CD A3 93
Z_8F86:
	call Z_93A3	; 8F86 CD A3 93
Z_8F89:
	rst 0x08	; 8F89 DD CB 00 6E
	db 0x00, 0x20
Z_8F8D:
	jp z,Z_8FE6	; 8F8D 28 57
Z_8F8F:
	rst 0x08	; 8F8F DD CB FF 56
	db 0xFF, 0x04
Z_8F93:
	jp z,Z_8FAF	; 8F93 28 1A
Z_8F95:
	rst 0x30	; 8F95 DD CB 00 B6
	db 0x00, 0xBF
Z_8F99:
	ld e,0x08	; 8F99 1E 08
Z_8F9B:
	rst 0x08	; 8F9B DD CB 01 46
	db 0x01, 0x01
Z_8F9F:
	jp nz,Z_8FA3	; 8F9F 20 02
Z_8FA1:
	ld e,0x00	; 8FA1 1E 00
Z_8FA3:
	rst 0x10	; 8FA3 DD 7E FF
	db 0xFF
Z_8FA6:
	and 0x08	; 8FA6 E6 08
Z_8FA8:
	xor e	; 8FA8 AB
Z_8FA9:
	jp z,Z_8FAF	; 8FA9 28 04
Z_8FAB:
	rst 0x28	; 8FAB DD CB 00 F6
	db 0x00, 0x40
Z_8FAF:
	ld bc,0x00	; 8FAF 01 00 00
Z_8FB2:
	rst 0x10	; 8FB2 DD 7E 02
	db 0x02
Z_8FB5:
	cp 0x54	; 8FB5 FE 54
Z_8FB7:
	jp z,Z_8FC3	; 8FB7 28 0A
Z_8FB9:
	ld c,0x02	; 8FB9 0E 02
Z_8FBB:
	jp c,Z_8FBF	; 8FBB 38 02
Z_8FBD:
	ld c,0xFE	; 8FBD 0E FE
Z_8FBF:
	add a,c	; 8FBF 81
Z_8FC0:
	rst 0x20	; 8FC0 DD 77 02
	db 0x02
Z_8FC3:
	ld e,0x09	; 8FC3 1E 09
Z_8FC5:
	rst 0x08	; 8FC5 DD CB 01 46
	db 0x01, 0x01
Z_8FC9:
	jp z,Z_8FCD	; 8FC9 28 02
Z_8FCB:
	ld e,0x6B	; 8FCB 1E 6B
Z_8FCD:
	rst 0x10	; 8FCD DD 7E 03
	db 0x03
Z_8FD0:
	cp e	; 8FD0 BB
Z_8FD1:
	jp z,Z_8FDD	; 8FD1 28 0A
Z_8FD3:
	jp nc,Z_8FDA	; 8FD3 30 05
Z_8FD5:
	inc a	; 8FD5 3C
Z_8FD6:
	ld b,0x01	; 8FD6 06 01
	jp	Z_8FD8	; мост в следующий кусок
	org	0x3A61
D_3A61:
Z_3A61:
	db	0x6F, 0x26, 0x00, 0xAF, 0x32, 0x22, 0x41, 0xCB, 0x7C, 0x28, 0x08, 0x3E, 0x2D, 0x32, 0x22, 0x41	; 3A61
	org	0x3A71
D_3A71:
Z_3A71:
	db	0xCD, 0x0A, 0xD7, 0x3A, 0xB1, 0xD1, 0xFE, 0x01, 0x38, 0x08, 0x28, 0x10, 0x01, 0x9D, 0xD8, 0xAF	; 3A71
	org	0x3A81
D_3A81:
Z_3A81:
	db	0x18, 0x0E, 0xCD, 0x72, 0xD8, 0x01, 0x8D, 0xD8, 0x3E, 0xC9, 0x18, 0x04, 0x01, 0x9A, 0xD8, 0xAF	; 3A81
	org	0x3A91
D_3A91:
Z_3A91:
	db	0xED, 0x43, 0x1C, 0x41, 0x32, 0x1E, 0x41, 0x3A, 0xB2, 0xD1, 0xB7, 0x28, 0x1B, 0x7C, 0xCD, 0xA6	; 3A91
	org	0x3AA1
D_3AA1:
Z_3AA1:
	db	0xD8, 0xCD, 0x88, 0xD8, 0x7C, 0xCD, 0xB4, 0xD8, 0xCD, 0x88, 0xD8, 0x7D, 0xCD, 0xA6, 0xD8, 0xCD	; 3AA1
	org	0x3AB1
D_3AB1:
Z_3AB1:
	db	0x88, 0xD8, 0x7D, 0xCD, 0xB4, 0xD8, 0x18, 0x1B, 0x11, 0xF0, 0xD8, 0xCD, 0x79, 0xD8, 0x11, 0x18	; 3AB1
	org	0x3AC1
D_3AC1:
Z_3AC1:
	db	0xFC, 0xCD, 0x79, 0xD8, 0x11, 0x9C, 0xFF, 0xCD, 0x79, 0xD8, 0x11, 0xF6, 0xFF, 0xCD, 0x79, 0xD8	; 3AC1
	org	0x3AD1
D_3AD1:
Z_3AD1:
	db	0x7D, 0xC6, 0x30, 0xDF, 0x3A, 0x1E, 0x41, 0xB7, 0xC0, 0x3A, 0x22, 0x41, 0xB7, 0xC8, 0xDF, 0xC9	; 3AD1
	org	0x3AE1
D_3AE1:
Z_3AE1:
	db	0x0E, 0x2F, 0x0C, 0x19, 0x38, 0xFC, 0xEB, 0x7A, 0xCD, 0x0A, 0xD7, 0x2F, 0x19, 0x57, 0x79, 0xE5	; 3AE1
	org	0x3AF1
D_3AF1:
Z_3AF1:
	db	0x2A, 0x1C, 0x41, 0xE9, 0xE1, 0xFE, 0x30, 0xC8, 0x01, 0x9A, 0xD8, 0xED, 0x43, 0x1C, 0x41, 0xDF	; 3AF1
	org	0x3B01
D_3B01:
Z_3B01:
	db	0xC9, 0xE1, 0xDF, 0xC9, 0xE1, 0xFE, 0x30, 0x20, 0xEF, 0x3E, 0x20, 0xDF, 0xC9, 0xE6, 0xF0, 0x1F	; 3B01
	org	0x3B11
D_3B11:
Z_3B11:
	db	0x1F, 0x1F, 0x1F, 0xC6, 0x30, 0xFE, 0x3A, 0xD8, 0xC6, 0x07, 0xC9, 0xE6, 0x0F, 0x18, 0xF4, 0xE1	; 3B11
	org	0x3B21
D_3B21:
Z_3B21:
	db	0x7E, 0x23, 0xE5, 0xB7, 0xC8, 0xDF, 0x18, 0xF7, 0xC9, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 3B21
	org	0x3B31
Z_8FD8:
	jp Z_8FDD	; 8FD8 18 03
Z_8FDA:
	dec a	; 8FDA 3D
Z_8FDB:
	ld b,0xFF	; 8FDB 06 FF
Z_8FDD:
	rst 0x20	; 8FDD DD 77 03
	db 0x03
Z_8FE0:
	rst 0x20	; 8FE0 DD 77 05
	db 0x05
Z_8FE3:
	call Z_938B	; 8FE3 CD 8B 93
Z_8FE6:
	rst 0x10	; 8FE6 DD 7E 04
	db 0x04
Z_8FE9:
	sub 0x04	; 8FE9 D6 04
Z_8FEB:
	rst 0x20	; 8FEB DD 77 04
	db 0x04
	jp	Z_8FEE	; мост в следующий кусок
	org	0x3B47
D_3B47:
Z_3B47:
	db	0xC5, 0xD5, 0xE5, 0xCD, 0xEB, 0xD8, 0xE1, 0xD1, 0xC1, 0xF1, 0xF1, 0xC9	; 3B47
	org	0x3B53
Z_8FEE:
	call il_ix_dec	; 8FEE DD 35 08
	db 0x08
Z_8FF1:
	jp nz,Z_9009	; 8FF1 20 16
Z_8FF3:
	rst 0x28	; 8FF3 DD CB 00 CE
	db 0x00, 0x02
Z_8FF7:
	rst 0x08	; 8FF7 DD CB 00 66
	db 0x00, 0x10
Z_8FFB:
	jp z,Z_9009	; 8FFB 28 0C
Z_8FFD:
	rst 0x08	; 8FFD DD CB 01 7E
	db 0x01, 0x80
Z_9001:
	jp z,Z_9009	; 9001 28 06
Z_9003:
	rst 0x28	; 9003 DD CB FE E6
	db 0xFE, 0x10
Z_9007:
	jp Z_9041	; 9007 18 38
Z_9009:
	rst 0x08	; 9009 DD CB 00 6E
	db 0x00, 0x20
Z_900D:
	ret nz	; 900D C0
Z_900E:
	rst 0x08	; 900E DD CB 00 7E
	db 0x00, 0x80
Z_9012:
	jp z,Z_9019	; 9012 28 05
Z_9014:
	rst 0x28	; 9014 DD CB FE EE
	db 0xFE, 0x20
Z_9018:
	ret	; 9018 C9
Z_9019:
	rst 0x08	; 9019 DD CB 00 66
	db 0x00, 0x10
Z_901D:
	jp nz,Z_9041	; 901D 20 22
Z_901F:
	rst 0x08	; 901F DD CB 01 5E
	db 0x01, 0x08
Z_9023:
	ret nz	; 9023 C0
Z_9024:
	ld a,(D_93EB)	; 9024 3A EB 93
Z_9027:
	ld (il_a),a	; 9027 CB 4F
	and 0x02
	ld a,(il_a)
Z_9029:
	jp z,Z_9034	; 9029 28 09
Z_902B:
	call il_ix_ldc	; 902B DD 4E 01
	db 0x01
Z_902E:
	ld (il_a),a	; 902E CB 09
	ld a,c
	rrca
	ld c,a
	ld a,(il_a)
Z_9030:
	xor c	; 9030 A9
Z_9031:
	and 0x80	; 9031 E6 80
Z_9033:
	ret z	; 9033 C8
Z_9034:
	rst 0x08	; 9034 DD CB 01 76
	db 0x01, 0x40
Z_9038:
	ret z	; 9038 C8
Z_9039:
	rst 0x08	; 9039 DD CB 01 5E
	db 0x01, 0x08
Z_903D:
	ret nz	; 903D C0
Z_903E:
	jp Z_8E73	; 903E C3 73 8E
Z_9041:
	rst 0x08	; 9041 DD CB 01 4E
	db 0x01, 0x02
Z_9045:
	jp nz,Z_90B7	; 9045 20 70
Z_9047:
	rst 0x08	; 9047 DD CB 01 56
	db 0x01, 0x04
Z_904B:
	jp nz,Z_907E	; 904B 20 31
Z_904D:
	rst 0x08	; 904D DD CB FE 66
	db 0xFE, 0x10
Z_9051:
	ret z	; 9051 C8
Z_9052:
	rst 0x10	; 9052 DD 7E 03
	db 0x03
Z_9055:
	rst 0x08	; 9055 DD CB 01 46
	db 0x01, 0x01
Z_9059:
	jp nz,Z_9061	; 9059 20 06
Z_905B:
	cp 0x14	; 905B FE 14
Z_905D:
	jp c,Z_90B3	; 905D 38 54
Z_905F:
	jp Z_9065	; 905F 18 04
Z_9061:
	cp 0x60	; 9061 FE 60
Z_9063:
	jp nc,Z_90B3	; 9063 30 4E
Z_9065:
	rst 0x08	; 9065 DD CB FF 56
	db 0xFF, 0x04
Z_9069:
	jp nz,Z_907A	; 9069 20 0F
Z_906B:
	rst 0x28	; 906B DD CB 00 FE
	db 0x00, 0x80
Z_906F:
	rst 0x28	; 906F DD CB FE EE
	db 0xFE, 0x20
Z_9073:
	xor a	; 9073 AF
Z_9074:
	rst 0x20	; 9074 DD 77 07
	db 0x07
Z_9077:
	jp Z_93BE	; 9077 C3 BE 93
Z_907A:
	rst 0x28	; 907A DD CB 01 D6
	db 0x01, 0x04
Z_907E:
	call il_ix_ldc	; 907E DD 4E FF
	db 0xFF
Z_9081:
	rst 0x08	; 9081 DD CB 01 46
	db 0x01, 0x01
Z_9085:
	jp nz,Z_90A4	; 9085 20 1D
Z_9087:
	ld (il_a),a	; 9087 CB 51
	ld a,c
	and 0x04
	ld a,(il_a)
Z_9089:
	jp z,Z_9096	; 9089 28 0B
Z_908B:
	ld (il_a),a	; 908B CB 59
	ld a,c
	and 0x08
	ld a,(il_a)
Z_908D:
	jp z,Z_90EF	; 908D 28 60
Z_908F:
	rst 0x00	; 908F DD 36 FF 03
	db 0xFF, 0x03
Z_9093:
	jp Z_93BE	; 9093 C3 BE 93
Z_9096:
	rst 0x00	; 9096 DD 36 FF 04
	db 0xFF, 0x04
Z_909A:
	jp Z_93BE	; 909A C3 BE 93
	org	0x3C1E
D_3C1E:
Z_3C1E:
	db	0xFF, 0x4A, 0x16, 0x4E, 0x34, 0x4A, 0x07, 0x4A, 0x14, 0xCA, 0x04, 0x4A, 0x04, 0xCA, 0x04, 0x4A	; 3C1E
	org	0x3C2E
D_3C2E:
Z_3C2E:
	db	0x04, 0x4A, 0x04, 0x4A, 0x04, 0x4A, 0x04, 0x4A, 0x04, 0x4A, 0x04, 0x4A, 0x04, 0x4A, 0x14, 0x4A	; 3C2E
	org	0x3C3E
D_3C3E:
Z_3C3E:
	db	0x14, 0x4A, 0x04, 0x4A, 0x14, 0x4A, 0x04, 0x4A, 0x14, 0x4A, 0x14, 0x4A, 0x06, 0x4E, 0x04, 0x4A	; 3C3E
	org	0x3C4E
D_3C4E:
Z_3C4E:
	db	0x04, 0xCA, 0x24, 0x4A, 0x04, 0x4E, 0x04, 0x4A, 0x07, 0xCA, 0x14, 0x4A, 0x36, 0x4A, 0x36, 0x4A	; 3C4E
	org	0x3C5E
D_3C5E:
Z_3C5E:
	db	0x37, 0xCA, 0x36, 0x4A, 0x37, 0xCA, 0x3E, 0x4A, 0x37, 0xCA, 0x00, 0xB8, 0x42, 0x11, 0x7B, 0x10	; 3C5E
	org	0x3C6E
D_3C6E:
Z_3C6E:
	db	0x6B, 0x10, 0x7B, 0x90, 0x6B, 0x10, 0x7B, 0x10, 0x6B, 0x90, 0x7B, 0x90, 0x6B, 0x10, 0x7B, 0x10	; 3C6E
	org	0x3C7E
D_3C7E:
Z_3C7E:
	db	0x7B, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x18, 0x18, 0x18, 0x18, 0x00	; 3C7E
	org	0x3C8E
D_3C8E:
Z_3C8E:
	db	0x18, 0x00, 0x6C, 0x6C, 0x6C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x6C, 0x6C, 0xFE, 0x6C, 0xFE, 0x6C	; 3C8E
	org	0x3C9E
D_3C9E:
Z_3C9E:
	db	0x6C, 0x00, 0x18, 0x3E, 0x58, 0x3C, 0x1A, 0x7C, 0x18, 0x00, 0x00, 0xC6, 0xCC, 0x18, 0x30, 0x66	; 3C9E
	org	0x3CAE
D_3CAE:
Z_3CAE:
	db	0xC6, 0x00, 0x38, 0x6C, 0x38, 0x76, 0xDC, 0xCC, 0x76, 0x00, 0x18, 0x18, 0x30, 0x00, 0x00, 0x00	; 3CAE
	org	0x3CBE
D_3CBE:
Z_3CBE:
	db	0x00, 0x00, 0x0C, 0x18, 0x30, 0x30, 0x30, 0x18, 0x0C, 0x00, 0x30, 0x18, 0x0C, 0x0C, 0x0C, 0x18	; 3CBE
	org	0x3CCE
D_3CCE:
Z_3CCE:
	db	0x30, 0x00, 0x00, 0x66, 0x3C, 0xFF, 0x3C, 0x66, 0x00, 0x00, 0x00, 0x18, 0x18, 0x7E, 0x18, 0x18	; 3CCE
	org	0x3CDE
D_3CDE:
Z_3CDE:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x18, 0x30, 0x00, 0x00, 0x00, 0x7E, 0x00, 0x00	; 3CDE
	org	0x3CEE
D_3CEE:
Z_3CEE:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x18, 0x00, 0x06, 0x0C, 0x18, 0x30, 0x60, 0xC0	; 3CEE
	org	0x3CFE
D_3CFE:
Z_3CFE:
	db	0x80, 0x00, 0x7C, 0xC6, 0xCE, 0xD6, 0xE6, 0xC6, 0x7C, 0x00, 0x18, 0x38, 0x18, 0x18, 0x18, 0x18	; 3CFE
	org	0x3D0E
D_3D0E:
Z_3D0E:
	db	0x7E, 0x00, 0x3C, 0x66, 0x06, 0x3C, 0x60, 0x66, 0x7E, 0x00, 0x3C, 0x66, 0x06, 0x1C, 0x06, 0x66	; 3D0E
	org	0x3D1E
D_3D1E:
Z_3D1E:
	db	0x3C, 0x00, 0x1C, 0x3C, 0x6C, 0xCC, 0xFE, 0x0C, 0x1E, 0x00, 0x7E, 0x62, 0x60, 0x7C, 0x06, 0x66	; 3D1E
	org	0x3D2E
D_3D2E:
Z_3D2E:
	db	0x3C, 0x00, 0x3C, 0x66, 0x60, 0x7C, 0x66, 0x66, 0x3C, 0x00, 0x7E, 0x66, 0x06, 0x0C, 0x18, 0x18	; 3D2E
	org	0x3D3E
D_3D3E:
Z_3D3E:
	db	0x18, 0x00, 0x3C, 0x66, 0x66, 0x3C, 0x66, 0x66, 0x3C, 0x00, 0x3C, 0x66, 0x66, 0x3E, 0x06, 0x66	; 3D3E
	org	0x3D4E
D_3D4E:
Z_3D4E:
	db	0x3C, 0x00, 0x00, 0x00, 0x18, 0x18, 0x00, 0x18, 0x18, 0x00, 0x00, 0x00, 0x18, 0x18, 0x00, 0x18	; 3D4E
	org	0x3D5E
D_3D5E:
Z_3D5E:
	db	0x18, 0x30, 0x0C, 0x18, 0x30, 0x60, 0x30, 0x18, 0x0C, 0x00, 0x00, 0x00, 0x7E, 0x00, 0x00, 0x7E	; 3D5E
	org	0x3D6E
D_3D6E:
Z_3D6E:
	db	0x00, 0x00, 0x60, 0x30, 0x18, 0x0C, 0x18, 0x30, 0x60, 0x00, 0x3C, 0x66, 0x66, 0x0C, 0x18, 0x00	; 3D6E
	org	0x3D7E
D_3D7E:
Z_3D7E:
	db	0x18, 0x00, 0x7C, 0xC6, 0xDE, 0xDE, 0xDE, 0xC0, 0x7C, 0x00, 0x18, 0x3C, 0x66, 0x66, 0x7E, 0x66	; 3D7E
	org	0x3D8E
D_3D8E:
Z_3D8E:
	db	0x66, 0x00, 0xFC, 0x66, 0x66, 0x7C, 0x66, 0x66, 0xFC, 0x00, 0x3C, 0x66, 0xC0, 0xC0, 0xC0, 0x66	; 3D8E
	org	0x3D9E
D_3D9E:
Z_3D9E:
	db	0x3C, 0x00, 0xF8, 0x6C, 0x66, 0x66, 0x66, 0x6C, 0xF8, 0x00, 0xFE, 0x62, 0x68, 0x78, 0x68, 0x62	; 3D9E
	org	0x3DAE
D_3DAE:
Z_3DAE:
	db	0xFE, 0x00, 0xFE, 0x62, 0x68, 0x78, 0x68, 0x60, 0xF0, 0x00, 0x3C, 0x66, 0xC0, 0xC0, 0xCE, 0x66	; 3DAE
	org	0x3DBE
D_3DBE:
Z_3DBE:
	db	0x3E, 0x00, 0x66, 0x66, 0x66, 0x7E, 0x66, 0x66, 0x66, 0x00, 0x7E, 0x18, 0x18, 0x18, 0x18, 0x18	; 3DBE
	org	0x3DCE
D_3DCE:
Z_3DCE:
	db	0x7E, 0x00, 0x1E, 0x0C, 0x0C, 0x0C, 0xCC, 0xCC, 0x78, 0x00, 0xE6, 0x66, 0x6C, 0x78, 0x6C, 0x66	; 3DCE
	org	0x3DDE
D_3DDE:
Z_3DDE:
	db	0xE6, 0x00, 0xF0, 0x60, 0x60, 0x60, 0x62, 0x66, 0xFE, 0x00, 0xC6, 0xEE, 0xFE, 0xFE, 0xD6, 0xC6	; 3DDE
	org	0x3DEE
D_3DEE:
Z_3DEE:
	db	0xC6, 0x00, 0xC6, 0xE6, 0xF6, 0xDE, 0xCE, 0xC6, 0xC6, 0x00, 0x38, 0x6C, 0xC6, 0xC6, 0xC6, 0x6C	; 3DEE
	org	0x3DFE
D_3DFE:
Z_3DFE:
	db	0x38, 0x00, 0xFC, 0x66, 0x66, 0x7C, 0x60, 0x60, 0xF0, 0x00, 0x38, 0x6C, 0xC6, 0xC6, 0xDA, 0xCC	; 3DFE
	org	0x3E0E
D_3E0E:
Z_3E0E:
	db	0x76, 0x00, 0xFC, 0x66, 0x66, 0x7C, 0x6C, 0x66, 0xE6, 0x00, 0x3C, 0x66, 0x60, 0x3C, 0x06, 0x66	; 3E0E
	org	0x3E1E
D_3E1E:
Z_3E1E:
	db	0x3C, 0x00, 0x7E, 0x5A, 0x18, 0x18, 0x18, 0x18, 0x3C, 0x00, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66	; 3E1E
	org	0x3E2E
D_3E2E:
Z_3E2E:
	db	0x3C, 0x00, 0x66, 0x66, 0x66, 0x66, 0x66, 0x3C, 0x18, 0x00, 0xC6, 0xC6, 0xC6, 0xD6, 0xFE, 0xEE	; 3E2E
	org	0x3E3E
D_3E3E:
Z_3E3E:
	db	0xC6, 0x00, 0xC6, 0x6C, 0x38, 0x38, 0x6C, 0xC6, 0xC6, 0x00, 0x66, 0x66, 0x66, 0x3C, 0x18, 0x18	; 3E3E
	org	0x3E4E
D_3E4E:
Z_3E4E:
	db	0x3C, 0x00, 0xFE, 0xC6, 0x8C, 0x18, 0x32, 0x66, 0xFE, 0x00, 0x3C, 0x30, 0x30, 0x30, 0x30, 0x30	; 3E4E
	org	0x3E5E
D_3E5E:
Z_3E5E:
	db	0x3C, 0x00, 0xC0, 0x60, 0x30, 0x18, 0x0C, 0x06, 0x02, 0x00, 0x3C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C	; 3E5E
	org	0x3E6E
D_3E6E:
Z_3E6E:
	db	0x3C, 0x00, 0x18, 0x3C, 0x7E, 0x18, 0x18, 0x18, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 3E6E
	org	0x3E7E
D_3E7E:
Z_3E7E:
	db	0x00, 0xFF, 0x30, 0x18, 0x0C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x78, 0x0C, 0x7C, 0xCC	; 3E7E
	org	0x3E8E
D_3E8E:
Z_3E8E:
	db	0x76, 0x00, 0xE0, 0x60, 0x7C, 0x66, 0x66, 0x66, 0xDC, 0x00, 0x00, 0x00, 0x3C, 0x66, 0x60, 0x66	; 3E8E
	org	0x3E9E
D_3E9E:
Z_3E9E:
	db	0x3C, 0x00, 0x1C, 0x0C, 0x7C, 0xCC, 0xCC, 0xCC, 0x76, 0x00, 0x00, 0x00, 0x3C, 0x66, 0x7E, 0x60	; 3E9E
	org	0x3EAE
D_3EAE:
Z_3EAE:
	db	0x3C, 0x00, 0x1C, 0x36, 0x30, 0x78, 0x30, 0x30, 0x78, 0x00, 0x00, 0x00, 0x3E, 0x66, 0x66, 0x3E	; 3EAE
	org	0x3EBE
D_3EBE:
Z_3EBE:
	db	0x06, 0x7C, 0xE0, 0x60, 0x6C, 0x76, 0x66, 0x66, 0xE6, 0x00, 0x18, 0x00, 0x38, 0x18, 0x18, 0x18	; 3EBE
	org	0x3ECE
D_3ECE:
Z_3ECE:
	db	0x3C, 0x00, 0x06, 0x00, 0x0E, 0x06, 0x06, 0x66, 0x66, 0x3C, 0xE0, 0x60, 0x66, 0x6C, 0x78, 0x6C	; 3ECE
	org	0x3EDE
D_3EDE:
Z_3EDE:
	db	0xE6, 0x00, 0x38, 0x18, 0x18, 0x18, 0x18, 0x18, 0x3C, 0x00, 0x00, 0x00, 0x6C, 0xFE, 0xD6, 0xD6	; 3EDE
	org	0x3EEE
D_3EEE:
Z_3EEE:
	db	0xC6, 0x00, 0x00, 0x00, 0xDC, 0x66, 0x66, 0x66, 0x66, 0x00, 0x00, 0x00, 0x3C, 0x66, 0x66, 0x66	; 3EEE
	org	0x3EFE
D_3EFE:
Z_3EFE:
	db	0x3C, 0x00, 0x00, 0x00, 0xDC, 0x66, 0x66, 0x7C, 0x60, 0xF0, 0x00, 0x00, 0x76, 0xCC, 0xCC, 0x7C	; 3EFE
	org	0x3F0E
D_3F0E:
Z_3F0E:
	db	0x0C, 0x1E, 0x00, 0x00, 0xDC, 0x76, 0x60, 0x60, 0xF0, 0x00, 0x00, 0x00, 0x3C, 0x60, 0x3C, 0x06	; 3F0E
	org	0x3F1E
D_3F1E:
Z_3F1E:
	db	0x7C, 0x00, 0x30, 0x30, 0x7C, 0x30, 0x30, 0x36, 0x1C, 0x00, 0x00, 0x00, 0x66, 0x66, 0x66, 0x66	; 3F1E
	org	0x3F2E
D_3F2E:
Z_3F2E:
	db	0x3E, 0x00, 0x00, 0x00, 0x66, 0x66, 0x66, 0x3C, 0x18, 0x00, 0x00, 0x00, 0xC6, 0xD6, 0xD6, 0xFE	; 3F2E
	org	0x3F3E
D_3F3E:
Z_3F3E:
	db	0x6C, 0x00, 0x00, 0x00, 0xC6, 0x6C, 0x38, 0x6C, 0xC6, 0x00, 0x00, 0x00, 0x66, 0x66, 0x66, 0x3E	; 3F3E
	org	0x3F4E
D_3F4E:
Z_3F4E:
	db	0x06, 0x7C, 0x00, 0x00, 0x7E, 0x4C, 0x18, 0x32, 0x7E, 0x00, 0x0E, 0x18, 0x18, 0x70, 0x18, 0x18	; 3F4E
	org	0x3F5E
D_3F5E:
Z_3F5E:
	db	0x0E, 0x00, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x00, 0x70, 0x18, 0x18, 0x0E, 0x18, 0x18	; 3F5E
	org	0x3F6E
D_3F6E:
Z_3F6E:
	db	0x70, 0x00, 0x76, 0xDC, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3C, 0x42, 0x99, 0xA1, 0xA1, 0x99	; 3F6E
	org	0x3F7E
D_3F7E:
Z_3F7E:
	db	0x42, 0x3C	; 3F7E
	org	0x3FB2
Z_909D:
	rst 0x00	; 909D DD 36 FF 0C
	db 0xFF, 0x0C
Z_90A1:
	jp Z_93BE	; 90A1 C3 BE 93
Z_90A4:
	ld (il_a),a	; 90A4 CB 51
	ld a,c
	and 0x04
	ld a,(il_a)
Z_90A6:
	jp z,Z_909D	; 90A6 28 F5
Z_90A8:
	ld (il_a),a	; 90A8 CB 59
	ld a,c
	and 0x08
	ld a,(il_a)
Z_90AA:
	jp nz,Z_90EF	; 90AA 20 43
Z_90AC:
	rst 0x00	; 90AC DD 36 FF 01
	db 0xFF, 0x01
Z_90B0:
	jp Z_93BE	; 90B0 C3 BE 93
Z_90B3:
	rst 0x28	; 90B3 DD CB 01 CE
	db 0x01, 0x02
Z_90B7:
	call il_ix_ldc	; 90B7 DD 4E FF
	db 0xFF
Z_90BA:
	rst 0x10	; 90BA DD 7E 02
	db 0x02
Z_90BD:
	cp 0x55	; 90BD FE 55
Z_90BF:
	jp nc,Z_90E7	; 90BF 30 26
Z_90C1:
	ld (il_a),a	; 90C1 CB 41
	ld a,c
	and 0x01
	ld a,(il_a)
Z_90C3:
	jp z,Z_90D9	; 90C3 28 14
Z_90C5:
	ld (il_a),a	; 90C5 CB 49
	ld a,c
	and 0x02
	ld a,(il_a)
Z_90C7:
	jp nz,Z_90EF	; 90C7 20 26
	jp	Z_90C9	; мост в следующий кусок
	org	0x6618
Z_90C9:
	ld a,0x04	; 90C9 3E 04
Z_90CB:
	rst 0x08	; 90CB DD CB 01 46
	db 0x01, 0x01
Z_90CF:
	jp z,Z_90D3	; 90CF 28 02
Z_90D1:
	ld a,0x0C	; 90D1 3E 0C
Z_90D3:
	rst 0x20	; 90D3 DD 77 FF
	db 0xFF
Z_90D6:
	jp Z_93BE	; 90D6 C3 BE 93
Z_90D9:
	rst 0x00	; 90D9 DD 36 FF 03
	db 0xFF, 0x03
Z_90DD:
	jp Z_93BE	; 90DD C3 BE 93
Z_90E0:
	rst 0x00	; 90E0 DD 36 FF 01
	db 0xFF, 0x01
Z_90E4:
	jp Z_93BE	; 90E4 C3 BE 93
Z_90E7:
	jp c,il_KC5	; 90E7 CB 41
	ld (il_a),a
	ld a,c
	and 0x01
	ld a,(il_a)
	jp il_KD6
il_KC5:
	ld (il_a),a
	ld a,c
	and 0x01
	scf
	ld a,(il_a)
il_KD6:
Z_90E9:
	jp z,Z_90E0	; 90E9 28 F5
Z_90EB:
	jp c,il_KC7	; 90EB CB 49
	ld (il_a),a
	ld a,c
	and 0x02
	ld a,(il_a)
	jp il_KD8
il_KC7:
	ld (il_a),a
	ld a,c
	and 0x02
	scf
	ld a,(il_a)
il_KD8:
Z_90ED:
	jp nz,Z_90C9	; 90ED 20 DA
Z_90EF:
	ld a,0x02	; 90EF 3E 02
Z_90F1:
	rst 0x08	; 90F1 DD CB 01 46
	db 0x01, 0x01
Z_90F5:
	jp z,Z_90F9	; 90F5 28 02
Z_90F7:
	push af	; 90F7 CB FF
	or 0x80
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_90F9:
	ld (D_93EB),a	; 90F9 32 EB 93
Z_90FC:
	rst 0x30	; 90FC DD CB 00 A6
	db 0x00, 0xEF
Z_9100:
	rst 0x30	; 9100 DD CB 00 9E
	db 0x00, 0xF7
Z_9104:
	rst 0x30	; 9104 DD CB 00 96
	db 0x00, 0xFB
Z_9108:
	call Z_9391	; 9108 CD 91 93
Z_910B:
	rst 0x10	; 910B DD 7E FD
	db 0xFD
Z_910E:
	ld (D_944D),a	; 910E 32 4D 94
Z_9111:
	rst 0x10	; 9111 DD 7E 0A
	db 0x0A
Z_9114:
	ld (D_944E),a	; 9114 32 4E 94
Z_9117:
	ld hl,D_943A	; 9117 21 3A 94
Z_911A:
	ld d,0x00	; 911A 16 00
Z_911C:
	call il_ix_lde	; 911C DD 5E FC
	db 0xFC
Z_911F:
	dec e	; 911F 1D
Z_9120:
	add hl,de	; 9120 19
Z_9121:
	ld a,(hl)	; 9121 7E
Z_9122:
	ld (D_9450),a	; 9122 32 50 94
Z_9125:
	rst 0x10	; 9125 DD 7E 02
	db 0x02
Z_9128:
	sub 0x58	; 9128 D6 58
Z_912A:
	jp nc,Z_912E	; 912A 30 02
Z_912C:
	cpl	; 912C ED 44
	inc a
Z_912E:
	ld c,a	; 912E 4F
Z_912F:
	rst 0x10	; 912F DD 7E 03
	db 0x03
Z_9132:
	rst 0x08	; 9132 DD CB 01 46
	db 0x01, 0x01
Z_9136:
	jp z,Z_913C	; 9136 28 04
Z_9138:
	cpl	; 9138 ED 44
	inc a
Z_913A:
	add a,0x74	; 913A C6 74
Z_913C:
	add a,c	; 913C 81
Z_913D:
	or a	; 913D CB 3F
	rra
Z_913F:
	ld (D_944F),a	; 913F 32 4F 94
Z_9142:
	rst 0x10	; 9142 DD 7E 04
	db 0x04
Z_9145:
	call il_ix_ldh	; 9145 DD 66 05
	db 0x05
Z_9148:
	sub 0x1A	; 9148 D6 1A
Z_914A:
	ld l,a	; 914A 6F
Z_914B:
	rst 0x08	; 914B DD CB 01 46
	db 0x01, 0x01
Z_914F:
	jp z,Z_915E	; 914F 28 0D
Z_9151:
	inc h	; 9151 24
Z_9152:
	rst 0x08	; 9152 DD CB FF 46
	db 0xFF, 0x01
Z_9156:
	jp nz,Z_9165	; 9156 20 0D
Z_9158:
	ld a,h	; 9158 7C
Z_9159:
	add a,0x08	; 9159 C6 08
Z_915B:
	ld h,a	; 915B 67
Z_915C:
	jp Z_9167	; 915C 18 09
Z_915E:
	dec h	; 915E 25
Z_915F:
	rst 0x08	; 915F DD CB FF 46
	db 0xFF, 0x01
Z_9163:
	jp z,Z_9167	; 9163 28 02
Z_9165:
	inc h	; 9165 24
Z_9166:
	inc h	; 9166 24
Z_9167:
	ld (D_93F1),hl	; 9167 22 F1 93
Z_916A:
	call il_ix_ldl	; 916A DD 6E 02
	db 0x02
Z_916D:
	ld (D_93F3),hl	; 916D 22 F3 93
Z_9170:
	rst 0x28	; 9170 DD CB FE F6
	db 0xFE, 0x40
Z_9174:
	rst 0x28	; 9174 DD CB 01 E6
	db 0x01, 0x10
Z_9178:
	ret	; 9178 C9
Z_9179:
	call il_ix_ldl	; 9179 DD 6E 04
	db 0x04
	jp	Z_917C	; мост в следующий кусок
	org	0x754A
Z_917C:
	call il_ix_ldh	; 917C DD 66 05
	db 0x05
Z_917F:
	call Z_9009	; 917F CD 09 90
Z_9182:
	rst 0x10	; 9182 DD 7E 04
	db 0x04
Z_9185:
	add a,0x04	; 9185 C6 04
Z_9187:
	rst 0x20	; 9187 DD 77 04
	db 0x04
Z_918A:
	call il_ix_cp	; 918A DD BE 02
	db 0x02
Z_918D:
	ret c	; 918D D8
Z_918E:
	rst 0x10	; 918E DD 7E 00
	db 0x00
Z_9191:
	and 0x18	; 9191 E6 18
Z_9193:
	rst 0x20	; 9193 DD 77 00
	db 0x00
Z_9196:
	rst 0x10	; 9196 DD 7E 01
	db 0x01
Z_9199:
	and 0x71	; 9199 E6 71
Z_919B:
	rst 0x20	; 919B DD 77 01
	db 0x01
Z_919E:
	rst 0x00	; 919E DD 36 06 00
	db 0x06, 0x00
Z_91A2:
	rst 0x08	; 91A2 DD CB 00 5E
	db 0x00, 0x08
Z_91A6:
	rst 0x30	; 91A6 DD CB 00 9E
	db 0x00, 0xF7
Z_91AA:
	ret z	; 91AA C8
Z_91AB:
	ld a,(D_93D6)	; 91AB 3A D6 93
Z_91AE:
	and a	; 91AE A7
Z_91AF:
	ret nz	; 91AF C0
Z_91B0:
	ld e,0x01	; 91B0 1E 01
Z_91B2:
	jp Z_93B2	; 91B2 C3 B2 93
Z_91B5:
	xor a	; 91B5 AF
Z_91B6:
	ld (D_93D6),a	; 91B6 32 D6 93
Z_91B9:
	ld (D_93F5),a	; 91B9 32 F5 93
Z_91BC:
	ld (D_9426),a	; 91BC 32 26 94
Z_91BF:
	inc a	; 91BF 3C
Z_91C0:
	ld (D_940C),a	; 91C0 32 0C 94
Z_91C3:
	ld hl,0x0C00	; 91C3 21 00 0C
Z_91C6:
	ld (D_9409),hl	; 91C6 22 09 94
Z_91C9:
	ld hl,0x0400	; 91C9 21 00 04
Z_91CC:
	ld (D_9423),hl	; 91CC 22 23 94
Z_91CF:
	ld a,(D_9400)	; 91CF 3A 00 94
Z_91D2:
	and a	; 91D2 A7
Z_91D3:
	jp nz,Z_91FE	; 91D3 20 29
Z_91D5:
	ld hl,0x1054	; 91D5 21 54 10
Z_91D8:
	ld (D_940D),hl	; 91D8 22 0D 94
Z_91DB:
	ld h,0x64	; 91DB 26 64
Z_91DD:
	ld (D_9427),hl	; 91DD 22 27 94
Z_91E0:
	ld h,0x3E	; 91E0 26 3E
Z_91E2:
	ld (D_93F3),hl	; 91E2 22 F3 93
Z_91E5:
	ld l,0x26	; 91E5 2E 26
Z_91E7:
	ld (D_93F1),hl	; 91E7 22 F1 93
Z_91EA:
	call Z_8B26	; 91EA CD 26 8B
Z_91ED:
	ld a,0x10	; 91ED 3E 10
Z_91EF:
	ld (D_93EB),a	; 91EF 32 EB 93
Z_91F2:
	xor a	; 91F2 AF
Z_91F3:
	ld (D_940B),a	; 91F3 32 0B 94
Z_91F6:
	ld (D_9425),a	; 91F6 32 25 94
Z_91F9:
	ld (D_9426),a	; 91F9 32 26 94
Z_91FC:
	jp Z_9269	; 91FC 18 6B
Z_91FE:
	ld e,a	; 91FE 5F
Z_91FF:
	and 0x07	; 91FF E6 07
Z_9201:
	cp 0x02	; 9201 FE 02
Z_9203:
	jp nz,Z_9229	; 9203 20 24
Z_9205:
	ld a,e	; 9205 7B
Z_9206:
	ld (D_93D6),a	; 9206 32 D6 93
Z_9209:
	ld a,0x16	; 9209 3E 16
Z_920B:
	ld (D_9415),a	; 920B 32 15 94
Z_920E:
	ld (D_942F),a	; 920E 32 2F 94
Z_9211:
	ld (il_a),a	; 9211 CB 7B
	ld a,e
	and 0x80
	ld a,(il_a)
Z_9213:
	jp z,Z_921F	; 9213 28 0A
Z_9215:
	ld hl,0xC854	; 9215 21 54 C8
Z_9218:
	ld (D_940D),hl	; 9218 22 0D 94
Z_921B:
	ld h,0x18	; 921B 26 18
Z_921D:
	jp Z_9235	; 921D 18 16
Z_921F:
	ld hl,0x5C54	; 921F 21 54 5C
Z_9222:
	ld (D_940D),hl	; 9222 22 0D 94
Z_9225:
	ld h,0xC8	; 9225 26 C8
Z_9227:
	jp Z_9251	; 9227 18 28
Z_9229:
	ld (il_a),a	; 9229 CB 7B
	ld a,e
	and 0x80
	ld a,(il_a)
Z_922B:
	jp z,Z_9249	; 922B 28 1C
Z_922D:
	ld hl,D_3654	; 922D 21 54 36
Z_9230:
	ld (D_940D),hl	; 9230 22 0D 94
Z_9233:
	ld h,0x64	; 9233 26 64
Z_9235:
	ld (D_9427),hl	; 9235 22 27 94
Z_9238:
	ld (il_tmp),hl	; 9238 DD 21 25 94
	ld hl,D_9425
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_923C:
	ld a,0x10	; 923C 3E 10
Z_923E:
	ld (D_9425),a	; 923E 32 25 94
Z_9241:
	xor a	; 9241 AF
Z_9242:
	ld (D_940B),a	; 9242 32 0B 94
Z_9245:
	ld a,0x01	; 9245 3E 01
Z_9247:
	jp Z_9263	; 9247 18 1A
Z_9249:
	ld hl,0x1054	; 9249 21 54 10
Z_924C:
	ld (D_940D),hl	; 924C 22 0D 94
Z_924F:
	ld h,0x3E	; 924F 26 3E
Z_9251:
	ld (D_9427),hl	; 9251 22 27 94
Z_9254:
	ld (il_tmp),hl	; 9254 DD 21 0B 94
	ld hl,D_940B
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_9258:
	ld a,0x10	; 9258 3E 10
Z_925A:
	ld (D_940B),a	; 925A 32 0B 94
Z_925D:
	xor a	; 925D AF
Z_925E:
	ld (D_9425),a	; 925E 32 25 94
Z_9261:
	ld a,0x81	; 9261 3E 81
Z_9263:
	ld (D_93EB),a	; 9263 32 EB 93
Z_9266:
	call Z_93BE	; 9266 CD BE 93
Z_9269:
	xor a	; 9269 AF
Z_926A:
	ld (D_9400),a	; 926A 32 00 94
Z_926D:
	ld (D_93D8),a	; 926D 32 D8 93
Z_9270:
	jp Z_939D	; 9270 C3 9D 93
Z_9273:
	ld hl,D_93EB	; 9273 21 EB 93
Z_9276:
	ld de,D_93EC	; 9276 11 EC 93
Z_9279:
	ld (hl),0x00	; 9279 36 00
Z_927B:
	ld bc,0x4E	; 927B 01 4E 00
Z_927E:
	call il_ldir	; 927E ED B0
Z_9280:
	ld a,0x02	; 9280 3E 02
Z_9282:
	ld (D_93D7),a	; 9282 32 D7 93
Z_9285:
	ld a,0x16	; 9285 3E 16
Z_9287:
	ld (D_9415),a	; 9287 32 15 94
Z_928A:
	ld (D_942F),a	; 928A 32 2F 94
Z_928D:
	ld a,0x19	; 928D 3E 19
Z_928F:
	ld (D_9408),a	; 928F 32 08 94
Z_9292:
	ld (D_9422),a	; 9292 32 22 94
Z_9295:
	ld hl,D_93E0	; 9295 21 E0 93
Z_9298:
	ld de,D_93E5	; 9298 11 E5 93
Z_929B:
	ld bc,0x05	; 929B 01 05 00
Z_929E:
	call il_ldir	; 929E ED B0
Z_92A0:
	xor a	; 92A0 AF
Z_92A1:
	ld (D_9400),a	; 92A1 32 00 94
Z_92A4:
	jp Z_937F	; 92A4 C3 7F 93
Z_92A7:
	call Z_9273	; 92A7 CD 73 92
Z_92AA:
	ld a,0x11	; 92AA 3E 11
Z_92AC:
	ld (D_3424),a	; 92AC 32 24 34
Z_92AF:
	call Z_3732	; 92AF CD 32 37
Z_92B2:
	call Z_91B5	; 92B2 CD B5 91
Z_92B5:
	nop	; 92B5 00
Z_92B6:
	nop	; 92B6 00
Z_92B7:
	nop	; 92B7 00
Z_92B8:
	ld l,0x01	; 92B8 2E 01
Z_92BA:
	call Z_932A	; 92BA CD 2A 93
Z_92BD:
	ld l,0x14	; 92BD 2E 14
Z_92BF:
	call Z_932A	; 92BF CD 2A 93
Z_92C2:
	call Z_939D	; 92C2 CD 9D 93
Z_92C5:
	ld a,0xF1	; 92C5 3E F1
Z_92C7:
	ld (D_3424),a	; 92C7 32 24 34
Z_92CA:
	ld hl,0x0E11	; 92CA 21 11 0E
Z_92CD:
	ld de,D_9348	; 92CD 11 48 93
Z_92D0:
	call Z_9397	; 92D0 CD 97 93
Z_92D3:
	call Z_9379	; 92D3 CD 79 93
Z_92D6:
	call Z_93A9	; 92D6 CD A9 93
Z_92D9:
	call Z_93AC	; 92D9 CD AC 93
Z_92DC:
	call Z_93A6	; 92DC CD A6 93
Z_92DF:
	call 0x01F2	; 92DF CD F2 01
Z_92E2:
	call Z_9385	; 92E2 CD 85 93
Z_92E5:
	call 0x01EF	; 92E5 CD EF 01
Z_92E8:
	nop	; 92E8 00
Z_92E9:
	nop	; 92E9 00
Z_92EA:
	nop	; 92EA 00
Z_92EB:
	nop	; 92EB 00
Z_92EC:
	nop	; 92EC 00
Z_92ED:
	nop	; 92ED 00
Z_92EE:
	nop	; 92EE 00
Z_92EF:
	nop	; 92EF 00
Z_92F0:
	nop	; 92F0 00
Z_92F1:
	nop	; 92F1 00
Z_92F2:
	nop	; 92F2 00
Z_92F3:
	nop	; 92F3 00
Z_92F4:
	nop	; 92F4 00
Z_92F5:
	nop	; 92F5 00
Z_92F6:
	nop	; 92F6 00
Z_92F7:
	nop	; 92F7 00
Z_92F8:
	nop	; 92F8 00
Z_92F9:
	nop	; 92F9 00
Z_92FA:
	nop	; 92FA 00
Z_92FB:
	nop	; 92FB 00
Z_92FC:
	nop	; 92FC 00
Z_92FD:
	nop	; 92FD 00
Z_92FE:
	ret	; 92FE C9
Z_932A:
	ret	; 932A C9
Z_9376:
	jp Z_A063	; 9376 C3 63 A0
Z_9379:
	jp Z_9F9A	; 9379 C3 9A 9F
Z_937C:
	jp Z_9F60	; 937C C3 60 9F
Z_937F:
	jp Z_9F67	; 937F C3 67 9F
Z_9382:
	jp Z_9543	; 9382 C3 43 95
Z_9385:
	jp Z_94B0	; 9385 C3 B0 94
Z_9388:
	jp Z_9A1B	; 9388 C3 1B 9A
Z_938B:
	jp Z_98D9	; 938B C3 D9 98
Z_938E:
	jp Z_994A	; 938E C3 4A 99
Z_9391:
	jp Z_99BC	; 9391 C3 BC 99
Z_9394:
	jp Z_9E6F	; 9394 C3 6F 9E
Z_9397:
	jp Z_A01F	; 9397 C3 1F A0
Z_939A:
	jp Z_A022	; 939A C3 22 A0
Z_939D:
	jp Z_9F25	; 939D C3 25 9F
Z_93A0:
	jp Z_9E82	; 93A0 C3 82 9E
Z_93A3:
	jp Z_9ED4	; 93A3 C3 D4 9E
Z_93A6:
	jp Z_A00E	; 93A6 C3 0E A0
Z_93A9:
	jp Z_9FC0	; 93A9 C3 C0 9F
Z_93AC:
	jp Z_9FF2	; 93AC C3 F2 9F
Z_93AF:
	jp Z_A03B	; 93AF C3 3B A0
Z_93B2:
	jp Z_9919	; 93B2 C3 19 99
Z_93B5:
	jp Z_9BF6	; 93B5 C3 F6 9B
Z_93B8:
	jp Z_98B3	; 93B8 C3 B3 98
Z_93BB:
	jp Z_9C83	; 93BB C3 83 9C
Z_93BE:
	jp Z_9DC2	; 93BE C3 C2 9D
Z_93C1:
	jp Z_A02C	; 93C1 C3 2C A0
Z_93C4:
	jp Z_9599	; 93C4 C3 99 95
Z_93C7:
	jp Z_958F	; 93C7 C3 8F 95
Z_94B0:
	ld hl,D_3C1E	; 94B0 21 1E 3C
Z_94B3:
	ld a,0x53	; 94B3 3E 53
Z_94B5:
	ld de,Z_84D3	; 94B5 11 D3 84
Z_94B8:
	call Z_953C	; 94B8 CD 3C 95
Z_94BB:
	ld a,(D_93EB)	; 94BB 3A EB 93
	jp	Z_94BE	; мост в следующий кусок
	org	0x7A57
Z_94BE:
	jp c,il_KC9	; 94BE CB 47
	ld (il_a),a
	and 0x01
	ld a,(il_a)
	jp il_KD10
il_KC9:
	ld (il_a),a
	and 0x01
	scf
	ld a,(il_a)
il_KD10:
Z_94C0:
	jp nz,Z_94CF	; 94C0 20 0D
Z_94C2:
	jp c,il_KC11	; 94C2 CB 57
	ld (il_a),a
	and 0x04
	ld a,(il_a)
	jp il_KD12
il_KC11:
	ld (il_a),a
	and 0x04
	scf
	ld a,(il_a)
il_KD12:
Z_94C4:
	jp nz,Z_94CF	; 94C4 20 09
Z_94C6:
	ld a,(D_93F3)	; 94C6 3A F3 93
Z_94C9:
	ld de,Z_84D6	; 94C9 11 D6 84
Z_94CC:
	call Z_953C	; 94CC CD 3C 95
Z_94CF:
	ld a,(D_940D)	; 94CF 3A 0D 94
Z_94D2:
	ld de,Z_9599	; 94D2 11 99 95
Z_94D5:
	call Z_953C	; 94D5 CD 3C 95
Z_94D8:
	ld a,(D_9427)	; 94D8 3A 27 94
Z_94DB:
	ld de,Z_958F	; 94DB 11 8F 95
Z_94DE:
	call Z_953C	; 94DE CD 3C 95
Z_94E1:
	ld (hl),0x00	; 94E1 36 00
Z_94E3:
	ld b,0x01	; 94E3 06 01
Z_94E5:
	ld (il_tmp),hl	; 94E5 DD 21 1E 3C
	ld hl,D_3C1E
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_94E9:
	ld (il_tmp2),hl	; 94E9 DD 7E 00
	ld hl,(z80_ix)
	ld a,(hl)
	ld hl,(il_tmp2)
Z_94EC:
	and a	; 94EC A7
Z_94ED:
	jp z,Z_9525	; 94ED 28 36
Z_94EF:
	ld (il_tmp2),hl	; 94EF DD BE 03
	ld hl,(z80_ix)
	inc hl
	inc hl
	inc hl
	cp (hl)
	ld hl,(il_tmp2)
Z_94F2:
	jp z,Z_951D	; 94F2 28 29
Z_94F4:
	jp c,Z_951D	; 94F4 38 27
Z_94F6:
	ld c,a	; 94F6 4F
Z_94F7:
	ld (il_tmp2),hl	; 94F7 DD 7E 03
	ld hl,(z80_ix)
	inc hl
	inc hl
	inc hl
	ld a,(hl)
	ld hl,(il_tmp2)
	jp	Z_94FA	; мост в следующий кусок
	org	0x7B51
Z_94FA:
	and a	; 94FA A7
Z_94FB:
	jp z,Z_9525	; 94FB 28 28
Z_94FD:
	call il_ix_stc	; 94FD DD 71 03
	db 0x03
Z_9500:
	rst 0x20	; 9500 DD 77 00
	db 0x00
Z_9503:
	call il_ix_ldl	; 9503 DD 6E 01
	db 0x01
Z_9506:
	call il_ix_ldh	; 9506 DD 66 02
	db 0x02
Z_9509:
	call il_ix_lde	; 9509 DD 5E 04
	db 0x04
Z_950C:
	call il_ix_ldd	; 950C DD 56 05
	db 0x05
Z_950F:
	ex de,hl	; 950F EB
Z_9510:
	call il_ix_stl	; 9510 DD 75 01
	db 0x01
Z_9513:
	call il_ix_sth	; 9513 DD 74 02
	db 0x02
Z_9516:
	call il_ix_ste	; 9516 DD 73 04
	db 0x04
Z_9519:
	call il_ix_std	; 9519 DD 72 05
	db 0x05
Z_951C:
	inc b	; 951C 04
Z_951D:
	ld (il_tmp),hl	; 951D DD 23
	ld hl,(z80_ix)
	inc hl
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_951F:
	ld (il_tmp),hl	; 951F DD 23
	ld hl,(z80_ix)
	inc hl
	ld (z80_ix),hl
	ld hl,(il_tmp)
	jp	Z_9521	; мост в следующий кусок
	org	0x8496
Z_9521:
	ld (il_tmp),hl	; 9521 DD 23
	ld hl,(z80_ix)
	inc hl
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_9523:
	jp Z_94E9	; 9523 18 C4
Z_9525:
	dec b	; 9525 10 BE
	jp nz,Z_94E5
Z_9527:
	ld hl,D_3C1E	; 9527 21 1E 3C
Z_952A:
	ld a,(hl)	; 952A 7E
Z_952B:
	and a	; 952B A7
Z_952C:
	ret z	; 952C C8
Z_952D:
	inc hl	; 952D 23
Z_952E:
	ld e,(hl)	; 952E 5E
Z_952F:
	inc hl	; 952F 23
Z_9530:
	ld d,(hl)	; 9530 56
Z_9531:
	inc hl	; 9531 23
Z_9532:
	push hl	; 9532 E5
Z_9533:
	ex de,hl	; 9533 EB
Z_9534:
	call Z_953B	; 9534 CD 3B 95
Z_9537:
	pop hl	; 9537 E1
Z_9538:
	jp Z_952A	; 9538 C3 2A 95
Z_953B:
	jp (hl)	; 953B E9
Z_953C:
	ld (hl),a	; 953C 77
Z_953D:
	inc hl	; 953D 23
Z_953E:
	ld (hl),e	; 953E 73
Z_953F:
	inc hl	; 953F 23
Z_9540:
	ld (hl),d	; 9540 72
Z_9541:
	inc hl	; 9541 23
Z_9542:
	ret	; 9542 C9
Z_9543:
	call Z_AC4A	; 9543 CD 4A AC
Z_9546:
	ld a,(D_9409)	; 9546 3A 09 94
Z_9549:
	ld c,a	; 9549 4F
Z_954A:
	ld a,(D_AC4D)	; 954A 3A 4D AC
Z_954D:
	ld (il_a),a	; 954D CB 67
	and 0x10
	ld a,(il_a)
Z_954F:
	jp z,Z_9559	; 954F 28 08
Z_9551:
	ld (il_a),a	; 9551 CB 79
	ld a,c
	and 0x80
	ld a,(il_a)
Z_9553:
	push af	; 9553 CB FF
	or 0x80
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_9555:
	jp z,Z_9559	; 9555 28 02
Z_9557:
	push af	; 9557 CB A7
	and 0xEF
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_9559:
	ld (D_9409),a	; 9559 32 09 94
Z_955C:
	ld a,(D_93EA)	; 955C 3A EA 93
Z_955F:
	and a	; 955F A7
Z_9560:
	call nz,Z_84DF	; 9560 C4 DF 84
Z_9563:
	ld a,(D_9423)	; 9563 3A 23 94
Z_9566:
	ld c,a	; 9566 4F
Z_9567:
	ld a,(D_AC4E)	; 9567 3A 4E AC
Z_956A:
	ld (il_a),a	; 956A CB 67
	and 0x10
	ld a,(il_a)
Z_956C:
	jp z,Z_9576	; 956C 28 08
Z_956E:
	ld (il_a),a	; 956E CB 79
	ld a,c
	and 0x80
	ld a,(il_a)
Z_9570:
	push af	; 9570 CB FF
	or 0x80
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_9572:
	jp z,Z_9576	; 9572 28 02
Z_9574:
	push af	; 9574 CB A7
	and 0xEF
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_9576:
	ld (D_9423),a	; 9576 32 23 94
Z_9579:
	ld a,(D_93D6)	; 9579 3A D6 93
Z_957C:
	and a	; 957C A7
Z_957D:
	ret z	; 957D C8
Z_957E:
	ld a,(D_9409)	; 957E 3A 09 94
Z_9581:
	and 0xF0	; 9581 E6 F0
Z_9583:
	ld (D_9409),a	; 9583 32 09 94
Z_9586:
	ld a,(D_9423)	; 9586 3A 23 94
Z_9589:
	and 0xF0	; 9589 E6 F0
Z_958B:
	ld (D_9423),a	; 958B 32 23 94
Z_958E:
	ret	; 958E C9
Z_958F:
	ld (il_tmp),hl	; 958F DD 21 25 94
	ld hl,D_9425
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_9593:
	ld (il_tmp),hl	; 9593 FD 21 0B 94
	ld hl,D_940B
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_9597:
	jp Z_95A1	; 9597 18 08
Z_9599:
	ld (il_tmp),hl	; 9599 DD 21 0B 94
	ld hl,D_940B
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_959D:
	ld (il_tmp),hl	; 959D FD 21 25 94
	ld hl,D_9425
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_95A1:
	ld (il_a),a	; 95A1 DD CB 00 6E
	ld (il_tmp2),hl
	ld hl,(z80_ix)
	ld a,(hl)
	and 0x20
	ld hl,(il_tmp2)
	ld a,(il_a)
Z_95A5:
	jp nz,Z_97F5	; 95A5 C2 F5 97
Z_95A8:
	ld (il_a),a	; 95A8 DD CB FE 6E
	ld (il_tmp2),hl
	ld hl,(z80_ix)
	dec hl
	dec hl
	ld a,(hl)
	and 0x20
	ld hl,(il_tmp2)
	ld a,(il_a)
Z_95AC:
	jp nz,Z_978A	; 95AC C2 8A 97
Z_95AF:
	ld (il_a),a	; 95AF DD CB 00 7E
	ld (il_tmp2),hl
	ld hl,(z80_ix)
	ld a,(hl)
	and 0x80
	ld hl,(il_tmp2)
	ld a,(il_a)
Z_95B3:
	jp nz,Z_978A	; 95B3 C2 8A 97
Z_95B6:
	ld (il_a),a	; 95B6 DD CB FE 76
	ld (il_tmp2),hl
	ld hl,(z80_ix)
	dec hl
	dec hl
	ld a,(hl)
	and 0x40
	ld hl,(il_tmp2)
	ld a,(il_a)
Z_95BA:
	jp nz,Z_9705	; 95BA C2 05 97
Z_95BD:
	ld (il_a),a	; 95BD DD CB 00 46
	ld (il_tmp2),hl
	ld hl,(z80_ix)
	ld a,(hl)
	and 0x01
	ld hl,(il_tmp2)
	ld a,(il_a)
Z_95C1:
	jp nz,Z_9705	; 95C1 C2 05 97
Z_95C4:
	ld e,0x01	; 95C4 1E 01
Z_95C6:
	ld hl,D_9442	; 95C6 21 42 94
Z_95C9:
	rst 0x10	; 95C9 DD 7E FE
	db 0xFE
Z_95CC:
	and 0x1F	; 95CC E6 1F
Z_95CE:
	jp nz,Z_95E3	; 95CE 20 13
Z_95D0:
	rst 0x08	; 95D0 DD CB 00 66
	db 0x00, 0x10
Z_95D4:
	jp z,Z_95F3	; 95D4 28 1D
Z_95D6:
	ld hl,D_9446	; 95D6 21 46 94
Z_95D9:
	dec e	; 95D9 1D
Z_95DA:
	rst 0x28	; 95DA DD CB 00 D6
	db 0x00, 0x04
Z_95DE:
	rst 0x10	; 95DE DD 7E 06
	db 0x06
Z_95E1:
	jp Z_95F3	; 95E1 18 10
Z_95E3:
	rst 0x10	; 95E3 DD 7E 06
	db 0x06
Z_95E6:
	rst 0x08	; 95E6 DD CB 00 56
	db 0x00, 0x04
Z_95EA:
	rst 0x30	; 95EA DD CB 00 96
	db 0x00, 0xFB
Z_95EE:
	jp z,Z_95F3	; 95EE 28 03
Z_95F0:
	dec a	; 95F0 3D
Z_95F1:
	push af	; 95F1 CB C7
	or 0x01
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_95F3:
	inc a	; 95F3 3C
Z_95F4:
	and 0x03	; 95F4 E6 03
Z_95F6:
	rst 0x20	; 95F6 DD 77 06
	db 0x06
Z_95F9:
	ld b,0x00	; 95F9 06 00
Z_95FB:
	ld c,a	; 95FB 4F
Z_95FC:
	add hl,bc	; 95FC 09
Z_95FD:
	ld a,(hl)	; 95FD 7E
Z_95FE:
	rst 0x20	; 95FE DD 77 07
	db 0x07
Z_9601:
	ld c,a	; 9601 4F
Z_9602:
	ld hl,D_944A	; 9602 21 4A 94
Z_9605:
	add hl,bc	; 9605 09
Z_9606:
	ld a,(hl)	; 9606 7E
Z_9607:
	call il_ix_ldl	; 9607 DD 6E 02
	db 0x02
Z_960A:
	call il_ix_ldh	; 960A DD 66 03
	db 0x03
Z_960D:
	dec e	; 960D 1D
Z_960E:
	jp z,Z_9612	; 960E 28 02
Z_9610:
	ld a,0xDB	; 9610 3E DB
Z_9612:
	add a,l	; 9612 85
Z_9613:
	ld l,a	; 9613 6F
Z_9614:
	push hl	; 9614 E5
Z_9615:
	ld (il_tmp),hl	; 9615 DD E5
	ld hl,(z80_ix)
	push hl
	ld hl,(il_tmp)
Z_9617:
	ld (il_tmp),hl	; 9617 FD E5
	ld hl,(z80_iy)
	push hl
	ld hl,(il_tmp)
Z_9619:
	call Z_9652	; 9619 CD 52 96
Z_961C:
	ld (il_tmp),hl	; 961C FD E1
	pop hl
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_961E:
	ld (il_tmp),hl	; 961E DD E1
	pop hl
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_9620:
	pop hl	; 9620 E1
Z_9621:
	ld a,0x0A	; 9621 3E 0A
Z_9623:
	rst 0x08	; 9623 DD CB FF 56
	db 0xFF, 0x04
Z_9627:
	jp nz,Z_9633	; 9627 20 0A
Z_9629:
	ld a,0x22	; 9629 3E 22
Z_962B:
	rst 0x08	; 962B DD CB FF 4E
	db 0xFF, 0x02
Z_962F:
	jp z,Z_9639	; 962F 28 08
Z_9631:
	jp Z_963B	; 9631 18 08
Z_9633:
	rst 0x08	; 9633 DD CB FF 5E
	db 0xFF, 0x08
Z_9637:
	jp z,Z_963B	; 9637 28 02
Z_9639:
	add a,0x0C	; 9639 C6 0C
Z_963B:
	rst 0x08	; 963B DD CB 01 46
	db 0x01, 0x01
	jp	Z_963F	; мост в следующий кусок
	org	0x8696
D_8696:
Z_8696:
	db	0x00	; 8696
	org	0x8697
D_8697:
Z_8697:
	db	0x00	; 8697
	org	0x8698
D_8698:
Z_8698:
	db	0x00	; 8698
	org	0x8699
D_8699:
Z_8699:
	db	0x00	; 8699
	org	0x869A
D_869A:
Z_869A:
	db	0x00	; 869A
	org	0x869B
D_869B:
Z_869B:
	db	0x00	; 869B
	org	0x869C
il_pro_ix:
	                ld      (il_tmp2),hl
	                push    af
	                pop     hl
	                ld      (il_f),hl       ; AF вызывателя: h = a, l = флаги
	                pop     hl              ; возврат в тело
	                ex      (sp),hl         ; hl -> inline-байты
	                ld      a,(hl)          ; смещение
	                inc     hl
	                ex      (sp),hl         ; на стеке место после байтов
	                push    hl              ; возврат в тело
	                ld      hl,(z80_ix)
	                or      a
	                jp      m,il_ADRN21
	                add     a,l
	                ld      l,a
	                ret     nc
	                inc     h
	                ret
il_ADRN21:
	                add     a,l
	                ld      l,a
	                ret     c
	                dec     h
	                ret
il_pro2_ix:
	                ld      (il_tmp2),hl
	                push    af
	                pop     hl
	                ld      (il_f),hl       ; AF вызывателя: h = a, l = флаги
	                pop     hl              ; возврат в тело
	                ex      (sp),hl         ; hl -> inline-байты
	                inc     hl
	                ld      a,(hl)
	                ld      (il_d),a        ; маска/значение
	                dec     hl
	                ld      a,(hl)          ; смещение
	                inc     hl
	                inc     hl
	                ex      (sp),hl         ; на стеке место после байтов
	                push    hl              ; возврат в тело
	                ld      hl,(z80_ix)
	                or      a
	                jp      m,il_ADRN22
	                add     a,l
	                ld      l,a
	                ret     nc
	                inc     h
	                ret
il_ADRN22:
	                add     a,l
	                ld      l,a
	                ret     c
	                dec     h
	                ret
il_pro_iy:
	                ld      (il_tmp2),hl
	                push    af
	                pop     hl
	                ld      (il_f),hl       ; AF вызывателя: h = a, l = флаги
	                pop     hl              ; возврат в тело
	                ex      (sp),hl         ; hl -> inline-байты
	                ld      a,(hl)          ; смещение
	                inc     hl
	                ex      (sp),hl         ; на стеке место после байтов
	                push    hl              ; возврат в тело
	                ld      hl,(z80_iy)
	                or      a
	                jp      m,il_ADRN23
	                add     a,l
	                ld      l,a
	                ret     nc
	                inc     h
	                ret
il_ADRN23:
	                add     a,l
	                ld      l,a
	                ret     c
	                dec     h
	                ret
il_pro2_iy:
	                ld      (il_tmp2),hl
	                push    af
	                pop     hl
	                ld      (il_f),hl       ; AF вызывателя: h = a, l = флаги
	                pop     hl              ; возврат в тело
	                ex      (sp),hl         ; hl -> inline-байты
	                inc     hl
	                ld      a,(hl)
	                ld      (il_d),a        ; маска/значение
	                dec     hl
	                ld      a,(hl)          ; смещение
	                inc     hl
	                inc     hl
	                ex      (sp),hl         ; на стеке место после байтов
	                push    hl              ; возврат в тело
	                ld      hl,(z80_iy)
	                or      a
	                jp      m,il_ADRN24
	                add     a,l
	                ld      l,a
	                ret     nc
	                inc     h
	                ret
il_ADRN24:
	                add     a,l
	                ld      l,a
	                ret     c
	                dec     h
	                ret
il_ret_hl:
	                ld      hl,(il_tmp2)
	                ret
il_epi:
	                ld      hl,(il_f)
	                push    hl
	                pop     af
	                ld      hl,(il_tmp2)
	                ret
il_epi_a:
	                ld      hl,(il_f)
	                push    hl
	                pop     af
	                ld      a,(il_a)
	                ld      hl,(il_tmp2)
	                ret
il_ix_add:
	                call    il_pro_ix
	                ld a,(il_f+1)
	                add a,(hl)
	                jp il_ret_hl
il_ix_bit_b:
	                call    il_pro2_ix
	                ld a,(il_f)
	                rra
	                ld a,(il_d)
	                jp c,il_BITC25
	                and (hl)
	                ld a,(il_f+1)
	                jp il_ret_hl
il_BITC25:
	                and (hl)
	                scf
	                ld a,(il_f+1)
	                jp il_ret_hl
il_ix_cp:
	                call    il_pro_ix
	                ld a,(il_f+1)
	                cp (hl)
	                jp il_ret_hl
il_ix_dec:
	                call    il_pro_ix
	                dec (hl)
	                ld a,(il_f+1)
	                jp il_ret_hl
il_ix_inc:
	                call    il_pro_ix
	                inc (hl)
	                ld a,(il_f+1)
	                jp il_ret_hl
il_ix_lda_b:
	                call    il_pro_ix
	                ld a,(hl)
	                ld (il_a),a
	                jp il_epi_a
il_ix_ldb:
	                call    il_pro_ix
	                ld b,(hl)
	                jp il_epi
il_ix_ldc:
	                call    il_pro_ix
	                ld c,(hl)
	                jp il_epi
il_ix_ldd:
	                call    il_pro_ix
	                ld d,(hl)
	                jp il_epi
il_ix_lde:
	                call    il_pro_ix
	                ld e,(hl)
	                jp il_epi
il_ix_ldh:
	                call    il_pro_ix
	                ld a,(hl)
	                ld (il_tmp2+1),a
	                jp il_epi
il_ix_ldl:
	                call    il_pro_ix
	                ld a,(hl)
	                ld (il_tmp2),a
	                jp il_epi
il_ix_res_b:
	                call    il_pro2_ix
	                ld a,(il_d)
	                and (hl)
	                ld (hl),a
	                jp il_epi
il_ix_set_b:
	                call    il_pro2_ix
	                ld a,(il_d)
	                or (hl)
	                ld (hl),a
	                jp il_epi
il_ix_sta_b:
	                call    il_pro_ix
	                ld a,(il_f+1)
	                ld (hl),a
	                jp il_epi
il_ix_stb:
	                call    il_pro_ix
	                ld (hl),b
	                jp il_epi
il_ix_stc:
	                call    il_pro_ix
	                ld (hl),c
	                jp il_epi
il_ix_std:
	                call    il_pro_ix
	                ld (hl),d
	                jp il_epi
il_ix_ste:
	                call    il_pro_ix
	                ld (hl),e
	                jp il_epi
il_ix_sth:
	                call    il_pro_ix
	                ld a,(il_tmp2+1)
	                ld (hl),a
	                jp il_epi
il_ix_stl:
	                call    il_pro_ix
	                ld a,(il_tmp2)
	                ld (hl),a
	                jp il_epi
il_ix_stn_b:
	                call    il_pro2_ix
	                ld a,(il_d)
	                ld (hl),a
	                jp il_epi
il_iy_add:
	                call    il_pro_iy
	                ld a,(il_f+1)
	                add a,(hl)
	                jp il_ret_hl
il_iy_bit:
	                call    il_pro2_iy
	                ld a,(il_f)
	                rra
	                ld a,(il_d)
	                jp c,il_BITC26
	                and (hl)
	                ld a,(il_f+1)
	                jp il_ret_hl
il_BITC26:
	                and (hl)
	                scf
	                ld a,(il_f+1)
	                jp il_ret_hl
il_iy_cp:
	                call    il_pro_iy
	                ld a,(il_f+1)
	                cp (hl)
	                jp il_ret_hl
il_iy_dec:
	                call    il_pro_iy
	                dec (hl)
	                ld a,(il_f+1)
	                jp il_ret_hl
il_iy_lda:
	                call    il_pro_iy
	                ld a,(hl)
	                ld (il_a),a
	                jp il_epi_a
il_iy_ldb:
	                call    il_pro_iy
	                ld b,(hl)
	                jp il_epi
il_iy_ldd:
	                call    il_pro_iy
	                ld d,(hl)
	                jp il_epi
il_iy_lde:
	                call    il_pro_iy
	                ld e,(hl)
	                jp il_epi
il_iy_ldl:
	                call    il_pro_iy
	                ld a,(hl)
	                ld (il_tmp2),a
	                jp il_epi
il_iy_res:
	                call    il_pro2_iy
	                ld a,(il_d)
	                and (hl)
	                ld (hl),a
	                jp il_epi
il_iy_sta:
	                call    il_pro_iy
	                ld a,(il_f+1)
	                ld (hl),a
	                jp il_epi
il_iy_std:
	                call    il_pro_iy
	                ld (hl),d
	                jp il_epi
il_iy_ste:
	                call    il_pro_iy
	                ld (hl),e
	                jp il_epi
il_iy_stn:
	                call    il_pro2_iy
	                ld a,(il_d)
	                ld (hl),a
	                jp il_epi
il_iy_sub:
	                call    il_pro_iy
	                ld a,(il_f+1)
	                sub (hl)
	                jp il_ret_hl
il_rnd:
	                ld      a,(z80_r)       ; у i8080 регистра R нет; ряд ведёт
	                add     a,0x9D          ; эта ячейка: +0x9D на чтение,
	                ld      (z80_r),a       ; +1 на кадр (V_ISR связки)
	                ret
il_ldir:
	                push    af              ; Z80 ldir не трогает ни A, ни CY
	                ld      a,c
	                and     3
	                jp      z,il_ldir_q
il_ldir_s:
	                ld      a,(hl)
	                ld      (de),a
	                inc     hl
	                inc     de
	                dec     bc              ; DCX у i8080 ФЛАГОВ НЕ СТАВИТ
	                ld      a,c
	                and     3
	                jp      nz,il_ldir_s
	                ld      a,b
	                or      c
	                jp      z,il_ldir_x
il_ldir_q:
	                ld      a,b
	                or      a
	                rra
	                ld      b,a
	                ld      a,c
	                rra
	                ld      c,a
	                ld      a,b
	                or      a
	                rra
	                ld      b,a
	                ld      a,c
	                rra
	                ld      c,a
il_ldir_l:
	                ld      a,(hl)
	                ld      (de),a
	                inc     hl
	                inc     de
	                ld      a,(hl)
	                ld      (de),a
	                inc     hl
	                inc     de
	                ld      a,(hl)
	                ld      (de),a
	                inc     hl
	                inc     de
	                ld      a,(hl)
	                ld      (de),a
	                inc     hl
	                inc     de
	                dec     bc
	                ld      a,b
	                or      c
	                jp      nz,il_ldir_l
il_ldir_x:
	                pop     af
	                ret
il_lddr:
	                push    af
il_lddr_l:
	                ld      a,(hl)
	                ld      (de),a
	                dec     hl
	                dec     de
	                dec     bc
	                ld      a,b
	                or      c
	                jp      nz,il_lddr_l
	                pop     af
	                ret
il_exaf:
	                ld      (il_tmp2),hl
	                push    af
	                pop     hl
	                ld      (il_f),hl
	                ld      hl,(z80_af_alt)
	                push    hl
	                pop     af
	                ld      hl,(il_f)
	                ld      (z80_af_alt),hl
	                ld      hl,(il_tmp2)
	                ret
il_exx:
	                ld      (il_tmp),hl
	                ld      hl,(z80_hl2)
	                ld      (il_tmp2),hl
	                ld      hl,(il_tmp)
	                ld      (z80_hl2),hl
	                ld      hl,(z80_bc2)
	                push    hl
	                ld      h,b
	                ld      l,c
	                ld      (z80_bc2),hl
	                pop     bc
	                ld      hl,(z80_de2)
	                ex      de,hl
	                ld      (z80_de2),hl
	                ld      hl,(il_tmp2)
	                ret
il_ldi:
	                ld      (il_a),a
	                ld      a,(hl)
	                ld      (de),a
	                inc     hl
	                inc     de
	                dec     bc
	                ld      a,b
	                or      c
	                ld      a,0x01
	                jp      z,il_ldi_z
	                ld      a,0x03
il_ldi_z:
	                or      a
	                ld      a,(il_a)
	                ret
Z_34AF:
	ld hl,0x3E	; 34AF 21 3E 00
Z_34B2:
	jp 0x34BD	; 34B2 18 09
Z_34BA:
	ld hl,0x7E	; 34BA 21 7E 00
	jp 0x34BD
Z_35C0:
	di	; 35C0 F3
Z_35C1:
	nop	; 35C1 00
Z_35C2:
	nop	; 35C2 00
Z_35C3:
	pop hl	; 35C3 E1
Z_35C4:
	ld (il_tmp),hl	; 35C4 ED 73 8F 34
	push af
	ld hl,2
	add hl,sp
	ld (D_348F),hl
	pop af
	ld hl,(il_tmp)
Z_35C8:
	ld sp,0xC000	; 35C8 31 00 C0
Z_35CB:
	push hl	; 35CB E5
Z_35CC:
	ld b,0x01	; 35CC 06 01
Z_35CE:
	call Z_3634	; 35CE CD 34 36
Z_35D1:
	ld (D_3489),a	; 35D1 32 89 34
Z_35D4:
	ld a,0x40	; 35D4 3E 40
Z_35D6:
	ld (D_348D),a	; 35D6 32 8D 34
Z_35D9:
	call Z_3662	; 35D9 CD 62 36
Z_35DC:
	jp c,Z_361B	; 35DC 38 3D
Z_35DE:
	ld a,(D_348E)	; 35DE 3A 8E 34
Z_35E1:
	ld (D_348A),a	; 35E1 32 8A 34
Z_35E4:
	ld hl,0x4111	; 35E4 21 11 41
Z_35E7:
	ld bc,0x05	; 35E7 01 05 00
Z_35EA:
	call Z_37A4	; 35EA CD A4 37
Z_35ED:
	call Z_3770	; 35ED CD 70 37
Z_35F0:
	ld a,0xC3	; 35F0 3E C3
Z_35F2:
	ld (0x0FF0),a	; 35F2 32 F0 0F
Z_35F5:
	ld hl,D_3B47	; 35F5 21 47 3B
Z_35F8:
	ld (0x0FF1),hl	; 35F8 22 F1 0F
Z_35FB:
	ld hl,0x4000	; 35FB 21 00 40
Z_35FE:
	ld bc,0x41	; 35FE 01 41 00
Z_3601:
	ld (hl),c	; 3601 71
Z_3602:
	inc hl	; 3602 23
Z_3603:
	dec b	; 3603 10 FC
	jp nz,Z_3601
Z_3605:
	ld (hl),c	; 3605 71
Z_3606:
	ld a,0xC3	; 3606 3E C3
Z_3608:
	ld (GAME_ISR_HOOK),a	; 3608 32 41 41
Z_360B:
	ld hl,Z_36F3	; 360B 21 F3 36
Z_360E:
	ld (0x4142),hl	; 360E 22 42 41
Z_3611:
	ld a,0x40	; 3611 3E 40
Z_3613:
Z_3615:
Z_3617:
	ei	; 3617 FB
Z_3618:
	jp Z_3732	; 3618 C3 32 37
Z_361B:
	ld a,0x0D	; 361B 3E 0D
Z_361D:
	call 0xA2	; 361D CD A2 00
Z_3620:
	ld hl,D_3498	; 3620 21 98 34
Z_3623:
	ld a,(hl)	; 3623 7E
Z_3624:
	cp 0x2B	; 3624 FE 2B
Z_3626:
	jp z,Z_362E	; 3626 28 06
Z_3628:
	call 0xA2	; 3628 CD A2 00
Z_362B:
	inc hl	; 362B 23
Z_362C:
	jp Z_3623	; 362C 18 F5
Z_362E:
	ld a,0xFF	; 362E 3E FF
Z_3630:
	call Z_3A2C	; 3630 CD 2C 3A
Z_3633:
Z_3634:
	xor a	; 3634 AF
Z_3635:
	ret	; 3635 C9
Z_3662:
	xor a	; 3662 AF
Z_3663:
	ret	; 3663 C9
Z_36D7:
	di	; 36D7 F3
Z_36D8:
	ld a,0xC9	; 36D8 3E C9
Z_36DA:
	ld (0x0FF0),a	; 36DA 32 F0 0F
Z_36DD:
Z_36DF:
	ld h,0x40	; 36DF 26 40
Z_36E1:
	ld a,(D_3489)	; 36E1 3A 89 34
Z_36E4:
	call 0x24	; 36E4 CD 24 00
Z_36E7:
	call 0x6C	; 36E7 CD 6C 00
Z_36EA:
	ei	; 36EA FB
Z_36EB:
	ld (il_tmp),hl	; 36EB ED 7B 8F 34
	ld hl,(D_348F)
	ld sp,hl
	ld hl,(il_tmp)
Z_36EF:
	ret	; 36EF C9
Z_36F3:
	di	; 36F3 F3
Z_36F4:
	push af	; 36F4 F5
Z_36F5:
	ld a,0x80	; 36F5 3E 80
Z_36F7:
	and a	; 36F7 A7
Z_36F8:
	jp p,Z_3712	; 36F8 F2 12 37
Z_36FB:
	push bc	; 36FB C5
Z_36FC:
	push hl	; 36FC E5
Z_36FD:
	push de	; 36FD D5
	ld hl,(il_tmp)
	push hl
	ld hl,(il_tmp2)
	push hl
	ld hl,(il_f)
	push hl
	ld hl,(il_a)
	push hl
Z_36FE:
	ld (il_tmp),hl	; 36FE DD E5
	ld hl,(z80_ix)
	push hl
	ld hl,(il_tmp)
Z_3700:
	ld (il_tmp),hl	; 3700 FD E5
	ld hl,(z80_iy)
	push hl
	ld hl,(il_tmp)
Z_3702:
	call Z_3714	; 3702 CD 14 37
Z_3705:
	call Z_3715	; 3705 CD 15 37
Z_3708:
	call Z_372C	; 3708 CD 2C 37
Z_370B:
	ld (il_tmp),hl	; 370B FD E1
	pop hl
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_370D:
	ld (il_tmp),hl	; 370D DD E1
	pop hl
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_370F:
	pop hl	; 370F D1
	ld (il_a),hl
	pop hl
	ld (il_f),hl
	pop hl
	ld (il_tmp2),hl
	pop hl
	ld (il_tmp),hl
	pop de
Z_3710:
	pop hl	; 3710 E1
Z_3711:
	pop bc	; 3711 C1
Z_3712:
	pop af	; 3712 F1
Z_3713:
	ei	; 3713 FB
Z_3714:
	ret	; 3714 C9
Z_3715:
	ld hl,(0x4111)	; 3715 2A 11 41
Z_3718:
	inc hl	; 3718 23
Z_3719:
	ld (0x4111),hl	; 3719 22 11 41
Z_371C:
	ld a,h	; 371C 7C
Z_371D:
	or l	; 371D B5
Z_371E:
	jp nz,Z_3724	; 371E 20 04
Z_3720:
	ld hl,0x4113	; 3720 21 13 41
Z_3723:
	inc (hl)	; 3723 34
Z_3724:
	jp Z_A186	; 3724 C3 86 A1
Z_372C:
	call 0x063F	; 372C CD 3F 06
Z_372F:
	jp Z_3811	; 372F C3 11 38
Z_3732:
	call Z_3769	; 3732 CD 69 37
Z_3735:
	ld hl,0x00	; 3735 21 00 00
Z_3738:
	ld (TEXT_ROW),hl	; 3738 22 02 41
Z_373B:
	ld bc,0x1800	; 373B 01 00 18
Z_373E:
	xor a	; 373E AF
Z_373F:
	call Z_377F	; 373F CD 7F 37
Z_3742:
	ld hl,0x2000	; 3742 21 00 20
Z_3745:
	ld bc,0x1800	; 3745 01 00 18
Z_3748:
	ld a,(D_3424)	; 3748 3A 24 34
Z_374B:
	call Z_377F	; 374B CD 7F 37
Z_374E:
	ld hl,0x1800	; 374E 21 00 18
Z_3751:
	ld bc,0x0300	; 3751 01 00 03
Z_3754:
	xor a	; 3754 AF
Z_3755:
	call Z_3791	; 3755 CD 91 37
Z_3758:
	ld hl,D_342D	; 3758 21 2D 34
Z_375B:
	push af	; 375B CB F6
	ld a,(hl)
	or 0x40
	ld (hl),a
	pop af
Z_375D:
	ld b,(hl)	; 375D 46
Z_375E:
	ld c,0x01	; 375E 0E 01
Z_3760:
	ret	; 3760 C9
Z_3769:
	ld hl,D_342D	; 3769 21 2D 34
Z_376C:
	push af	; 376C CB B6
	ld a,(hl)
	and 0xBF
	ld (hl),a
	pop af
Z_376E:
	jp Z_375D	; 376E 18 ED
Z_3770:
	ld hl,D_3433	; 3770 21 33 34
Z_3773:
	ld c,0x07	; 3773 0E 07
Z_3775:
	ld b,(hl)	; 3775 46
Z_3776:
	call Z_3760	; 3776 CD 60 37
Z_3779:
	dec hl	; 3779 2B
Z_377A:
	dec c	; 377A 0D
Z_377B:
	jp p,Z_3775	; 377B F2 75 37
Z_377E:
	ret	; 377E C9
Z_377F:
	push af	; 377F F5
Z_3780:
	ld a,h	; 3780 7C
Z_3781:
	or l	; 3781 B5
Z_3782:
	jp nz,Z_378C	; 3782 20 08
Z_3784:
	ld a,(0x0FEE)	; 3784 3A EE 0F
Z_3787:
	or a	; 3787 B7
Z_3788:
	jp z,Z_378C	; 3788 28 02
Z_378A:
	pop af	; 378A F1
Z_378B:
	ret	; 378B C9
Z_378C:
	pop af	; 378C F1
Z_378D:
	jp 0x02FC	; 378D C3 FC 02
Z_3791:
	jp 0x031B	; 3791 C3 1B 03
Z_37A4:
	ld (hl),0x00	; 37A4 36 00
Z_37A6:
	push hl	; 37A6 E5
Z_37A7:
	pop de	; 37A7 D1
Z_37A8:
	inc de	; 37A8 13
Z_37A9:
	dec bc	; 37A9 0B
Z_37AA:
	call il_ldir	; 37AA ED B0
Z_37AC:
	ret	; 37AC C9
Z_37BD:
	rlca	; 37BD 07
Z_37BE:
	rlca	; 37BE 07
Z_37BF:
	rlca	; 37BF 07
Z_37C0:
	rlca	; 37C0 07
Z_37C1:
	ld b,a	; 37C1 47
Z_37C2:
	ld a,(D_3424)	; 37C2 3A 24 34
Z_37C5:
	and 0x0F	; 37C5 E6 0F
Z_37C7:
	or b	; 37C7 B0
Z_37C8:
	ld (D_3424),a	; 37C8 32 24 34
Z_37CB:
	ret	; 37CB C9
Z_37CC:
	di	; 37CC F3
Z_37CD:
	call Z_37D2	; 37CD CD D2 37
Z_37D0:
	ei	; 37D0 FB
Z_37D1:
	ret	; 37D1 C9
Z_37D2:
	jp 0x063E	; 37D2 C3 3E 06
Z_3811:
	ld hl,0x4104	; 3811 21 04 41
Z_3814:
	ld b,0x0B	; 3814 06 0B
Z_3816:
	ld a,(hl)	; 3816 7E
Z_3817:
	cp 0xFF	; 3817 FE FF
Z_3819:
	jp z,Z_383E	; 3819 28 23
Z_381B:
	ld c,0x00	; 381B 0E 00
Z_381D:
	rrca	; 381D 0F
Z_381E:
	jp nc,Z_3823	; 381E 30 03
Z_3820:
	inc c	; 3820 0C
Z_3821:
	jp Z_381D	; 3821 18 FA
Z_3823:
	ld a,0x0B	; 3823 3E 0B
Z_3825:
	sub b	; 3825 90
Z_3826:
	rlca	; 3826 07
Z_3827:
	rlca	; 3827 07
Z_3828:
	rlca	; 3828 07
Z_3829:
	add a,c	; 3829 81
Z_382A:
	ld (G_KEY_CODE),a	; 382A 32 0F 41
Z_382D:
	ld e,a	; 382D 5F
Z_382E:
	ld d,0x00	; 382E 16 00
Z_3830:
	ld hl,(D_3436)	; 3830 2A 36 34
Z_3833:
	add hl,de	; 3833 19
Z_3834:
	ld a,(hl)	; 3834 7E
Z_3835:
	cp 0x05	; 3835 FE 05
Z_3837:
	jp z,Z_36D7	; 3837 CA D7 36
Z_383A:
	ld (G_KEY_ASCII),a	; 383A 32 10 41
Z_383D:
	ret	; 383D C9
Z_383E:
	inc hl	; 383E 23
Z_383F:
	dec b	; 383F 10 D5
	jp nz,Z_3816
Z_3841:
	ld (G_KEY_CODE),a	; 3841 32 0F 41
Z_3844:
	jp Z_383A	; 3844 18 F4
Z_3846:
	ld l,a	; 3846 6F
Z_3847:
	ld (il_a),a	; 3847 CB 3D
	ld a,l
	or a
	rra
	ld l,a
	ld a,(il_a)
Z_3849:
	ld (il_a),a	; 3849 CB 3D
	ld a,l
	or a
	rra
	ld l,a
	ld a,(il_a)
Z_384B:
	ld (il_a),a	; 384B CB 3D
	ld a,l
	or a
	rra
	ld l,a
	ld a,(il_a)
Z_384D:
	ld bc,0x4104	; 384D 01 04 41
Z_3850:
	ld h,0x00	; 3850 26 00
Z_3852:
	add hl,bc	; 3852 09
Z_3853:
	and 0x07	; 3853 E6 07
Z_3855:
	rlca	; 3855 07
Z_3856:
	rlca	; 3856 07
Z_3857:
	rlca	; 3857 07
Z_3858:
	or 0x46	; 3858 F6 46
Z_385A:
	ld (il_a),a	; 385A 32 5E 38
	rrca
	rrca
	rrca
	and 7
	push bc
	ld c,a
	ld a,1
	inc c
il_HAND1_l:
	dec c
	jp z,il_HAND1_d
	add a,a
	jp il_HAND1_l
il_HAND1_d:
	ld (il_d),a
	pop bc
Z_385D:
	ld a,(il_d)	; 385D CB 46
	and (hl)
	ld a,(il_a)
Z_385F:
	ret	; 385F C9
Z_386E:
	push de	; 386E D5
Z_386F:
	ld hl,(0x4114)	; 386F 2A 14 41
Z_3872:
	ld d,h	; 3872 54
Z_3873:
	ld e,l	; 3873 5D
Z_3874:
	add hl,hl	; 3874 29
Z_3875:
	add hl,hl	; 3875 29
Z_3876:
	add hl,de	; 3876 19
Z_3877:
	add hl,hl	; 3877 29
Z_3878:
	add hl,hl	; 3878 29
Z_3879:
	add hl,hl	; 3879 29
Z_387A:
	add hl,de	; 387A 19
Z_387B:
	push af	; 387B CB BC
	ld a,h
	and 0x7F
	ld h,a
	pop af
Z_387D:
	ld (0x4114),hl	; 387D 22 14 41
Z_3880:
	ld a,l	; 3880 7D
Z_3881:
	pop de	; 3881 D1
Z_3882:
	ret	; 3882 C9
Z_388A:
	push de	; 388A D5
Z_388B:
	xor a	; 388B AF
Z_388C:
	ld (il_a),a	; 388C ED 52
	ld a,l
	sbc a,e
	ld l,a
	ld a,h
	sbc a,d
	ld h,a
	jp nz,il_AS3
	jp c,il_ASC4
	ld a,l
	or a
	jp il_AS3
il_ASC4:
	ld a,l
	or a
	scf
il_AS3:
	ld a,(il_a)
Z_388E:
	push hl	; 388E E5
Z_388F:
	pop bc	; 388F C1
Z_3890:
	ld hl,0x7FFF	; 3890 21 FF 7F
Z_3893:
	call Z_39A3	; 3893 CD A3 39
Z_3896:
	push hl	; 3896 E5
Z_3897:
	call Z_386E	; 3897 CD 6E 38
Z_389A:
	pop bc	; 389A C1
Z_389B:
	call Z_39A3	; 389B CD A3 39
Z_389E:
	pop de	; 389E D1
Z_389F:
	add hl,de	; 389F 19
Z_38A0:
	ld (BLIT_Y),hl	; 38A0 22 00 33
Z_38A3:
	ret	; 38A3 C9
Z_38E8:
	ld bc,0x00	; 38E8 01 00 00
Z_38EB:
	ld a,(BLIT_Y)	; 38EB 3A 00 33
Z_38EE:
	ld de,Z_3924	; 38EE 11 24 39
Z_38F1:
	nop	; 38F1 00
Z_38F2:
	nop	; 38F2 00
Z_38F3:
	nop	; 38F3 00
Z_38F4:
	nop	; 38F4 00
Z_38F5:
	ld (0x411E),a	; 38F5 32 1E 41
Z_38F8:
	push hl	; 38F8 ED 43 1F 41
	ld h,b
	ld l,c
	ld (0x411F),hl
	pop hl
Z_38FC:
	ld de,0x4146	; 38FC 11 46 41
Z_38FF:
	ld b,0x00	; 38FF 06 00
Z_3901:
	ld a,0x5F	; 3901 3E 5F
Z_3903:
	rst 0x18	; 3903 DF
Z_3904:
	ld a,0x08	; 3904 3E 08
Z_3906:
	rst 0x18	; 3906 DF
Z_3907:
	ld a,0xFF	; 3907 3E FF
Z_3909:
	ld (de),a	; 3909 12
Z_390A:
	call Z_3A2F	; 390A CD 2F 3A
Z_390D:
	cp 0x0D	; 390D FE 0D
Z_390F:
	jp z,Z_3935	; 390F 28 24
Z_3911:
	cp 0x10	; 3911 FE 10
Z_3913:
	jp z,Z_397A	; 3913 28 65
Z_3915:
	cp 0x20	; 3915 FE 20
Z_3917:
	jp c,Z_390A	; 3917 38 F1
Z_3919:
	cp 0x5B	; 3919 FE 5B
Z_391B:
	jp nc,Z_390A	; 391B 30 ED
Z_391D:
	nop	; 391D 00
Z_391E:
	nop	; 391E 00
Z_391F:
	nop	; 391F 00
Z_3920:
	nop	; 3920 00
Z_3921:
	nop	; 3921 00
Z_3922:
	nop	; 3922 00
Z_3923:
	nop	; 3923 00
Z_3924:
	rst 0x18	; 3924 DF
Z_3925:
	ld (de),a	; 3925 12
Z_3926:
	inc de	; 3926 13
Z_3927:
	ld a,0xFF	; 3927 3E FF
Z_3929:
	ld (de),a	; 3929 12
Z_392A:
	inc b	; 392A 04
Z_392B:
	ld a,b	; 392B 78
Z_392C:
	ld hl,0x411E	; 392C 21 1E 41
Z_392F:
	cp (hl)	; 392F BE
Z_3930:
	jp c,Z_3901	; 3930 38 CF
Z_3932:
	ld (0x4123),a	; 3932 32 23 41
Z_3935:
	ld a,0x20	; 3935 3E 20
Z_3937:
	rst 0x18	; 3937 DF
Z_3938:
	ld a,(0x411F)	; 3938 3A 1F 41
Z_393B:
	or a	; 393B B7
Z_393C:
	jp nz,Z_3943	; 393C 20 05
Z_393E:
	ld a,b	; 393E 78
Z_393F:
	ld (BLIT_Y),a	; 393F 32 00 33
Z_3942:
	ret	; 3942 C9
Z_3943:
	ld de,0x4146	; 3943 11 46 41
Z_3946:
	ld hl,0x00	; 3946 21 00 00
Z_3949:
	xor a	; 3949 AF
Z_394A:
	ld (0x4122),a	; 394A 32 22 41
Z_394D:
	ld a,(de)	; 394D 1A
Z_394E:
	cp 0x2D	; 394E FE 2D
Z_3950:
	jp nz,Z_3959	; 3950 20 07
Z_3952:
	ld a,0x01	; 3952 3E 01
Z_3954:
	ld (0x4122),a	; 3954 32 22 41
Z_3957:
	jp Z_396A	; 3957 18 11
Z_3959:
	cp 0xFF	; 3959 FE FF
Z_395B:
	jp z,Z_396D	; 395B 28 10
Z_395D:
	push af	; 395D F5
Z_395E:
	push hl	; 395E ED 4B 1F 41
	ld hl,(0x411F)
	ld b,h
	ld c,l
	pop hl
Z_3962:
	call Z_398C	; 3962 CD 8C 39
Z_3965:
	pop af	; 3965 F1
Z_3966:
	ld c,a	; 3966 4F
Z_3967:
	ld b,0x00	; 3967 06 00
Z_3969:
	add hl,bc	; 3969 09
Z_396A:
	inc de	; 396A 13
Z_396B:
	jp Z_394D	; 396B 18 E0
Z_396D:
	ld a,(0x4122)	; 396D 3A 22 41
Z_3970:
	or a	; 3970 B7
Z_3971:
	ret z	; 3971 C8
Z_3972:
	ld a,h	; 3972 7C
Z_3973:
	cpl	; 3973 2F
Z_3974:
	ld h,a	; 3974 67
Z_3975:
	ld a,l	; 3975 7D
Z_3976:
	cpl	; 3976 2F
Z_3977:
	ld l,a	; 3977 6F
Z_3978:
	inc hl	; 3978 23
Z_3979:
	ret	; 3979 C9
Z_397A:
	ld a,b	; 397A 78
Z_397B:
	or a	; 397B B7
Z_397C:
	jp z,Z_3901	; 397C 28 83
Z_397E:
	dec de	; 397E 1B
Z_397F:
	dec b	; 397F 05
Z_3980:
	ld a,0x20	; 3980 3E 20
Z_3982:
	rst 0x18	; 3982 DF
Z_3983:
	ld a,0x08	; 3983 3E 08
Z_3985:
	rst 0x18	; 3985 DF
Z_3986:
	ld a,0x10	; 3986 3E 10
Z_3988:
	rst 0x18	; 3988 DF
Z_3989:
	jp Z_3901	; 3989 C3 01 39
Z_398C:
	push de	; 398C D5
Z_398D:
	ld de,0x00	; 398D 11 00 00
Z_3990:
	ex de,hl	; 3990 EB
Z_3991:
	ld a,0x10	; 3991 3E 10
Z_3993:
	ld (il_a),a	; 3993 CB 38
	ld a,b
	or a
	rra
	ld b,a
	ld a,(il_a)
Z_3995:
	ld (il_a),a	; 3995 CB 19
	ld a,c
	rra
	ld c,a
	ld a,(il_a)
Z_3997:
	jp nc,Z_399A	; 3997 30 01
Z_3999:
	add hl,de	; 3999 19
Z_399A:
	ld (il_a),a	; 399A CB 23
	ld a,e
	add a,a
	ld e,a
	ld a,(il_a)
Z_399C:
	ld (il_a),a	; 399C CB 12
	ld a,d
	rla
	ld d,a
	ld a,(il_a)
Z_399E:
	dec a	; 399E 3D
Z_399F:
	jp nz,Z_3993	; 399F 20 F2
Z_39A1:
	pop de	; 39A1 D1
Z_39A2:
	ret	; 39A2 C9
Z_39A3:
	push de	; 39A3 D5
Z_39A4:
	ld de,0x00	; 39A4 11 00 00
Z_39A7:
	ex de,hl	; 39A7 EB
Z_39A8:
	ld a,0x10	; 39A8 3E 10
Z_39AA:
	ld (il_a),a	; 39AA CB 13
	ld a,e
	rla
	ld e,a
	ld a,(il_a)
Z_39AC:
	ld (il_a),a	; 39AC CB 12
	ld a,d
	rla
	ld d,a
	ld a,(il_a)
Z_39AE:
	ld (il_a),a	; 39AE ED 6A
	ld a,l
	adc a,l
	ld l,a
	ld a,h
	adc a,h
	ld h,a
	ld a,(il_a)
Z_39B0:
	ld (il_a),a	; 39B0 ED 42
	ld a,l
	sbc a,c
	ld l,a
	ld a,h
	sbc a,b
	ld h,a
	ld a,(il_a)
Z_39B2:
	jp nc,Z_39B5	; 39B2 30 01
Z_39B4:
	add hl,bc	; 39B4 09
Z_39B5:
	ccf	; 39B5 3F
Z_39B6:
	dec a	; 39B6 3D
Z_39B7:
	jp nz,Z_39AA	; 39B7 20 F1
Z_39B9:
	ld (il_a),a	; 39B9 CB 13
	ld a,e
	rla
	ld e,a
	ld a,(il_a)
Z_39BB:
	ld (il_a),a	; 39BB CB 12
	ld a,d
	rla
	ld d,a
	ld a,(il_a)
Z_39BD:
	ld (0x411A),hl	; 39BD 22 1A 41
Z_39C0:
	ex de,hl	; 39C0 EB
Z_39C1:
	pop de	; 39C1 D1
Z_39C2:
	ret	; 39C2 C9
Z_39E6:
	ld d,0x00	; 39E6 16 00
Z_39E8:
	push de	; 39E8 D5
Z_39E9:
	ld e,a	; 39E9 5F
Z_39EA:
	push de	; 39EA D5
Z_39EB:
	ld hl,0x00	; 39EB 21 00 00
Z_39EE:
	ld (il_tmp),hl	; 39EE DD 21 00 00
	ld hl,0x00
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_39F2:
	ld a,(D_341D)	; 39F2 3A 1D 34
Z_39F5:
	ld b,0x06	; 39F5 06 06
Z_39F7:
	rrca	; 39F7 0F
Z_39F8:
	jp nc,Z_39FB	; 39F8 30 01
Z_39FA:
	add hl,de	; 39FA 19
Z_39FB:
	ld (il_a),a	; 39FB CB 23
	ld a,e
	add a,a
	ld e,a
	ld a,(il_a)
Z_39FD:
	ld (il_a),a	; 39FD CB 12
	ld a,d
	rla
	ld d,a
	ld a,(il_a)
Z_39FF:
	dec b	; 39FF 10 F6
	jp nz,Z_39F7
Z_3A01:
	pop de	; 3A01 D1
Z_3A02:
	ld (il_a),a	; 3A02 CB 3B
	ld a,e
	or a
	rra
	ld e,a
	ld a,(il_a)
Z_3A04:
	ld (il_a),a	; 3A04 CB 3B
	ld a,e
	or a
	rra
	ld e,a
	ld a,(il_a)
Z_3A06:
	ld (il_a),a	; 3A06 CB 3B
	ld a,e
	or a
	rra
	ld e,a
	ld a,(il_a)
Z_3A08:
	ld a,(D_341D)	; 3A08 3A 1D 34
Z_3A0B:
	ld b,0x06	; 3A0B 06 06
Z_3A0D:
	rrca	; 3A0D 0F
Z_3A0E:
	jp nc,Z_3A12	; 3A0E 30 02
Z_3A10:
	ld (il_tmp),hl	; 3A10 DD 19
	ld hl,(z80_ix)
	add hl,de
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_3A12:
	ld (il_a),a	; 3A12 CB 23
	ld a,e
	add a,a
	ld e,a
	ld a,(il_a)
Z_3A14:
	ld (il_a),a	; 3A14 CB 12
	ld a,d
	rla
	ld d,a
	ld a,(il_a)
Z_3A16:
	dec b	; 3A16 10 F5
	jp nz,Z_3A0D
Z_3A18:
	pop bc	; 3A18 C1
Z_3A19:
	push hl	; 3A19 ED 5B 20 34
	ld hl,(D_3420)
	ld d,h
	ld e,l
	pop hl
Z_3A1D:
	ld (il_tmp),hl	; 3A1D DD 19
	ld hl,(z80_ix)
	add hl,de
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_3A1F:
	ld (il_tmp),hl	; 3A1F DD 09
	ld hl,(z80_ix)
	add hl,bc
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_3A21:
	ld (il_tmp),hl	; 3A21 DD 22 22 34
	ld hl,(z80_ix)
	ld (D_3422),hl
	ld hl,(il_tmp)
Z_3A25:
	push hl	; 3A25 ED 5B 1E 34
	ld hl,(D_341E)
	ld d,h
	ld e,l
	pop hl
Z_3A29:
	add hl,de	; 3A29 19
Z_3A2A:
	add hl,bc	; 3A2A 09
Z_3A2B:
	ret	; 3A2B C9
Z_3A2C:
	or a	; 3A2C B7
Z_3A2D:
	jp nz,Z_3A4A	; 3A2D 20 1B
Z_3A2F:
	push hl	; 3A2F E5
Z_3A30:
	push bc	; 3A30 C5
Z_3A31:
	push de	; 3A31 D5
Z_3A32:
	call Z_3A56	; 3A32 CD 56 3A
Z_3A35:
	ld a,(G_KEY_ASCII)	; 3A35 3A 10 41
Z_3A38:
	cp 0xFF	; 3A38 FE FF
Z_3A3A:
	jp nz,Z_3A32	; 3A3A 20 F6
Z_3A3C:
	call Z_3A56	; 3A3C CD 56 3A
Z_3A3F:
	ld a,(G_KEY_ASCII)	; 3A3F 3A 10 41
Z_3A42:
	cp 0xFF	; 3A42 FE FF
Z_3A44:
	jp z,Z_3A3C	; 3A44 28 F6
Z_3A46:
	pop de	; 3A46 D1
Z_3A47:
	pop bc	; 3A47 C1
Z_3A48:
	pop hl	; 3A48 E1
Z_3A49:
	ret	; 3A49 C9
Z_3A4A:
	ld b,a	; 3A4A 47
Z_3A4B:
	ld hl,0x0362	; 3A4B 21 62 03
Z_3A4E:
	dec hl	; 3A4E 2B
Z_3A4F:
	ld a,h	; 3A4F 7C
Z_3A50:
	or l	; 3A50 B5
Z_3A51:
	jp nz,Z_3A4E	; 3A51 20 FB
Z_3A53:
	dec b	; 3A53 10 F6
	jp nz,Z_3A4B
Z_3A55:
	ret	; 3A55 C9
Z_3A56:
	ld a,0x05	; 3A56 3E 05
Z_3A58:
	call Z_3A4A	; 3A58 CD 4A 3A
Z_3A5B:
	call Z_37CC	; 3A5B CD CC 37
Z_3A5E:
	jp Z_3811	; 3A5E C3 11 38
Z_3B3F:
	ld hl,(D_3422)	; 3B3F 2A 22 34
Z_3B42:
	ld a,(D_3424)	; 3B42 3A 24 34
Z_3B45:
	ld (hl),a	; 3B45 77
Z_3B46:
	ret	; 3B46 C9
Z_3B53:
	cp 0x20	; 3B53 FE 20
Z_3B55:
	jp nc,Z_3B6B	; 3B55 30 14
Z_3B57:
	cp 0x0D	; 3B57 FE 0D
Z_3B59:
	jp z,Z_3BCC	; 3B59 CA CC 3B
Z_3B5C:
	cp 0x08	; 3B5C FE 08
Z_3B5E:
	jp z,Z_3BE1	; 3B5E CA E1 3B
Z_3B61:
	cp 0x09	; 3B61 FE 09
Z_3B63:
	jp z,Z_3BFE	; 3B63 CA FE 3B
Z_3B66:
	cp 0x10	; 3B66 FE 10
Z_3B68:
	jp z,Z_3C14	; 3B68 CA 14 3C
Z_3B6B:
	ld l,a	; 3B6B 6F
Z_3B6C:
	ld h,0x00	; 3B6C 26 00
Z_3B6E:
	add hl,hl	; 3B6E 29
Z_3B6F:
	add hl,hl	; 3B6F 29
Z_3B70:
	add hl,hl	; 3B70 29
Z_3B71:
	push hl	; 3B71 ED 5B 34 34
	ld hl,(D_3434)
	ld d,h
	ld e,l
	pop hl
Z_3B75:
	add hl,de	; 3B75 19
Z_3B76:
	ld a,(D_341C)	; 3B76 3A 1C 34
Z_3B79:
	or a	; 3B79 B7
Z_3B7A:
	jp nz,Z_3B9D	; 3B7A 20 21
Z_3B7C:
	call 0x02DE	; 3B7C CD DE 02
Z_3B7F:
	jp Z_3BC2	; 3B7F C3 C2 3B
Z_3B9D:
	push hl	; 3B9D E5
Z_3B9E:
	ld a,(TEXT_COL)	; 3B9E 3A 03 41
Z_3BA1:
	ld e,a	; 3BA1 5F
Z_3BA2:
	ld a,(TEXT_ROW)	; 3BA2 3A 02 41
Z_3BA5:
	rlca	; 3BA5 07
Z_3BA6:
	rlca	; 3BA6 07
Z_3BA7:
	rlca	; 3BA7 07
Z_3BA8:
	call Z_39E6	; 3BA8 CD E6 39
Z_3BAB:
	ld a,(D_341D)	; 3BAB 3A 1D 34
Z_3BAE:
	ld e,a	; 3BAE 5F
Z_3BAF:
	ld d,0x00	; 3BAF 16 00
Z_3BB1:
	ld (il_tmp),hl	; 3BB1 DD E1
	pop hl
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_3BB3:
	ld b,0x08	; 3BB3 06 08
Z_3BB5:
	rst 0x10	; 3BB5 DD 7E 00
	db 0x00
Z_3BB8:
	nop	; 3BB8 00
Z_3BB9:
	ld (hl),a	; 3BB9 77
Z_3BBA:
	ld (il_tmp),hl	; 3BBA DD 23
	ld hl,(z80_ix)
	inc hl
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_3BBC:
	add hl,de	; 3BBC 19
Z_3BBD:
	dec b	; 3BBD 10 F6
	jp nz,Z_3BB5
Z_3BBF:
	call Z_3B3F	; 3BBF CD 3F 3B
Z_3BC2:
	ld a,(TEXT_COL)	; 3BC2 3A 03 41
Z_3BC5:
	inc a	; 3BC5 3C
Z_3BC6:
	ld hl,D_341D	; 3BC6 21 1D 34
Z_3BC9:
	cp (hl)	; 3BC9 BE
Z_3BCA:
	jp c,Z_3BDD	; 3BCA 38 11
Z_3BCC:
	xor a	; 3BCC AF
Z_3BCD:
	ld (TEXT_COL),a	; 3BCD 32 03 41
Z_3BD0:
	ld a,(TEXT_ROW)	; 3BD0 3A 02 41
Z_3BD3:
	inc a	; 3BD3 3C
Z_3BD4:
	cp 0x18	; 3BD4 FE 18
Z_3BD6:
	jp c,Z_3BD9	; 3BD6 38 01
Z_3BD8:
	xor a	; 3BD8 AF
Z_3BD9:
	ld (TEXT_ROW),a	; 3BD9 32 02 41
Z_3BDC:
	ret	; 3BDC C9
Z_3BDD:
	ld (TEXT_COL),a	; 3BDD 32 03 41
Z_3BE0:
	ret	; 3BE0 C9
Z_3BE1:
	ld a,(TEXT_COL)	; 3BE1 3A 03 41
Z_3BE4:
	or a	; 3BE4 B7
Z_3BE5:
	jp nz,Z_3BF8	; 3BE5 20 11
Z_3BE7:
	ld a,(D_341D)	; 3BE7 3A 1D 34
Z_3BEA:
	dec a	; 3BEA 3D
Z_3BEB:
	ld (TEXT_COL),a	; 3BEB 32 03 41
Z_3BEE:
	ld a,(TEXT_ROW)	; 3BEE 3A 02 41
Z_3BF1:
	or a	; 3BF1 B7
Z_3BF2:
	jp nz,Z_3BFB	; 3BF2 20 07
Z_3BF4:
	ld a,0x17	; 3BF4 3E 17
Z_3BF6:
	jp Z_3BD9	; 3BF6 18 E1
Z_3BF8:
	dec a	; 3BF8 3D
Z_3BF9:
	jp Z_3BDD	; 3BF9 18 E2
Z_3BFB:
	dec a	; 3BFB 3D
Z_3BFC:
	jp Z_3BD9	; 3BFC 18 DB
Z_3BFE:
	ld a,(TEXT_COL)	; 3BFE 3A 03 41
Z_3C01:
	or a	; 3C01 B7
Z_3C02:
	ret z	; 3C02 C8
Z_3C03:
	ld b,a	; 3C03 47
Z_3C04:
	ld a,(D_341B)	; 3C04 3A 1B 34
Z_3C07:
	ld c,a	; 3C07 4F
Z_3C08:
	cp b	; 3C08 B8
Z_3C09:
	jp nc,Z_3BDD	; 3C09 30 D2
Z_3C0B:
	add a,c	; 3C0B 81
Z_3C0C:
	ld hl,D_341D	; 3C0C 21 1D 34
Z_3C0F:
	cp (hl)	; 3C0F BE
Z_3C10:
	jp c,Z_3C08	; 3C10 38 F6
Z_3C12:
	jp Z_3BCC	; 3C12 18 B8
Z_3C14:
	call Z_3BE1	; 3C14 CD E1 3B
Z_3C17:
	ld a,0x20	; 3C17 3E 20
Z_3C19:
	call Z_3B53	; 3C19 CD 53 3B
Z_3C1C:
	jp Z_3BE1	; 3C1C 18 C3
Z_84D0:
	jp Z_84E8	; 84D0 C3 E8 84
Z_84D3:
	jp Z_8C60	; 84D3 C3 60 8C
Z_84D6:
	jp Z_8ADD	; 84D6 C3 DD 8A
Z_84D9:
	jp Z_90EF	; 84D9 C3 EF 90
Z_84DC:
	jp Z_8C16	; 84DC C3 16 8C
Z_84DF:
	jp Z_870E	; 84DF C3 0E 87
Z_84E2:
	jp Z_8F76	; 84E2 C3 76 8F
Z_84E5:
	jp Z_8E5A	; 84E5 C3 5A 8E
Z_84E8:
	call Z_A0A1	; 84E8 CD A1 A0
Z_84EB:
	ld a,0xC9	; 84EB 3E C9
Z_84ED:
	ld (Z_3732),a	; 84ED 32 32 37
Z_84F0:
	call Z_35C0	; 84F0 CD C0 35
Z_84F3:
	ld a,0xCD	; 84F3 3E CD
Z_84F5:
	ld (Z_3732),a	; 84F5 32 32 37
Z_84F8:
	ld hl,0x7EAF	; 84F8 21 AF 7E
Z_84FB:
	ld (BLIT_Y),hl	; 84FB 22 00 33
Z_84FE:
	xor a	; 84FE AF
Z_84FF:
	ld (D_AA82),a	; 84FF 32 82 AA
Z_8502:
	jp Z_8515	; 8502 C3 15 85
Z_8505:
	nop	; 8505 00
Z_8506:
	nop	; 8506 00
Z_8507:
	nop	; 8507 00
Z_8508:
	ld hl,0x7EAF	; 8508 21 AF 7E
Z_850B:
	ld (BLIT_Y),hl	; 850B 22 00 33
Z_850E:
	xor a	; 850E AF
Z_850F:
	ld (D_AA82),a	; 850F 32 82 AA
Z_8512:
	call Z_AA7C	; 8512 CD 7C AA
Z_8515:
	call Z_A095	; 8515 CD 95 A0
Z_8518:
	ld hl,0x7F49	; 8518 21 49 7F
Z_851B:
	ld (BLIT_Y),hl	; 851B 22 00 33
Z_851E:
	call Z_AA7C	; 851E CD 7C AA
Z_8521:
	ld a,(D_AC4F)	; 8521 3A 4F AC
Z_8524:
	ld (Z_8679+1),a	; 8524 32 7A 86
Z_8527:
	call Z_92A7	; 8527 CD A7 92
Z_852A:
	jp Z_8547	; 852A 18 1B
Z_852C:
	xor a	; 852C AF
Z_852D:
	ld (D_93D8),a	; 852D 32 D8 93
Z_8530:
	call Z_A098	; 8530 CD 98 A0
Z_8533:
	call Z_92AA	; 8533 CD AA 92
Z_8536:
	jp Z_8547	; 8536 18 0F
Z_8538:
	call Z_91B5	; 8538 CD B5 91
Z_853B:
	call 0x01F2	; 853B CD F2 01
Z_853E:
	call Z_9385	; 853E CD 85 93
Z_8541:
	call Z_93A6	; 8541 CD A6 93
Z_8544:
	call Z_A08C	; 8544 CD 8C A0
Z_8547:
	ld a,(D_93D6)	; 8547 3A D6 93
Z_854A:
	and a	; 854A A7
Z_854B:
	call z,Z_937C	; 854B CC 7C 93
Z_854E:
	call Z_A09B	; 854E CD 9B A0
Z_8551:
	call Z_869C	; 8551 CD 9C 86
Z_8554:
	call Z_A193	; 8554 CD 93 A1
Z_8557:
	call Z_A092	; 8557 CD 92 A0
Z_855A:
	call Z_8A23	; 855A CD 23 8A
Z_855D:
	ld a,(D_93EB)	; 855D 3A EB 93
Z_8560:
	push af	; 8560 CB AF
	and 0xDF
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_8562:
	ld (D_93EB),a	; 8562 32 EB 93
Z_8565:
	call Z_9382	; 8565 CD 82 93
Z_8568:
	ld (il_tmp),hl	; 8568 DD 21 0B 94
	ld hl,D_940B
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_856C:
	ld (il_tmp),hl	; 856C FD 21 25 94
	ld hl,D_9425
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_8570:
	call Z_93BB	; 8570 CD BB 93
Z_8573:
	ld (il_tmp),hl	; 8573 DD 21 25 94
	ld hl,D_9425
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_8577:
	ld (il_tmp),hl	; 8577 FD 21 0B 94
	ld hl,D_940B
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_857B:
	call Z_93BB	; 857B CD BB 93
Z_857E:
	call Z_A09E	; 857E CD 9E A0
Z_8581:
	call Z_9385	; 8581 CD 85 93
Z_8584:
	call Z_9379	; 8584 CD 79 93
Z_8587:
	call 0x01EF	; 8587 CD EF 01
Z_858A:
	call Z_8676	; 858A CD 76 86
Z_858D:
	call Z_8685	; 858D CD 85 86
Z_8590:
	jp z,Z_8508	; 8590 CA 08 85
Z_8593:
	ld a,(D_93E5)	; 8593 3A E5 93
Z_8596:
	and a	; 8596 A7
Z_8597:
	jp nz,Z_8657	; 8597 C2 57 86
Z_859A:
	ld a,(D_9400)	; 859A 3A 00 94
Z_859D:
	and a	; 859D A7
Z_859E:
	jp z,Z_8554	; 859E CA 54 85
Z_85A1:
	call Z_937F	; 85A1 CD 7F 93
Z_85A4:
	ld a,(D_9451)	; 85A4 3A 51 94
Z_85A7:
	and a	; 85A7 A7
Z_85A8:
	jp z,Z_860F	; 85A8 28 65
Z_85AA:
	dec a	; 85AA 3D
Z_85AB:
	ld (D_9451),a	; 85AB 32 51 94
Z_85AE:
	cp 0x13	; 85AE FE 13
Z_85B0:
	jp nz,Z_8554	; 85B0 C2 54 85
Z_85B3:
	ld a,0x91	; 85B3 3E 91
Z_85B5:
	ld (D_3424),a	; 85B5 32 24 34
Z_85B8:
	ld hl,0x0114	; 85B8 21 14 01
Z_85BB:
	ld a,(D_9400)	; 85BB 3A 00 94
Z_85BE:
	ld (D_3314),a	; 85BE 32 14 33
Z_85C1:
	ld b,a	; 85C1 47
Z_85C2:
	and 0x80	; 85C2 E6 80
Z_85C4:
	jp nz,Z_85C8	; 85C4 20 02
Z_85C6:
	ld h,0x14	; 85C6 26 14
Z_85C8:
	ld (TEXT_ROW),hl	; 85C8 22 02 41
Z_85CB:
	ld hl,D_946A	; 85CB 21 6A 94
Z_85CE:
	ld a,b	; 85CE 78
Z_85CF:
	and 0x3F	; 85CF E6 3F
Z_85D1:
	ld b,a	; 85D1 47
Z_85D2:
	ld a,(hl)	; 85D2 7E
Z_85D3:
	inc hl	; 85D3 23
Z_85D4:
	inc a	; 85D4 3C
Z_85D5:
	jp nz,Z_85D2	; 85D5 20 FB
Z_85D7:
	dec b	; 85D7 10 F9
	jp nz,Z_85D2
Z_85D9:
	ex de,hl	; 85D9 EB
Z_85DA:
	call Z_939A	; 85DA CD 9A 93
Z_85DD:
	ld a,(D_9400)	; 85DD 3A 00 94
Z_85E0:
	and 0x07	; 85E0 E6 07
Z_85E2:
	ld e,0x06	; 85E2 1E 06
Z_85E4:
	cp 0x04	; 85E4 FE 04
Z_85E6:
	jp z,Z_85ED	; 85E6 28 05
Z_85E8:
	dec e	; 85E8 1D
Z_85E9:
	xor a	; 85E9 AF
Z_85EA:
	ld (D_93D3),a	; 85EA 32 D3 93
Z_85ED:
	ld a,e	; 85ED 7B
Z_85EE:
	ld (D_AA83),a	; 85EE 32 83 AA
Z_85F1:
	ld hl,0x02	; 85F1 21 02 00
Z_85F4:
	ld (BLIT_Y),hl	; 85F4 22 00 33
Z_85F7:
	ld hl,0x807D	; 85F7 21 7D 80
Z_85FA:
	cp 0x05	; 85FA FE 05
Z_85FC:
	jp z,Z_8606	; 85FC 28 08
Z_85FE:
	ld a,0x01	; 85FE 3E 01
Z_8600:
	ld (D_93D8),a	; 8600 32 D8 93
Z_8603:
	ld hl,0x7FBA	; 8603 21 BA 7F
Z_8606:
	ld (BLIT_SRC),hl	; 8606 22 02 33
Z_8609:
	call Z_AA80	; 8609 CD 80 AA
Z_860C:
	jp Z_8554	; 860C C3 54 85
Z_860F:
	ld a,(D_93D3)	; 860F 3A D3 93
Z_8612:
	and a	; 8612 A7
Z_8613:
	jp nz,Z_852C	; 8613 C2 2C 85
Z_8616:
	ld a,(D_93D6)	; 8616 3A D6 93
Z_8619:
	ld e,a	; 8619 5F
Z_861A:
	and 0x07	; 861A E6 07
Z_861C:
	jp z,Z_8538	; 861C CA 38 85
Z_861F:
	dec e	; 861F 1D
Z_8620:
	ld a,e	; 8620 7B
Z_8621:
	ld (D_93D6),a	; 8621 32 D6 93
Z_8624:
	and 0x07	; 8624 E6 07
Z_8626:
	jp z,Z_863E	; 8626 28 16
Z_8628:
	ld a,(D_9400)	; 8628 3A 00 94
Z_862B:
	and 0x07	; 862B E6 07
Z_862D:
	cp 0x04	; 862D FE 04
Z_862F:
	jp nz,Z_863A	; 862F 20 09
Z_8631:
	call Z_9211	; 8631 CD 11 92
Z_8634:
	call Z_93A6	; 8634 CD A6 93
Z_8637:
	jp Z_8554	; 8637 C3 54 85
Z_863A:
	xor a	; 863A AF
Z_863B:
	ld (D_93D6),a	; 863B 32 D6 93
Z_863E:
	ld a,(D_9416)	; 863E 3A 16 94
Z_8641:
	cp 0x05	; 8641 FE 05
Z_8643:
	jp z,Z_864D	; 8643 28 08
Z_8645:
	ld a,(D_9430)	; 8645 3A 30 94
Z_8648:
	cp 0x05	; 8648 FE 05
Z_864A:
	jp nz,Z_8538	; 864A C2 38 85
Z_864D:
	ld a,0x01	; 864D 3E 01
Z_864F:
	ld (D_93D7),a	; 864F 32 D7 93
Z_8652:
	ld a,0xFF	; 8652 3E FF
Z_8654:
	ld (D_93E5),a	; 8654 32 E5 93
Z_8657:
	xor a	; 8657 AF
Z_8658:
	ld (D_93D8),a	; 8658 32 D8 93
Z_865B:
	call Z_A08F	; 865B CD 8F A0
Z_865E:
	call Z_9295	; 865E CD 95 92
Z_8661:
	ld a,(D_93D7)	; 8661 3A D7 93
Z_8664:
	dec a	; 8664 3D
Z_8665:
	ld (D_93D7),a	; 8665 32 D7 93
Z_8668:
	jp z,Z_8508	; 8668 CA 08 85
Z_866B:
	ld a,0x16	; 866B 3E 16
Z_866D:
	ld (D_9415),a	; 866D 32 15 94
Z_8670:
	ld (D_942F),a	; 8670 32 2F 94
Z_8673:
	jp Z_8538	; 8673 C3 38 85
Z_8676:
	ld a,(G_KEY_CODE)	; 8676 3A 0F 41
Z_8679:
	cp 0x06	; 8679 FE 06
Z_867B:
	ret nz	; 867B C0
Z_867C:
	call Z_937F	; 867C CD 7F 93
Z_867F:
	call Z_3A2F	; 867F CD 2F 3A
Z_8682:
	jp 0x064D	; 8682 C3 4D 06
Z_8685:
	ld a,0x30	; 8685 3E 30
Z_8687:
	call 0x0660	; 8687 CD 60 06
Z_868A:
	ret nz	; 868A C0
Z_868B:
	ld a,0x31	; 868B 3E 31
Z_868D:
	call 0x0669	; 868D CD 69 06
Z_8690:
	ret nz	; 8690 C0
Z_8691:
	ld a,0x3A	; 8691 3E 3A
Z_8693:
	jp 0x0669	; 8693 C3 69 06
Z_869C:
	ld hl,0x00	; 869C 21 00 00
Z_869F:
	ld (D_8696),hl	; 869F 22 96 86
Z_86A2:
	ld a,(D_93D2)	; 86A2 3A D2 93
Z_86A5:
	and 0x03	; 86A5 E6 03
Z_86A7:
	sub 0x04	; 86A7 D6 04
Z_86A9:
	cpl	; 86A9 ED 44
	inc a
Z_86AB:
	dec a	; 86AB 3D
Z_86AC:
	ld (Z_88D6+1),a	; 86AC 32 D7 88
Z_86AF:
	call Z_386E	; 86AF CD 6E 38
Z_86B2:
	and 0x03	; 86B2 E6 03
Z_86B4:
	ld c,0x0C	; 86B4 0E 0C
Z_86B6:
	jp z,Z_86C4	; 86B6 28 0C
Z_86B8:
	cp 0x02	; 86B8 FE 02
Z_86BA:
	ld c,0x01	; 86BA 0E 01
Z_86BC:
	jp c,Z_86C4	; 86BC 38 06
Z_86BE:
	ld c,0x04	; 86BE 0E 04
Z_86C0:
	jp z,Z_86C4	; 86C0 28 02
Z_86C2:
	ld c,0x03	; 86C2 0E 03
Z_86C4:
	ld a,c	; 86C4 79
Z_86C5:
	ld (D_8699),a	; 86C5 32 99 86
Z_86C8:
	ld (il_tmp),hl	; 86C8 DD 21 25 94
	ld hl,D_9425
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_86CC:
	ld (il_tmp),hl	; 86CC FD 21 0B 94
	ld hl,D_940B
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_86D0:
	call Z_A160	; 86D0 CD 60 A1
Z_86D3:
	nop	; 86D3 00
Z_86D4:
	push af	; 86D4 F5
Z_86D5:
	ld de,0x46	; 86D5 11 46 00
Z_86D8:
	ld hl,0x66	; 86D8 21 66 00
Z_86DB:
	jp c,Z_86EE	; 86DB 38 11
Z_86DD:
	rst 0x10	; 86DD DD 7E 02
	db 0x02
Z_86E0:
	call il_iy_cp	; 86E0 FD BE 02
	db 0x02
Z_86E3:
	ld hl,0x4E	; 86E3 21 4E 00
Z_86E6:
	jp c,Z_86EE	; 86E6 38 06
Z_86E8:
	ld de,0x5E	; 86E8 11 5E 00
Z_86EB:
	ld hl,0x68	; 86EB 21 68 00
Z_86EE:
	call Z_388A	; 86EE CD 8A 38
Z_86F1:
	ld h,0x14	; 86F1 26 14
Z_86F3:
	push af	; 86F3 CB 85
	ld a,l
	and 0xFE
	ld l,a
	pop af
Z_86F5:
	ld (D_869A),hl	; 86F5 22 9A 86
Z_86F8:
	pop af	; 86F8 F1
Z_86F9:
	ld de,0x18	; 86F9 11 18 00
Z_86FC:
	jp c,Z_8701	; 86FC 38 03
Z_86FE:
	ld de,0x0A	; 86FE 11 0A 00
Z_8701:
	ld hl,0x22	; 8701 21 22 00
Z_8704:
	call Z_388A	; 8704 CD 8A 38
Z_8707:
	push af	; 8707 CB 85
	ld a,l
	and 0xFE
	ld l,a
	pop af
Z_8709:
	ld a,l	; 8709 7D
Z_870A:
	ld (D_869B),a	; 870A 32 9B 86
Z_870D:
	ret	; 870D C9
Z_870E:
	ld (il_tmp),hl	; 870E DD 21 25 94
	ld hl,D_9425
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_8712:
	ld (il_tmp),hl	; 8712 FD 21 0B 94
	ld hl,D_940B
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_8716:
	ld a,(D_93D6)	; 8716 3A D6 93
Z_8719:
	and a	; 8719 A7
Z_871A:
	jp z,Z_872D	; 871A 28 11
Z_871C:
	rst 0x08	; 871C DD CB 00 66
	db 0x00, 0x10
Z_8720:
	jp z,Z_877F	; 8720 28 5D
Z_8722:
	rst 0x08	; 8722 DD CB 00 46
	db 0x00, 0x01
Z_8726:
	jp nz,Z_8776	; 8726 20 4E
Z_8728:
	ld a,0x10	; 8728 3E 10
Z_872A:
	jp Z_88E5	; 872A C3 E5 88
Z_872D:
	ld a,(D_9400)	; 872D 3A 00 94
Z_8730:
	and a	; 8730 A7
Z_8731:
	jp z,Z_8749	; 8731 28 16
Z_8733:
	ld (il_a),a	; 8733 CB 7F
	and 0x80
	ld a,(il_a)
Z_8735:
	ret nz	; 8735 C0
Z_8736:
	and 0x07	; 8736 E6 07
Z_8738:
	cp 0x04	; 8738 FE 04
Z_873A:
	ret nz	; 873A C0
Z_873B:
	ld hl,0x6454	; 873B 21 54 64
Z_873E:
	rst 0x30	; 873E DD CB 01 B6
	db 0x01, 0xBF
Z_8742:
	rst 0x30	; 8742 DD CB 02 86
	db 0x02, 0xFE
Z_8746:
	jp Z_889F	; 8746 C3 9F 88
Z_8749:
	rst 0x08	; 8749 DD CB 00 66
	db 0x00, 0x10
Z_874D:
	jp z,Z_8873	; 874D CA 73 88
Z_8750:
	rst 0x08	; 8750 DD CB 00 46
	db 0x00, 0x01
Z_8754:
	jp z,Z_8783	; 8754 28 2D
Z_8756:
	rst 0x08	; 8756 DD CB 00 6E
	db 0x00, 0x20
Z_875A:
	ld a,(D_8699)	; 875A 3A 99 86
Z_875D:
	jp nz,Z_88E5	; 875D C2 E5 88
Z_8760:
	rst 0x08	; 8760 DD CB 00 5E
	db 0x00, 0x08
Z_8764:
	jp nz,Z_8776	; 8764 20 10
Z_8766:
	rst 0x10	; 8766 DD 7E 03
	db 0x03
Z_8769:
	cp 0x20	; 8769 FE 20
Z_876B:
	jp nc,Z_877F	; 876B 30 12
Z_876D:
	call Z_A169	; 876D CD 69 A1
Z_8770:
	nop	; 8770 00
Z_8771:
	jp nz,Z_88C6	; 8771 C2 C6 88
Z_8774:
	jp Z_877F	; 8774 18 09
Z_8776:
	rst 0x08	; 8776 DD CB 00 4E
	db 0x00, 0x02
Z_877A:
	ld a,0x10	; 877A 3E 10
Z_877C:
	jp nz,Z_88E5	; 877C C2 E5 88
Z_877F:
	xor a	; 877F AF
Z_8780:
	jp Z_88E5	; 8780 C3 E5 88
Z_8783:
	ld a,(D_8697)	; 8783 3A 97 86
Z_8786:
	and a	; 8786 A7
Z_8787:
	jp z,Z_878F	; 8787 28 06
Z_8789:
	dec a	; 8789 3D
Z_878A:
	ld (D_8697),a	; 878A 32 97 86
Z_878D:
	jp nz,Z_87A2	; 878D 20 13
Z_878F:
	rst 0x10	; 878F DD 7E 0A
	db 0x0A
Z_8792:
	cp 0x04	; 8792 FE 04
Z_8794:
	jp nc,Z_87FE	; 8794 30 68
Z_8796:
	ld c,a	; 8796 4F
Z_8797:
	call Z_A172	; 8797 CD 72 A1
Z_879A:
	nop	; 879A 00
Z_879B:
	or 0x03	; 879B F6 03
Z_879D:
	add a,c	; 879D 81
Z_879E:
	rlca	; 879E 07
Z_879F:
	ld (D_8697),a	; 879F 32 97 86
Z_87A2:
	rst 0x10	; 87A2 DD 7E 02
	db 0x02
Z_87A5:
	call il_iy_sub	; 87A5 FD 96 02
	db 0x02
Z_87A8:
	ld e,0x01	; 87A8 1E 01
Z_87AA:
	jp nc,Z_87AF	; 87AA 30 03
Z_87AC:
	dec e	; 87AC 1D
Z_87AD:
	cpl	; 87AD ED 44
	inc a
Z_87AF:
	cp 0x06	; 87AF FE 06
Z_87B1:
	jp nc,Z_877F	; 87B1 30 CC
Z_87B3:
	rst 0x10	; 87B3 DD 7E 03
	db 0x03
Z_87B6:
	add a,0x02	; 87B6 C6 02
Z_87B8:
	call il_iy_sub	; 87B8 FD 96 03
	db 0x03
Z_87BB:
	ld d,0x01	; 87BB 16 01
Z_87BD:
	jp nc,Z_87C2	; 87BD 30 03
Z_87BF:
	dec d	; 87BF 15
Z_87C0:
	cpl	; 87C0 ED 44
	inc a
Z_87C2:
	cp 0x0E	; 87C2 FE 0E
Z_87C4:
	jp nc,Z_877F	; 87C4 30 B9
Z_87C6:
	cp 0x06	; 87C6 FE 06
Z_87C8:
	jp c,Z_87E3	; 87C8 38 19
Z_87CA:
	ld a,d	; 87CA 7A
Z_87CB:
	and a	; 87CB A7
Z_87CC:
	rst 0x10	; 87CC DD 7E FF
	db 0xFF
Z_87CF:
	jp z,Z_87DA	; 87CF 28 09
Z_87D1:
	xor 0x0C	; 87D1 EE 0C
Z_87D3:
	jp z,Z_877F	; 87D3 28 AA
Z_87D5:
	ld a,0x1C	; 87D5 3E 1C
Z_87D7:
	jp Z_88C6	; 87D7 C3 C6 88
Z_87DA:
	xor 0x04	; 87DA EE 04
Z_87DC:
	jp z,Z_877F	; 87DC 28 A1
Z_87DE:
	ld a,0x14	; 87DE 3E 14
Z_87E0:
	jp Z_88C6	; 87E0 C3 C6 88
Z_87E3:
	ld a,e	; 87E3 7B
Z_87E4:
	and a	; 87E4 A7
Z_87E5:
	rst 0x10	; 87E5 DD 7E FF
	db 0xFF
Z_87E8:
	jp z,Z_87F4	; 87E8 28 0A
Z_87EA:
	xor 0x03	; 87EA EE 03
Z_87EC:
	jp z,Z_877F	; 87EC CA 7F 87
Z_87EF:
	ld a,0x13	; 87EF 3E 13
Z_87F1:
	jp Z_88C6	; 87F1 C3 C6 88
Z_87F4:
	xor 0x01	; 87F4 EE 01
Z_87F6:
	jp z,Z_877F	; 87F6 CA 7F 87
Z_87F9:
	ld a,0x11	; 87F9 3E 11
Z_87FB:
	jp Z_88C6	; 87FB C3 C6 88
Z_87FE:
	rst 0x10	; 87FE DD 7E FF
	db 0xFF
Z_8801:
	and 0x0C	; 8801 E6 0C
Z_8803:
	cp 0x04	; 8803 FE 04
Z_8805:
	jp z,Z_8813	; 8805 28 0C
Z_8807:
	ld a,(D_8696)	; 8807 3A 96 86
Z_880A:
	ld (il_a),a	; 880A CB 5F
	and 0x08
	ld a,(il_a)
Z_880C:
	jp nz,Z_8813	; 880C 20 05
Z_880E:
	ld a,0x14	; 880E 3E 14
Z_8810:
	jp Z_88C6	; 8810 C3 C6 88
Z_8813:
	ld hl,0x0754	; 8813 21 54 07
Z_8816:
	rst 0x10	; 8816 DD 7E 02
	db 0x02
Z_8819:
	cp l	; 8819 BD
Z_881A:
	jp nz,Z_8825	; 881A 20 09
Z_881C:
	rst 0x10	; 881C DD 7E 03
	db 0x03
Z_881F:
	cp h	; 881F BC
Z_8820:
	ld a,0x10	; 8820 3E 10
Z_8822:
	jp z,Z_88E5	; 8822 CA E5 88
Z_8825:
	ld a,(Z_88D6+1)	; 8825 3A D7 88
Z_8828:
	inc a	; 8828 3C
Z_8829:
	cpl	; 8829 ED 44
	inc a
Z_882B:
	call il_iy_add	; 882B FD 86 03
	db 0x03
Z_882E:
	cp 0x0E	; 882E FE 0E
Z_8830:
	jp nc,Z_8844	; 8830 30 12
Z_8832:
	cp 0x04	; 8832 FE 04
Z_8834:
	jp c,Z_8844	; 8834 38 0E
Z_8836:
	call il_iy_lda	; 8836 FD 7E 02
	db 0x02
Z_8839:
	cp 0x51	; 8839 FE 51
Z_883B:
	jp c,Z_8844	; 883B 38 07
Z_883D:
	cp 0x58	; 883D FE 58
Z_883F:
	jp nc,Z_8844	; 883F 30 03
Z_8841:
	ld hl,(D_869A)	; 8841 2A 9A 86
Z_8844:
	ld a,(Z_88D6+1)	; 8844 3A D7 88
Z_8847:
	ld c,a	; 8847 4F
Z_8848:
	ld b,a	; 8848 47
Z_8849:
	inc c	; 8849 0C
Z_884A:
	cp 0x03	; 884A FE 03
Z_884C:
	jp c,Z_884F	; 884C 38 01
Z_884E:
	inc c	; 884E 0C
Z_884F:
	call il_ix_add	; 884F DD 86 02
	db 0x02
Z_8852:
	sub l	; 8852 95
Z_8853:
	jp c,Z_8869	; 8853 38 14
Z_8855:
	cp c	; 8855 B9
Z_8856:
	jp nc,Z_8869	; 8856 30 11
Z_8858:
	rst 0x10	; 8858 DD 7E 03
	db 0x03
Z_885B:
	add a,b	; 885B 80
Z_885C:
	sub h	; 885C 94
Z_885D:
	jp c,Z_8869	; 885D 38 0A
Z_885F:
	cp c	; 885F B9
Z_8860:
	jp nc,Z_8869	; 8860 30 07
Z_8862:
	call Z_86D0	; 8862 CD D0 86
Z_8865:
	ld a,0x10	; 8865 3E 10
Z_8867:
	jp Z_88E5	; 8867 18 7C
Z_8869:
	call Z_88F4	; 8869 CD F4 88
Z_886C:
	and a	; 886C A7
Z_886D:
	jp nz,Z_88C6	; 886D 20 57
Z_886F:
	ld a,0x10	; 886F 3E 10
	jp	Z_8871	; мост в следующий кусок
	org	0x9321
Z_963F:
	jp z,Z_9642	; 963F 28 01
Z_9641:
	inc a	; 9641 3C
Z_9642:
	rst 0x08	; 9642 DD CB 00 66
	db 0x00, 0x10
Z_9646:
	call nz,Z_96BC	; 9646 C4 BC 96
Z_9649:
	ld (BLIT_Y),hl	; 9649 22 00 33
Z_964C:
	call Z_9E6F	; 964C CD 6F 9E
Z_964F:
	jp Z_B01C	; 964F C3 1C B0
Z_9652:
	call il_ix_ldl	; 9652 DD 6E 02
	db 0x02
Z_9655:
	call il_ix_ldh	; 9655 DD 66 03
	db 0x03
Z_9658:
	ld a,l	; 9658 7D
Z_9659:
	sub 0x1C	; 9659 D6 1C
Z_965B:
	ld l,a	; 965B 6F
Z_965C:
	rst 0x08	; 965C DD CB 00 66
	db 0x00, 0x10
Z_9660:
	rst 0x10	; 9660 DD 7E 07
	db 0x07
	jp	Z_9663	; мост в следующий кусок
	org	0x9348
D_9348:
Z_9348:
	db	0x54, 0x49, 0x4D, 0x45, 0xFF, 0xC3, 0x35, 0x9F, 0xC3, 0x11, 0x95, 0xC3, 0x7E, 0x94, 0xC3, 0xE9	; 9348
	org	0x9358
D_9358:
Z_9358:
	db	0x99, 0xC3, 0xA7, 0x98, 0xC3, 0x18, 0x99, 0xC3, 0x8A, 0x99, 0xC3, 0x3D, 0x9E, 0xC3, 0xEA, 0x9F	; 9358
	org	0x9368
D_9368:
Z_9368:
	db	0xC3, 0xED, 0x9F, 0xC3, 0xF3, 0x9E, 0xC3, 0x50, 0x9E, 0xC3, 0xA2, 0x9E, 0xC3, 0xD9	; 9368
	org	0x9376
Z_9663:
	jp z,Z_9667	; 9663 28 02
Z_9665:
	add a,0x03	; 9665 C6 03
Z_9667:
	rst 0x08	; 9667 DD CB FF 56
	db 0xFF, 0x04
Z_966B:
	jp nz,Z_9677	; 966B 20 0A
Z_966D:
	add a,0x18	; 966D C6 18
Z_966F:
	rst 0x08	; 966F DD CB FF 4E
	db 0xFF, 0x02
Z_9673:
	jp z,Z_967D	; 9673 28 08
Z_9675:
	jp Z_967F	; 9675 18 08
Z_9677:
	rst 0x08	; 9677 DD CB FF 5E
	db 0xFF, 0x08
Z_967B:
	jp z,Z_967F	; 967B 28 02
Z_967D:
	add a,0x0C	; 967D C6 0C
Z_967F:
	ld (BLIT_Y),hl	; 967F 22 00 33
Z_9682:
	ld (il_tmp),hl	; 9682 DD E5
	ld hl,(z80_ix)
	push hl
	ld hl,(il_tmp)
Z_9684:
	push af	; 9684 F5
Z_9685:
	call Z_9E6F	; 9685 CD 6F 9E
Z_9688:
	call Z_B01C	; 9688 CD 1C B0
Z_968B:
	pop de	; 968B D1
Z_968C:
	ld (il_tmp),hl	; 968C DD E1
	pop hl
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_968E:
	ld hl,D_94A7	; 968E 21 A7 94
Z_9691:
	ld a,(hl)	; 9691 7E
Z_9692:
	inc hl	; 9692 23
Z_9693:
	and a	; 9693 A7
Z_9694:
	ret z	; 9694 C8
Z_9695:
	cp d	; 9695 BA
Z_9696:
	jp nz,Z_9691	; 9696 20 F9
Z_9698:
	ld a,(D_93EB)	; 9698 3A EB 93
	jp	Z_969B	; мост в следующий кусок
	org	0x93CA
D_93CA:
Z_93CA:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 93CA
	org	0x93D1
D_93D1:
Z_93D1:
	db	0x00	; 93D1
	org	0x93D2
D_93D2:
Z_93D2:
	db	0x00	; 93D2
	org	0x93D3
D_93D3:
Z_93D3:
	db	0x00, 0x00, 0x00	; 93D3
	org	0x93D6
D_93D6:
Z_93D6:
	db	0x00	; 93D6
	org	0x93D7
D_93D7:
Z_93D7:
	db	0x00	; 93D7
	org	0x93D8
D_93D8:
Z_93D8:
	db	0x00	; 93D8
	org	0x93D9
D_93D9:
Z_93D9:
	db	0x00	; 93D9
	org	0x93DA
D_93DA:
Z_93DA:
	db	0x00, 0x00	; 93DA
	org	0x93DC
D_93DC:
Z_93DC:
	db	0x3F, 0x40, 0x41, 0xFF	; 93DC
	org	0x93E0
D_93E0:
Z_93E0:
	db	0x00, 0x00, 0x35, 0x30, 0x30	; 93E0
	org	0x93E5
D_93E5:
Z_93E5:
	db	0x00	; 93E5
	org	0x93E6
D_93E6:
Z_93E6:
	db	0x00	; 93E6
	org	0x93E7
D_93E7:
Z_93E7:
	db	0x00, 0x00	; 93E7
	org	0x93E9
D_93E9:
Z_93E9:
	db	0x00	; 93E9
	org	0x93EA
D_93EA:
Z_93EA:
	db	0x00	; 93EA
	org	0x93EB
D_93EB:
Z_93EB:
	db	0x00	; 93EB
	org	0x93EC
D_93EC:
Z_93EC:
	db	0x00	; 93EC
	org	0x93ED
D_93ED:
Z_93ED:
	db	0x00, 0x00	; 93ED
	org	0x93EF
D_93EF:
Z_93EF:
	db	0x00	; 93EF
	org	0x93F0
D_93F0:
Z_93F0:
	db	0x00	; 93F0
	org	0x93F1
D_93F1:
Z_93F1:
	db	0x00, 0x00	; 93F1
	org	0x93F3
D_93F3:
Z_93F3:
	db	0x00	; 93F3
	org	0x93F4
D_93F4:
Z_93F4:
	db	0x00	; 93F4
	org	0x93F5
D_93F5:
Z_93F5:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 93F5
	org	0x9400
D_9400:
Z_9400:
	db	0x00	; 9400
	org	0x9401
D_9401:
Z_9401:
	db	0x00	; 9401
	org	0x9402
D_9402:
Z_9402:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 9402
	org	0x9408
D_9408:
Z_9408:
	db	0x00	; 9408
	org	0x9409
D_9409:
Z_9409:
	db	0x00	; 9409
	org	0x940A
D_940A:
Z_940A:
	db	0x00	; 940A
	org	0x940B
D_940B:
Z_940B:
	db	0x00	; 940B
	org	0x940C
D_940C:
Z_940C:
	db	0x00	; 940C
	org	0x940D
D_940D:
Z_940D:
	db	0x00	; 940D
	org	0x940E
D_940E:
Z_940E:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 940E
	org	0x9415
D_9415:
Z_9415:
	db	0x00	; 9415
	org	0x9416
D_9416:
Z_9416:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 9416
	org	0x9422
D_9422:
Z_9422:
	db	0x00	; 9422
	org	0x9423
D_9423:
Z_9423:
	db	0x00	; 9423
	org	0x9424
D_9424:
Z_9424:
	db	0x00	; 9424
	org	0x9425
D_9425:
Z_9425:
	db	0x00	; 9425
	org	0x9426
D_9426:
Z_9426:
	db	0x00	; 9426
	org	0x9427
D_9427:
Z_9427:
	db	0x00	; 9427
	org	0x9428
D_9428:
Z_9428:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 9428
	org	0x942F
D_942F:
Z_942F:
	db	0x00	; 942F
	org	0x9430
D_9430:
Z_9430:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 9430
	org	0x943A
D_943A:
Z_943A:
	db	0x05, 0x04, 0x03, 0x02, 0x01, 0x06, 0x07, 0x08	; 943A
	org	0x9442
D_9442:
Z_9442:
	db	0x00, 0x01, 0x02, 0x01	; 9442
	org	0x9446
D_9446:
Z_9446:
	db	0x01, 0x03, 0x01, 0x04	; 9446
	org	0x944A
D_944A:
Z_944A:
	db	0xDD, 0xDB, 0xDD	; 944A
	org	0x944D
D_944D:
Z_944D:
	db	0x00	; 944D
	org	0x944E
D_944E:
Z_944E:
	db	0x00	; 944E
	org	0x944F
D_944F:
Z_944F:
	db	0x00	; 944F
	org	0x9450
D_9450:
Z_9450:
	db	0x00	; 9450
	org	0x9451
D_9451:
Z_9451:
	db	0x00	; 9451
	org	0x9452
D_9452:
Z_9452:
	db	0x20	; 9452
	org	0x9453
D_9453:
Z_9453:
	db	0x50, 0x4C, 0x41, 0x59, 0x45, 0x52, 0x20, 0x31, 0x20, 0x20, 0xFF, 0x20	; 9453
	org	0x945F
D_945F:
Z_945F:
	db	0x4D, 0x41, 0x52, 0x54, 0x49, 0x4E, 0x20, 0x46, 0x2E, 0x20, 0xFF	; 945F
	org	0x946A
D_946A:
Z_946A:
	db	0xFF, 0x20, 0x20, 0x44, 0x4F, 0x55, 0x42, 0x4C, 0x45, 0x20, 0x20, 0x20, 0xFF, 0x20, 0x20, 0x20	; 946A
	org	0x947A
D_947A:
Z_947A:
	db	0x46, 0x4F, 0x55, 0x4C, 0x20, 0x20, 0x20, 0x20, 0xFF, 0x20, 0x20, 0x2A, 0x20, 0x4F, 0x55, 0x54	; 947A
	org	0x948A
D_948A:
Z_948A:
	db	0x20, 0x2A, 0x20, 0x20, 0xFF, 0x20, 0x42, 0x41, 0x53, 0x4B, 0x45, 0x54, 0x20, 0x21, 0x20, 0x20	; 948A
	org	0x949A
D_949A:
Z_949A:
	db	0xFF, 0x42, 0x41, 0x43, 0x4B, 0x20, 0x43, 0x4F, 0x55, 0x52, 0x54, 0x20, 0xFF	; 949A
	org	0x94A7
D_94A7:
Z_94A7:
	db	0x03, 0x06, 0x0F, 0x12, 0x1B, 0x1E, 0x27, 0x2A, 0x00	; 94A7
	org	0x94B0
Z_969B:
	push af	; 969B CB F7
	or 0x40
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_969D:
	ld (D_93EB),a	; 969D 32 EB 93
Z_96A0:
	rst 0x00	; 96A0 DD 36 FA 03
	db 0xFA, 0x03
Z_96A4:
	ld a,(D_93D8)	; 96A4 3A D8 93
Z_96A7:
	and a	; 96A7 A7
Z_96A8:
	ret nz	; 96A8 C0
Z_96A9:
	inc a	; 96A9 3C
Z_96AA:
	ld (D_AA83),a	; 96AA 32 83 AA
Z_96AD:
	ld hl,0x02	; 96AD 21 02 00
Z_96B0:
	ld (BLIT_Y),hl	; 96B0 22 00 33
Z_96B3:
	ld hl,0x8070	; 96B3 21 70 80
Z_96B6:
	ld (BLIT_SRC),hl	; 96B6 22 02 33
Z_96B9:
	jp Z_AA80	; 96B9 C3 80 AA
Z_96BC:
	rst 0x08	; 96BC DD CB 00 56
	db 0x00, 0x04
Z_96C0:
	ret nz	; 96C0 C0
Z_96C1:
	ld c,a	; 96C1 4F
Z_96C2:
	rst 0x10	; 96C2 DD 7E 03
	db 0x03
Z_96C5:
	call il_iy_sub	; 96C5 FD 96 03
	db 0x03
Z_96C8:
	ld b,0x0A	; 96C8 06 0A
Z_96CA:
	ld e,0x00	; 96CA 1E 00
Z_96CC:
	jp nc,Z_96D3	; 96CC 30 05
Z_96CE:
	ld b,0x16	; 96CE 06 16
Z_96D0:
	inc e	; 96D0 1C
Z_96D1:
	cpl	; 96D1 ED 44
	inc a
Z_96D3:
	cp 0x06	; 96D3 FE 06
Z_96D5:
	jp nc,Z_9703	; 96D5 30 2C
Z_96D7:
	rst 0x10	; 96D7 DD 7E 02
	db 0x02
Z_96DA:
	call il_iy_sub	; 96DA FD 96 02
	db 0x02
Z_96DD:
	jp nc,Z_96E1	; 96DD 30 02
Z_96DF:
	cpl	; 96DF ED 44
	inc a
Z_96E1:
	cp 0x0A	; 96E1 FE 0A
Z_96E3:
	jp nc,Z_9703	; 96E3 30 1E
Z_96E5:
	rst 0x08	; 96E5 DD CB 01 46
	db 0x01, 0x01
Z_96E9:
	jp z,Z_96EC	; 96E9 28 01
Z_96EB:
	inc b	; 96EB 04
Z_96EC:
	ld a,b	; 96EC 78
Z_96ED:
	cp c	; 96ED B9
Z_96EE:
	ret z	; 96EE C8
Z_96EF:
	rst 0x08	; 96EF DD CB FF 56
	db 0xFF, 0x04
Z_96F3:
	jp z,Z_96F6	; 96F3 28 01
Z_96F5:
	ret	; 96F5 C9
Z_96F6:
	rst 0x08	; 96F6 DD CB FF 4E
	db 0xFF, 0x02
Z_96FA:
	jp z,Z_9703	; 96FA 28 07
Z_96FC:
	rst 0x08	; 96FC DD CB 01 46
	db 0x01, 0x01
Z_9700:
	ret z	; 9700 C8
Z_9701:
	dec l	; 9701 2D
Z_9702:
	ret	; 9702 C9
Z_9703:
	ld a,c	; 9703 79
Z_9704:
	ret	; 9704 C9
Z_9705:
	rst 0x08	; 9705 DD CB FF 56
	db 0xFF, 0x04
Z_9709:
	jp nz,Z_974C	; 9709 20 41
Z_970B:
	rst 0x08	; 970B DD CB FF 4E
	db 0xFF, 0x02
Z_970F:
	jp nz,Z_974C	; 970F 20 3B
Z_9711:
	ld (il_tmp),hl	; 9711 DD E5
	ld hl,(z80_ix)
	push hl
	ld hl,(il_tmp)
Z_9713:
	call Z_9753	; 9713 CD 53 97
Z_9716:
	ld (il_tmp),hl	; 9716 DD E1
	pop hl
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_9718:
	call il_ix_ldl	; 9718 DD 6E 04
	db 0x04
Z_971B:
	call il_ix_ldh	; 971B DD 66 05
	db 0x05
Z_971E:
	ld a,l	; 971E 7D
Z_971F:
	sub 0x25	; 971F D6 25
Z_9721:
	ld l,a	; 9721 6F
Z_9722:
	ld a,0x0A	; 9722 3E 0A
Z_9724:
	rst 0x08	; 9724 DD CB FF 56
	db 0xFF, 0x04
Z_9728:
	jp z,Z_9732	; 9728 28 08
Z_972A:
	rst 0x08	; 972A DD CB FF 5E
	db 0xFF, 0x08
Z_972E:
	jp z,Z_973C	; 972E 28 0C
Z_9730:
	jp Z_973A	; 9730 18 08
Z_9732:
	add a,0x18	; 9732 C6 18
Z_9734:
	rst 0x08	; 9734 DD CB FF 4E
	db 0xFF, 0x02
Z_9738:
	jp nz,Z_973C	; 9738 20 02
Z_973A:
	add a,0x0C	; 973A C6 0C
Z_973C:
	rst 0x08	; 973C DD CB 01 46
	db 0x01, 0x01
Z_9740:
	jp z,Z_9743	; 9740 28 01
Z_9742:
	inc a	; 9742 3C
Z_9743:
	ld (BLIT_Y),hl	; 9743 22 00 33
Z_9746:
	call Z_9E6F	; 9746 CD 6F 9E
Z_9749:
	jp Z_B01C	; 9749 C3 1C B0
Z_974C:
	ld (il_tmp),hl	; 974C DD E5
	ld hl,(z80_ix)
	push hl
	ld hl,(il_tmp)
Z_974E:
	call Z_9718	; 974E CD 18 97
Z_9751:
	ld (il_tmp),hl	; 9751 DD E1
	pop hl
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_9753:
	call il_ix_ldl	; 9753 DD 6E 04
	db 0x04
Z_9756:
	call il_ix_ldh	; 9756 DD 66 05
	db 0x05
Z_9759:
	ld a,l	; 9759 7D
Z_975A:
	sub 0x24	; 975A D6 24
Z_975C:
	ld l,a	; 975C 6F
Z_975D:
	rst 0x08	; 975D DD CB 00 66
	db 0x00, 0x10
Z_9761:
	ld a,0x09	; 9761 3E 09
Z_9763:
	jp z,Z_9766	; 9763 28 01
Z_9765:
	dec a	; 9765 3D
Z_9766:
	rst 0x08	; 9766 DD CB FF 56
	db 0xFF, 0x04
Z_976A:
	jp z,Z_9777	; 976A 28 0B
Z_976C:
	rst 0x08	; 976C DD CB FF 5E
	db 0xFF, 0x08
Z_9770:
	jp z,Z_9781	; 9770 28 0F
Z_9772:
	add a,0x0C	; 9772 C6 0C
Z_9774:
	inc h	; 9774 24
Z_9775:
	jp Z_9781	; 9775 18 0A
Z_9777:
	add a,0x24	; 9777 C6 24
Z_9779:
	rst 0x08	; 9779 DD CB FF 4E
	db 0xFF, 0x02
Z_977D:
	jp z,Z_9781	; 977D 28 02
Z_977F:
	sub 0x0C	; 977F D6 0C
Z_9781:
	ld (BLIT_Y),hl	; 9781 22 00 33
Z_9784:
	call Z_9E6F	; 9784 CD 6F 9E
Z_9787:
	jp Z_B01C	; 9787 C3 1C B0
Z_978A:
	call il_ix_ldl	; 978A DD 6E 04
	db 0x04
Z_978D:
	call il_ix_ldh	; 978D DD 66 05
	db 0x05
Z_9790:
	ld a,l	; 9790 7D
Z_9791:
	sub 0x24	; 9791 D6 24
Z_9793:
	ld l,a	; 9793 6F
Z_9794:
	rst 0x08	; 9794 DD CB 01 46
	db 0x01, 0x01
Z_9798:
	jp z,Z_979C	; 9798 28 02
Z_979A:
	dec h	; 979A 25
Z_979B:
	dec h	; 979B 25
Z_979C:
	ld (BLIT_Y),hl	; 979C 22 00 33
Z_979F:
	rst 0x10	; 979F DD 7E 07
	db 0x07
Z_97A2:
	add a,0x36	; 97A2 C6 36
Z_97A4:
	rst 0x08	; 97A4 DD CB FF 4E
	db 0xFF, 0x02
Z_97A8:
	jp nz,Z_97AC	; 97A8 20 02
Z_97AA:
	inc a	; 97AA 3C
Z_97AB:
	inc a	; 97AB 3C
Z_97AC:
	rst 0x08	; 97AC DD CB 01 46
	db 0x01, 0x01
Z_97B0:
	jp z,Z_97B4	; 97B0 28 02
Z_97B2:
	add a,0x04	; 97B2 C6 04
Z_97B4:
	call Z_9E6F	; 97B4 CD 6F 9E
Z_97B7:
	ld (il_tmp),hl	; 97B7 DD E5
	ld hl,(z80_ix)
	push hl
	ld hl,(il_tmp)
Z_97B9:
	call Z_B01C	; 97B9 CD 1C B0
Z_97BC:
	ld (il_tmp),hl	; 97BC DD E1
	pop hl
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_97BE:
	rst 0x10	; 97BE DD 7E 07
	db 0x07
Z_97C1:
	inc a	; 97C1 3C
Z_97C2:
	and 0x01	; 97C2 E6 01
Z_97C4:
	ret z	; 97C4 C8
Z_97C5:
	rst 0x20	; 97C5 DD 77 07
	db 0x07
Z_97C8:
	jp Z_84D9	; 97C8 C3 D9 84
Z_97CB:
	cp 0x22	; 97CB FE 22
Z_97CD:
	jp nc,Z_9705	; 97CD D2 05 97
Z_97D0:
	call Z_97D6	; 97D0 CD D6 97
Z_97D3:
	jp Z_9705	; 97D3 C3 05 97
Z_97D6:
	xor a	; 97D6 AF
Z_97D7:
	rst 0x08	; 97D7 DD CB 01 46
	db 0x01, 0x01
Z_97DB:
	jp z,Z_97DF	; 97DB 28 02
Z_97DD:
	push af	; 97DD CB FF
	or 0x80
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_97DF:
	ld (D_93EB),a	; 97DF 32 EB 93
Z_97E2:
	ld a,(D_9400)	; 97E2 3A 00 94
Z_97E5:
	and a	; 97E5 A7
Z_97E6:
	ld a,0x00	; 97E6 3E 00
Z_97E8:
	jp nz,Z_97EF	; 97E8 20 05
Z_97EA:
	call il_ix_inc	; 97EA DD 34 0C
	db 0x0C
Z_97ED:
	ld a,0x02	; 97ED 3E 02
Z_97EF:
	ld (D_93D9),a	; 97EF 32 D9 93
Z_97F2:
	jp Z_84DC	; 97F2 C3 DC 84
Z_97F5:
	rst 0x10	; 97F5 DD 7E 04
	db 0x04
Z_97F8:
	call il_ix_ldh	; 97F8 DD 66 05
	db 0x05
Z_97FB:
	dec h	; 97FB 25
Z_97FC:
	sub 0x24	; 97FC D6 24
Z_97FE:
	ld l,a	; 97FE 6F
Z_97FF:
	ld (BLIT_Y),hl	; 97FF 22 00 33
Z_9802:
	ld c,0x02	; 9802 0E 02
Z_9804:
	rst 0x08	; 9804 DD CB 00 76
	db 0x00, 0x40
Z_9808:
	jp nz,Z_980B	; 9808 20 01
Z_980A:
	dec c	; 980A 0D
Z_980B:
	rst 0x08	; 980B DD CB 00 4E
	db 0x00, 0x02
Z_980F:
	jp nz,Z_9875	; 980F 20 64
Z_9811:
	dec c	; 9811 0D
Z_9812:
	ld a,(D_93EB)	; 9812 3A EB 93
Z_9815:
	ld (il_a),a	; 9815 CB 57
	and 0x04
	ld a,(il_a)
Z_9817:
	ld a,l	; 9817 7D
Z_9818:
	jp nz,Z_9829	; 9818 20 0F
Z_981A:
	rst 0x08	; 981A DD CB 00 76
	db 0x00, 0x40
Z_981E:
	jp z,Z_9822	; 981E 28 02
Z_9820:
	jp Z_97CB	; 9820 18 A9
Z_9822:
	cp 0x22	; 9822 FE 22
Z_9824:
	jp nc,Z_9705	; 9824 D2 05 97
Z_9827:
	jp Z_986C	; 9827 18 43
Z_9829:
	rst 0x28	; 9829 DD CB 00 CE
	db 0x00, 0x02
Z_982D:
	rst 0x28	; 982D DD CB 01 DE
	db 0x01, 0x08
Z_9831:
	rst 0x30	; 9831 DD CB 00 A6
	db 0x00, 0xEF
Z_9835:
	rst 0x30	; 9835 DD CB 00 9E
	db 0x00, 0xF7
Z_9839:
	ld hl,0x084C	; 9839 21 4C 08
Z_983C:
	rst 0x08	; 983C DD CB 01 46
	db 0x01, 0x01
Z_9840:
	jp z,Z_9844	; 9840 28 02
Z_9842:
	ld h,0x74	; 9842 26 74
Z_9844:
	ld (D_93F3),hl	; 9844 22 F3 93
Z_9847:
	ld l,0x21	; 9847 2E 21
Z_9849:
	ld (D_93F1),hl	; 9849 22 F1 93
Z_984C:
	inc c	; 984C 0C
Z_984D:
	push bc	; 984D C5
Z_984E:
	ld hl,(BLIT_Y)	; 984E 2A 00 33
Z_9851:
	push hl	; 9851 E5
Z_9852:
	xor a	; 9852 AF
Z_9853:
	ld (D_AA83),a	; 9853 32 83 AA
Z_9856:
	ld hl,0x02	; 9856 21 02 00
Z_9859:
	ld (BLIT_Y),hl	; 9859 22 00 33
Z_985C:
	ld hl,0x8039	; 985C 21 39 80
Z_985F:
	ld (BLIT_SRC),hl	; 985F 22 02 33
Z_9862:
	call Z_AA80	; 9862 CD 80 AA
Z_9865:
	pop hl	; 9865 E1
Z_9866:
	ld (BLIT_Y),hl	; 9866 22 00 33
Z_9869:
	pop bc	; 9869 C1
Z_986A:
	jp Z_9875	; 986A 18 09
Z_986C:
	rst 0x28	; 986C DD CB 01 DE
	db 0x01, 0x08
Z_9870:
	cp 0x1D	; 9870 FE 1D
Z_9872:
	call c,Z_97D6	; 9872 DC D6 97
Z_9875:
	ld a,0x30	; 9875 3E 30
Z_9877:
	add a,c	; 9877 81
Z_9878:
	ld c,0x01	; 9878 0E 01
Z_987A:
	rst 0x08	; 987A DD CB FF 56
	db 0xFF, 0x04
Z_987E:
	jp nz,Z_98A4	; 987E 20 24
Z_9880:
	ld hl,0x3301	; 9880 21 01 33
Z_9883:
	rst 0x08	; 9883 DD CB 01 46
	db 0x01, 0x01
Z_9887:
	jp z,Z_9897	; 9887 28 0E
Z_9889:
	rst 0x08	; 9889 DD CB FF 4E
	db 0xFF, 0x02
Z_988D:
	jp nz,Z_9892	; 988D 20 03
Z_988F:
	add a,0x02	; 988F C6 02
Z_9891:
	inc (hl)	; 9891 34
Z_9892:
	dec c	; 9892 0D
Z_9893:
	add a,0x08	; 9893 C6 08
Z_9895:
	jp Z_98A4	; 9895 18 0D
Z_9897:
	inc (hl)	; 9897 34
Z_9898:
	add a,0x06	; 9898 C6 06
Z_989A:
	rst 0x08	; 989A DD CB FF 4E
	db 0xFF, 0x02
Z_989E:
	jp nz,Z_98A4	; 989E 20 04
Z_98A0:
	add a,0x02	; 98A0 C6 02
Z_98A2:
	jp Z_98AD	; 98A2 18 09
Z_98A4:
	rst 0x08	; 98A4 DD CB 01 46
	db 0x01, 0x01
Z_98A8:
	jp z,Z_98AD	; 98A8 28 03
Z_98AA:
	add a,0x02	; 98AA C6 02
Z_98AC:
	add a,c	; 98AC 81
Z_98AD:
	call Z_9E6F	; 98AD CD 6F 9E
Z_98B0:
	jp Z_B01C	; 98B0 C3 1C B0
Z_98B3:
	call il_iy_lde	; 98B3 FD 5E 02
	db 0x02
Z_98B6:
	call il_iy_ldd	; 98B6 FD 56 03
	db 0x03
Z_98B9:
	ld bc,0x00	; 98B9 01 00 00
Z_98BC:
	rst 0x10	; 98BC DD 7E FF
	db 0xFF
Z_98BF:
	ld (il_a),a	; 98BF CB 47
	and 0x01
	ld a,(il_a)
Z_98C1:
	jp z,Z_98CB	; 98C1 28 08
Z_98C3:
	ld c,0xFE	; 98C3 0E FE
Z_98C5:
	ld (il_a),a	; 98C5 CB 4F
	and 0x02
	ld a,(il_a)
Z_98C7:
	jp z,Z_98CB	; 98C7 28 02
Z_98C9:
	ld c,0x02	; 98C9 0E 02
Z_98CB:
	ld (il_a),a	; 98CB CB 57
	and 0x04
	ld a,(il_a)
Z_98CD:
	jp z,Z_98F7	; 98CD 28 28
Z_98CF:
	ld b,0xFF	; 98CF 06 FF
Z_98D1:
	ld (il_a),a	; 98D1 CB 5F
	and 0x08
	ld a,(il_a)
Z_98D3:
	jp z,Z_98F7	; 98D3 28 22
Z_98D5:
	ld b,0x01	; 98D5 06 01
Z_98D7:
	jp Z_98F7	; 98D7 18 1E
Z_98D9:
	call il_ix_ldl	; 98D9 DD 6E 02
	db 0x02
Z_98DC:
	call il_ix_ldh	; 98DC DD 66 03
	db 0x03
Z_98DF:
	call il_iy_lde	; 98DF FD 5E 02
	db 0x02
Z_98E2:
	call il_iy_ldd	; 98E2 FD 56 03
	db 0x03
Z_98E5:
	ld a,h	; 98E5 7C
Z_98E6:
	sub d	; 98E6 92
Z_98E7:
	jp nc,Z_98EB	; 98E7 30 02
Z_98E9:
	cpl	; 98E9 ED 44
	inc a
Z_98EB:
	cp 0x06	; 98EB FE 06
Z_98ED:
	ret nc	; 98ED D0
Z_98EE:
	ld a,l	; 98EE 7D
Z_98EF:
	sub e	; 98EF 93
Z_98F0:
	jp nc,Z_98F4	; 98F0 30 02
Z_98F2:
	cpl	; 98F2 ED 44
	inc a
Z_98F4:
	cp 0x03	; 98F4 FE 03
Z_98F6:
	ret nc	; 98F6 D0
Z_98F7:
	ld a,e	; 98F7 7B
Z_98F8:
	add a,c	; 98F8 81
Z_98F9:
	call il_iy_sta	; 98F9 FD 77 02
	db 0x02
Z_98FC:
	ld a,d	; 98FC 7A
Z_98FD:
	add a,b	; 98FD 80
Z_98FE:
	call il_iy_sta	; 98FE FD 77 03
	db 0x03
Z_9901:
	call il_iy_sta	; 9901 FD 77 05
	db 0x05
Z_9904:
	ld e,0x02	; 9904 1E 02
Z_9906:
	call il_iy_bit	; 9906 FD CB 00 46
	db 0x00, 0x01
Z_990A:
	jp nz,Z_9919	; 990A 20 0D
Z_990C:
	call il_iy_lda	; 990C FD 7E FE
	db 0xFE
Z_990F:
	and 0x1F	; 990F E6 1F
Z_9911:
	jp nz,Z_9919	; 9911 20 06
Z_9913:
	call il_iy_lda	; 9913 FD 7E FF
	db 0xFF
Z_9916:
	call il_iy_sta	; 9916 FD 77 FE
	db 0xFE
Z_9919:
	ld a,(D_9400)	; 9919 3A 00 94
Z_991C:
	and a	; 991C A7
Z_991D:
	ret nz	; 991D C0
Z_991E:
	rst 0x08	; 991E DD CB 01 46
	db 0x01, 0x01
Z_9922:
	jp z,Z_9926	; 9922 28 02
Z_9924:
	push af	; 9924 CB FB
	ld a,e
	or 0x80
	ld e,a
	pop af
Z_9926:
	ld a,e	; 9926 7B
Z_9927:
	ld (D_9400),a	; 9927 32 00 94
Z_992A:
	ld a,0x14	; 992A 3E 14
Z_992C:
	ld (D_9451),a	; 992C 32 51 94
Z_992F:
	ld a,e	; 992F 7B
Z_9930:
	push af	; 9930 CB BF
	and 0x7F
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_9932:
	cp 0x02	; 9932 FE 02
Z_9934:
	ret nz	; 9934 C0
Z_9935:
	rst 0x10	; 9935 DD 7E 0B
	db 0x0B
Z_9938:
	cp 0x05	; 9938 FE 05
Z_993A:
	ret z	; 993A C8
Z_993B:
	call il_ix_inc	; 993B DD 34 0B
	db 0x0B
Z_993E:
	ld (il_tmp),hl	; 993E DD E5
	ld hl,(z80_ix)
	push hl
	ld hl,(il_tmp)
Z_9940:
	ld (il_tmp),hl	; 9940 FD E5
	ld hl,(z80_iy)
	push hl
	ld hl,(il_tmp)
Z_9942:
	call Z_9FC0	; 9942 CD C0 9F
Z_9945:
	ld (il_tmp),hl	; 9945 FD E1
	pop hl
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_9947:
	ld (il_tmp),hl	; 9947 DD E1
	pop hl
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_9949:
	ret	; 9949 C9
Z_994A:
	rst 0x08	; 994A DD CB 01 5E
	db 0x01, 0x08
Z_994E:
	ret nz	; 994E C0
Z_994F:
	rst 0x08	; 994F DD CB 01 4E
	db 0x01, 0x02
Z_9953:
	ret nz	; 9953 C0
Z_9954:
	rst 0x08	; 9954 DD CB 01 56
	db 0x01, 0x04
Z_9958:
	ret nz	; 9958 C0
Z_9959:
	rst 0x10	; 9959 DD 7E FE
	db 0xFE
Z_995C:
	and 0x0F	; 995C E6 0F
Z_995E:
	ret z	; 995E C8
Z_995F:
	call il_ix_ldc	; 995F DD 4E FF
	db 0xFF
Z_9962:
	ld (il_a),a	; 9962 CB 57
	and 0x04
	ld a,(il_a)
Z_9964:
	jp z,Z_998C	; 9964 28 26
Z_9966:
	ld (il_a),a	; 9966 CB 41
	ld a,c
	and 0x01
	ld a,(il_a)
Z_9968:
	jp z,Z_9970	; 9968 28 06
Z_996A:
	ld (il_a),a	; 996A CB 5F
	and 0x08
	ld a,(il_a)
Z_996C:
	jp z,Z_99AE	; 996C 28 40
Z_996E:
	jp Z_999D	; 996E 18 2D
Z_9970:
	ld (il_a),a	; 9970 CB 5F
	and 0x08
	ld a,(il_a)
Z_9972:
	jp nz,Z_9980	; 9972 20 0C
Z_9974:
	ld (il_a),a	; 9974 CB 59
	ld a,c
	and 0x08
	ld a,(il_a)
Z_9976:
	ret z	; 9976 C8
Z_9977:
	rst 0x00	; 9977 DD 36 FF 03
	db 0xFF, 0x03
Z_997B:
	rst 0x30	; 997B DD CB 00 B6
	db 0x00, 0xBF
Z_997F:
	ret	; 997F C9
Z_9980:
	ld (il_a),a	; 9980 CB 59
	ld a,c
	and 0x08
	ld a,(il_a)
Z_9982:
	ret nz	; 9982 C0
Z_9983:
	rst 0x00	; 9983 DD 36 FF 01
	db 0xFF, 0x01
Z_9987:
	rst 0x30	; 9987 DD CB 00 B6
	db 0x00, 0xBF
Z_998B:
	ret	; 998B C9
Z_998C:
	ld (il_a),a	; 998C CB 51
	ld a,c
	and 0x04
	ld a,(il_a)
Z_998E:
	jp z,Z_9996	; 998E 28 06
Z_9990:
	ld (il_a),a	; 9990 CB 4F
	and 0x02
	ld a,(il_a)
Z_9992:
	jp z,Z_9983	; 9992 28 EF
Z_9994:
	jp Z_9977	; 9994 18 E1
Z_9996:
	ld (il_a),a	; 9996 CB 4F
	and 0x02
	ld a,(il_a)
Z_9998:
	jp nz,Z_99AB	; 9998 20 11
Z_999A:
	ld (il_a),a	; 999A CB 49
	ld a,c
	and 0x02
	ld a,(il_a)
Z_999C:
	ret z	; 999C C8
Z_999D:
	rst 0x00	; 999D DD 36 FF 0C
	db 0xFF, 0x0C
Z_99A1:
	rst 0x08	; 99A1 DD CB 01 46
	db 0x01, 0x01
Z_99A5:
	ret z	; 99A5 C8
Z_99A6:
	rst 0x30	; 99A6 DD CB 00 B6
	db 0x00, 0xBF
Z_99AA:
	ret	; 99AA C9
Z_99AB:
	ld (il_a),a	; 99AB CB 49
	ld a,c
	and 0x02
	ld a,(il_a)
Z_99AD:
	ret nz	; 99AD C0
Z_99AE:
	rst 0x00	; 99AE DD 36 FF 04
	db 0xFF, 0x04
Z_99B2:
	rst 0x08	; 99B2 DD CB 01 46
	db 0x01, 0x01
Z_99B6:
	ret nz	; 99B6 C0
Z_99B7:
	rst 0x30	; 99B7 DD CB 00 B6
	db 0x00, 0xBF
Z_99BB:
	ret	; 99BB C9
Z_99BC:
	ld a,(D_93D6)	; 99BC 3A D6 93
Z_99BF:
	ld c,0x01	; 99BF 0E 01
Z_99C1:
	and a	; 99C1 A7
Z_99C2:
	jp nz,Z_99F2	; 99C2 20 2E
Z_99C4:
	ld c,0x03	; 99C4 0E 03
Z_99C6:
	rst 0x10	; 99C6 DD 7E 02
	db 0x02
Z_99C9:
	cp 0x48	; 99C9 FE 48
Z_99CB:
	jp c,Z_99F2	; 99CB 38 25
Z_99CD:
	cp 0x66	; 99CD FE 66
Z_99CF:
	jp nc,Z_99F2	; 99CF 30 21
Z_99D1:
	rst 0x10	; 99D1 DD 7E 03
	db 0x03
Z_99D4:
	rst 0x08	; 99D4 DD CB 01 46
	db 0x01, 0x01
Z_99D8:
	jp z,Z_99FD	; 99D8 28 23
Z_99DA:
	cp 0x52	; 99DA FE 52
Z_99DC:
	jp c,Z_99F2	; 99DC 38 14
Z_99DE:
	cp 0x58	; 99DE FE 58
Z_99E0:
	jp nc,Z_99F0	; 99E0 30 0E
Z_99E2:
	rst 0x10	; 99E2 DD 7E 02
	db 0x02
Z_99E5:
	cp 0x4C	; 99E5 FE 4C
Z_99E7:
	jp nc,Z_99F7	; 99E7 30 0E
Z_99E9:
	rst 0x10	; 99E9 DD 7E 03
	db 0x03
Z_99EC:
	cp 0x56	; 99EC FE 56
Z_99EE:
	jp c,Z_99F2	; 99EE 38 02
Z_99F0:
	push af	; 99F0 CB 81
	ld a,c
	and 0xFE
	ld c,a
	pop af
Z_99F2:
	ld a,c	; 99F2 79
Z_99F3:
	ld (D_93D9),a	; 99F3 32 D9 93
Z_99F6:
	ret	; 99F6 C9
Z_99F7:
	cp 0x5E	; 99F7 FE 5E
Z_99F9:
	jp c,Z_99F0	; 99F9 38 F5
Z_99FB:
	jp Z_99F2	; 99FB 18 F5
Z_99FD:
	cp 0x24	; 99FD FE 24
Z_99FF:
	jp nc,Z_99F2	; 99FF 30 F1
Z_9A01:
	cp 0x1E	; 9A01 FE 1E
Z_9A03:
	jp c,Z_99F0	; 9A03 38 EB
Z_9A05:
	rst 0x10	; 9A05 DD 7E 02
	db 0x02
Z_9A08:
	cp 0x4C	; 9A08 FE 4C
Z_9A0A:
	jp nc,Z_9A15	; 9A0A 30 09
Z_9A0C:
	rst 0x10	; 9A0C DD 7E 03
	db 0x03
Z_9A0F:
	cp 0x22	; 9A0F FE 22
Z_9A11:
	jp c,Z_99F0	; 9A11 38 DD
Z_9A13:
	jp Z_99F2	; 9A13 18 DD
Z_9A15:
	cp 0x5E	; 9A15 FE 5E
Z_9A17:
	jp c,Z_99F0	; 9A17 38 D7
Z_9A19:
	jp Z_99F2	; 9A19 18 D7
Z_9A1B:
	ld (il_tmp),hl	; 9A1B DD 21 F5 93
	ld hl,D_93F5
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_9A1F:
	rst 0x08	; 9A1F DD CB 00 46
	db 0x00, 0x01
Z_9A23:
	jp nz,Z_9A84	; 9A23 20 5F
Z_9A25:
	rst 0x00	; 9A25 DD 36 00 01
	db 0x00, 0x01
Z_9A29:
	ld a,0x01	; 9A29 3E 01
Z_9A2B:
	ld (D_93F0),a	; 9A2B 32 F0 93
Z_9A2E:
	ld hl,D_9B69	; 9A2E 21 69 9B
Z_9A31:
	ld (D_93ED),hl	; 9A31 22 ED 93
Z_9A34:
	call il_ix_ldl	; 9A34 DD 6E FE
	db 0xFE
Z_9A37:
	call il_ix_ldh	; 9A37 DD 66 FF
	db 0xFF
Z_9A3A:
	ld a,(D_93F1)	; 9A3A 3A F1 93
Z_9A3D:
	rst 0x20	; 9A3D DD 77 01
	db 0x01
Z_9A40:
	sub 0x1E	; 9A40 D6 1E
Z_9A42:
	jp nc,Z_9A4A	; 9A42 30 06
Z_9A44:
	cpl	; 9A44 ED 44
	inc a
Z_9A46:
	rst 0x28	; 9A46 DD CB 00 FE
	db 0x00, 0x80
Z_9A4A:
	rst 0x20	; 9A4A DD 77 02
	db 0x02
Z_9A4D:
	ld de,0x0554	; 9A4D 11 54 05
Z_9A50:
	rst 0x08	; 9A50 DD CB F6 7E
	db 0xF6, 0x80
Z_9A54:
	jp z,Z_9A58	; 9A54 28 02
Z_9A56:
	ld d,0x39	; 9A56 16 39
Z_9A58:
	ld a,d	; 9A58 7A
Z_9A59:
	ld (il_a),a	; 9A59 CB 3C
	ld a,h
	or a
	rra
	ld h,a
	ld a,(il_a)
Z_9A5B:
	sub h	; 9A5B 94
Z_9A5C:
	ld d,0x02	; 9A5C 16 02
Z_9A5E:
	jp nc,Z_9A64	; 9A5E 30 04
Z_9A60:
	cpl	; 9A60 ED 44
	inc a
Z_9A62:
	ld d,0xFE	; 9A62 16 FE
Z_9A64:
	ld b,a	; 9A64 47
Z_9A65:
	ld a,e	; 9A65 7B
Z_9A66:
	sub l	; 9A66 95
Z_9A67:
	ld e,0x02	; 9A67 1E 02
Z_9A69:
	jp nc,Z_9A6F	; 9A69 30 04
Z_9A6B:
	cpl	; 9A6B ED 44
	inc a
Z_9A6D:
	ld e,0xFE	; 9A6D 1E FE
Z_9A6F:
	ld c,a	; 9A6F 4F
Z_9A70:
	ld (il_a),a	; 9A70 CB 39
	ld a,c
	or a
	rra
	ld c,a
	ld a,(il_a)
Z_9A72:
	ld a,b	; 9A72 78
Z_9A73:
	cp c	; 9A73 B9
Z_9A74:
	jp nc,Z_9A77	; 9A74 30 01
Z_9A76:
	ld a,c	; 9A76 79
Z_9A77:
	ld (D_93EF),a	; 9A77 32 EF 93
Z_9A7A:
	or a	; 9A7A CB 3F
	rra
	or a
Z_9A7C:
	ld (D_93EC),a	; 9A7C 32 EC 93
Z_9A7F:
	call Z_9AF6	; 9A7F CD F6 9A
Z_9A82:
	jp Z_9AAF	; 9A82 18 2B
Z_9A84:
	rst 0x08	; 9A84 DD CB 00 56
	db 0x00, 0x04
Z_9A88:
	jp z,Z_9AAC	; 9A88 28 22
Z_9A8A:
	ld a,(D_93EB)	; 9A8A 3A EB 93
Z_9A8D:
	ld (il_a),a	; 9A8D CB 7F
	and 0x80
	ld a,(il_a)
Z_9A8F:
	ld a,0x01	; 9A8F 3E 01
Z_9A91:
	jp nz,Z_9A95	; 9A91 20 02
Z_9A93:
	cpl	; 9A93 ED 44
	inc a
Z_9A95:
	call il_ix_ldc	; 9A95 DD 4E FF
	db 0xFF
Z_9A98:
	add a,c	; 9A98 81
Z_9A99:
	rst 0x20	; 9A99 DD 77 FF
	db 0xFF
Z_9A9C:
	rst 0x20	; 9A9C DD 77 FD
	db 0xFD
Z_9A9F:
	rst 0x10	; 9A9F DD 7E FC
	db 0xFC
Z_9AA2:
	add a,0x04	; 9AA2 C6 04
Z_9AA4:
	rst 0x20	; 9AA4 DD 77 FC
	db 0xFC
Z_9AA7:
	rst 0x28	; 9AA7 DD CB 00 CE
	db 0x00, 0x02
Z_9AAB:
	ret	; 9AAB C9
Z_9AAC:
	call Z_9B4C	; 9AAC CD 4C 9B
Z_9AAF:
	ld hl,(D_93ED)	; 9AAF 2A ED 93
Z_9AB2:
	ld c,(hl)	; 9AB2 4E
Z_9AB3:
	ld a,(D_93EC)	; 9AB3 3A EC 93
Z_9AB6:
	and a	; 9AB6 A7
Z_9AB7:
	jp z,Z_9AC0	; 9AB7 28 07
Z_9AB9:
	dec a	; 9AB9 3D
Z_9ABA:
	ld (D_93EC),a	; 9ABA 32 EC 93
Z_9ABD:
	inc hl	; 9ABD 23
Z_9ABE:
	jp Z_9AC1	; 9ABE 18 01
Z_9AC0:
	dec hl	; 9AC0 2B
Z_9AC1:
	ld (D_93ED),hl	; 9AC1 22 ED 93
Z_9AC4:
	call il_ix_ldh	; 9AC4 DD 66 FF
	db 0xFF
Z_9AC7:
	call il_ix_sth	; 9AC7 DD 74 FD
	db 0xFD
Z_9ACA:
	push bc	; 9ACA C5
Z_9ACB:
	call il_ix_ldc	; 9ACB DD 4E FB
	db 0xFB
Z_9ACE:
	call il_ix_inc	; 9ACE DD 34 FB
	db 0xFB
Z_9AD1:
	call il_ix_ldl	; 9AD1 DD 6E 02
	db 0x02
Z_9AD4:
	ld h,0x00	; 9AD4 26 00
Z_9AD6:
	ld b,h	; 9AD6 44
Z_9AD7:
	call Z_398C	; 9AD7 CD 8C 39
Z_9ADA:
	ld b,0x00	; 9ADA 06 00
Z_9ADC:
	call il_ix_ldc	; 9ADC DD 4E FA
	db 0xFA
Z_9ADF:
	call Z_39A3	; 9ADF CD A3 39
Z_9AE2:
	rst 0x08	; 9AE2 DD CB 00 7E
	db 0x00, 0x80
Z_9AE6:
	jp z,Z_9AEC	; 9AE6 28 04
Z_9AE8:
	ld a,l	; 9AE8 7D
Z_9AE9:
	cpl	; 9AE9 ED 44
	inc a
Z_9AEB:
	ld l,a	; 9AEB 6F
Z_9AEC:
	rst 0x10	; 9AEC DD 7E 01
	db 0x01
Z_9AEF:
	sub l	; 9AEF 95
Z_9AF0:
	pop bc	; 9AF0 C1
Z_9AF1:
	sub c	; 9AF1 91
Z_9AF2:
	rst 0x20	; 9AF2 DD 77 FC
	db 0xFC
Z_9AF5:
	ret	; 9AF5 C9
Z_9AF6:
	ld a,c	; 9AF6 79
Z_9AF7:
	cp b	; 9AF7 B8
Z_9AF8:
	jp nc,Z_9B00	; 9AF8 30 06
Z_9AFA:
	ld l,c	; 9AFA 69
Z_9AFB:
	push de	; 9AFB D5
Z_9AFC:
	xor a	; 9AFC AF
Z_9AFD:
	ld e,a	; 9AFD 5F
Z_9AFE:
	jp Z_9B08	; 9AFE 18 08
Z_9B00:
	or c	; 9B00 B1
Z_9B01:
	jp z,Z_9B47	; 9B01 28 44
Z_9B03:
	ld l,b	; 9B03 68
Z_9B04:
	ld b,c	; 9B04 41
Z_9B05:
	push de	; 9B05 D5
Z_9B06:
	ld d,0x00	; 9B06 16 00
Z_9B08:
	ld h,b	; 9B08 60
Z_9B09:
	ld a,b	; 9B09 78
Z_9B0A:
	rra	; 9B0A 1F
Z_9B0B:
	add a,l	; 9B0B 85
Z_9B0C:
	jp c,Z_9B11	; 9B0C 38 03
Z_9B0E:
	cp h	; 9B0E BC
Z_9B0F:
	jp c,Z_9B18	; 9B0F 38 07
Z_9B11:
	sub h	; 9B11 94
Z_9B12:
	ld c,a	; 9B12 4F
Z_9B13:
	call il_exx	; 9B13 D9
Z_9B14:
	pop bc	; 9B14 C1
Z_9B15:
	push bc	; 9B15 C5
Z_9B16:
	jp Z_9B1C	; 9B16 18 04
Z_9B18:
	ld c,a	; 9B18 4F
Z_9B19:
	push de	; 9B19 D5
Z_9B1A:
	call il_exx	; 9B1A D9
Z_9B1B:
	pop bc	; 9B1B C1
Z_9B1C:
	ld a,b	; 9B1C 78
Z_9B1D:
	call il_ix_add	; 9B1D DD 86 FF
	db 0xFF
Z_9B20:
	rst 0x20	; 9B20 DD 77 FF
	db 0xFF
Z_9B23:
	ld b,a	; 9B23 47
Z_9B24:
	ld a,c	; 9B24 79
Z_9B25:
	call il_ix_add	; 9B25 DD 86 FE
	db 0xFE
Z_9B28:
	rst 0x20	; 9B28 DD 77 FE
	db 0xFE
Z_9B2B:
	call il_exx	; 9B2B D9
Z_9B2C:
	dec b	; 9B2C 05
Z_9B2D:
	call il_ix_stl	; 9B2D DD 75 03
	db 0x03
Z_9B30:
	call il_ix_sth	; 9B30 DD 74 04
	db 0x04
Z_9B33:
	call il_ix_stc	; 9B33 DD 71 05
	db 0x05
Z_9B36:
	call il_ix_stb	; 9B36 DD 70 06
	db 0x06
Z_9B39:
	call il_ix_ste	; 9B39 DD 73 07
	db 0x07
Z_9B3C:
	call il_ix_std	; 9B3C DD 72 08
	db 0x08
Z_9B3F:
	pop hl	; 9B3F E1
Z_9B40:
	call il_ix_stl	; 9B40 DD 75 09
	db 0x09
Z_9B43:
	call il_ix_sth	; 9B43 DD 74 0A
	db 0x0A
Z_9B46:
	ret nz	; 9B46 C0
Z_9B47:
	rst 0x28	; 9B47 DD CB 00 D6
	db 0x00, 0x04
Z_9B4B:
	ret	; 9B4B C9
Z_9B4C:
	call il_ix_lde	; 9B4C DD 5E 09
	db 0x09
Z_9B4F:
	call il_ix_ldd	; 9B4F DD 56 0A
	db 0x0A
Z_9B52:
	push de	; 9B52 D5
Z_9B53:
	call il_ix_ldl	; 9B53 DD 6E 03
	db 0x03
Z_9B56:
	call il_ix_ldh	; 9B56 DD 66 04
	db 0x04
Z_9B59:
	call il_ix_ldc	; 9B59 DD 4E 05
	db 0x05
Z_9B5C:
	call il_ix_ldb	; 9B5C DD 46 06
	db 0x06
Z_9B5F:
	call il_ix_lde	; 9B5F DD 5E 07
	db 0x07
Z_9B62:
	call il_ix_ldd	; 9B62 DD 56 08
	db 0x08
Z_9B65:
	ld a,c	; 9B65 79
Z_9B66:
	jp Z_9B0B	; 9B66 C3 0B 9B
Z_9BF6:
	ld (il_tmp),hl	; 9BF6 DD 21 F5 93
	ld hl,D_93F5
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_9BFA:
	rst 0x08	; 9BFA DD CB 00 46
	db 0x00, 0x01
Z_9BFE:
	jp nz,Z_9C36	; 9BFE C2 36 9C
Z_9C01:
	rst 0x00	; 9C01 DD 36 00 41
	db 0x00, 0x41
Z_9C05:
	call Z_386E	; 9C05 CD 6E 38
Z_9C08:
	push af	; 9C08 F5
Z_9C09:
	call Z_386E	; 9C09 CD 6E 38
Z_9C0C:
	and 0x03	; 9C0C E6 03
Z_9C0E:
	ld hl,D_9B89	; 9C0E 21 89 9B
Z_9C11:
	jp z,Z_9C22	; 9C11 28 0F
Z_9C13:
	ld hl,D_9B9F	; 9C13 21 9F 9B
Z_9C16:
	dec a	; 9C16 3D
Z_9C17:
	jp z,Z_9C22	; 9C17 28 09
Z_9C19:
	ld hl,D_9BBB	; 9C19 21 BB 9B
Z_9C1C:
	dec a	; 9C1C 3D
Z_9C1D:
	jp z,Z_9C22	; 9C1D 28 03
Z_9C1F:
	ld hl,D_9BD7	; 9C1F 21 D7 9B
Z_9C22:
	ld (D_93ED),hl	; 9C22 22 ED 93
Z_9C25:
	pop af	; 9C25 F1
Z_9C26:
	and 0x03	; 9C26 E6 03
Z_9C28:
	jp z,Z_9C36	; 9C28 28 0C
Z_9C2A:
	rst 0x30	; 9C2A DD CB 00 B6
	db 0x00, 0xBF
Z_9C2E:
	ld (il_a),a	; 9C2E CB 47
	and 0x01
	ld a,(il_a)
Z_9C30:
	jp z,Z_9C36	; 9C30 28 04
Z_9C32:
	rst 0x28	; 9C32 DD CB 00 FE
	db 0x00, 0x80
Z_9C36:
	ld hl,(D_93ED)	; 9C36 2A ED 93
Z_9C39:
	ld a,(D_93D6)	; 9C39 3A D6 93
Z_9C3C:
	and a	; 9C3C A7
Z_9C3D:
	jp nz,Z_9C45	; 9C3D 20 06
Z_9C3F:
	rst 0x08	; 9C3F DD CB 00 76
	db 0x00, 0x40
Z_9C43:
	jp nz,Z_9C54	; 9C43 20 0F
Z_9C45:
	ld a,(hl)	; 9C45 7E
Z_9C46:
	rst 0x08	; 9C46 DD CB 00 7E
	db 0x00, 0x80
Z_9C4A:
	jp z,Z_9C4E	; 9C4A 28 02
Z_9C4C:
	cpl	; 9C4C ED 44
	inc a
Z_9C4E:
	call il_ix_add	; 9C4E DD 86 FE
	db 0xFE
Z_9C51:
	rst 0x20	; 9C51 DD 77 FE
	db 0xFE
Z_9C54:
	inc hl	; 9C54 23
Z_9C55:
	ld a,(D_93EB)	; 9C55 3A EB 93
Z_9C58:
	ld (il_a),a	; 9C58 CB 7F
	and 0x80
	ld a,(il_a)
Z_9C5A:
	ld a,(hl)	; 9C5A 7E
Z_9C5B:
	jp z,Z_9C5F	; 9C5B 28 02
Z_9C5D:
	cpl	; 9C5D ED 44
	inc a
Z_9C5F:
	call il_ix_add	; 9C5F DD 86 FF
	db 0xFF
Z_9C62:
	rst 0x20	; 9C62 DD 77 FF
	db 0xFF
Z_9C65:
	rst 0x20	; 9C65 DD 77 FD
	db 0xFD
Z_9C68:
	inc hl	; 9C68 23
Z_9C69:
	ld a,(hl)	; 9C69 7E
Z_9C6A:
	call il_ix_add	; 9C6A DD 86 FC
	db 0xFC
Z_9C6D:
	rst 0x20	; 9C6D DD 77 FC
	db 0xFC
Z_9C70:
	inc hl	; 9C70 23
Z_9C71:
	ld (D_93ED),hl	; 9C71 22 ED 93
Z_9C74:
	ld a,(hl)	; 9C74 7E
Z_9C75:
	inc a	; 9C75 3C
Z_9C76:
	ret nz	; 9C76 C0
Z_9C77:
	rst 0x28	; 9C77 DD CB 00 CE
	db 0x00, 0x02
Z_9C7B:
	ret	; 9C7B C9
Z_9C7C:
	rst 0x30	; 9C7C DD CB 01 AE
	db 0x01, 0xDF
Z_9C80:
	jp Z_9E82	; 9C80 C3 82 9E
	org	0x9B69
D_9B69:
Z_9B69:
	db	0x02, 0x03, 0x03, 0x04, 0x04, 0x05, 0x05, 0x06, 0x06, 0x07, 0x07, 0x08, 0x08, 0x09, 0x09, 0x0A	; 9B69
	org	0x9B79
D_9B79:
Z_9B79:
	db	0x0A, 0x0A, 0x0B, 0x0B, 0x0B, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0D, 0x0D, 0x0D, 0x0D, 0x0D, 0x0D	; 9B79
	org	0x9B89
D_9B89:
Z_9B89:
	db	0x00, 0x02, 0xFC, 0xFE, 0x01, 0x00, 0x00, 0x01, 0x02, 0x00, 0x01, 0x02, 0x00, 0x00, 0x06, 0x00	; 9B89
	org	0x9B99
D_9B99:
Z_9B99:
	db	0x00, 0x06, 0x00, 0x00, 0x06, 0xFF	; 9B99
	org	0x9B9F
D_9B9F:
Z_9B9F:
	db	0x00, 0x02, 0xFC, 0xFE, 0x02, 0xFE, 0xFE, 0x02, 0x00, 0x00, 0x02, 0x04, 0x00, 0x02, 0x04, 0x00	; 9B9F
	org	0x9BAF
D_9BAF:
Z_9BAF:
	db	0x01, 0x04, 0x00, 0x01, 0x06, 0x00, 0x01, 0x06, 0x00, 0x00, 0x06, 0xFF	; 9BAF
	org	0x9BBB
D_9BBB:
Z_9BBB:
	db	0x00, 0x02, 0xFC, 0xFE, 0x02, 0xFE, 0xFE, 0x02, 0x00, 0xFE, 0x02, 0x02, 0xFE, 0x02, 0x04, 0x00	; 9BBB
	org	0x9BCB
D_9BCB:
Z_9BCB:
	db	0x02, 0x04, 0x00, 0x02, 0x06, 0x00, 0x01, 0x06, 0x00, 0x01, 0x06, 0xFF	; 9BCB
	org	0x9BD7
D_9BD7:
Z_9BD7:
	db	0x00, 0x02, 0xFC, 0xFE, 0x02, 0xFC, 0xFE, 0x02, 0xFC, 0x00, 0x02, 0x00, 0xFE, 0x02, 0x04, 0xFE	; 9BD7
	org	0x9BE7
D_9BE7:
Z_9BE7:
	db	0x02, 0x04, 0x00, 0x01, 0x04, 0x00, 0x01, 0x04, 0x00, 0x01, 0x06, 0x00, 0x01, 0x06, 0xFF	; 9BE7
	org	0x9BF6
Z_9C83:
	push af	; 9C83 DD CB F9 86
	ld (il_tmp2),hl
	ld hl,(z80_ix)
	ld a,l
	add a,249
	ld l,a
	ld a,h
	adc a,255
	ld h,a
	ld a,(hl)
	and 0xFE
	ld (hl),a
	ld hl,(il_tmp2)
	pop af
Z_9C87:
	ld (il_a),a	; 9C87 DD CB 00 46
	ld (il_tmp2),hl
	ld hl,(z80_ix)
	ld a,(hl)
	and 0x01
	ld hl,(il_tmp2)
	ld a,(il_a)
Z_9C8B:
	jp nz,Z_84E2	; 9C8B C2 E2 84
Z_9C8E:
	rst 0x10	; 9C8E DD 7E FE
	db 0xFE
Z_9C91:
	and 0x1F	; 9C91 E6 1F
Z_9C93:
	jp z,Z_9C7C	; 9C93 28 E7
Z_9C95:
	call il_ix_ldb	; 9C95 DD 46 FF
	db 0xFF
Z_9C98:
	cp 0x10	; 9C98 FE 10
Z_9C9A:
	jp z,Z_84E5	; 9C9A CA E5 84
Z_9C9D:
	rst 0x08	; 9C9D DD CB 00 66
	db 0x00, 0x10
Z_9CA1:
	jp z,Z_9CB1	; 9CA1 28 0E
Z_9CA3:
	ld (il_a),a	; 9CA3 CB 67
	and 0x10
	ld a,(il_a)
Z_9CA5:
	jp z,Z_9CB9	; 9CA5 28 12
Z_9CA7:
	push af	; 9CA7 CB A7
	and 0xEF
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_9CA9:
	call il_ix_cp	; 9CA9 DD BE FF
	db 0xFF
Z_9CAC:
	jp z,Z_84E5	; 9CAC CA E5 84
Z_9CAF:
	jp Z_9CB6	; 9CAF 18 05
Z_9CB1:
	ld (il_a),a	; 9CB1 CB 67
	and 0x10
	ld a,(il_a)
Z_9CB3:
	jp nz,Z_84E5	; 9CB3 C2 E5 84
Z_9CB6:
	rst 0x20	; 9CB6 DD 77 FF
	db 0xFF
Z_9CB9:
	ld c,a	; 9CB9 4F
Z_9CBA:
	call il_ix_ldl	; 9CBA DD 6E 02
	db 0x02
Z_9CBD:
	call il_ix_ldh	; 9CBD DD 66 03
	db 0x03
Z_9CC0:
	call il_iy_lde	; 9CC0 FD 5E 02
	db 0x02
Z_9CC3:
	call il_iy_ldd	; 9CC3 FD 56 03
	db 0x03
Z_9CC6:
	rst 0x30	; 9CC6 DD CB 01 AE
	db 0x01, 0xDF
Z_9CCA:
	ld (il_a),a	; 9CCA CB 41
	ld a,c
	and 0x01
	ld a,(il_a)
Z_9CCC:
	jp z,Z_9D23	; 9CCC 28 55
Z_9CCE:
	ld a,l	; 9CCE 7D
Z_9CCF:
	ld (il_a),a	; 9CCF CB 49
	ld a,c
	and 0x02
	ld a,(il_a)
Z_9CD1:
	jp nz,Z_9CFC	; 9CD1 20 29
Z_9CD3:
	cp 0x41	; 9CD3 FE 41
Z_9CD5:
	jp c,Z_9D23	; 9CD5 38 4C
Z_9CD7:
	ld a,d	; 9CD7 7A
Z_9CD8:
	sub h	; 9CD8 94
Z_9CD9:
	jp nc,Z_9CDD	; 9CD9 30 02
Z_9CDB:
	cpl	; 9CDB ED 44
	inc a
Z_9CDD:
	cp 0x06	; 9CDD FE 06
Z_9CDF:
	jp nc,Z_9CF3	; 9CDF 30 12
Z_9CE1:
	ld a,l	; 9CE1 7D
Z_9CE2:
	inc a	; 9CE2 3C
Z_9CE3:
	cp e	; 9CE3 BB
Z_9CE4:
	jp c,Z_9CF3	; 9CE4 38 0D
Z_9CE6:
	sub 0x06	; 9CE6 D6 06
Z_9CE8:
	cp e	; 9CE8 BB
Z_9CE9:
	rst 0x28	; 9CE9 DD CB 01 EE
	db 0x01, 0x20
Z_9CED:
	jp c,Z_9D23	; 9CED 38 34
Z_9CEF:
	rst 0x30	; 9CEF DD CB 01 AE
	db 0x01, 0xDF
Z_9CF3:
	dec l	; 9CF3 2D
Z_9CF4:
	call Z_9E47	; 9CF4 CD 47 9E
Z_9CF7:
	jp nz,Z_9D23	; 9CF7 20 2A
Z_9CF9:
	dec l	; 9CF9 2D
Z_9CFA:
	jp Z_9D23	; 9CFA 18 27
Z_9CFC:
	cp 0x6E	; 9CFC FE 6E
Z_9CFE:
	jp nc,Z_9D23	; 9CFE 30 23
Z_9D00:
	ld a,d	; 9D00 7A
Z_9D01:
	sub h	; 9D01 94
Z_9D02:
	jp nc,Z_9D06	; 9D02 30 02
Z_9D04:
	cpl	; 9D04 ED 44
	inc a
Z_9D06:
	cp 0x06	; 9D06 FE 06
Z_9D08:
	jp nc,Z_9D1C	; 9D08 30 12
Z_9D0A:
	ld a,e	; 9D0A 7B
Z_9D0B:
	inc a	; 9D0B 3C
Z_9D0C:
	cp l	; 9D0C BD
Z_9D0D:
	jp c,Z_9D1C	; 9D0D 38 0D
Z_9D0F:
	sub 0x06	; 9D0F D6 06
Z_9D11:
	cp l	; 9D11 BD
Z_9D12:
	rst 0x28	; 9D12 DD CB 01 EE
	db 0x01, 0x20
Z_9D16:
	jp c,Z_9D23	; 9D16 38 0B
Z_9D18:
	rst 0x30	; 9D18 DD CB 01 AE
	db 0x01, 0xDF
Z_9D1C:
	inc l	; 9D1C 2C
Z_9D1D:
	call Z_9E47	; 9D1D CD 47 9E
Z_9D20:
	jp nz,Z_9D23	; 9D20 20 01
Z_9D22:
	inc l	; 9D22 2C
Z_9D23:
	ld a,0x70	; 9D23 3E 70
Z_9D25:
	ld c,a	; 9D25 4F
Z_9D26:
	sub l	; 9D26 95
Z_9D27:
	or a	; 9D27 CB 3F
	rra
Z_9D29:
	or a	; 9D29 CB 3F
	rra
Z_9D2B:
	inc a	; 9D2B 3C
Z_9D2C:
	ld b,a	; 9D2C 47
Z_9D2D:
	cp h	; 9D2D BC
Z_9D2E:
	jp c,Z_9D3B	; 9D2E 38 0B
Z_9D30:
	ld a,h	; 9D30 7C
Z_9D31:
	inc a	; 9D31 3C
Z_9D32:
	cp b	; 9D32 B8
Z_9D33:
	jp nc,Z_9D4F	; 9D33 30 1A
Z_9D35:
	rst 0x00	; 9D35 DD 36 FE 0C
	db 0xFE, 0x0C
Z_9D39:
	jp Z_9D4F	; 9D39 18 14
Z_9D3B:
	cpl	; 9D3B ED 44
	inc a
Z_9D3D:
	add a,0x73	; 9D3D C6 73
Z_9D3F:
	ld c,a	; 9D3F 4F
Z_9D40:
	cp h	; 9D40 BC
Z_9D41:
	jp nc,Z_9D4F	; 9D41 30 0C
Z_9D43:
	ld a,h	; 9D43 7C
Z_9D44:
	dec a	; 9D44 3D
Z_9D45:
	dec a	; 9D45 3D
Z_9D46:
	cp c	; 9D46 B9
Z_9D47:
	jp c,Z_9D4F	; 9D47 38 06
Z_9D49:
	jp z,Z_9D4F	; 9D49 28 04
Z_9D4B:
	rst 0x00	; 9D4B DD 36 FE 04
	db 0xFE, 0x04
Z_9D4F:
	rst 0x08	; 9D4F DD CB FE 56
	db 0xFE, 0x04
Z_9D53:
	jp z,Z_9DB9	; 9D53 28 64
Z_9D55:
	rst 0x08	; 9D55 DD CB FE 5E
	db 0xFE, 0x08
Z_9D59:
	jp nz,Z_9D8B	; 9D59 20 30
Z_9D5B:
	rst 0x28	; 9D5B DD CB F9 C6
	db 0xF9, 0x01
Z_9D5F:
	ld a,b	; 9D5F 78
Z_9D60:
	cp h	; 9D60 BC
Z_9D61:
	jp nc,Z_9DB9	; 9D61 30 56
Z_9D63:
	rst 0x30	; 9D63 DD CB F9 86
	db 0xF9, 0xFE
Z_9D67:
	ld a,l	; 9D67 7D
Z_9D68:
	sub e	; 9D68 93
Z_9D69:
	jp nc,Z_9D6D	; 9D69 30 02
Z_9D6B:
	cpl	; 9D6B ED 44
	inc a
Z_9D6D:
	cp 0x03	; 9D6D FE 03
Z_9D6F:
	jp nc,Z_9D82	; 9D6F 30 11
Z_9D71:
	ld a,h	; 9D71 7C
Z_9D72:
	cp d	; 9D72 BA
Z_9D73:
	jp c,Z_9D82	; 9D73 38 0D
Z_9D75:
	sub 0x08	; 9D75 D6 08
Z_9D77:
	cp d	; 9D77 BA
Z_9D78:
	rst 0x28	; 9D78 DD CB 01 EE
	db 0x01, 0x20
Z_9D7C:
	jp c,Z_9DB9	; 9D7C 38 3B
Z_9D7E:
	rst 0x30	; 9D7E DD CB 01 AE
	db 0x01, 0xDF
Z_9D82:
	dec h	; 9D82 25
Z_9D83:
	call Z_9E47	; 9D83 CD 47 9E
Z_9D86:
	jp nz,Z_9DB9	; 9D86 20 31
Z_9D88:
	dec h	; 9D88 25
Z_9D89:
	jp Z_9DB9	; 9D89 18 2E
Z_9D8B:
	rst 0x28	; 9D8B DD CB F9 C6
	db 0xF9, 0x01
Z_9D8F:
	ld a,c	; 9D8F 79
Z_9D90:
	cp h	; 9D90 BC
Z_9D91:
	jp c,Z_9DB9	; 9D91 38 26
Z_9D93:
	rst 0x30	; 9D93 DD CB F9 86
	db 0xF9, 0xFE
Z_9D97:
	ld a,l	; 9D97 7D
Z_9D98:
	sub e	; 9D98 93
Z_9D99:
	jp nc,Z_9D9D	; 9D99 30 02
Z_9D9B:
	cpl	; 9D9B ED 44
	inc a
Z_9D9D:
	cp 0x03	; 9D9D FE 03
Z_9D9F:
	jp nc,Z_9DB2	; 9D9F 30 11
Z_9DA1:
	ld a,d	; 9DA1 7A
Z_9DA2:
	cp h	; 9DA2 BC
Z_9DA3:
	jp c,Z_9DB2	; 9DA3 38 0D
Z_9DA5:
	sub 0x08	; 9DA5 D6 08
Z_9DA7:
	cp h	; 9DA7 BC
Z_9DA8:
	rst 0x28	; 9DA8 DD CB 01 EE
	db 0x01, 0x20
Z_9DAC:
	jp c,Z_9DB9	; 9DAC 38 0B
Z_9DAE:
	rst 0x30	; 9DAE DD CB 01 AE
	db 0x01, 0xDF
Z_9DB2:
	inc h	; 9DB2 24
Z_9DB3:
	call Z_9E47	; 9DB3 CD 47 9E
Z_9DB6:
	jp nz,Z_9DB9	; 9DB6 20 01
Z_9DB8:
	inc h	; 9DB8 24
Z_9DB9:
	call il_ix_stl	; 9DB9 DD 75 02
	db 0x02
Z_9DBC:
	call il_ix_sth	; 9DBC DD 74 03
	db 0x03
Z_9DBF:
	call Z_9ED4	; 9DBF CD D4 9E
Z_9DC2:
	call il_ix_ldl	; 9DC2 DD 6E 02
	db 0x02
Z_9DC5:
	call il_ix_ldh	; 9DC5 DD 66 03
	db 0x03
Z_9DC8:
	rst 0x08	; 9DC8 DD CB 00 66
	db 0x00, 0x10
Z_9DCC:
	ret z	; 9DCC C8
Z_9DCD:
	call il_ix_ldc	; 9DCD DD 4E FF
	db 0xFF
Z_9DD0:
	ld (il_a),a	; 9DD0 CB 51
	ld a,c
	and 0x04
	ld a,(il_a)
Z_9DD2:
	jp z,Z_9DDE	; 9DD2 28 0A
Z_9DD4:
	ld (il_a),a	; 9DD4 CB 59
	ld a,c
	and 0x08
	ld a,(il_a)
Z_9DD6:
	jp z,Z_9DED	; 9DD6 28 15
Z_9DD8:
	ld a,h	; 9DD8 7C
Z_9DD9:
	add a,0x09	; 9DD9 C6 09
Z_9DDB:
	ld h,a	; 9DDB 67
Z_9DDC:
	jp Z_9DED	; 9DDC 18 0F
Z_9DDE:
	ld (il_a),a	; 9DDE CB 49
	ld a,c
	and 0x02
	ld a,(il_a)
Z_9DE0:
	ld c,0x02	; 9DE0 0E 02
Z_9DE2:
	jp nz,Z_9DEA	; 9DE2 20 06
Z_9DE4:
	ld c,0xFE	; 9DE4 0E FE
Z_9DE6:
	ld a,h	; 9DE6 7C
Z_9DE7:
	add a,0x09	; 9DE7 C6 09
Z_9DE9:
	ld h,a	; 9DE9 67
Z_9DEA:
	ld a,l	; 9DEA 7D
Z_9DEB:
	add a,c	; 9DEB 81
Z_9DEC:
	ld l,a	; 9DEC 6F
Z_9DED:
	ld (D_93F3),hl	; 9DED 22 F3 93
Z_9DF0:
	ld a,l	; 9DF0 7D
Z_9DF1:
	cp 0x41	; 9DF1 FE 41
Z_9DF3:
	jp c,Z_9DF9	; 9DF3 38 04
Z_9DF5:
	cp 0x6E	; 9DF5 FE 6E
Z_9DF7:
	jp c,Z_9E05	; 9DF7 38 0C
Z_9DF9:
	rst 0x08	; 9DF9 DD CB 00 66
	db 0x00, 0x10
Z_9DFD:
	jp z,Z_9E05	; 9DFD 28 06
Z_9DFF:
	ld e,0x03	; 9DFF 1E 03
Z_9E01:
	call Z_9919	; 9E01 CD 19 99
Z_9E04:
	ret	; 9E04 C9
Z_9E05:
	rst 0x08	; 9E05 DD CB 00 66
	db 0x00, 0x10
Z_9E09:
	jp nz,Z_9E10	; 9E09 20 05
Z_9E0B:
	rst 0x30	; 9E0B DD CB 01 A6
	db 0x01, 0xEF
Z_9E0F:
	ret	; 9E0F C9
Z_9E10:
	rst 0x08	; 9E10 DD CB 01 66
	db 0x01, 0x10
Z_9E14:
	rst 0x10	; 9E14 DD 7E 03
	db 0x03
Z_9E17:
	jp nz,Z_9E2F	; 9E17 20 16
Z_9E19:
	rst 0x08	; 9E19 DD CB 01 46
	db 0x01, 0x01
Z_9E1D:
	jp z,Z_9E27	; 9E1D 28 08
Z_9E1F:
	cp 0x3E	; 9E1F FE 3E
Z_9E21:
	ret c	; 9E21 D8
Z_9E22:
	rst 0x28	; 9E22 DD CB 01 E6
	db 0x01, 0x10
Z_9E26:
	ret	; 9E26 C9
Z_9E27:
	cp 0x38	; 9E27 FE 38
Z_9E29:
	ret nc	; 9E29 D0
Z_9E2A:
	rst 0x28	; 9E2A DD CB 01 E6
	db 0x01, 0x10
Z_9E2E:
	ret	; 9E2E C9
Z_9E2F:
	rst 0x08	; 9E2F DD CB 01 46
	db 0x01, 0x01
Z_9E33:
	jp z,Z_9E3A	; 9E33 28 05
Z_9E35:
	cp 0x3E	; 9E35 FE 3E
Z_9E37:
	ret nc	; 9E37 D0
Z_9E38:
	jp Z_9E3D	; 9E38 18 03
Z_9E3A:
	cp 0x38	; 9E3A FE 38
Z_9E3C:
	ret c	; 9E3C D8
Z_9E3D:
	ld e,0x05	; 9E3D 1E 05
Z_9E3F:
	call Z_9919	; 9E3F CD 19 99
Z_9E42:
	rst 0x30	; 9E42 DD CB 01 A6
	db 0x01, 0xEF
Z_9E46:
	ret	; 9E46 C9
Z_9E47:
	rst 0x10	; 9E47 DD 7E 0A
	db 0x0A
Z_9E4A:
	and a	; 9E4A A7
Z_9E4B:
	jp nz,Z_9E57	; 9E4B 20 0A
Z_9E4D:
	rst 0x10	; 9E4D DD 7E FB
	db 0xFB
Z_9E50:
	inc a	; 9E50 3C
Z_9E51:
	and 0x01	; 9E51 E6 01
Z_9E53:
	rst 0x20	; 9E53 DD 77 FB
	db 0xFB
Z_9E56:
	ret	; 9E56 C9
Z_9E57:
	rst 0x08	; 9E57 DD CB 00 66
	db 0x00, 0x10
Z_9E5B:
	ret z	; 9E5B C8
Z_9E5C:
	ld a,(D_93EB)	; 9E5C 3A EB 93
Z_9E5F:
	ld (il_a),a	; 9E5F CB 77
	and 0x40
	ld a,(il_a)
Z_9E61:
	ret z	; 9E61 C8
Z_9E62:
	call il_ix_dec	; 9E62 DD 35 FA
	db 0xFA
Z_9E65:
	ret nz	; 9E65 C0
Z_9E66:
	ld a,(D_93EB)	; 9E66 3A EB 93
Z_9E69:
	push af	; 9E69 CB B7
	and 0xBF
	ld (il_a),a
	pop af
	ld a,(il_a)
Z_9E6B:
	ld (D_93EB),a	; 9E6B 32 EB 93
Z_9E6E:
	ret	; 9E6E C9
Z_9E6F:
	add a,a	; 9E6F 87
Z_9E70:
	ld l,a	; 9E70 6F
Z_9E71:
	ld h,0x00	; 9E71 26 00
Z_9E73:
	ld de,0x7760	; 9E73 11 60 77
Z_9E76:
	add hl,de	; 9E76 19
Z_9E77:
	ld e,(hl)	; 9E77 5E
Z_9E78:
	inc hl	; 9E78 23
Z_9E79:
	ld d,(hl)	; 9E79 56
Z_9E7A:
	ld hl,0x415A	; 9E7A 21 5A 41
Z_9E7D:
	add hl,de	; 9E7D 19
Z_9E7E:
	ld (BLIT_SRC),hl	; 9E7E 22 02 33
Z_9E81:
	ret	; 9E81 C9
Z_9E82:
	ld a,(D_93D6)	; 9E82 3A D6 93
Z_9E85:
	and a	; 9E85 A7
Z_9E86:
	ret nz	; 9E86 C0
Z_9E87:
	ld a,(D_93D3)	; 9E87 3A D3 93
Z_9E8A:
	dec a	; 9E8A 3D
Z_9E8B:
	ret z	; 9E8B C8
Z_9E8C:
	rst 0x10	; 9E8C DD 7E 0A
	db 0x0A
Z_9E8F:
	cp 0x16	; 9E8F FE 16
Z_9E91:
	ret nc	; 9E91 D0
Z_9E92:
	ld a,0x01	; 9E92 3E 01
Z_9E94:
	ld b,a	; 9E94 47
Z_9E95:
	call il_ix_ldc	; 9E95 DD 4E 09
	db 0x09
Z_9E98:
	ld (il_a),a	; 9E98 CB 79
	ld a,c
	and 0x80
	ld a,(il_a)
Z_9E9A:
	jp z,Z_9EA5	; 9E9A 28 09
Z_9E9C:
	ld b,a	; 9E9C 47
Z_9E9D:
	push af	; 9E9D CB B9
	ld a,c
	and 0x7F
	ld c,a
	pop af
Z_9E9F:
	sub c	; 9E9F 91
Z_9EA0:
	jp nc,Z_9EA3	; 9EA0 30 01
Z_9EA2:
	xor a	; 9EA2 AF
Z_9EA3:
	ld c,a	; 9EA3 4F
Z_9EA4:
	ld a,b	; 9EA4 78
Z_9EA5:
	inc c	; 9EA5 0C
Z_9EA6:
	cp c	; 9EA6 B9
Z_9EA7:
	jp nc,Z_9EAB	; 9EA7 30 02
Z_9EA9:
	ld c,0x00	; 9EA9 0E 00
Z_9EAB:
	call il_ix_stc	; 9EAB DD 71 09
	db 0x09
Z_9EAE:
	ret nc	; 9EAE D0
Z_9EAF:
	ld hl,0x1001	; 9EAF 21 01 10
Z_9EB2:
	rst 0x08	; 9EB2 DD CB 01 46
	db 0x01, 0x01
Z_9EB6:
	jp nz,Z_9EBA	; 9EB6 20 02
Z_9EB8:
	ld l,0x14	; 9EB8 2E 14
Z_9EBA:
	rst 0x10	; 9EBA DD 7E 0A
	db 0x0A
Z_9EBD:
	inc a	; 9EBD 3C
Z_9EBE:
	rst 0x20	; 9EBE DD 77 0A
	db 0x0A
Z_9EC1:
	dec a	; 9EC1 3D
Z_9EC2:
	ld d,0x00	; 9EC2 16 00
Z_9EC4:
	ld e,a	; 9EC4 5F
Z_9EC5:
	ld (il_a),a	; 9EC5 CB 3B
	ld a,e
	or a
	rra
	ld e,a
	ld a,(il_a)
Z_9EC7:
	add hl,de	; 9EC7 19
Z_9EC8:
	ld c,0xE0	; 9EC8 0E E0
Z_9ECA:
	ld (il_a),a	; 9ECA CB 47
	and 0x01
	ld a,(il_a)
Z_9ECC:
	jp z,Z_9F48	; 9ECC CA 48 9F
Z_9ECF:
	ld c,0xEE	; 9ECF 0E EE
Z_9ED1:
	jp Z_9F48	; 9ED1 C3 48 9F
Z_9ED4:
	ld a,(D_93D6)	; 9ED4 3A D6 93
Z_9ED7:
	and a	; 9ED7 A7
Z_9ED8:
	ret nz	; 9ED8 C0
Z_9ED9:
	ld a,(D_93D3)	; 9ED9 3A D3 93
Z_9EDC:
	dec a	; 9EDC 3D
Z_9EDD:
	ret z	; 9EDD C8
Z_9EDE:
	push af	; 9EDE DD 7E 0A
	ld (il_tmp2),hl
	ld hl,(z80_ix)
	ld a,l
	add a,10
	ld l,a
	ld a,h
	adc a,0
	ld h,a
	ld a,(hl)
	ld (il_a),a
	ld hl,(il_tmp2)
	pop af
	ld a,(il_a)
Z_9EE1:
	and a	; 9EE1 A7
Z_9EE2:
	ret z	; 9EE2 C8
Z_9EE3:
	ld a,0x07	; 9EE3 3E 07
Z_9EE5:
	ld b,a	; 9EE5 47
Z_9EE6:
	call il_ix_ldc	; 9EE6 DD 4E 09
	db 0x09
Z_9EE9:
	ld (il_a),a	; 9EE9 CB 79
	ld a,c
	and 0x80
	ld a,(il_a)
Z_9EEB:
	jp nz,Z_9EF4	; 9EEB 20 07
Z_9EED:
	ld b,a	; 9EED 47
Z_9EEE:
	sub c	; 9EEE 91
Z_9EEF:
	jp nc,Z_9EF2	; 9EEF 30 01
Z_9EF1:
	xor a	; 9EF1 AF
Z_9EF2:
	ld c,a	; 9EF2 4F
Z_9EF3:
	ld a,b	; 9EF3 78
Z_9EF4:
	push af	; 9EF4 CB B9
	ld a,c
	and 0x7F
	ld c,a
	pop af
Z_9EF6:
	inc c	; 9EF6 0C
Z_9EF7:
	cp c	; 9EF7 B9
Z_9EF8:
	jp nc,Z_9EFC	; 9EF8 30 02
Z_9EFA:
	ld c,0x00	; 9EFA 0E 00
Z_9EFC:
	push af	; 9EFC CB F9
	ld a,c
	or 0x80
	ld c,a
	pop af
Z_9EFE:
	call il_ix_stc	; 9EFE DD 71 09
	db 0x09
Z_9F01:
	ret nc	; 9F01 D0
Z_9F02:
	ld hl,0x1001	; 9F02 21 01 10
Z_9F05:
	rst 0x08	; 9F05 DD CB 01 46
	db 0x01, 0x01
Z_9F09:
	jp nz,Z_9F0D	; 9F09 20 02
Z_9F0B:
	ld l,0x14	; 9F0B 2E 14
Z_9F0D:
	rst 0x10	; 9F0D DD 7E 0A
	db 0x0A
Z_9F10:
	dec a	; 9F10 3D
Z_9F11:
	rst 0x20	; 9F11 DD 77 0A
	db 0x0A
Z_9F14:
	inc a	; 9F14 3C
Z_9F15:
	ld d,0x00	; 9F15 16 00
Z_9F17:
	ld e,a	; 9F17 5F
Z_9F18:
	ld (il_a),a	; 9F18 CB 3B
	ld a,e
	or a
	rra
	ld e,a
	ld a,(il_a)
Z_9F1A:
	add hl,de	; 9F1A 19
Z_9F1B:
	ld c,d	; 9F1B 4A
Z_9F1C:
	ld (il_a),a	; 9F1C CB 47
	and 0x01
	ld a,(il_a)
Z_9F1E:
	jp nz,Z_9F48	; 9F1E 20 28
Z_9F20:
	ld c,0xE0	; 9F20 0E E0
Z_9F22:
	dec l	; 9F22 2D
Z_9F23:
	jp Z_9F48	; 9F23 18 23
Z_9F25:
	ld hl,0x1001	; 9F25 21 01 10
Z_9F28:
	ld a,(D_9415)	; 9F28 3A 15 94
Z_9F2B:
	ld c,0xEE	; 9F2B 0E EE
Z_9F2D:
	call Z_9F36	; 9F2D CD 36 9F
Z_9F30:
	ld hl,0x1014	; 9F30 21 14 10
Z_9F33:
	ld a,(D_942F)	; 9F33 3A 2F 94
Z_9F36:
	and a	; 9F36 A7
Z_9F37:
	ret z	; 9F37 C8
Z_9F38:
	ld b,a	; 9F38 47
Z_9F39:
	ld (il_a),a	; 9F39 CB 38
	ld a,b
	or a
	rra
	or a
	ld b,a
	ld a,(il_a)
Z_9F3B:
	jp z,Z_9F43	; 9F3B 28 06
Z_9F3D:
	call Z_9F48	; 9F3D CD 48 9F
Z_9F40:
	inc l	; 9F40 2C
Z_9F41:
	dec b	; 9F41 10 FA
	jp nz,Z_9F3D
Z_9F43:
	ld (il_a),a	; 9F43 CB 47
	and 0x01
	ld a,(il_a)
Z_9F45:
	ret z	; 9F45 C8
Z_9F46:
	ld c,0xE0	; 9F46 0E E0
Z_9F48:
	jp 0x02CE	; 9F48 C3 CE 02
Z_9F60:
	ld hl,Z_9F6E	; 9F60 21 6E 9F
Z_9F63:
	ld (Z_3705+1),hl	; 9F63 22 06 37
Z_9F66:
	ret	; 9F66 C9
Z_9F67:
	ld hl,Z_9F6D	; 9F67 21 6D 9F
Z_9F6A:
	ld (Z_3705+1),hl	; 9F6A 22 06 37
Z_9F6D:
	ret	; 9F6D C9
Z_9F6E:
	call Z_3715	; 9F6E CD 15 37
Z_9F71:
	ld a,(D_93E6)	; 9F71 3A E6 93
Z_9F74:
	inc a	; 9F74 3C
Z_9F75:
	cp 0x32	; 9F75 FE 32
Z_9F77:
	jp c,Z_9F7A	; 9F77 38 01
Z_9F79:
	xor a	; 9F79 AF
Z_9F7A:
	ld (D_93E6),a	; 9F7A 32 E6 93
Z_9F7D:
	ret c	; 9F7D D8
Z_9F7E:
	ld a,0x2F	; 9F7E 3E 2F
Z_9F80:
	ld hl,D_93E9	; 9F80 21 E9 93
Z_9F83:
	dec (hl)	; 9F83 35
Z_9F84:
	cp (hl)	; 9F84 BE
Z_9F85:
	ret nz	; 9F85 C0
Z_9F86:
	ld (hl),0x39	; 9F86 36 39
Z_9F88:
	dec hl	; 9F88 2B
Z_9F89:
	dec (hl)	; 9F89 35
Z_9F8A:
	cp (hl)	; 9F8A BE
Z_9F8B:
	ret nz	; 9F8B C0
Z_9F8C:
	ld (hl),0x35	; 9F8C 36 35
Z_9F8E:
	dec hl	; 9F8E 2B
Z_9F8F:
	dec (hl)	; 9F8F 35
Z_9F90:
	cp (hl)	; 9F90 BE
Z_9F91:
	ret nz	; 9F91 C0
Z_9F92:
	ld a,0x01	; 9F92 3E 01
Z_9F94:
	ld (D_93E5),a	; 9F94 32 E5 93
Z_9F97:
	jp Z_9F67	; 9F97 C3 67 9F
Z_9F9A:
	ld a,(D_93E5)	; 9F9A 3A E5 93
Z_9F9D:
	and a	; 9F9D A7
Z_9F9E:
	ret nz	; 9F9E C0
Z_9F9F:
	ld hl,0x0E14	; 9F9F 21 14 0E
Z_9FA2:
	ld (TEXT_ROW),hl	; 9FA2 22 02 41
Z_9FA5:
	ld a,0xF1	; 9FA5 3E F1
Z_9FA7:
	ld (D_3424),a	; 9FA7 32 24 34
Z_9FAA:
	ld hl,D_93E7	; 9FAA 21 E7 93
Z_9FAD:
	ld a,(hl)	; 9FAD 7E
Z_9FAE:
	call Z_A063	; 9FAE CD 63 A0
Z_9FB1:
	ld a,0x3A	; 9FB1 3E 3A
Z_9FB3:
	call Z_A063	; 9FB3 CD 63 A0
Z_9FB6:
	inc hl	; 9FB6 23
Z_9FB7:
	ld a,(hl)	; 9FB7 7E
Z_9FB8:
	call Z_A063	; 9FB8 CD 63 A0
Z_9FBB:
	inc hl	; 9FBB 23
Z_9FBC:
	ld a,(hl)	; 9FBC 7E
Z_9FBD:
	jp Z_A063	; 9FBD C3 63 A0
Z_9FC0:
	ld hl,0x0112	; 9FC0 21 12 01
Z_9FC3:
	ld (TEXT_ROW),hl	; 9FC3 22 02 41
Z_9FC6:
	ld a,(D_9416)	; 9FC6 3A 16 94
Z_9FC9:
	call Z_9FD4	; 9FC9 CD D4 9F
Z_9FCC:
	ld a,0x14	; 9FCC 3E 14
Z_9FCE:
	ld (TEXT_COL),a	; 9FCE 32 03 41
Z_9FD1:
	ld a,(D_9430)	; 9FD1 3A 30 94
Z_9FD4:
	ld c,a	; 9FD4 4F
Z_9FD5:
	inc c	; 9FD5 0C
Z_9FD6:
	ld b,0x05	; 9FD6 06 05
Z_9FD8:
	push bc	; 9FD8 C5
Z_9FD9:
	ld a,0x06	; 9FD9 3E 06
Z_9FDB:
	sub b	; 9FDB 90
Z_9FDC:
	cp c	; 9FDC B9
Z_9FDD:
	ld a,0x91	; 9FDD 3E 91
Z_9FDF:
	jp c,Z_9FE3	; 9FDF 38 02
Z_9FE1:
	ld a,0xF1	; 9FE1 3E F1
Z_9FE3:
	ld (D_3424),a	; 9FE3 32 24 34
Z_9FE6:
	pop bc	; 9FE6 C1
Z_9FE7:
	ld a,0x06	; 9FE7 3E 06
Z_9FE9:
	sub b	; 9FE9 90
Z_9FEA:
	add a,0x30	; 9FEA C6 30
Z_9FEC:
	call Z_A063	; 9FEC CD 63 A0
Z_9FEF:
	dec b	; 9FEF 10 E7
	jp nz,Z_9FD8
Z_9FF1:
	ret	; 9FF1 C9
Z_9FF2:
	ld hl,0x0812	; 9FF2 21 12 08
Z_9FF5:
	ld (TEXT_ROW),hl	; 9FF5 22 02 41
Z_9FF8:
	ld a,0xA1	; 9FF8 3E A1
Z_9FFA:
	ld (D_3424),a	; 9FFA 32 24 34
Z_9FFD:
	ld a,(D_9401)	; 9FFD 3A 01 94
Z_A000:
	call Z_A037	; A000 CD 37 A0
Z_A003:
	ld a,0x1B	; A003 3E 1B
Z_A005:
	ld (TEXT_COL),a	; A005 32 03 41
Z_A008:
	ld a,(D_9402)	; A008 3A 02 94
Z_A00B:
	jp Z_A037	; A00B C3 37 A0
Z_A00E:
	ld a,0xF1	; A00E 3E F1
Z_A010:
	ld (D_3424),a	; A010 32 24 34
Z_A013:
	ld de,D_9452	; A013 11 52 94
Z_A016:
	ld hl,0x0114	; A016 21 14 01
Z_A019:
	call Z_A01F	; A019 CD 1F A0
Z_A01C:
	ld hl,0x1414	; A01C 21 14 14
	jp	Z_A01F	; мост в следующий кусок
	org	0xA06F
D_A06F:
Z_A06F:
	db	0x83, 0xF8, 0xF5, 0xC5, 0xD5, 0xE5, 0xCD, 0xEB, 0xD8, 0xE1, 0xD1, 0xC1, 0xF1, 0xC9, 0xD8, 0xE1	; A06F
	org	0xA07F
D_A07F:
Z_A07F:
	db	0xD1, 0xC1, 0xF1, 0xC9, 0xBE, 0xA0, 0x18, 0xF6, 0xE5, 0xD5, 0x6F, 0x26, 0x00	; A07F
	org	0xA08C
Z_A01F:
	ld (TEXT_ROW),hl	; A01F 22 02 41
Z_A022:
	ld a,(de)	; A022 1A
Z_A023:
	inc de	; A023 13
Z_A024:
	cp 0xFF	; A024 FE FF
Z_A026:
	ret z	; A026 C8
Z_A027:
	call Z_A063	; A027 CD 63 A0
Z_A02A:
	jp Z_A022	; A02A 18 F6
Z_A02C:
	push hl	; A02C E5
Z_A02D:
	push de	; A02D D5
Z_A02E:
	ld l,a	; A02E 6F
Z_A02F:
	ld h,0x00	; A02F 26 00
Z_A031:
	ld b,0xFF	; A031 06 FF
	jp	Z_A033	; мост в следующий кусок
	org	0xA0A4
D_A0A4:
Z_A0A4:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; A0A4
	org	0xA0AD
D_A0AD:
Z_A0AD:
	db	0xC3, 0x5F, 0xA7	; A0AD
	org	0xA0B0
Z_A033:
	ld e,0x30	; A033 1E 30
Z_A035:
	jp Z_A049	; A035 18 12
Z_A037:
	ld c,0x30	; A037 0E 30
Z_A039:
	jp Z_A03D	; A039 18 02
Z_A03B:
	ld c,0x20	; A03B 0E 20
Z_A03D:
	push hl	; A03D E5
Z_A03E:
	push de	; A03E D5
Z_A03F:
	ld l,a	; A03F 6F
Z_A040:
	ld h,0x00	; A040 26 00
Z_A042:
	ld e,c	; A042 59
Z_A043:
	ld bc,0xFF9C	; A043 01 9C FF
Z_A046:
	call Z_A055	; A046 CD 55 A0
Z_A049:
	ld c,0xF6	; A049 0E F6
Z_A04B:
	call Z_A055	; A04B CD 55 A0
	jp	Z_A04E	; мост в следующий кусок
	org	0xA133
Z_A04E:
	ld a,l	; A04E 7D
Z_A04F:
	call Z_A05F	; A04F CD 5F A0
Z_A052:
	pop de	; A052 D1
Z_A053:
	pop hl	; A053 E1
Z_A054:
	ret	; A054 C9
Z_A055:
	xor a	; A055 AF
Z_A056:
	add hl,bc	; A056 09
Z_A057:
	inc a	; A057 3C
Z_A058:
	jp c,Z_A056	; A058 38 FC
Z_A05A:
	ld (il_a),a	; A05A ED 42
	ld a,l
	sbc a,c
	ld l,a
	ld a,h
	sbc a,b
	ld h,a
	ld a,(il_a)
Z_A05C:
	dec a	; A05C 3D
Z_A05D:
	jp z,Z_A061	; A05D 28 02
Z_A05F:
	ld e,0x30	; A05F 1E 30
Z_A061:
	add a,e	; A061 83
Z_A062:
	ret m	; A062 F8
Z_A063:
	push af	; A063 F5
Z_A064:
	push bc	; A064 C5
Z_A065:
	push de	; A065 D5
Z_A066:
	push hl	; A066 E5
	jp	Z_A067	; мост в следующий кусок
	org	0xA15C
D_A15C:
Z_A15C:
	db	0x00, 0x00, 0x00, 0x00	; A15C
	org	0xA160
Z_A067:
	call Z_3B53	; A067 CD 53 3B
Z_A06A:
	pop hl	; A06A E1
Z_A06B:
	pop de	; A06B D1
Z_A06C:
	pop bc	; A06C C1
Z_A06D:
	pop af	; A06D F1
Z_A06E:
	ret	; A06E C9
Z_A08C:
	jp Z_A0BF	; A08C C3 BF A0
Z_A08F:
	jp Z_A1AA	; A08F C3 AA A1
Z_A092:
	jp Z_A502	; A092 C3 02 A5
Z_A095:
	jp Z_A5FD	; A095 C3 FD A5
Z_A098:
	jp Z_A82C	; A098 C3 2C A8
Z_A09B:
	jp Z_A95E	; A09B C3 5E A9
Z_A09E:
	jp Z_A969	; A09E C3 69 A9
Z_A0A1:
	jp Z_A53A	; A0A1 C3 3A A5
Z_A0AA:
	jp Z_A0B0	; A0AA C3 B0 A0
Z_A0B0:
	ld l,a	; A0B0 6F
Z_A0B1:
	xor a	; A0B1 AF
Z_A0B2:
	ld b,0x08	; A0B2 06 08
Z_A0B4:
	add a,a	; A0B4 87
Z_A0B5:
	ret c	; A0B5 D8
Z_A0B6:
	ld (il_a),a	; A0B6 CB 11
	ld a,c
	rla
	ld c,a
	ld a,(il_a)
Z_A0B8:
	jp nc,Z_A0BC	; A0B8 30 02
Z_A0BA:
	add a,l	; A0BA 85
Z_A0BB:
	ret c	; A0BB D8
Z_A0BC:
	dec b	; A0BC 10 F6
	jp nz,Z_A0B4
Z_A0BE:
	ret	; A0BE C9
	org	0xA1A4
D_A1A4:
Z_A1A4:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; A1A4
	org	0xA1AA
Z_A0BF:
	ld (il_tmp),hl	; A0BF DD 21 14 33
	ld hl,D_3314
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_A0C3:
	ld c,0x31	; A0C3 0E 31
Z_A0C5:
	call 0xA0D0	; A0C5 CD D0 A0
Z_A0C8:
	call 0xA132	; A0C8 CD 32 A1
Z_A0CB:
	halt	; A0CB 76
Z_A0CC:
	dec c	; A0CC 0D
Z_A0CD:
	jp nz,Z_A0C5	; A0CD 20 F6
Z_A0CF:
	ret	; A0CF C9
Z_A133:
	rst 0x08	; A133 DD CB 01 76
	db 0x01, 0x40
Z_A137:
	ld a,0x10	; A137 3E 10
Z_A139:
	ret z	; A139 C8
Z_A13A:
	ld a,(D_93D2)	; A13A 3A D2 93
Z_A13D:
	and 0x03	; A13D E6 03
Z_A13F:
	cp 0x02	; A13F FE 02
Z_A141:
	jp nc,Z_A158	; A141 30 15
Z_A143:
	push hl	; A143 E5
Z_A144:
	push de	; A144 D5
Z_A145:
	inc a	; A145 3C
Z_A146:
	rrca	; A146 0F
Z_A147:
	rrca	; A147 0F
Z_A148:
	rrca	; A148 0F
Z_A149:
	ld e,a	; A149 5F
Z_A14A:
	call Z_386E	; A14A CD 6E 38
Z_A14D:
	ld a,h	; A14D 7C
Z_A14E:
	cp e	; A14E BB
Z_A14F:
	pop de	; A14F D1
Z_A150:
	pop hl	; A150 E1
Z_A151:
	jp c,Z_A158	; A151 38 05
Z_A153:
	or 0x01	; A153 F6 01
Z_A155:
	ld a,0x00	; A155 3E 00
Z_A157:
	ret	; A157 C9
Z_A158:
	ld a,0x10	; A158 3E 10
Z_A15A:
	or a	; A15A B7
Z_A15B:
	ret	; A15B C9
Z_A160:
	push hl	; A160 E5
Z_A161:
	call Z_386E	; A161 CD 6E 38
Z_A164:
	ld a,h	; A164 7C
Z_A165:
	pop hl	; A165 E1
Z_A166:
	cp 0x64	; A166 FE 64
Z_A168:
	ret	; A168 C9
Z_A169:
	push hl	; A169 E5
Z_A16A:
	call Z_386E	; A16A CD 6E 38
Z_A16D:
	ld a,h	; A16D 7C
Z_A16E:
	pop hl	; A16E E1
Z_A16F:
	and 0x10	; A16F E6 10
Z_A171:
	ret	; A171 C9
Z_A172:
	push hl	; A172 E5
Z_A173:
	call Z_386E	; A173 CD 6E 38
Z_A176:
	ld a,h	; A176 7C
Z_A177:
	pop hl	; A177 E1
Z_A178:
	and 0x0F	; A178 E6 0F
Z_A17A:
	ret	; A17A C9
Z_A17B:
	push hl	; A17B E5
Z_A17C:
	call Z_386E	; A17C CD 6E 38
Z_A17F:
	ld a,h	; A17F 7C
Z_A180:
	pop hl	; A180 E1
Z_A181:
	ld (il_tmp),hl	; A181 DD 21 03 00
	ld hl,0x03
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_A185:
	ret	; A185 C9
Z_A186:
	ld a,(0x0FED)	; A186 3A ED 0F
Z_A189:
	dec a	; A189 3D
Z_A18A:
	ret z	; A18A C8
Z_A18B:
	ld hl,(0x4114)	; A18B 2A 14 41
Z_A18E:
	inc hl	; A18E 23
Z_A18F:
	ld (0x4114),hl	; A18F 22 14 41
Z_A192:
	ret	; A192 C9
Z_A193:
	push hl	; A193 E5
Z_A194:
	push de	; A194 D5
Z_A195:
	ld hl,(0x4114)	; A195 2A 14 41
Z_A198:
	ld de,0x07	; A198 11 07 00
Z_A19B:
	add hl,de	; A19B 19
Z_A19C:
	ld (0x4114),hl	; A19C 22 14 41
Z_A19F:
	pop de	; A19F D1
Z_A1A0:
	pop hl	; A1A0 E1
Z_A1A1:
	jp Z_B1F2	; A1A1 C3 F2 B1
Z_A1AA:
	ld a,(D_93E5)	; A1AA 3A E5 93
Z_A1AD:
	jp c,il_KC13	; A1AD CB 7F
	ld (il_a),a
	and 0x80
	ld a,(il_a)
	jp il_KD14
il_KC13:
	ld (il_a),a
	and 0x80
	scf
	ld a,(il_a)
il_KD14:
Z_A1AF:
	jp z,Z_A1BD	; A1AF 28 0C
Z_A1B1:
	ld hl,0x0806	; A1B1 21 06 08
Z_A1B4:
	ld de,D_A37B	; A1B4 11 7B A3
Z_A1B7:
	call Z_9397	; A1B7 CD 97 93
Z_A1BA:
	inc l	; A1BA 2C
Z_A1BB:
	jp Z_A1C3	; A1BB 18 06
Z_A1BD:
	ld hl,0x0B07	; A1BD 21 07 0B
Z_A1C0:
	ld de,D_A3BF	; A1C0 11 BF A3
Z_A1C3:
	call Z_9397	; A1C3 CD 97 93
Z_A1C6:
	inc l	; A1C6 2C
Z_A1C7:
	call Z_9397	; A1C7 CD 97 93
Z_A1CA:
	inc l	; A1CA 2C
Z_A1CB:
	call Z_9397	; A1CB CD 97 93
Z_A1CE:
	call Z_A9AD	; A1CE CD AD A9
Z_A1D1:
	xor a	; A1D1 AF
Z_A1D2:
	ld (0x0FEF),a	; A1D2 32 EF 0F
Z_A1D5:
	nop	; A1D5 00
Z_A1D6:
	nop	; A1D6 00
Z_A1D7:
	nop	; A1D7 00
Z_A1D8:
	nop	; A1D8 00
Z_A1D9:
	nop	; A1D9 00
Z_A1DA:
	nop	; A1DA 00
Z_A1DB:
	nop	; A1DB 00
Z_A1DC:
	nop	; A1DC 00
Z_A1DD:
	nop	; A1DD 00
Z_A1DE:
	call Z_93A6	; A1DE CD A6 93
Z_A1E1:
	call Z_A0BF	; A1E1 CD BF A0
Z_A1E4:
	ld hl,0x7EF9	; A1E4 21 F9 7E
Z_A1E7:
	ld (BLIT_Y),hl	; A1E7 22 00 33
Z_A1EA:
	call Z_AA7C	; A1EA CD 7C AA
Z_A1ED:
	call Z_A419	; A1ED CD 19 A4
Z_A1F0:
	ld hl,0x0110	; A1F0 21 10 01
Z_A1F3:
	ld bc,0x0528	; A1F3 01 28 05
Z_A1F6:
	ld a,0x17	; A1F6 3E 17
Z_A1F8:
	call Z_A75F	; A1F8 CD 5F A7
Z_A1FB:
	ld (il_tmp),hl	; A1FB DD 21 0B 94
	ld hl,D_940B
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_A1FF:
	ld hl,0x0602	; A1FF 21 02 06
Z_A202:
	call Z_A25D	; A202 CD 5D A2
Z_A205:
	ld hl,0x1A48	; A205 21 48 1A
Z_A208:
	ld bc,0x0528	; A208 01 28 05
Z_A20B:
	ld a,0x17	; A20B 3E 17
Z_A20D:
	call Z_A75F	; A20D CD 5F A7
Z_A210:
	ld (il_tmp),hl	; A210 DD 21 25 94
	ld hl,D_9425
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_A214:
	ld hl,0x0109	; A214 21 09 01
Z_A217:
	call Z_A25D	; A217 CD 5D A2
Z_A21A:
	ld a,0xFF	; A21A 3E FF
Z_A21C:
	ld (D_9451),a	; A21C 32 51 94
Z_A21F:
	call Z_A472	; A21F CD 72 A4
Z_A222:
	call Z_A232	; A222 CD 32 A2
Z_A225:
	call Z_37CC	; A225 CD CC 37
Z_A228:
	call Z_3811	; A228 CD 11 38
Z_A22B:
	ld a,(G_KEY_ASCII)	; A22B 3A 10 41
Z_A22E:
	inc a	; A22E 3C
Z_A22F:
	jp z,Z_A21F	; A22F 28 EE
Z_A231:
	ret	; A231 C9
Z_A232:
	ld a,(D_93E5)	; A232 3A E5 93
Z_A235:
	ld (il_a),a	; A235 CB 7F
	and 0x80
	ld a,(il_a)
Z_A237:
	jp nz,Z_A23E	; A237 20 05
Z_A239:
	ld a,0x05	; A239 3E 05
Z_A23B:
	jp Z_3A2C	; A23B C3 2C 3A
Z_A23E:
	ld a,(D_9451)	; A23E 3A 51 94
Z_A241:
	inc a	; A241 3C
Z_A242:
	and 0x0F	; A242 E6 0F
Z_A244:
	ld (D_9451),a	; A244 32 51 94
Z_A247:
	call Z_37BD	; A247 CD BD 37
Z_A24A:
	ld de,D_A362	; A24A 11 62 A3
Z_A24D:
	ld hl,0x0703	; A24D 21 03 07
Z_A250:
	ld a,(D_9400)	; A250 3A 00 94
Z_A253:
	ld (il_a),a	; A253 CB 7F
	and 0x80
	ld a,(il_a)
Z_A255:
	jp z,Z_A25A	; A255 28 03
Z_A257:
	ld hl,0x020A	; A257 21 0A 02
Z_A25A:
	jp Z_9397	; A25A C3 97 93
Z_A25D:
	call Z_A472	; A25D CD 72 A4
Z_A260:
	ld a,0xF1	; A260 3E F1
Z_A262:
	ld (D_3424),a	; A262 32 24 34
Z_A265:
	ld de,D_A3E3	; A265 11 E3 A3
Z_A268:
	call Z_9397	; A268 CD 97 93
Z_A26B:
	ld b,0x06	; A26B 06 06
Z_A26D:
	call Z_A32C	; A26D CD 2C A3
Z_A270:
	ld a,0xF1	; A270 3E F1
Z_A272:
	ld (D_3424),a	; A272 32 24 34
Z_A275:
	rst 0x10	; A275 DD 7E 0D
	db 0x0D
Z_A278:
	call Z_93C1	; A278 CD C1 93
Z_A27B:
	ld a,0x2F	; A27B 3E 2F
Z_A27D:
	call Z_9376	; A27D CD 76 93
Z_A280:
	rst 0x10	; A280 DD 7E 0C
	db 0x0C
Z_A283:
	call Z_93C1	; A283 CD C1 93
Z_A286:
	ld a,0x20	; A286 3E 20
Z_A288:
	call Z_9376	; A288 CD 76 93
Z_A28B:
	call il_ix_ldc	; A28B DD 4E 0C
	db 0x0C
Z_A28E:
	call il_ix_ldb	; A28E DD 46 0D
	db 0x0D
Z_A291:
	call Z_A341	; A291 CD 41 A3
Z_A294:
	call Z_A472	; A294 CD 72 A4
Z_A297:
	inc l	; A297 2C
	jp	Z_A298	; мост в следующий кусок
	org	0xA362
D_A362:
Z_A362:
	db	0x46, 0x4F, 0x55, 0x4C, 0x45, 0x44, 0x20, 0x4F, 0x55, 0x54, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20	; A362
	org	0xA372
D_A372:
Z_A372:
	db	0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0xFF	; A372
	org	0xA37B
D_A37B:
Z_A37B:
	db	0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20	; A37B
	org	0xA38B
D_A38B:
Z_A38B:
	db	0xFF, 0x20, 0x20, 0x47, 0x41, 0x4D, 0x45, 0x20, 0x20, 0x20, 0x4F, 0x56, 0x45, 0x52, 0x20, 0x20	; A38B
	org	0xA39B
D_A39B:
Z_A39B:
	db	0x20, 0xFF, 0x20, 0x20, 0x20, 0x20, 0x4F, 0x4E, 0x20, 0x46, 0x4F, 0x55, 0x4C, 0x53, 0x20, 0x20	; A39B
	org	0xA3AB
D_A3AB:
Z_A3AB:
	db	0x20, 0x20, 0xFF, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20	; A3AB
	org	0xA3BB
D_A3BB:
Z_A3BB:
	db	0x20, 0x20, 0x20, 0xFF	; A3BB
	org	0xA3BF
D_A3BF:
Z_A3BF:
	db	0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0xFF, 0x20, 0x20, 0x54, 0x49	; A3BF
	org	0xA3CF
D_A3CF:
Z_A3CF:
	db	0x4D, 0x45, 0x20, 0x21, 0x21, 0x20, 0x20, 0xFF, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20	; A3CF
	org	0xA3DF
D_A3DF:
Z_A3DF:
	db	0x20, 0x20, 0x20, 0xFF	; A3DF
	org	0xA3E3
D_A3E3:
Z_A3E3:
	db	0x20, 0x42, 0x41, 0x53, 0x4B, 0x45, 0x54, 0x53, 0x20, 0xFF, 0x20, 0x46, 0x4F, 0x55, 0x4C, 0x53	; A3E3
	org	0xA3F3
D_A3F3:
Z_A3F3:
	db	0x20, 0x20, 0x20, 0x20, 0x20, 0xFF, 0x20, 0x46, 0x52, 0x45, 0x45, 0x20, 0x54, 0x48, 0x52, 0x4F	; A3F3
	org	0xA403
D_A403:
Z_A403:
	db	0x57, 0x53, 0x20, 0xFF, 0x20, 0x42, 0x4F, 0x41, 0x52, 0x44, 0x53, 0x20, 0xFF, 0x20, 0x54, 0x48	; A403
	org	0xA413
D_A413:
Z_A413:
	db	0x52, 0x45, 0x45, 0x53, 0x20, 0xFF	; A413
	org	0xA419
Z_A298:
	call Z_9397	; A298 CD 97 93
Z_A29B:
	ld b,0x07	; A29B 06 07
Z_A29D:
	call Z_A32C	; A29D CD 2C A3
Z_A2A0:
	ld a,0xF1	; A2A0 3E F1
Z_A2A2:
	ld (D_3424),a	; A2A2 32 24 34
Z_A2A5:
	rst 0x10	; A2A5 DD 7E 0B
	db 0x0B
Z_A2A8:
	call Z_93C1	; A2A8 CD C1 93
Z_A2AB:
	ld b,0x05	; A2AB 06 05
Z_A2AD:
	call Z_A337	; A2AD CD 37 A3
Z_A2B0:
	call Z_A472	; A2B0 CD 72 A4
Z_A2B3:
	inc l	; A2B3 2C
Z_A2B4:
	call Z_9397	; A2B4 CD 97 93
Z_A2B7:
	ld b,0x02	; A2B7 06 02
Z_A2B9:
	call Z_A32C	; A2B9 CD 2C A3
Z_A2BC:
	ld a,0xF1	; A2BC 3E F1
Z_A2BE:
	ld (D_3424),a	; A2BE 32 24 34
Z_A2C1:
	rst 0x10	; A2C1 DD 7E 0F
	db 0x0F
Z_A2C4:
	call Z_93C1	; A2C4 CD C1 93
Z_A2C7:
	ld a,0x2F	; A2C7 3E 2F
Z_A2C9:
	call Z_9376	; A2C9 CD 76 93
Z_A2CC:
	rst 0x10	; A2CC DD 7E 0E
	db 0x0E
Z_A2CF:
	call Z_93C1	; A2CF CD C1 93
Z_A2D2:
	ld a,0x20	; A2D2 3E 20
Z_A2D4:
	call Z_9376	; A2D4 CD 76 93
Z_A2D7:
	call il_ix_ldc	; A2D7 DD 4E 0E
	db 0x0E
Z_A2DA:
	call il_ix_ldb	; A2DA DD 46 0F
	db 0x0F
Z_A2DD:
	call Z_A341	; A2DD CD 41 A3
Z_A2E0:
	call Z_A472	; A2E0 CD 72 A4
Z_A2E3:
	inc l	; A2E3 2C
Z_A2E4:
	call Z_9397	; A2E4 CD 97 93
Z_A2E7:
	ld b,0x0A	; A2E7 06 0A
Z_A2E9:
	call Z_A32C	; A2E9 CD 2C A3
Z_A2EC:
	ld a,0xF1	; A2EC 3E F1
Z_A2EE:
	ld (D_3424),a	; A2EE 32 24 34
Z_A2F1:
	rst 0x10	; A2F1 DD 7E 10
	db 0x10
Z_A2F4:
	call Z_93C1	; A2F4 CD C1 93
Z_A2F7:
	ld b,0x05	; A2F7 06 05
Z_A2F9:
	call Z_A337	; A2F9 CD 37 A3
Z_A2FC:
	call Z_A472	; A2FC CD 72 A4
Z_A2FF:
	inc l	; A2FF 2C
Z_A300:
	call Z_9397	; A300 CD 97 93
Z_A303:
	ld b,0x07	; A303 06 07
Z_A305:
	call Z_A32C	; A305 CD 2C A3
Z_A308:
	ld a,0xF1	; A308 3E F1
Z_A30A:
	ld (D_3424),a	; A30A 32 24 34
Z_A30D:
	rst 0x10	; A30D DD 7E 12
	db 0x12
Z_A310:
	call Z_93C1	; A310 CD C1 93
	jp	Z_A313	; мост в следующий кусок
	org	0xA494
D_A494:
Z_A494:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; A494
	org	0xA49F
D_A49F:
Z_A49F:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; A49F
	org	0xA4A8
Z_A313:
	ld a,0x2F	; A313 3E 2F
Z_A315:
	call Z_9376	; A315 CD 76 93
Z_A318:
	rst 0x10	; A318 DD 7E 11
	db 0x11
Z_A31B:
	call Z_93C1	; A31B CD C1 93
Z_A31E:
	ld a,0x20	; A31E 3E 20
Z_A320:
	call Z_9376	; A320 CD 76 93
Z_A323:
	call il_ix_ldc	; A323 DD 4E 11
	db 0x11
Z_A326:
	call il_ix_ldb	; A326 DD 46 12
	db 0x12
Z_A329:
	jp Z_A341	; A329 C3 41 A3
Z_A32C:
	push bc	; A32C C5
Z_A32D:
	ld a,0x71	; A32D 3E 71
Z_A32F:
	ld (D_3424),a	; A32F 32 24 34
Z_A332:
	pop bc	; A332 C1
Z_A333:
	ld a,0x2E	; A333 3E 2E
Z_A335:
	jp Z_A339	; A335 18 02
Z_A337:
	ld a,0x20	; A337 3E 20
Z_A339:
	push af	; A339 F5
Z_A33A:
	call Z_9376	; A33A CD 76 93
Z_A33D:
	pop af	; A33D F1
	jp	Z_A33E	; мост в следующий кусок
	org	0xA4DB
D_A4DB:
Z_A4DB:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC9	; A4DB
	org	0xA4E7
Z_A33E:
	dec b	; A33E 10 F9
	jp nz,Z_A339
Z_A340:
	ret	; A340 C9
Z_A341:
	push hl	; A341 E5
Z_A342:
	push de	; A342 D5
Z_A343:
	ld e,c	; A343 59
Z_A344:
	ld l,b	; A344 68
Z_A345:
	ld bc,0x64	; A345 01 64 00
Z_A348:
	ld a,e	; A348 7B
Z_A349:
	and a	; A349 A7
Z_A34A:
	jp z,Z_A357	; A34A 28 0B
Z_A34C:
	ld d,b	; A34C 50
Z_A34D:
	ld h,b	; A34D 60
Z_A34E:
	call Z_398C	; A34E CD 8C 39
Z_A351:
	ld c,e	; A351 4B
Z_A352:
	ld b,d	; A352 42
Z_A353:
	call Z_39A3	; A353 CD A3 39
Z_A356:
	ld a,l	; A356 7D
Z_A357:
	call Z_93AF	; A357 CD AF 93
Z_A35A:
	ld a,0x25	; A35A 3E 25
Z_A35C:
	call Z_9376	; A35C CD 76 93
Z_A35F:
	pop de	; A35F D1
Z_A360:
	pop hl	; A360 E1
Z_A361:
	ret	; A361 C9
Z_A419:
	ld hl,0x7E2C	; A419 21 2C 7E
Z_A41C:
	ld (D_940D),hl	; A41C 22 0D 94
Z_A41F:
	ld hl,0xF864	; A41F 21 64 F8
Z_A422:
	ld (D_9427),hl	; A422 22 27 94
Z_A425:
	ld a,0x10	; A425 3E 10
	jp	Z_A427	; мост в следующий кусок
	org	0xA535
D_A535:
Z_A535:
	db	0x00, 0x00, 0x00, 0x00, 0x00	; A535
	org	0xA53A
Z_A427:
	ld (D_940B),a	; A427 32 0B 94
Z_A42A:
	ld (D_9425),a	; A42A 32 25 94
Z_A42D:
	ld hl,0x0404	; A42D 21 04 04
Z_A430:
	ld (D_9409),hl	; A430 22 09 94
Z_A433:
	ld hl,0x0C0C	; A433 21 0C 0C
Z_A436:
	ld (D_9423),hl	; A436 22 23 94
Z_A439:
	call Z_A4E7	; A439 CD E7 A4
Z_A43C:
	ld a,(D_940E)	; A43C 3A 0E 94
Z_A43F:
	dec a	; A43F 3D
Z_A440:
	dec a	; A440 3D
Z_A441:
	ld (D_940E),a	; A441 32 0E 94
Z_A444:
	ld a,(D_9428)	; A444 3A 28 94
Z_A447:
	inc a	; A447 3C
Z_A448:
	inc a	; A448 3C
Z_A449:
	ld (D_9428),a	; A449 32 28 94
Z_A44C:
	cp 0x6E	; A44C FE 6E
Z_A44E:
	jp nz,Z_A439	; A44E 20 E9
Z_A450:
	ld a,0x03	; A450 3E 03
Z_A452:
	ld (D_940A),a	; A452 32 0A 94
Z_A455:
	ld (D_9424),a	; A455 32 24 94
Z_A458:
	call Z_A4E7	; A458 CD E7 A4
Z_A45B:
	ld a,0x0C	; A45B 3E 0C
Z_A45D:
	ld (D_940A),a	; A45D 32 0A 94
Z_A460:
	ld a,0x04	; A460 3E 04
Z_A462:
	ld (D_9424),a	; A462 32 24 94
Z_A465:
	call Z_A4E7	; A465 CD E7 A4
Z_A468:
	xor a	; A468 AF
Z_A469:
	ld (D_9409),a	; A469 32 09 94
Z_A46C:
	ld (D_9423),a	; A46C 32 23 94
Z_A46F:
	jp Z_A4E7	; A46F C3 E7 A4
Z_A472:
	push hl	; A472 E5
Z_A473:
	push de	; A473 D5
Z_A474:
	ld (il_tmp),hl	; A474 DD E5
	ld hl,(z80_ix)
	push hl
	ld hl,(il_tmp)
Z_A476:
	call Z_A4A8	; A476 CD A8 A4
Z_A479:
	ld de,0x0101	; A479 11 01 01
Z_A47C:
	call Z_A493	; A47C CD 93 A4
Z_A47F:
	ld de,0x081A	; A47F 11 1A 08
Z_A482:
	call Z_A493	; A482 CD 93 A4
Z_A485:
	call Z_93C4	; A485 CD C4 93
Z_A488:
	call Z_93C7	; A488 CD C7 93
Z_A48B:
	call Z_B1FE	; A48B CD FE B1
Z_A48E:
	ld (il_tmp),hl	; A48E DD E1
	pop hl
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_A490:
	pop de	; A490 D1
Z_A491:
	pop hl	; A491 E1
Z_A492:
	ret	; A492 C9
Z_A493:
	ret	; A493 C9
Z_A4A8:
	jp 0x01F8	; A4A8 C3 F8 01
Z_A4E7:
	call Z_93C4	; A4E7 CD C4 93
Z_A4EA:
	call Z_93C7	; A4EA CD C7 93
Z_A4ED:
	call Z_B1FE	; A4ED CD FE B1
Z_A4F0:
	xor a	; A4F0 AF
Z_A4F1:
	ld (0x0FEF),a	; A4F1 32 EF 0F
Z_A4F4:
	nop	; A4F4 00
Z_A4F5:
	nop	; A4F5 00
Z_A4F6:
	nop	; A4F6 00
Z_A4F7:
	nop	; A4F7 00
Z_A4F8:
	nop	; A4F8 00
Z_A4F9:
	nop	; A4F9 00
Z_A4FA:
	nop	; A4FA 00
Z_A4FB:
	nop	; A4FB 00
Z_A4FC:
	nop	; A4FC 00
Z_A4FD:
	ld a,0x05	; A4FD 3E 05
Z_A4FF:
	jp Z_3A2C	; A4FF C3 2C 3A
Z_A502:
	call CROWD_TICK	; A502 CD BA 74
Z_A505:
	and 0x0F	; A505 E6 0F
Z_A507:
	cp 0x04	; A507 FE 04
Z_A509:
	ret nz	; A509 C0
Z_A50A:
	ld a,(D_9451)	; A50A 3A 51 94
Z_A50D:
	jp c,il_KC15	; A50D CB 47
	ld (il_a),a
	and 0x01
	ld a,(il_a)
	jp il_KD16
il_KC15:
	ld (il_a),a
	and 0x01
	scf
	ld a,(il_a)
il_KD16:
Z_A50F:
	ret nz	; A50F C0
Z_A510:
	call Z_A17B	; A510 CD 7B A1
Z_A513:
	nop	; A513 00
Z_A514:
	nop	; A514 00
Z_A515:
	nop	; A515 00
Z_A516:
	push af	; A516 DD 6F
	ld a,a
	ld (z80_ix),a
	pop af
Z_A518:
	ld hl,0x0105	; A518 21 05 01
Z_A51B:
	call 0xA521	; A51B CD 21 A5
Z_A51E:
	ld hl,0x0110	; A51E 21 10 01
	jp 0xA521
Z_A53A:
	ld a,0x01	; A53A 3E 01
Z_A53C:
	ld (D_3433),a	; A53C 32 33 34
Z_A53F:
	ld a,0xF1	; A53F 3E F1
Z_A541:
	ld (D_3424),a	; A541 32 24 34
Z_A544:
	nop	; A544 00
Z_A545:
	nop	; A545 00
Z_A546:
	nop	; A546 00
Z_A547:
	jp Z_AC44	; A547 C3 44 AC
Z_A5FD:
	ld a,0xF1	; A5FD 3E F1
Z_A5FF:
	ld (D_3424),a	; A5FF 32 24 34
Z_A602:
	call Z_3732	; A602 CD 32 37
Z_A605:
	call 0x01FB	; A605 CD FB 01
Z_A608:
	ld a,0x07	; A608 3E 07
Z_A60A:
	ld (0x0FED),a	; A60A 32 ED 0F
Z_A60D:
	ld hl,0x0160	; A60D 21 60 01
Z_A610:
	ld bc,0x1E60	; A610 01 60 1E
Z_A613:
	ld a,0x17	; A613 3E 17
Z_A615:
	call Z_A75F	; A615 CD 5F A7
Z_A618:
	ld hl,0x0660	; A618 21 60 06
Z_A61B:
	ld (BLIT_Y),hl	; A61B 22 00 33
Z_A61E:
	ld hl,0x58	; A61E 21 58 00
Z_A621:
	ld (D_3308),hl	; A621 22 08 33
Z_A624:
	ld l,0x14	; A624 2E 14
Z_A626:
	ld (D_330A),hl	; A626 22 0A 33
Z_A629:
	ld a,0xF1	; A629 3E F1
Z_A62B:
	ld (D_3424),a	; A62B 32 24 34
Z_A62E:
	call MENU_BOX_CLEAR	; A62E CD F6 18
Z_A631:
	ld hl,0x076E	; A631 21 6E 07
Z_A634:
	ld (D_940D),hl	; A634 22 0D 94
Z_A637:
	ld h,0x6E	; A637 26 6E
Z_A639:
	ld (D_9427),hl	; A639 22 27 94
Z_A63C:
	ld hl,0x0C00	; A63C 21 00 0C
Z_A63F:
	ld (D_9409),hl	; A63F 22 09 94
Z_A642:
	ld hl,0x0400	; A642 21 00 04
Z_A645:
	ld (D_9423),hl	; A645 22 23 94
Z_A648:
	ld a,0x10	; A648 3E 10
Z_A64A:
	ld (D_940B),a	; A64A 32 0B 94
Z_A64D:
	ld (D_9425),a	; A64D 32 25 94
Z_A650:
	xor a	; A650 AF
Z_A651:
	ld (D_9426),a	; A651 32 26 94
Z_A654:
	ld (D_A49F),a	; A654 32 9F A4
Z_A657:
	inc a	; A657 3C
Z_A658:
	ld (D_940C),a	; A658 32 0C 94
Z_A65B:
	ld de,D_A797	; A65B 11 97 A7
Z_A65E:
	ld hl,0x0808	; A65E 21 08 08
Z_A661:
	call Z_9397	; A661 CD 97 93
Z_A664:
	ld l,0x0A	; A664 2E 0A
Z_A666:
	call Z_9397	; A666 CD 97 93
Z_A669:
	ld hl,0x080C	; A669 21 0C 08
Z_A66C:
	ld de,D_A7AD	; A66C 11 AD A7
Z_A66F:
	call Z_9397	; A66F CD 97 93
Z_A672:
	push de	; A672 D5
Z_A673:
	ld de,D_A7DA	; A673 11 DA A7
Z_A676:
	ld a,(D_93D2)	; A676 3A D2 93
Z_A679:
	and 0x03	; A679 E6 03
Z_A67B:
	jp z,Z_A686	; A67B 28 09
Z_A67D:
	ld de,D_A7E2	; A67D 11 E2 A7
Z_A680:
	dec a	; A680 3D
Z_A681:
	jp z,Z_A686	; A681 28 03
Z_A683:
	ld de,D_A7EA	; A683 11 EA A7
Z_A686:
	call Z_939A	; A686 CD 9A 93
Z_A689:
	pop de	; A689 D1
Z_A68A:
	ld l,0x0E	; A68A 2E 0E
Z_A68C:
	call Z_9397	; A68C CD 97 93
Z_A68F:
	ld l,0x10	; A68F 2E 10
Z_A691:
	call Z_9397	; A691 CD 97 93
Z_A694:
	call Z_A77F	; A694 CD 7F A7
Z_A697:
	call MENU_KEY	; A697 CD BB 06
Z_A69A:
	nop	; A69A 00
Z_A69B:
	nop	; A69B 00
Z_A69C:
	nop	; A69C 00
Z_A69D:
	nop	; A69D 00
Z_A69E:
	nop	; A69E 00
Z_A69F:
	cp 0x34	; A69F FE 34
Z_A6A1:
	jp z,Z_A6E1	; A6A1 28 3E
Z_A6A3:
	cp 0x33	; A6A3 FE 33
Z_A6A5:
	jp z,Z_A6CD	; A6A5 28 26
Z_A6A7:
	ld c,0x01	; A6A7 0E 01
Z_A6A9:
	cp 0x31	; A6A9 FE 31
Z_A6AB:
	jp z,Z_A6B2	; A6AB 28 05
Z_A6AD:
	cp 0x32	; A6AD FE 32
Z_A6AF:
	jp nz,Z_A694	; A6AF 20 E3
Z_A6B1:
	dec c	; A6B1 0D
Z_A6B2:
	ld a,c	; A6B2 79
Z_A6B3:
	ld (D_93EA),a	; A6B3 32 EA 93
Z_A6B6:
	and a	; A6B6 A7
Z_A6B7:
	ld hl,D_A7FD	; A6B7 21 FD A7
Z_A6BA:
	jp z,Z_A6BF	; A6BA 28 03
Z_A6BC:
	ld hl,D_A7F2	; A6BC 21 F2 A7
Z_A6BF:
	ld de,D_945F	; A6BF 11 5F 94
Z_A6C2:
	ld bc,0x0A	; A6C2 01 0A 00
Z_A6C5:
	call il_ldir	; A6C5 ED B0
Z_A6C7:
	ld a,0x01	; A6C7 3E 01
Z_A6C9:
	ld (0x0FED),a	; A6C9 32 ED 0F
Z_A6CC:
	ret	; A6CC C9
Z_A6CD:
	ld a,(D_93D2)	; A6CD 3A D2 93
Z_A6D0:
	inc a	; A6D0 3C
Z_A6D1:
	cp 0x03	; A6D1 FE 03
Z_A6D3:
	jp c,Z_A6D6	; A6D3 38 01
Z_A6D5:
	xor a	; A6D5 AF
Z_A6D6:
	ld (D_93D2),a	; A6D6 32 D2 93
Z_A6D9:
	ld a,0x0A	; A6D9 3E 0A
Z_A6DB:
	call Z_3A2C	; A6DB CD 2C 3A
Z_A6DE:
	jp Z_A669	; A6DE C3 69 A6
Z_A6E1:
	ld hl,0x0660	; A6E1 21 60 06
Z_A6E4:
	ld (BLIT_Y),hl	; A6E4 22 00 33
Z_A6E7:
	ld hl,0x50	; A6E7 21 50 00
Z_A6EA:
	ld (D_3308),hl	; A6EA 22 08 33
Z_A6ED:
	ld l,0x14	; A6ED 2E 14
Z_A6EF:
	ld (D_330A),hl	; A6EF 22 0A 33
Z_A6F2:
	ld a,0xF1	; A6F2 3E F1
Z_A6F4:
	ld (D_3424),a	; A6F4 32 24 34
Z_A6F7:
	call MENU_BOX_CLEAR	; A6F7 CD F6 18
Z_A6FA:
	ld hl,0x0808	; A6FA 21 08 08
Z_A6FD:
	ld de,D_A808	; A6FD 11 08 A8
Z_A700:
	call Z_9397	; A700 CD 97 93
Z_A703:
	ld hl,0x080A	; A703 21 0A 08
Z_A706:
	ld (TEXT_ROW),hl	; A706 22 02 41
Z_A709:
	ld hl,0x09	; A709 21 09 00
Z_A70C:
	ld (BLIT_Y),hl	; A70C 22 00 33
Z_A70F:
	call Z_38E8	; A70F CD E8 38
Z_A712:
	ld de,D_9453	; A712 11 53 94
Z_A715:
	call Z_A739	; A715 CD 39 A7
Z_A718:
	ld hl,0x080C	; A718 21 0C 08
Z_A71B:
	ld de,D_A81A	; A71B 11 1A A8
Z_A71E:
	call Z_9397	; A71E CD 97 93
Z_A721:
	ld hl,0x080E	; A721 21 0E 08
Z_A724:
	ld (TEXT_ROW),hl	; A724 22 02 41
	jp	Z_A727	; мост в следующий кусок
	org	0xA759
D_A759:
Z_A759:
	db	0xCD, 0x47, 0xAC, 0xC3, 0x18, 0xA6	; A759
	org	0xA75F
Z_A727:
	ld hl,0x09	; A727 21 09 00
Z_A72A:
	ld (BLIT_Y),hl	; A72A 22 00 33
Z_A72D:
	call Z_38E8	; A72D CD E8 38
Z_A730:
	ld de,D_A7FD	; A730 11 FD A7
Z_A733:
	call Z_A739	; A733 CD 39 A7
Z_A736:
	jp Z_A618	; A736 C3 18 A6
Z_A739:
	ld hl,0x4146	; A739 21 46 41
Z_A73C:
	ld c,0x00	; A73C 0E 00
Z_A73E:
	ld a,(hl)	; A73E 7E
Z_A73F:
	cp 0xFF	; A73F FE FF
Z_A741:
	jp z,Z_A749	; A741 28 06
Z_A743:
	ld (de),a	; A743 12
Z_A744:
	inc de	; A744 13
Z_A745:
	inc hl	; A745 23
Z_A746:
	inc c	; A746 0C
Z_A747:
	jp Z_A73E	; A747 18 F5
Z_A749:
	ld a,c	; A749 79
Z_A74A:
	and a	; A74A A7
Z_A74B:
	ret z	; A74B C8
Z_A74C:
	sub 0x09	; A74C D6 09
Z_A74E:
	ret z	; A74E C8
Z_A74F:
	cpl	; A74F ED 44
	inc a
Z_A751:
	ex de,hl	; A751 EB
Z_A752:
	ld (hl),0x20	; A752 36 20
Z_A754:
	inc hl	; A754 23
Z_A755:
	dec a	; A755 3D
Z_A756:
	jp nz,Z_A752	; A756 20 FA
Z_A758:
	ret	; A758 C9
	org	0xA797
D_A797:
Z_A797:
	db	0x31, 0x20, 0x50, 0x4C, 0x41, 0x59, 0x45, 0x52, 0x20, 0xFF, 0x32, 0x20, 0x50, 0x4C, 0x41, 0x59	; A797
	org	0xA7A7
D_A7A7:
Z_A7A7:
	db	0x45, 0x52, 0x53, 0x20, 0x20, 0xFF	; A7A7
	org	0xA7AD
D_A7AD:
Z_A7AD:
	db	0x33, 0x20, 0x4C, 0x45, 0x56, 0x45, 0x4C, 0x20, 0xFF, 0x34, 0x20, 0x43, 0x48, 0x41, 0x4E, 0x47	; A7AD
	org	0xA7BD
D_A7BD:
Z_A7BD:
	db	0x45, 0x20, 0x4E, 0x41, 0x4D, 0x45, 0x53, 0x20, 0x20, 0x20, 0xFF, 0x20, 0x20, 0x20, 0x20, 0x20	; A7BD
	org	0xA7CD
D_A7CD:
Z_A7CD:
	db	0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0xFF	; A7CD
	org	0xA7DA
D_A7DA:
Z_A7DA:
	db	0x52, 0x4F, 0x4F, 0x4B, 0x49, 0x45, 0x20, 0xFF	; A7DA
	org	0xA7E2
D_A7E2:
Z_A7E2:
	db	0x41, 0x4D, 0x41, 0x54, 0x45, 0x55, 0x52, 0xFF	; A7E2
	org	0xA7EA
D_A7EA:
Z_A7EA:
	db	0x4E, 0x42, 0x41, 0x20, 0x20, 0x20, 0x20, 0xFF	; A7EA
	org	0xA7F2
D_A7F2:
Z_A7F2:
	db	0x4D, 0x41, 0x52, 0x54, 0x49, 0x4E, 0x20, 0x46, 0x2E, 0x20, 0xFF	; A7F2
	org	0xA7FD
D_A7FD:
Z_A7FD:
	db	0x50, 0x4C, 0x41, 0x59, 0x45, 0x52, 0x20, 0x32, 0x20, 0x20, 0xFF	; A7FD
	org	0xA808
D_A808:
Z_A808:
	db	0x4C, 0x45, 0x46, 0x54, 0x20, 0x43, 0x4F, 0x55, 0x52, 0x54, 0x3A, 0x20, 0x20, 0x20, 0x20, 0x20	; A808
	org	0xA818
D_A818:
Z_A818:
	db	0x20, 0xFF	; A818
	org	0xA81A
D_A81A:
Z_A81A:
	db	0x52, 0x49, 0x47, 0x48, 0x54, 0x20, 0x43, 0x4F, 0x55, 0x52, 0x54, 0x3A, 0x20, 0x20, 0x20, 0x20	; A81A
	org	0xA82A
D_A82A:
Z_A82A:
	db	0x20, 0xFF	; A82A
	org	0xA82C
Z_A75F:
	ld (D_3424),a	; A75F 32 24 34
Z_A762:
	ld (BLIT_Y),hl	; A762 22 00 33
Z_A765:
	ld h,0x00	; A765 26 00
Z_A767:
	ld l,c	; A767 69
Z_A768:
	ld (D_3308),hl	; A768 22 08 33
Z_A76B:
	ld l,b	; A76B 68
Z_A76C:
	ld (D_330A),hl	; A76C 22 0A 33
Z_A76F:
	ld hl,0x0118	; A76F 21 18 01
Z_A772:
	ld (BLIT_PASS_FLAG),hl	; A772 22 DF 34
Z_A775:
	call Z_34BA	; A775 CD BA 34
Z_A778:
	ld hl,0x88CD	; A778 21 CD 88
Z_A77B:
	ld (BLIT_PASS_FLAG),hl	; A77B 22 DF 34
Z_A77E:
	ret	; A77E C9
Z_A77F:
	call Z_A4A8	; A77F CD A8 A4
Z_A782:
	ld de,0x0901	; A782 11 01 09
Z_A785:
	call Z_A493	; A785 CD 93 A4
Z_A788:
	ld de,0x091A	; A788 11 1A 09
Z_A78B:
	call Z_A493	; A78B CD 93 A4
Z_A78E:
	call Z_93C4	; A78E CD C4 93
Z_A791:
	call Z_93C7	; A791 CD C7 93
Z_A794:
	jp Z_B1FE	; A794 C3 FE B1
Z_A82C:
	call Z_3769	; A82C CD 69 37
Z_A82F:
	ld hl,0x00	; A82F 21 00 00
Z_A832:
	ld bc,0x2070	; A832 01 70 20
Z_A835:
	ld a,0x1F	; A835 3E 1F
Z_A837:
	call Z_A75F	; A837 CD 5F A7
Z_A83A:
	ld hl,0x0840	; A83A 21 40 08
Z_A83D:
	ld bc,0x1820	; A83D 01 20 18
Z_A840:
	ld a,(D_9400)	; A840 3A 00 94
Z_A843:
	jp c,il_KC17	; A843 CB 7F
	ld (il_a),a
	and 0x80
	ld a,(il_a)
	jp il_KD18
il_KC17:
	ld (il_a),a
	and 0x80
	scf
	ld a,(il_a)
il_KD18:
Z_A845:
	jp z,Z_A849	; A845 28 02
Z_A847:
	ld h,0x00	; A847 26 00
Z_A849:
	ld a,0x1A	; A849 3E 1A
Z_A84B:
	call Z_A75F	; A84B CD 5F A7
Z_A84E:
	ld hl,0x70	; A84E 21 70 00
Z_A851:
	ld bc,0x2050	; A851 01 50 20
Z_A854:
	ld a,0x17	; A854 3E 17
Z_A856:
	call Z_A75F	; A856 CD 5F A7
Z_A859:
	call RING_REPLAY	; A859 CD 1C 75
Z_A85C:
	nop	; A85C 00
Z_A85D:
	nop	; A85D 00
Z_A85E:
	nop	; A85E 00
Z_A85F:
	ld hl,D_93EB	; A85F 21 EB 93
Z_A862:
	ld de,0x1B40	; A862 11 40 1B
Z_A865:
	ld bc,0x4F	; A865 01 4F 00
Z_A868:
	call il_ldir	; A868 ED B0
Z_A86A:
	xor a	; A86A AF
Z_A86B:
	ld (D_3332),a	; A86B 32 32 33
Z_A86E:
	inc a	; A86E 3C
Z_A86F:
	ld (D_93D1),a	; A86F 32 D1 93
Z_A872:
	ld a,(D_9400)	; A872 3A 00 94
Z_A875:
	ld (D_3333),a	; A875 32 33 33
	jp	Z_A878	; мост в следующий кусок
	org	0xA8CB
D_A8CB:
Z_A8CB:
	db	0x3C, 0xE6, 0x01, 0x32, 0xCA, 0xD0, 0xC8, 0x01, 0x03, 0x00, 0x3A, 0xCB, 0xD0, 0xCB, 0x7F, 0x28	; A8CB
	org	0xA8DB
D_A8DB:
Z_A8DB:
	db	0x02, 0x0E, 0x1C, 0x11, 0x4F, 0x1E, 0x21, 0x98, 0xC3, 0x09, 0x01, 0x20, 0x08, 0x1A, 0x2F, 0x77	; A8DB
	org	0xA8EB
D_A8EB:
Z_A8EB:
	db	0x13, 0x78, 0x06, 0x00, 0x09, 0x47, 0x10, 0xF5, 0xC9	; A8EB
	org	0xA8F7
D_A8F7:
Z_A8F7:
	db	0xC3, 0x11	; A8F7
	org	0xA8F9
D_A8F9:
Z_A8F9:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; A8F9
	org	0xA909
Z_A878:
	jp c,il_KC19	; A878 CB 7F
	ld (il_a),a
	and 0x80
	ld a,(il_a)
	jp il_KD20
il_KC19:
	ld (il_a),a
	and 0x80
	scf
	ld a,(il_a)
il_KD20:
Z_A87A:
	ld hl,0x00	; A87A 21 00 00
Z_A87D:
	jp z,Z_A881	; A87D 28 02
Z_A87F:
	ld l,0x10	; A87F 2E 10
Z_A881:
	ld (D_A8F9),hl	; A881 22 F9 A8
Z_A884:
	call Z_A991	; A884 CD 91 A9
Z_A887:
	call REPLAY_STATE_BEGIN	; A887 CD 4C 14
Z_A88A:
	call REPLAY_SCENE	; A88A CD 4F 14
Z_A88D:
	call Z_A8F4	; A88D CD F4 A8
Z_A890:
	call Z_3758	; A890 CD 58 37
Z_A893:
	ld a,(D_93D3)	; A893 3A D3 93
Z_A896:
	dec a	; A896 3D
Z_A897:
	ld a,0x0A	; A897 3E 0A
Z_A899:
	jp z,Z_A8B5	; A899 28 1A
Z_A89B:
	call Z_A991	; A89B CD 91 A9
Z_A89E:
	call REPLAY_STATE_BEGIN	; A89E CD 4C 14
Z_A8A1:
	call REPLAY_SCENE	; A8A1 CD 4F 14
Z_A8A4:
	call Z_A8C8	; A8A4 CD C8 A8
Z_A8A7:
	call Z_A8F4	; A8A7 CD F4 A8
Z_A8AA:
	ld a,(G_KEY_ASCII)	; A8AA 3A 10 41
Z_A8AD:
	sub 0x20	; A8AD D6 20
Z_A8AF:
	jp nz,Z_A893	; A8AF 20 E2
Z_A8B1:
	ld (D_93D3),a	; A8B1 32 D3 93
Z_A8B4:
	inc a	; A8B4 3C
Z_A8B5:
	ld hl,0x1B40	; A8B5 21 40 1B
	jp	Z_A8B8	; мост в следующий кусок
	org	0xA965
D_A965:
Z_A965:
	db	0x00, 0x00, 0x00, 0x00	; A965
	org	0xA969
Z_A8B8:
	ld de,D_93EB	; A8B8 11 EB 93
	jp	Z_A8BB	; мост в следующий кусок
	org	0xA971
D_A971:
Z_A971:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; A971
	org	0xA981
D_A981:
Z_A981:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; A981
	org	0xA994
D_A994:
Z_A994:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; A994
	org	0xA9A4
D_A9A4:
Z_A9A4:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; A9A4
	org	0xA9AD
Z_A8BB:
	ld bc,0x4F	; A8BB 01 4F 00
Z_A8BE:
	call il_ldir	; A8BE ED B0
Z_A8C0:
	call 0x08DE	; A8C0 CD DE 08
Z_A8C3:
	xor a	; A8C3 AF
Z_A8C4:
	ld (D_93D1),a	; A8C4 32 D1 93
Z_A8C7:
	ret	; A8C7 C9
Z_A8C8:
	jp 0x0903	; A8C8 C3 03 09
Z_A8F4:
	jp 0x0885	; A8F4 C3 85 08
Z_A95E:
	xor a	; A95E AF
	jp	Z_A95F	; мост в следующий кусок
	org	0xA9C7
D_A9C7:
Z_A9C7:
	db	0x3A, 0x00, 0x94, 0xA7, 0xC0, 0xED, 0x5B, 0xD4, 0x93, 0x21, 0xEB, 0x93, 0x01, 0x4F, 0x00, 0xED	; A9C7
	org	0xA9D7
D_A9D7:
Z_A9D7:
	db	0xB0, 0x21, 0xE1, 0x1F, 0xED, 0x52, 0x30, 0x0B, 0x11, 0x8F, 0x1B, 0x21, 0xDE, 0x1B, 0x01, 0x52	; A9D7
	org	0xA9E7
D_A9E7:
Z_A9E7:
	db	0x04, 0xED, 0xB0, 0xED, 0x53, 0xD4, 0x70, 0x60, 0xFF, 0x80, 0x1F, 0x00, 0x0F, 0x80, 0xFF, 0xF0	; A9E7
	org	0xA9F7
D_A9F7:
Z_A9F7:
	db	0x7F, 0x28, 0x06, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x00, 0xE0, 0x00, 0xFF, 0x1F, 0xFF, 0x03	; A9F7
	org	0xAA07
D_AA07:
Z_AA07:
	db	0x90, 0x00, 0xFC, 0x0F, 0xFF, 0x04, 0x50, 0x00, 0xF8, 0x0F, 0xFF, 0x0B, 0x3E, 0x00, 0xF0, 0x01	; AA07
	org	0xAA17
D_AA17:
Z_AA17:
	db	0xFF, 0x0C, 0xBF, 0x00, 0xF3, 0x00, 0xFF, 0x01, 0x9F, 0x00, 0xFE, 0x00, 0xFF, 0x01, 0x93, 0x80	; AA17
	org	0xAA27
D_AA27:
Z_AA27:
	db	0xFE, 0x00, 0x7F, 0x01, 0x99, 0x00, 0xFE, 0x00, 0xFF, 0x01, 0x9A, 0x00, 0xFE, 0x01, 0xFF, 0x01	; AA27
	org	0xAA37
D_AA37:
Z_AA37:
	db	0x91, 0x00, 0xFE, 0x00, 0xFF, 0x01, 0x91, 0x00, 0xFE, 0x00, 0xFF, 0x01, 0x2E, 0x00, 0xFE, 0x01	; AA37
	org	0xAA47
D_AA47:
Z_AA47:
	db	0xFF, 0x01, 0x21, 0x00, 0xFE, 0x00, 0xFF, 0x02, 0x20, 0x80, 0xFC, 0x00, 0x7F, 0x02, 0x30, 0x80	; AA47
	org	0xAA57
D_AA57:
Z_AA57:
	db	0xFC, 0x00, 0x7F, 0x02, 0x3F, 0x00, 0xFC, 0x00, 0xFF, 0x01, 0xCA, 0x00, 0xFE, 0x01, 0xFF, 0x01	; AA57
	org	0xAA67
D_AA67:
Z_AA67:
	db	0x02, 0x00, 0xFE, 0x01, 0xFF, 0x01, 0x04, 0x00, 0xFE, 0x03, 0xFF, 0x00, 0x84, 0x00, 0xFF, 0x03	; AA67
	org	0xAA77
D_AA77:
Z_AA77:
	db	0xFF, 0x00, 0xFC, 0x18, 0x6F	; AA77
	org	0xAA7E
D_AA7E:
Z_AA7E:
	db	0x18, 0x57	; AA7E
	org	0xAA82
D_AA82:
Z_AA82:
	db	0x00	; AA82
	org	0xAA83
D_AA83:
Z_AA83:
	db	0x05	; AA83
	org	0xAA84
D_AA84:
Z_AA84:
	db	0x00	; AA84
	org	0xAA85
Z_A95F:
	ld (D_93D3),a	; A95F 32 D3 93
Z_A962:
	jp RING_RESET	; A962 C3 11 75
Z_A969:
	ld a,(D_9400)	; A969 3A 00 94
Z_A96C:
	and a	; A96C A7
Z_A96D:
	ret nz	; A96D C0
Z_A96E:
	jp RING_PUSH	; A96E C3 E8 74
Z_A991:
	jp RING_PULL	; A991 C3 2D 75
Z_A9AD:
	di	; A9AD F3
Z_A9AE:
	ld e,0x96	; A9AE 1E 96
Z_A9B0:
	xor a	; A9B0 AF
Z_A9B1:
	push af	; A9B1 F5
Z_A9B2:
	call 0x0135	; A9B2 CD 35 01
Z_A9B5:
	pop af	; A9B5 F1
Z_A9B6:
	xor 0x10	; A9B6 EE 10
Z_A9B8:
	ld d,a	; A9B8 57
Z_A9B9:
	ld bc,0x02BC	; A9B9 01 BC 02
Z_A9BC:
	dec bc	; A9BC 0B
Z_A9BD:
	ld a,b	; A9BD 78
Z_A9BE:
	or c	; A9BE B1
Z_A9BF:
	jp nz,Z_A9BC	; A9BF 20 FB
Z_A9C1:
	ld a,d	; A9C1 7A
Z_A9C2:
	dec e	; A9C2 1D
Z_A9C3:
	jp nz,Z_A9B1	; A9C3 20 EC
Z_A9C5:
	ei	; A9C5 FB
Z_A9C6:
	ret	; A9C6 C9
Z_AA7C:
	jp Z_AA85	; AA7C 18 07
Z_AA80:
	jp Z_AAF0	; AA80 18 6E
Z_AA85:
	ld hl,(BLIT_Y)	; AA85 2A 00 33
Z_AA88:
	di	; AA88 F3
Z_AA89:
	ld (D_AC07),hl	; AA89 22 07 AC
Z_AA8C:
	ld (D_AC05),hl	; AA8C 22 05 AC
Z_AA8F:
	ld hl,(D_AC05)	; AA8F 2A 05 AC
Z_AA92:
	ld (il_tmp),hl	; AA92 FD 21 09 AC
	ld hl,D_AC09
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_AA96:
	ld b,0x03	; AA96 06 03
Z_AA98:
	call il_iy_stn	; AA98 FD 36 00 00
	db 0x00, 0x00
Z_AA9C:
	call il_iy_stn	; AA9C FD 36 01 00
	db 0x01, 0x00
Z_AAA0:
	ld e,(hl)	; AAA0 5E
Z_AAA1:
	inc hl	; AAA1 23
Z_AAA2:
	ld d,(hl)	; AAA2 56
Z_AAA3:
	inc hl	; AAA3 23
Z_AAA4:
	ld a,e	; AAA4 7B
Z_AAA5:
	and d	; AAA5 A2
Z_AAA6:
	cp 0xFF	; AAA6 FE FF
Z_AAA8:
	jp nz,Z_AABA	; AAA8 20 10
Z_AAAA:
	ld a,(D_AA82)	; AAAA 3A 82 AA
Z_AAAD:
	or a	; AAAD B7
Z_AAAE:
	ld a,0x00	; AAAE 3E 00
Z_AAB0:
	ld (D_AA82),a	; AAB0 32 82 AA
Z_AAB3:
	jp nz,Z_AAEB	; AAB3 20 36
Z_AAB5:
	ld hl,(D_AC07)	; AAB5 2A 07 AC
Z_AAB8:
	jp Z_AA8C	; AAB8 18 D2
Z_AABA:
	call il_iy_ste	; AABA FD 73 02
	db 0x02
Z_AABD:
	call il_iy_std	; AABD FD 72 03
	db 0x03
Z_AAC0:
	ld de,0x08	; AAC0 11 08 00
Z_AAC3:
	ld (il_tmp),hl	; AAC3 FD 19
	ld hl,(z80_iy)
	add hl,de
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_AAC5:
	dec b	; AAC5 10 D1
	jp nz,Z_AA98
Z_AAC7:
	ld e,(hl)	; AAC7 5E
Z_AAC8:
	inc hl	; AAC8 23
Z_AAC9:
	ld d,(hl)	; AAC9 56
Z_AACA:
	inc hl	; AACA 23
Z_AACB:
	ld (D_AC05),hl	; AACB 22 05 AC
Z_AACE:
	ld hl,D_AC25	; AACE 21 25 AC
	jp	Z_AAD1	; мост в следующий кусок
	org	0xAB23
D_AB23:
Z_AB23:
	db	0x0E, 0x00	; AB23
	org	0xAB25
Z_AAD1:
	ex de,hl	; AAD1 EB
Z_AAD2:
	ld bc,0x1E	; AAD2 01 1E 00
Z_AAD5:
	call il_ldir	; AAD5 ED B0
Z_AAD7:
	ld hl,Z_AB28	; AAD7 21 28 AB
Z_AADA:
	di	; AADA F3
Z_AADB:
	ld a,0x07	; AADB 3E 07
Z_AADD:
	ld c,0xB8	; AADD 0E B8
Z_AADF:
	call Z_ABFF	; AADF CD FF AB
Z_AAE2:
	xor a	; AAE2 AF
Z_AAE3:
	ld (D_AC21),a	; AAE3 32 21 AC
Z_AAE6:
	ld (Z_3702+1),hl	; AAE6 22 03 37
Z_AAE9:
	jp Z_AB1E	; AAE9 18 33
Z_AAEB:
	ld hl,Z_AB83	; AAEB 21 83 AB
Z_AAEE:
	jp Z_AADA	; AAEE 18 EA
Z_AAF0:
	ld hl,(D_AC13)	; AAF0 2A 13 AC
Z_AAF3:
	ld a,h	; AAF3 7C
Z_AAF4:
	or l	; AAF4 B5
Z_AAF5:
	ret nz	; AAF5 C0
Z_AAF6:
	ld a,(D_AC21)	; AAF6 3A 21 AC
Z_AAF9:
	or a	; AAF9 B7
Z_AAFA:
	jp z,Z_AB01	; AAFA 28 05
Z_AAFC:
	ld a,(D_AA84)	; AAFC 3A 84 AA
Z_AAFF:
	or a	; AAFF B7
Z_AB00:
	ret nz	; AB00 C0
Z_AB01:
	ld hl,(BLIT_SRC)	; AB01 2A 02 33
Z_AB04:
	di	; AB04 F3
Z_AB05:
	ld (D_AC23),hl	; AB05 22 23 AC
Z_AB08:
	ld hl,0x01	; AB08 21 01 00
Z_AB0B:
	ld (D_AC21),hl	; AB0B 22 21 AC
Z_AB0E:
	ld a,0x09	; AB0E 3E 09
Z_AB10:
	ld c,0x10	; AB10 0E 10
Z_AB12:
	call Z_ABFF	; AB12 CD FF AB
Z_AB15:
	ld a,0x06	; AB15 3E 06
Z_AB17:
	ld c,0x1F	; AB17 0E 1F
Z_AB19:
	call Z_ABFF	; AB19 CD FF AB
Z_AB1C:
	ei	; AB1C FB
Z_AB1D:
	ret	; AB1D C9
Z_AB1E:
	call 0x90	; AB1E CD 90 00
Z_AB21:
	ei	; AB21 FB
Z_AB22:
	ret	; AB22 C9
Z_AB25:
	jp Z_ABFF	; AB25 C3 FF AB
Z_AB28:
	call 0x0726	; AB28 CD 26 07
Z_AB2B:
	jp nz,Z_AB83	; AB2B 20 56
Z_AB2D:
	xor a	; AB2D AF
Z_AB2E:
	ld (Z_AB21),a	; AB2E 32 21 AB
Z_AB31:
	call Z_AA8F	; AB31 CD 8F AA
Z_AB34:
	ld a,0xFB	; AB34 3E FB
Z_AB36:
	ld (Z_AB21),a	; AB36 32 21 AB
Z_AB39:
	jp Z_AB83	; AB39 18 48
Z_AB83:
	ld a,(D_AC21)	; AB83 3A 21 AC
Z_AB86:
	or a	; AB86 B7
Z_AB87:
	ret z	; AB87 C8
Z_AB88:
	ld a,(D_AC22)	; AB88 3A 22 AC
Z_AB8B:
	or a	; AB8B B7
Z_AB8C:
	jp z,Z_AB93	; AB8C 28 05
Z_AB8E:
	dec a	; AB8E 3D
Z_AB8F:
	ld (D_AC22),a	; AB8F 32 22 AC
Z_AB92:
	ret	; AB92 C9
Z_AB93:
	ld a,(D_AA83)	; AB93 3A 83 AA
Z_AB96:
	ld (D_AC22),a	; AB96 32 22 AC
Z_AB99:
	ld hl,(D_AC23)	; AB99 2A 23 AC
Z_AB9C:
	ld a,(hl)	; AB9C 7E
Z_AB9D:
	cp 0xFF	; AB9D FE FF
Z_AB9F:
	jp nz,Z_ABA9	; AB9F 20 08
Z_ABA1:
	xor a	; ABA1 AF
Z_ABA2:
	ld (D_AC21),a	; ABA2 32 21 AC
Z_ABA5:
	ld c,0x00	; ABA5 0E 00
Z_ABA7:
	jp Z_ABD7	; ABA7 18 2E
Z_ABA9:
	ld d,a	; ABA9 57
Z_ABAA:
	ld (il_a),a	; ABAA CB 52
	ld a,d
	and 0x04
	ld a,(il_a)
Z_ABAC:
	jp z,Z_ABB2	; ABAC 28 04
Z_ABAE:
	ld c,0xA8	; ABAE 0E A8
Z_ABB0:
	jp Z_ABB4	; ABB0 18 02
Z_ABB2:
	ld c,0xB8	; ABB2 0E B8
Z_ABB4:
	ld a,0x07	; ABB4 3E 07
Z_ABB6:
	call Z_ABFF	; ABB6 CD FF AB
Z_ABB9:
	inc hl	; ABB9 23
Z_ABBA:
	ld c,(hl)	; ABBA 4E
Z_ABBB:
	inc hl	; ABBB 23
Z_ABBC:
	push hl	; ABBC E5
Z_ABBD:
	ld a,0x02	; ABBD 3E 02
Z_ABBF:
	call Z_ABFF	; ABBF CD FF AB
Z_ABC2:
	pop hl	; ABC2 E1
Z_ABC3:
	ld c,(hl)	; ABC3 4E
Z_ABC4:
	inc hl	; ABC4 23
Z_ABC5:
	ld (D_AC23),hl	; ABC5 22 23 AC
Z_ABC8:
	ld a,0x03	; ABC8 3E 03
Z_ABCA:
	call Z_ABFF	; ABCA CD FF AB
Z_ABCD:
	nop	; ABCD 00
Z_ABCE:
	ld c,d	; ABCE 4A
Z_ABCF:
	ld (il_a),a	; ABCF CB 39
	ld a,c
	or a
	rra
	ld c,a
	ld a,(il_a)
Z_ABD1:
	ld (il_a),a	; ABD1 CB 39
	ld a,c
	or a
	rra
	ld c,a
	ld a,(il_a)
	jp	Z_ABD3	; мост в следующий кусок
	org	0xAC05
D_AC05:
Z_AC05:
	db	0x00, 0x00	; AC05
	org	0xAC07
D_AC07:
Z_AC07:
	db	0x00, 0x00	; AC07
	org	0xAC09
D_AC09:
Z_AC09:
	db	0x00, 0x00, 0x00, 0x00, 0x25, 0xAC, 0x00, 0x08, 0x00, 0x00	; AC09
	org	0xAC13
D_AC13:
Z_AC13:
	db	0x00, 0x00, 0x2F, 0xAC, 0x02, 0x09, 0x00, 0x00, 0x00, 0x00, 0x39, 0xAC, 0x04, 0x0A	; AC13
	org	0xAC21
D_AC21:
Z_AC21:
	db	0x00	; AC21
	org	0xAC22
D_AC22:
Z_AC22:
	db	0x00	; AC22
	org	0xAC23
D_AC23:
Z_AC23:
	db	0x00, 0x00	; AC23
	org	0xAC25
D_AC25:
Z_AC25:
	db	0x0D, 0x0C, 0x0B, 0x0A, 0x09, 0x08, 0x07, 0x06, 0x05, 0x04, 0x0D, 0x0C, 0x0B, 0x0A, 0x09, 0x08	; AC25
	org	0xAC35
D_AC35:
Z_AC35:
	db	0x07, 0x06, 0x05, 0x04, 0x0D, 0x0C, 0x0B, 0x0A, 0x09, 0x08, 0x07, 0x06, 0x05, 0x04, 0xC9	; AC35
	org	0xAC47
D_AC47:
Z_AC47:
	db	0xC3, 0x50, 0xAC	; AC47
	org	0xAC4D
D_AC4D:
Z_AC4D:
	db	0x00	; AC4D
	org	0xAC4E
D_AC4E:
Z_AC4E:
	db	0x00	; AC4E
	org	0xAC4F
D_AC4F:
Z_AC4F:
	db	0x00, 0x21, 0x60, 0x06, 0x22, 0x00, 0x33, 0x21, 0x58, 0x00, 0x22, 0x08, 0x33, 0x2E, 0x14, 0x22	; AC4F
	org	0xAC5F
D_AC5F:
Z_AC5F:
	db	0x0A, 0x33, 0x3E, 0xF1, 0x32, 0x24, 0x34, 0xCD, 0xA9, 0x34, 0x3E, 0xA1, 0x32, 0x24, 0x34, 0x21	; AC5F
	org	0xAC6F
D_AC6F:
Z_AC6F:
	db	0x0D, 0x0A, 0x11, 0x77, 0xAE, 0xCD, 0xFA, 0xAE, 0x3E, 0x31, 0x47, 0xDF, 0x3A, 0x15, 0xAE, 0x2C	; AC6F
	org	0xAC7F
D_AC7F:
Z_AC7F:
	db	0xCD, 0xE6, 0xAE, 0x3A, 0x16, 0xAE, 0x04, 0x2C, 0xCD, 0xE6, 0xAE, 0x3E, 0xA1, 0x32, 0x24, 0x34	; AC7F
	org	0xAC8F
D_AC8F:
Z_AC8F:
	db	0x2C, 0x2C, 0x11, 0x77, 0xAE, 0xCD, 0xFA, 0xAE, 0x3E, 0x32, 0xDF, 0x3A, 0x17, 0xAE, 0x04, 0x2C	; AC8F
	org	0xAC9F
D_AC9F:
Z_AC9F:
	db	0xCD, 0xE6, 0xAE, 0x3A, 0x18, 0xAE, 0x04, 0x2C, 0xCD, 0xE6, 0xAE, 0x3E, 0xF1, 0x32, 0x24, 0x34	; AC9F
	org	0xACAF
D_ACAF:
Z_ACAF:
	db	0x2C, 0x2C, 0x11, 0x92, 0xAE, 0xCD, 0xFA, 0xAE, 0xCD, 0x2F, 0x3A, 0xFE, 0x30, 0x38, 0xF9, 0xCA	; ACAF
	org	0xACBF
D_ACBF:
Z_ACBF:
	db	0xDF, 0xAD, 0xFE, 0x35, 0x30, 0xF2, 0xF5, 0xCD, 0xDF, 0xAD, 0xF1, 0xFE, 0x31, 0x28, 0x2B, 0xFE	; ACBF
	org	0xACCF
D_ACCF:
Z_ACCF:
	db	0x33, 0xCA, 0x05, 0xAD, 0xFE, 0x34, 0x28, 0x11, 0x3E, 0x31, 0xCD, 0x11, 0xAD, 0xDD, 0x21, 0x5D	; ACCF
	org	0xACDF
D_ACDF:
Z_ACDF:
	db	0xAE, 0xCD, 0x3D, 0xAE, 0x21, 0x00, 0x01, 0x18, 0x17, 0x3E, 0x32, 0xCD, 0x11, 0xAD, 0xDD, 0x21	; ACDF
	org	0xACEF
D_ACEF:
Z_ACEF:
	db	0x6D, 0xAE, 0xCD, 0x3D, 0xAE, 0x21, 0x00, 0x01, 0x18, 0x12, 0xCD, 0x2B, 0xAE, 0x21, 0x01, 0x00	; ACEF
	org	0xACFF
D_ACFF:
Z_ACFF:
	db	0x22, 0x15, 0xAE, 0xC3, 0x69, 0xAC, 0xCD, 0x34, 0xAE, 0x21, 0x01, 0x00, 0x22, 0x17, 0xAE, 0xC3	; ACFF
	org	0xAD0F
D_AD0F:
Z_AD0F:
	db	0x69, 0xAC, 0xF5, 0x21, 0x60, 0x09, 0x22, 0x00, 0x33, 0x21, 0x58, 0x00, 0x22, 0x08, 0x33, 0x2E	; AD0F
	org	0xAD1F
D_AD1F:
Z_AD1F:
	db	0x0E, 0x22, 0x0A, 0x33, 0xCD, 0xA9, 0x34, 0x21, 0x0F, 0xAE, 0x11, 0x10, 0xAE, 0x01, 0x05, 0x00	; AD1F
	org	0xAD2F
D_AD2F:
Z_AD2F:
	db	0x36, 0xFF, 0xED, 0xB0, 0x3E, 0xA1, 0x32, 0x24, 0x34, 0x21, 0x0D, 0x0A, 0x11, 0x77, 0xAE, 0xCD	; AD2F
	org	0xAD3F
D_AD3F:
Z_AD3F:
	db	0xFA, 0xAE, 0xF1, 0xDF, 0x3E, 0xF1, 0x32, 0x24, 0x34, 0xDD, 0x21, 0x0F, 0xAE, 0x01, 0x0F, 0xAE	; AD3F
	org	0xAD4F
D_AD4F:
Z_AD4F:
	db	0x11, 0x99, 0xAE, 0x21, 0x0F, 0x09, 0xCD, 0x8C, 0xAD, 0x2C, 0xCD, 0x8C, 0xAD, 0x2C, 0xCD, 0x8C	; AD4F
	org	0xAD5F
D_AD5F:
Z_AD5F:
	db	0xAD, 0x2C, 0xCD, 0x8C, 0xAD, 0x2C, 0x2C, 0xCD, 0x8C, 0xAD, 0x2C, 0xCD, 0x8C, 0xAD, 0xCD, 0x2F	; AD5F
	org	0xAD6F
D_AD6F:
Z_AD6F:
	db	0x3A, 0xFE, 0x30, 0x38, 0x04, 0xFE, 0x3A, 0x38, 0xF5, 0x21, 0x60, 0x08, 0x22, 0x00, 0x33, 0x21	; AD6F
	org	0xAD7F
D_AD7F:
Z_AD7F:
	db	0x58, 0x00, 0x22, 0x08, 0x33, 0x2E, 0x11, 0x22, 0x0A, 0x33, 0xC3, 0xA9, 0x34, 0xCD, 0xFA, 0xAE	; AD7F
	org	0xAD8F
D_AD8F:
Z_AD8F:
	db	0x18, 0x1B, 0xF3, 0xC5, 0xE5, 0x2E, 0x4B, 0xAF, 0xF5, 0xCD, 0x35, 0x01, 0x01, 0xBC, 0x02, 0x0B	; AD8F
	org	0xAD9F
D_AD9F:
Z_AD9F:
	db	0x78, 0xB1, 0x20, 0xFB, 0xF1, 0xEE, 0x01, 0x2D, 0x20, 0xEE, 0xE1, 0xC1, 0xFB, 0xD5, 0xC5, 0xE5	; AD9F
	org	0xADAF
D_ADAF:
Z_ADAF:
	db	0xCD, 0xF5, 0xAD, 0xE1, 0xC1, 0xD1, 0xDD, 0xBE, 0x00, 0x28, 0xD7, 0xDD, 0xBE, 0x01, 0x28, 0xD2	; ADAF
	org	0xADBF
D_ADBF:
Z_ADBF:
	db	0xDD, 0xBE, 0x02, 0x28, 0xCD, 0xDD, 0xBE, 0x03, 0x28, 0xC8, 0xDD, 0xBE, 0x04, 0x28, 0xC3, 0xDD	; ADBF
	org	0xADCF
D_ADCF:
Z_ADCF:
	db	0xBE, 0x05, 0x28, 0xBE, 0x02, 0x03, 0xD5, 0xC5, 0x11, 0xE1, 0xAE, 0xCD, 0xFD, 0xAE, 0xC1, 0xD1	; ADCF
	org	0xADDF
D_ADDF:
Z_ADDF:
	db	0xC5, 0xF3, 0x0E, 0xC8, 0xAF, 0xF5, 0xCD, 0x35, 0x01, 0xF1, 0xEE, 0x01, 0x06, 0x64, 0x10, 0xFE	; ADDF
	org	0xADEF
D_ADEF:
Z_ADEF:
	db	0x0D, 0x20, 0xF2, 0xFB, 0xC1, 0xC9, 0xCD, 0xCC, 0x37, 0xCD, 0x11, 0x38, 0x3A, 0x0F, 0x41, 0x3C	; ADEF
	org	0xADFF
D_ADFF:
Z_ADFF:
	db	0x20, 0xF4, 0xCD, 0xCC, 0x37, 0xCD, 0x11, 0x38, 0x3A, 0x0F, 0x41, 0xFE, 0xFF, 0x28, 0xF3, 0xC9	; ADFF
	org	0xAE0F
D_AE0F:
Z_AE0F:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; AE0F
	org	0xAE15
D_AE15:
Z_AE15:
	db	0x00	; AE15
	org	0xAE16
D_AE16:
Z_AE16:
	db	0x00	; AE16
	org	0xAE17
D_AE17:
Z_AE17:
	db	0x00	; AE17
	org	0xAE18
D_AE18:
Z_AE18:
	db	0x00	; AE18
	org	0xAE19
Z_ABD3:
	ld (il_a),a	; ABD3 CB 39
	ld a,c
	or a
	rra
	ld c,a
	ld a,(il_a)
Z_ABD5:
	ld (il_a),a	; ABD5 CB 39
	ld a,c
	or a
	rra
	ld c,a
	ld a,(il_a)
Z_ABD7:
	ld a,0x09	; ABD7 3E 09
Z_ABD9:
	jp Z_ABFF	; ABD9 18 24
Z_ABFF:
	ld e,c	; ABFF 59
Z_AC00:
	call 0x93	; AC00 CD 93 00
Z_AC03:
	di	; AC03 F3
Z_AC04:
	ret	; AC04 C9
	org	0xAE3D
D_AE3D:
Z_AE3D:
	db	0x21, 0x0F, 0xAE	; AE3D
	org	0xAE40
Z_AC44:
	jp Z_AE19	; AC44 C3 19 AE
Z_AC4A:
	jp Z_AF05	; AC4A C3 05 AF
Z_AE19:
	ld a,0x01	; AE19 3E 01
Z_AE1B:
	ld (D_AE15),a	; AE1B 32 15 AE
Z_AE1E:
	ld (D_AE17),a	; AE1E 32 17 AE
Z_AE21:
	xor a	; AE21 AF
Z_AE22:
	ld (D_AE16),a	; AE22 32 16 AE
	jp	Z_AE25	; мост в следующий кусок
	org	0xAE57
D_AE57:
Z_AE57:
	db	0x01, 0x26, 0x19, 0x1B, 0x2F, 0x3F	; AE57
	org	0xAE5D
D_AE5D:
Z_AE5D:
	dw	D_AF0E	; AE5D 0E AF
	org	0xAE5F
D_AE5F:
Z_AE5F:
	dw	D_AF17	; AE5F 17 AF
	org	0xAE61
D_AE61:
Z_AE61:
	dw	D_AF2A	; AE61 2A AF
	org	0xAE63
D_AE63:
Z_AE63:
	dw	D_AF33	; AE63 33 AF
	org	0xAE65
D_AE65:
Z_AE65:
	dw	D_AF46	; AE65 46 AF
	org	0xAE67
D_AE67:
Z_AE67:
	db	0x45, 0x46, 0x44, 0x47, 0x3F, 0x06	; AE67
	org	0xAE6D
D_AE6D:
Z_AE6D:
	dw	D_AF55	; AE6D 55 AF
	org	0xAE6F
D_AE6F:
Z_AE6F:
	dw	D_AF5E	; AE6F 5E AF
	org	0xAE71
D_AE71:
Z_AE71:
	dw	D_AF71	; AE71 71 AF
	org	0xAE73
D_AE73:
Z_AE73:
	dw	D_AF7A	; AE73 7A AF
	org	0xAE75
D_AE75:
Z_AE75:
	dw	D_AF8D	; AE75 8D AF
	org	0xAE77
D_AE77:
Z_AE77:
	db	0x50, 0x4C, 0x41, 0x59, 0x45, 0x52, 0x20, 0x20, 0xFF, 0x4B, 0x45, 0x59, 0x53, 0x20, 0x20, 0x20	; AE77
	org	0xAE87
D_AE87:
Z_AE87:
	db	0xFF, 0x52, 0x45, 0x44, 0x45, 0x46, 0x49, 0x4E, 0x45, 0x20, 0xFF, 0x30, 0x20, 0x4D, 0x45, 0x4E	; AE87
	org	0xAE97
D_AE97:
Z_AE97:
	db	0x55, 0xFF, 0x55, 0x50, 0x3A, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0xFF, 0x44, 0x4F	; AE97
	org	0xAEA7
D_AEA7:
Z_AEA7:
	db	0x57, 0x4E, 0x3A, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0xFF, 0x4C, 0x45, 0x46, 0x54, 0x3A, 0x20	; AEA7
	org	0xAEB7
D_AEB7:
Z_AEB7:
	db	0x20, 0x20, 0x20, 0x20, 0x20, 0xFF, 0x52, 0x49, 0x47, 0x48, 0x54, 0x3A, 0x20, 0x20, 0x20, 0x20	; AEB7
	org	0xAEC7
D_AEC7:
Z_AEC7:
	db	0x20, 0xFF, 0x46, 0x49, 0x52, 0x45, 0x3A, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0xFF, 0x50, 0x41	; AEC7
	org	0xAED7
D_AED7:
Z_AED7:
	db	0x55, 0x53, 0x45, 0x3A, 0x20, 0x20, 0x20, 0x20, 0x20, 0xFF, 0x4F, 0x2E, 0x4B, 0x2E, 0xFF, 0x22	; AED7
	org	0xAEE7
D_AEE7:
Z_AEE7:
	db	0x02, 0x41, 0xA7, 0x3E, 0xF1, 0x28, 0x02, 0x3E, 0x21, 0x32, 0x24, 0x34, 0x78, 0xDF, 0x3E, 0x20	; AEE7
	org	0xAEF7
D_AEF7:
Z_AEF7:
	db	0xDF, 0x18, 0x03	; AEF7
	org	0xAEFA
Z_AE25:
	ld (D_AE18),a	; AE25 32 18 AE
Z_AE28:
	call Z_AE34	; AE28 CD 34 AE
	jp	Z_AE2B	; мост в следующий кусок
	org	0xAF0E
D_AF0E:
Z_AF0E:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; AF0E
	org	0xAF17
D_AF17:
Z_AF17:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; AF17
	org	0xAF27
D_AF27:
Z_AF27:
	db	0x00, 0x00, 0x00	; AF27
	org	0xAF2A
D_AF2A:
Z_AF2A:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; AF2A
	org	0xAF33
D_AF33:
Z_AF33:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; AF33
	org	0xAF43
D_AF43:
Z_AF43:
	db	0x00, 0x00, 0x00	; AF43
	org	0xAF46
D_AF46:
Z_AF46:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; AF46
	org	0xAF55
D_AF55:
Z_AF55:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; AF55
	org	0xAF5E
D_AF5E:
Z_AF5E:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; AF5E
	org	0xAF6E
D_AF6E:
Z_AF6E:
	db	0x00, 0x00, 0x00	; AF6E
	org	0xAF71
D_AF71:
Z_AF71:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; AF71
	org	0xAF7A
D_AF7A:
Z_AF7A:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; AF7A
	org	0xAF8A
D_AF8A:
Z_AF8A:
	db	0x00, 0x00, 0x00	; AF8A
	org	0xAF8D
D_AF8D:
Z_AF8D:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xDE, 0xD5, 0x20	; AF8D
	org	0xAF9D
D_AF9D:
Z_AF9D:
	db	0x02, 0xCB, 0xE3, 0x7B, 0x32, 0x4E, 0xAC, 0xC9, 0xD5, 0x20, 0x02, 0xCB, 0xE3, 0x7B, 0x32, 0x4E	; AF9D
	org	0xAFAD
D_AFAD:
Z_AFAD:
	db	0xAC, 0xC9, 0xFE, 0x00, 0x7F, 0x00, 0x9B, 0x80, 0xFF, 0x00, 0x7F, 0x00, 0x51, 0x80, 0xFF, 0x80	; AFAD
	org	0xAFBD
D_AFBD:
Z_AFBD:
	db	0x7F, 0x00, 0x82, 0x40, 0xFF, 0x00, 0x3F, 0x00, 0x82, 0x3C, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00	; AFBD
	org	0xAFCD
Z_AE2B:
	ld (il_tmp),hl	; AE2B DD 21 5D AE
	ld hl,D_AE5D
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_AE2F:
	ld hl,D_AE57	; AE2F 21 57 AE
Z_AE32:
	jp Z_AE40	; AE32 18 0C
Z_AE34:
	ld (il_tmp),hl	; AE34 DD 21 6D AE
	ld hl,D_AE6D
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_AE38:
	ld hl,D_AE67	; AE38 21 67 AE
Z_AE3B:
	jp Z_AE40	; AE3B 18 03
Z_AE40:
	ld bc,0x05	; AE40 01 05 00
Z_AE43:
	call il_ix_lde	; AE43 DD 5E 00
	db 0x00
Z_AE46:
	ld (il_tmp),hl	; AE46 DD 23
	ld hl,(z80_ix)
	inc hl
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_AE48:
	call il_ix_ldd	; AE48 DD 56 00
	db 0x00
Z_AE4B:
	ld (il_tmp),hl	; AE4B DD 23
	ld hl,(z80_ix)
	inc hl
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_AE4D:
	call il_ldi	; AE4D ED A0
Z_AE4F:
	jp pe,Z_AE43	; AE4F EA 43 AE
	jp	Z_AE52	; мост в следующий кусок
	org	0xB01F
D_B01F:
Z_B01F:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B01F
	org	0xB02F
D_B02F:
Z_B02F:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B02F
	org	0xB03F
D_B03F:
Z_B03F:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B03F
	org	0xB04F
D_B04F:
Z_B04F:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B04F
	org	0xB05F
D_B05F:
Z_B05F:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B05F
	org	0xB06F
D_B06F:
Z_B06F:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B06F
	org	0xB07F
D_B07F:
Z_B07F:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B07F
	org	0xB08F
D_B08F:
Z_B08F:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B08F
	org	0xB09F
D_B09F:
Z_B09F:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B09F
	org	0xB0AF
D_B0AF:
Z_B0AF:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B0AF
	org	0xB0BF
D_B0BF:
Z_B0BF:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B0BF
	org	0xB0CF
D_B0CF:
Z_B0CF:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B0CF
	org	0xB0DF
D_B0DF:
Z_B0DF:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B0DF
	org	0xB0EF
D_B0EF:
Z_B0EF:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B0EF
	org	0xB0FF
D_B0FF:
Z_B0FF:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B0FF
	org	0xB10F
D_B10F:
Z_B10F:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B10F
	org	0xB11F
D_B11F:
Z_B11F:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B11F
	org	0xB12F
D_B12F:
Z_B12F:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B12F
	org	0xB13F
D_B13F:
Z_B13F:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B13F
	org	0xB14F
D_B14F:
Z_B14F:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B14F
	org	0xB15F
D_B15F:
Z_B15F:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B15F
	org	0xB16F
D_B16F:
Z_B16F:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B16F
	org	0xB17F
D_B17F:
Z_B17F:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B17F
	org	0xB18F
D_B18F:
Z_B18F:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B18F
	org	0xB19F
D_B19F:
Z_B19F:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B19F
	org	0xB1AF
D_B1AF:
Z_B1AF:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B1AF
	org	0xB1BF
Z_AE52:
	ld a,(hl)	; AE52 7E
Z_AE53:
	ld (D_AC4F),a	; AE53 32 4F AC
Z_AE56:
	ret	; AE56 C9
Z_AEFA:
	ld (TEXT_ROW),hl	; AEFA 22 02 41
Z_AEFD:
	ld a,(de)	; AEFD 1A
Z_AEFE:
	inc de	; AEFE 13
Z_AEFF:
	cp 0xFF	; AEFF FE FF
Z_AF01:
	ret z	; AF01 C8
	jp	Z_AF02	; мост в следующий кусок
	org	0xB1CF
D_B1CF:
Z_B1CF:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B1CF
	org	0xB1DF
D_B1DF:
Z_B1DF:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B1DF
	org	0xB1EF
D_B1EF:
Z_B1EF:
	db	0x00, 0x00, 0x00	; B1EF
	org	0xB1F5
D_B1F5:
Z_B1F5:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; B1F5
	org	0xB1FE
Z_AF02:
	rst 0x18	; AF02 DF
Z_AF03:
	jp Z_AEFD	; AF03 18 F8
Z_AF05:
	call Z_37CC	; AF05 CD CC 37
Z_AF08:
	call Z_3811	; AF08 CD 11 38
Z_AF0B:
	jp NATIVE_PADS	; AF0B C3 D0 6C
Z_B01C:
	jp 0x01E9	; B01C C3 E9 01
Z_B1F2:
	jp 0x01E6	; B1F2 C3 E6 01
Z_B1FE:
	jp 0x01EF	; B1FE C3 EF 01
	org	0xB251
D_B251:
Z_B251:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC9	; B251
