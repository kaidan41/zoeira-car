# Zoeira Car — Setup e Deploy

## Pré-requisitos

- Flutter SDK 3.22.2 (`C:\flutter`)
- Android Studio com Android SDK 34+
- **JDK 17** (Temurin) — o JBR do Android Studio é Java 25 e o Gradle 8.0 não suporta.
  O script 1 baixa e instala em `%LOCALAPPDATA%\Eclipse Adoptium\jdk-17` e aponta
  `org.gradle.java.home` no `android/gradle.properties`.
- Conta Google Play Console ativa
- Projeto Firebase criado

---

## 1. Firebase

### 1.1 Criar projeto
1. Acesse https://console.firebase.google.com
2. Crie um novo projeto: **zoeira-car**
3. Ative **Authentication** (método: E-mail/Senha)
4. Ative **Cloud Firestore** (modo de produção)

### 1.2 Gerar firebase_options.dart
Baixe o `google-services.json` REAL no Firebase Console (Configurações do projeto →
Seus apps → Android → Baixar `google-services.json`) e coloque em `android/app/`
(substitui o placeholder). Depois rode:
```bash
scripts\3_configurar_firebase.ps1
```
Ele gera o `lib/firebase_options.dart` automaticamente — sem login no browser.
Alternativa manual: `dart pub global activate flutterfire_cli; flutterfire configure`.

### 1.3 Regras do Firestore
```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Veículos: leitura pública, escrita apenas admin
    match /vehicles/{vehicleId} {
      allow read: if true;
      allow write: if false;
    }
    // Assinaturas: somente o próprio usuário
    match /subscriptions/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    // Acesso a consultas: somente o próprio usuário
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```
Colar o conteúdo de `firestore.rules` no console (Firestore → Regras) e **publicar**.

---

## 2. Vídeos do canal (sem API key)

O app busca os vídeos via **RSS público do YouTube** (últimas 15 postagens, com views),
sem chave de API. Só o `youtubeChannelId` é usado (`lib/utils/app_constants.dart`,
já preenchido com `UCJHq9RfDWdnnI_eJV-_C13g`). Se um dia quiser histórico completo,
ativa a **YouTube Data API v3** e preenche `youtubeApiKey`.

---

## 3. Google Play Billing (modelo híbrido: assinatura + consulta avulsa)

### 3.1 Produtos na Play Console
1. Play Console → Seu app → Monetização → Produtos:
   - **Assinatura** `zoeira_car_mensal` — preço **R$ 9,90/mês** (editar preço se criado como R$ 15,00)
   - **Produto no app (one-time)** `zoeira_consulta` — preço **R$ 5,00** (consumível)
2. Publique ambos.

### 3.2 Modelo
- **Assinatura R$ 9,90/mês**: acesso ilimitado a todos os veículos.
- **Consulta avulsa R$ 5,00**: desbloqueia 1 veículo para sempre.
- Todos os desbloqueios são **validados no servidor** (Cloudflare Worker +
  API do Google Play). O app NÃO escreve em `subscriptions`/`users` — só lê.

### 3.3 Testar compras
- Adicione contas de teste em Play Console → Configuração → Testadores
- Use o ambiente de sandbox para testar sem cobrar

### 3.4 Validação no servidor (Cloudflare Workers — 100% grátis)
O cliente envia o **token da compra** para o Worker, que valida na
API do Google Play (Android Publisher v3) e só então concede o acesso.
Sem isso, qualquer pessoa poderia gravar "assinante: true" no Firestore.
Sem Cloud Functions: **não precisa de plano Blaze nem de cartão**.

Passos (2 scripts + 2 telas no console):

1. **Service account** (1 clique): rode
   ```
   scripts\09_export_sa_key.ps1
   ```
   Ele instala o `gcloud` (se faltar), faz login no navegador e baixa a
   chave JSON para `worker\service-account.json`.
2. **Play Console → Configuração → Acesso à API**:
   - Associar o projeto Google Cloud `zoeira-car`.
   - Adicionar a service account `zoeira-car@appspot.gserviceaccount.com`.
3. **Publicar** (automatizado):
   ```
   scripts\10_deploy_worker.ps1
   ```
   Pede login grátis no **Cloudflare**, registra o secret, publica o Worker
   em `*.workers.dev` e grava a URL em `lib/utils/app_constants.dart`.
4. **Regras novas** (`firestore.rules`): publicar no console — `subscriptions` e
   `users` ficam com **escrita bloqueada** (só o Worker grava).

> O código fica em `worker/` (`wrangler.toml` + `src/index.js`), usado por
> `/purchase`, `/unlock`, `/verify` e o webhook `/webhook/play`. A pasta
> `functions/` (Cloud Functions) é uma alternativa que exige o plano Blaze
> e atualmente **não** é usada.

**RTDN (opcional, recomendado):** renovações/cancelamentos chegam sozinhos:
1. GCP → Pub/Sub → criar tópico e assinatura **Push** apontando para
   `https://<worker>.workers.dev/webhook/play`.
2. Play Console → Monetização → Configuração de assinaturas →
   **Notificações do desenvolvedor** → marcar/selecionar o tópico Pub/Sub.

---

## 4. Rodando o projeto

