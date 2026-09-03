// =============================================================
// ZOEIRA CAR — Sincroniza thumbnails do Firestore com assets locais
// -------------------------------------------------------------
// Para cada veículo no Firestore com thumbnail_url vazio ou apontando
// para URL externa (Wikimedia/outras = risco de direito autoral), se
// existir assets/images/vehicles/<brand>_<model>.jpg no repositório,
// atualiza thumbnail_url para o asset local.
// Isso garante que veículos criados pela IA (que só existem no
// Firestore) também ganhem imagem quando o modelo tiver asset.
// =============================================================

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const ASSET_DIR = path.join(__dirname, '..', 'assets', 'images', 'vehicles');

function normalize(s) {
  return String(s || '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_|_$/g, '')
    .trim();
}

async function main() {
  const snap = await db.collection('vehicles').get();
  let updated = 0;
  let skipped = 0;

  const batch = db.batch();
  let writes = 0;

  for (const doc of snap.docs) {
    const v = doc.data();
    const thumb = String(v.thumbnail_url || '');

    // Já tem imagem local? Nada a fazer.
    if (thumb.startsWith('assets/images/vehicles/')) {
      skipped++;
      continue;
    }

    const fileName = `${normalize(v.brand)}_${normalize(v.model)}.jpg`;
    const assetPath = path.join(ASSET_DIR, fileName);
    const localRef = `assets/images/vehicles/${fileName}`;

    if (fs.existsSync(assetPath)) {
      batch.update(doc.ref, { thumbnail_url: localRef });
      writes++;
      if (writes >= 450) {
        await batch.commit();
        writes = 0;
        console.log(`  ⚡ lote de 450 commitado...`);
      }
      updated++;
      console.log(`  🖼️  ${v.brand} ${v.model} ${v.version || ''} → ${localRef}`);
    } else {
      skipped++;
    }
  }

  if (writes > 0) {
    await batch.commit();
  }

  console.log(`\n✅ Thumbnails atualizados: ${updated} | sem asset local: ${skipped - updated > 0 ? '(aguardando geração)' : ''}`);
  console.log(`Total veículos no Firestore: ${snap.size}`);
}

main().catch((err) => {
  console.error('❌ Erro:', err);
  process.exit(1);
});
