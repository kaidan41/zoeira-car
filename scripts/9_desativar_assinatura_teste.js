// Desativa a assinatura de teste do usuário para o paywall voltar a aparecer.
// Uso: node scripts/9_desativar_assinatura_teste.js [uid]
// Padrão: uid do usuário de teste (Ex7adtCLZ9hrV3k7g3GTLXI3WCe2)
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

async function main() {
  const saPath = path.join(__dirname, 'serviceAccountKey.json');
  if (!fs.existsSync(saPath)) {
    console.error('Faltando scripts/serviceAccountKey.json');
    process.exit(1);
  }

  admin.initializeApp({ credential: admin.credential.cert(require(saPath)) });
  const db = admin.firestore();

  const uid = process.argv[2] || 'Ex7adtCLZ9hrV3k7g3GTLXI3WCe2';
  const past = new Date(Date.now() - 86400000); // ontem
  const doc = db.collection('subscriptions').doc(uid);
  const snap = await doc.get();

  if (!snap.exists) {
    console.log('Sem assinatura registrada para esse usuário. Nada a fazer.');
    return;
  }

  await doc.set(
    {
      status: 'expired',
      expiry_date: admin.firestore.Timestamp.fromDate(past),
      auto_renewing: false,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  console.log('Assinatura de teste desativada com sucesso!');
  console.log('- uid:', uid);
  console.log('- status: active => expired');
  console.log('- vencimento: ontem (' + past.toISOString() + ')');
  console.log('');
  console.log('Agora TODO carro mostra apenas a consulta básica + paywall.');
  console.log('Para reativar (testar assinante), rode:');
  console.log("  node scripts/9_reativar_assinatura_teste.js");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});