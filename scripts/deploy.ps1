# Deploy Script - Zoeira Car
# Facilita o dispatch da GitHub Action para diferentes tracks

param(
    [ValidateSet('internal', 'alpha', 'beta', 'production')]
    [string]$Track = 'internal',
    [switch]$Help
)

if ($Help) {
    Write-Host @"
╔════════════════════════════════════════════════════════════════╗
║           Zoeira Car - Deploy via GitHub Actions              ║
╚════════════════════════════════════════════════════════════════╝

Uso:
  .\scripts\deploy.ps1 [-Track <track>] [-Help]

Opções:
  -Track      Track de publicação (padrão: internal)
              Valores: internal | alpha | beta | production
  
  -Help       Mostra este help

Exemplos:
  # Deploy pra teste interno (padrão)
  .\scripts\deploy.ps1

  # Deploy pra beta/closed testing
  .\scripts\deploy.ps1 -Track beta

  # Deploy pra production
  .\scripts\deploy.ps1 -Track production

Processo:
  1. Valida se o repositório está sincronizado
  2. Dispara a GitHub Action com o track selecionado
  3. Mostra link pro monitor do GitHub Actions

Observações:
  - A action levará ~5-10 minutos pra completar
  - O Play Console levará ~2-4h pra processar a atualização
  - Você precisa ter `gh` CLI instalado e autenticado
"@
    exit 0
}

# Verificar se gh CLI está instalado
$ghCheck = gh --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ GitHub CLI não está instalado ou não autenticado" -ForegroundColor Red
    Write-Host "   Instale em: https://cli.github.com" -ForegroundColor Yellow
    exit 1
}

Write-Host "🚀 Deploy - Zoeira Car" -ForegroundColor Cyan
Write-Host "Track: $Track" -ForegroundColor Cyan
Write-Host ""

# Verificar se está no repositório correto
if (-not (Test-Path ".git")) {
    Write-Host "❌ Erro: Não está no diretório raiz do repositório" -ForegroundColor Red
    exit 1
}

# Verificar status do git
$status = git status --porcelain
if ($status) {
    Write-Host "⚠️  Aviso: Você tem mudanças não commitadas:" -ForegroundColor Yellow
    Write-Host $status -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Deseja continuar? (s/n)"
    if ($continue -ne 's') {
        Write-Host "❌ Deploy cancelado" -ForegroundColor Red
        exit 1
    }
}

# Disparar a action
Write-Host "📤 Disparando GitHub Action..." -ForegroundColor Green

try {
    gh workflow run deploy_play_store.yaml `
        -f track=$Track `
        --repo kaidan41/zoeira-car
    
    Write-Host "✅ GitHub Action disparada com sucesso!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Monitorar progresso:" -ForegroundColor Cyan
    Write-Host "   https://github.com/kaidan41/zoeira-car/actions/workflows/deploy_play_store.yaml" -ForegroundColor Blue
    Write-Host ""
    Write-Host "⏱️  Tempo estimado: 5-10 minutos" -ForegroundColor Yellow
    Write-Host "🕐 O Play Console levará 2-4h pra processar" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Track selecionado: $Track" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Erro ao disparar GitHub Action: $_" -ForegroundColor Red
    exit 1
}
