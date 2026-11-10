; СГЕНЕРИРОВАНО tools/recompile_i8080.py — правки вносить ТУДА.
; Код игры Basket Master, перекомпилированный Z80 -> i8080 (Вектор-06Ц, ВМ80А).
; Эталон — disasm/v06/game.asm (раскладка Вектора, гейт tools/disasm_v06.py --verify).
; Метод, врезки, гейты и такты — docs/recompilation.md.


BLIT_PASS_FLAG:	equ	0x34DF
BLIT_SRC:	equ	0x3302
BLIT_Y:	equ	0x3300
CROWD_TICK:	equ	0x761A
GAME_ISR_HOOK:	equ	0x4141
G_KEY_ASCII:	equ	0x4110
G_KEY_CODE:	equ	0x410F
HUD_ICON:	equ	0xB455
MENU_BOX_CLEAR:	equ	0x18F6
MENU_KEY:	equ	0x06BB
NATIVE_PADS:	equ	0x6D85
REPLAY_SCENE:	equ	0x13EA
REPLAY_STATE_BEGIN:	equ	0x13E7
RING_PULL:	equ	0x768D
RING_PUSH:	equ	0x7648
RING_REPLAY:	equ	0x767C
RING_RESET:	equ	0x7671
TEXT_COL:	equ	0x4103
TEXT_ROW:	equ	0x4102
IX0	equ	0x9425
IX1	equ	0x9426
IX2	equ	0x9427
IX3	equ	0x9428
IXA	equ	0x942F
IXM1	equ	0x9424
IXM2	equ	0x9423
IXM7	equ	0x941E
IY0	equ	0x940B
IY2	equ	0x940D
IY3	equ	0x940E
IYM1	equ	0x940A
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

	org	0x0C7E
NAT_action_220:
	and 0x20
NAT_action_221:
	ret nz
NAT_action_222:
	ld a,(hl)
NAT_action_223:
	and 0x80
NAT_action_224:
	jp z,ac_19
NAT_action_225:
	dec hl
NAT_action_226:
	dec hl
NAT_action_227:
	ld a,(hl)
NAT_action_228:
	or 0x20
NAT_action_229:
	ld (hl),a
NAT_action_230:
	ret
ac_19:
NAT_action_232:
	ld a,(hl)
NAT_action_233:
	and 0x10
NAT_action_234:
	jp nz,ac_rel
NAT_action_235:
	inc hl
NAT_action_236:
	ld a,(hl)
NAT_action_237:
	and 8
NAT_action_238:
	ret nz
NAT_action_239:
	ld a,(0x93EB)
NAT_action_240:
	and 2
NAT_action_241:
	jp z,ac_34
NAT_action_242:
	ld a,(hl)
NAT_action_243:
	rrca
NAT_action_244:
	ld b,a
NAT_action_245:
	ld a,(0x93EB)
NAT_action_246:
	xor b
NAT_action_247:
	and 0x80
NAT_action_248:
	ret z
ac_34:
NAT_action_250:
	ld a,(hl)
NAT_action_251:
	and 0x40
NAT_action_252:
	ret z
NAT_action_253:
	ld a,(hl)
NAT_action_254:
	and 8
NAT_action_255:
	ret nz
NAT_action_256:
	jp Z_8E73
ac_rel:
NAT_action_258:
	ld hl,(z80_ix)
NAT_action_259:
	inc hl
NAT_action_260:
	ld a,(hl)
NAT_action_261:
	and 2
NAT_action_262:
	jp nz,ac_b7
NAT_action_263:
	ld a,(hl)
NAT_action_264:
	and 4
NAT_action_265:
	jp nz,ac_7e
NAT_action_266:
	dec hl
NAT_action_267:
	dec hl
NAT_action_268:
	dec hl
NAT_action_269:
	ld a,(hl)
NAT_action_270:
	and 0x10
NAT_action_271:
	ret z
NAT_action_272:
	ld hl,(z80_ix)
NAT_action_273:
	inc hl
NAT_action_274:
	ld b,(hl)
NAT_action_275:
	inc hl
NAT_action_276:
	inc hl
NAT_action_277:
	ld a,(hl)
NAT_action_278:
	ld c,a
NAT_action_279:
	ld a,b
NAT_action_280:
	rrca
NAT_action_281:
	ld a,c
NAT_action_282:
	jp nc,ac_r1
NAT_action_283:
	cp 0x60
NAT_action_284:
	jp nc,ac_lo
NAT_action_285:
	jp ac_r2
ac_r1:
NAT_action_287:
	cp 0x14
NAT_action_288:
	jp c,ac_lo
ac_r2:
NAT_action_290:
	ld hl,(z80_ix)
NAT_action_291:
	dec hl
NAT_action_292:
	ld a,(hl)
NAT_action_293:
	and 4
NAT_action_294:
	jp nz,ac_hi
NAT_action_295:
	inc hl
NAT_action_296:
	ld a,(hl)
NAT_action_297:
	or 0x80
NAT_action_298:
	ld (hl),a
NAT_action_299:
	dec hl
NAT_action_300:
	dec hl
NAT_action_301:
	ld a,(hl)
NAT_action_302:
	or 0x20
NAT_action_303:
	ld (hl),a
NAT_action_304:
	xor a
NAT_action_305:
	ld de,9
NAT_action_306:
	add hl,de
NAT_action_307:
	ld (hl),a
NAT_action_308:
	jp Z_9DC2
ac_hi:
NAT_action_310:
	inc hl
NAT_action_311:
	inc hl
NAT_action_312:
	ld a,(hl)
NAT_action_313:
	or 4
NAT_action_314:
	ld (hl),a
NAT_action_315:
	jp ac_7e
ac_lo:
NAT_action_317:
	ld hl,(z80_ix)
NAT_action_318:
	inc hl
NAT_action_319:
	ld a,(hl)
NAT_action_320:
	or 2
NAT_action_321:
	ld (hl),a
ac_b7:
NAT_action_323:
	ld hl,(z80_ix)
NAT_action_324:
	dec hl
NAT_action_325:
	ld c,(hl)
NAT_action_326:
	inc hl
NAT_action_327:
	inc hl
NAT_action_328:
	inc hl
NAT_action_329:
	ld a,(hl)
NAT_action_330:
	cp 0x55
NAT_action_331:
	jp c,ac_b1
NAT_action_332:
	ld a,c
NAT_action_333:
	rrca
NAT_action_334:
	ld a,1
NAT_action_335:
	jp nc,ac_pose
NAT_action_336:
	ld a,c
NAT_action_337:
	and 2
NAT_action_338:
	jp nz,ac_c9
NAT_action_339:
	jp Z_90EF
ac_b1:
NAT_action_341:
	ld a,c
NAT_action_342:
	rrca
NAT_action_343:
	ld a,3
NAT_action_344:
	jp nc,ac_pose
NAT_action_345:
	ld a,c
NAT_action_346:
	and 2
NAT_action_347:
	jp nz,Z_90EF
ac_c9:
NAT_action_349:
	ld hl,(z80_ix)
NAT_action_350:
	inc hl
NAT_action_351:
	ld a,(hl)
NAT_action_352:
	rrca
NAT_action_353:
	ld a,4
NAT_action_354:
	jp nc,ac_pose
NAT_action_355:
	ld a,0x0C
NAT_action_356:
	jp ac_pose
ac_7e:
NAT_action_358:
	ld hl,(z80_ix)
NAT_action_359:
	dec hl
NAT_action_360:
	ld c,(hl)
NAT_action_361:
	inc hl
NAT_action_362:
	inc hl
NAT_action_363:
	ld a,(hl)
NAT_action_364:
	rrca
NAT_action_365:
	jp nc,ac_7f
NAT_action_366:
	ld a,c
NAT_action_367:
	and 4
NAT_action_368:
	ld a,0x0C
NAT_action_369:
	jp z,ac_pose
NAT_action_370:
	ld a,c
NAT_action_371:
	and 8
NAT_action_372:
	jp nz,Z_90EF
NAT_action_373:
	ld a,1
NAT_action_374:
	jp ac_pose
ac_7f:
NAT_action_376:
	ld a,c
NAT_action_377:
	and 4
NAT_action_378:
	ld a,4
NAT_action_379:
	jp z,ac_pose
NAT_action_380:
	ld a,c
NAT_action_381:
	and 8
NAT_action_382:
	jp z,Z_90EF
NAT_action_383:
	ld a,3
ac_pose:
NAT_action_385:
	ld hl,(z80_ix)
NAT_action_386:
	dec hl
NAT_action_387:
	ld (hl),a
NAT_action_388:
	jp Z_9DC2
Z_90EF:
NAT_action_390:
	ld hl,(z80_ix)
NAT_action_391:
	inc hl
NAT_action_392:
	ld a,(hl)
NAT_action_393:
	rrca
NAT_action_394:
	ld a,2
NAT_action_395:
	jp nc,ac_s1
NAT_action_396:
	ld a,0x82
ac_s1:
NAT_action_398:
	ld (0x93EB),a
NAT_action_399:
	dec hl
NAT_action_400:
	ld a,(hl)
NAT_action_401:
	and 0xE3
NAT_action_402:
	ld (hl),a
NAT_action_403:
	call Z_9391
NAT_action_404:
	ld a,0xFD
NAT_action_405:
	call ac_at
NAT_action_406:
	ld a,(hl)
NAT_action_407:
	ld (0x944D),a
NAT_action_408:
	dec hl
NAT_action_409:
	ld e,(hl)
NAT_action_410:
	dec e
NAT_action_411:
	ld d,0
NAT_action_412:
	ld a,0x0A
NAT_action_413:
	call ac_at2
NAT_action_414:
	ld a,(hl)
NAT_action_415:
	ld (0x944E),a
NAT_action_416:
	ld hl,0x943A
NAT_action_417:
	add hl,de
NAT_action_418:
	ld a,(hl)
NAT_action_419:
	ld (0x9450),a
NAT_action_420:
	ld hl,(z80_ix)
NAT_action_421:
	inc hl
NAT_action_422:
	ld b,(hl)
NAT_action_423:
	inc hl
NAT_action_424:
	ld a,(hl)
NAT_action_425:
	sub 0x58
NAT_action_426:
	jp nc,ac_s2
NAT_action_427:
	cpl
NAT_action_428:
	inc a
ac_s2:
NAT_action_430:
	ld c,a
NAT_action_431:
	inc hl
NAT_action_432:
	ld a,(hl)
NAT_action_433:
	ld d,a
NAT_action_434:
	ld a,b
NAT_action_435:
	rrca
NAT_action_436:
	ld a,d
NAT_action_437:
	jp nc,ac_s3
NAT_action_438:
	cpl
NAT_action_439:
	inc a
NAT_action_440:
	add a,0x74
ac_s3:
NAT_action_442:
	add a,c
NAT_action_443:
	or a
NAT_action_444:
	rra
NAT_action_445:
	ld (0x944F),a
NAT_action_446:
	inc hl
NAT_action_447:
	ld a,(hl)
NAT_action_448:
	sub 0x1A
NAT_action_449:
	ld e,a
NAT_action_450:
	inc hl
NAT_action_451:
	ld d,(hl)
NAT_action_452:
	ld hl,(z80_ix)
NAT_action_453:
	dec hl
NAT_action_454:
	ld c,(hl)
NAT_action_455:
	ld a,b
NAT_action_456:
	rrca
NAT_action_457:
	jp nc,ac_s5
NAT_action_458:
	inc d
NAT_action_459:
	ld a,c
NAT_action_460:
	rrca
NAT_action_461:
	jp c,ac_s6
NAT_action_462:
	ld a,d
NAT_action_463:
	add a,8
	jp	NAT_action_464	; мост в следующий кусок
	org	0x1548
NAT_action_464:
	ld d,a
NAT_action_465:
	jp ac_s7
ac_s5:
NAT_action_467:
	dec d
NAT_action_468:
	ld a,c
NAT_action_469:
	rrca
NAT_action_470:
	jp nc,ac_s7
ac_s6:
NAT_action_472:
	inc d
NAT_action_473:
	inc d
ac_s7:
NAT_action_475:
	ex de,hl
NAT_action_476:
	ld (0x93F1),hl
NAT_action_477:
	ex de,hl
NAT_action_478:
	inc hl
NAT_action_479:
	inc hl
NAT_action_480:
	inc hl
NAT_action_481:
	ld a,(hl)
NAT_action_482:
	ld e,a
NAT_action_483:
	ex de,hl
NAT_action_484:
	ld (0x93F3),hl
NAT_action_485:
	ex de,hl
NAT_action_486:
	dec hl
NAT_action_487:
	dec hl
NAT_action_488:
	dec hl
NAT_action_489:
	dec hl
NAT_action_490:
	ld a,(hl)
NAT_action_491:
	or 0x40
NAT_action_492:
	ld (hl),a
NAT_action_493:
	inc hl
NAT_action_494:
	inc hl
NAT_action_495:
	inc hl
NAT_action_496:
	ld a,(hl)
NAT_action_497:
	or 0x10
NAT_action_498:
	ld (hl),a
NAT_action_499:
	ret
Z_8E73:
NAT_action_501:
	ld a,(0x93EB)
NAT_action_502:
	ld c,a
NAT_action_503:
	and 8
NAT_action_504:
	jp z,ac_t1
NAT_action_505:
	ld a,0x10
NAT_action_506:
	call ac_at
NAT_action_507:
	inc (hl)
ac_t1:
NAT_action_509:
	ld hl,(z80_ix)
NAT_action_510:
	inc hl
NAT_action_511:
	ld a,(hl)
NAT_action_512:
	rrca
NAT_action_513:
	ld a,0x21
NAT_action_514:
	jp nc,ac_t2
NAT_action_515:
	ld a,0xA1
ac_t2:
NAT_action_517:
	ld (0x93EB),a
NAT_action_518:
	xor a
NAT_action_519:
	ld (0x93F5),a
NAT_action_520:
	ld hl,(z80_iy)
NAT_action_521:
	dec hl
NAT_action_522:
	dec hl
NAT_action_523:
	ld a,(hl)
NAT_action_524:
	and 0xDF
NAT_action_525:
	ld (hl),a
NAT_action_526:
	inc hl
NAT_action_527:
	inc hl
NAT_action_528:
	ld a,(hl)
NAT_action_529:
	ld b,a
NAT_action_530:
	and 0x43
NAT_action_531:
	ld (hl),a
NAT_action_532:
	inc hl
NAT_action_533:
	ld a,(hl)
NAT_action_534:
	and 0xA9
NAT_action_535:
	ld (hl),a
NAT_action_536:
	ld hl,(z80_ix)
NAT_action_537:
	ld a,(hl)
NAT_action_538:
	or 0x10
NAT_action_539:
	ld (hl),a
NAT_action_540:
	dec hl
NAT_action_541:
	dec hl
NAT_action_542:
	ld a,(hl)
NAT_action_543:
	and 0xEF
NAT_action_544:
	ld (hl),a
NAT_action_545:
	ld de,8
NAT_action_546:
	add hl,de
NAT_action_547:
	ld (hl),3
NAT_action_548:
	ld a,c
NAT_action_549:
	rrca
NAT_action_550:
	jp c,ac_t3
NAT_action_551:
	ld hl,(z80_ix)
NAT_action_552:
	ld a,(hl)
NAT_action_553:
	rrca
NAT_action_554:
	jp c,ac_t3
NAT_action_555:
	ld a,(0x93F1)
NAT_action_556:
	ld c,a
NAT_action_557:
	ld a,(0x93F3)
NAT_action_558:
	sub c
NAT_action_559:
	cp 0x14
NAT_action_560:
	jp c,ac_t3
NAT_action_561:
	dec hl
NAT_action_562:
	dec hl
NAT_action_563:
	ld a,(hl)
NAT_action_564:
	or 0x40
NAT_action_565:
	ld (hl),a
NAT_action_566:
	inc hl
NAT_action_567:
	inc hl
NAT_action_568:
	inc hl
NAT_action_569:
	inc hl
NAT_action_570:
	ld a,(hl)
NAT_action_571:
	sub 2
NAT_action_572:
	inc hl
NAT_action_573:
	ld c,(hl)
NAT_action_574:
	inc hl
NAT_action_575:
	ld (hl),a
NAT_action_576:
	inc hl
NAT_action_577:
	ld (hl),c
ac_t3:
NAT_action_579:
	ld a,b
NAT_action_580:
	and 0x20
NAT_action_581:
	jp z,Z_9DC2
NAT_action_582:
	ld hl,(z80_iy)
NAT_action_583:
	ld de,8
NAT_action_584:
	add hl,de
NAT_action_585:
	ld (hl),4
NAT_action_586:
	xor a
	jp	NAT_action_587	; мост в следующий кусок
	org	0x1748
NAT_action_587:
	ld (0x93D3),a
NAT_action_588:
	jp Z_9DC2
ac_land:
NAT_action_590:
	call Z_9009
NAT_action_591:
	ld hl,(z80_ix)
NAT_action_592:
	inc hl
NAT_action_593:
	inc hl
NAT_action_594:
	ld b,(hl)
NAT_action_595:
	inc hl
NAT_action_596:
	inc hl
NAT_action_597:
	ld a,(hl)
NAT_action_598:
	add a,4
NAT_action_599:
	ld (hl),a
NAT_action_600:
	cp b
NAT_action_601:
	ret c
	jp	NAT_action_602	; мост в следующий кусок
	org	0x18B7
NAT_action_602:
	ld hl,(z80_ix)
NAT_action_603:
	ld a,(hl)
NAT_action_604:
	ld b,a
NAT_action_605:
	and 0x10
NAT_action_606:
	ld (hl),a
NAT_action_607:
	inc hl
NAT_action_608:
	ld a,(hl)
NAT_action_609:
	and 0x71
NAT_action_610:
	ld (hl),a
NAT_action_611:
	ld de,5
	jp	NAT_action_612	; мост в следующий кусок
	org	0x190A
NAT_action_612:
	add hl,de
NAT_action_613:
	ld (hl),0
NAT_action_614:
	ld a,b
NAT_action_615:
	and 8
NAT_action_616:
	ret z
NAT_action_617:
	ld a,(0x93D6)
NAT_action_618:
	and a
NAT_action_619:
	ret nz
NAT_action_620:
	ld e,1
NAT_action_621:
	jp Z_9919
ac_at:
NAT_action_623:
	ld hl,(z80_ix)
NAT_action_624:
	ld e,a
NAT_action_625:
	add a,a
NAT_action_626:
	sbc a,a
NAT_action_627:
	ld d,a
NAT_action_628:
	add hl,de
NAT_action_629:
	ret
ac_at2:
NAT_action_631:
	push de
NAT_action_632:
	call ac_at
NAT_action_633:
	pop de
NAT_action_634:
	ret
Z_869C:
NAT_ai_1:
	ld hl,0
NAT_ai_2:
	ld (0x8696),hl
NAT_ai_3:
	ld a,(0x93D2)
NAT_ai_4:
	and 3
NAT_ai_5:
	sub 4
NAT_ai_6:
	cpl
NAT_ai_7:
	inc a
NAT_ai_8:
	dec a
NAT_ai_9:
	ld (ai_lvl),a
NAT_ai_10:
	call Z_386E
NAT_ai_11:
	and 3
NAT_ai_12:
	ld c,0x0C
NAT_ai_13:
	jp z,ai_s1
NAT_ai_14:
	cp 2
NAT_ai_15:
	ld c,1
NAT_ai_16:
	jp c,ai_s1
NAT_ai_17:
	ld c,4
NAT_ai_18:
	jp z,ai_s1
NAT_ai_19:
	ld c,3
ai_s1:
NAT_ai_21:
	ld a,c
NAT_ai_22:
	ld (0x8699),a
NAT_ai_23:
	ld hl,IX0
NAT_ai_24:
	ld (z80_ix),hl
NAT_ai_25:
	ld hl,IY0
NAT_ai_26:
	ld (z80_iy),hl
Z_86D0:
NAT_ai_28:
	call Z_A160
NAT_ai_29:
	push af
NAT_ai_30:
	ld de,0x46
NAT_ai_31:
	ld hl,0x66
NAT_ai_32:
	jp c,ai_t1
NAT_ai_33:
	ld a,(IY2)
NAT_ai_34:
	ld b,a
NAT_ai_35:
	ld a,(IX2)
NAT_ai_36:
	cp b
NAT_ai_37:
	ld hl,0x4E
NAT_ai_38:
	jp c,ai_t1
NAT_ai_39:
	ld de,0x5E
NAT_ai_40:
	ld hl,0x68
ai_t1:
NAT_ai_42:
	call Z_388A
NAT_ai_43:
	ld h,0x14
NAT_ai_44:
	ld a,l
NAT_ai_45:
	and 0xFE
NAT_ai_46:
	ld l,a
NAT_ai_47:
	ld (0x869A),hl
NAT_ai_48:
	pop af
NAT_ai_49:
	ld de,0x18
NAT_ai_50:
	jp c,ai_t2
NAT_ai_51:
	ld de,0x0A
ai_t2:
NAT_ai_53:
	ld hl,0x22
NAT_ai_54:
	call Z_388A
NAT_ai_55:
	ld a,l
NAT_ai_56:
	and 0xFE
NAT_ai_57:
	ld (0x869B),a
NAT_ai_58:
	ret
Z_870E:
NAT_ai_60:
	ld hl,IX0
NAT_ai_61:
	ld (z80_ix),hl
NAT_ai_62:
	ld hl,IY0
NAT_ai_63:
	ld (z80_iy),hl
NAT_ai_64:
	ld a,(0x93D6)
NAT_ai_65:
	and a
NAT_ai_66:
	jp z,ai_72d
NAT_ai_67:
	ld a,(IX0)
NAT_ai_68:
	and 0x10
NAT_ai_69:
	jp z,ai_77f
NAT_ai_70:
	ld a,(IX0)
NAT_ai_71:
	rrca
NAT_ai_72:
	jp c,ai_776
NAT_ai_73:
	ld a,0x10
NAT_ai_74:
	jp ai_8e5
ai_72d:
NAT_ai_76:
	ld a,(0x9400)
NAT_ai_77:
	and a
NAT_ai_78:
	jp z,ai_749
