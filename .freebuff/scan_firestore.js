// Read-only Firestore scan of the vehicles catalog.
const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');
const SA = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'scripts', 'serviceAccountKey.json'), 'utf8'));

admin.initializeApp({ credential: admin.credential.cert(SA) });
const db = admin.firestore();

const ASSET_DIR = path.join(__dirname, '..', 'assets', 'images', 'vehicles');
const disk = fs.readdirSync(ASSET_DIR).filter((f) => /\.(jpg|png)$/i.test(f));

async function main() {
  const snap = await db.collection('vehicles').get();
  let empty = 0, assetImagens = 0, assetImagesMissing = 0, assetImagesOk = 0, http = 0, other = 0, aiNotReviewed = 0;
  const brokenAsset = [];
  const countByBrand = {};
  const brokenSamples = [];
  for (const doc of snap.docs) {
    const v = doc.data();
    const t = String(v.thumbnail_url || '');
    countByBrand[v.brand] = (countByBrand[v.brand] || 0) + 1;
    if (v.ai_reviewed === false) aiNotReviewed++;
    if (!t) empty++;
    else if (t.includes('assets/imagens/')) {
      assetImagens++;
      brokenAsset.push({ brand: v.brand, model: v.model, version: v.version, url: t });
    } else if (t.startsWith('assets/')) {
      const f = t.split('/').pop();
      if (disk.includes(f)) assetImagesOk++;
      else { assetImagesMissing++; brokenAsset.push({ brand: v.brand, model: v.model, version: v.version, url: t }); }
    } else if (t.startsWith('http')) http++;
    else other++;
  }
  console.log('=== FIRESTORE vehicles ===');
  console.log('total:', snap.size);
  console.log('thumbnail empty:', empty);
  console.log('thumbnail assets/imagens/ (folder errada):', assetImagens);
  console.log('thumbnail assets/images OK no repo:', assetImagesOk);
  console.log('thumbnail assets/images arquivo AUSENTE no repo:', assetImagesMissing);
  console.log('thumbnail http externa:', http);
  console.log('thumbnail outro:', other);
  console.log('ai_reviewed === false:', aiNotReviewed);
  console.log('brands:', Object.keys(countByBrand).length);
  console.log('');
  console.log('=== BROKEN/REFERENCED-BUT-MISSING samples (max 60) ===');
  for (const b of brokenAsset.slice(0, 60)) console.log(`  ${b.brand} ${b.model} ${b.version || ''} => ${b.url}`);
  console.log('');
  console.log('total broken:', brokenAsset.length);
  console.log('unique broken urls:', new Set(brokenAsset.map((b) => b.url)).size);
  process.exit(0);
}
main().catch((e) => { console.error('ERRO', e.message); process.exit(1); });
