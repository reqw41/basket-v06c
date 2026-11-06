# Текстовое меню CPC и баннер VECTOR

Рабочий ROM: `build/v06/basket-visual-fix-98940148.rom`  
SHA-256 `9894014866630a2241b2a9f4bd60f951a17a244047cb548163c647aba27f06ec`  
Контрольный ROM до смены оформления: `build/v06/basket-control-pre-menu-vector-54f34fc.rom`  
(`1245bdac…`). Предыдущий text/VECTOR без visual-fix: `30b222a4…`.

## До / после

| Объект | До | После | Δ |
|---|---:|---:|---:|
| Меню (packed) | 1530 LZ mono Executive | **800** dual LZ text chrome | **−730** |
| Splash asset | 1261 zlib → 16K planes | generated from font into planes | source removed |
| Court tiles | 3856 (213 tiles, tail 272) | **3824** (211 tiles, tail 240) | **−32** |
| Menu LZ decoder | 83 B @1720 | 91 B @1320 + 3 B JP @1720 | +11 code |
| `0FED` | reserved | LZ end-page scratch | — |
| Menu slot gap | 6 B | **645** retained zeros `137B..15FF` | not claimed free |
| Court tail gap | 0 | **32** retained zeros `16F0..170F` | not claimed free |
| ROM size | 65280 | 65280 | 0 |
| Reserves / stack / replay / planes | unchanged | unchanged | 0 |

Суммарно ресурсы меню+корт: 1530+3856=5386 → 800+3824=4624 (**−762**), плюс удалены исходники Executive splash/menu.

## Форматы

- Заставка и меню: `tools/gen_text_screens.py` рисует чёрный фон, рамку (белый/синий/розовый), `BASKET MASTER` ×2 из шрифта `(3434)→3B80`, подсказки. Меню: `dw hi_addr` + LZ low + LZ high @`1000`. `MENU_BG_RELOAD` распаковывает обе плоскости и сбрасывает `TITLE_SNAPPED`.
- Пункты `1..5` по-прежнему печатает игровой код (`A797` / `A694`).
- Баннер: при `pack_court()` три щита AMSTRAD (tile cols 4/12/20, rows 40..54) очищаются и заполняются `VECTOR` (синяя заливка, белый контур). Полный re-dedupe тайлов.
- Эталон поля для тестов: `build/v06/expected_court_pairs.bin`.

## Скорость (500 кадров, keyboard scenarios)

| Сценарий | `1245bdac` | `30b222a4` | `98940148` |
|---|---:|---:|---:|
| 1P без ввода | 6.71 tick/s | 6.71 | 6.81 |
| 1P motion→stop | 6.01 | 6.01 | 6.01 |

## Проверки

`python3 tools/verify_refactor.py --profile full` — полный набор. Независимые эталоны: `menu_text_{lo,hi}.bin`, `cpc_court_mode1.bin`, MSX Executive masks; плюс `tools/test_visual_regressions.py` (мяч/трибуны/попадание).