NAT_ai_79:
	ld b,a
NAT_ai_80:
	and 0x80
NAT_ai_81:
	ret nz
NAT_ai_82:
	ld a,b
NAT_ai_83:
	and 7
NAT_ai_84:
	cp 4
NAT_ai_85:
	ret nz
NAT_ai_86:
	ld hl,0x6454
NAT_ai_87:
	ld a,(IX1)
NAT_ai_88:
	and 0xBF
NAT_ai_89:
	ld (IX1),a
NAT_ai_90:
	ld a,(IX2)
NAT_ai_91:
	and 0xFE
NAT_ai_92:
	ld (IX2),a
NAT_ai_93:
	jp ai_89f
ai_749:
NAT_ai_95:
	ld a,(IX0)
NAT_ai_96:
	and 0x10
NAT_ai_97:
	jp z,ai_873
NAT_ai_98:
	ld a,(IX0)
NAT_ai_99:
	rrca
NAT_ai_100:
	jp nc,ai_783
NAT_ai_101:
	ld a,(IX0)
NAT_ai_102:
	and 0x20
NAT_ai_103:
	ld a,(0x8699)
NAT_ai_104:
	jp nz,ai_8e5
NAT_ai_105:
	ld a,(IX0)
NAT_ai_106:
	and 8
NAT_ai_107:
	jp nz,ai_776
NAT_ai_108:
	ld a,(IX3)
NAT_ai_109:
	cp 0x20
NAT_ai_110:
	jp nc,ai_77f
NAT_ai_111:
	call Z_A169
NAT_ai_112:
	jp nz,ai_8c6
NAT_ai_113:
	jp ai_77f
ai_776:
NAT_ai_115:
	ld a,(IX0)
NAT_ai_116:
	and 2
NAT_ai_117:
	ld a,0x10
NAT_ai_118:
	jp nz,ai_8e5
ai_77f:
NAT_ai_120:
	xor a
NAT_ai_121:
	jp ai_8e5
ai_783:
NAT_ai_123:
	ld a,(0x8697)
NAT_ai_124:
	and a
NAT_ai_125:
	jp z,ai_78f
NAT_ai_126:
	dec a
NAT_ai_127:
	ld (0x8697),a
NAT_ai_128:
	jp nz,ai_7a2
ai_78f:
NAT_ai_130:
	ld a,(IXA)
NAT_ai_131:
	cp 4
NAT_ai_132:
	jp nc,ai_7fe
NAT_ai_133:
	ld c,a
NAT_ai_134:
	call Z_A172
NAT_ai_135:
	or 3
NAT_ai_136:
	add a,c
NAT_ai_137:
	rlca
NAT_ai_138:
	ld (0x8697),a
ai_7a2:
NAT_ai_140:
	ld a,(IY2)
NAT_ai_141:
	ld b,a
NAT_ai_142:
	ld a,(IX2)
NAT_ai_143:
	sub b
NAT_ai_144:
	ld e,1
NAT_ai_145:
	jp nc,ai_7af
NAT_ai_146:
	dec e
NAT_ai_147:
	cpl
NAT_ai_148:
	inc a
ai_7af:
NAT_ai_150:
	cp 6
NAT_ai_151:
	jp nc,ai_77f
NAT_ai_152:
	ld a,(IY3)
NAT_ai_153:
	ld b,a
NAT_ai_154:
	ld a,(IX3)
NAT_ai_155:
	add a,2
NAT_ai_156:
	sub b
NAT_ai_157:
	ld d,1
NAT_ai_158:
	jp nc,ai_7c2
NAT_ai_159:
	dec d
NAT_ai_160:
	cpl
NAT_ai_161:
	inc a
ai_7c2:
NAT_ai_163:
	cp 0x0E
NAT_ai_164:
	jp nc,ai_77f
NAT_ai_165:
	cp 6
NAT_ai_166:
	jp c,ai_7e3
NAT_ai_167:
	ld a,d
NAT_ai_168:
	and a
NAT_ai_169:
	ld a,(IXM1)
NAT_ai_170:
	jp z,ai_7da
NAT_ai_171:
	xor 0x0C
NAT_ai_172:
	jp z,ai_77f
NAT_ai_173:
	ld a,0x1C
NAT_ai_174:
	jp ai_8c6
ai_7da:
NAT_ai_176:
	xor 4
NAT_ai_177:
	jp z,ai_77f
NAT_ai_178:
	ld a,0x14
NAT_ai_179:
	jp ai_8c6
ai_7e3:
NAT_ai_181:
	ld a,e
NAT_ai_182:
	and a
NAT_ai_183:
	ld a,(IXM1)
NAT_ai_184:
	jp z,ai_7f4
NAT_ai_185:
	xor 3
NAT_ai_186:
	jp z,ai_77f
NAT_ai_187:
	ld a,0x13
NAT_ai_188:
	jp ai_8c6
ai_7f4:
NAT_ai_190:
	xor 1
NAT_ai_191:
	jp z,ai_77f
NAT_ai_192:
	ld a,0x11
NAT_ai_193:
	jp ai_8c6
ai_7fe:
NAT_ai_195:
	ld a,(IXM1)
NAT_ai_196:
	and 0x0C
NAT_ai_197:
	cp 4
NAT_ai_198:
	jp z,ai_813
NAT_ai_199:
	ld a,(0x8696)
NAT_ai_200:
	and 8
NAT_ai_201:
	jp nz,ai_813
NAT_ai_202:
	ld a,0x14
NAT_ai_203:
	jp ai_8c6
ai_813:
NAT_ai_205:
	ld hl,0x0754
NAT_ai_206:
	ld a,(IX2)
NAT_ai_207:
	cp l
NAT_ai_208:
	jp nz,ai_825
NAT_ai_209:
	ld a,(IX3)
NAT_ai_210:
	cp h
NAT_ai_211:
	ld a,0x10
NAT_ai_212:
	jp z,ai_8e5
ai_825:
NAT_ai_214:
	ld a,(ai_lvl)
NAT_ai_215:
	inc a
NAT_ai_216:
	cpl
NAT_ai_217:
	inc a
NAT_ai_218:
	ld e,a
NAT_ai_219:
	ld a,(IY3)
NAT_ai_220:
	add a,e
NAT_ai_221:
	cp 0x0E
NAT_ai_222:
	jp nc,ai_844
NAT_ai_223:
	cp 4
NAT_ai_224:
	jp c,ai_844
NAT_ai_225:
	ld a,(IY2)
NAT_ai_226:
	cp 0x51
NAT_ai_227:
	jp c,ai_844
NAT_ai_228:
	cp 0x58
NAT_ai_229:
	jp nc,ai_844
NAT_ai_230:
	ld hl,(0x869A)
ai_844:
NAT_ai_232:
	ld a,(ai_lvl)
NAT_ai_233:
	ld c,a
NAT_ai_234:
	ld b,a
NAT_ai_235:
	inc c
NAT_ai_236:
	cp 3
NAT_ai_237:
	jp c,ai_84f
NAT_ai_238:
	inc c
ai_84f:
NAT_ai_240:
	ld e,a
NAT_ai_241:
	ld a,(IX2)
NAT_ai_242:
	add a,e
NAT_ai_243:
	sub l
NAT_ai_244:
	jp c,ai_869
NAT_ai_245:
	cp c
NAT_ai_246:
	jp nc,ai_869
NAT_ai_247:
	ld a,(IX3)
NAT_ai_248:
	add a,b
NAT_ai_249:
	sub h
NAT_ai_250:
	jp c,ai_869
NAT_ai_251:
	cp c
NAT_ai_252:
	jp nc,ai_869
NAT_ai_253:
	call Z_86D0
NAT_ai_254:
	ld a,0x10
	jp	NAT_ai_255	; мост в следующий кусок
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
NAT_ai_255:
	jp ai_8e5
ai_869:
NAT_ai_257:
	call ai_attack
NAT_ai_258:
	and a
NAT_ai_259:
	jp nz,ai_8c6
NAT_ai_260:
	ld a,0x10
NAT_ai_261:
	jp ai_8c6
ai_873:
NAT_ai_263:
	ld hl,(0x93F3)
NAT_ai_264:
	ld a,(0x93EB)
NAT_ai_265:
	ld b,a
NAT_ai_266:
	and 4
NAT_ai_267:
	ret nz
NAT_ai_268:
	ld a,b
NAT_ai_269:
	and 0x10
NAT_ai_270:
	jp nz,ai_89f
NAT_ai_271:
	ld a,b
NAT_ai_272:
	and 8
NAT_ai_273:
	jp nz,ai_88c
NAT_ai_274:
	ld a,b
NAT_ai_275:
	and 2
NAT_ai_276:
	jp z,ai_89f
NAT_ai_277:
	ld a,b
NAT_ai_278:
	and 0x80
NAT_ai_279:
	jp z,ai_89f
ai_88c:
NAT_ai_281:
	ld a,(IX3)
NAT_ai_282:
	sub h
NAT_ai_283:
	ld e,4
NAT_ai_284:
	jp nc,ai_896
NAT_ai_285:
	cpl
NAT_ai_286:
	inc a
ai_896:
NAT_ai_288:
	cp 4
NAT_ai_289:
	jp nc,ai_89f
NAT_ai_290:
	ld a,0x10
NAT_ai_291:
	or e
NAT_ai_292:
	jp ai_8c6
ai_89f:
NAT_ai_294:
	call Z_A133
NAT_ai_295:
	jp nz,ai_8c6
NAT_ai_296:
	call ai_defend
NAT_ai_297:
	and a
NAT_ai_298:
	jp nz,ai_8be
NAT_ai_299:
	ld a,(IX3)
NAT_ai_300:
	xor 1
NAT_ai_301:
	ld (IX3),a
NAT_ai_302:
	ld a,(IX2)
NAT_ai_303:
	xor 1
NAT_ai_304:
	ld (IX2),a
NAT_ai_305:
	xor a
ai_8be:
NAT_ai_307:
	ld b,a
NAT_ai_308:
	ld a,(IX1)
NAT_ai_309:
	and 0x40
NAT_ai_310:
	ld a,b
NAT_ai_311:
	jp z,ai_8c6
NAT_ai_312:
	or 0x10
ai_8c6:
NAT_ai_314:
	ld c,a
NAT_ai_315:
	and a
NAT_ai_316:
	jp z,ai_8e5
NAT_ai_317:
	ld a,(0x93EB)
NAT_ai_318:
	rrca
NAT_ai_319:
	ld a,c
NAT_ai_320:
	jp nc,ai_8e5
NAT_ai_321:
	ld a,(ai_lvl)
NAT_ai_322:
	ld b,a
NAT_ai_323:
	ld a,(0x8698)
NAT_ai_324:
	inc a
NAT_ai_325:
	cp b
NAT_ai_326:
	jp c,ai_8db
NAT_ai_327:
	xor a
ai_8db:
NAT_ai_329:
	ld (0x8698),a
NAT_ai_330:
	and a
NAT_ai_331:
	ld a,c
NAT_ai_332:
	jp z,ai_8e5
NAT_ai_333:
	ld a,(0x8696)
ai_8e5:
NAT_ai_335:
	ld b,a
NAT_ai_336:
	ld a,(IXM2)
NAT_ai_337:
	and 0x80
NAT_ai_338:
	ld a,b
NAT_ai_339:
	jp z,ai_8ed
NAT_ai_340:
	and 0xEF
ai_8ed:
NAT_ai_342:
	ld (0xAC4E),a
NAT_ai_343:
	ld (0x8696),a
NAT_ai_344:
	ret
ai_attack:
NAT_ai_346:
	ld c,0x0C
NAT_ai_347:
	ld a,(IX2)
NAT_ai_348:
	cp 0x54
NAT_ai_349:
	jp nc,ai_906
NAT_ai_350:
	ld a,(IY2)
NAT_ai_351:
	cp 0x51
NAT_ai_352:
	jp nc,ai_906
NAT_ai_353:
	ld c,0x10
ai_906:
NAT_ai_355:
	ld a,(IY3)
NAT_ai_356:
	ld d,a
NAT_ai_357:
	ld a,h
NAT_ai_358:
	sub 6
NAT_ai_359:
	sub d
NAT_ai_360:
	jp nc,ai_a01
NAT_ai_361:
	cpl
NAT_ai_362:
	inc a
NAT_ai_363:
	ld b,a
NAT_ai_364:
	ld a,(IX3)
NAT_ai_365:
	add a,6
NAT_ai_366:
	sub d
NAT_ai_367:
	jp c,ai_a01
NAT_ai_368:
	ld a,b
NAT_ai_369:
	cp c
NAT_ai_370:
	jp nc,ai_944
NAT_ai_371:
	ld a,(IY2)
NAT_ai_372:
	ld d,a
NAT_ai_373:
	ld a,(IX2)
NAT_ai_374:
	sub d
NAT_ai_375:
	ld e,1
NAT_ai_376:
	jp nc,ai_92f
NAT_ai_377:
	dec e
ai_92f:
NAT_ai_379:
	ld a,d
NAT_ai_380:
	cp l
NAT_ai_381:
	ld a,1
NAT_ai_382:
	jp nc,ai_938
NAT_ai_383:
	dec a
ai_938:
NAT_ai_385:
	add a,e
NAT_ai_386:
	cp 1
NAT_ai_387:
	jp z,ai_a01
NAT_ai_388:
	ld a,0x0D
NAT_ai_389:
	ret nc
NAT_ai_390:
	ld a,0x0F
NAT_ai_391:
	ret
ai_944:
NAT_ai_393:
	ld e,1
NAT_ai_394:
	ld a,(IY2)
NAT_ai_395:
	ld d,a
NAT_ai_396:
	ld a,l
NAT_ai_397:
	sub d
NAT_ai_398:
	jp nc,ai_94f
NAT_ai_399:
	dec e
NAT_ai_400:
	cpl
	jp	NAT_ai_401	; мост в следующий кусок
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
NAT_ai_401:
	inc a
ai_94f:
NAT_ai_403:
	inc a
NAT_ai_404:
	and 0xFE
NAT_ai_405:
	cp 6
NAT_ai_406:
	jp nc,ai_a01
NAT_ai_407:
	add a,6
NAT_ai_408:
	dec e
NAT_ai_409:
	jp z,ai_95e
NAT_ai_410:
	cpl
NAT_ai_411:
	inc a
ai_95e:
NAT_ai_413:
	add a,l
NAT_ai_414:
	ld l,a
NAT_ai_415:
	jp ai_a01
	org	0x36F0
D_36F0:
Z_36F0:
	db	0xC3, 0x9B, 0x40	; 36F0
	org	0x36F3
ai_defend:
NAT_ai_417:
	ld c,8
NAT_ai_418:
	ld a,(IY0)
NAT_ai_419:
	and 0x10
NAT_ai_420:
	jp z,ai_96d
NAT_ai_421:
	ld c,0x0A
ai_96d:
NAT_ai_423:
	ld a,(IY3)
NAT_ai_424:
	ld e,a
NAT_ai_425:
	ld a,(IX3)
NAT_ai_426:
	sub e
NAT_ai_427:
	jp nc,ai_977
NAT_ai_428:
	cpl
NAT_ai_429:
	inc a
ai_977:
NAT_ai_431:
	cp c
NAT_ai_432:
	ld d,a
NAT_ai_433:
	jp nc,ai_a01
NAT_ai_434:
	ld a,(IY2)
NAT_ai_435:
	and 0xE0
NAT_ai_436:
	rrca
NAT_ai_437:
	rrca
NAT_ai_438:
	rrca
NAT_ai_439:
	rrca
NAT_ai_440:
	ld b,a
NAT_ai_441:
	ld a,(IY0)
NAT_ai_442:
	and 0x10
NAT_ai_443:
	jp z,ai_9ce
	jp	NAT_ai_444	; мост в следующий кусок
	org	0x3727
D_3727:
Z_3727:
	db	0x00, 0x00, 0x00, 0x00, 0xC9	; 3727
	org	0x372C
NAT_ai_444:
	ld a,(IYM1)
NAT_ai_445:
	and 4
NAT_ai_446:
	jp nz,ai_9ce
NAT_ai_447:
	ld a,(IX2)
NAT_ai_448:
	cp l
NAT_ai_449:
	sbc a,a
NAT_ai_450:
	ld e,a
NAT_ai_451:
	ld a,(IYM1)
NAT_ai_452:
	and 2
NAT_ai_453:
	jp z,ai_9b3
NAT_ai_454:
	inc l
NAT_ai_455:
	inc l
NAT_ai_456:
	ld a,e
NAT_ai_457:
	or a
NAT_ai_458:
	jp z,ai_a01
NAT_ai_459:
	ld a,d
NAT_ai_460:
	cp 6
NAT_ai_461:
	jp nc,ai_a01
NAT_ai_462:
	ld e,3
NAT_ai_463:
	ld a,0x14
NAT_ai_464:
	sub b
NAT_ai_465:
	ld b,a
ai_9ae:
NAT_ai_467:
	ld a,h
NAT_ai_468:
	sub b
NAT_ai_469:
	ld h,a
NAT_ai_470:
	jp ai_a0e
ai_9b3:
NAT_ai_472:
	ld a,e
NAT_ai_473:
	or a
	jp	NAT_ai_474	; мост в следующий кусок
	org	0x3761
D_3761:
Z_3761:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 3761
	org	0x3769
NAT_ai_474:
	jp nz,ai_a01
NAT_ai_475:
	ld a,d
NAT_ai_476:
	cp 6
NAT_ai_477:
	jp c,ai_9be
NAT_ai_478:
	dec l
NAT_ai_479:
	dec l
NAT_ai_480:
	jp ai_a01
ai_9be:
NAT_ai_482:
	ld e,1
NAT_ai_483:
	ld a,(IY3)
NAT_ai_484:
	ld c,a
NAT_ai_485:
	ld a,0x62
NAT_ai_486:
	add a,b
NAT_ai_487:
	ld b,0x0F
NAT_ai_488:
	cp c
NAT_ai_489:
	jp c,ai_9ae
NAT_ai_490:
	inc h
NAT_ai_491:
	inc h
NAT_ai_492:
	jp ai_a0e
	org	0x3790
D_3790:
Z_3790:
	db	0x00	; 3790
	org	0x3791
ai_9ce:
NAT_ai_494:
	ld a,(IY2)
NAT_ai_495:
	ld e,a
NAT_ai_496:
	ld a,(IX2)
NAT_ai_497:
	sub e
NAT_ai_498:
	jp nc,ai_9d8
NAT_ai_499:
	cpl
NAT_ai_500:
	inc a
ai_9d8:
NAT_ai_502:
	inc a
NAT_ai_503:
	and 0xFE
NAT_ai_504:
	cp 4
NAT_ai_505:
	jp nc,ai_a01
NAT_ai_506:
	ld a,(IY2)
NAT_ai_507:
	sub l
	jp	NAT_ai_508	; мост в следующий кусок
	org	0x37AD
D_37AD:
Z_37AD:
	db	0x32, 0xCB, 0xD1, 0x47, 0x0E, 0x07, 0x18, 0xAB, 0x47, 0x3A, 0xBC, 0xD1, 0xE6, 0xF0, 0x18, 0x0A	; 37AD
	org	0x37BD
NAT_ai_508:
	ld e,1
NAT_ai_509:
	jp nc,ai_9ea
NAT_ai_510:
	dec e
NAT_ai_511:
	cpl
NAT_ai_512:
	inc a
ai_9ea:
NAT_ai_514:
	inc a
NAT_ai_515:
	and 0xFE
NAT_ai_516:
	cp 4
NAT_ai_517:
	jp nc,ai_a01
NAT_ai_518:
	and a
NAT_ai_519:
	jp nz,ai_9f8
	jp	NAT_ai_520	; мост в следующий кусок
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
NAT_ai_520:
	ld e,3
NAT_ai_521:
	jp ai_a0e
ai_9f8:
NAT_ai_523:
	dec e
NAT_ai_524:
	ld e,3
NAT_ai_525:
	jp nz,ai_a0e
NAT_ai_526:
	ld e,1
NAT_ai_527:
	jp ai_a0e
ai_a01:
NAT_ai_529:
	ld a,(IX2)
NAT_ai_530:
	ld b,a
NAT_ai_531:
	ld a,l
NAT_ai_532:
	ld e,0
NAT_ai_533:
	cp b
NAT_ai_534:
	jp z,ai_a0e
NAT_ai_535:
	inc e
NAT_ai_536:
	jp c,ai_a0e
NAT_ai_537:
	ld e,3
ai_a0e:
NAT_ai_539:
	ld a,(IX3)
NAT_ai_540:
	cp h
NAT_ai_541:
	ld a,e
NAT_ai_542:
	jp z,ai_a1b
NAT_ai_543:
	ld a,0x0C
NAT_ai_544:
	jp c,ai_a1b
NAT_ai_545:
	ld a,4
ai_a1b:
NAT_ai_547:
	or e
NAT_ai_548:
	ld b,a
NAT_ai_549:
	ld a,(IXM7)
NAT_ai_550:
	rrca
NAT_ai_551:
	ld a,b
NAT_ai_552:
	ret nc
NAT_ai_553:
	ld a,e
NAT_ai_554:
	ret
ai_lvl:
NAT_ai_556:
	db 0
Z_8A23:
NAT_ball_1:
	ld a,(0x93EB)
NAT_ball_2:
	ld b,a
NAT_ball_3:
	and 5
NAT_ball_4:
	jp nz,bl_icons
NAT_ball_5:
	ld a,b
NAT_ball_6:
	and 2
NAT_ball_7:
	jp nz,bl_fly
NAT_ball_8:
	ld a,b
	jp	NAT_ball_9	; мост в следующий кусок
	org	0x3860
D_3860:
Z_3860:
	db	0xCD, 0xDE, 0xD5, 0x26, 0x00, 0x28, 0x04, 0x3E, 0xFF, 0x6F, 0xC9, 0xAF, 0x6F, 0xC9	; 3860
	org	0x386E
NAT_ball_9:
	and 8
NAT_ball_10:
	jp nz,bl_reb
NAT_ball_11:
	ld a,b
NAT_ball_12:
	and 0x10
NAT_ball_13:
	jp z,bl_icons
NAT_ball_14:
	ld hl,0x93F1
