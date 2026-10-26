#!/usr/bin/env bash
# Vuelve el proyecto al estado inicial para repetir la guía.
set -euo pipefail
cd "$(dirname "$0")/.."

git reset --hard estado-inicial
git clean -fdx

echo
echo "Proyecto restaurado a 'estado-inicial'."
echo "Estado esperado: 4 fallos, 4 aprobados."
python3 -m pytest -q || true
