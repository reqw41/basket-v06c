; ============================================================================
;  GLUE: Main initialization and runtime for Basket Master on Vector-06C
;  
;  Memory Map (CPC-style four pens):
;    0000..00FF  RST vectors and BIOS stubs
;    0100..0107  Boot code (DI; LD SP; JP INIT)
;    0200..0EFF  Adapter code (soft VDP, kbd, snd, BIOS stubs)
;    0F00..0FFF  Adapter work RAM
;    1000..1B3F  menu LZ, court tile tail, native helpers and tile cache
;    1B40..1FFF  replay state/ring workspace
;    2000..24FF  shared menu/replay gfx work
;    2500..32FF  CPC court tiles; 3300..3F80 relocated system/HUD/state
;    4000..B497  Game RAM + code + backboard stamp
;    7AE8..7B95  direct CPC-style court colour helpers
;    808A..8411  packed low/high HUD decoration
;    8412..84C9  streaming menu/HUD background helpers
;    84CA..84CF  proven free tail before game entry
;    B258..B2C4  DIRTY_OLD work RAM (permanent; not a code pocket)
;    B2C5..B330  previous-frame sprite metadata; B331..B337 free tail
;    B498..BBFF  staged sprite stream (replay composes from it in place)
;    BC00..BFFF  Stack (SP=C000)
;    C000..DFFF  Active high colour-bit video plane (initial splash)
;    E000..FFFF  Active low colour-bit video plane (initial splash)
;
;  No MSX VDP: every picture is written straight to the two planes.
;    RST 08/10/20/28 once emulated OUT/IN 98h/99h; no game path reaches
;    them now (tools/inventory_softvdp_v06.py), they are bare RETs.
;    RST 18 (0018h) = MSX BIOS OUTDO: the game's own glyph printer.
; ============================================================================

#include "labels_glue.inc"
        org     0x0000

; ============================================================================
;  RST VECTORS at 0000h
; ============================================================================

RST_00:
        ; Do NOT jp BOOT_ENTRY — any stray jump/RST 0 would soft-reboot
        ; and re-LDIR page0 forever. Vector boots at 0100 only.
        ret

        ds      0x0008 - $, 0           ; pad to RST 08

RST_08:
        ret                             ; no VDP

        ds      0x0010 - $, 0           ; pad to RST 10

RST_10:
        ret                             ; no VDP

        ds      0x0018 - $, 0           ; pad to RST 18

RST_18:
        ; MSX BIOS OUTDO - character output (game uses RST 18!)
        ; For now, just ignore - return immediately
        jp      BIOS_OUTDO

        ds      0x0020 - $, 0           ; pad to RST 20

RST_20:
        ret                             ; no VDP

        ds      0x0024 - $, 0           ; pad to INITXT (0024h)

BIOS_0024:
        ; MSX ENASLT (slot select) — no-op success on Vector (flat memory).
        ; Was wrongly wired to INITXT (fills nametable / races title blit).
        ret

        ds      0x0028 - $, 0           ; pad to RST 28

RST_28:
        ret                             ; no VDP

        ds      0x0030 - $, 0           ; pad to RST 30

RST_30:
        ret                             ; unused
        ds      0x0038 - $, 0

RST_38:
        ; Mode 1 interrupt handler
        jp      IRQ_HANDLER

; ============================================================================
;  MSX BIOS STUBS at standard addresses (must be in ascending order!)
; ============================================================================

        ds      0x0051 - $, 0           ; pad to CHSNS

BIOS_0051:
        ; CHSNS - Check keyboard buffer (5768 CALL.P)
        xor     a                       ; Z flag = no char available
        ret

        ds      0x0061 - $, 0           ; pad to CHGET

BIOS_0061:
        ; CHGET - Get character from keyboard (61b7 CALL.PE)
        xor     a                       ; return 0 (no char)
        ret

        ds      0x006C - $, 0           ; pad to CLS

BIOS_006C:
        ; CLS - Clear screen (game calls this)
        jp      BIOS_CLS

        ds      0x0076 - $, 0           ; pad to CHPUT

BIOS_0076:
        ; CHPUT — 1 byte only (0078 is LPTOUT). Text goes through RST 18 / OUTDO.
        ret

        ds      0x0078 - $, 0           ; pad to LPTOUT

BIOS_0078:
        ; LPTOUT - Output to printer (669d CALL.Z)
        ret

        ds      0x0085 - $, 0           ; pad to BEEP

BIOS_0085:
        ; BEEP - Generate beep (576b CALL.P)
        ret

        ds      0x0090 - $, 0           ; pad to GICINI

BIOS_0090:
        ; GICINI - Initialize PSG
        jp      BIOS_GICINI

        ds      0x0093 - $, 0           ; pad to WRTPSG

BIOS_0093:
        ; WRTPSG - Write PSG register
        jp      BIOS_WRTPSG

        ds      0x00A2 - $, 0           ; pad to WSLREG

