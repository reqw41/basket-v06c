#!/usr/bin/env bash
# Корень spirits-v06c и его tools. Форки появляются в этом репо по мере надобности.
: "${SPIRITS_V06C:=$HOME/projects/spirits-v06c}"
export SPIRITS_V06C
export SPIRITS_TOOLS="$SPIRITS_V06C/tools"

if [[ ! -d "$SPIRITS_TOOLS" ]]; then
  echo "spirits tools not found: $SPIRITS_TOOLS" >&2
  echo "set SPIRITS_V06C to the spirits-v06c checkout" >&2
  return 1 2>/dev/null || exit 1
fi
