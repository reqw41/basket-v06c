; Small scene dispatchers in the unused tail of the packed-menu slot.
; The menu/court codecs end before 18CA; helpers stop below the replay ring 1B40.
        include "labels_menu_player_helpers.inc"
        org 0x18CA
; After HUD_DECOR STORE (multi-frame), reprint panel text into the holes.
HUD_TEXT_REFRESH:
        push    af
        push    bc
        push    de
        push    hl
        call    GAME_PRINT_FOULS                  ; foul marks
        call    GAME_PRINT_SCORES                  ; scores
        call    GAME_PRINT_NAMES                  ; team names
        call    GAME_PRINT_CLOCK                  ; clock
        call    GAME_POWER_BARS                  ; both power bars (HUD_DECOR wiped them)
        ld      hl,0x0E11               ; col 14, row 17: box above the clock
        ld      de,TIME_TEXT               ; TIME_TEXT (hud_icon.asm)
        call    GAME_PRINT_STRING                  ; game string printer (RST 18 glyphs)
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

PLAYER_BACKGROUND_HIGH:
        ld a,(0x0FEF)
        or a
        jp z,COURT_HIGH_BYTE
        ld a,(0x0F59)           ; high from last MENU_PLANE_PAIR / court fetch
        ret

PLAYER_SCENE_HELPERS_END:
