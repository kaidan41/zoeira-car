# =============================================================
# ZOEIRA CAR  Script 6: Build Release + AAB assinado para Play Store
# =============================================================

$projectRoot = "F:\Kiro Projetcts\zoeira_car"
Set-Location $projectRoot

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ZOEIRA CAR  Build para Play Store" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ── Verifica se build.gradle tem a configuração de assinatura ──
$buildGradlePath = "$projectRoot\android\app\build.gradle"
$buildGradleContent = Get-Content $buildGradlePath -Raw -ErrorAction SilentlyContinue

if ($buildGradleContent -and $buildGradleContent -notlike "*signingConfigs*") {
    Write-Host ""
    Write-Host "ATENCAO: O build.gradle nao contem a configuracao de assinatura." -ForegroundColor Red
    Write-Host "Rode o 'scripts/2_configurar_projeto.ps1' (ou corriga o build.gradle)" -ForegroundColor Red
    Write-Host "antes de rodar este script. Abortando para nao corromper o projeto." -ForegroundColor Red
    Write-Host ""
    exit 1
}

# ── Limpa build anterior ──
Write-Host "[1/3] Limpando build anterior..." -ForegroundColor Yellow
& "C:\flutter\bin\flutter.bat" clean

# ── Atualiza dependências ──
Write-Host "[2/3] Atualizando dependencias..." -ForegroundColor Yellow
& "C:\flutter\bin\flutter.bat" pub get

# ── Gera o AAB assinado ──
Write-Host "[3/3] Gerando AAB para Play Store (pode demorar ~5 min)..." -ForegroundColor Yellow
& "C:\flutter\bin\flutter.bat" build appbundle --release

$aabPath = "$projectRoot\build\app\outputs\bundle\release\app-release.aab"

if (Test-Path $aabPath) {
    $aabSize = [math]::Round((Get-Item $aabPath).Length / 1MB, 2)

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  BUILD CONCLUIDO COM SUCESSO!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Arquivo AAB gerado:" -ForegroundColor White
    Write-Host "  $aabPath" -ForegroundColor Cyan
    Write-Host "  Tamanho: ${aabSize}MB" -ForegroundColor White
    Write-Host ""
    Write-Host "  ULTIMO PASSO:" -ForegroundColor Yellow
    Write-Host "  Sobe o AAB na Google Play Console:" -ForegroundColor White
    Write-Host "  https://play.google.com/console" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Green

    # Abre a pasta do AAB no Explorer
    explorer.exe (Split-Path $aabPath)

} else {
    Write-Host ""
    Write-Host "ERRO: AAB nao foi gerado." -ForegroundColor Red
    Write-Host "Verifique os erros acima e tente novamente." -ForegroundColor Red
}
