$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot

Write-Host "== Sintaxis PowerShell =="
$scripts = @(Get-ChildItem (Join-Path $Root 'scripts\*.ps1') -ErrorAction SilentlyContinue)
$scripts += @(Get-ChildItem (Join-Path $Root 'practice\scripts\*.ps1') -ErrorAction SilentlyContinue)
foreach ($script in $scripts) {
    [scriptblock]::Create((Get-Content $script.FullName -Raw)) | Out-Null
}
Write-Host "  ok"

Write-Host ""
Write-Host "== Python =="
$py = if (Get-Command py -ErrorAction SilentlyContinue) { 'py' } elseif (Get-Command python -ErrorAction SilentlyContinue) { 'python' } else { $null }
if (-not $py) {
    Write-Warning "Python no encontrado; se omite compileall/pytest."
    exit 0
}

& $py -m compileall -q (Join-Path $Root 'practice')
Write-Host "  ok"

Write-Host ""
Write-Host "== pytest (esperado: 4 fallos) =="
Push-Location (Join-Path $Root 'practice')
try {
    & $py -m pytest -q
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  (fallos esperados: el proyecto arranca en rojo)"
    }
} finally {
    Pop-Location
}
exit 0
