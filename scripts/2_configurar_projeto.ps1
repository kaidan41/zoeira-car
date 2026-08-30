# =============================================================
# ZOEIRA CAR  Script 2: Configurar projeto Flutter + Firebase CLI
# Execute DEPOIS do script 1, com PowerShell como Administrador
# =============================================================

$ErrorActionPreference = "Continue"
$projectRoot = "F:\Kiro Projetcts\zoeira_car"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ZOEIRA CAR  Configurando projeto" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $projectRoot

# ── 1. flutter pub get ──
Write-Host "[1/6] Baixando dependencias Flutter..." -ForegroundColor Yellow
& "C:\flutter\bin\flutter.bat" pub get
Write-Host "Dependencias OK!" -ForegroundColor Green

# ── 2. Instala Firebase CLI via npm ──
Write-Host "[2/6] Instalando Firebase CLI..." -ForegroundColor Yellow
npm install -g firebase-tools
Write-Host "Firebase CLI instalado!" -ForegroundColor Green

# ── 3. Instala FlutterFire CLI ──
Write-Host "[3/6] Instalando FlutterFire CLI..." -ForegroundColor Yellow
& "C:\flutter\bin\dart.bat" pub global activate flutterfire_cli
# Garante que o dart pub global esta no PATH
$dartGlobalPath = "$env:LOCALAPPDATA\Pub\Cache\bin"
if ($env:Path -notlike "*$dartGlobalPath*") {
    $env:Path += ";$dartGlobalPath"
    [System.Environment]::SetEnvironmentVariable("Path",
        [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";$dartGlobalPath",
        "Machine")
}
Write-Host "FlutterFire CLI instalado!" -ForegroundColor Green

# ── 4. Aceita licencas Android SDK (necessario para build) ──
Write-Host "[4/6] Aceitando licencas Android SDK..." -ForegroundColor Yellow
echo "y" | & "C:\flutter\bin\flutter.bat" doctor --android-licenses 2>&1 | Out-Null
Write-Host "Licencas aceitas!" -ForegroundColor Green

# ── 5. Cria o keystore de assinatura do app ──
Write-Host "[5/6] Criando keystore de assinatura..." -ForegroundColor Yellow

$keystoreDir = "$projectRoot\android\app"
$keystorePath = "$keystoreDir\zoeira_car.jks"

if (-not (Test-Path $keystorePath)) {
    # Usa o keytool do Android Studio (ja detectado)
    $keytool = "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
    if (-not (Test-Path $keytool)) {
        # Fallback: busca keytool do Java instalado separado
        $keytool = (Get-Command keytool -ErrorAction SilentlyContinue)?.Source
    }
    if (-not $keytool) {
        $keytool = (Get-Item "C:\Program Files\Eclipse Adoptium\jdk-17*\bin\keytool.exe" -ErrorAction SilentlyContinue | Select-Object -First 1)?.FullName
    }

    if ($keytool) {
        & $keytool `
            -genkey -v `
            -keystore $keystorePath `
            -keyalg RSA `
            -keysize 2048 `
            -validity 10000 `
            -alias zoeira_car `
            -dname "CN=Zoeira Car, OU=Mobile, O=ZoeiraCarTV, L=Brasil, ST=SP, C=BR" `
            -storepass "ZoeiraCarPass2025!" `
            -keypass "ZoeiraCarPass2025!" `
            -storetype PKCS12

        Write-Host "Keystore criado em: $keystorePath" -ForegroundColor Green
    } else {
        Write-Host "keytool nao encontrado. Crie o keystore manualmente." -ForegroundColor Red
    }
} else {
    Write-Host "Keystore ja existe. OK" -ForegroundColor Green
}

# ── 6. Cria key.properties com dados do keystore ──
Write-Host "[6/6] Criando key.properties..." -ForegroundColor Yellow

$keyPropertiesPath = "$projectRoot\android\key.properties"
$keyPropertiesContent = @"
storePassword=ZoeiraCarPass2025!
keyPassword=ZoeiraCarPass2025!
keyAlias=zoeira_car
storeFile=zoeira_car.jks
storeType=pkcs12
"@

# Escreve SEM BOM (UTF-8): BOM quebraria o Properties.load do Java (primeira chave viraria nula)
[System.IO.File]::WriteAllText($keyPropertiesPath, $keyPropertiesContent, [System.Text.UTF8Encoding]::new($false))
Write-Host "key.properties criado!" -ForegroundColor Green

# Adiciona key.properties ao .gitignore
$gitignorePath = "$projectRoot\.gitignore"
$gitignoreContent = Get-Content $gitignorePath -ErrorAction SilentlyContinue
if ($gitignoreContent -notcontains "android/key.properties") {
    Add-Content -Path $gitignorePath -Value "`nandroid/key.properties`nandroid/app/zoeira_car.jks"
    Write-Host ".gitignore atualizado (keystore nao sera versionado)" -ForegroundColor Green
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Projeto configurado!" -ForegroundColor Green
Write-Host ""
Write-Host "  PROXIMO PASSO:" -ForegroundColor Yellow
Write-Host "  Execute: scripts\3_configurar_firebase.ps1" -ForegroundColor Yellow
Write-Host "  (Voce precisara estar logado no Google)" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Green
