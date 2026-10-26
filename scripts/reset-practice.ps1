$ErrorActionPreference = 'Stop'

$Practice = if ($env:PRACTICE_DIR) { $env:PRACTICE_DIR } else { Join-Path $HOME 'src\ia-python-practica' }

if (-not (Test-Path (Join-Path $Practice '.git'))) {
    throw "No es un repositorio git: $Practice"
}

git -C $Practice reset --hard estado-inicial
git -C $Practice clean -fdx

Write-Host "Proyecto restaurado a estado-inicial: $Practice"
Write-Host "Estado esperado: 4 fallos, 4 aprobados."
