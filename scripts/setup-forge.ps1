$ErrorActionPreference = 'Stop'

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "Falta gh (GitHub CLI). Instálalo y ejecuta: gh auth login"
}
gh auth status
if ($LASTEXITCODE -ne 0) {
    throw "gh no está autenticado. Ejecuta: gh auth login"
}

$Login = gh api user -q .login
$Token = gh auth token
$Authinfo = Join-Path $HOME '.authinfo'

$Lines = @(
    "machine api.github.com login $Login^forge password $Token",
    "machine api.github.com login $Login^ghub password $Token"
)
Set-Content -Path $Authinfo -Value $Lines -Encoding ASCII
icacls $Authinfo /inheritance:r /grant:r "$($env:USERNAME):(R)" | Out-Null

git config --global github.user $Login

Write-Host "Listo: $Authinfo (solo tu usuario) y github.user=$Login"
Write-Host "No compartas .authinfo ni el token."
