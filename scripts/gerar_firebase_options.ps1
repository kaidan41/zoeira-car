# =============================================================
# ZOEIRA CAR  Gerador de firebase_options.dart
# =============================================================
# Lê o android/app/google-services.json REAL (baixado do Firebase
# Console) e gera o lib/firebase_options.dart automaticamente.
# Nao precisa de login no browser nem do flutterfire CLI.

param(
    [string]$ProjectRoot = "F:\Kiro Projetcts\zoeira_car",
    [string]$PackageName = "com.zoeiracartv.app"
)

$ErrorActionPreference = "Stop"
Set-Location $ProjectRoot

$gsJsonPath = "$ProjectRoot\android\app\google-services.json"
if (-not (Test-Path $gsJsonPath)) {
    Write-Host "ERRO: Nao encontrei android\app\google-services.json" -ForegroundColor Red
    Write-Host "Baixe o arquivo no Firebase Console e cole nesta pasta primeiro." -ForegroundColor Yellow
    exit 1
}

$raw = [System.IO.File]::ReadAllText($gsJsonPath)

# Marker do placeholder usado para smoke test
if ($raw -match "AIzaSyDUMMY|000000000000") {
    Write-Host "ERRO: o google-services.json ainda e o PLACEHOLDER (dummy)." -ForegroundColor Red
    Write-Host "Baixe o arquivo REAL no Firebase Console: " -ForegroundColor Yellow
    Write-Host "   Firebase -> Configuracoes do projeto -> Seus apps -> Android -> Baixar google-services.json" -ForegroundColor Cyan
    Write-Host "e SOBRESCREVA android\app\google-services.json." -ForegroundColor Yellow
    exit 1
}

$json = $raw | ConvertFrom-Json

$client = $json.client | Where-Object {
    $_.client_info.android_client_info.package_name -eq $PackageName
} | Select-Object -First 1

if (-not $client) {
    Write-Host "ERRO: google-services.json nao contem o pacote $PackageName." -ForegroundColor Red
    exit 1
}

$apiKey       = $client.api_key[0].current_key
$appId        = $client.client_info.mobilesdk_app_id
$projectId    = $json.project_info.project_id
$senderId     = $json.project_info.project_number
$storageBucket = "$projectId.appspot.com"
$authDomain   = "$projectId.firebaseapp.com"

if (-not $apiKey -or -not $appId -or -not $projectId -or -not $senderId) {
    Write-Host "ERRO: google-services.json incompleto (apiKey/appId/projectId/senderId)." -ForegroundColor Red
    exit 1
}

# ── Gera o firebase_options.dart (formato do firebase_core 2.x) ──
$content = @"
// GERADO AUTOMATICAMENTE por scripts\gerar_firebase_options.ps1
// Nao edite manualmente. Rode o script de novo se trocar o google-services.json.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('App Android-only; web nao suportado.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions não está configurado para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '$apiKey',
    appId: '$appId',
    messagingSenderId: '$senderId',
    projectId: '$projectId',
    storageBucket: '$storageBucket',
    authDomain: '$authDomain',
  );
}
"@

# SEM BOM (UTF-8) para nao ter problemas com nenhuma ferramenta
[System.IO.File]::WriteAllText("$ProjectRoot\lib\firebase_options.dart", $content, [System.Text.UTF8Encoding]::new($false))

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  firebase_options.dart gerado com sucesso!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host "  projectId : $projectId" -ForegroundColor White
Write-Host "  appId     : $appId" -ForegroundColor White
Write-Host "  package   : $PackageName" -ForegroundColor White
Write-Host ""
Write-Host "  Proximo passo: aplicar as regras do Firestore" -ForegroundColor Yellow
Write-Host "  -> scripts\4_configurar_firestore.ps1 (precisa login no firebase CLI)" -ForegroundColor Yellow
Write-Host "  -> OU cole o conteudo de firestore.rules no console do Firebase" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Green