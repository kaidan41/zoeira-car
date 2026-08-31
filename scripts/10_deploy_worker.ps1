# 10_deploy_worker.ps1
# Publica a validacao de compras no Cloudflare Workers (plano free,
# 100k req/dia) e grava a URL final em lib/utils/app_constants.dart.
#
# Pre-requisitos: rodar scripts\09_export_sa_key.ps1 antes (ou baixar
# o JSON da service account manualmente para worker\service-account.json).
# Vai pedir login no navegador no Cloudflare (gratis, sem cartao).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$workerDir = Join-Path $root 'worker'
$saJson = Join-Path $workerDir 'service-account.json'
$constants = Join-Path $root 'lib\utils\app_constants.dart'

Set-Location -LiteralPath $workerDir

Write-Host '>> Instalando dependencias do Worker...'
npm install --loglevel=error 2>$null | Out-Null

if (-not (Test-Path $saJson)) {
    Write-Host "[ERRO]: worker\service-account.json nao encontrado."
    Write-Host "Rode scripts\09_export_sa_key.ps1 primeiro."
    exit 1
}

Write-Host '>> Verificando login no Cloudflare...'
$who = npx wrangler whoami 2>$null | Out-String
if ($who -match 'not logged in|not authenticated|Login required') {
    Write-Host '>> Abrindo login do Cloudflare no navegador...'
    npx wrangler login
    if (-not $?) { exit 1 }
}

Write-Host '>> Registrando a service account como secret (PLAY_SERVICE_ACCOUNT_JSON)...'
$oneLine = Get-Content -LiteralPath $saJson -Raw | ConvertFrom-Json | ConvertTo-Json -Compress
$oneLine | npx wrangler secret put PLAY_SERVICE_ACCOUNT_JSON
if (-not $?) { exit 1 }

Write-Host '>> Publicando o Worker...'
$out = npx wrangler deploy 2>&1 | Out-String
$url = [regex]::Match($out, 'https://[a-z0-9-]+\.workers\.dev').Value
if (-not $url) {
    Write-Host $out
    Write-Host '[ERRO]: nao consegui extrair a URL do Worker no output.'
    exit 1
}

Write-Host ''
Write-Host ">> Worker no ar: $url"
$content = Get-Content -LiteralPath $constants -Raw
$updated = $content -replace 'https://zoeira-car-billing\.<SEU_ACCOUNT>\.workers\.dev', $url
if ($updated -eq $content) {
    Write-Host ">> AVISO: nao achei o placeholder na URL no app_constants.dart."
} else {
    Set-Content -LiteralPath $constants -Value $updated -NoNewline -Encoding ASCII
    Write-Host '>> URL gravada em lib/utils/app_constants.dart.'
}
Write-Host '>> Pronto! Rebuild o app e teste a compra.'