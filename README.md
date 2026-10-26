# Emacs + DeepSeek para programación asistida

Guía práctica y configuración mínima de Emacs para programar Python con DeepSeek: chat, tests, refactor con diff, agente de proyecto y Git/GitHub.

> **Sin claves en el repositorio.** La API key vive en `DEEPSEEK_API_KEY` o en `~/.emacs.d/.deepseek-key`; el token de GitHub, en `~/.authinfo`.

## Qué incluye

- **`emacs/init.el`** — configuración autocontenida (gptel + DeepSeek, LSP/Pyright, pytest, black, Magit, Forge, diff-hl, git-link).
- **`docs/guia.md`** — guía completa, desde cero, con ejercicios.
- **`docs/instalacion.md`** — instalación paso a paso.
- **`practice/`** — proyecto de práctica (calculadora con tests en rojo).
- **`scripts/`** — instalación, token de Forge, reset y verificación.

## Requisitos

- Emacs 29 o superior (probado con 31).
- `git`, `python3`, `pytest`, `black`, `ripgrep`.
- Opcional: `gh` (GitHub CLI) para Forge y pull requests.

## Inicio rápido

```bash
git clone https://github.com/lmedinar/emacs-deepseek-assistance-tools.git
cd emacs-deepseek-assistance-tools

# 1. Clave de DeepSeek (elige una)
export DEEPSEEK_API_KEY='tu-clave'
# o:
mkdir -p ~/.emacs.d
printf '%s' 'tu-clave' > ~/.emacs.d/.deepseek-key
chmod 600 ~/.emacs.d/.deepseek-key

# 2. Proyecto de práctica
./scripts/setup.sh

# 3. Emacs con esta configuración
emacs --init-directory "$PWD/emacs"
```

Dentro de Emacs:

1. Abre `~/src/ia-python-practica/tests/test_operaciones.py`.
2. `C-c P t` → deben fallar 4 tests.
3. Sigue `docs/guia.md`.

## Atajos

| Prefijo | Para |
|---|---|
| `C-c I` | IA: explicar, tests, implementar, revisar, refactor, docstrings, corregir, agente |
| `C-c P` | Python: ejecutar, pytest, black, lint, REPL |
| `C-c G` | Git: status, commit, push, fetch, log, diff, rama, blame, stash, Forge |
| `C-x g` | Magit status |

## El ciclo

```
C-c P t   → tests en rojo
C-c I i   → la IA implementa
pegar     → aplicar
C-c P f   → black
C-c P t   → tests en verde
C-c I r   → revisión
C-c G c   → commit
```

## Agente de proyecto

`C-c I p` abre `*IA: proyecto*`. DeepSeek puede:

- listar, leer y buscar archivos;
- editar con **diff + confirmación**;
- crear archivos y borrar a la papelera;
- ejecutar pytest;
- consultar Git, hacer commit y push con confirmación.

Todo queda confinado a la raíz del proyecto. No hay shell libre.

## Seguridad

- No subas `~/.emacs.d/.deepseek-key`, `~/.authinfo` ni `.env`.
- El `.gitignore` ya excluye esos archivos.
- La config lee la clave así:

```elisp
(or (getenv "DEEPSEEK_API_KEY")
    (mi-leer-clave "~/.emacs.d/.deepseek-key"))
```

- Forge usa `~/.authinfo` con las entradas `usuario^forge` y `usuario^ghub`.
- Antes de publicar cambios:

```bash
grep -RInE "sk-|ghp_|password|api[_-]?key" . || true
```

## Estructura

```
.
├── docs/
│   ├── guia.md
│   └── instalacion.md
├── emacs/
│   ├── init.el
│   └── README.md
├── practice/
│   ├── calc/
│   ├── tests/
│   ├── pyproject.toml
│   └── scripts/reset.sh
├── scripts/
│   ├── setup.sh
│   ├── setup-forge.sh
│   ├── reset-practice.sh
│   └── check.sh
└── .github/workflows/ci.yml
```

## Repetir la guía

```bash
./scripts/reset-practice.sh
```

Vuelve al commit `estado-inicial`: **4 fallos, 4 aprobados**.

## Licencia

MIT. Ver [LICENSE](LICENSE).