NAT_ball_15:
	ld (z80_ix),hl
	jp	NAT_ball_16	; мост в следующий кусок
	org	0x3883
D_3883:
Z_3883:
	db	0xED, 0x5B, 0x00, 0x33, 0x2A, 0x9A, 0xD0	; 3883
	org	0x388A
NAT_ball_16:
	ld a,(0x93EF)
NAT_ball_17:
	rrca
NAT_ball_18:
	jp c,bl_down
NAT_ball_19:
	ld a,(hl)
NAT_ball_20:
	add a,6
NAT_ball_21:
	ld (hl),a
NAT_ball_22:
	ld b,a
NAT_ball_23:
	ld a,(0x93F3)
NAT_ball_24:
	ld c,a
NAT_ball_25:
	ld a,b
NAT_ball_26:
	cp c
NAT_ball_27:
	jp c,bl_icons
NAT_ball_28:
	ld (hl),c
	jp	NAT_ball_29	; мост в следующий кусок
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
NAT_ball_29:
	ld a,(0x93EF)
NAT_ball_30:
	or 1
NAT_ball_31:
	ld (0x93EF),a
NAT_ball_32:
	jp Z_8BFE
bl_down:
NAT_ball_34:
	ld a,(0x93F0)
NAT_ball_35:
	ld c,a
NAT_ball_36:
	ld a,(hl)
NAT_ball_37:
	cp c
NAT_ball_38:
	jp c,bl_d1
NAT_ball_39:
	sub 6
NAT_ball_40:
	ld (hl),a
NAT_ball_41:
	jp bl_icons
bl_d1:
NAT_ball_43:
	ld a,c
NAT_ball_44:
	add a,6
NAT_ball_45:
	ld c,a
NAT_ball_46:
	ld a,(0x93F3)
NAT_ball_47:
	ld b,a
NAT_ball_48:
	ld a,c
NAT_ball_49:
	cp b
NAT_ball_50:
	jp nc,bl_dead
NAT_ball_51:
	ld (0x93F0),a
NAT_ball_52:
	ld a,(0x93EF)
NAT_ball_53:
	and 0xFE
NAT_ball_54:
	ld (0x93EF),a
NAT_ball_55:
	jp bl_icons
bl_dead:
NAT_ball_57:
	xor a
NAT_ball_58:
	ld (0x93EB),a
NAT_ball_59:
	call Z_8BFE
NAT_ball_60:
	jp bl_icons
bl_reb:
NAT_ball_62:
	call Z_9BF6
NAT_ball_63:
	jp bl_icons
bl_fly:
NAT_ball_65:
	call Z_9A1B
bl_icons:
NAT_ball_67:
	ld hl,0x940B
NAT_ball_68:
	ld (z80_ix),hl
NAT_ball_69:
	ld hl,0x9425
NAT_ball_70:
	ld (z80_iy),hl
NAT_ball_71:
	ld hl,0x0690
NAT_ball_72:
	call bl_icon
NAT_ball_73:
	ld hl,0x9425
NAT_ball_74:
	ld (z80_ix),hl
NAT_ball_75:
	ld hl,0x940B
NAT_ball_76:
	ld (z80_iy),hl
NAT_ball_77:
	ld hl,0x1990
bl_icon:
NAT_ball_79:
	push hl
NAT_ball_80:
	call Z_8CF7
NAT_ball_81:
	ld de,0x7750
NAT_ball_82:
	ld hl,(z80_ix)
NAT_ball_83:
	inc hl
NAT_ball_84:
	ld a,(hl)
NAT_ball_85:
	jp nc,bl_i1
NAT_ball_86:
	or 0x40
NAT_ball_87:
	ld (hl),a
NAT_ball_88:
	pop hl
NAT_ball_89:
	jp HUD_ICON
bl_i1:
NAT_ball_91:
	and 0xBF
NAT_ball_92:
	ld (hl),a
NAT_ball_93:
	ld e,0x58
NAT_ball_94:
	pop hl
NAT_ball_95:
	jp HUD_ICON
Z_8ADD:
NAT_ball_97:
	ld hl,(0x93F3)
NAT_ball_98:
	ld a,l
NAT_ball_99:
	sub 4
NAT_ball_100:
	ld l,a
NAT_ball_101:
	ld (0x3300),hl
NAT_ball_102:
	ld a,0x49
NAT_ball_103:
	call Z_9E6F
NAT_ball_104:
	call Z_B01C
NAT_ball_105:
	ld hl,(0x93F3)
NAT_ball_106:
	ld a,(0x93EB)
NAT_ball_107:
	and 0x1A
NAT_ball_108:
	jp z,bl_b1
NAT_ball_109:
	ld hl,(0x93F1)
bl_b1:
NAT_ball_111:
	ld a,l
NAT_ball_112:
	sub 8
NAT_ball_113:
	ld l,a
NAT_ball_114:
	ld (0x3300),hl
NAT_ball_115:
	ld a,0x48
NAT_ball_116:
	call Z_9E6F
NAT_ball_117:
	call Z_B01C
NAT_ball_118:
	ld hl,0x93F5
NAT_ball_119:
	ld (z80_ix),hl
NAT_ball_120:
	ld a,(hl)
NAT_ball_121:
	and 2
NAT_ball_122:
	ret z
NAT_ball_123:
	ld (hl),0
NAT_ball_124:
	ld a,(0x93EB)
NAT_ball_125:
	ld b,a
NAT_ball_126:
	and 8
NAT_ball_127:
	jp z,bl_chance
NAT_ball_128:
	ld a,b
NAT_ball_129:
	and 0xE0
NAT_ball_130:
	or 0x10
NAT_ball_131:
	ld (0x93EB),a
Z_8B26:
NAT_ball_133:
	ld a,(0x93F1)
	jp	NAT_ball_134	; мост в следующий кусок
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
NAT_ball_134:
	add a,6
NAT_ball_135:
	ld (0x93F0),a
NAT_ball_136:
	xor a
NAT_ball_137:
	ld (0x93EF),a
NAT_ball_138:
	ld hl,0x93EF
NAT_ball_139:
	ret
bl_chance:
NAT_ball_141:
	ld a,(0x944F)
NAT_ball_142:
	ld bc,0x32
NAT_ball_143:
	ld de,0x46
NAT_ball_144:
	call bl_term
NAT_ball_145:
	push hl
NAT_ball_146:
	ld a,(0x9450)
NAT_ball_147:
	ld bc,0x23
NAT_ball_148:
	ld de,0x08
NAT_ball_149:
	call bl_term
NAT_ball_150:
	pop de
NAT_ball_151:
	add hl,de
NAT_ball_152:
	push hl
NAT_ball_153:
	ld a,(0x944E)
NAT_ball_154:
	cpl
NAT_ball_155:
	inc a
NAT_ball_156:
	add a,0x16
NAT_ball_157:
	ld bc,0x0A
NAT_ball_158:
	ld de,0x17
NAT_ball_159:
	call bl_term
NAT_ball_160:
	pop de
NAT_ball_161:
	add hl,de
NAT_ball_162:
	push hl
NAT_ball_163:
	ld a,(0x944D)
NAT_ball_164:
	cpl
NAT_ball_165:
	inc a
NAT_ball_166:
	add a,0x32
NAT_ball_167:
	ld bc,0x05
NAT_ball_168:
	ld de,0x32
NAT_ball_169:
	call bl_term
NAT_ball_170:
	pop de
NAT_ball_171:
	add hl,de
NAT_ball_172:
	call Z_A172
NAT_ball_173:
	add a,4
NAT_ball_174:
	ld c,l
NAT_ball_175:
	call Z_A0B0
NAT_ball_176:
	ld a,c
NAT_ball_177:
	rla
NAT_ball_178:
	ld c,a
NAT_ball_179:
	ld a,(0x93EB)
NAT_ball_180:
	and 0x80
NAT_ball_181:
	ld hl,0x9425
NAT_ball_182:
	ld de,0x940B
NAT_ball_183:
	jp z,bl_c1
NAT_ball_184:
	ex de,hl
bl_c1:
NAT_ball_186:
	ld (z80_ix),hl
NAT_ball_187:
	ex de,hl
NAT_ball_188:
	ld (z80_iy),hl
NAT_ball_189:
	ex de,hl
NAT_ball_190:
	ld a,(0x93D9)
NAT_ball_191:
	cp 3
	jp	NAT_ball_192	; мост в следующий кусок
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
NAT_ball_192:
	jp nz,bl_c2
NAT_ball_193:
	ld de,0x11
NAT_ball_194:
	call bl_inc
NAT_ball_195:
	jp bl_c4
bl_c2:
NAT_ball_197:
	cp 1
NAT_ball_198:
	jp nz,bl_c3
	jp	NAT_ball_199	; мост в следующий кусок
	org	0x3B47
D_3B47:
Z_3B47:
	db	0xC5, 0xD5, 0xE5, 0xCD, 0xEB, 0xD8, 0xE1, 0xD1, 0xC1, 0xF1, 0xF1, 0xC9	; 3B47
	org	0x3B53
NAT_ball_199:
	ld de,0x0E
NAT_ball_200:
	call bl_inc
NAT_ball_201:
	jp bl_c4
bl_c3:
NAT_ball_203:
	ld de,0x0C
NAT_ball_204:
	add hl,de
NAT_ball_205:
	inc (hl)
NAT_ball_206:
	jp bl_c5
bl_c4:
NAT_ball_208:
	ld a,c
NAT_ball_209:
	rrca
NAT_ball_210:
	jp c,bl_c5
NAT_ball_211:
	inc hl
NAT_ball_212:
	inc (hl)
bl_c5:
NAT_ball_214:
	ld a,c
NAT_ball_215:
	rrca
NAT_ball_216:
	jp nc,Z_8C16
NAT_ball_217:
	ld a,(0x93EB)
NAT_ball_218:
	and 0xFD
NAT_ball_219:
	or 8
NAT_ball_220:
	ld (0x93EB),a
NAT_ball_221:
	ld hl,(z80_ix)
NAT_ball_222:
	dec hl
NAT_ball_223:
	dec hl
NAT_ball_224:
	dec hl
NAT_ball_225:
	ld a,(hl)
NAT_ball_226:
	sub 2
NAT_ball_227:
	jp nc,bl_c6
NAT_ball_228:
	xor a
bl_c6:
NAT_ball_230:
	ld (hl),a
NAT_ball_231:
	ld hl,(z80_iy)
NAT_ball_232:
	dec hl
NAT_ball_233:
	dec hl
NAT_ball_234:
	dec hl
NAT_ball_235:
	ld a,(hl)
NAT_ball_236:
	inc a
NAT_ball_237:
	cp 0x33
NAT_ball_238:
	jp z,bl_c7
NAT_ball_239:
	ld (hl),a
bl_c7:
NAT_ball_241:
	call Z_8BFE
NAT_ball_242:
	ld a,(0x93D6)
NAT_ball_243:
	and a
NAT_ball_244:
	ret z
NAT_ball_245:
	ld e,3
NAT_ball_246:
	jp Z_9919
bl_term:
NAT_ball_248:
	ld l,a
NAT_ball_249:
	ld h,0
NAT_ball_250:
	push de
NAT_ball_251:
	call Z_398C
NAT_ball_252:
	pop bc
NAT_ball_253:
	jp Z_39A3
bl_inc:
NAT_ball_255:
	add hl,de
NAT_ball_256:
	inc (hl)
NAT_ball_257:
	ret
Z_8BFE:
NAT_ball_259:
	ld a,(0x93D8)
NAT_ball_260:
	and a
NAT_ball_261:
	ret nz
NAT_ball_262:
	inc a
NAT_ball_263:
	ld (0xAA83),a
NAT_ball_264:
	ld hl,2
NAT_ball_265:
	ld (0x3300),hl
NAT_ball_266:
	ld hl,0x8070
NAT_ball_267:
	ld (0x3302),hl
NAT_ball_268:
	jp Z_AA80
Z_8C16:
NAT_ball_270:
	ld a,(0x93D9)
NAT_ball_271:
	cp 2
NAT_ball_272:
	jp nz,bl_m1
NAT_ball_273:
	ld hl,(z80_ix)
NAT_ball_274:
	ld de,0x0D
NAT_ball_275:
	add hl,de
NAT_ball_276:
	inc (hl)
bl_m1:
NAT_ball_278:
	ld a,(0x93EB)
NAT_ball_279:
	and 0xFD
NAT_ball_280:
	or 4
NAT_ball_281:
	ld (0x93EB),a
NAT_ball_282:
	ld hl,0x93DC
NAT_ball_283:
	ld (0x93DA),hl
NAT_ball_284:
	ld hl,(z80_ix)
NAT_ball_285:
	dec hl
NAT_ball_286:
	dec hl
NAT_ball_287:
	dec hl
NAT_ball_288:
	ld a,(hl)
NAT_ball_289:
	add a,2
NAT_ball_290:
	cp 0x32
NAT_ball_291:
	jp c,bl_m2
NAT_ball_292:
	ld a,0x32
bl_m2:
NAT_ball_294:
	ld (hl),a
NAT_ball_295:
	ld hl,(z80_iy)
NAT_ball_296:
	dec hl
NAT_ball_297:
	dec hl
NAT_ball_298:
	dec hl
NAT_ball_299:
	ld a,(hl)
NAT_ball_300:
	and a
NAT_ball_301:
	jp z,bl_m3
NAT_ball_302:
	dec (hl)
bl_m3:
NAT_ball_304:
	ld hl,(z80_ix)
NAT_ball_305:
	ld a,(hl)
NAT_ball_306:
	and 0x20
NAT_ball_307:
	ret nz
NAT_ball_308:
	xor a
NAT_ball_309:
	ld (0xAA83),a
NAT_ball_310:
	ld hl,2
NAT_ball_311:
	ld (0x3300),hl
NAT_ball_312:
	ld hl,0x8039
	jp	NAT_ball_313	; мост в следующий кусок
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
NAT_ball_313:
	ld (0x3302),hl
NAT_ball_314:
	jp Z_AA80
Z_8C60:
NAT_ball_316:
	ld hl,0x9425
NAT_ball_317:
	ld (z80_ix),hl
NAT_ball_318:
	ld hl,0x0418
NAT_ball_319:
	ld de,0x9402
NAT_ball_320:
	call bl_bk
NAT_ball_321:
	ld hl,0x940B
NAT_ball_322:
	ld (z80_ix),hl
NAT_ball_323:
	ld hl,0x7018
NAT_ball_324:
	ld de,0x9401
bl_bk:
NAT_ball_326:
	push hl
NAT_ball_327:
	ld a,(0x93EB)
NAT_ball_328:
	ld b,a
NAT_ball_329:
	and 4
NAT_ball_330:
	ld a,0x3E
NAT_ball_331:
	jp z,bl_k9
NAT_ball_332:
	ld a,b
NAT_ball_333:
	rlca
NAT_ball_334:
	ld b,a
NAT_ball_335:
	ld hl,(z80_ix)
NAT_ball_336:
	inc hl
NAT_ball_337:
	ld a,(hl)
NAT_ball_338:
	xor b
NAT_ball_339:
	and 1
NAT_ball_340:
	ld a,0x3E
NAT_ball_341:
	jp nz,bl_k9
NAT_ball_342:
	ld hl,(0x93DA)
NAT_ball_343:
	ld a,(hl)
NAT_ball_344:
	inc hl
NAT_ball_345:
	ld (0x93DA),hl
NAT_ball_346:
	cp 0xFF
NAT_ball_347:
	jp nz,bl_k9
	jp	NAT_ball_348	; мост в следующий кусок
	org	0x6618
NAT_ball_348:
	ld a,0x2A
NAT_ball_349:
	ld (0x93F1),a
NAT_ball_350:
	add a,8
NAT_ball_351:
	ld (0x93F0),a
NAT_ball_352:
	xor a
NAT_ball_353:
	ld (0x93EF),a
NAT_ball_354:
	ld a,(0x93EB)
NAT_ball_355:
	and 0xFB
NAT_ball_356:
	or 0x10
NAT_ball_357:
	ld (0x93EB),a
NAT_ball_358:
	ld a,(0x9400)
NAT_ball_359:
	and a
NAT_ball_360:
	jp z,bl_k2
NAT_ball_361:
	and 0x80
NAT_ball_362:
	ld b,a
NAT_ball_363:
	ld a,(0x93EB)
NAT_ball_364:
	and 0x80
NAT_ball_365:
	xor b
NAT_ball_366:
	jp z,bl_k3
bl_k2:
NAT_ball_368:
	ld a,(0x93D9)
NAT_ball_369:
	ex de,hl
NAT_ball_370:
	add a,(hl)
NAT_ball_371:
	ld (hl),a
NAT_ball_372:
	ld a,(0x93D3)
NAT_ball_373:
	dec a
NAT_ball_374:
	call nz,Z_9FF2
NAT_ball_375:
	ld e,0x44
NAT_ball_376:
	call Z_9919
bl_k3:
NAT_ball_378:
	ld a,(0x93F4)
NAT_ball_379:
	ld h,a
NAT_ball_380:
	ld l,0x22
NAT_ball_381:
	ld (0x3300),hl
NAT_ball_382:
	ld a,0x48
NAT_ball_383:
	call Z_9E6F
NAT_ball_384:
	call Z_B01C
NAT_ball_385:
	ld a,0x42
bl_k9:
NAT_ball_387:
	pop hl
NAT_ball_388:
	ld (0x3300),hl
NAT_ball_389:
	ld b,a
NAT_ball_390:
	ld a,h
NAT_ball_391:
	and 0x40
NAT_ball_392:
	ld a,b
NAT_ball_393:
	jp z,bl_k10
NAT_ball_394:
	add a,5
bl_k10:
NAT_ball_396:
	call Z_9E6F
NAT_ball_397:
	jp Z_B01C
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
	org	0x7739
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
	jp	Z_923C	; мост в следующий кусок
	org	0x7A57
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
	jp	Z_92BF	; мост в следующий кусок
	org	0x7B2D
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
	org	0x8496
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
Z_9C83:
NAT_walk_1:
	ld hl,(z80_ix)
NAT_walk_2:
	ld de,0xFFF9
NAT_walk_3:
	add hl,de
NAT_walk_4:
	ld (wk_p7),hl
NAT_walk_5:
	ld a,(hl)
NAT_walk_6:
	and 0xFE
NAT_walk_7:
	ld (hl),a
NAT_walk_8:
	ld hl,(z80_ix)
NAT_walk_9:
	ld a,(hl)
NAT_walk_10:
	rrca
NAT_walk_11:
	jp c,Z_8F76
NAT_walk_12:
	dec hl
NAT_walk_13:
	dec hl
NAT_walk_14:
	ld a,(hl)
NAT_walk_15:
	and 0x1F
NAT_walk_16:
	jp z,wk_idle
NAT_walk_17:
	inc hl
NAT_walk_18:
	ld b,(hl)
NAT_walk_19:
	cp 0x10
NAT_walk_20:
	jp z,Z_8E5A
NAT_walk_21:
	ld c,a
NAT_walk_22:
	inc hl
NAT_walk_23:
	ld a,(hl)
NAT_walk_24:
	and 0x10
NAT_walk_25:
	jp z,wk_gnd
NAT_walk_26:
	ld a,c
NAT_walk_27:
	and 0x10
NAT_walk_28:
	jp z,wk_pos
NAT_walk_29:
	ld a,c
NAT_walk_30:
	and 0xEF
NAT_walk_31:
	cp b
NAT_walk_32:
	jp z,Z_8E5A
NAT_walk_33:
	jp wk_st
wk_gnd:
NAT_walk_35:
	ld a,c
NAT_walk_36:
	and 0x10
NAT_walk_37:
	jp nz,Z_8E5A
NAT_walk_38:
	ld a,c
wk_st:
NAT_walk_40:
	ld c,a
NAT_walk_41:
	dec hl
NAT_walk_42:
	ld (hl),a
NAT_walk_43:
	inc hl
wk_pos:
NAT_walk_45:
	inc hl
NAT_walk_46:
	ld a,(hl)
NAT_walk_47:
	and 0xDF
NAT_walk_48:
	ld (hl),a
NAT_walk_49:
	inc hl
NAT_walk_50:
	ld e,(hl)
NAT_walk_51:
	inc hl
NAT_walk_52:
	ld d,(hl)
NAT_walk_53:
	ld hl,(z80_iy)
NAT_walk_54:
	inc hl
NAT_walk_55:
	inc hl
NAT_walk_56:
	ld a,(hl)
NAT_walk_57:
	inc hl
NAT_walk_58:
	ld h,(hl)
NAT_walk_59:
	ld l,a
NAT_walk_60:
	ex de,hl
NAT_walk_61:
	ld a,c
NAT_walk_62:
	rrca
NAT_walk_63:
	jp nc,wk_edge
NAT_walk_64:
	ld a,c
NAT_walk_65:
	and 2
NAT_walk_66:
	jp nz,wk_right
NAT_walk_67:
	ld a,l
NAT_walk_68:
	cp 0x41
NAT_walk_69:
	jp c,wk_edge
NAT_walk_70:
	call wk_neary
NAT_walk_71:
	jp nc,wk_lmov
NAT_walk_72:
	ld a,l
NAT_walk_73:
	inc a
NAT_walk_74:
	cp e
NAT_walk_75:
	jp c,wk_lmov
NAT_walk_76:
	sub 6
NAT_walk_77:
	cp e
NAT_walk_78:
	jp c,wk_xblk
wk_lmov:
NAT_walk_80:
	dec l
NAT_walk_81:
	call wk_rate
NAT_walk_82:
	jp nz,wk_edge
NAT_walk_83:
	dec l
NAT_walk_84:
	jp wk_edge
wk_right:
NAT_walk_86:
	ld a,l
NAT_walk_87:
	cp 0x6E
NAT_walk_88:
	jp nc,wk_edge
NAT_walk_89:
	call wk_neary
NAT_walk_90:
	jp nc,wk_rmov
NAT_walk_91:
	ld a,e
NAT_walk_92:
	inc a
NAT_walk_93:
	cp l
NAT_walk_94:
	jp c,wk_rmov
NAT_walk_95:
	sub 6
NAT_walk_96:
	cp l
