# Что перенимаем из spirits-v06c

Корень по умолчанию: `~/projects/spirits-v06c` (`SPIRITS_V06C` в
`tools/env.sh`).

## Брать почти as-is (через env / тонкие обёртки)

| инструмент | зачем |
|---|---|
| `tools/recompile_i8080.py` | Z80→i8080 |
| `tools/check_i8080.py` | гейт чистого i8080 |
| `tools/cycles_i8080.py` | оценка тактов |
| `tools/prof_pc_v06js.js` | горячие IX/IY |
| `tools/block_equiv_v06js.js` | эквивалентность границ витка |
| `tools/trap_stale_v06js.js` | непереехавшие адреса |
| `tools/find_unrelocated.py` | указатели в данных |
| `src/v06/kbd.asm`, `joy.asm`, `snd.asm` | как образец ABI (не копипаст адресов) |

## Форкать под Basket (появятся локальные копии)

| зона | почему |
|---|---|
| `disasm_msx.py` / verify_* | другие сегменты и точки входа |
| `build_*_rom.py` | другая карта и 2+2 экран |
| `screen_adapter.asm` | плоскости и перья под баскетбол |
| стенды playthrough | другой геймплей (матч, не 87 комнат) |

## Документы-доноры

| spirits | зачем читать |
|---|---|
| `docs/recompilation.md` | полный журнал сайтов Spirits |
| `docs/pitfalls.md` | дефекты и детекторы |
| `docs/cpc-render.md` | модель «1-бит + перья → 4 цвета» |
| `docs/v06-memory.md` | как не положить стек на рабочую RAM |
| `docs/adapter-requirements.md` | контракт врезок |

Уроки, полезные любому порту, дублируются в сжатом виде в
[recompilation.md](recompilation.md) этого репо — чтобы не прыгать в
spirits за чеклистом первой недели.
