# Intake: MSX Fernando Martín Executive

## Какую редакцию брать

| редакция | брать? | заметка |
|---|---|---|
| **Fernando Martín Basket Master Executive** (MSX, Dinamic, 1987) | **да** | переписанная MSX-версия; меню, больше цвета |
| первая MSX Basket Master | только для сравнения | сырая, с ошибками; Executive её заменил на рынке |
| CPC / ZX / C64 | эталон вида / сверка банков | не база кода |
| DOS Basket Master (1990) | нет | другая платформа |

Источник страницы задачи:
https://www.myabandonware.com/game/fernando-martin-executive-qpu

«QPU» в URL My Abandonware — внутренний суффикс сайта, не подзаголовок
издания.

## Текущий результат intake

Executive принят как рабочая база: кассета разобрана в три payload-файла,
собран проверочный 64K ASCII16 ROM, а блок 2 уже имеет дизассемблер с
байт-в-байт round-trip. Первый MSX DSK сохранён в `ref/msx/first/` только
для сравнения и явно не является базой порта. CPC-архив остаётся эталоном
палитры/вида, не исходником кода.

## Куда класть

```
ref/msx/
  MANIFEST.md          # имена, размер, SHA-256, происхождение
  executive/           # кассета / DSK / извлечённые payload
  first-msx/           # опционально, для diff
```

Крупные бинарники в `.gitignore`. В git — только манифест и мелкие
тексты.

## Что зафиксировать в MANIFEST

1. Имя файла как скачано.
2. Размер и SHA-256 всего архива и каждого payload.
3. Тип носителя (CAS/WAV/DSK/ROM).
4. Команда загрузки / точки BLOAD / entry.
5. Подтверждение, что это **Executive**, а не первая MSX (меню, скриншоты,
   размер, сравнение с known dumps).

## Пока дампа нет

Сборка и дизасм не стартуют. CPC-эталон уже локально:

```
ref/cpc/basketmb.zip   # gitignored; скопирован из ADATE tape/games
# внутри: Fernando Martin Basket Master.cdt + file_id.diz
```

После появления MSX-дампа — шаг 1 в [plan.md](plan.md).
