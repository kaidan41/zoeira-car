# =============================================================
# ZOEIRA CAR  Script 3: Gerar firebase_options.dart
# =============================================================
# Deixa o google-services.json REAL em android/app e roda o gerador.
# Nao precisa de login no browser nem do flutterfire CLI.

$projectRoot = "F:\Kiro Projetcts\zoeira_car"
Set-Location $projectRoot

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ZOEIRA CAR  Firebase - firebase_options.dart" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "PASSO 1 (voce): baixe o google-services.json REAL" -ForegroundColor Yellow
Write-Host "  Firebase Console -> seu projeto -> Configuracoes do projeto" -ForegroundColor White
Write-Host "  -> Seus apps -> Android (com.zoeiracartv.app) -> Baixar google-services.json" -ForegroundColor White
Write-Host "  -> coloque em: android\app\google-services.json (substituindo o placeholder)" -ForegroundColor White
if (-not (Test-Path "android\app\google-services.json")) {
    Write-Host ""
    Write-Host "  Ainda nao encontraste o arquivo. Poe ele na pasta e roda este script de novo." -ForegroundColor Red
    exit 1
}
Write-Host ""
Write-Host "PASSO 2: gerando firebase_options.dart..." -ForegroundColor Yellow
& "$PSScriptRoot\gerar_firebase_options.ps1" -ProjectRoot $projectRoot