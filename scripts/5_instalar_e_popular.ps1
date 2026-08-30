# =============================================================
# ZOEIRA CAR  Script 5b: Instala dependências e roda o seed
# =============================================================

$projectRoot = "F:\Kiro Projetcts\zoeira_car"

# ── Localiza o Node.js (winget ou installers padrões) e adiciona ao PATH ──
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

Set-Location "$projectRoot\scripts"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ZOEIRA CAR  Populando banco de veiculos" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Verifica se serviceAccountKey.json existe
if (-not (Test-Path "$projectRoot\scripts\serviceAccountKey.json")) {
    Write-Host ""
    Write-Host "ATENCAO: Arquivo serviceAccountKey.json nao encontrado!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Para baixar a chave de servico:" -ForegroundColor Yellow
    Write-Host "  1. Acesse: https://console.firebase.google.com" -ForegroundColor White
    Write-Host "  2. Seu projeto (zoeira-car)" -ForegroundColor White
    Write-Host "  3. Icone de engrenagem > Configuracoes do projeto" -ForegroundColor White
    Write-Host "  4. Aba 'Contas de servico'" -ForegroundColor White
    Write-Host "  5. Clique em 'Gerar nova chave privada'" -ForegroundColor White
    Write-Host "  6. Salve o arquivo como:" -ForegroundColor White
    Write-Host "     $projectRoot\scripts\serviceAccountKey.json" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Pressiona ENTER depois de salvar o arquivo"
}

# Instala firebase-admin (v12, fixada no package.json) via npm
Write-Host "Instalando firebase-admin..." -ForegroundColor Yellow
npm install --no-audit --no-fund

# Roda o script de seed
Write-Host "Populando o Firestore..." -ForegroundColor Yellow
node "$projectRoot\scripts\5_popular_veiculos.js"

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Banco populado!" -ForegroundColor Green
Write-Host "  PROXIMO PASSO:" -ForegroundColor Yellow
Write-Host "  Execute: scripts\6_build_e_assinar.ps1" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Green
