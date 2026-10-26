$ErrorActionPreference = 'Stop'

$Practice = Split-Path -Parent $PSScriptRoot

if (Test-Path (Join-Path $Practice '.git')) {
    git -C $Practice reset --hard estado-inicial
    git -C $Practice clean -fdx
} else {
    Write-Host "El proyecto aún no es un repositorio git; no hay nada que resetear."
}

Write-Host "Proyecto restaurado a estado-inicial."
Write-Host "Estado esperado: 4 fallos, 4 aprobados."