NAT_walk_97:
	jp c,wk_xblk
wk_rmov:
NAT_walk_99:
	inc l
NAT_walk_100:
	call wk_rate
NAT_walk_101:
	jp nz,wk_edge
NAT_walk_102:
	inc l
NAT_walk_103:
	jp wk_edge
wk_xblk:
NAT_walk_105:
	call wk_set5
wk_edge:
NAT_walk_107:
	ld a,0x70
NAT_walk_108:
	ld c,a
NAT_walk_109:
	sub l
NAT_walk_110:
	or a
NAT_walk_111:
	rra
NAT_walk_112:
	or a
NAT_walk_113:
	rra
NAT_walk_114:
	inc a
NAT_walk_115:
	ld b,a
NAT_walk_116:
	cp h
NAT_walk_117:
	jp c,wk_e1
NAT_walk_118:
	ld a,h
NAT_walk_119:
	inc a
NAT_walk_120:
	cp b
NAT_walk_121:
	jp nc,wk_y
NAT_walk_122:
	ld a,0x0C
NAT_walk_123:
	jp wk_e2
wk_e1:
NAT_walk_125:
	cpl
NAT_walk_126:
	inc a
NAT_walk_127:
	add a,0x73
NAT_walk_128:
	ld c,a
NAT_walk_129:
	cp h
NAT_walk_130:
	jp nc,wk_y
NAT_walk_131:
	ld a,h
NAT_walk_132:
	dec a
NAT_walk_133:
	dec a
NAT_walk_134:
	cp c
NAT_walk_135:
	jp c,wk_y
NAT_walk_136:
	jp z,wk_y
NAT_walk_137:
	ld a,4
wk_e2:
NAT_walk_139:
	push hl
NAT_walk_140:
	ld hl,(z80_ix)
NAT_walk_141:
	dec hl
NAT_walk_142:
	dec hl
NAT_walk_143:
	ld (hl),a
NAT_walk_144:
	pop hl
wk_y:
NAT_walk_146:
	push hl
NAT_walk_147:
	ld hl,(z80_ix)
NAT_walk_148:
	dec hl
NAT_walk_149:
	dec hl
NAT_walk_150:
	ld a,(hl)
NAT_walk_151:
	pop hl
NAT_walk_152:
	ld (wk_t),a
NAT_walk_153:
	and 4
NAT_walk_154:
	jp z,wk_end
NAT_walk_155:
	ld a,(wk_t)
NAT_walk_156:
	and 8
NAT_walk_157:
	jp nz,wk_down
NAT_walk_158:
	ld a,b
NAT_walk_159:
	cp h
NAT_walk_160:
	jp nc,wk_set0
NAT_walk_161:
	call wk_nearx
NAT_walk_162:
	jp nc,wk_umov
NAT_walk_163:
	ld a,h
NAT_walk_164:
	cp d
NAT_walk_165:
	jp c,wk_umov
NAT_walk_166:
	sub 8
NAT_walk_167:
	cp d
NAT_walk_168:
	jp c,wk_yblk
wk_umov:
NAT_walk_170:
	dec h
NAT_walk_171:
	call wk_rate
NAT_walk_172:
	jp nz,wk_end
NAT_walk_173:
	dec h
NAT_walk_174:
	jp wk_end
wk_down:
NAT_walk_176:
	ld a,c
NAT_walk_177:
	cp h
NAT_walk_178:
	jp c,wk_set0
NAT_walk_179:
	call wk_nearx
NAT_walk_180:
	jp nc,wk_dmov
NAT_walk_181:
	ld a,d
NAT_walk_182:
	cp h
NAT_walk_183:
	jp c,wk_dmov
NAT_walk_184:
	sub 8
NAT_walk_185:
	cp h
NAT_walk_186:
	jp c,wk_yblk
wk_dmov:
NAT_walk_188:
	inc h
NAT_walk_189:
	call wk_rate
NAT_walk_190:
	jp nz,wk_end
NAT_walk_191:
	inc h
NAT_walk_192:
	jp wk_end
wk_yblk:
NAT_walk_194:
	call wk_set5
NAT_walk_195:
	jp wk_end
wk_set0:
NAT_walk_197:
	push hl
NAT_walk_198:
	ld hl,(wk_p7)
NAT_walk_199:
	ld a,(hl)
NAT_walk_200:
	or 1
NAT_walk_201:
	ld (hl),a
NAT_walk_202:
	pop hl
wk_end:
NAT_walk_204:
	ex de,hl
NAT_walk_205:
	ld hl,(z80_ix)
NAT_walk_206:
	inc hl
NAT_walk_207:
	inc hl
NAT_walk_208:
	ld (hl),e
NAT_walk_209:
	inc hl
NAT_walk_210:
	ld (hl),d
NAT_walk_211:
	call Z_9ED4
Z_9DC2:
NAT_walk_213:
	ld hl,(z80_ix)
NAT_walk_214:
	ld a,(hl)
NAT_walk_215:
	and 0x10
NAT_walk_216:
	ret z
NAT_walk_217:
	dec hl
NAT_walk_218:
	ld c,(hl)
NAT_walk_219:
	inc hl
NAT_walk_220:
	inc hl
NAT_walk_221:
	ld a,(hl)
NAT_walk_222:
	ld (wk_t),a
NAT_walk_223:
	inc hl
NAT_walk_224:
	ld e,(hl)
NAT_walk_225:
	inc hl
NAT_walk_226:
	ld d,(hl)
NAT_walk_227:
	ld b,d
NAT_walk_228:
	ex de,hl
NAT_walk_229:
	ld a,c
NAT_walk_230:
	and 4
NAT_walk_231:
	jp z,wk_f1
NAT_walk_232:
	ld a,c
NAT_walk_233:
	and 8
NAT_walk_234:
	jp z,wk_f3
NAT_walk_235:
	ld a,h
NAT_walk_236:
	add a,9
NAT_walk_237:
	ld h,a
NAT_walk_238:
	jp wk_f3
wk_f1:
NAT_walk_240:
	ld a,c
NAT_walk_241:
	and 2
NAT_walk_242:
	ld c,2
NAT_walk_243:
	jp nz,wk_f2
NAT_walk_244:
	ld c,0xFE
NAT_walk_245:
	ld a,h
NAT_walk_246:
	add a,9
NAT_walk_247:
	ld h,a
wk_f2:
NAT_walk_249:
	ld a,l
NAT_walk_250:
	add a,c
NAT_walk_251:
	ld l,a
wk_f3:
NAT_walk_253:
	ld (0x93F3),hl
NAT_walk_254:
	ld a,l
NAT_walk_255:
	cp 0x41
NAT_walk_256:
	jp c,wk_out
NAT_walk_257:
	cp 0x6E
NAT_walk_258:
	jp c,wk_in
wk_out:
NAT_walk_260:
	ld e,3
NAT_walk_261:
	jp Z_9919
wk_in:
NAT_walk_263:
	ld a,(wk_t)
NAT_walk_264:
	ld c,a
NAT_walk_265:
	and 0x10
NAT_walk_266:
	jp nz,wk_cr
NAT_walk_267:
	ld a,c
NAT_walk_268:
	rrca
NAT_walk_269:
	ld a,b
NAT_walk_270:
	jp nc,wk_i2
NAT_walk_271:
	cp 0x3E
NAT_walk_272:
	ret c
NAT_walk_273:
	jp wk_set4
wk_i2:
NAT_walk_275:
	cp 0x38
NAT_walk_276:
	ret nc
wk_set4:
NAT_walk_278:
	ld hl,(z80_ix)
NAT_walk_279:
	inc hl
NAT_walk_280:
	ld a,(hl)
NAT_walk_281:
	or 0x10
NAT_walk_282:
	ld (hl),a
NAT_walk_283:
	ret
wk_cr:
NAT_walk_285:
	ld a,c
NAT_walk_286:
	rrca
NAT_walk_287:
	ld a,b
NAT_walk_288:
	jp nc,wk_c2
NAT_walk_289:
	cp 0x3E
NAT_walk_290:
	ret nc
NAT_walk_291:
	jp wk_c3
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
	                jp      m,il_ADRN13
	                add     a,l
	                ld      l,a
	                ret     nc
	                inc     h
	                ret
il_ADRN13:
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
	                jp      m,il_ADRN14
	                add     a,l
	                ld      l,a
	                ret     nc
	                inc     h
	                ret
il_ADRN14:
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
	                jp      m,il_ADRN15
	                add     a,l
	                ld      l,a
	                ret     nc
	                inc     h
	                ret
il_ADRN15:
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
	                jp      m,il_ADRN16
	                add     a,l
	                ld      l,a
	                ret     nc
	                inc     h
	                ret
il_ADRN16:
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
il_ix_bit_b:
	                call    il_pro2_ix
	                ld a,(il_f)
	                rra
	                ld a,(il_d)
	                jp c,il_BITC17
	                and (hl)
	                ld a,(il_f+1)
	                jp il_ret_hl
il_BITC17:
	                and (hl)
	                scf
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
NAT_isr_1:
	di
NAT_isr_2:
	push af
NAT_isr_3:
	ld a,0x80
NAT_isr_4:
	and a
NAT_isr_5:
	push bc
NAT_isr_6:
	push hl
NAT_isr_7:
	push de
NAT_isr_8:
	ld hl,(il_tmp)
NAT_isr_9:
	push hl
NAT_isr_10:
	ld hl,(il_tmp2)
NAT_isr_11:
	push hl
NAT_isr_12:
	ld hl,(il_f)
NAT_isr_13:
	push hl
NAT_isr_14:
	ld hl,(il_a)
NAT_isr_15:
	push hl
NAT_isr_16:
	ld hl,(z80_ix)
NAT_isr_17:
	push hl
NAT_isr_18:
	ld hl,(z80_iy)
NAT_isr_19:
	push hl
Z_3702:
NAT_isr_21:
	call Z_3714
Z_3705:
NAT_isr_23:
	call Z_3715
NAT_isr_24:
	call Z_372C
NAT_isr_25:
	pop hl
NAT_isr_26:
	ld (z80_iy),hl
NAT_isr_27:
	pop hl
NAT_isr_28:
	ld (z80_ix),hl
NAT_isr_29:
	pop hl
NAT_isr_30:
	ld (il_a),hl
NAT_isr_31:
	pop hl
NAT_isr_32:
	ld (il_f),hl
NAT_isr_33:
	pop hl
NAT_isr_34:
	ld (il_tmp2),hl
NAT_isr_35:
	pop hl
NAT_isr_36:
	ld (il_tmp),hl
NAT_isr_37:
	pop de
NAT_isr_38:
	pop hl
NAT_isr_39:
	pop bc
NAT_isr_40:
	pop af
NAT_isr_41:
	ei
Z_3714:
NAT_isr_43:
	ret
Z_3715:
NAT_isr_45:
	ld hl,(0x4111)
NAT_isr_46:
	inc hl
NAT_isr_47:
	ld (0x4111),hl
NAT_isr_48:
	ld a,h
NAT_isr_49:
	or l
NAT_isr_50:
	jp nz,Z_A186
NAT_isr_51:
	ld hl,0x4113
NAT_isr_52:
	inc (hl)
Z_A186:
NAT_isr_54:
	ld a,(0x0FED)
NAT_isr_55:
	dec a
NAT_isr_56:
	ret z
NAT_isr_57:
	ld hl,(0x4114)
NAT_isr_58:
	inc hl
NAT_isr_59:
	ld (0x4114),hl
NAT_isr_60:
	ret
Z_372C:
NAT_isr_62:
	call 0x063F
Z_3811:
NAT_isr_64:
	ld hl,0x4104
NAT_isr_65:
	ld b,0x0B
is_k1:
NAT_isr_67:
	ld a,(hl)
NAT_isr_68:
	cp 0xFF
NAT_isr_69:
	jp nz,is_k2
NAT_isr_70:
	inc hl
NAT_isr_71:
	dec b
NAT_isr_72:
	jp nz,is_k1
NAT_isr_73:
	ld (0x410F),a
NAT_isr_74:
	ld (0x4110),a
NAT_isr_75:
	ret
is_k2:
NAT_isr_77:
	ld c,0
is_k3:
NAT_isr_79:
	rrca
NAT_isr_80:
	jp nc,is_k4
NAT_isr_81:
	inc c
NAT_isr_82:
	jp is_k3
is_k4:
NAT_isr_84:
	ld a,0x0B
NAT_isr_85:
	sub b
NAT_isr_86:
	rlca
NAT_isr_87:
	rlca
NAT_isr_88:
	rlca
NAT_isr_89:
	add a,c
NAT_isr_90:
	ld (0x410F),a
NAT_isr_91:
	ld e,a
NAT_isr_92:
	ld d,0
NAT_isr_93:
	ld hl,(0x3436)
NAT_isr_94:
	add hl,de
NAT_isr_95:
	ld a,(hl)
NAT_isr_96:
	cp 5
NAT_isr_97:
	jp z,Z_36D7
NAT_isr_98:
	ld (0x4110),a
NAT_isr_99:
	ret
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
Z_8CF7:
NAT_contact_1:
	ld hl,(z80_ix)
NAT_contact_2:
	ld a,(hl)
NAT_contact_3:
	ld (ct_x0),a
NAT_contact_4:
	inc hl
NAT_contact_5:
	ld a,(hl)
NAT_contact_6:
	ld (ct_x1),a
NAT_contact_7:
	dec hl
NAT_contact_8:
	dec hl
NAT_contact_9:
	ld a,(hl)
NAT_contact_10:
	ld (ct_px),a
NAT_contact_11:
	ld hl,(z80_iy)
NAT_contact_12:
	ld a,(hl)
NAT_contact_13:
	ld (ct_y0),a
NAT_contact_14:
	dec hl
NAT_contact_15:
	ld a,(hl)
NAT_contact_16:
	ld (ct_py),a
NAT_contact_17:
	ld a,(0x93EB)
NAT_contact_18:
	ld b,a
NAT_contact_19:
	and 0x20
NAT_contact_20:
	jp nz,ct_held
NAT_contact_21:
	ld a,b
NAT_contact_22:
	rrca
NAT_contact_23:
	jp c,ct_loose
NAT_contact_24:
	ld a,b
NAT_contact_25:
	and 0x04
NAT_contact_26:
	jp nz,ct_held
NAT_contact_27:
	ld a,b
NAT_contact_28:
	and 0x02
NAT_contact_29:
	jp nz,ct_e2
NAT_contact_30:
	ld a,b
NAT_contact_31:
	and 0x08
NAT_contact_32:
	jp z,ct_n8
NAT_contact_33:
	ld c,0xE6
NAT_contact_34:
	ld a,(ct_x0)
NAT_contact_35:
	rrca
NAT_contact_36:
	jp nc,ct_hand
NAT_contact_37:
	jp ct_e2
ct_n8:
NAT_contact_39:
	ld a,b
NAT_contact_40:
	and 0x10
NAT_contact_41:
	jp z,ct_ball
NAT_contact_42:
	ld a,(ct_x0)
NAT_contact_43:
	rrca
NAT_contact_44:
	jp nc,ct_ball
ct_e2:
NAT_contact_46:
	ld c,0xE2
ct_hand:
NAT_contact_48:
	ld hl,(0x93F1)
NAT_contact_49:
	jp ct_with
ct_held:
NAT_contact_51:
	ld a,(ct_x0)
NAT_contact_52:
	and 0x10
NAT_contact_53:
	add a,0xF0
NAT_contact_54:
	ret
ct_loose:
NAT_contact_56:
	ld a,(ct_x0)
NAT_contact_57:
	and 0x10
NAT_contact_58:
	jp z,ct_l1
NAT_contact_59:
	scf
NAT_contact_60:
	ret
ct_l1:
NAT_contact_62:
	ld hl,(0x93F3)
NAT_contact_63:
	ld c,0
NAT_contact_64:
	ld a,(ct_y0)
NAT_contact_65:
	rrca
NAT_contact_66:
	jp nc,ct_with
NAT_contact_67:
	push hl
NAT_contact_68:
	ld hl,(z80_iy)
NAT_contact_69:
	inc hl
NAT_contact_70:
	inc hl
NAT_contact_71:
	inc hl
NAT_contact_72:
	inc hl
NAT_contact_73:
	ld a,(hl)
NAT_contact_74:
	pop hl
NAT_contact_75:
	ld l,a
ct_with:
NAT_contact_77:
	push hl
NAT_contact_78:
	push bc
NAT_contact_79:
	call ct_ball
NAT_contact_80:
	pop bc
NAT_contact_81:
	pop hl
NAT_contact_82:
	ret nc
NAT_contact_83:
	ex de,hl
NAT_contact_84:
	ld hl,(z80_ix)
NAT_contact_85:
	inc hl
NAT_contact_86:
	inc hl
NAT_contact_87:
	ld a,(ct_x0)
NAT_contact_88:
	rrca
NAT_contact_89:
	jp nc,ct_w1
NAT_contact_90:
	inc hl
NAT_contact_91:
	inc hl
ct_w1:
NAT_contact_93:
	ld a,(hl)
NAT_contact_94:
	inc hl
NAT_contact_95:
	ld h,(hl)
NAT_contact_96:
	ld l,a
NAT_contact_97:
	ex de,hl
NAT_contact_98:
	ld a,(ct_y0)
NAT_contact_99:
	rrca
NAT_contact_100:
	jp nc,ct_box
NAT_contact_101:
	ld a,l
NAT_contact_102:
	sub e
NAT_contact_103:
	jp nc,ct_w2
NAT_contact_104:
	cpl
NAT_contact_105:
	inc a
NAT_contact_106:
	add a,a
ct_w2:
NAT_contact_108:
	cpl
NAT_contact_109:
	inc a
NAT_contact_110:
	add a,c
NAT_contact_111:
	ld c,a
NAT_contact_112:
	jp ct_box
ct_ball:
NAT_contact_114:
	ld hl,(z80_ix)
NAT_contact_115:
	inc hl
NAT_contact_116:
	inc hl
NAT_contact_117:
	ld e,(hl)
NAT_contact_118:
	inc hl
NAT_contact_119:
	ld d,(hl)
NAT_contact_120:
	ld hl,(0x93F3)
NAT_contact_121:
	ld c,0
ct_box:
NAT_contact_123:
	ld a,e
NAT_contact_124:
	add a,c
NAT_contact_125:
	ld e,a
NAT_contact_126:
	ld a,(ct_px)
NAT_contact_127:
	and 0x04
NAT_contact_128:
	jp z,ct_low
NAT_contact_129:
	ld c,8
NAT_contact_130:
	ld b,4
NAT_contact_131:
	ld a,(ct_y0)
NAT_contact_132:
	and 0x10
NAT_contact_133:
	jp z,ct_hi2
NAT_contact_134:
	ld c,6
NAT_contact_135:
	ld a,(ct_py)
NAT_contact_136:
	and 0x04
NAT_contact_137:
	jp z,ct_hib
NAT_contact_138:
	ld b,3
NAT_contact_139:
	ld a,(ct_py)
NAT_contact_140:
	and 0x08
NAT_contact_141:
	jp nz,ct_hia
NAT_contact_142:
	ld b,6
NAT_contact_143:
	ld a,(ct_px)
NAT_contact_144:
	and 0x08
NAT_contact_145:
	jp nz,ct_hi2
NAT_contact_146:
	dec b
NAT_contact_147:
	jp ct_hi2
ct_hia:
NAT_contact_149:
	ld a,(ct_px)
NAT_contact_150:
	and 0x08
NAT_contact_151:
	jp z,ct_hi2
NAT_contact_152:
	inc b
NAT_contact_153:
	jp ct_hi2
ct_hib:
NAT_contact_155:
	ld b,6
NAT_contact_156:
	ld c,b
NAT_contact_157:
	ld a,(ct_py)
NAT_contact_158:
	and 0x02
NAT_contact_159:
	jp nz,ct_hi2
NAT_contact_160:
	ld b,4
NAT_contact_161:
	inc c
ct_hi2:
NAT_contact_163:
	ld a,d
NAT_contact_164:
	add a,b
NAT_contact_165:
	ld d,a
NAT_contact_166:
	ld a,(ct_px)
NAT_contact_167:
	and 0x08
NAT_contact_168:
	jp z,ct_hi3
NAT_contact_169:
	ld a,d
NAT_contact_170:
	ld d,h
NAT_contact_171:
	ld h,a
ct_hi3:
NAT_contact_173:
	ld a,d
NAT_contact_174:
	sub h
NAT_contact_175:
	cp c
NAT_contact_176:
	ret nc
NAT_contact_177:
	ld a,e
NAT_contact_178:
	add a,4
NAT_contact_179:
	sub l
NAT_contact_180:
	cp 9
NAT_contact_181:
	ret
ct_low:
NAT_contact_183:
	ld c,6
NAT_contact_184:
	ld a,e
NAT_contact_185:
	ld b,a
NAT_contact_186:
	ld a,(ct_y0)
NAT_contact_187:
	and 0x10
NAT_contact_188:
	ld a,b
NAT_contact_189:
	jp z,ct_l37
NAT_contact_190:
	ld a,(ct_py)
NAT_contact_191:
	and 0x04
NAT_contact_192:
	jp z,ct_lo2
NAT_contact_193:
	ld a,b
NAT_contact_194:
	dec a
NAT_contact_195:
	dec c
NAT_contact_196:
	ld b,a
NAT_contact_197:
	ld a,(ct_px)
NAT_contact_198:
	and 0x02
NAT_contact_199:
	ld a,b
NAT_contact_200:
	jp z,ct_l30
NAT_contact_201:
	dec a
ct_l30:
NAT_contact_203:
	ld b,a
NAT_contact_204:
	ld a,(ct_x1)
NAT_contact_205:
	rrca
NAT_contact_206:
	ld a,b
NAT_contact_207:
	jp c,ct_l37
NAT_contact_208:
	inc a
NAT_contact_209:
	jp ct_l37
ct_lo2:
NAT_contact_211:
	ld a,(ct_py)
NAT_contact_212:
	and 0x02
NAT_contact_213:
	jp z,ct_lo3
NAT_contact_214:
	ld c,3
NAT_contact_215:
	ld a,b
NAT_contact_216:
	add a,4
