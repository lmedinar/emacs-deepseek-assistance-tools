param(
    [switch]$Install
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Practice = if ($env:PRACTICE_DIR) { $env:PRACTICE_DIR } else { Join-Path $HOME 'src\ia-python-practica' }

Write-Host "== Herramientas =="
$required = @('git', 'python', 'py', 'pytest', 'black', 'rg', 'pyright')
$missing = @()
foreach ($cmd in $required) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        Write-Host "  ok: $cmd"
    } else {
        Write-Host "  FALTA: $cmd"
        $missing += $cmd
    }
}

if ($Install) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget no está disponible. Actualiza Windows o instala las herramientas manualmente."
    }
    $pkgs = @(
        'GNU.Emacs',
        'Git.Git',
        'BurntSushi.ripgrep.MSVC',
        'Python.Python.3.12',
        'GitHub.cli',
        'OpenJS.NodeJS.LTS'
    )
    foreach ($id in $pkgs) {
        Write-Host "  winget install $id"
        winget install --id $id -e --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) { Write-Warning "winget devolvió $LASTEXITCODE para $id (¿ya instalado?)" }
    }
    $py = if (Get-Command py -ErrorAction SilentlyContinue) { 'py' } elseif (Get-Command python -ErrorAction SilentlyContinue) { 'python' } else { $null }
    if ($py) { & $py -m pip install --user pytest black }
    if (Get-Command npm -ErrorAction SilentlyContinue) { npm install -g pyright }
    Write-Host "  Abre una terminal nueva si winget cambió el PATH."
} elseif ($missing.Count -gt 0) {
    Write-Host "  Instala lo que falta con: .\scripts\setup.ps1 -Install"
}

Write-Host ""
Write-Host "== Clave de DeepSeek =="
$KeyFile = Join-Path $HOME '.emacs.d\.deepseek-key'
if ($env:DEEPSEEK_API_KEY) {
    Write-Host "  DEEPSEEK_API_KEY está definida."
} elseif (Test-Path $KeyFile) {
    Write-Host "  Usando $KeyFile"
} else {
    Write-Host "  No hay clave configurada. Haz una de estas dos cosas:"
    Write-Host "    `$env:DEEPSEEK_API_KEY = 'tu-clave'"
    Write-Host "    New-Item -ItemType Directory -Force (Split-Path $KeyFile) | Out-Null"
    Write-Host "    Set-Content -Path $KeyFile -Value 'tu-clave' -NoNewline"
}

Write-Host ""
Write-Host "== Proyecto de práctica =="
if (Test-Path $Practice) {
    Write-Host "  Ya existe: $Practice (no se toca)"
} else {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Practice) | Out-Null
    Copy-Item -Recurse -Path (Join-Path $Root 'practice') -Destination $Practice
    git -C $Practice init -q -b main
    git -C $Practice add .
    $name = if ($env:GIT_AUTHOR_NAME) { $env:GIT_AUTHOR_NAME } else { 'Práctica' }
    $email = if ($env:GIT_AUTHOR_EMAIL) { $env:GIT_AUTHOR_EMAIL } else { 'practica@example.com' }
    git -C $Practice -c "user.name=$name" -c "user.email=$email" commit -qm "Estado inicial"
    git -C $Practice tag estado-inicial
    Write-Host "  Creado: $Practice (tag estado-inicial)"
}

Write-Host ""
Write-Host "== Siguiente paso =="
Write-Host "  emacs --init-directory `"$Root\emacs`""
Write-Host "  Abre $Practice y pulsa C-c P t"