BIOS_00A2:
        ; WSLREG - Write to VDP status latch (game calls this)
        jp      BIOS_WSLREG

        ds      0x00D5 - $, 0           ; pad to GTSTCK

BIOS_00D5:
        ; GTSTCK - Get joystick direction
        jp      BIOS_GTSTCK

        ds      0x00D8 - $, 0           ; pad to GTTRIG

BIOS_00D8:
        ; GTTRIG - Get trigger button
        jp      BIOS_GTTRIG

        ds      0x00DB - $, 0           ; pad to BREAKX

BIOS_00DB:
        ; BREAKX - Check CTRL-STOP (game JP.M/JP.P here)
        xor     a                       ; A=0 = not pressed
        ret                             ; CY=0 = not pressed

; ============================================================================
;  BOOT CODE at 0100h (where Vector-06C ROM starts execution)
;
;  .rom file is Vector-native: file[0] maps to mem[0100]. Page 0
;  (RST + BIOS stubs) is not in the file — install it from PAGE0_BLOB.
; ============================================================================

        ds      0x0100 - $, 0           ; pad to boot entry

BOOT_ENTRY:
        di
        ld      sp,GAME_STACK
        ld      hl,PAGE0_BLOB           ; copy RST/BIOS page into 0000..00FF
        ld      de,0x0000
boot_page0:
        ld      a,(hl)
        ld      (de),a
        inc     hl
        inc     e
        jp      nz,boot_page0
        jp      ADAPTER_INIT            ; jump to initialization

; ============================================================================
;  More BIOS stubs after boot entry (0100+)
; ============================================================================

        ds      0x011E - $, 0           ; pad to CKCNTC

BIOS_011E:
        ; CKCNTC - Check CTRL-C (3443 CALL.P)
        xor     a                       ; no CTRL-C
        ret

        ds      0x0135 - $, 0           ; pad to Dinamic click/beep

BIOS_0135:
        ; Dinamic click pattern - short delay/beep (game calls this 3x)
        jp      BIOS_CLICK

        ds      0x0138 - $, 0           ; pad to secondary beep stub

BIOS_0138:
        ; Another beep/delay entry point
        jp      BIOS_BEEP

        ds      0x0141 - $, 0           ; pad to SNSMAT

BIOS_0141:
        ; SNSMAT - Sense keyboard matrix
        jp      BIOS_SNSMAT

        ds      0x015B - $, 0           ; pad to ERAFNK

BIOS_015B:
        ; ERAFNK - Erase function key display (5de4 JP.Z)
        ret

        ds      0x01DE - $, 0           ; pad to CALBAS

BIOS_01DE:
        ; CALBAS - Call BASIC interpreter (34b5, 3513 JP.PO)
        ret

; Fixed entries for native replacements patched into the game
; (addresses used by tools/build_v06_rom.py) — keep 3-byte slots.
        ds      0x01E0 - $, 0
NATIVE_ROWREAD:
        ret                             ; former A4CC path — unreachable
        nop
        nop
NATIVE_ROWWRITE:
        ret                             ; former B231 path — unreachable
        nop
        nop
NATIVE_COURT:
        jp      COLOR_FRAME_BEGIN
NATIVE_SPRITE:
        jp      COLOR_SPRITE
NATIVE_STAMP:                           ; A521: the fans jump in CROWD_TICK
        ret
        nop
        nop
NATIVE_FRAME:
        jp      FRAME_END
NATIVE_RESET:
        jp      FRAME_RESET
NATIVE_DIRTY:
        jp      SPRITE_ROWS
NATIVE_BOXES:
        jp      COLOR_MENU_BEGIN
        ds      0x01FB - $, 0
NATIVE_TITLE:
        jp      TITLE_RELOAD

        ds      0x01FE - $, 0           ; pad to SUBROM

BIOS_01FE:
        ; SUBROM - Call SUB-ROM (26bb CALL.M)
        ret

; ============================================================================
;  ADAPTER CODE starts at 0200h
; ============================================================================

        ds      0x0200 - $, 0           ; pad to adapter area

ADAPTER_INIT:
        ; Called from boot at 0100h
        ; DI and SP already set
        
        call    INIT_VECTOR
        call    SOFTVDP_INIT
        call    V_KBD_INIT
        call    V_SND_INIT

        ; Splash is pre-rendered into plane E000 in the ROM image.
        ; Match/menu render directly to E000. Replay stages 960 bytes at 2000.
        
        
        xor     a
        ld      (IRQ_FRAME_COUNT),a
        ei
        ; The CPC title animation until Space (splash_anim.asm, in the
        ; replay ring/DP_BUF), then those buffers go back to zero as in the
        ; image: the game starts on the same memory as without it.
        call    SPLASH_ANIM
        ld      hl,SPLASH_ANIM
title_clear:
        ld      (hl),0
        inc     hl
        ld      a,h
        cp      0x25                    ; SA_END: DP_BUF ends at 24FF
        jp      nz,title_clear
        jp      GAME_ENTRY

