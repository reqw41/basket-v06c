# Темп ZX-версии (10.11.2026)

Образ: Spectrum Computing, запись 1741, `FernandoMartinBasketMaster.tzx.zip` → `ref/zx/` (не в git).
Снимок: `tap2sna.py "ref/zx/Fernando Martin Basket Master.tzx" ref/zx/bm.z80` (SkoolKit 10.1,
venv `~/projects/greatescape-v06c/tools/.venv`).

    PY=~/projects/greatescape-v06c/tools/.venv/bin/python
    $PY tools/zx_speed/bench.py            # без ввода, спорная память (CCMIOSimulator)
    PLAN=1 $PY tools/zx_speed/bench.py     # игрок 1 бегает (P/Q/O/A)
    CMIO=0 $PY tools/zx_speed/bench.py     # без задержек спорной памяти

Ход игры = вход в 61F6 (тот же код, что MSX 8554). Меню: SPACE на заставке, «1» — один игрок.
