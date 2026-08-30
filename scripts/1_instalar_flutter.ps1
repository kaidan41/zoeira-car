# =============================================================
# ZOEIRA CAR  Script 1: Instalar Flutter SDK
# Execute como Administrador no PowerShell
# Android Studio ja detectado  so instala o Flutter
# =============================================================

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ZOEIRA CAR  Instalando Flutter SDK" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ── Java do Android Studio (ja instalado) ──
$jbrBin = "C:\Program Files\Android\Android Studio\jbr\bin"

# ── JDK 17 (Temurin) para o Gradle — o JBR do Android Studio é Java 25 e
#    o Gradle 8.0 (usado pelo projeto) só suporta Java 17-20 ──
$jdk17Path = "$env:LOCALAPPDATA\Eclipse Adoptium\jdk-17"
if (-not (Test-Path "$jdk17Path\bin\java.exe")) {
    Write-Host "[...] Baixando JDK 17 (Temurin) para $jdk17Path ..." -ForegroundColor Yellow
    $jdkZip = "$env:TEMP\jdk17.zip"
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile("https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse", $jdkZip)
    New-Item -ItemType Directory -Path "$env:LOCALAPPDATA\Eclipse Adoptium" -Force | Out-Null
    Expand-Archive -Path $jdkZip -DestinationPath "$env:LOCALAPPDATA\Eclipse Adoptium" -Force
    Remove-Item $jdkZip -Force
    # Adoptium extrai em pasta "jdk-17.0.x+1"; normaliza para jdk-17
    $extracted = Get-ChildItem "$env:LOCALAPPDATA\Eclipse Adoptium" -Directory | Where-Object { $_.Name -like "jdk-17*" -and $_.Name -ne "jdk-17" } | Select-Object -First 1
    if ($extracted) {
        Remove-Item "$env:LOCALAPPDATA\Eclipse Adoptium\jdk-17" -Recurse -Force -ErrorAction SilentlyContinue
        Rename-Item $extracted.FullName "jdk-17"
    }
    Write-Host "[OK] JDK 17 instalado." -ForegroundColor Green
} else {
    Write-Host "[OK] JDK 17 detectado em $jdk17Path" -ForegroundColor Green
}

# Ajusta org.gradle.java.home no gradle.properties para este PATH (por máquina)
$gradleProps = "$PSScriptRoot\..\android\gradle.properties"
$gpContent = Get-Content $gradleProps -Raw
$escaped = $jdk17Path -replace '\\','\\'
$gpNew = [regex]::Replace($gpContent, "(?m)^org\.gradle\.java\.home=.*$", "org.gradle.java.home=$escaped")
[System.IO.File]::WriteAllText($gradleProps, $gpNew, [System.Text.UTF8Encoding]::new($false))
Write-Host "[OK] gradle.properties apontado para o JDK 17." -ForegroundColor Green


Write-Host "[OK] Android Studio detectado." -ForegroundColor Green

# Adiciona o JBR do Android Studio ao PATH da sessao
if ($env:Path -notlike "*$jbrBin*") {
    $env:Path += ";$jbrBin"
    [System.Environment]::SetEnvironmentVariable(
        "Path",
        [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";$jbrBin",
        "Machine"
    )
}
# JAVA_HOME aponta para o JDK 17 (suportado pelo Gradle 8). Fallback: JBR do Studio.
$env:JAVA_HOME = $jdk17Path
if (-not (Test-Path "$env:JAVA_HOME\bin\java.exe")) { $env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr" }
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", $env:JAVA_HOME, "Machine")
Write-Host "[OK] JAVA_HOME configurado: $env:JAVA_HOME" -ForegroundColor Green

# ── Instala Flutter SDK ──
$flutterPath = "C:\flutter"
if (-not (Test-Path "$flutterPath\bin\flutter.bat")) {
    Write-Host ""
    Write-Host "[...] Baixando Flutter SDK 3.22.2 (~700MB, aguarde)..." -ForegroundColor Yellow

    $zipUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.22.2-stable.zip"
    $zipFile = "$env:TEMP\flutter.zip"

    # Baixa o Flutter
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($zipUrl, $zipFile)

    Write-Host "[...] Extraindo para C:\flutter ..." -ForegroundColor Yellow
    Expand-Archive -Path $zipFile -DestinationPath "C:\" -Force
    Remove-Item $zipFile -Force

    Write-Host "[OK] Flutter extraido!" -ForegroundColor Green
} else {
    Write-Host "[OK] Flutter ja instalado em $flutterPath" -ForegroundColor Green
}

# ── Adiciona Flutter ao PATH ──
$currentMachinePath = [System.Environment]::GetEnvironmentVariable("Path","Machine")
if ($currentMachinePath -notlike "*C:\flutter\bin*") {
    [System.Environment]::SetEnvironmentVariable(
        "Path",
        "$currentMachinePath;C:\flutter\bin",
        "Machine"
    )
    Write-Host "[OK] Flutter adicionado ao PATH do sistema." -ForegroundColor Green
} else {
    Write-Host "[OK] Flutter ja esta no PATH." -ForegroundColor Green
}
$env:Path += ";C:\flutter\bin"

# ── Instala Node.js (necessario para Firebase CLI) ──
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "[...] Baixando Node.js LTS..." -ForegroundColor Yellow

    $nodeUrl = "https://nodejs.org/dist/v20.14.0/node-v20.14.0-x64.msi"
    $nodeMsi = "$env:TEMP\nodejs.msi"
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($nodeUrl, $nodeMsi)

    Start-Process msiexec.exe -ArgumentList "/i `"$nodeMsi`" /quiet /norestart" -Wait
    Remove-Item $nodeMsi -Force

    # Recarrega PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Host "[OK] Node.js instalado!" -ForegroundColor Green
} else {
    $nodeVer = node --version
    Write-Host "[OK] Node.js ja instalado: $nodeVer" -ForegroundColor Green
}

# ── Verifica Android SDK ──
$sdkPath = "$env:LOCALAPPDATA\Android\Sdk"
if (Test-Path $sdkPath) {
    Write-Host "[OK] Android SDK detectado em: $sdkPath" -ForegroundColor Green
    $env:ANDROID_HOME = $sdkPath
    [System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $sdkPath, "Machine")
} else {
    Write-Host "[AVISO] Android SDK nao encontrado. Abra o Android Studio e instale o SDK." -ForegroundColor Yellow
}

# ── Aceita licencas Android SDK ──
Write-Host ""
Write-Host "[...] Aceitando licencas do Android SDK (responde 'y' para tudo)..." -ForegroundColor Yellow
$flutterBat = "C:\flutter\bin\flutter.bat"
if (Test-Path $flutterBat) {
    "y`ny`ny`ny`ny`ny`ny" | & $flutterBat doctor --android-licenses 2>&1 | Out-Null
    Write-Host "[OK] Licencas aceitas!" -ForegroundColor Green
}

# ── Flutter doctor para verificar status ──
Write-Host ""
Write-Host "══ Verificando instalacao com flutter doctor ══" -ForegroundColor Cyan
& "C:\flutter\bin\flutter.bat" doctor

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Flutter instalado com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "  FECHE e REABRA o PowerShell como Admin" -ForegroundColor Yellow
Write-Host "  Depois execute: INICIAR_AQUI.ps1" -ForegroundColor Yellow
Write-Host "  (ou pule para scripts\2_configurar_projeto.ps1)" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Green