```bash
# Instalar dependências
flutter pub get

# Rodar no dispositivo Android
flutter run

# Build para produção (AAB assinado para a Play Store)
#   - Prefira o script completo: scripts/6_build_e_assinar.ps1
#   - Ou manualmente:
$env:Path += ";C:\flutter\bin"
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
$env:JAVA_HOME = "$env:LOCALAPPDATA\Eclipse Adoptium\jdk-17"
flutter build appbundle --release
```

> IMPORTANTE: `android/key.properties` NÃO pode ter BOM UTF-8 no início. O `Properties.load`
> do Gradle devora a primeira chave (`storePassword`) e a assinatura falha com
> `NullPointerException` no `signReleaseBundle`. Os scripts gravam sem BOM de propósito.

---

## 5. Estrutura do Firestore — Coleções `vehicles` e `users`

### `vehicles/{vehicleId}`
```
vehicles/{vehicleId}
  brand: string              // "Fiat"
  model: string              // "Marea"
  version: string            // "Turbo 2.0 16V"
  year_start: number         // 1997
  year_end: number           // 0 (ainda fabricado) ou 2007
  price_range: string        // "R$ 15.000 - R$ 35.000"
  verdict: string            // "recommended" | "ok_if_cheap" | "run_away"
  verdict_summary: string    // Resumo zoeiro curto (público)
  thumbnail_url: string      // URL da imagem (vazio => fallback com ícone)
  featured: boolean          // Exibir no banner da Home
  search_tokens: string[]    // Tokens para busca: ["fiat", "marea", "turbo"]
  brand_model_lower: string  // "fiat marea turbo" (para busca por prefixo)
  slug: string               // Identificador único do upsert (brand;model;version)
  ai_updated_at: timestamp   // (futuro) última atualização do agente de IA
  ai_reviewed: boolean       // (futuro) veredito ainda exige revisão humana

  // Campos premium (assinantes / consulta avulsa)
  chronic_problems: string   // Texto dos problemas crônicos
  why_buy: string            // Por que comprar
  why_avoid: string          // Por que passar longe
  technical_specs: string    // "Motor: 2.0 16V\nPotência: 185cv\n..."
  fipe_code: string          // "005234-1"
  fipe_price: number         // Preço FIPE em reais
  fipe_updated_at: timestamp
  created_at: timestamp
  updated_at: timestamp
```

### `users/{userId}`
```
users/{userId}
  unlocked_vehicle_ids: string[]  // veículos desbloqueados (avulsa paga)
  consulta_credits: number        // créditos de consulta avulsa comprados
  last_product_id: string         // último produto comprado
  last_purchase_at: timestamp
```

### `subscriptions/{userId}`
```
subscriptions/{userId}
  status: string           // "active" | "expired" (| "trial")
  product_id: string       // "zoeira_car_mensal"
  purchase_token: string   // token da compra na Play Store
  start_date: timestamp
  expiry_date: timestamp
  auto_renewing: boolean
  verified_at: timestamp   // última validação com a Google Play
  updated_at: timestamp
```
*Escrita só via Worker (Cloudflare). A coleção `purchase_tokens` guarda o hash
de cada token já processado (idempotência da consulta avulsa).*

### Alimentar a base
```bash
node scripts\5_popular_veiculos.js   # upsert (atualiza pelo slug, não duplica)
```

---

## 6. Publicação na Play Store

1. `flutter build appbundle --release`
2. Keystore de assinatura (gerado por `scripts/2_configurar_projeto.ps1`):
   ```bash
   keytool -genkeypair -v -keystore zoeira_car.jks -keyalg RSA -keysize 2048 -validity 10000 -alias zoeira_car -storetype PKCS12
   ```
3. Configure `android/key.properties` (não versionar!):
   ```
   storePassword=...
   keyPassword=...
   keyAlias=zoeira_car
   storeFile=zoeira_car.jks
   storeType=pkcs12
   ```
4. Upload do `.aab` (em `build\app\outputs\bundle\release\`) no Play Console → Produção
5. Preencha a ficha: ícone 512x512, screenshots, descrição

---

## 7. Checklist antes de publicar

- [ ] `firebase_options.dart` gerado pelo FlutterFire CLI
- [ ] `android/app/google-services.json` **substituído pelo REAL** (o atual é um placeholder
      para o build; é gitignored, então num clone novo ele nem existe — baixar do Firebase Console)
- [ ] Produto `zoeira_car_mensal` com preço **R$ 9,90/mês** publicado na Play Console
- [ ] Produto `zoeira_consulta` (R$ 5,00, consumível) publicado na Play Console
- [ ] **Worker publicado no Cloudflare** (`scripts/10_deploy_worker.ps1`) e URL no `app_constants.dart`
- [ ] Service account com acesso à Google Play configurada (`scripts/09_export_sa_key.ps1`)
- [ ] Regras do `firestore.rules` **publicadas** no console (escrita só no servidor)
- [ ] Authentication → E-mail/Senha ativo + usuário de teste com assinatura vigente
- [ ] Ícone do app (512x512) adicionado em `android/app/src/main/res/mipmap-*/`
- [ ] Keystore configurado em `android/app/build.gradle`
- [ ] `google-services.json` em `android/app/`
- [ ] Testar fluxo de compra com conta de teste (assinatura + consulta avulsa + restauração)
- [ ] Testar fluxo de login/cadastro
- [ ] Testar busca e detalhe de veículo
- [ ] Base de veículos populada (`node scripts\5_popular_veiculos.js`)
