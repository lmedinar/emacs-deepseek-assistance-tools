#!/usr/bin/env bash
# Configura el token de GitHub para Forge/ghub en ~/.authinfo.
set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "Falta gh (GitHub CLI). Instálalo y ejecuta: gh auth login" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh no está autenticado. Ejecuta: gh auth login" >&2
  exit 1
fi

LOGIN="$(gh api user -q .login)"
TOKEN="$(gh auth token)"

umask 077
{
  printf 'machine api.github.com login %s^forge password %s\n' "$LOGIN" "$TOKEN"
  printf 'machine api.github.com login %s^ghub password %s\n' "$LOGIN" "$TOKEN"
} > "$HOME/.authinfo"
chmod 600 "$HOME/.authinfo"

git config --global github.user "$LOGIN" 2>/dev/null || true

echo "Listo: ~/.authinfo (600) y github.user=$LOGIN"
echo "No compartas ~/.authinfo ni el token."
