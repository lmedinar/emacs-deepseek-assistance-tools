#!/usr/bin/env bash
# Prepara el entorno y el proyecto de práctica.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRACTICE="${PRACTICE_DIR:-$HOME/src/ia-python-practica}"

INSTALL=0
for arg in "$@"; do
  case "$arg" in
    --install) INSTALL=1 ;;
    -h|--help)
      echo "Uso: $0 [--install]"
      echo "  --install  Instala las dependencias con scripts/install-deps.sh --yes."
      exit 0 ;;
    *) echo "Argumento desconocido: $arg" >&2; exit 1 ;;
  esac
done

if [ "$INSTALL" -eq 1 ]; then
  "$ROOT/scripts/install-deps.sh" --yes
fi

echo "== Herramientas =="
FALTAN=0
for cmd in git python3 pytest black rg pyright; do
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "  ok: $cmd"
  else
    echo "  FALTA: $cmd"
    FALTAN=1
  fi
done
if [ "$FALTAN" -eq 1 ] && [ "$INSTALL" -eq 0 ]; then
  echo "  Instala lo que falta con: ./scripts/install-deps.sh --yes"
fi

echo
echo "== Clave de DeepSeek =="
KEY_FILE="$HOME/.emacs.d/.deepseek-key"
if [ -n "${DEEPSEEK_API_KEY:-}" ]; then
  echo "  DEEPSEEK_API_KEY está definida."
elif [ -s "$KEY_FILE" ]; then
  echo "  Usando $KEY_FILE"
else
  echo "  No hay clave configurada. Haz una de estas dos cosas:"
  echo "    export DEEPSEEK_API_KEY='tu-clave'"
  echo "    mkdir -p ~/.emacs.d && printf '%s' 'tu-clave' > $KEY_FILE && chmod 600 $KEY_FILE"
fi

echo
echo "== Proyecto de práctica =="
if [ -e "$PRACTICE" ]; then
  echo "  Ya existe: $PRACTICE (no se toca)"
else
  mkdir -p "$(dirname "$PRACTICE")"
  cp -a "$ROOT/practice" "$PRACTICE"
  git -C "$PRACTICE" init -q -b main
  git -C "$PRACTICE" add .
  git -C "$PRACTICE" -c user.name="${GIT_AUTHOR_NAME:-Práctica}" \
      -c user.email="${GIT_AUTHOR_EMAIL:-practica@example.com}" \
      commit -qm "Estado inicial"
  git -C "$PRACTICE" tag estado-inicial
  echo "  Creado: $PRACTICE (tag estado-inicial)"
fi

echo
echo "== Siguiente paso =="
echo "  emacs --init-directory \"$ROOT/emacs\""
echo "  Abre $PRACTICE y pulsa C-c P t"
