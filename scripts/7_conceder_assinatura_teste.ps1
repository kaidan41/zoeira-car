# =============================================================
# ZOEIRA CAR  Script 7: Conceder assinatura de TESTE no Firestore
# =============================================================
# Desbloqueia o conteudo premium (assinatura) para o usuario de
# teste no Firestore — sem precisar comprar na Play Store.
# Pré-requisitos (1 vez):
#   1. npm install firebase-admin   (dentro de scripts/)
#   2. Firebase Console > Configurações > Contas de serviço >
#      "Gerar nova chave privada" > salvar como scripts/serviceAccountKey.json

$projectRoot = "F:\Kiro Projetcts\zoeira_car"

# ── Localiza o Node.js (instalado via winget ou installers padrões) e adiciona ao PATH ──
$nodeFound = $false
$candidates = @(
    "$env:ProgramFiles\nodejs\node.exe",
    "${env:ProgramFiles(x86)}\nodejs\node.exe",
    "$env:LOCALAPPDATA\Programs\nodejs\node.exe"
) + (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "node.exe" -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match "node-v" } | Select-Object -ExpandProperty FullName)
foreach ($c in $candidates) {
    if ($c -and (Test-Path $c)) { $env:Path += ";" + (Split-Path $c); $nodeFound = $true; break }
}
if (-not $nodeFound) {
    Write-Host "ERRO: Node.js nao encontrado. Instale com:" -ForegroundColor Red
    Write-Host "  winget install OpenJS.NodeJS.LTS --scope user" -ForegroundColor Yellow
    exit 1
}

Set-Location $projectRoot

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ZOEIRA CAR  Assinatura de TESTE" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path "scripts\serviceAccountKey.json")) {
    Write-Host "ERRO: falta scripts\serviceAccountKey.json" -ForegroundColor Red
    Write-Host "  Baixe no Firebase Console -> Configurações -> Contas de serviço" -ForegroundColor Yellow
    Write-Host "  -> 'Gerar nova chave privada' -> salve como scripts\serviceAccountKey.json" -ForegroundColor Yellow
    exit 1
}

Push-Location scripts
if (-not (Test-Path "node_modules\firebase-admin")) {
    Write-Host "Instalando firebase-admin (v12, uma vez)... " -ForegroundColor Yellow
    npm install --no-audit --no-fund
}
Pop-Location

Write-Host "Concedendo assinatura de teste para o usuario..." -ForegroundColor Yellow
node scripts/conceder_assinatura_teste.js