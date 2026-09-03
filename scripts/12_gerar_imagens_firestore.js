// =============================================================
// ZOEIRA CAR — Gera imagens IA (Pollinations) para veículos que só
// existem no Firestore (adicionados pelo agente de IA) e ainda não
// têm asset local em assets/images/vehicles/<brand>_<model>.jpg.
// Só escreve os arquivos .jpg; o 11_sync_thumbnails.js faz o vínculo
// thumbnail_url → asset no Firestore.
// =============================================================

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const OUT_DIR = path.join(__dirname, '..', 'assets', 'images', 'vehicles');
if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });

const BATCH = Number(process.env.BATCH2 || process.env.BATCH || 10);

function normalize(s) {
  return String(s || '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9 ]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function fileNameFor(brand, model) {
  const b = normalize(brand).replace(/\s+/g, '_');
  const m = normalize(model).replace(/\s+/g, '_');
  return `${b}_${m}.jpg`;
}

async function genOne({ brand, model, version }) {
  const fileName = fileNameFor(brand, model);
  const outPath = path.join(OUT_DIR, fileName);

  if (fs.existsSync(outPath) && fs.statSync(outPath).size > 10000) {
    console.log(`  SKIP ${fileName} (asset já existe)`);
    return true;
  }

  const prompt =
    `${brand} ${model} ${version} car, realistic side 3/4 front view, ` +
    `white studio background, photorealistic car photography, highly detailed`;
  const url =
    `https://image.pollinations.ai/prompt/${encodeURIComponent(prompt)}` +
    `?width=1024&height=768&model=flux&seed=${Math.floor(Math.random() * 1000000)}&nologo=true`;

  console.log(`  🎨 ${fileName} ← ${brand} ${model} ${version || ''}`);
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const r = await fetch(url);
      const buf = Buffer.from(await r.arrayBuffer());
      if (buf.length < 10000) {
        console.log(`    Rate limit, aguardando 45s...`);
        await new Promise((res) => setTimeout(res, 45000));
        continue;
      }
      fs.writeFileSync(outPath, buf);
      console.log(`    OK ${fileName} (${(buf.length / 1024).toFixed(0)}KB)`);
      await new Promise((res) => setTimeout(res, 35000));
      return true;
    } catch (e) {
      console.log(`    Erro: ${e.message}`);
      await new Promise((res) => setTimeout(res, 10000));
    }
  }
  return false;
}

(async () => {
  const snap = await db.collection('vehicles').get();
  const seen = new Map(); // brand|model → {brand, model, version}

  for (const doc of snap.docs) {
    const v = doc.data();
    const thumb = String(v.thumbnail_url || '');
    if (thumb.startsWith('assets/images/vehicles/')) continue;
    const key = `${normalize(v.brand)}|${normalize(v.model)}`;
    if (seen.has(key)) continue;
    seen.set(key, { brand: v.brand, model: v.model, version: v.version || '' });
  }

  const targets = Array.from(seen.values()).slice(0, BATCH);
  console.log(`\n🎨 Gerando imagens para ${targets.length} modelos do Firestore sem asset...\n`);

  let ok = 0;
  for (const t of targets) {
    if (await genOne(t)) ok++;
  }

  console.log(`\n✅ ${ok}/${targets.length} imagens geradas.`);
  console.log('Agora rode: node scripts/11_sync_thumbnails.js (ou o workflow faz isso).');
  process.exit(0);
})().catch((e) => {
  console.error('❌ Erro:', e);
  process.exit(1);
});