NAT_contact_217:
	ld e,a
NAT_contact_218:
	ld a,(ct_px)
NAT_contact_219:
	and 0x02
NAT_contact_220:
	jp nz,ct_l27
NAT_contact_221:
	ld a,e
NAT_contact_222:
	add a,4
NAT_contact_223:
	ld e,a
NAT_contact_224:
	ld c,4
NAT_contact_225:
	ld a,(ct_x1)
NAT_contact_226:
	rrca
NAT_contact_227:
	ld a,e
NAT_contact_228:
	jp c,ct_l40
NAT_contact_229:
	inc c
NAT_contact_230:
	jp ct_l40
ct_lo3:
NAT_contact_232:
	ld c,5
NAT_contact_233:
	ld a,b
NAT_contact_234:
	add a,2
NAT_contact_235:
	ld e,a
NAT_contact_236:
	ld a,(ct_px)
NAT_contact_237:
	and 0x02
NAT_contact_238:
	jp nz,ct_l27
NAT_contact_239:
	ld a,e
NAT_contact_240:
	add a,4
NAT_contact_241:
	ld e,a
NAT_contact_242:
	ld c,2
NAT_contact_243:
	ld a,(ct_x1)
NAT_contact_244:
	rrca
NAT_contact_245:
	ld a,e
NAT_contact_246:
	jp c,ct_l40
NAT_contact_247:
	inc c
NAT_contact_248:
	jp ct_l40
ct_l27:
NAT_contact_250:
	ld a,(ct_x1)
NAT_contact_251:
	rrca
NAT_contact_252:
	jp c,ct_l44
NAT_contact_253:
	dec c
NAT_contact_254:
	jp ct_l44
ct_l37:
NAT_contact_256:
	add a,6
NAT_contact_257:
	ld e,a
NAT_contact_258:
	ld b,a
NAT_contact_259:
	ld a,(ct_px)
NAT_contact_260:
	and 0x02
NAT_contact_261:
	ld a,b
NAT_contact_262:
	jp nz,ct_l44
ct_l40:
NAT_contact_264:
	sub 0x0A
NAT_contact_265:
	ld e,l
NAT_contact_266:
	ld l,a
ct_l44:
NAT_contact_268:
	ld a,e
NAT_contact_269:
	sub l
NAT_contact_270:
	cp c
NAT_contact_271:
	ret nc
NAT_contact_272:
	ld a,d
NAT_contact_273:
	add a,0x0D
NAT_contact_274:
	ld b,a
NAT_contact_275:
	ld c,0x10
NAT_contact_276:
	ld a,(ct_px)
NAT_contact_277:
	and 0x02
NAT_contact_278:
	ld a,b
NAT_contact_279:
	jp z,ct_l57
NAT_contact_280:
	ld c,0x0E
NAT_contact_281:
	sub 2
ct_l57:
NAT_contact_283:
	sub h
NAT_contact_284:
	cp c
NAT_contact_285:
	ret
ct_x0:
NAT_contact_287:
	db 0
ct_x1:
NAT_contact_289:
	db 0
ct_px:
NAT_contact_291:
	db 0
ct_y0:
NAT_contact_293:
	db 0
ct_py:
NAT_contact_295:
	db 0
Z_8E5A:
NAT_action_1:
	ld a,0xFE
NAT_action_2:
	call ac_at
NAT_action_3:
	ld a,(hl)
NAT_action_4:
	and 0xEF
NAT_action_5:
	ld (hl),a
NAT_action_6:
	inc hl
NAT_action_7:
	inc hl
NAT_action_8:
	ld a,(hl)
NAT_action_9:
	and 0x10
NAT_action_10:
	jp nz,ac_air
NAT_action_11:
	inc hl
NAT_action_12:
	ld a,(hl)
NAT_action_13:
	and 0x40
NAT_action_14:
	jp z,ac_f00
NAT_action_15:
	ld a,(hl)
NAT_action_16:
	and 8
NAT_action_17:
	jp z,Z_8E73
ac_f00:
NAT_action_19:
	ld hl,(z80_iy)
NAT_action_20:
	ld a,(hl)
NAT_action_21:
	and 0x10
NAT_action_22:
	jp z,ac_f51
NAT_action_23:
	ld hl,(z80_ix)
NAT_action_24:
	inc hl
NAT_action_25:
	ld a,(hl)
NAT_action_26:
	and 0x20
NAT_action_27:
	jp nz,Z_98B3
NAT_action_28:
	jp ac_f51
ac_air:
NAT_action_30:
	ld a,(hl)
NAT_action_31:
	or 8
NAT_action_32:
	ld (hl),a
NAT_action_33:
	inc hl
NAT_action_34:
	ld b,(hl)
NAT_action_35:
	inc hl
NAT_action_36:
	ld a,(hl)
NAT_action_37:
	inc hl
NAT_action_38:
	ld h,(hl)
NAT_action_39:
	ld l,a
NAT_action_40:
	cp 0x50
NAT_action_41:
	jp c,ac_f51
NAT_action_42:
	cp 0x5B
NAT_action_43:
	jp nc,ac_f51
NAT_action_44:
	ld a,b
NAT_action_45:
	rrca
NAT_action_46:
	ld a,h
NAT_action_47:
	jp nc,ac_a1
NAT_action_48:
	cp 0x68
NAT_action_49:
	jp c,ac_f51
NAT_action_50:
	jp ac_f33
ac_a1:
NAT_action_52:
	cp 0x0D
NAT_action_53:
	jp nc,ac_f51
ac_f33:
NAT_action_55:
	ld a,0x0A
NAT_action_56:
	call ac_at
NAT_action_57:
	ld a,(hl)
NAT_action_58:
	cp 3
NAT_action_59:
	jp c,ac_f59
NAT_action_60:
	ld hl,(z80_ix)
NAT_action_61:
	ld a,(hl)
NAT_action_62:
	or 0x20
NAT_action_63:
	and 0xF7
NAT_action_64:
	ld (hl),a
NAT_action_65:
	ld b,9
NAT_action_66:
	ld a,(0x9400)
NAT_action_67:
	and a
NAT_action_68:
	jp nz,ac_f5f
NAT_action_69:
	ld a,2
NAT_action_70:
	ld (0x93D3),a
NAT_action_71:
	jp ac_f5f
ac_f51:
NAT_action_73:
	ld a,0x0A
NAT_action_74:
	call ac_at
NAT_action_75:
	ld a,(hl)
NAT_action_76:
	ld b,4
NAT_action_77:
	and a
NAT_action_78:
	jp nz,ac_f5f
ac_f59:
NAT_action_80:
	ld b,2
NAT_action_81:
	ld hl,(z80_ix)
NAT_action_82:
	inc hl
NAT_action_83:
	ld a,(hl)
NAT_action_84:
	or 0x80
NAT_action_85:
	ld (hl),a
ac_f5f:
NAT_action_87:
	ld hl,(z80_ix)
NAT_action_88:
	ld a,(hl)
NAT_action_89:
	or 1
NAT_action_90:
	ld (hl),a
NAT_action_91:
	ld de,8
NAT_action_92:
	add hl,de
NAT_action_93:
	ld (hl),b
NAT_action_94:
	ld de,0xFFF4
NAT_action_95:
	add hl,de
NAT_action_96:
	ld (hl),0
NAT_action_97:
	ld de,6
NAT_action_98:
	add hl,de
NAT_action_99:
	ld a,(hl)
NAT_action_100:
	inc hl
NAT_action_101:
	ld b,(hl)
NAT_action_102:
	inc hl
NAT_action_103:
	ld (hl),a
NAT_action_104:
	inc hl
NAT_action_105:
	ld (hl),b
Z_8F76:
NAT_action_107:
	ld a,0xFC
NAT_action_108:
	call ac_at
NAT_action_109:
	inc (hl)
NAT_action_110:
	call Z_938E
NAT_action_111:
	ld hl,(z80_ix)
NAT_action_112:
	ld a,(hl)
NAT_action_113:
	and 2
NAT_action_114:
	jp nz,ac_land
NAT_action_115:
	call Z_93A3
NAT_action_116:
	call Z_93A3
NAT_action_117:
	ld hl,(z80_ix)
NAT_action_118:
	ld a,(hl)
NAT_action_119:
	and 0x20
NAT_action_120:
	jp z,ac_fe6
NAT_action_121:
	dec hl
NAT_action_122:
	ld a,(hl)
NAT_action_123:
	and 4
NAT_action_124:
	jp z,ac_faf
NAT_action_125:
	ld b,(hl)
NAT_action_126:
	inc hl
NAT_action_127:
	ld a,(hl)
NAT_action_128:
	and 0xBF
NAT_action_129:
	ld (hl),a
NAT_action_130:
	inc hl
NAT_action_131:
	ld a,(hl)
NAT_action_132:
	rrca
NAT_action_133:
	ld e,8
NAT_action_134:
	jp c,ac_fa3
NAT_action_135:
	ld e,0
ac_fa3:
NAT_action_137:
	ld a,b
NAT_action_138:
	and 8
NAT_action_139:
	xor e
NAT_action_140:
	jp z,ac_faf
NAT_action_141:
	dec hl
NAT_action_142:
	ld a,(hl)
NAT_action_143:
	or 0x40
NAT_action_144:
	ld (hl),a
ac_faf:
NAT_action_146:
	ld bc,0
NAT_action_147:
	ld hl,(z80_ix)
NAT_action_148:
	inc hl
NAT_action_149:
	inc hl
NAT_action_150:
	ld a,(hl)
NAT_action_151:
	cp 0x54
NAT_action_152:
	jp z,ac_fc3
NAT_action_153:
	ld c,2
NAT_action_154:
	jp c,ac_fbf
NAT_action_155:
	ld c,0xFE
ac_fbf:
NAT_action_157:
	add a,c
NAT_action_158:
	ld (hl),a
ac_fc3:
NAT_action_160:
	dec hl
NAT_action_161:
	ld a,(hl)
NAT_action_162:
	inc hl
NAT_action_163:
	inc hl
NAT_action_164:
	rrca
NAT_action_165:
	ld e,9
NAT_action_166:
	jp nc,ac_fcd
NAT_action_167:
	ld e,0x6B
ac_fcd:
NAT_action_169:
	ld a,(hl)
NAT_action_170:
	cp e
NAT_action_171:
	jp z,ac_fdd
NAT_action_172:
	jp c,ac_fd5
NAT_action_173:
	dec a
NAT_action_174:
	ld b,0xFF
NAT_action_175:
	jp ac_fdd
ac_fd5:
NAT_action_177:
	inc a
NAT_action_178:
	ld b,1
ac_fdd:
NAT_action_180:
	ld (hl),a
NAT_action_181:
	inc hl
NAT_action_182:
	inc hl
NAT_action_183:
	ld (hl),a
NAT_action_184:
	call Z_938B
ac_fe6:
NAT_action_186:
	ld hl,(z80_ix)
NAT_action_187:
	inc hl
NAT_action_188:
	inc hl
NAT_action_189:
	inc hl
NAT_action_190:
	inc hl
NAT_action_191:
	ld a,(hl)
NAT_action_192:
	sub 4
NAT_action_193:
	ld (hl),a
NAT_action_194:
	inc hl
NAT_action_195:
	inc hl
NAT_action_196:
	inc hl
NAT_action_197:
	inc hl
NAT_action_198:
	dec (hl)
NAT_action_199:
	jp nz,Z_9009
NAT_action_200:
	ld hl,(z80_ix)
NAT_action_201:
	ld a,(hl)
NAT_action_202:
	or 2
NAT_action_203:
	ld (hl),a
NAT_action_204:
	and 0x10
NAT_action_205:
	jp z,Z_9009
NAT_action_206:
	inc hl
NAT_action_207:
	ld a,(hl)
NAT_action_208:
	and 0x80
NAT_action_209:
	jp z,Z_9009
NAT_action_210:
	dec hl
NAT_action_211:
	dec hl
NAT_action_212:
	dec hl
NAT_action_213:
	ld a,(hl)
NAT_action_214:
	or 0x10
NAT_action_215:
	ld (hl),a
NAT_action_216:
	jp ac_rel
Z_9009:
NAT_action_218:
	ld hl,(z80_ix)
NAT_action_219:
	ld a,(hl)
	jp	NAT_action_220	; мост в следующий кусок
	org	0x9321
wk_c2:
NAT_walk_293:
	cp 0x38
NAT_walk_294:
	ret c
wk_c3:
NAT_walk_296:
	ld e,5
NAT_walk_297:
	call Z_9919
NAT_walk_298:
	ld hl,(z80_ix)
NAT_walk_299:
	inc hl
NAT_walk_300:
	ld a,(hl)
NAT_walk_301:
	and 0xEF
NAT_walk_302:
	ld (hl),a
NAT_walk_303:
	ret
wk_idle:
NAT_walk_305:
	ld hl,(z80_ix)
NAT_walk_306:
	inc hl
NAT_walk_307:
	ld a,(hl)
NAT_walk_308:
	and 0xDF
NAT_walk_309:
	ld (hl),a
NAT_walk_310:
	jp Z_9E82
wk_neary:
NAT_walk_312:
	ld a,d
NAT_walk_313:
	sub h
NAT_walk_314:
	jp nc,wk_ny1
NAT_walk_315:
	cpl
NAT_walk_316:
	inc a
	jp	wk_ny1	; мост в следующий кусок
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
wk_ny1:
NAT_walk_318:
	cp 6
NAT_walk_319:
	ret
wk_nearx:
NAT_walk_321:
	ld a,l
NAT_walk_322:
	sub e
NAT_walk_323:
	jp nc,wk_nx1
NAT_walk_324:
	cpl
NAT_walk_325:
	inc a
wk_nx1:
NAT_walk_327:
	cp 3
NAT_walk_328:
	ret
wk_set5:
NAT_walk_330:
	push hl
NAT_walk_331:
	ld hl,(z80_ix)
NAT_walk_332:
	inc hl
NAT_walk_333:
	ld a,(hl)
NAT_walk_334:
	or 0x20
NAT_walk_335:
	ld (hl),a
NAT_walk_336:
	pop hl
NAT_walk_337:
	ret
wk_rate:
NAT_walk_339:
	push hl
NAT_walk_340:
	push bc
NAT_walk_341:
	ld hl,(z80_ix)
NAT_walk_342:
	ld bc,0x0A
NAT_walk_343:
	add hl,bc
NAT_walk_344:
	ld a,(hl)
NAT_walk_345:
	and a
NAT_walk_346:
	jp nz,wk_r1
NAT_walk_347:
	ld bc,0xFFF1
NAT_walk_348:
	add hl,bc
NAT_walk_349:
	ld a,(hl)
NAT_walk_350:
	inc a
NAT_walk_351:
	and 1
NAT_walk_352:
	ld (hl),a
NAT_walk_353:
	pop bc
NAT_walk_354:
	pop hl
NAT_walk_355:
	ret
wk_r1:
NAT_walk_357:
	ld bc,0xFFF6
NAT_walk_358:
	add hl,bc
NAT_walk_359:
	ld a,(hl)
NAT_walk_360:
	and 0x10
NAT_walk_361:
	jp z,wk_rx
NAT_walk_362:
	ld a,(0x93EB)
NAT_walk_363:
	and 0x40
NAT_walk_364:
	jp z,wk_rx
NAT_walk_365:
	ld bc,0xFFFA
NAT_walk_366:
	add hl,bc
NAT_walk_367:
	dec (hl)
NAT_walk_368:
	jp nz,wk_rx
NAT_walk_369:
	ld a,(0x93EB)
NAT_walk_370:
	and 0xBF
	jp	NAT_walk_371	; мост в следующий кусок
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
NAT_walk_371:
	ld (0x93EB),a
NAT_walk_372:
	xor a
wk_rx:
NAT_walk_374:
	pop bc
NAT_walk_375:
	pop hl
NAT_walk_376:
	ret
wk_p7:
NAT_walk_378:
	dw 0
wk_t:
NAT_walk_380:
	db 0
Z_9E82:
NAT_stamina_1:
	ld a,(0x93D6)
NAT_stamina_2:
	and a
NAT_stamina_3:
	ret nz
NAT_stamina_4:
	ld a,(0x93D3)
NAT_stamina_5:
	dec a
NAT_stamina_6:
	ret z
NAT_stamina_7:
	ld hl,(z80_ix)
NAT_stamina_8:
	ld de,0x0A
NAT_stamina_9:
	add hl,de
NAT_stamina_10:
	ld a,(hl)
NAT_stamina_11:
	cp 0x16
NAT_stamina_12:
	ret nc
NAT_stamina_13:
	dec hl
NAT_stamina_14:
	ld b,1
NAT_stamina_15:
	ld c,(hl)
NAT_stamina_16:
	ld a,c
NAT_stamina_17:
	and 0x80
NAT_stamina_18:
	ld a,b
NAT_stamina_19:
	jp z,su1
NAT_stamina_20:
	ld a,c
NAT_stamina_21:
	and 0x7F
NAT_stamina_22:
	ld c,a
NAT_stamina_23:
	ld a,b
NAT_stamina_24:
	sub c
NAT_stamina_25:
	jp nc,su0
NAT_stamina_26:
	xor a
su0:
NAT_stamina_28:
	ld c,a
NAT_stamina_29:
	ld a,b
su1:
NAT_stamina_31:
	inc c
NAT_stamina_32:
	cp c
NAT_stamina_33:
	jp nc,su2
NAT_stamina_34:
	ld c,0
su2:
NAT_stamina_36:
	ld (hl),c
NAT_stamina_37:
	ret nc
NAT_stamina_38:
	inc hl
NAT_stamina_39:
	ld a,(hl)
NAT_stamina_40:
	ld c,a
NAT_stamina_41:
	inc a
NAT_stamina_42:
	ld (hl),a
NAT_stamina_43:
	ld e,0xEE
NAT_stamina_44:
	jp st_cell
Z_9ED4:
NAT_stamina_46:
	ld a,(0x93D6)
NAT_stamina_47:
	and a
NAT_stamina_48:
	ret nz
NAT_stamina_49:
	ld a,(0x93D3)
NAT_stamina_50:
	dec a
NAT_stamina_51:
	ret z
NAT_stamina_52:
	ld hl,(z80_ix)
NAT_stamina_53:
	ld de,0x0A
NAT_stamina_54:
	add hl,de
NAT_stamina_55:
	ld a,(hl)
NAT_stamina_56:
	and a
NAT_stamina_57:
	ret z
NAT_stamina_58:
	dec hl
NAT_stamina_59:
	ld b,7
NAT_stamina_60:
	ld c,(hl)
NAT_stamina_61:
	ld a,c
NAT_stamina_62:
	and 0x80
NAT_stamina_63:
	ld a,b
NAT_stamina_64:
	jp nz,sd1
NAT_stamina_65:
	sub c
NAT_stamina_66:
	jp nc,sd0
NAT_stamina_67:
	xor a
sd0:
NAT_stamina_69:
	ld c,a
NAT_stamina_70:
	ld a,b
sd1:
NAT_stamina_72:
	ld e,a
NAT_stamina_73:
	ld a,c
NAT_stamina_74:
	and 0x7F
NAT_stamina_75:
	inc a
NAT_stamina_76:
	ld c,a
NAT_stamina_77:
	ld a,e
NAT_stamina_78:
	cp c
NAT_stamina_79:
	jp c,sd2
NAT_stamina_80:
	ld a,c
NAT_stamina_81:
	or 0x80
NAT_stamina_82:
	ld (hl),a
NAT_stamina_83:
	ret
sd2:
NAT_stamina_85:
	ld (hl),0x80
NAT_stamina_86:
	inc hl
NAT_stamina_87:
	ld a,(hl)
NAT_stamina_88:
	dec a
NAT_stamina_89:
	ld (hl),a
NAT_stamina_90:
	inc a
NAT_stamina_91:
	ld c,a
NAT_stamina_92:
	ld e,0
st_cell:
NAT_stamina_94:
	ld hl,(z80_ix)
NAT_stamina_95:
	inc hl
NAT_stamina_96:
	ld a,(hl)
NAT_stamina_97:
	ld hl,0x1001
NAT_stamina_98:
	rrca
NAT_stamina_99:
	jp c,st_c1
NAT_stamina_100:
	ld l,0x14
st_c1:
NAT_stamina_102:
	ld a,c
NAT_stamina_103:
	or a
NAT_stamina_104:
	rra
NAT_stamina_105:
	add a,l
NAT_stamina_106:
	ld l,a
NAT_stamina_107:
	ld a,c
NAT_stamina_108:
	ld c,e
NAT_stamina_109:
	rrca
NAT_stamina_110:
	jp c,st_c2
NAT_stamina_111:
	ld c,0xE0
NAT_stamina_112:
	ld a,e
NAT_stamina_113:
	or a
NAT_stamina_114:
	jp z,st_c3
NAT_stamina_115:
	inc l
st_c3:
NAT_stamina_117:
	dec l
st_c2:
NAT_stamina_119:
	jp Z_9F48
Z_9F25:
NAT_stamina_121:
	ld hl,0x1001
NAT_stamina_122:
	ld a,(0x9415)
NAT_stamina_123:
	ld c,0xEE
NAT_stamina_124:
	call Z_9F36
NAT_stamina_125:
	ld hl,0x1014
NAT_stamina_126:
	ld a,(0x942F)
Z_9F36:
NAT_stamina_128:
	and a
NAT_stamina_129:
	ret z
NAT_stamina_130:
	ld b,a
NAT_stamina_131:
	ld a,b
NAT_stamina_132:
	or a
NAT_stamina_133:
	rra
NAT_stamina_134:
	ld e,a
NAT_stamina_135:
	ld a,b
NAT_stamina_136:
	ld b,e
NAT_stamina_137:
	inc b
NAT_stamina_138:
	dec b
NAT_stamina_139:
	jp z,st_b2
st_b1:
NAT_stamina_141:
	call Z_9F48
NAT_stamina_142:
	inc l
NAT_stamina_143:
	dec b
NAT_stamina_144:
	jp nz,st_b1
st_b2:
NAT_stamina_146:
	rrca
NAT_stamina_147:
	ret nc
NAT_stamina_148:
	ld c,0xE0
NAT_stamina_149:
	jp Z_9F48
