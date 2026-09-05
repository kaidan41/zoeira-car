# 🚀 Guia de Deploy - Zoeira Car

## Fluxo de Deployment Automático

Todos os deploys são feitos via **GitHub Actions**. Não precisar fazer upload manual no Play Console!

---

## 📋 **Opções de Deploy**

### **1. Deploy Automático via Tag (Internal Testing)**

Quando vocês criam uma **tag de versão**, a action automaticamente:
1. Faz build do AAB em Release mode
2. Faz upload pro Play Console (track: **internal**)

**Como fazer:**

```bash
# Incrementar versão no pubspec.yaml (ex: 1.0.5+12 → 1.0.6+13)
# Depois criar e fazer push da tag:

git tag v1.0.6
git push origin v1.0.6
```

✅ A action dispara automaticamente!
⏱️ Tempo: ~5-10 minutos

---

### **2. Deploy Manual via Workflow Dispatch (Qualquer Track)**

Se vocês querem escolher a track, usem:

**No GitHub:**
1. Vá para: **Actions** → **Deploy Play Store (Teste Interno)**
2. Clique em **"Run workflow"**
3. Escolha a track:
   - `internal` - Testadores internos
   - `closed_testing` - Teste fechado (grupo controlado)
   - `open_testing` - Teste aberto (público)
   - `production` - Production (Google Play público)

✅ Dispara imediatamente!
⏱️ Tempo: ~5-10 minutos

---

## 🔄 **Fluxo Recomendado**

```
1. Fazer mudanças no código
   ↓
2. Commitar: git add . && git commit -m "..."
   ↓
3. Push pro main: git push origin main
   ↓
4. **Criar tag** (dispara internal automaticamente):
   git tag v1.0.6 && git push origin v1.0.6
   ↓
5. Aguardar ~5-10min (action rodando)
   ↓
6. **Se quiser testar em outro track** (ex: closed_testing):
   GitHub > Actions > Run workflow > Escolher "closed_testing"
   ↓
7. Quando pronto pra production:
   GitHub > Actions > Run workflow > Escolher "production"
```

---

## 📊 **Track vs Destino**

| Track | Destino | Tempo | Uso |
|-------|---------|-------|-----|
| `internal` | Testadores internos | ~2-4h | Testes rápidos |
| `closed_testing` | Teste fechado (beta) | ~2-4h | Testes com grupo controlado |
| `open_testing` | Teste aberto | ~2-4h | Testes públicos |
| `production` | Google Play Público | ~24h | Lançamento final |

---

## ⚙️ **Secrets Necessários**

A action precisa dos seguintes secrets configurados no GitHub:

- `KEYSTORE_BASE64` - Keystore codificado em base64
- `KEY_STORE_PASSWORD` - Senha do keystore
- `KEY_PASSWORD` - Senha da chave privada
- `KEY_ALIAS` - Alias da chave (ex: `zoeira_car`)
- `PLAY_STORE_SERVICE_ACCOUNT_JSON` - JSON da conta de serviço

✅ Tudo já está configurado!

---

## 🎯 **Release Notes**

Antes de fazer deploy, atualize os arquivos de release notes:

```
distribution/whatsnew/whatsnew-pt-BR  (português)
distribution/whatsnew/whatsnew-en-US  (inglês)
```

A action automaticamente inclui essas descrições no Play Console.

---

## 📝 **Exemplo Prático**

**Cenário:** Vocês fizeram correções e querem testar no Closed Testing

```bash
# 1. Fazer commits
git add .
git commit -m "fix: corrigir compra de IAP"
git push origin main

# 2. Criar tag pra internal (testes rápidos)
git tag v1.0.6
git push origin v1.0.6

# 3. Aguardar ~5-10min (action rodando)

# 4. Quando pronto, ir pra beta via workflow manual:
#    GitHub > Actions > Deploy Play Store > Run workflow > "beta"

# 5. Depois de testar tudo, ir pra production:
#    GitHub > Actions > Deploy Play Store > Run workflow > "production"
```

---

## ✅ **Checklist Antes de Deploy**

- [ ] Código testado localmente
- [ ] Versão incrementada em `pubspec.yaml`
- [ ] Release notes atualizadas (`whatsnew-pt-BR`, `whatsnew-en-US`)
- [ ] Commits feitos e pushos
- [ ] Tag criada e pushada (ou workflow manual disparado)

---

## 🆘 **Troubleshooting**

**Q: Action falhou?**
A: Verifique os logs em GitHub > Actions > [seu workflow] > Logs

**Q: Não vejo a opção de track no workflow manual?**
A: Verifique se a action está em `.github/workflows/deploy_play_store.yaml` com `workflow_dispatch`

**Q: Produto não aparece no app após deploy?**
A: Aguarde 2-4h (Google processa os produtos assincronamente)

**Q: Quero fazer deploy de uma versão anterior?**
A: Crie uma tag apontando pro commit antigo:
```bash
git tag v1.0.5 abc1234  # abc1234 = hash do commit
git push origin v1.0.5
```

---

## 📞 **Contato / Dúvidas**

Se tiver dúvidas sobre o processo, verifique:
1. Os logs da action no GitHub
2. O status do upload no Play Console
3. Este guia (arquivo `DEPLOY_GUIA.md`)
