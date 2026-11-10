# Покрытие эталонами (A0, tools/native/golden_cover.js)

Команд игры: 4244; исполнено: 4016 (94.6%); мёртвых с причиной: 181; не покрыто: 47.

## Сценарии

| сценарий | кадров | ходов | событий | команд | новых |
|---|---|---|---|---|---|
| 1p_amateur_shooter | 11556 | 749 | 123407 | 2851 | 2851 |
| 1p_chase | 10961 | 842 | 123332 | 2786 | 82 |
| 1p_long | 39999 | 4548 | 510188 | 3735 | 809 |
| 1p_nba_mix | 10486 | 781 | 117511 | 3057 | 5 |
| 1p_random_s1 | 9134 | 752 | 104432 | 3510 | 7 |
| 1p_random_s2 | 8325 | 768 | 100496 | 3531 | 0 |
| 1p_random_s3 | 8263 | 769 | 99963 | 3393 | 17 |
| 1p_rookie_random | 7499 | 707 | 90377 | 3493 | 0 |
| 2p_chase | 5391 | 598 | 65736 | 1783 | 6 |
| 2p_random | 5627 | 623 | 68689 | 2328 | 1 |
| 2p_shooter | 5696 | 580 | 68270 | 2327 | 0 |
| fouls_end | 16255 | 1587 | 197961 | 3597 | 40 |
| fouls_end2 | 22572 | 2039 | 266225 | 3677 | 0 |
| menu_music | 9256 | 0 | 88856 | 554 | 8 |
| names_long | 1078 | 95 | 14341 | 2979 | 140 |
| names_pause | 2121 | 351 | 33243 | 2447 | 25 |
| search_1004 | 9890 | 787 | 112627 | 3458 | 8 |
| search_1007 | 10656 | 819 | 120101 | 3346 | 0 |
| search_1011 | 15999 | 1595 | 195787 | 3620 | 8 |
| search_1013 | 10785 | 908 | 127022 | 3594 | 0 |
| search_1018 | 9252 | 880 | 113008 | 3456 | 4 |
| search_1100 | 6429 | 846 | 87082 | 2600 | 2 |
| search_1105 | 10082 | 854 | 118204 | 3292 | 0 |
| search_1124 | 15999 | 1332 | 184386 | 3571 | 0 |
| search_2023 | 8673 | 823 | 104791 | 3484 | 3 |

## Непокрытые процедуры и участки

| вход | команд | не покрыто | участки |
|---|---|---|---|
| 99BC | 44 | 12 | 99DE..99EE 99F7..99FB 9A13 |
| 95A1 | 195 | 10 | 9842 9889..9895 98AA..98AC |
| 8C77 | 63 | 6 | 8CB7..8CC0 |
| 9041 | 64 | 6 | 90C9..90D6 |
| 8E73 | 49 | 4 | 8EF5..8EFD |
| 8F76 | 80 | 3 | 8FCB 8FDA..8FDB |
| A82C | 63 | 2 | A847 A87F |
| 8ADD | 119 | 1 | 8BE2 |
| 97D6 | 14 | 1 | 97DD |
| 9ED4 | 46 | 1 | 9EF1 |
| A232 | 17 | 1 | A257 |

## Мёртвый код (cfg/native_dead.json)

- 3B9D-3BBF: print 3B53, graphics-mode glyph path: D_341C (MSX screen-mode flag) is 0 in the image and no instruction writes it
- 39E6-3A2B: address calc of the graphics-mode glyph path (only caller 3BA8, dead with D_341C = 0)
- 3B3F-3B46: colour store of the graphics-mode glyph path (only caller 3BBF, dead with D_341C = 0)
- 3943-3979: line input 38E8, number parse: taken when (411F) <> 0, but 38E8 itself stores BC = 0 there (ld bc,0 at 38E8)
- 3846-385F: MSX key-bit test helper: no CALL/JP and no pointer to 3846 anywhere in the image
- 361B-3633: boot 35C0, error branch after 3662 (RAM search): the port patches the search to 'found' (D3FA), so carry never comes back
- 36D7-36EF: key parse 3811, exit to MSX BASIC on a key whose table value is 05: the table at 3438 (88 entries, read-only) has no 05
- 8505-8507: NOPs left by the 'call CC76 -> NOP' patch; 8502 jumps over them to 8515
- 34AF-34B2: MSX box fill: its two calls (A62E, A6F7) are patched to MENU_BOX_CLEAR; no other reference
- 93A0: jump-table entry 'jp 9E82' that nothing calls (no CALL/JP/pointer to 93A0)
- AB25: jump-table entry 'jp ABFF' that nothing calls (no CALL/JP/pointer to AB25)
- 3BE7-3BFC: print 3B53, backspace at column 0 (wrap to the previous row): the only BS printer is the line input, which starts at column 9 with at most 9 characters
- 3BCC-3BD8: print 3B53, CR (0D), TAB (09) and the wrap past column 31: the game prints only 20..5F plus BS/10h of the line input, and never past column 30 (PROBE=3B53 over the scenarios; strings are FF-terminated fixed texts and numbers)
- 3BD9-3BDC: print 3B53, CR (0D), TAB (09) and the wrap past column 31: the game prints only 20..5F plus BS/10h of the line input, and never past column 30 (PROBE=3B53 over the scenarios; strings are FF-terminated fixed texts and numbers)
- 3BFE-3C12: print 3B53, CR (0D), TAB (09) and the wrap past column 31: the game prints only 20..5F plus BS/10h of the line input, and never past column 30 (PROBE=3B53 over the scenarios; strings are FF-terminated fixed texts and numbers)
- AAEB-AAEE: music player AA8F, end of a tune with D_AA82 (MUSIC_LOOP) <> 0: AA82 is 0 in the image and every store to it writes 0 (84FF, 850F, AAB0, splash_anim)
- 9E0B-9E0F: 9DC2: RET Z on bit 4,(ix+0) above; the same bit is tested again at 9E05 (always set there)
- 88C4: 870E: 88BE is reached only when A133 returned Z, which it does only with bit 6,(ix+1) clear; 88C4 needs that bit set (8963 does not touch it)

## Ожидания платформы (cfg/native_waits.json)

- 3A4A-3A55: delay loop B x 0362h (key poll 3A56, line input 38E8): spends real time while the frame IRQ runs; traced as a platform wait, the model calls it as one
