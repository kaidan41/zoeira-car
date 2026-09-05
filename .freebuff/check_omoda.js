// Read-only: dump Firestore docs where brand/model mentions omoda/omda + one pollinations connectivity test.
const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');
const SA = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'scripts', 'serviceAccountKey.json'), 'utf8'));
admin.initializeApp({ credential: admin.credential.cert(SA) });
const db = admin.firestore();

(async () => {
  const snap = await db.collection('vehicles').where('brand', '==', 'Chery').get();
  console.log('=== Chery docs in Firestore ===');
  for (const d of snap.docs) {
    const v = d.data();
    console.log(`  ${v.brand} ${v.model} ${v.version || ''} => thumb: '${v.thumbnail_url || ''}' (doc ${d.id})`);
  }
  // any doc whose thumbnail mentions omda/imagens
  const all = await db.collection('vehicles').get();
  const weird = [];
  for (const d of all.docs) {
    const t = String(d.data().thumbnail_url || '');
    if (/omda|imagens|http/.test(t)) weird.push(`${d.data().brand} ${d.data().model} => ${t}`);
  }
  console.log('docs with omda/imagens/http thumb:', weird.length, weird.slice(0, 10));
  process.exit(0);
})().catch((e) => { console.error('ERRO', e.message); process.exit(1); });