GAME_STACK      equ     0xC000

; ============================================================================
;  Vector-06C Hardware Init
; ============================================================================
INIT_VECTOR:
        ; Set up PPI
        ld      a,0x88                  ; Port A,B,C output mode
        out     (0x00),a
        
        ; Scroll FF: top screen line = plane row FF (RENDER maps y→DF-y)
        ld      a,0xFF
        out     (0x03),a
        ld      (V_SCROLL),a
        
        ; Border black / 256-px (palette latched in IRQ via PAL_WRITE)
        xor     a
        out     (0x02),a
        ld      (V_BORDER),a
        ; Skip full-plane clear — title blit + RENDER fill E000; long LDIR
        ; delayed asset preload and starved the game under IRQ.
        ret

; CPC-style four-pen palette. E000 is bit 0 and C000 is bit 1.
; Byte = BB GGG RRR; unused upper-plane combinations repeat the same pens.
; MUST run from IRQ — Vector latches palette by raster.
PAL_TAB:
        db      0xC0,0xFF,0x00,0x5F,0xC0,0xFF,0x00,0x5F
        db      0xC0,0xFF,0x00,0x5F,0xC0,0xFF,0x00,0x5F

PAL_WRITE:
        ld      a,0x1F
        out     (0x03),a
        ld      hl,PAL_TAB+15
        ld      b,0x10
        ld      c,0x0F
pw_l:
        ld      a,c
        out     (0x02),a
        ld      a,(hl)
        out     (0x0C),a
        out     (0x0C),a                ; 2× enough for latch (was 8× — starved game)
        dec     hl
        dec     c
        dec     b
        jp      nz,pw_l
        xor     a
        out     (0x02),a
        ret

; ============================================================================
;  Interrupt Handler (once per frame ~50Hz)
; ============================================================================
IRQ_FRAME_COUNT equ     0x0F60

IRQ_HANDLER:
        di
        push    af
        push    bc
        push    de
        push    hl

        ld      a,(IRQ_FRAME_COUNT)
        inc     a
        ld      (IRQ_FRAME_COUNT),a
        ld      b,a

        ; Palette every 4th frame (latch is sticky enough)
        and     0x03
        jp      nz,irq_no_pal
        call    PAL_WRITE
irq_no_pal:
        call    V_KBD_POLL
        call    DP_ISR_COPY             ; match boxes, beam above the court
        
        call    V_SND_TICK
        
        pop     hl
        pop     de
        pop     bc
        ; Game ISR (MSX IM2 vector entry 4141: JP isr) once installed;
        ; it saves its own registers and ends with EI; RET.
        ; Music: runtime patches call 3714 → call AB28 at 3702.
        ld      a,(GAME_ISR_HOOK)
        cp      0xC3
        jp      nz,irq_no_game
        pop     af
        jp      GAME_ISR_HOOK
irq_no_game:
        pop     af
        ei
        ret


; ============================================================================
;  BIOS STUBS IMPLEMENTATIONS
; ============================================================================
        ds      0x029A - $, 0           ; BIOS_OUTDO stays at 029A (relocation manifest);
                                        ; the freed bytes held the VDP IN wrappers

BIOS_OUTDO:
        ; Menu 4/5 and the scoreboard print via RST 18. The game's own
        ; glyph blit is D8EB (font at (D1CC), cursor 4102=row / 4103=col).
        ; high_memory_relocation rewrites this call to 3B53 after the
        ; system/HUD block moves out of C000..DFFF.
        push    af
        push    bc
        push    de
        push    hl
        call    0xD8EB
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

BIOS_INITXT:
        ; Nametable is identity and is not stored. Plane is pre-baked.
        ret

BIOS_CLS:
        ; CLS — leave plane alone for bring-up (CLEAR_PLANE was too heavy)
        ret

BIOS_WSLREG:
        ; WSLREG - Write to VDP status latch register
        ; For SCREEN 2, this is typically a no-op or sets write address
        ; Just return for now
        ret

; Body is in win_a524.asm. Fixed entry 0135 is JP BIOS_CLICK.

BIOS_BEEP:
        ; Beep stub - just return
        ret

; ============================================================================
;  Include other modules
; ============================================================================
#include "softvdp.asm"
#include "kbd.asm"
#include "snd.asm"
#include "rle.asm"
#include "replay.asm"
GLUE_END:
        ds      0x0E00 - $, 0           ; free tail up to the page-0 image (zero, proven free)

; ============================================================================
;  Page-0 image for Vector-native .rom (loaded at 0100h).
;  build_v06_rom.py fills this from the assembled 0000..00FF bytes.
;  Must sit below VDP_REGS / kbd / snd work RAM at 0F00..
; ============================================================================
#assert $ <= 0x0E00               ; the code above must not run into this org
        org     0x0E00
PAGE0_BLOB:
        ds      0x0100, 0
