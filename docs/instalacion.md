# Instalación

Esta configuración está pensada para probarse **sin tocar tu configuración personal** de Emacs. Usa `--init-directory` para arrancar con una carpeta de usuario independiente.

## 1. Requisitos

| Herramienta | Qué es | Para qué | Comprobar |
|---|---|---|---|
| **Emacs 29+** | Editor | gptel, Magit, LSP y la guía | `emacs --version` |
| **Python 3.10+** | Intérprete | Proyecto y tests | `python3 --version` (Windows: `py --version`) |
| **pytest** | Ejecutor de tests | Ciclo rojo → verde | `python3 -m pytest --version` |
| **black** | Formateador automático | Estilo único; no busca bugs | `black --version` |
| **Pyright** | Servidor de lenguaje (LSP) | Autocompletado, diagnósticos, ir a definición | `pyright --version` |
| **ripgrep (`rg`)** | Buscador rápido | Lo usa el agente | `rg --version` |
| **git** | Control de versiones | Magit, commits, ramas | `git --version` |
| **gh** (opcional) | GitHub CLI | Forge, PRs y CI | `gh --version` |
| **pandoc + xelatex** (opcional) | Markdown → PDF | Regenerar la guía | `pandoc --version` |

**Qué instala cada cosa:**

- `emacs/init.el` instala los **paquetes de Emacs** desde MELPA (`gptel`, `lsp-mode`, `lsp-pyright`, `magit`, `forge`, etc.).
- `scripts/install-deps.sh --yes` (Linux/macOS) o `scripts/setup.ps1 -Install` (Windows) instalan las **herramientas del sistema**, `pytest`, `black` y `pyright`.
- `scripts/setup.sh` / `scripts/setup.ps1` **solo comprueban** y crean el proyecto de práctica; no instalan por defecto.

> **black vs LSP:** `black` reescribe el código (formato). **Pyright** es el servidor de lenguaje: diagnostics, autocompletado, navegación. No se sustituyen.

### Linux (Debian/Ubuntu)

```bash
sudo apt update
sudo apt install emacs git ripgrep python3 python3-pip gh nodejs npm
python3 -m pip install --user pytest black
npm install -g pyright
```

### Arch Linux

```bash
sudo pacman -S --needed emacs git ripgrep python python-pip nodejs npm github-cli
python -m pip install --user pytest black
npm install -g pyright
```

### macOS (Homebrew)

```bash
brew install emacs git ripgrep python gh node
python3 -m pip install --user pytest black
npm install -g pyright
```

### Windows (PowerShell)

```powershell
winget install -e --id GNU.Emacs
winget install -e --id Git.Git
winget install -e --id BurntSushi.ripgrep.MSVC
winget install -e --id Python.Python.3.12
winget install -e --id GitHub.cli
winget install -e --id OpenJS.NodeJS.LTS
py -m pip install --user pytest black
npm install -g pyright
```

> En Windows usa `py` o `python`; la config detecta el ejecutable. Los scripts `.sh` requieren Git Bash/WSL; los `.ps1` están incluidos.

O deja que el repo lo haga por ti:

```bash
./scripts/install-deps.sh --yes   # Linux/macOS
```
```powershell
.\scripts\setup.ps1 -Install      # Windows
```

## 2. Clonar el repositorio

```bash
git clone https://github.com/lmedinar/emacs-deepseek-assistance-tools.git
cd emacs-deepseek-assistance-tools
```

## 3. Clave de DeepSeek

Elige **una** de las dos formas.

**Variable de entorno** (para la sesión actual):

```bash
export DEEPSEEK_API_KEY='tu-clave'
```

Para que persista, añádela a `~/.bashrc` o `~/.zshrc` (sin compartir el archivo).

**Archivo local** (recomendado para uso diario):

```bash
mkdir -p ~/.emacs.d
printf '%s' 'tu-clave' > ~/.emacs.d/.deepseek-key
chmod 600 ~/.emacs.d/.deepseek-key
```

La configuración lee primero `DEEPSEEK_API_KEY` y, si no existe, el archivo.

> **Aviso:** Nunca pongas la clave en `init.el`, en el README ni en un commit.

**Windows (PowerShell):**

```powershell
New-Item -ItemType Directory -Force "$HOME\.emacs.d" | Out-Null
Set-Content -Path "$HOME\.emacs.d\.deepseek-key" -Value 'tu-clave' -NoNewline
```

## 4. GitHub y Forge (opcional)

Forge permite ver issues y pull requests dentro de Magit.

```bash
gh auth login
./scripts/setup-forge.sh
```