Z_9F60:
NAT_stamina_151:
	ld hl,Z_9F6E
NAT_stamina_152:
	ld (Z_3705+1),hl
NAT_stamina_153:
	ret
Z_9F67:
NAT_stamina_155:
	ld hl,Z_9F6D
NAT_stamina_156:
	ld (Z_3705+1),hl
Z_9F6D:
NAT_stamina_158:
	ret
Z_9F6E:
NAT_stamina_160:
	call Z_3715
NAT_stamina_161:
	ld a,(0x93E6)
NAT_stamina_162:
	inc a
NAT_stamina_163:
	cp 0x32
NAT_stamina_164:
	jp c,st_k1
NAT_stamina_165:
	xor a
st_k1:
NAT_stamina_167:
	ld (0x93E6),a
NAT_stamina_168:
	ret c
NAT_stamina_169:
	ld a,0x2F
NAT_stamina_170:
	ld hl,0x93E9
NAT_stamina_171:
	dec (hl)
NAT_stamina_172:
	cp (hl)
NAT_stamina_173:
	ret nz
NAT_stamina_174:
	ld (hl),0x39
NAT_stamina_175:
	dec hl
NAT_stamina_176:
	dec (hl)
NAT_stamina_177:
	cp (hl)
NAT_stamina_178:
	ret nz
NAT_stamina_179:
	ld (hl),0x35
NAT_stamina_180:
	dec hl
NAT_stamina_181:
	dec (hl)
NAT_stamina_182:
	cp (hl)
NAT_stamina_183:
	ret nz
NAT_stamina_184:
	ld a,1
NAT_stamina_185:
	ld (0x93E5),a
NAT_stamina_186:
	jp Z_9F67
Z_958F:
NAT_pdraw_1:
	ld hl,0x9425
NAT_pdraw_2:
	ld (z80_ix),hl
NAT_pdraw_3:
	ld hl,0x940B
NAT_pdraw_4:
	ld (z80_iy),hl
NAT_pdraw_5:
	jp Z_95A1
Z_9599:
NAT_pdraw_7:
	ld hl,0x940B
NAT_pdraw_8:
	ld (z80_ix),hl
NAT_pdraw_9:
	ld hl,0x9425
NAT_pdraw_10:
	ld (z80_iy),hl
Z_95A1:
NAT_pdraw_12:
	call pd_pose
NAT_pdraw_13:
	ld a,(pd_x0)
NAT_pdraw_14:
	and 0x20
NAT_pdraw_15:
	jp nz,pd_jump
NAT_pdraw_16:
	ld a,e
NAT_pdraw_17:
	and 0x20
NAT_pdraw_18:
	jp nz,pd_shot
NAT_pdraw_19:
	ld a,(pd_x0)
NAT_pdraw_20:
	and 0x80
NAT_pdraw_21:
	jp nz,pd_shot
NAT_pdraw_22:
	ld a,e
NAT_pdraw_23:
	and 0x40
NAT_pdraw_24:
	jp nz,pd_ball
NAT_pdraw_25:
	ld a,(pd_x0)
NAT_pdraw_26:
	rrca
NAT_pdraw_27:
	jp c,pd_ball
NAT_pdraw_28:
	ld hl,(z80_ix)
NAT_pdraw_29:
	ld de,0x9442
NAT_pdraw_30:
	ld a,1
NAT_pdraw_31:
	ld (pd_e),a
NAT_pdraw_32:
	ld a,(pd_m2)
NAT_pdraw_33:
	and 0x1F
NAT_pdraw_34:
	jp nz,pd_w1
NAT_pdraw_35:
	ld a,(pd_x0)
NAT_pdraw_36:
	and 0x10
NAT_pdraw_37:
	ld a,0
NAT_pdraw_38:
	jp z,pd_w3
NAT_pdraw_39:
	ld a,(hl)
NAT_pdraw_40:
	or 4
NAT_pdraw_41:
	ld (hl),a
NAT_pdraw_42:
	ld de,0x9446
NAT_pdraw_43:
	xor a
NAT_pdraw_44:
	ld (pd_e),a
NAT_pdraw_45:
	jp pd_w2
pd_w1:
NAT_pdraw_47:
	ld a,(pd_x0)
NAT_pdraw_48:
	and 4
NAT_pdraw_49:
	jp z,pd_w2
NAT_pdraw_50:
	ld a,(hl)
NAT_pdraw_51:
	and 0xFB
NAT_pdraw_52:
	ld (hl),a
NAT_pdraw_53:
	call pd_ix6
NAT_pdraw_54:
	ld a,(hl)
NAT_pdraw_55:
	dec a
NAT_pdraw_56:
	or 1
NAT_pdraw_57:
	jp pd_w4
pd_w2:
NAT_pdraw_59:
	call pd_ix6
NAT_pdraw_60:
	ld a,(hl)
NAT_pdraw_61:
	jp pd_w4
pd_w3:
NAT_pdraw_63:
	call pd_ix6
pd_w4:
NAT_pdraw_65:
	inc a
NAT_pdraw_66:
	and 3
NAT_pdraw_67:
	ld (hl),a
NAT_pdraw_68:
	inc hl
NAT_pdraw_69:
	ex de,hl
NAT_pdraw_70:
	add a,l
NAT_pdraw_71:
	ld l,a
NAT_pdraw_72:
	ld a,h
NAT_pdraw_73:
	adc a,0
NAT_pdraw_74:
	ld h,a
NAT_pdraw_75:
	ld a,(hl)
NAT_pdraw_76:
	ld (de),a
NAT_pdraw_77:
	ld hl,0x944A
NAT_pdraw_78:
	add a,l
NAT_pdraw_79:
	ld l,a
NAT_pdraw_80:
	ld a,h
NAT_pdraw_81:
	adc a,0
NAT_pdraw_82:
	ld h,a
NAT_pdraw_83:
	ld b,(hl)
NAT_pdraw_84:
	ld hl,(z80_ix)
NAT_pdraw_85:
	inc hl
NAT_pdraw_86:
	inc hl
NAT_pdraw_87:
	ld a,(hl)
NAT_pdraw_88:
	inc hl
NAT_pdraw_89:
	ld h,(hl)
NAT_pdraw_90:
	ld l,a
NAT_pdraw_91:
	ld a,(pd_e)
NAT_pdraw_92:
	or a
NAT_pdraw_93:
	ld a,b
NAT_pdraw_94:
	jp nz,pd_w5
NAT_pdraw_95:
	ld a,0xDB
pd_w5:
NAT_pdraw_97:
	add a,l
NAT_pdraw_98:
	ld l,a
NAT_pdraw_99:
	push hl
NAT_pdraw_100:
	call pd_body
NAT_pdraw_101:
	call pd_pose
NAT_pdraw_102:
	pop hl
NAT_pdraw_103:
	ld a,b
NAT_pdraw_104:
	and 4
NAT_pdraw_105:
	jp z,pd_w6
NAT_pdraw_106:
	ld a,0x0A
NAT_pdraw_107:
	call pd_b3c
NAT_pdraw_108:
	jp pd_w7
pd_w6:
NAT_pdraw_110:
	ld a,0x22
NAT_pdraw_111:
	call pd_nb1c
pd_w7:
NAT_pdraw_113:
	call pd_side
NAT_pdraw_114:
	ld b,a
NAT_pdraw_115:
	ld a,(pd_x0)
NAT_pdraw_116:
	and 0x10
NAT_pdraw_117:
	ld a,b
NAT_pdraw_118:
	call nz,pd_cpose
NAT_pdraw_119:
	jp pd_blit
pd_body:
NAT_pdraw_121:
	call pd_pose
NAT_pdraw_122:
	ld hl,(z80_ix)
NAT_pdraw_123:
	inc hl
NAT_pdraw_124:
	inc hl
NAT_pdraw_125:
	ld a,(hl)
NAT_pdraw_126:
	sub 0x1C
NAT_pdraw_127:
	inc hl
NAT_pdraw_128:
	ld h,(hl)
NAT_pdraw_129:
	ld l,a
NAT_pdraw_130:
	ld (0x3300),hl
NAT_pdraw_131:
	ld hl,(z80_ix)
NAT_pdraw_132:
	ld de,7
NAT_pdraw_133:
	add hl,de
NAT_pdraw_134:
	ld a,(hl)
NAT_pdraw_135:
	ld d,a
NAT_pdraw_136:
	ld a,(pd_x0)
NAT_pdraw_137:
	and 0x10
NAT_pdraw_138:
	ld a,d
NAT_pdraw_139:
	jp z,pd_b1
NAT_pdraw_140:
	add a,3
pd_b1:
NAT_pdraw_142:
	ld d,a
NAT_pdraw_143:
	ld a,b
NAT_pdraw_144:
	and 4
NAT_pdraw_145:
	ld a,d
NAT_pdraw_146:
	jp z,pd_b2
NAT_pdraw_147:
	call pd_b3c
NAT_pdraw_148:
	jp pd_b4
pd_b2:
NAT_pdraw_150:
	add a,0x18
NAT_pdraw_151:
	call pd_nb1c
pd_b4:
NAT_pdraw_153:
	ld (pd_fr),a
NAT_pdraw_154:
	call Z_9E6F
NAT_pdraw_155:
	call Z_B01C
NAT_pdraw_156:
	ld a,(pd_fr)
NAT_pdraw_157:
	ld d,a
NAT_pdraw_158:
	ld hl,0x94A7
pd_b5:
NAT_pdraw_160:
	ld a,(hl)
NAT_pdraw_161:
	inc hl
NAT_pdraw_162:
	and a
NAT_pdraw_163:
	ret z
NAT_pdraw_164:
	cp d
NAT_pdraw_165:
	jp nz,pd_b5
NAT_pdraw_166:
	ld a,(0x93EB)
NAT_pdraw_167:
	or 0x40
NAT_pdraw_168:
	ld (0x93EB),a
NAT_pdraw_169:
	ld hl,(z80_ix)
NAT_pdraw_170:
	ld de,0xFFFA
NAT_pdraw_171:
	add hl,de
NAT_pdraw_172:
	ld (hl),3
NAT_pdraw_173:
	ld a,(0x93D8)
NAT_pdraw_174:
	and a
NAT_pdraw_175:
	ret nz
NAT_pdraw_176:
	inc a
NAT_pdraw_177:
	ld (0xAA83),a
NAT_pdraw_178:
	ld hl,2
NAT_pdraw_179:
	ld (0x3300),hl
NAT_pdraw_180:
	ld hl,0x8070
NAT_pdraw_181:
	ld (0x3302),hl
NAT_pdraw_182:
	jp Z_AA80
pd_cpose:
NAT_pdraw_184:
	ld c,a
NAT_pdraw_185:
	ld a,(pd_x0)
NAT_pdraw_186:
	and 4
NAT_pdraw_187:
	ld a,c
NAT_pdraw_188:
	ret nz
NAT_pdraw_189:
	push hl
NAT_pdraw_190:
	ld hl,(z80_ix)
NAT_pdraw_191:
	inc hl
NAT_pdraw_192:
	inc hl
NAT_pdraw_193:
	ld e,(hl)
NAT_pdraw_194:
	inc hl
NAT_pdraw_195:
	ld d,(hl)
NAT_pdraw_196:
	ld hl,(z80_iy)
NAT_pdraw_197:
	inc hl
NAT_pdraw_198:
	inc hl
NAT_pdraw_199:
	inc hl
NAT_pdraw_200:
	ld a,d
NAT_pdraw_201:
	sub (hl)
NAT_pdraw_202:
	ld b,0x0A
NAT_pdraw_203:
	jp nc,pd_c1
NAT_pdraw_204:
	ld b,0x16
NAT_pdraw_205:
	cpl
NAT_pdraw_206:
	inc a
pd_c1:
NAT_pdraw_208:
	cp 6
NAT_pdraw_209:
	jp nc,pd_c9
NAT_pdraw_210:
	dec hl
NAT_pdraw_211:
	ld a,e
NAT_pdraw_212:
	sub (hl)
NAT_pdraw_213:
	jp nc,pd_c2
NAT_pdraw_214:
	cpl
NAT_pdraw_215:
	inc a
pd_c2:
NAT_pdraw_217:
	cp 0x0A
NAT_pdraw_218:
	jp nc,pd_c9
NAT_pdraw_219:
	pop hl
NAT_pdraw_220:
	ld a,(pd_x1)
NAT_pdraw_221:
	rrca
NAT_pdraw_222:
	jp nc,pd_c3
NAT_pdraw_223:
	inc b
pd_c3:
NAT_pdraw_225:
	ld a,b
NAT_pdraw_226:
	cp c
NAT_pdraw_227:
	ret z
NAT_pdraw_228:
	ld a,(pd_px)
NAT_pdraw_229:
	and 4
NAT_pdraw_230:
	ld a,b
NAT_pdraw_231:
	ret nz
NAT_pdraw_232:
	ld a,(pd_px)
NAT_pdraw_233:
	and 2
NAT_pdraw_234:
	ld a,c
NAT_pdraw_235:
	ret z
NAT_pdraw_236:
	ld a,(pd_x1)
NAT_pdraw_237:
	rrca
NAT_pdraw_238:
	ld a,b
NAT_pdraw_239:
	ret nc
NAT_pdraw_240:
	dec l
NAT_pdraw_241:
	ret
pd_c9:
NAT_pdraw_243:
	pop hl
NAT_pdraw_244:
	ld a,c
NAT_pdraw_245:
	ret
pd_ball:
NAT_pdraw_247:
	ld a,b
NAT_pdraw_248:
	and 6
NAT_pdraw_249:
	jp z,pd_bl1
NAT_pdraw_250:
	call pd_hand
NAT_pdraw_251:
	jp pd_arm
pd_bl1:
NAT_pdraw_253:
	call pd_arm
pd_hand:
NAT_pdraw_255:
	call pd_pose
NAT_pdraw_256:
	ld hl,(z80_ix)
NAT_pdraw_257:
	inc hl
NAT_pdraw_258:
	inc hl
NAT_pdraw_259:
	inc hl
NAT_pdraw_260:
	inc hl
NAT_pdraw_261:
	ld a,(hl)
NAT_pdraw_262:
	sub 0x25
NAT_pdraw_263:
	inc hl
NAT_pdraw_264:
	ld h,(hl)
NAT_pdraw_265:
	ld l,a
NAT_pdraw_266:
	ld a,b
NAT_pdraw_267:
	and 4
NAT_pdraw_268:
	ld a,0x0A
NAT_pdraw_269:
	jp z,pd_h1
NAT_pdraw_270:
	call pd_b3c
NAT_pdraw_271:
	jp pd_h2
pd_h1:
NAT_pdraw_273:
	add a,0x18
NAT_pdraw_274:
	call pd_nb1c
pd_h2:
NAT_pdraw_276:
	call pd_side
NAT_pdraw_277:
	jp pd_blit
pd_arm:
NAT_pdraw_279:
	call pd_pose
NAT_pdraw_280:
	ld hl,(z80_ix)
NAT_pdraw_281:
	inc hl
NAT_pdraw_282:
	inc hl
NAT_pdraw_283:
	inc hl
NAT_pdraw_284:
	inc hl
NAT_pdraw_285:
	ld a,(hl)
NAT_pdraw_286:
	sub 0x24
NAT_pdraw_287:
	inc hl
NAT_pdraw_288:
	ld h,(hl)
NAT_pdraw_289:
	ld l,a
NAT_pdraw_290:
	ld a,(pd_x0)
NAT_pdraw_291:
	and 0x10
NAT_pdraw_292:
	ld a,9
NAT_pdraw_293:
	jp z,pd_a1
NAT_pdraw_294:
	dec a
pd_a1:
NAT_pdraw_296:
	ld d,a
NAT_pdraw_297:
	ld a,b
NAT_pdraw_298:
	and 4
NAT_pdraw_299:
	ld a,d
NAT_pdraw_300:
	jp z,pd_a2
NAT_pdraw_301:
	ld a,b
NAT_pdraw_302:
	and 8
NAT_pdraw_303:
	ld a,d
NAT_pdraw_304:
	jp z,pd_blit
NAT_pdraw_305:
	add a,0x0C
NAT_pdraw_306:
	inc h
NAT_pdraw_307:
	jp pd_blit
pd_a2:
NAT_pdraw_309:
	add a,0x24
NAT_pdraw_310:
	ld d,a
NAT_pdraw_311:
	ld a,b
NAT_pdraw_312:
	and 2
NAT_pdraw_313:
	ld a,d
NAT_pdraw_314:
	jp z,pd_blit
NAT_pdraw_315:
	sub 0x0C
NAT_pdraw_316:
	jp pd_blit
pd_shot:
NAT_pdraw_318:
	ld hl,(z80_ix)
NAT_pdraw_319:
	inc hl
NAT_pdraw_320:
	inc hl
NAT_pdraw_321:
	inc hl
NAT_pdraw_322:
	inc hl
NAT_pdraw_323:
	ld a,(hl)
NAT_pdraw_324:
	sub 0x24
NAT_pdraw_325:
	inc hl
NAT_pdraw_326:
	ld h,(hl)
NAT_pdraw_327:
	ld l,a
NAT_pdraw_328:
	ld a,(pd_x1)
NAT_pdraw_329:
	rrca
NAT_pdraw_330:
	jp nc,pd_s1
NAT_pdraw_331:
	dec h
NAT_pdraw_332:
	dec h
pd_s1:
NAT_pdraw_334:
	ld (0x3300),hl
NAT_pdraw_335:
	ld hl,(z80_ix)
NAT_pdraw_336:
	ld de,7
NAT_pdraw_337:
	add hl,de
NAT_pdraw_338:
	ld a,(hl)
NAT_pdraw_339:
	add a,0x36
NAT_pdraw_340:
	ld d,a
NAT_pdraw_341:
	ld a,b
NAT_pdraw_342:
	and 2
NAT_pdraw_343:
	ld a,d
NAT_pdraw_344:
	jp nz,pd_s2
NAT_pdraw_345:
	add a,2
pd_s2:
NAT_pdraw_347:
	ld d,a
NAT_pdraw_348:
	ld a,(pd_x1)
NAT_pdraw_349:
	rrca
NAT_pdraw_350:
	ld a,d
NAT_pdraw_351:
	jp nc,pd_s3
NAT_pdraw_352:
	add a,4
pd_s3:
NAT_pdraw_354:
	call Z_9E6F
NAT_pdraw_355:
	call Z_B01C
NAT_pdraw_356:
	ld hl,(z80_ix)
NAT_pdraw_357:
	ld de,7
NAT_pdraw_358:
	add hl,de
NAT_pdraw_359:
	ld a,(hl)
NAT_pdraw_360:
	inc a
NAT_pdraw_361:
	and 1
NAT_pdraw_362:
	ret z
NAT_pdraw_363:
	ld (hl),a
NAT_pdraw_364:
	jp Z_90EF
pd_loose:
NAT_pdraw_366:
	ld a,(pd_x1)
NAT_pdraw_367:
	rrca
NAT_pdraw_368:
	ld a,0
NAT_pdraw_369:
	jp nc,pd_l1
NAT_pdraw_370:
	ld a,0x80
pd_l1:
NAT_pdraw_372:
	ld (0x93EB),a
NAT_pdraw_373:
	ld a,(0x9400)
NAT_pdraw_374:
	and a
NAT_pdraw_375:
	ld a,0
NAT_pdraw_376:
	jp nz,pd_l2
NAT_pdraw_377:
	ld hl,(z80_ix)
NAT_pdraw_378:
	ld de,0x0C
NAT_pdraw_379:
	add hl,de
NAT_pdraw_380:
	inc (hl)
NAT_pdraw_381:
	ld a,2
pd_l2:
NAT_pdraw_383:
	ld (0x93D9),a
NAT_pdraw_384:
	jp Z_8C16
pd_jump:
NAT_pdraw_386:
	ld hl,(z80_ix)
NAT_pdraw_387:
	inc hl
NAT_pdraw_388:
	inc hl
NAT_pdraw_389:
	inc hl
NAT_pdraw_390:
	inc hl
NAT_pdraw_391:
	ld a,(hl)
NAT_pdraw_392:
	sub 0x24
NAT_pdraw_393:
	inc hl
NAT_pdraw_394:
	ld h,(hl)
NAT_pdraw_395:
	dec h
NAT_pdraw_396:
	ld l,a
NAT_pdraw_397:
	ld (0x3300),hl
NAT_pdraw_398:
	ld c,2
NAT_pdraw_399:
	ld a,(pd_x0)
NAT_pdraw_400:
	and 0x40
NAT_pdraw_401:
	jp nz,pd_j1
NAT_pdraw_402:
	dec c
pd_j1:
NAT_pdraw_404:
	ld a,(pd_x0)
NAT_pdraw_405:
	and 2
NAT_pdraw_406:
	jp nz,pd_j5
NAT_pdraw_407:
	dec c
NAT_pdraw_408:
	ld a,(0x93EB)
NAT_pdraw_409:
	and 4
NAT_pdraw_410:
	jp nz,pd_dunk
NAT_pdraw_411:
	ld a,(pd_x0)
NAT_pdraw_412:
	and 0x40
NAT_pdraw_413:
	ld a,l
NAT_pdraw_414:
	jp z,pd_j2
NAT_pdraw_415:
	cp 0x22
NAT_pdraw_416:
	jp nc,pd_ball
NAT_pdraw_417:
	call pd_loose
NAT_pdraw_418:
	call pd_pose
NAT_pdraw_419:
	jp pd_ball
pd_j2:
NAT_pdraw_421:
	cp 0x22
NAT_pdraw_422:
	jp nc,pd_ball
NAT_pdraw_423:
	ld d,a
NAT_pdraw_424:
	ld hl,(z80_ix)
NAT_pdraw_425:
	inc hl
NAT_pdraw_426:
	ld a,(hl)
NAT_pdraw_427:
	or 8
NAT_pdraw_428:
	ld (hl),a
NAT_pdraw_429:
	ld a,d
NAT_pdraw_430:
	cp 0x1D
NAT_pdraw_431:
	jp nc,pd_j5
NAT_pdraw_432:
	call pd_loose
NAT_pdraw_433:
	call pd_pose
