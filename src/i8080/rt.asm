; СГЕНЕРИРОВАНО tools/recompile_i8080.py — правки вносить ТУДА.
; РАНТАЙМ РЕКОМПИЛЯЦИИ Z80 -> i8080: хелперы (ix+d)/(iy+d) с общими
; прологом и эпилогом, ldir/lddr, ex af,af', замена регистру R.
; Контракт хелперов: беречь HL, A и ФЛАГИ; DE/BC не трогать.
; ЭТОТ ФАЙЛ НЕ СОБИРАЕТСЯ отдельно: те же процедуры лежат внутри
; src/i8080/game.asm, разложенные по свободным кускам образа
; (docs/recompilation.md, §5).  Здесь — чтобы их можно было читать.
;
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
il_ret_hl:                              ; вернуть HL (флаги не трогаются)
                ld      hl,(il_tmp2)
                ret
il_epi:                                 ; вернуть AF и HL вызывателя
                ld      hl,(il_f)
                push    hl
                pop     af
                ld      hl,(il_tmp2)
                ret
il_epi_a:                               ; флаги и HL вызывателя, a = прочитанное
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
il_rnd:                                 ; ЗАМЕНА `ld a,r` (docs/determinism.md)
                ld      a,(z80_r)       ; у i8080 регистра R нет; ряд ведёт
                add     a,0x9D          ; эта ячейка: +0x9D на чтение,
                ld      (z80_r),a       ; +1 на кадр (V_ISR связки)
                ret
il_ldir:                                ; ldir: (hl)->(de), bc байт (0 = 65536)
                push    af              ; Z80 ldir не трогает ни A, ни CY
                ld      a,c
                and     3
                jp      z,il_ldir_q
il_ldir_s:                              ; сначала bc mod 4 по байту
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
il_ldir_q:                              ; bc кратно 4: bc/4 проходов по 4 байта
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
il_exaf:                                ; ex af,af' через теневую ячейку
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
il_exx:                                 ; exx: BC/DE/HL <-> z80_bc2/de2/hl2
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
il_ldi:                                 ; ldi; P (pe) = BC <> 0, A kept
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
