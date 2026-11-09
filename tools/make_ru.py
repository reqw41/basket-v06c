#!/usr/bin/env python3
"""Russian edition: the same image with Russian texts and Cyrillic glyphs.

  python3 tools/make_ru.py IN.rom OUT.rom      # Z80 or i8080 image, loads at 0100

The game prints with its 8x8 font (GAME_FONT, code * 8) and every text is a
string in place (FF-terminated, or the 0-terminated control records of the
menu, src/v06/menu_color_bg.asm). Strings and the font are data: they stay
at the same addresses in the Z80 and the i8080 image, so the Russian edition
is a patch of the finished image, not a second build:

- Russian letters that look like Latin ones use the Latin glyphs
  (А В Е К М Н О Р С Т Х); the others (tools/cyr8.py) replace punctuation
  that no text uses. Latin letters stay: the name entry types Latin.
- Each string keeps its length (padded with spaces): the code walks from
  string to string over the terminators.
- The menu control records are re-laid in the same 133 bytes.

Every English string is checked before it is replaced, so a moved string
stops the script instead of patching the wrong bytes.
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from cyr8 import CYR, LAT  # noqa: E402

BASE = 0x100
GAME_FONT = 0x3B80
# Punctuation no English or Russian text prints (the name entry may type some
# of these keys; it then shows a Russian letter).
FREE = "\"#$%&'()<;=>@[\\]^"

# addr, English (as in the image), Russian (same length)
STRINGS = [
    # match messages, 11 each (9452..; an empty one after the name)
    (0x9452, " PLAYER 1  ", " ИГРОК 1   "),
    (0x945E, " MARTIN F. ", " МАРТИН Ф. "),
    (0x946B, "  DOUBLE   ", " ДВ.ВЕДЕНИЕ"),
    (0x9477, "   FOUL    ", "    ФОЛ    "),
    (0x9483, "  * OUT *  ", "  * АУТ *  "),
    (0x948F, " BASKET !  ", " КОРЗИНА ! "),
    (0x949B, "BACK COURT ", "  ВОЗВРАТ  "),
    # end of a match and statistics (A362..)
    (0xA362, "FOULED OUT              ", "УДАЛЕН ЗА ФОЛЫ          "),
    (0xA38C, "  GAME   OVER   ", "  КОНЕЦ  ИГРЫ   "),
    (0xA39D, "    ON FOULS    ", "   ПО  ФОЛАМ    "),
    (0xA3CB, "  TIME !!  ", " ВРЕМЯ !!  "),
    (0xA3E3, " BASKETS ", " КОРЗИНЫ "),
    (0xA3ED, " FOULS     ", " ФОЛЫ      "),
    (0xA3F9, " FREE THROWS ", " ШТРАФНЫЕ    "),
    (0xA407, " BOARDS ", " ПОДБОРЫ"),
    (0xA410, " THREES ", " ТРЕШКИ "),
    # menu (A797..)
    (0xA797, "1 PLAYER ", "1 ИГРОК  "),
    (0xA7A1, "2 PLAYERS  ", "2 ИГРОКА   "),
    (0xA7AD, "3 LEVEL ", "3 КЛАСС "),
    (0xA7B6, "4 CHANGE NAMES   ", "4 ИМЕНА ИГРОКОВ  "),
    (0xA7DA, "ROOKIE ", "НОВИЧОК"),
    (0xA7E2, "AMATEUR", "СРЕДНИЙ"),
    (0xA7EA, "NBA    ", "НБА    "),
    (0xA7F2, "MARTIN F. ", "МАРТИН Ф. "),
    (0xA7FD, "PLAYER 2  ", "ИГРОК 2   "),
    (0xA808, "LEFT COURT:      ", "ЛЕВАЯ СТОРОНА:   "),
    (0xA81A, "RIGHT COURT:     ", "ПРАВАЯ СТОРОНА:  "),
    # scoreboard
    (0x9348, "TIME", "ТАЙМ"),
    (0xB48C, "TIME", "ТАЙМ"),
]

# menu control records: column, plane Y, high-plane mask (FF pink), text, 0
MDC_EN = [
    (3, 0xDF - 150, 0xFF, "1 PLAYER:"), (13, 0xDF - 150, 0, "JOYSTICK OR KEYS"),
    (3, 0xDF - 161, 0xFF, "2 PLAYERS:"), (14, 0xDF - 161, 0, "P1 JOY, P2 KEYS"),
    (4, 0xDF - 172, 0xFF, "KEYS:"), (10, 0xDF - 172, 0, "ARROWS, FIRE SPACE"),
    (1, 0xDF - 184, 0, "COPYRIGHT DINAMIC SOFTWARE 1987"),
]
MDC_RU = [
    (3, 0xDF - 150, 0xFF, "1 ИГРОК:"), (12, 0xDF - 150, 0, "ДЖОЙСТИК, КЛАВИШИ"),
    (2, 0xDF - 161, 0xFF, "2 ИГРОКА:"), (12, 0xDF - 161, 0, "ДЖОЙСТИК+КЛАВИШИ"),
    (4, 0xDF - 172, 0xFF, "КЛАВИШИ:"), (13, 0xDF - 172, 0, "СТРЕЛКИ, ПРОБЕЛ"),
    (1, 0xDF - 184, 0, "COPYRIGHT DINAMIC SOFTWARE 1987"),
]


def records(recs, enc) -> bytes:
    out = bytearray()
    for col, y, mask, text in recs:
        out += bytes([col, y, mask]) + enc(text) + b"\0"
    return bytes(out + b"\0")


def main() -> None:
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])
    img = bytearray(src.read_bytes())

    def at(a: int) -> int:
        return a - BASE

    letters = sorted({c for _, _, ru in STRINGS for c in ru} | {c for r in MDC_RU for c in r[3]})
    own = [c for c in letters if c in CYR]
    if len(own) > len(FREE):
        raise SystemExit(f"{len(own)} Russian glyphs, {len(FREE)} free places")
    code = {c: FREE[i] for i, c in enumerate(own)}
    for c in letters:
        if "А" <= c <= "Я" and c not in CYR and c not in LAT:
            raise SystemExit(f"no glyph for {c}")

    def enc(text: str) -> bytes:
        return bytes(ord(code.get(c, LAT.get(c, c))) for c in text)

    for a, en, ru in STRINGS:
        if len(en) != len(ru):
            raise SystemExit(f"{a:04X}: {ru!r} is {len(ru)}, want {len(en)}")
        if bytes(img[at(a):at(a) + len(en)]) != en.encode() or img[at(a) + len(en)] != 0xFF:
            raise SystemExit(f"{a:04X}: image has {bytes(img[at(a):at(a) + len(en) + 1])!r}, want {en!r}+FF")
        img[at(a):at(a) + len(ru)] = enc(ru)

    en_rec = records(MDC_EN, lambda t: t.encode())
    hit = img.find(en_rec)
    if hit < 0 or img.find(en_rec, hit + 1) >= 0:
        raise SystemExit("menu control records not found once")
    ru_rec = records(MDC_RU, enc)
    if len(ru_rec) > len(en_rec):
        raise SystemExit(f"menu control records {len(ru_rec)} B, room {len(en_rec)}")
    img[hit:hit + len(en_rec)] = ru_rec + bytes(len(en_rec) - len(ru_rec))

    for c, slot in code.items():
        g = bytes(int(row.replace("#", "1").replace(".", "0"), 2) for row in CYR[c])
        img[at(GAME_FONT + ord(slot) * 8):at(GAME_FONT + ord(slot) * 8) + 8] = g
    dst.write_bytes(img)
    print(f"{dst}: {len(STRINGS)} strings + menu controls; glyphs "
          + " ".join(f"{c}={code[c]}" for c in own) + f" ({len(own)}/{len(FREE)})")


if __name__ == "__main__":
    main()
