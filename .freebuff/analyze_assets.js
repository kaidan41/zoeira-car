// Read-only analysis: seed vehicles.js thumbnail refs vs assets/images/vehicles on disk
const fs = require('fs');
const path = require('path');

const VEHICLES = path.join(__dirname, '..', 'scripts', 'data', 'vehicles.js');
const ASSET_DIR = path.join(__dirname, '..', 'assets', 'images', 'vehicles');

const vehicles = require(VEHICLES);
const disk = fs.readdirSync(ASSET_DIR).filter((f) => /\.(jpg|png)$/i.test(f));

function slug(b, m) {
  return (b + ' ' + m).toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '');
}

const byModel = new Map(); // slug -> entries
for (const v of vehicles) {
  const k = slug(v.brand, v.model);
  if (!byModel.has(k)) byModel.set(k, []);
  byModel.get(k).push(v);
}

const empty = vehicles.filter((v) => !v.thumbnail_url || v.thumbnail_url === '');
const http = vehicles.filter((v) => (v.thumbnail_url || '').startsWith('http'));
const other = vehicles.filter((v) => v.thumbnail_url && !v.thumbnail_url.startsWith('http') && !v.thumbnail_url.startsWith('assets/'));

const assetRefs = vehicles.filter((v) => (v.thumbnail_url || '').startsWith('assets/'));
const missingRef = assetRefs.filter((v) => {
  const f = v.thumbnail_url.replace('assets/images/vehicles/', '').replace('assets/imagens/vehicles/', '');
  return !disk.includes(f);
});
const imagensRefs = vehicles.filter((v) => (v.thumbnail_url || '').includes('assets/imagens/'));

// expected asset name per model per normalize rules used by scripts (lowercase slug + .jpg)
function fileNameFor(brand, model) {
  const b = String(brand).toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim().replace(/\s+/g, '_');
  const m = String(model).toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim().replace(/\s+/g, '_');
  return `${b}_${m}.jpg`;
}

// models missing any local image
const modelsNoImage = [];
for (const [k, entries] of byModel) {
  const hasLocal = entries.some((v) => {
    const t = v.thumbnail_url || '';
    if (!t.startsWith('assets/')) return false;
    const f = t.split('/').pop();
    return disk.includes(f);
  });
  if (!hasLocal) {
    modelsNoImage.push({ key: k, brand: entries[0].brand, model: entries[0].model, versions: entries.length, expectedFile: fileNameFor(entries[0].brand, entries[0].model) });
  }
}

console.log('=== SEED vehicles.js ===');
console.log('Total entries:', vehicles.length);
console.log('Distinct brand|model:', byModel.size);
console.log('thumbnail empty:', empty.length);
console.log('thumbnail http (external):', http.length);
console.log('thumbnail other (non-asset):', other.length);
console.log('thumbnail asset refs:', assetRefs.length);
console.log('asset refs -> file NOT on disk:', missingRef.length);
for (const v of missingRef) {
  console.log('   MISSING REF:', v.brand, v.model, v.version, '=>', v.thumbnail_url);
}
console.log('refs containing assets/imagens/:', imagensRefs.length);
console.log('');
console.log('=== DISK assets ===');
console.log('files on disk:', disk.length);
const referenced = new Set(assetRefs.map((v) => v.thumbnail_url.split('/').pop()));
const orphan = disk.filter((f) => !referenced.has(f));
console.log('files NOT referenced by seed:', orphan.length, orphan.join(', '));
console.log('');
console.log('=== MODELS with NO local image (need asset or empty thumb) ===');
console.log('count:', modelsNoImage.length);
for (const m of modelsNoImage) {
  console.log(`  ${m.brand} ${m.model} (${m.versions}v) expected=${m.expectedFile}`);
}