NAT_pdraw_434:
	jp pd_j5
pd_dunk:
NAT_pdraw_436:
	ld hl,(z80_ix)
NAT_pdraw_437:
	ld a,(hl)
NAT_pdraw_438:
	or 2
NAT_pdraw_439:
	and 0xE7
NAT_pdraw_440:
	ld (hl),a
NAT_pdraw_441:
	inc hl
NAT_pdraw_442:
	ld a,(hl)
NAT_pdraw_443:
	or 8
NAT_pdraw_444:
	ld (hl),a
NAT_pdraw_445:
	ld hl,0x084C
NAT_pdraw_446:
	ld a,(pd_x1)
NAT_pdraw_447:
	rrca
NAT_pdraw_448:
	jp nc,pd_d1
NAT_pdraw_449:
	ld h,0x74
pd_d1:
NAT_pdraw_451:
	ld (0x93F3),hl
NAT_pdraw_452:
	ld l,0x21
NAT_pdraw_453:
	ld (0x93F1),hl
NAT_pdraw_454:
	inc c
NAT_pdraw_455:
	push bc
NAT_pdraw_456:
	ld hl,(0x3300)
NAT_pdraw_457:
	push hl
NAT_pdraw_458:
	xor a
NAT_pdraw_459:
	ld (0xAA83),a
NAT_pdraw_460:
	ld hl,2
NAT_pdraw_461:
	ld (0x3300),hl
NAT_pdraw_462:
	ld hl,0x8039
NAT_pdraw_463:
	ld (0x3302),hl
NAT_pdraw_464:
	call Z_AA80
NAT_pdraw_465:
	pop hl
NAT_pdraw_466:
	ld (0x3300),hl
NAT_pdraw_467:
	call pd_pose
NAT_pdraw_468:
	pop bc
pd_j5:
NAT_pdraw_470:
	ld a,0x30
NAT_pdraw_471:
	add a,c
NAT_pdraw_472:
	ld c,1
NAT_pdraw_473:
	ld e,a
NAT_pdraw_474:
	ld a,b
NAT_pdraw_475:
	and 4
NAT_pdraw_476:
	ld a,e
NAT_pdraw_477:
	jp nz,pd_j8
NAT_pdraw_478:
	ld hl,0x3301
NAT_pdraw_479:
	ld a,(pd_x1)
NAT_pdraw_480:
	rrca
NAT_pdraw_481:
	jp nc,pd_j6
NAT_pdraw_482:
	ld a,b
NAT_pdraw_483:
	and 2
NAT_pdraw_484:
	ld a,e
NAT_pdraw_485:
	jp nz,pd_j7
NAT_pdraw_486:
	add a,2
NAT_pdraw_487:
	inc (hl)
pd_j7:
NAT_pdraw_489:
	dec c
NAT_pdraw_490:
	add a,8
NAT_pdraw_491:
	jp pd_j8
pd_j6:
NAT_pdraw_493:
	inc (hl)
NAT_pdraw_494:
	ld a,e
NAT_pdraw_495:
	add a,6
NAT_pdraw_496:
	ld e,a
NAT_pdraw_497:
	ld a,b
NAT_pdraw_498:
	and 2
NAT_pdraw_499:
	ld a,e
NAT_pdraw_500:
	jp nz,pd_j8
NAT_pdraw_501:
	add a,2
NAT_pdraw_502:
	jp pd_j9
pd_j8:
NAT_pdraw_504:
	ld e,a
NAT_pdraw_505:
	ld a,(pd_x1)
NAT_pdraw_506:
	rrca
NAT_pdraw_507:
	ld a,e
NAT_pdraw_508:
	jp nc,pd_j9
NAT_pdraw_509:
	add a,2
NAT_pdraw_510:
	add a,c
pd_j9:
NAT_pdraw_512:
	call Z_9E6F
NAT_pdraw_513:
	jp Z_B01C
pd_pose:
NAT_pdraw_515:
	ld hl,(z80_ix)
NAT_pdraw_516:
	dec hl
NAT_pdraw_517:
	dec hl
NAT_pdraw_518:
	ld e,(hl)
NAT_pdraw_519:
	ld a,e
NAT_pdraw_520:
	ld (pd_m2),a
NAT_pdraw_521:
	inc hl
NAT_pdraw_522:
	ld b,(hl)
NAT_pdraw_523:
	ld a,b
NAT_pdraw_524:
	ld (pd_px),a
NAT_pdraw_525:
	inc hl
NAT_pdraw_526:
	ld a,(hl)
NAT_pdraw_527:
	ld (pd_x0),a
NAT_pdraw_528:
	inc hl
NAT_pdraw_529:
	ld a,(hl)
NAT_pdraw_530:
	ld (pd_x1),a
NAT_pdraw_531:
	ret
pd_ix6:
NAT_pdraw_533:
	ld hl,(z80_ix)
NAT_pdraw_534:
	inc hl
NAT_pdraw_535:
	inc hl
NAT_pdraw_536:
	inc hl
NAT_pdraw_537:
	inc hl
NAT_pdraw_538:
	inc hl
NAT_pdraw_539:
	inc hl
NAT_pdraw_540:
	ret
pd_b3c:
NAT_pdraw_542:
	ld d,a
NAT_pdraw_543:
	ld a,b
NAT_pdraw_544:
	and 8
NAT_pdraw_545:
	ld a,d
NAT_pdraw_546:
	ret z
NAT_pdraw_547:
	add a,0x0C
NAT_pdraw_548:
	ret
pd_nb1c:
NAT_pdraw_550:
	ld d,a
NAT_pdraw_551:
	ld a,b
NAT_pdraw_552:
	and 2
NAT_pdraw_553:
	ld a,d
NAT_pdraw_554:
	ret nz
NAT_pdraw_555:
	add a,0x0C
NAT_pdraw_556:
	ret
pd_side:
NAT_pdraw_558:
	ld d,a
NAT_pdraw_559:
	ld a,(pd_x1)
NAT_pdraw_560:
	rrca
NAT_pdraw_561:
	ld a,d
NAT_pdraw_562:
	ret nc
NAT_pdraw_563:
	inc a
NAT_pdraw_564:
	ret
pd_blit:
NAT_pdraw_566:
	ld (0x3300),hl
NAT_pdraw_567:
	call Z_9E6F
NAT_pdraw_568:
	jp Z_B01C
Z_9E6F:
NAT_pdraw_570:
	add a,a
NAT_pdraw_571:
	ld l,a
NAT_pdraw_572:
	ld h,0
NAT_pdraw_573:
	ld de,0x7760
NAT_pdraw_574:
	add hl,de
NAT_pdraw_575:
	ld e,(hl)
NAT_pdraw_576:
	inc hl
NAT_pdraw_577:
	ld d,(hl)
NAT_pdraw_578:
	ld hl,0x415A
NAT_pdraw_579:
	add hl,de
NAT_pdraw_580:
	ld (0x3302),hl
NAT_pdraw_581:
	ret
pd_e:
NAT_pdraw_583:
	db 0
pd_fr:
NAT_pdraw_585:
	db 0
pd_px:
NAT_pdraw_587:
	db 0
pd_x0:
NAT_pdraw_589:
	db 0
pd_x1:
NAT_pdraw_591:
	db 0
pd_m2:
NAT_pdraw_593:
	db 0
Z_94B0:
NAT_sched_1:
	ld hl,0x3C1E
NAT_sched_2:
	ld a,0x53
NAT_sched_3:
	ld de,Z_84D3
NAT_sched_4:
	call sc_put
NAT_sched_5:
	ld a,(0x93EB)
NAT_sched_6:
	and 5
NAT_sched_7:
	jp nz,sc_1
NAT_sched_8:
	ld a,(0x93F3)
NAT_sched_9:
	ld de,Z_84D6
NAT_sched_10:
	call sc_put
sc_1:
NAT_sched_12:
	ld a,(0x940D)
NAT_sched_13:
	ld de,Z_9599
NAT_sched_14:
	call sc_put
NAT_sched_15:
	ld a,(0x9427)
NAT_sched_16:
	ld de,Z_958F
NAT_sched_17:
	call sc_put
NAT_sched_18:
	ld (hl),0
NAT_sched_19:
	ld b,1
sc_pass:
NAT_sched_21:
	ld hl,0x3C1E
sc_cmp:
NAT_sched_23:
	ld a,(hl)
NAT_sched_24:
	and a
NAT_sched_25:
	jp z,sc_next
NAT_sched_26:
	ld d,a
NAT_sched_27:
	push hl
NAT_sched_28:
	inc hl
NAT_sched_29:
	inc hl
NAT_sched_30:
	inc hl
NAT_sched_31:
	ld c,(hl)
NAT_sched_32:
	pop hl
NAT_sched_33:
	cp c
NAT_sched_34:
	jp z,sc_skip
NAT_sched_35:
	jp c,sc_skip
NAT_sched_36:
	ld a,c
NAT_sched_37:
	and a
NAT_sched_38:
	jp z,sc_next
NAT_sched_39:
	ld (hl),c
NAT_sched_40:
	inc hl
NAT_sched_41:
	ld e,(hl)
NAT_sched_42:
	inc hl
NAT_sched_43:
	ld c,(hl)
NAT_sched_44:
	inc hl
NAT_sched_45:
	ld (hl),d
NAT_sched_46:
	inc hl
NAT_sched_47:
	ld a,(hl)
NAT_sched_48:
	ld (hl),e
NAT_sched_49:
	inc hl
NAT_sched_50:
	ld d,(hl)
NAT_sched_51:
	ld (hl),c
NAT_sched_52:
	dec hl
NAT_sched_53:
	dec hl
NAT_sched_54:
	dec hl
NAT_sched_55:
	ld (hl),d
NAT_sched_56:
	dec hl
NAT_sched_57:
	ld (hl),a
NAT_sched_58:
	inc hl
NAT_sched_59:
	inc hl
NAT_sched_60:
	inc b
NAT_sched_61:
	jp sc_cmp
sc_skip:
NAT_sched_63:
	inc hl
NAT_sched_64:
	inc hl
NAT_sched_65:
	inc hl
NAT_sched_66:
	jp sc_cmp
sc_next:
NAT_sched_68:
	dec b
NAT_sched_69:
	jp nz,sc_pass
NAT_sched_70:
	ld hl,0x3C1E
sc_call:
NAT_sched_72:
	ld a,(hl)
NAT_sched_73:
	and a
NAT_sched_74:
	ret z
NAT_sched_75:
	inc hl
NAT_sched_76:
	ld e,(hl)
NAT_sched_77:
	inc hl
NAT_sched_78:
	ld d,(hl)
NAT_sched_79:
	inc hl
NAT_sched_80:
	push hl
NAT_sched_81:
	ex de,hl
NAT_sched_82:
	call sc_jp
NAT_sched_83:
	pop hl
NAT_sched_84:
	jp sc_call
sc_jp:
NAT_sched_86:
	jp (hl)
sc_put:
NAT_sched_88:
	ld (hl),a
NAT_sched_89:
	inc hl
NAT_sched_90:
	ld (hl),e
NAT_sched_91:
	inc hl
NAT_sched_92:
	ld (hl),d
NAT_sched_93:
	inc hl
NAT_sched_94:
	ret
Z_9543:
NAT_sched_96:
	call Z_AC4A
NAT_sched_97:
	ld hl,0x9409
NAT_sched_98:
	ld a,(0xAC4D)
NAT_sched_99:
	call sc_stick
NAT_sched_100:
	ld a,(0x93EA)
NAT_sched_101:
	and a
NAT_sched_102:
	call nz,Z_84DF
NAT_sched_103:
	ld hl,0x9423
NAT_sched_104:
	ld a,(0xAC4E)
NAT_sched_105:
	call sc_stick
NAT_sched_106:
	ld a,(0x93D6)
NAT_sched_107:
	and a
NAT_sched_108:
	ret z
NAT_sched_109:
	ld hl,0x9409
NAT_sched_110:
	ld a,(hl)
NAT_sched_111:
	and 0xF0
NAT_sched_112:
	ld (hl),a
NAT_sched_113:
	ld hl,0x9423
NAT_sched_114:
	ld a,(hl)
NAT_sched_115:
	and 0xF0
NAT_sched_116:
	ld (hl),a
NAT_sched_117:
	ret
sc_stick:
NAT_sched_119:
	ld c,a
NAT_sched_120:
	and 0x10
NAT_sched_121:
	ld a,c
NAT_sched_122:
	jp z,sc_s1
NAT_sched_123:
	or 0x80
NAT_sched_124:
	ld c,a
NAT_sched_125:
	ld a,(hl)
NAT_sched_126:
	and 0x80
NAT_sched_127:
	ld a,c
NAT_sched_128:
	jp z,sc_s1
NAT_sched_129:
	and 0xEF
sc_s1:
NAT_sched_131:
	ld (hl),a
NAT_sched_132:
	ret
Z_98B3:
NAT_move_1:
	ld hl,(z80_iy)
NAT_move_2:
	inc hl
NAT_move_3:
	inc hl
NAT_move_4:
	ld e,(hl)
NAT_move_5:
	inc hl
NAT_move_6:
	ld d,(hl)
NAT_move_7:
	ld bc,0
NAT_move_8:
	ld hl,(z80_ix)
NAT_move_9:
	dec hl
NAT_move_10:
	ld l,(hl)
NAT_move_11:
	ld a,l
NAT_move_12:
	and 1
NAT_move_13:
	jp z,mv_p1
NAT_move_14:
	ld c,0xFE
NAT_move_15:
	ld a,l
NAT_move_16:
	and 2
NAT_move_17:
	jp z,mv_p1
NAT_move_18:
	ld c,2
mv_p1:
NAT_move_20:
	ld a,l
NAT_move_21:
	and 4
NAT_move_22:
	jp z,Z_98F7
NAT_move_23:
	ld b,0xFF
NAT_move_24:
	ld a,l
NAT_move_25:
	and 8
NAT_move_26:
	jp z,Z_98F7
NAT_move_27:
	ld b,1
NAT_move_28:
	jp Z_98F7
Z_98D9:
NAT_move_30:
	ld hl,(z80_iy)
NAT_move_31:
	inc hl
NAT_move_32:
	inc hl
NAT_move_33:
	ld e,(hl)
NAT_move_34:
	inc hl
NAT_move_35:
	ld d,(hl)
NAT_move_36:
	ld hl,(z80_ix)
NAT_move_37:
	inc hl
NAT_move_38:
	inc hl
NAT_move_39:
	ld a,(hl)
NAT_move_40:
	inc hl
NAT_move_41:
	ld h,(hl)
NAT_move_42:
	ld l,a
NAT_move_43:
	ld a,h
NAT_move_44:
	sub d
NAT_move_45:
	jp nc,mv_b1
NAT_move_46:
	cpl
NAT_move_47:
	inc a
mv_b1:
NAT_move_49:
	cp 6
NAT_move_50:
	ret nc
NAT_move_51:
	ld a,l
NAT_move_52:
	sub e
NAT_move_53:
	jp nc,mv_b2
NAT_move_54:
	cpl
NAT_move_55:
	inc a
mv_b2:
NAT_move_57:
	cp 3
NAT_move_58:
	ret nc
Z_98F7:
NAT_move_60:
	ld hl,(z80_iy)
NAT_move_61:
	inc hl
NAT_move_62:
	inc hl
NAT_move_63:
	ld a,e
NAT_move_64:
	add a,c
NAT_move_65:
	ld (hl),a
NAT_move_66:
	inc hl
NAT_move_67:
	ld a,d
NAT_move_68:
	add a,b
NAT_move_69:
	ld (hl),a
NAT_move_70:
	inc hl
NAT_move_71:
	inc hl
NAT_move_72:
	ld (hl),a
NAT_move_73:
	ld e,2
NAT_move_74:
	ld hl,(z80_iy)
NAT_move_75:
	ld a,(hl)
NAT_move_76:
	rrca
NAT_move_77:
	jp c,Z_9919
NAT_move_78:
	dec hl
NAT_move_79:
	dec hl
NAT_move_80:
	ld a,(hl)
NAT_move_81:
	and 0x1F
NAT_move_82:
	jp nz,Z_9919
NAT_move_83:
	inc hl
NAT_move_84:
	ld a,(hl)
NAT_move_85:
	dec hl
NAT_move_86:
	ld (hl),a
Z_9919:
NAT_move_88:
	ld a,(0x9400)
NAT_move_89:
	and a
NAT_move_90:
	ret nz
NAT_move_91:
	ld hl,(z80_ix)
NAT_move_92:
	inc hl
NAT_move_93:
	ld a,(hl)
NAT_move_94:
	rrca
NAT_move_95:
	jp nc,mv_e1
NAT_move_96:
	ld a,e
NAT_move_97:
	or 0x80
NAT_move_98:
	ld e,a
mv_e1:
NAT_move_100:
	ld a,e
NAT_move_101:
	ld (0x9400),a
NAT_move_102:
	ld a,0x14
NAT_move_103:
	ld (0x9451),a
NAT_move_104:
	ld a,e
NAT_move_105:
	and 0x7F
NAT_move_106:
	cp 2
NAT_move_107:
	ret nz
NAT_move_108:
	ld hl,(z80_ix)
NAT_move_109:
	ld de,0x0B
NAT_move_110:
	add hl,de
NAT_move_111:
	ld a,(hl)
NAT_move_112:
	cp 5
NAT_move_113:
	ret z
NAT_move_114:
	inc (hl)
NAT_move_115:
	ld hl,(z80_ix)
NAT_move_116:
	push hl
NAT_move_117:
	ld hl,(z80_iy)
NAT_move_118:
	push hl
NAT_move_119:
	call Z_9FC0
NAT_move_120:
	pop hl
NAT_move_121:
	ld (z80_iy),hl
NAT_move_122:
	pop hl
NAT_move_123:
	ld (z80_ix),hl
NAT_move_124:
	ret
Z_994A:
NAT_move_126:
	ld hl,(z80_ix)
NAT_move_127:
	inc hl
NAT_move_128:
	ld a,(hl)
NAT_move_129:
	and 0x0E
NAT_move_130:
	ret nz
NAT_move_131:
	dec hl
NAT_move_132:
	dec hl
NAT_move_133:
	dec hl
NAT_move_134:
	ld a,(hl)
NAT_move_135:
	and 0x0F
NAT_move_136:
	ret z
NAT_move_137:
	ld d,a
NAT_move_138:
	inc hl
NAT_move_139:
	ld c,(hl)
NAT_move_140:
	ld a,d
NAT_move_141:
	and 4
NAT_move_142:
	jp z,mv_s8c
NAT_move_143:
	ld a,c
NAT_move_144:
	rrca
NAT_move_145:
	jp nc,mv_s70
NAT_move_146:
	ld a,d
	jp	NAT_move_147	; мост в следующий кусок
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
NAT_move_147:
	and 8
NAT_move_148:
	jp z,mv_sae
NAT_move_149:
	jp mv_s9d
mv_s70:
NAT_move_151:
	ld a,d
NAT_move_152:
	and 8
NAT_move_153:
	jp nz,mv_s80
NAT_move_154:
	ld a,c
NAT_move_155:
	and 8
NAT_move_156:
	ret z
NAT_move_157:
	jp mv_s77
mv_s80:
NAT_move_159:
	ld a,c
NAT_move_160:
	and 8
NAT_move_161:
	ret nz
NAT_move_162:
	jp mv_s83
mv_s8c:
NAT_move_164:
	ld a,c
NAT_move_165:
	and 4
NAT_move_166:
	jp z,mv_s96
NAT_move_167:
	ld a,d
NAT_move_168:
	and 2
NAT_move_169:
	jp z,mv_s83
NAT_move_170:
	jp mv_s77
mv_s96:
NAT_move_172:
	ld a,d
NAT_move_173:
	and 2
NAT_move_174:
	jp nz,mv_sab
NAT_move_175:
	ld a,c
NAT_move_176:
	and 2
NAT_move_177:
	ret z
NAT_move_178:
	jp mv_s9d
mv_sab:
NAT_move_180:
	ld a,c
NAT_move_181:
	and 2
NAT_move_182:
	ret nz
NAT_move_183:
	jp mv_sae
mv_s77:
NAT_move_185:
	ld (hl),3
NAT_move_186:
	inc hl
NAT_move_187:
	jp mv_r6
mv_s83:
NAT_move_189:
	ld (hl),1
NAT_move_190:
	inc hl
NAT_move_191:
	jp mv_r6
mv_s9d:
NAT_move_193:
	ld (hl),0x0C
NAT_move_194:
	inc hl
NAT_move_195:
	inc hl
NAT_move_196:
	ld a,(hl)
NAT_move_197:
	dec hl
NAT_move_198:
	rrca
NAT_move_199:
	ret nc
NAT_move_200:
	jp mv_r6
mv_sae:
NAT_move_202:
	ld (hl),4
NAT_move_203:
	inc hl
NAT_move_204:
	inc hl
NAT_move_205:
	ld a,(hl)
NAT_move_206:
	dec hl
NAT_move_207:
	rrca
NAT_move_208:
	ret c
mv_r6:
NAT_move_210:
	ld a,(hl)
NAT_move_211:
	and 0xBF
NAT_move_212:
	ld (hl),a
NAT_move_213:
	ret
Z_99BC:
NAT_move_215:
	ld a,(0x93D6)
NAT_move_216:
	ld c,1
NAT_move_217:
	and a
NAT_move_218:
	jp nz,mv_vf2
NAT_move_219:
	ld c,3
NAT_move_220:
	ld hl,(z80_ix)
NAT_move_221:
	inc hl
NAT_move_222:
	ld b,(hl)
NAT_move_223:
	inc hl
NAT_move_224:
	ld a,(hl)
NAT_move_225:
	inc hl
NAT_move_226:
	ld h,(hl)
NAT_move_227:
	ld l,a
NAT_move_228:
	cp 0x48
NAT_move_229:
	jp c,mv_vf2
NAT_move_230:
	cp 0x66
NAT_move_231:
	jp nc,mv_vf2
NAT_move_232:
	ld a,b
NAT_move_233:
	rrca
NAT_move_234:
	ld a,h
NAT_move_235:
	jp nc,mv_vfd
NAT_move_236:
	cp 0x52
