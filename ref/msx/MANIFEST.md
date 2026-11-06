# MSX dumps (Executive)

Положить сюда кассету **Fernando Martín Basket Master Executive** и
запустить `tools/prepare_orig.py` (ниже) — он соберёт остальные файлы таблицы. Материалы оригинала в `.gitignore` — в git только этот манифест.

См. [docs/msx-intake.md](../../docs/msx-intake.md).

| файл | размер | SHA-256 | что это |
|---|---:|---|---|
| `executive/Fernando Martin Basket Master - Executive (1987)(Dinamic Software)(ES)[a][RUN'CAS-'].cas` | 48671 | `0c8577f41c5eb9518d54d29e35a4628b93d38b405b53b207ea527f715beb4f70` | cassette image |
| `executive/executive.rom` | 65536 | `fa119d7d2d9d7017f86bde5e241c7722f9fd2d88f988953bbb477c4f50c2822d` | ASCII16 64K, 3-stage BLOAD+R |
| `executive/executive.block0.bin` | 10601 | `37d9bf3f5fac06a6e7d1ab7d6aaac31d991ada1e63c62eb2dcc7fbcee094975b` | BLOAD `B3B0h..DD18h`, entry `CF08h` |
| `executive/executive.block1.bin` | 19136 | `0c9c3f0fdf0284882fa27d81149fe03fc5f4e1fdad58bf7101319744c6ef2ca6` | BLOAD `8534h..CFF3h`, entry `CF08h` |
| `executive/executive.block2.bin` | 18529 | `96898d004ccdc1a40f0fe6fbce2573f60d41671a13f429ffdb3a989d15dacdfc` | BLOAD `84D0h..CD30h`, entry `84D0h` |

The ROM contains the sequential-load overlay `84D0h..DD18h` (22601
bytes), copied to RAM by the cartridge initializer, then jumps to `84D0h`.
The source blocks are `B3B0h..DD18h` (entry `CF08h`), `8534h..CFF3h`
(entry `CF08h`), and `84D0h..CD30h` (entry `84D0h`).
`CF08h` is the VDP fill/upload routine used by the first two stages; it is
not a tape continuation entry.

Build:

```sh
python3 tools/prepare_orig.py 'ref/msx/executive/'*.cas   # блоки, overlay, картридж; сверка SHA-256
```

Run in openMSX (no `RUN"CAS:"`):

```sh
tools/run_exec_msx.sh
```

Проверка, что это Executive, а не первая MSX: меню, цвет, сравнение с
known dumps / скриншотами My Abandonware Executive.