**Windows:**

```powershell
gh auth login
.\scripts\setup-forge.ps1
```

El script crea `~/.authinfo` con permisos `600` y dos entradas:

```
machine api.github.com login TU_USUARIO^forge password TU_TOKEN
machine api.github.com login TU_USUARIO^ghub  password TU_TOKEN
```

También configura `github.user` en Git, que `ghub` necesita para saber el usuario.

> **Importante:** No compartas `~/.authinfo`. El token da acceso a tu cuenta de GitHub.

## 5. Proyecto de práctica

```bash
./scripts/setup.sh
```

**Windows:**

```powershell
.\scripts\setup.ps1
```

El script:

1. Comprueba las herramientas.
2. Copia `practice/` a `~/src/ia-python-practica`.
3. Inicializa Git, hace el primer commit y crea la etiqueta `estado-inicial`.

Si la carpeta ya existe, no la toca.

Al usar el agente (`C-c I p`), se crea `<proyecto>/.emacs-deepseek/` con `contexto.md` y `proyecto.md`. Está ignorado por Git (`.emacs-deepseek/.gitignore` contiene `*`) y no guarda claves.

## 6. Abrir Emacs con esta configuración

```bash
emacs --init-directory "$PWD/emacs"
```

**Windows (PowerShell):**

```powershell
emacs --init-directory "$PWD\emacs"
```

La primera vez, `use-package` descargará gptel, Magit, Forge, LSP, etc. Puede tardar unos minutos.

Dentro de Emacs:

```
C-x C-f ~/src/ia-python-practica/tests/test_operaciones.py RET
C-c P t
```

Deben fallar **4 tests** y pasar **4**. Ese es el punto de partida.

## 7. Usar la configuración en tu Emacs personal

Tienes dos opciones:

**Copiar el archivo:**

```bash
cp emacs/init.el ~/.emacs.d/init.el
```

**Cargarlo solo cuando lo necesites:**

```bash
emacs -Q -l "$PWD/emacs/init.el"
```

> **Aviso:** Si ya tienes un `~/.emacs.d/init.el`, no lo sobrescribas sin hacer una copia. Esta config está pensada para arrancar en una carpeta separada con `--init-directory`.

## 8. Verificar

```bash
./scripts/check.sh
```

**Windows:**

```powershell
.\scripts\check.ps1
```

Comprueba:

- sintaxis de los scripts;
- que Emacs carga la config y define el backend y las herramientas;
- que el proyecto de práctica sigue en rojo (4 fallos).

## 9. Generar el PDF (opcional)

El PDF ya está incluido en `docs/guia.pdf`. Para regenerarlo necesitas **pandoc** y **xelatex**:

```bash
./scripts/build-pdf.sh
```

Si no tienes pandoc instalado, descarga el binario estático y pásalo con `PANDOC`:

```bash
PANDOC=/ruta/a/pandoc ./scripts/build-pdf.sh
```

El script quita el título y el índice manual del Markdown (pandoc genera la portada y el índice) y produce un A4 con resaltado de código.

## 10. Repetir la guía

```bash
./scripts/reset-practice.sh
```

**Windows:**

```powershell
.\scripts\reset-practice.ps1
```

Vuelve a `estado-inicial`:

```bash
git -C ~/src/ia-python-practica reset --hard estado-inicial
git -C ~/src/ia-python-practica clean -fdx
```

## Seguridad

- `.gitignore` excluye `*.key`, `.env`, `.authinfo` y `.authinfo.gpg`.
- La config pública no contiene claves.
- Antes de publicar cambios:

```bash
grep -RInE "sk-|ghp_|password|api[_-]?key" . || true
```

- Si una clave se filtró, revócala y genera otra.

## Problemas comunes

**`emacs --init-directory` no encuentra paquetes.**
La primera ejecución instala desde MELPA. Comprueba tu conexión y vuelve a abrir.

**`pytest` no se encuentra.**
`python3 -m pytest --version`. La config usa `python3 -m pytest`, no el binario suelto.

**Forge no lista issues/PRs.**
Revisa `~/.authinfo`, sus permisos (`600`) y que `gh auth status` funcione. Luego, en Magit, `'` → **Add repository** → **Pull**.

**El agente dice que la ruta está fuera del proyecto.**
Abre `C-c I p` desde un archivo dentro del proyecto. La raíz se fija al abrir el agente.

**La clave no se lee.**
Comprueba `echo $DEEPSEEK_API_KEY` o `wc -c ~/.emacs.d/.deepseek-key` (debe tener la clave, sin saltos de línea).