NAT_move_237:
	jp c,mv_vf2
NAT_move_238:
	cp 0x58
NAT_move_239:
	jp nc,mv_vf0
NAT_move_240:
	ld a,l
NAT_move_241:
	cp 0x4C
NAT_move_242:
	jp nc,mv_vf7
NAT_move_243:
	ld a,h
NAT_move_244:
	cp 0x56
NAT_move_245:
	jp c,mv_vf2
NAT_move_246:
	jp mv_vf0
mv_vf7:
NAT_move_248:
	cp 0x5E
NAT_move_249:
	jp c,mv_vf0
NAT_move_250:
	jp mv_vf2
mv_vfd:
NAT_move_252:
	cp 0x24
NAT_move_253:
	jp nc,mv_vf2
NAT_move_254:
	cp 0x1E
NAT_move_255:
	jp c,mv_vf0
NAT_move_256:
	ld a,l
NAT_move_257:
	cp 0x4C
NAT_move_258:
	jp nc,mv_vf7
NAT_move_259:
	ld a,h
NAT_move_260:
	cp 0x22
NAT_move_261:
	jp c,mv_vf0
NAT_move_262:
	jp mv_vf2
mv_vf0:
NAT_move_264:
	ld a,c
NAT_move_265:
	and 0xFE
NAT_move_266:
	ld c,a
mv_vf2:
NAT_move_268:
	ld a,c
NAT_move_269:
	ld (0x93D9),a
NAT_move_270:
	ret
Z_9A1B:
NAT_flight_1:
	ld hl,0x93F5
NAT_flight_2:
	ld (z80_ix),hl
NAT_flight_3:
	ld a,(hl)
NAT_flight_4:
	rrca
NAT_flight_5:
	jp nc,fl_new
NAT_flight_6:
	ld a,(hl)
NAT_flight_7:
	and 4
NAT_flight_8:
	jp z,fl_res
NAT_flight_9:
	ld a,(0x93EB)
NAT_flight_10:
	and 0x80
NAT_flight_11:
	ld a,1
NAT_flight_12:
	jp nz,fl_d1
NAT_flight_13:
	ld a,0xFF
fl_d1:
NAT_flight_15:
	ld hl,0x93F4
NAT_flight_16:
	add a,(hl)
NAT_flight_17:
	ld (hl),a
NAT_flight_18:
	ld (0x93F2),a
NAT_flight_19:
	ld a,(0x93F1)
NAT_flight_20:
	add a,4
NAT_flight_21:
	ld (0x93F1),a
NAT_flight_22:
	ld hl,0x93F5
NAT_flight_23:
	ld a,(hl)
NAT_flight_24:
	or 2
NAT_flight_25:
	ld (hl),a
NAT_flight_26:
	ret
fl_res:
NAT_flight_28:
	ld a,(0x93FC)
NAT_flight_29:
	ld e,a
NAT_flight_30:
	ld a,(0x93FD)
NAT_flight_31:
	ld d,a
NAT_flight_32:
	ld hl,(0x93F8)
NAT_flight_33:
	ld a,(0x93FB)
NAT_flight_34:
	ld b,a
NAT_flight_35:
	ld a,(0x93FA)
NAT_flight_36:
	ld c,a
NAT_flight_37:
	call fl_step
NAT_flight_38:
	jp fl_hgt
fl_new:
NAT_flight_40:
	ld (hl),1
NAT_flight_41:
	ld a,1
NAT_flight_42:
	ld (0x93F0),a
NAT_flight_43:
	ld hl,D_9B69
NAT_flight_44:
	ld (0x93ED),hl
NAT_flight_45:
	ld hl,(0x93F3)
NAT_flight_46:
	ld a,(0x93F1)
NAT_flight_47:
	ld (0x93F6),a
NAT_flight_48:
	sub 0x1E
NAT_flight_49:
	jp nc,fl_n1
NAT_flight_50:
	cpl
NAT_flight_51:
	inc a
NAT_flight_52:
	ld b,a
NAT_flight_53:
	ld a,(0x93F5)
NAT_flight_54:
	or 0x80
NAT_flight_55:
	ld (0x93F5),a
NAT_flight_56:
	ld a,b
fl_n1:
NAT_flight_58:
	ld (0x93F7),a
NAT_flight_59:
	ld de,0x0554
NAT_flight_60:
	ld a,(0x93EB)
NAT_flight_61:
	and 0x80
NAT_flight_62:
	jp z,fl_n2
NAT_flight_63:
	ld d,0x39
fl_n2:
NAT_flight_65:
	ld a,h
NAT_flight_66:
	or a
NAT_flight_67:
	rra
NAT_flight_68:
	ld h,a
NAT_flight_69:
	ld a,d
NAT_flight_70:
	sub h
NAT_flight_71:
	ld d,2
NAT_flight_72:
	jp nc,fl_n3
NAT_flight_73:
	cpl
NAT_flight_74:
	inc a
NAT_flight_75:
	ld d,0xFE
fl_n3:
NAT_flight_77:
	ld b,a
NAT_flight_78:
	ld a,e
NAT_flight_79:
	sub l
NAT_flight_80:
	ld e,2
NAT_flight_81:
	jp nc,fl_n4
NAT_flight_82:
	cpl
NAT_flight_83:
	inc a
NAT_flight_84:
	ld e,0xFE
fl_n4:
NAT_flight_86:
	or a
NAT_flight_87:
	rra
NAT_flight_88:
	ld c,a
NAT_flight_89:
	ld a,b
NAT_flight_90:
	cp c
NAT_flight_91:
	jp nc,fl_n5
NAT_flight_92:
	ld a,c
fl_n5:
NAT_flight_94:
	ld (0x93EF),a
NAT_flight_95:
	or a
NAT_flight_96:
	rra
NAT_flight_97:
	ld (0x93EC),a
NAT_flight_98:
	call fl_setup
fl_hgt:
NAT_flight_100:
	ld hl,(0x93ED)
NAT_flight_101:
	ld c,(hl)
NAT_flight_102:
	ld a,(0x93EC)
NAT_flight_103:
	and a
NAT_flight_104:
	jp z,fl_h1
NAT_flight_105:
	dec a
NAT_flight_106:
	ld (0x93EC),a
NAT_flight_107:
	inc hl
NAT_flight_108:
	jp fl_h2
fl_h1:
NAT_flight_110:
	dec hl
fl_h2:
NAT_flight_112:
	ld (0x93ED),hl
NAT_flight_113:
	ld a,(0x93F4)
NAT_flight_114:
	ld (0x93F2),a
NAT_flight_115:
	push bc
NAT_flight_116:
	ld a,(0x93F0)
NAT_flight_117:
	ld c,a
NAT_flight_118:
	inc a
NAT_flight_119:
	ld (0x93F0),a
NAT_flight_120:
	ld a,(0x93F7)
NAT_flight_121:
	ld l,a
NAT_flight_122:
	ld h,0
NAT_flight_123:
	ld b,h
NAT_flight_124:
	call Z_398C
NAT_flight_125:
	ld b,0
NAT_flight_126:
	ld a,(0x93EF)
NAT_flight_127:
	ld c,a
NAT_flight_128:
	call Z_39A3
NAT_flight_129:
	ld a,(0x93F5)
NAT_flight_130:
	and 0x80
NAT_flight_131:
	jp z,fl_h3
NAT_flight_132:
	ld a,l
NAT_flight_133:
	cpl
NAT_flight_134:
	inc a
NAT_flight_135:
	ld l,a
fl_h3:
NAT_flight_137:
	ld a,(0x93F6)
NAT_flight_138:
	sub l
NAT_flight_139:
	pop bc
NAT_flight_140:
	sub c
NAT_flight_141:
	ld (0x93F1),a
NAT_flight_142:
	ret
fl_setup:
NAT_flight_144:
	ld a,c
NAT_flight_145:
	cp b
NAT_flight_146:
	jp nc,fl_s2
NAT_flight_147:
	ld l,c
NAT_flight_148:
	ld a,e
NAT_flight_149:
	ld (0x93FE),a
NAT_flight_150:
	ld a,d
NAT_flight_151:
	ld (0x93FF),a
NAT_flight_152:
	ld e,0
NAT_flight_153:
	jp fl_s3
fl_s2:
NAT_flight_155:
	or c
NAT_flight_156:
	jp z,fl_end
NAT_flight_157:
	ld l,b
NAT_flight_158:
	ld b,c
NAT_flight_159:
	ld a,e
NAT_flight_160:
	ld (0x93FE),a
NAT_flight_161:
	ld a,d
NAT_flight_162:
	ld (0x93FF),a
NAT_flight_163:
	ld d,0
fl_s3:
NAT_flight_165:
	ld h,b
NAT_flight_166:
	ld a,b
NAT_flight_167:
	or a
NAT_flight_168:
	rra
fl_step:
NAT_flight_170:
	add a,l
NAT_flight_171:
	jp c,fl_dg
NAT_flight_172:
	cp h
NAT_flight_173:
	jp nc,fl_dg
NAT_flight_174:
	ld c,a
NAT_flight_175:
	ld a,d
NAT_flight_176:
	ld (fl_dy),a
NAT_flight_177:
	ld a,e
NAT_flight_178:
	ld (fl_dx),a
NAT_flight_179:
	jp fl_mv
fl_dg:
NAT_flight_181:
	sub h
NAT_flight_182:
	ld c,a
NAT_flight_183:
	ld a,(0x93FF)
NAT_flight_184:
	ld (fl_dy),a
NAT_flight_185:
	ld a,(0x93FE)
NAT_flight_186:
	ld (fl_dx),a
fl_mv:
NAT_flight_188:
	push hl
NAT_flight_189:
	ld hl,0x93F4
NAT_flight_190:
	ld a,(fl_dy)
NAT_flight_191:
	add a,(hl)
NAT_flight_192:
	ld (hl),a
NAT_flight_193:
	dec hl
NAT_flight_194:
	ld a,(fl_dx)
NAT_flight_195:
	add a,(hl)
NAT_flight_196:
	ld (hl),a
NAT_flight_197:
	pop hl
NAT_flight_198:
	dec b
NAT_flight_199:
	ld a,l
NAT_flight_200:
	ld (0x93F8),a
NAT_flight_201:
	ld a,h
NAT_flight_202:
	ld (0x93F9),a
NAT_flight_203:
	ld a,c
NAT_flight_204:
	ld (0x93FA),a
NAT_flight_205:
	ld a,b
NAT_flight_206:
	ld (0x93FB),a
NAT_flight_207:
	ld a,e
NAT_flight_208:
	ld (0x93FC),a
NAT_flight_209:
	ld a,d
NAT_flight_210:
	ld (0x93FD),a
NAT_flight_211:
	ld a,b
NAT_flight_212:
	or a
NAT_flight_213:
	ret nz
fl_end:
NAT_flight_215:
	ld hl,0x93F5
NAT_flight_216:
	ld a,(hl)
NAT_flight_217:
	or 4
NAT_flight_218:
	ld (hl),a
NAT_flight_219:
	ret
Z_9BF6:
NAT_flight_221:
	ld hl,0x93F5
NAT_flight_222:
	ld (z80_ix),hl
NAT_flight_223:
	ld a,(hl)
NAT_flight_224:
	rrca
NAT_flight_225:
	jp c,fl_r2
NAT_flight_226:
	ld (hl),0x41
NAT_flight_227:
	call Z_386E
NAT_flight_228:
	push af
NAT_flight_229:
	call Z_386E
NAT_flight_230:
	and 3
NAT_flight_231:
	ld hl,D_9B89
NAT_flight_232:
	jp z,fl_r1
NAT_flight_233:
	ld hl,D_9B9F
NAT_flight_234:
	dec a
NAT_flight_235:
	jp z,fl_r1
NAT_flight_236:
	ld hl,D_9BBB
NAT_flight_237:
	dec a
NAT_flight_238:
	jp z,fl_r1
NAT_flight_239:
	ld hl,D_9BD7
fl_r1:
NAT_flight_241:
	ld (0x93ED),hl
NAT_flight_242:
	pop af
NAT_flight_243:
	and 3
NAT_flight_244:
	jp z,fl_r2
NAT_flight_245:
	ld hl,0x93F5
NAT_flight_246:
	ld b,a
NAT_flight_247:
	ld a,(hl)
NAT_flight_248:
	and 0xBF
NAT_flight_249:
	ld (hl),a
NAT_flight_250:
	ld a,b
NAT_flight_251:
	rrca
NAT_flight_252:
	jp nc,fl_r2
NAT_flight_253:
	ld a,(hl)
NAT_flight_254:
	or 0x80
NAT_flight_255:
	ld (hl),a
fl_r2:
NAT_flight_257:
	ld hl,(0x93ED)
NAT_flight_258:
	ld a,(0x93D6)
NAT_flight_259:
	and a
NAT_flight_260:
	jp nz,fl_r3
NAT_flight_261:
	ld a,(0x93F5)
NAT_flight_262:
	and 0x40
NAT_flight_263:
	jp nz,fl_r4
fl_r3:
NAT_flight_265:
	ld a,(0x93F5)
NAT_flight_266:
	and 0x80
NAT_flight_267:
	ld a,(hl)
NAT_flight_268:
	jp z,fl_r5
NAT_flight_269:
	cpl
NAT_flight_270:
	inc a
fl_r5:
NAT_flight_272:
	push hl
NAT_flight_273:
	ld hl,0x93F3
NAT_flight_274:
	add a,(hl)
NAT_flight_275:
	ld (hl),a
NAT_flight_276:
	pop hl
fl_r4:
NAT_flight_278:
	inc hl
NAT_flight_279:
	ld a,(0x93EB)
NAT_flight_280:
	and 0x80
NAT_flight_281:
	ld a,(hl)
NAT_flight_282:
	jp z,fl_r6
NAT_flight_283:
	cpl
NAT_flight_284:
	inc a
fl_r6:
NAT_flight_286:
	push hl
NAT_flight_287:
	ld hl,0x93F4
NAT_flight_288:
	add a,(hl)
NAT_flight_289:
	ld (hl),a
NAT_flight_290:
	ld (0x93F2),a
NAT_flight_291:
	pop hl
NAT_flight_292:
	inc hl
NAT_flight_293:
	ld a,(hl)
NAT_flight_294:
	push hl
NAT_flight_295:
	ld hl,0x93F1
NAT_flight_296:
	add a,(hl)
NAT_flight_297:
	ld (hl),a
NAT_flight_298:
	pop hl
NAT_flight_299:
	inc hl
NAT_flight_300:
	ld (0x93ED),hl
NAT_flight_301:
	ld a,(hl)
NAT_flight_302:
	inc a
NAT_flight_303:
	ret nz
NAT_flight_304:
	ld a,(0x93F5)
NAT_flight_305:
	or 2
NAT_flight_306:
	ld (0x93F5),a
NAT_flight_307:
	ret
fl_dy:
NAT_flight_309:
	db 0
fl_dx:
NAT_flight_311:
	db 0
Z_9F48:
	jp 0x02CE	; 9F48 C3 CE 02
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
	jp	Z_A185	; мост в следующий кусок
	org	0xA06F
D_A06F:
Z_A06F:
	db	0x83, 0xF8, 0xF5, 0xC5, 0xD5, 0xE5, 0xCD, 0xEB, 0xD8, 0xE1, 0xD1, 0xC1, 0xF1, 0xC9, 0xD8, 0xE1	; A06F
	org	0xA07F
D_A07F:
Z_A07F:
	db	0xD1, 0xC1, 0xF1, 0xC9, 0xBE, 0xA0, 0x18, 0xF6, 0xE5, 0xD5, 0x6F, 0x26, 0x00	; A07F
	org	0xA08C
Z_A185:
	ret	; A185 C9
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
	jp	Z_A1AD	; мост в следующий кусок
	org	0xA0A4
D_A0A4:
Z_A0A4:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; A0A4
	org	0xA0AD
D_A0AD:
Z_A0AD:
	db	0xC3, 0x5F, 0xA7	; A0AD
	org	0xA0B0
Z_A1AD:
	jp c,il_KC5	; A1AD CB 7F
	ld (il_a),a
	and 0x80
	ld a,(il_a)
	jp il_KD6
il_KC5:
	ld (il_a),a
	and 0x80
	scf
	ld a,(il_a)
il_KD6:
Z_A1AF:
	jp z,Z_A1BD	; A1AF 28 0C
Z_A1B1:
	ld hl,0x0806	; A1B1 21 06 08
	jp	Z_A1B4	; мост в следующий кусок
	org	0xA133
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
	jp	Z_A1D9	; мост в следующий кусок
	org	0xA15C
D_A15C:
Z_A15C:
	db	0x00, 0x00, 0x00, 0x00	; A15C
	org	0xA160
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
	jp	Z_A210	; мост в следующий кусок
	org	0xA1A4
D_A1A4:
Z_A1A4:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; A1A4
	org	0xA1AA
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
	jp	Z_A462	; мост в следующий кусок
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
	call CROWD_TICK	; A502 CD 1A 76
Z_A505:
	and 0x0F	; A505 E6 0F
Z_A507:
	cp 0x04	; A507 FE 04
Z_A509:
	ret nz	; A509 C0
Z_A50A:
	ld a,(D_9451)	; A50A 3A 51 94
	jp	Z_A50D	; мост в следующий кусок
	org	0xA494
D_A494:
Z_A494:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; A494
	org	0xA49F
D_A49F:
Z_A49F:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; A49F
	org	0xA4A8
Z_A50D:
	jp c,il_KC7	; A50D CB 47
	ld (il_a),a
	and 0x01
	ld a,(il_a)
	jp il_KD8
il_KC7:
	ld (il_a),a
	and 0x01
	scf
	ld a,(il_a)
il_KD8:
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
	jp	Z_A53A	; мост в следующий кусок
	org	0xA4DB
D_A4DB:
Z_A4DB:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC9	; A4DB
	org	0xA4E7
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
	jp	Z_A624	; мост в следующий кусок
	org	0xA535
D_A535:
Z_A535:
	db	0x00, 0x00, 0x00, 0x00, 0x00	; A535
	org	0xA53A
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
	jp c,il_KC9	; A843 CB 7F
	ld (il_a),a
	and 0x80
	ld a,(il_a)
	jp il_KD10
il_KC9:
	ld (il_a),a
	and 0x80
	scf
	ld a,(il_a)
il_KD10:
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
	call RING_REPLAY	; A859 CD 7C 76
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
Z_A878:
	jp c,il_KC11	; A878 CB 7F
	ld (il_a),a
	and 0x80
	ld a,(il_a)
	jp il_KD12
il_KC11:
	ld (il_a),a
	and 0x80
	scf
	ld a,(il_a)
il_KD12:
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
	call REPLAY_STATE_BEGIN	; A887 CD E7 13
Z_A88A:
	call REPLAY_SCENE	; A88A CD EA 13
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
	call REPLAY_STATE_BEGIN	; A89E CD E7 13
	jp	Z_A8A1	; мост в следующий кусок
	org	0xA759
D_A759:
Z_A759:
	db	0xCD, 0x47, 0xAC, 0xC3, 0x18, 0xA6	; A759
	org	0xA75F
Z_A8A1:
	call REPLAY_SCENE	; A8A1 CD EA 13
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
Z_A8B8:
	ld de,D_93EB	; A8B8 11 EB 93
Z_A8BB:
	ld bc,0x4F	; A8BB 01 4F 00
Z_A8BE:
	call il_ldir	; A8BE ED B0
Z_A8C0:
	call 0x08EB	; A8C0 CD EB 08
Z_A8C3:
	xor a	; A8C3 AF
Z_A8C4:
	ld (D_93D1),a	; A8C4 32 D1 93
Z_A8C7:
	ret	; A8C7 C9
Z_A8C8:
	jp 0x0910	; A8C8 C3 10 09
Z_A8F4:
	jp 0x088F	; A8F4 C3 8F 08
Z_A95E:
	xor a	; A95E AF
Z_A95F:
	ld (D_93D3),a	; A95F 32 D3 93
	jp	Z_A962	; мост в следующий кусок
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
Z_A962:
	jp RING_RESET	; A962 C3 71 76
Z_A969:
	ld a,(D_9400)	; A969 3A 00 94
Z_A96C:
	and a	; A96C A7
Z_A96D:
	ret nz	; A96D C0
Z_A96E:
	jp RING_PUSH	; A96E C3 48 76
Z_A991:
	jp RING_PULL	; A991 C3 8D 76
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
Z_AAD1:
	ex de,hl	; AAD1 EB
Z_AAD2:
	ld bc,0x1E	; AAD2 01 1E 00
	jp	Z_AAD5	; мост в следующий кусок
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
	jp	Z_AB2B	; мост в следующий кусок
	org	0xA965
D_A965:
Z_A965:
	db	0x00, 0x00, 0x00, 0x00	; A965
	org	0xA969
Z_AB2B:
	jp nz,Z_AB83	; AB2B 20 56
Z_AB2D:
	xor a	; AB2D AF
	jp	Z_AB2E	; мост в следующий кусок
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
	jp	Z_AB8C	; мост в следующий кусок
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
Z_AE25:
	ld (D_AE18),a	; AE25 32 18 AE
Z_AE28:
	call Z_AE34	; AE28 CD 34 AE
	jp	Z_AE2B	; мост в следующий кусок
	org	0xAB23
D_AB23:
Z_AB23:
	db	0x0E, 0x00	; AB23
	org	0xAB25
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
Z_AF02:
	rst 0x18	; AF02 DF
Z_AF03:
	jp Z_AEFD	; AF03 18 F8
Z_AF05:
	call Z_37CC	; AF05 CD CC 37
Z_AF08:
	call Z_3811	; AF08 CD 11 38
Z_AF0B:
	jp NATIVE_PADS	; AF0B C3 85 6D
Z_B01C:
	jp 0x01E9	; B01C C3 E9 01
Z_B1F2:
	jp 0x01E6	; B1F2 C3 E6 01
Z_B1FE:
	jp 0x01EF	; B1FE C3 EF 01
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
	org	0xAE3D
D_AE3D:
Z_AE3D:
	db	0x21, 0x0F, 0xAE	; AE3D
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
	org	0xB251
D_B251:
Z_B251:
	db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC9	; B251
