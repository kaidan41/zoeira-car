# =============================================================
# ZOEIRA CAR  Script 4: Configurar Firestore (regras + dados iniciais)
# Faz deploy das regras e popula a coleção vehicles
# =============================================================

$projectRoot = "F:\Kiro Projetcts\zoeira_car"
Set-Location $projectRoot

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ZOEIRA CAR  Configurando Firestore" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. Cria firebase.json ──
Write-Host "[1/3] Criando firebase.json..." -ForegroundColor Yellow
$firebaseJson = @'
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  }
}
'@
Set-Content -Path "$projectRoot\firebase.json" -Value $firebaseJson -Encoding UTF8

# ── 2. Cria firestore.rules ──
Write-Host "[2/3] Criando regras do Firestore..." -ForegroundColor Yellow
$firestoreRules = @'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Veiculos: leitura publica, escrita bloqueada para clientes
    match /vehicles/{vehicleId} {
      allow read: if true;
      allow write: if false;
    }

    // Assinaturas: somente o proprio usuario logado (leitura)
    match /subscriptions/{userId} {
      allow read: if request.auth != null
                  && request.auth.uid == userId;
      allow write: if false;
    }

    // Acesso e perfil do usuario: leitura, criacao e atualizacao pelo proprio usuario
    match /users/{userId} {
      allow read: if request.auth != null
                  && request.auth.uid == userId;
      allow create, update: if request.auth != null
                            && request.auth.uid == userId;
      allow delete: if false;
    }

    // Bloqueia qualquer outra colecao por padrao
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
'@
Set-Content -Path "$projectRoot\firestore.rules" -Value $firestoreRules -Encoding UTF8

# ── 3. Cria firestore.indexes.json ──
$firestoreIndexes = @'
{
  "indexes": [],
  "fieldOverrides": []
}
'@
Set-Content -Path "$projectRoot\firestore.indexes.json" -Value $firestoreIndexes -Encoding UTF8

Write-Host "[3/3] Fazendo deploy das regras no Firebase..." -ForegroundColor Yellow
firebase deploy --only firestore:rules --project zoeira-car

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Firestore configurado!" -ForegroundColor Green
Write-Host ""
Write-Host "  PROXIMO PASSO:" -ForegroundColor Yellow
Write-Host "  Execute: scripts\5_popular_veiculos.ps1" -ForegroundColor Yellow
Write-Host "  (Vai popular o banco com os primeiros veiculos)" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Green
