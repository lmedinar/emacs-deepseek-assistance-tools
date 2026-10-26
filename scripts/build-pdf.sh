#!/usr/bin/env bash
# Genera docs/guia.pdf a partir de docs/guia.md.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PANDOC="${PANDOC:-pandoc}"

if ! command -v "$PANDOC" >/dev/null 2>&1; then
  echo "Falta pandoc. Instálalo con tu gestor de paquetes o define PANDOC=/ruta/a/pandoc." >&2
  echo "Binario estático: https://github.com/jgm/pandoc/releases/latest" >&2
  exit 1
fi

if ! command -v xelatex >/dev/null 2>&1; then
  echo "Falta xelatex (TeX Live). Instala texlive-xetex y las fuentes DejaVu." >&2
  exit 1
fi

TMP="$(mktemp --suffix=.md)"
trap 'rm -f "$TMP"' EXIT

python3 - "$ROOT/docs/guia.md" "$TMP" <<'PY'
import sys

src, dst = sys.argv[1], sys.argv[2]
text = open(src, encoding="utf-8").read()
lines = text.splitlines()

# Quitar el H1: el título lo pone la portada de pandoc.
if lines and lines[0].startswith("# "):
    lines = lines[1:]
    while lines and not lines[0].strip():
        lines.pop(0)

# Quitar el índice manual: pandoc genera el suyo con --toc.
out = []
skip = False
for ln in lines:
    if ln.strip() == "## Índice":
        skip = True
        continue
    if skip:
        if ln.strip() == "---":
            skip = False
        continue
    out.append(ln)

open(dst, "w", encoding="utf-8").write("\n".join(out) + "\n")
PY

"$PANDOC" "$TMP" -o "$ROOT/docs/guia.pdf" \
  --pdf-engine=xelatex \
  --toc --toc-depth=2 \
  --highlight-style=tango \
  --standalone \
  --metadata title="Programación asistida por IA en Emacs (Python)" \
  --metadata subtitle="Guía y ejercicios" \
  --metadata author="Luis A. Medina" \
  --metadata date="$(date +%Y-%m-%d)" \
  --metadata lang=es \
  -V geometry:margin=2.5cm \
  -V mainfont="DejaVu Sans" \
  -V monofont="JetBrainsMono Nerd Font Mono" \
  -V fontsize=11pt \
  -V colorlinks=true \
  -V linkcolor=blue \
  -V urlcolor=blue \
  -V toccolor=black \
  -V titlepage \
  -V papersize=a4

echo "Generado: $ROOT/docs/guia.pdf"
