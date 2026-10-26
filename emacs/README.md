# Configuración de Emacs

`init.el` es una configuración **autocontenida** para probar el flujo de la guía sin tocar tu `~/.emacs.d`.

## Arrancar

```bash
emacs --init-directory /ruta/a/emacs-deepseek-assistance-tools/emacs
```

La primera vez instalará los paquetes desde MELPA en `emacs/elpa/` (ignorado por Git).

## Qué incluye

| Paquete | Para qué |
|---|---|
| `gptel` | Chat con DeepSeek, herramientas y diff |
| `lsp-mode` + `lsp-pyright` | Completado y diagnóstico de Python |
| `flycheck` | Errores en el buffer |
| `blacken` | Formato con `black` |
| `magit` | Git |
| `forge` | Issues y pull requests de GitHub |
| `diff-hl` | Cambios en el margen |
| `git-link` | Copiar URL de GitHub |

## Atajos

| Prefijo | Acciones |
|---|---|
| `C-c I` | `e` explicar, `t` tests, `i` implementar, `r` revisar, `f` refactor, `d` docstrings, `x` corregir, `p` agente, `a`/`K`/`D` aceptar/rechazar/diff, `c` chat, `m` menú, `1`/`2`/`3` modelos |
| `C-c P` | `r` ejecutar, `t` pytest, `f` black, `l` lint, `c` REPL |
| `C-c G` | `s` status, `c` commit, `p` push, `f` fetch, `l` log, `d` diff, `b` rama, `B` blame, `S` stash, `g` enlace, `F` Forge |
| `C-x g` | Magit status |

## Clave de DeepSeek

La configuración lee la clave en este orden:

1. `DEEPSEEK_API_KEY`.
2. `~/.emacs.d/.deepseek-key`.

Nunca se guarda en este repositorio.

## GitHub / Forge

Forge lee `~/.authinfo`. Usa `../scripts/setup-forge.sh` para crearlo con el token de `gh`.

## Usarla en tu Emacs personal

Copia `init.el` a `~/.emacs.d/init.el` **después de hacer una copia de seguridad**. Si ya tienes una configuración, es mejor arrancar con `--init-directory` o cargar este archivo con `emacs -Q -l init.el`.
