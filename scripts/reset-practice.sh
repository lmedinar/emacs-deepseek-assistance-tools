#!/usr/bin/env bash
# Vuelve el proyecto de práctica al commit estado-inicial.
set -euo pipefail

PRACTICE="${PRACTICE_DIR:-$HOME/src/ia-python-practica}"

if [ ! -d "$PRACTICE/.git" ]; then
  echo "No es un repositorio git: $PRACTICE" >&2
  exit 1
fi

git -C "$PRACTICE" reset --hard estado-inicial
git -C "$PRACTICE" clean -fdx

echo "Proyecto restaurado a estado-inicial: $PRACTICE"
echo "Estado esperado: 4 fallos, 4 aprobados."
