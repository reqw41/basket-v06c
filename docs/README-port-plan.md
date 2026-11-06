# Fernando Martín Basket Master → Вектор-06Ц

Порт **Fernando Martín Basket Master Executive** (Dinamic, MSX, 1987) на
**ванильный Вектор-06Ц** (КР580ВМ80А, без Z80-переходника). Метод и
инструменты — по лекалам [`spirits-v06c`](../spirits-v06c): дизасм MSX →
раскладка Вектора → адаптер экрана/ввода/звука → рекомпиляция Z80→i8080.

Целевая картинка: **режим 2+2 плоскости** видеопамяти Вектора, чтобы
получить раскраску, близкую к **Amstrad CPC** (4 пера), а не к типичной
ZX/MSX-монохромной конверсии.

Стадия: **Z80, четыре цвета** — спрайты напрямую извлечены из CPC-версии
и выводятся в две аппаратные плоскости с палитрой чёрный/белый/синий/розовый.
Повтор захватывает и увеличивает обе плоскости. Площадка, HUD и меню пока
остаются однобитными; следующий графический этап — их CPC-раскраска.
Переход игрового кода с Z80 на КР580ВМ80А остаётся отдельным этапом.

---

## Об игре

Один-на-один баскетбол по мотивам Фернандо Мартина. Издания: CPC, ZX,
C64, MSX, позже DOS. На MSX первая версия была сырой; **Executive** —
переписанный релиз с меню и более живой палитрой (ближе к Spectrum, уже
не ч/б). Источник для порта — **Executive (MSX)**: проще декомпилируется
(тонкий VDP/BIOS-слой), чем CPC с Mode 1 и теневым буфером.

Ссылки:

- [My Abandonware — Executive (MSX)](https://www.myabandonware.com/game/fernando-martin-executive-qpu)
- [Basket Master (обзор изданий)](https://www.myabandonware.com/game/fernando-martin-basket-master-a0)
- [MSXBlog — Executive](https://www.msxblog.es/fernando-martin-basket-master-executive-marzo-2009/)

---

## План порта (кратко)

Порядок как в Spirits: **сначала эталон Z80 на Векторе**, рекомпиляция
i8080 — после него. Подробно — [`docs/plan.md`](docs/plan.md).

| этап | суть | статус |
|---|---|---|
| A | Intake Executive + дизасм round-trip | next |
| B | Карта MSX + инвентаризация чт/зп (первая неделя) | |
| C | Раскладка v06, `trap_stale` | |
| D | Адаптер **2+2**, живой эталон Z80 | |
| E | Профиль IX/IY → `recompile_i8080` → block_equiv | |
| F | Emu80/MiSTer, полный порт | |

Метод и жёсткие правила — [`docs/recompilation.md`](docs/recompilation.md)
(полный журнал — в spirits). Цвет — [`docs/v06-planes-2plus2.md`](docs/v06-planes-2plus2.md).

---

## Инструменты

Базовый конвейер живёт в `../spirits-v06c/tools/`. Локальные обёртки и
форки — в `tools/` этого репо. Переопределение корня spirits:

```sh
export SPIRITS_V06C=~/projects/spirits-v06c   # по умолчанию так и есть
source tools/env.sh
```

См. [`tools/README.md`](tools/README.md). При необходимости tools
дорабатываются здесь или в spirits с обратным переносом уроков в
`docs/recompilation.md`.

### Зависимости (как у spirits)

- Python 3
- **zasm 4.5** (`--8080`); типичный путь —
  `~/projects/kvalley-v06c/tools/bin/sjasm`
- Node.js — стенды на [vector06js](https://github.com/svofski/vector06js)
- openMSX — сверки с живым MSX (не нужен для сборки ROM)

---

## Каталоги

| путь | роль |
|---|---|
| `ref/msx/` | дампы Executive (кассета/DSK/ROM) + манифест |
| `ref/cpc/` | эталон цвета CPC (`basketmb.zip` — CDT) |
| `ref/zx/` | при необходимости сверка графики |
| `disasm/msx/` | дизасм (канон / orig / v06) |
| `src/v06/` | адаптер Вектора (ручной i8080) |
| `src/i8080/` | GENERATED: игра после рекомпиляции |
| `docs/` | план, память, рекомпиляция, цвет |
| `tools/` | обёртки + локальные форки |

Оригинальные бинарники **не лицензируются MIT** — см. `NOTICE`.

---

## Документация

Оглавление — [`docs/README.md`](docs/README.md).
