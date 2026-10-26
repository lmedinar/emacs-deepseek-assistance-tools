#!/usr/bin/env bash
# Instala las dependencias del sistema y de Python (opt-in).
# Por defecto SOLO muestra los comandos. Usa --yes para ejecutarlos.
set -euo pipefail

YES=0
PDF=0
for arg in "$@"; do
  case "$arg" in
    --yes|-y) YES=1 ;;
    --pdf) PDF=1 ;;
    -h|--help)
      echo "Uso: $0 [--yes] [--pdf]"
      echo "  --yes  Ejecuta los comandos (por defecto solo los muestra)."
      echo "  --pdf  Incluye pandoc y TeX Live/MacTeX para regenerar el PDF."
      exit 0 ;;
    *) echo "Argumento desconocido: $arg" >&2; exit 1 ;;
  esac
done

run() {
  printf '  %s\n' "$*"
  if [ "$YES" -eq 1 ]; then "$@"; fi
}

PY="$(command -v python3 || command -v python || true)"
OS="$(uname -s)"

echo "== Dependencias del sistema =="
case "$OS" in
  Linux)
    if command -v apt-get >/dev/null 2>&1; then
      PKGS="emacs git ripgrep python3 python3-pip python3-venv nodejs npm"
      [ "$PDF" -eq 1 ] && PKGS="$PKGS pandoc texlive-xetex texlive-fonts-recommended"
      run sudo apt-get update
      run sudo apt-get install -y $PKGS
    elif command -v dnf >/dev/null 2>&1; then
      PKGS="emacs git ripgrep python3 python3-pip nodejs npm"
      [ "$PDF" -eq 1 ] && PKGS="$PKGS pandoc texlive-xetex"
      run sudo dnf install -y $PKGS
    elif command -v pacman >/dev/null 2>&1; then
      PKGS="emacs git ripgrep python python-pip nodejs npm"
      [ "$PDF" -eq 1 ] && PKGS="$PKGS pandoc texlive-core"
      run sudo pacman -S --needed $PKGS
    else
      echo "  Gestor de paquetes no reconocido. Instala manualmente:"
      echo "  emacs git ripgrep python3 python3-pip gh"
    fi
    ;;
  Darwin)
    if ! command -v brew >/dev/null 2>&1; then
      echo "  Homebrew no está instalado: https://brew.sh"
    else
      run brew install emacs git ripgrep python gh node
      if [ "$PDF" -eq 1 ]; then
        run brew install pandoc
        run brew install --cask mactex-no-gui
      fi
    fi
    ;;
  *)
    echo "  SO no soportado por este script: $OS"
    echo "  En Windows usa: .\\scripts\\setup.ps1 -Install"
    exit 1
    ;;
esac

if ! command -v gh >/dev/null 2>&1; then
  echo "  gh no está instalado (opcional): https://cli.github.com/"
fi

echo
echo "== Paquetes de Python =="
if [ -n "$PY" ]; then
  run "$PY" -m pip install --user pytest black
else
  echo "  Python no encontrado; instálalo primero."
fi

echo
echo "== Servidor de lenguaje (Pyright) =="
if command -v pipx >/dev/null 2>&1; then
  run pipx install pyright
elif command -v npm >/dev/null 2>&1; then
  run npm install -g pyright
else
  echo "  Falta pipx o npm. Instala uno y luego: pipx install pyright"
fi

echo
if [ "$YES" -eq 0 ]; then
  echo "Modo simulación: no se instaló nada."
  echo "Ejecuta de nuevo con --yes para instalar."
else
  echo "Instalación terminada. Abre una terminal nueva si cambió el PATH."
fi
