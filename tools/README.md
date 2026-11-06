# Tools basket-v06c

Пока форков нет — берём конвейер из spirits:

```sh
source tools/env.sh          # SPIRITS_V06C, SPIRITS_TOOLS
python3 "$SPIRITS_TOOLS/recompile_i8080.py" --help
python3 "$SPIRITS_TOOLS/check_i8080.py" --help
```

Что перенимать / когда форкать — [`docs/spirits-handoff.md`](../docs/spirits-handoff.md).

Локальные скрипты этого репо появятся здесь же (дизасм Basket, сборка ROM,
стенды матча).
