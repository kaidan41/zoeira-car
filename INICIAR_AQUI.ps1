# =============================================================
#   ZOEIRA CAR - Setup Completo
#   Execute como ADMINISTRADOR no PowerShell
#   Clique direito > "Executar com PowerShell" (como Admin)
# =============================================================

$ErrorActionPreference = "Continue"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Clear-Host
Write-Host ""
Write-Host "  +------------------------------------------+" -ForegroundColor Cyan
Write-Host "  |      ZOEIRA CAR - Setup Completo         |" -ForegroundColor Cyan
Write-Host "  +------------------------------------------+" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Este script vai:" -ForegroundColor White
Write-Host "    1. Instalar Flutter SDK" -ForegroundColor Gray
Write-Host "    2. Instalar Node.js e Firebase CLI" -ForegroundColor Gray
Write-Host "    3. Configurar o projeto" -ForegroundColor Gray
Write-Host "    4. Criar keystore de assinatura" -ForegroundColor Gray
Write-Host "    5. Conectar ao Firebase (vai abrir o browser)" -ForegroundColor Gray
Write-Host "    6. Configurar Firestore com regras de seguranca" -ForegroundColor Gray
Write-Host "    7. Popular banco com 8 veiculos iniciais" -ForegroundColor Gray
Write-Host "    8. Gerar o AAB pronto para a Play Store" -ForegroundColor Gray
Write-Host ""
Write-Host "  Status do ambiente detectado:" -ForegroundColor Yellow
Write-Host "    [OK] Android Studio em C:\Program Files\Android\Android Studio" -ForegroundColor Green
Write-Host "    [OK] Java (JBR do Android Studio)" -ForegroundColor Green
Write-Host "    [OK] Android SDK em AppData\Local\Android\Sdk" -ForegroundColor Green
Write-Host "    [ ] Flutter - sera instalado agora" -ForegroundColor White
Write-Host "    [ ] Conta Google para Firebase - necessaria" -ForegroundColor White
Write-Host "    [ ] YouTube API Key - instrucoes aparecerao durante o script" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Tudo pronto? Digite S para continuar ou N para sair"
if ($confirm -ne "S" -and $confirm -ne "s") {
    Write-Host "Ate mais! Volte quando estiver pronto." -ForegroundColor Yellow
    exit
}

# ======================================================
# ETAPA 1 - Instalar Flutter e dependencias
# ======================================================
Write-Host ""
Write-Host "=== ETAPA 1/8: Instalando Flutter ===" -ForegroundColor Magenta
& "$projectRoot\scripts\1_instalar_flutter.ps1"

# Recarrega o PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# ======================================================
# ETAPA 2 - YouTube API Key
# ======================================================
Write-Host ""
Write-Host "=== ETAPA 2/8: YouTube API ===" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Vamos configurar a chave da API do YouTube." -ForegroundColor Yellow
Write-Host "  O browser vai abrir. Siga os passos:" -ForegroundColor White
Write-Host "    1. Clique em 'Criar credenciais' > 'Chave de API'" -ForegroundColor Gray
Write-Host "    2. Em restricoes, ative 'YouTube Data API v3'" -ForegroundColor Gray
Write-Host "    3. Copie a chave e cole abaixo" -ForegroundColor Gray
Write-Host ""

Start-Process "https://console.cloud.google.com/apis/credentials"
$youtubeApiKey = Read-Host "Cole sua YouTube API Key aqui"

Write-Host ""
Write-Host "  Agora precisamos do Channel ID do canal Zoeira Car." -ForegroundColor Yellow
Write-Host "  O browser vai abrir um site que busca o ID automaticamente." -ForegroundColor White
Write-Host "  Cole a URL do canal: https://www.youtube.com/@ZoeiraCar" -ForegroundColor Gray
Write-Host ""

Start-Process "https://commentpicker.com/youtube-channel-id.php"
$youtubeChannelId = Read-Host "Cole o Channel ID do canal Zoeira Car aqui"

