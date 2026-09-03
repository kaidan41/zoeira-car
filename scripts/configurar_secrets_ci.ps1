# =============================================================
# ZOEIRA CAR — Configura os secrets do GitHub Actions
# -------------------------------------------------------------
# O CI falhava porque os secrets de assinatura estavam faltando:
#   KEYSTORE_BASE64, KEY_STORE_PASSWORD, KEY_PASSWORD, KEY_ALIAS,
#   PLAY_STORE_SERVICE_ACCOUNT_JSON
#
# Este script gera os valores certos a partir do keystore LOCAL
# (android/app/zoeira_car.jks) e mostra o que colar no GitHub.
#
# Como usar:
#   1. Rode:  powershell -ExecutionPolicy Bypass -File scripts\configurar_secrets_ci.ps1
#   2. Copie o valor de KEYSTORE_BASE64 (é longo — copie tudo)
#   3. No GitHub: repo > Settings > Secrets and variables > Actions
#   4. Adicione cada secret abaixo (New repository secret)
#   5. PLAY_STORE_SERVICE_ACCOUNT_JSON: crie no Play Console
#      (Configuração > Acesso à API > Criar conta de serviço) e cole o JSON.
# =============================================================

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$keystorePath = Join-Path $projectRoot 'android\app\zoeira_car.jks'
$keyPropsPath = Join-Path $projectRoot 'android\key.properties'

if (-not (Test-Path $keystorePath)) {
    Write-Host "ERRO: keystore nao encontrado em $keystorePath" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $keyPropsPath)) {
    Write-Host "ERRO: key.properties nao encontrado em $keyPropsPath" -ForegroundColor Red
    exit 1
}

function Get-PropValue($file, $key) {
    $line = Get-Content $file | Where-Object { $_ -match "^$key=" } | Select-Object -First 1
    if ($line) { return ($line -split '=', 2)[1].Trim() }
    return ''
}

$storePass = Get-PropValue $keyPropsPath 'storePassword'
$keyPass   = Get-PropValue $keyPropsPath 'keyPassword'
$alias     = Get-PropValue $keyPropsPath 'keyAlias'
if (-not $alias) { $alias = 'zoeira_car' }

# Base64 do keystore (com quebras de linha para o GitHub aceitar em uma linha só depois)
$keystoreBytes = [System.IO.File]::ReadAllBytes($keystorePath)
$base64 = [Convert]::ToBase64String($keystoreBytes)
# Remove quebras de linha para colar como um único valor
$base64 = $base64 -replace "`r", '' -replace "`n", ''

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  COPIE OS VALORES ABAIXO PARA O GITHUB (Settings > Secrets)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Secret: KEYSTORE_BASE64" -ForegroundColor Yellow
Write-Host $base64
Write-Host ""
Write-Host "Secret: KEY_STORE_PASSWORD" -ForegroundColor Yellow
Write-Host $storePass
Write-Host ""
Write-Host "Secret: KEY_PASSWORD" -ForegroundColor Yellow
Write-Host $keyPass
Write-Host ""
Write-Host "Secret: KEY_ALIAS" -ForegroundColor Yellow
Write-Host $alias
Write-Host ""
Write-Host "Secret: PLAY_STORE_SERVICE_ACCOUNT_JSON" -ForegroundColor Yellow
Write-Host "  (coloque o JSON inteiro da conta de servico criada no Play Console)"
Write-Host ""
Write-Host "Depois rode o workflow em: Actions > Deploy Play Store (Teste Interno) > Run workflow (track: internal)" -ForegroundColor Green