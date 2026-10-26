#!/usr/bin/env bash
# Verifica scripts, configuración de Emacs y estado del proyecto.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "== Sintaxis de scripts =="
bash -n "$ROOT"/scripts/*.sh "$ROOT"/practice/scripts/*.sh
echo "  ok"

echo
echo "== Emacs carga la configuración =="
emacs --batch -l "$ROOT/emacs/init.el" \
  --eval '(princ (format "  backend: %s | modelo: %s | herramientas: %s\n" (gptel-backend-name gptel-backend) gptel-model (length ia--tools-proyecto)))'

echo
echo "== pytest (esperado: 4 fallos) =="
(cd "$ROOT/practice" && python3 -m pytest -q) || true

echo
echo "== Listo =="
