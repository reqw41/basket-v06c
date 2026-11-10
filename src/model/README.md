# JS-модель логики Basket Master (A1)

Логика игры (окно 84D0..B257 и системный блок 3300..3F7F) переписана на JS
по Z80-коду порта (`disasm/v06/game.asm`) — спецификация для ручного i8080 (A2).

- Процедура — функция `fn(m)` с адресом входа Z80 в `module.exports.procs`;
  `m` — машина стенда (`tools/native/machine.js`): регистры `m.r`, память
  `m.rd/m.wr/m.rd16/m.wr16`, стек `m.push/m.pop`.
- Вызовы: `m.call(addr)` — процедура игры как CALL (кладёт адрес возврата,
  как Z80); `m.pcall(addr)` — платформа как CALL; `return m.jp(addr)` —
  хвостовой переход (в модель или платформу); `m.halt(pc)`, `m.mark(pc)`.
  Прямой вызов JS-функции — только для процедур без выхода в платформу
  (иначе SP в событии платформы будет не тот).
- Флаги — помощниками `z80.js` (`add8`, `cp8`, `bitm`…), точно как ядро
  эмулятора; поля игроков — `ent.js` (`ix(d)`, `sx(d, bit)`…).
- Модули: `main` (главный цикл, кадр 8554), `setup` (рестарты, планировщик
  объектов 94B0), `walk`, `action`, `contact`, `move`, `flight`, `ball`,
  `pdraw` (отрисовка игроков), `ai` (соперник), `stamina` (силы, часы),
  `score`, `stats`, `menu`, `replay`, `sound` (PSG-проигрыватель MSX),
  `sys` (системный блок), `math`, `rng`, `stubs` (векторные таблицы).

Проверка:

    STRICT=1 node tools/native/model_run.js      # все эталоны, без Z80
    SHADOW=1 node tools/native/model_run.js      # + каждый вызов против Z80 (флаги)
    node tools/native/model_fuzz.js 30 7         # мутации и редкие ветви против Z80
