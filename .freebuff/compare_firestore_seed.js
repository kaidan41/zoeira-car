// Read-only: diff Firestore vs seed + definitive "needs image" list from Firestore.
const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');
const SA = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'scripts', 'serviceAccountKey.json'), 'utf8'));

admin.initializeApp({ credential: admin.credential.cert(SA) });
const db = admin.firestore();

const vehicles = require(path.join(__dirname, '..', 'scripts', 'data', 'vehicles.js'));
const ASSET_DIR = path.join(__dirname, '..', 'assets', 'images', 'vehicles');
const disk = fs.readdirSync(ASSET_DIR).filter((f) => /\.(jpg|png)$/i.test(f));

function slug(brand, model, version) {
  return `${String(brand || '').replace(/\s+/g, '-')};${String(model || '').replace(/\s+/g, '-')};${String(version || '').replace(/\s+/g, '-')}`.toLowerCase();
}
function norm(s) {
  return String(s || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '').trim();
}
function fileFor(brand, model) {
  return `${norm(brand)}_${norm(model)}.jpg`;
}

async function main() {
  const snap = await db.collection('vehicles').get();
  const fsSeen = {};
  for (const d of snap.docs) fsSeen[slug(d.data().brand, d.data().model, d.data().version)] = d.data();

  const seedSeen = {};
  for (const v of vehicles) seedSeen[slug(v.brand, v.model, v.version)] = v;

  const onlyFS = Object.keys(fsSeen).filter((k) => !seedSeen[k]);
  const onlySeed = Object.keys(seedSeen).filter((k) => !fsSeen[k]);
  console.log('Firestore docs:', snap.size, '| seed entries:', vehicles.length);
  console.log('Firestore-only (not in seed):', onlyFS.length, onlyFS.slice(0, 20).join('\n  '));
  console.log('Seed-only (not in Firestore):', onlySeed.length, onlySeed.slice(0, 20).join('\n  '));
  console.log('');

  // FIPE: firestore has code, seed empty?
  let fipeOnlyFS = 0, fipeMismatch = 0;
  for (const k of Object.keys(fsSeen)) {
    const f = fsSeen[k].fipe_code || '';
    const s = seedSeen[k] ? (seedSeen[k].fipe_code || '') : '';
    if (f && !s) fipeOnlyFS++;
    if (f && s && f !== s) fipeMismatch++;
  }
  console.log('FIPE code in Firestore but EMPTY in seed:', fipeOnlyFS);
  console.log('FIPE code differs FS vs seed:', fipeMismatch);

  // Needs-image list (broken ref or empty), from Firestore perspective (app truth)
  const need = [];
  for (const d of snap.docs) {
    const v = d.data();
    const t = String(v.thumbnail_url || '');
    if (!t) { need.push({ ...v, reason: 'empty', want: fileFor(v.brand, v.model) }); continue; }
    if (!t.startsWith('assets/')) { need.push({ ...v, reason: 'não-asset', want: fileFor(v.brand, v.model) }); continue; }
    const f = t.split('/').pop();
    if (!disk.includes(f)) need.push({ ...v, reason: `ref ${f}`, want: t.replace('assets/images/vehicles/', '').replace('assets/imagens/vehicles/', '') });
  }
  console.log('');
  console.log('=== NEEDS IMAGE (Firestore docs):', need.length, '===');
  const uniq = new Map();
  for (const n of need) {
    if (!uniq.has(n.want)) uniq.set(n.want, []);
    uniq.get(n.want).push(`${n.brand} ${n.model}`);
  }
  console.log('unique files to generate:', uniq.size);
  console.log('');
  console.log('=== Seed entries pointing to assets NOT on disk (broken refs in seed) ===');
  for (const v of vehicles) {
    const t = v.thumbnail_url || '';
    if (!t.startsWith('assets/')) continue;
    const f = t.split('/').pop();
    if (!disk.includes(f)) console.log(`  ${v.brand} ${v.model} ${v.version} => ${t}`);
  }
  process.exit(0);
}
main().catch((e) => { console.error('ERRO', e.message); process.exit(1); });
