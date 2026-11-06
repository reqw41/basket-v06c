# Контрольная точка рефакторинга (этап 0)

Зафиксировано **2026-09-26**. Монохромный Z80-порт до перекомпоновки
памяти и четырёхцветной графики. `BASELINE_PASS` — не полная приёмка игры.

## ROM

| Образ | Путь | SHA-256 |
|---|---|---|
| Рабочий / воспроизводимый | `build/v06/basket.rom` (gitignore) | `4c0679cb1a4535ee03f56ab4324ba8fc1be4d03fdd7bd8b6f20575f4e6ceb5b5` |
| Эталон переноса (relocation) | `build/v06/basket-etalon-54d6ee2d.rom` (gitignore) | `54d6ee2ddcbb89afc641e41accc0b42f61f4e5a3d00a962f98002a535dfb71e0` |

Две чистые сборки в изолированных каталогах совпали между собой и с
сохранённым рабочим образом (`reproducible_current_rom: PASS`).
Исходники и внешний инструментарий во время прогона не изменились
(`working_tree_unchanged: PASS`). `memory_layout: NOT_CHECKED`.

Эталон переноса хранится только локально в `build/v06/`; в Git не
входит. Для проверок `verify_refactor.py` копирует его в первый
изолированный work-каталог после чистой сборки.

## Сборка

```sh
python3 tools/build_v06_rom.py
```

Выход: `build/v06/basket.rom` (65280 байт, загрузка с `0x0100`).
Сборщик читает `ref/msx/executive/executive.{overlay,block0,block1}.bin`
и собирает адаптер через sjasm (`src/v06/*.asm`).

## Проверки

Команды из корня (см. [verification.md](verification.md)):

```sh
python3 tools/verify_refactor.py --profile full
python3 tools/verify_refactor.py --profile baseline
```

### Полный профиль — FAIL

Отчёт: `build/verification/20260926T083411.910312Z/`
(`report.md`, `report.json`, `logs/`).

| Проверка | Статус |
|---|---|
| clean_build_1 / clean_build_2 | PASS |
| reproducible_current_rom | PASS |
| verification_harness / cfg | PASS |
| sprite_model / relocation / replay_graphics | PASS |
| match_1p / match_2p / match_1p_throw | PASS |
| match_1p_esc | **FAIL** — нет `menu_return_via_input` («menu return not observed») |
| match_replay | **FAIL** — нет `REPLAY_ZOOM` / `replay_via_game` («natural replay entry not observed») |
| working_tree_unchanged | PASS |

FAIL полного профиля — известное ограничение исходной контрольной точки,
не скрыто и не ослаблено правкой тестов.

### Сокращённый профиль — BASELINE_PASS

Отчёт: `build/verification/20260926T083433.250004Z/`
(`report.md`, `report.json`, `logs/`).

Те же проверки, что выше, кроме `match_1p_esc` и `match_replay`
(`NOT_RUN`). Код возврата 0. Это фиксация контрольной точки с
ограничениями, не полная приёмка.

## Зависимости (версии и пути на момент прогона)

| Компонент | Значение |
|---|---|
| Python | 3.14.6 |
| Node.js | v26.4.0 |
| sjasm (zasm) | 4.5.0 (`/Users/boris/projects/kvalley-v06c/tools/bin/sjasm`, SHA-256 `664400e42d69d04a73c2472185b04dd96bbf383dcce72d6cfb24bf3cec7f4efc`) |
| z80dis | `/Users/boris/projects/spirits-v06c/tools/vendor/z80dis.py` (`a472b34bd036aef0a00473057e2eb784c81ffa7e681e5336cd81d9391fd74535`) |
| vector06js | `/Users/boris/projects/vector06js` (+ `z80_adapter.js`) |

Полные хеши файлов эмулятора и исходников — в `report.json`
(`dependency_files`, `source_files`).

## Игнорируемые и внешние ресурсы

Нужны для сборки/сверки, в Git не входят (см. `.gitignore` и
[ref/msx/MANIFEST.md](../ref/msx/MANIFEST.md)):

| Ресурс | Роль |
|---|---|
| `ref/msx/executive/executive.{cas,rom,zip}` | исходные дампы Executive |
| `ref/msx/first/*.dsk` | сверка с первой MSX |
| `ref/cpc/*.{cdt,zip}` | эталон цвета CPC |
| `build/v06/basket.rom` | рабочий образ (пересобирается) |
| `build/v06/basket-etalon-54d6ee2d.rom` | эталон relocation |
| `build/verification/` | артефакты прогонов |
| `src/v06/{scheme,cpu,game_labels}.inc` | генерируются сборкой |

В коммит baseline входят payload-ы сборки
`executive.overlay.bin` / `block0.bin` / `block1.bin` / `block2.bin`
(хеши в манифесте), исходники `src/v06/`, `disasm/`, `tools/`, `docs/`.

Вне репозитория: `kvalley-v06c` (sjasm), `spirits-v06c` (z80dis),
`vector06js` (эмулятор с Z80-адаптером).

## Ограничения покрытия

- Текущая монохромная раскладка Z80; не приёмка 2+2 / i8080.
- `sprite_model` — Python-модель, не исполнение спрайтовой процедуры ROM.
- `replay_graphics` — прямые вызовы процедур (в т.ч. подготовленный повтор);
  не штатное событие, запускающее повтор.
- `match_replay` / `match_1p_esc` на полном профиле **FAIL** (см. выше).
- `match_1p_throw` — вход и обращения к обработчику кнопки, не все варианты
  завершения броска.
- Нет автоматической оценки мерцания / качества звука.
- `memory_layout: NOT_CHECKED` — целевая карта ещё не внедрена.
- Адреса в тестах относятся к текущей раскладке.

## Воспроизведение

1. Восстановить локально `build/v06/basket-etalon-54d6ee2d.rom` с хешем выше
   (или получить из предыдущего машинного снимка).
2. Убедиться, что sjasm / vector06js / z80dis доступны по путям выше
   (или эквивалентным, как в `tools/build_v06_rom.py` / `tools/env.sh`).
3. `python3 tools/build_v06_rom.py` → ROM с SHA-256 `4c0679cb…ceb5b5`.
4. `python3 tools/verify_refactor.py --profile baseline` → `BASELINE_PASS`.
5. `python3 tools/verify_refactor.py --profile full` → ожидаемый `FAIL` на
   `match_1p_esc` и `match_replay`, при прочих PASS и совпадении хеша ROM.
