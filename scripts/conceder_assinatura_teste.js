// =============================================================
// ZOEIRA CAR — Conceder assinatura de TESTE no Firestore
// Executar com: node scripts/conceder_assinatura_teste.js
// (ou pelo scripts\7_conceder_assinatura_teste.ps1, que instala tudo)
// Precisa de: scripts/serviceAccountKey.json
//   (Firebase Console > Configuracoes > Contas de servico > Gerar chave privada)
// =============================================================

// UID do usuario de teste (Firebase Auth) — teste do mltecno@hotmail.com
const TEST_UID = process.env.ZOEIRA_TEST_UID || 'Ex7adtCLZ9hrV3k7g3GTLXI3WCe2';

// status: 'active' | 'trial'
const TEST_STATUS = (process.env.ZOEIRA_TEST_STATUS || 'active').toLowerCase();

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function grantTestSubscription() {
  console.log('\n🐊 Zoeira Car — Concedendo assinatura de teste...\n');
  console.log(`  UID   : ${TEST_UID}`);
  console.log(`  status: ${TEST_STATUS}\n`);

  if (!['active', 'trial', 'expired'].includes(TEST_STATUS)) {
    console.error('❌ ZOEIRA_TEST_STATUS deve ser active, trial ou expired.');
    process.exit(1);
  }

  const now = new Date();
  const expiry = new Date(now.getTime() + 31 * 24 * 60 * 60 * 1000);

  const docRef = db.collection('subscriptions').doc(TEST_UID);
  await docRef.set(
    {
      status: TEST_STATUS,
      product_id: 'zoeira_car_mensal',
      start_date: admin.firestore.Timestamp.fromDate(now),
      expiry_date: admin.firestore.Timestamp.fromDate(expiry),
      auto_renewing: false,
      purchase_token: 'TEST_GRANT_' + Date.now(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  console.log(`✅ Assinatura ${TEST_STATUS.toUpperCase()} concedida até ${expiry.toISOString().slice(0, 10)}`);
  console.log('');
  console.log('Para revogar (expirar) o acesso de teste, rode:');
  console.log('  $env:ZOEIRA_TEST_STATUS="expired"; node scripts/conceder_assinatura_teste.js');
  console.log('');

  process.exit(0);
}

grantTestSubscription().catch(err => {
  console.error('❌ Erro ao conceder assinatura:', err);
  process.exit(1);
});