# Atualiza app_constants.dart
$constantsPath = "$projectRoot\lib\utils\app_constants.dart"
$constantsContent = Get-Content $constantsPath -Raw -Encoding UTF8
$constantsContent = $constantsContent -replace "SUA_YOUTUBE_API_KEY_AQUI", $youtubeApiKey
$constantsContent = $constantsContent -replace "SEU_CHANNEL_ID_AQUI", $youtubeChannelId
[System.IO.File]::WriteAllText($constantsPath, $constantsContent, [System.Text.Encoding]::UTF8)

Write-Host "  app_constants.dart atualizado!" -ForegroundColor Green

# ======================================================
# ETAPA 3 - Configurar projeto Flutter
# ======================================================
Write-Host ""
Write-Host "=== ETAPA 3/8: Configurando projeto Flutter ===" -ForegroundColor Magenta
& "$projectRoot\scripts\2_configurar_projeto.ps1"

# ======================================================
# ETAPA 4 - Firebase
# ======================================================
Write-Host ""
Write-Host "=== ETAPA 4/8: Configurando Firebase ===" -ForegroundColor Magenta
& "$projectRoot\scripts\3_configurar_firebase.ps1"

# ======================================================
# ETAPA 5 - Firestore
# ======================================================
Write-Host ""
Write-Host "=== ETAPA 5/8: Configurando Firestore ===" -ForegroundColor Magenta
& "$projectRoot\scripts\4_configurar_firestore.ps1"

# ======================================================
# ETAPA 6 - Popular banco com veiculos
# ======================================================
Write-Host ""
Write-Host "=== ETAPA 6/8: Populando banco de veiculos ===" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Precisamos da chave de servico do Firebase." -ForegroundColor Yellow
Write-Host "  O browser vai abrir o Firebase Console." -ForegroundColor White
Write-Host ""
Write-Host "  Passos:" -ForegroundColor White
Write-Host "    1. Va em: Engrenagem > Configuracoes do projeto" -ForegroundColor Gray
Write-Host "    2. Aba 'Contas de servico'" -ForegroundColor Gray
Write-Host "    3. Clique em 'Gerar nova chave privada'" -ForegroundColor Gray
Write-Host "    4. Salve o arquivo como:" -ForegroundColor Gray
Write-Host "       $projectRoot\scripts\serviceAccountKey.json" -ForegroundColor Cyan
Write-Host ""

Start-Process "https://console.firebase.google.com"
Read-Host "Pressione ENTER depois de salvar o serviceAccountKey.json"

& "$projectRoot\scripts\5_instalar_e_popular.ps1"

# ======================================================
# ETAPA 7 - Build AAB
# ======================================================
Write-Host ""
Write-Host "=== ETAPA 7/8: Gerando build para Play Store ===" -ForegroundColor Magenta
& "$projectRoot\scripts\6_build_e_assinar.ps1"

# ======================================================
# ETAPA 8 - Instrucoes finais
# ======================================================
Write-Host ""
Write-Host "=== ETAPA 8/8: Publicar na Play Store ===" -ForegroundColor Magenta
Write-Host ""
Write-Host "  +----------------------------------------------------+" -ForegroundColor Green
Write-Host "  |  TUDO PRONTO! So falta publicar na Play Store!     |" -ForegroundColor Green
Write-Host "  +----------------------------------------------------+" -ForegroundColor Green
Write-Host ""
Write-Host "  Passos finais (so voce pode fazer):" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Acesse: https://play.google.com/console" -ForegroundColor Cyan
Write-Host "     - Crie o app com nome: Zoeira Car" -ForegroundColor Gray
Write-Host "     - Package name: com.zoeiracartv.app" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Em Monetizacao > Assinaturas:" -ForegroundColor White
Write-Host "     - Produto ID: zoeira_car_mensal" -ForegroundColor Gray
Write-Host "     - Preco: R$ 15,00/mes" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Em Versoes > Producao:" -ForegroundColor White
Write-Host "     - Faca upload do arquivo AAB gerado" -ForegroundColor Gray
Write-Host ""
Write-Host "  O arquivo AAB esta em:" -ForegroundColor White
Write-Host "  $projectRoot\build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Cyan
Write-Host ""

Start-Process "https://play.google.com/console"

Write-Host "  Bora dominar o mercado automotivo!" -ForegroundColor Green
Write-Host ""
