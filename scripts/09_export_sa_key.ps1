# 09_export_sa_key.ps1
# Exporta a chave JSON da service account do Firebase/GCP (grátis).
# Depois rode scripts\10_deploy_worker.ps1.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$outJson = Join-Path $root 'worker\service-account.json'

$gcloud = Get-Command gcloud -ErrorAction SilentlyContinue
if (-not $gcloud) {
    Write-Host 'gcloud nao encontrado. Instalando via winget (pode levar alguns minutos)...'
    winget install -e --id Google.CloudSDK --accept-source-agreements --accept-package-agreements
    $newBin = "$env:LOCALAPPDATA\Google\Cloud SDK\google-cloud-sdk\bin"
    if (Test-Path $newBin) { $env:Path = "$newBin;$env:Path" }
    $gcloud = Get-Command gcloud -ErrorAction SilentlyContinue
    if (-not $gcloud) {
        Write-Host 'Instale manualmente: winget install -e --id Google.CloudSDK'
        exit 1
    }
}

gcloud config set project zoeira-car 2>$null | Out-Null

$acct = gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>$null
if (-not $acct) {
    Write-Host 'Fazendo login no Google (abre o navegador)...'
    gcloud auth login
    $acct = gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>$null
    if (-not $acct) { Write-Host 'Login cancelado.'; exit 1 }
}

Write-Host "Conta ativa: $acct"
try {
    gcloud iam service-accounts keys create "$outJson" `
        --iam-account "zoeira-car@appspot.gserviceaccount.com" 2>$null
} catch {
    Write-Host "[ERRO]: sua conta pode nao ter permissao para criar chaves."
    Write-Host "Alternativa manual: console.cloud.google.com -> IAM -> Contas de servico"
    Write-Host "-> zoeira-car@appspot.gserviceaccount.com -> Chaves -> Adicionar chave -> JSON"
    Write-Host "(salve o arquivo como worker\service-account.json)"
    exit 1
}

Write-Host ""
Write-Host "Chave salva em: $outJson"
Write-Host "Proximo passo: scripts\10_deploy_worker.ps1"