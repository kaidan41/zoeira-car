#!/usr/bin/env pwsh
<#
.SYNOPSIS
Dispara uma GitHub Action workflow manualmente

.PARAMETER Track
Track de publicação: internal, closed_testing, open_testing, production

.PARAMETER Token
GitHub Personal Access Token (ou configure via $env:GH_TOKEN)

.EXAMPLE
.\scripts\dispatch_action.ps1 -Track closed_testing -Token "ghp_xxxxx"
.\scripts\dispatch_action.ps1 -Track closed_testing  # usa $env:GH_TOKEN
#>

param(
    [ValidateSet('internal', 'closed_testing', 'open_testing', 'production')]
    [string]$Track = 'internal',
    [string]$Token
)

$ErrorActionPreference = "Stop"

# Obter token
if (-not $Token) {
    $Token = $env:GH_TOKEN
}

if (-not $Token) {
    Write-Host "❌ ERRO: Token GitHub não fornecido"
    Write-Host ""
    Write-Host "Opções:"
    Write-Host "  1. Passe -Token 'seu_token'"
    Write-Host "  2. Configure: `$env:GH_TOKEN = 'seu_token'"
    Write-Host ""
    Write-Host "Para gerar um token:"
    Write-Host "  https://github.com/settings/tokens/new"
    Write-Host "  Permissões necessárias: repo (full control)"
    exit 1
}

Write-Host "🚀 Disparando GitHub Action..."
Write-Host "Track: $Track"
Write-Host ""

$owner = "kaidan41"
$repo = "zoeira-car"
$workflow = "deploy_play_store.yaml"

$url = "https://api.github.com/repos/$owner/$repo/actions/workflows/$workflow/dispatches"

$body = @{
    ref = "main"
    inputs = @{
        track = $Track
    }
} | ConvertTo-Json

Write-Host "POST $url"
Write-Host "Body: $body"
Write-Host ""

try {
    $response = Invoke-WebRequest `
        -Uri $url `
        -Method POST `
        -UseBasicParsing `
        -Headers @{
            "Authorization" = "token $Token"
            "Accept" = "application/vnd.github.v3+json"
            "Content-Type" = "application/json"
        } `
        -Body $body `
        -ErrorAction Stop

    Write-Host "✅ Action disparada com sucesso!"
    Write-Host ""
    Write-Host "Status: $($response.StatusCode)"
    Write-Host ""
    Write-Host "Acompanhe em: https://github.com/$owner/$repo/actions"
    Write-Host ""
    Write-Host "⏱️  A action deve completar em ~5-10 minutos"
    
} catch {
    $statusCode = $_.Exception.Response.StatusCode.Value__
    $message = $_.Exception.Message
    
    Write-Host "❌ Erro ao disparar action: $message"
    
    if ($statusCode -eq 401) {
        Write-Host "   Token inválido ou expirado"
    } elseif ($statusCode -eq 404) {
        Write-Host "   Workflow não encontrado"
    } elseif ($statusCode -eq 422) {
        Write-Host "   Parâmetros inválidos"
    }
    
    exit 1
}
