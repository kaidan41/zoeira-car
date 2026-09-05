// Resolve código FIPE -> modelo Parallelum v1 (marca id + modelo id) para o catálogo.
// v1: https://parallelum.com.br/fipe/api/v1/carros/marcas/{marca}/modelos/{modelo}/anos
const admin = require('firebase-admin');
const sa = require('./scripts/serviceAccountKey.json');

admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();

const V1 = 'https://parallelum.com.br/fipe/api/v1/carros';
const norm = (s) => String(s || '').toLowerCase()
  .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
  .replace(/[^a-z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim();

async function get(url, tries = 3) {
  for (let i = 0; i < tries; i++) {
    try {
      const r = await fetch(url);
      if (r.ok) return await r.json();
    } catch (e) { /* retry */ }
    await new Promise((res) => setTimeout(res, 800 * (i + 1)));
  }
  return null;
}

(async () => {
  const brands = await get(`${V1}/marcas`);
  const brandById = {};
  brands.forEach((b) => (brandById[b.codigo] = b.nome));

  // Todos os veículos com código FIPE (ou sem, dos Onix em falta)
  const snap = await db.collection('vehicles')
    .where('fipe_code', '!=', '').get();
  const cars = [];
  snap.forEach((d) => {
    const v = d.data();
    cars.push({ id: d.id, brand: v.brand, model: v.model, version: v.version || '', yearStart: v.year_start, code: (v.fipe_code || '').trim() });
  });
  // Onix sem código
  for (const extra of [
    { id: 'k8Vf2SR73oRTxxHvySFp', brand: 'Chevrolet', model: 'Onix', version: '1.4 LT', yearStart: 2012 },
    { id: 'TNjtwCG7Rk6aA2ftWsmz', brand: 'Chevrolet', model: 'Onix Plus', version: 'LTZ 1.0 Turbo', yearStart: 2019 },
  ]) {
    if (!cars.find((c) => c.id === extra.id)) cars.push(extra);
  }

  // Cache de modelos por marca
  const modelsByBrand = {};
  async function getModels(brandId) {
    if (modelsByBrand[brandId]) return modelsByBrand[brandId];
    const m = await get(`${V1}/marcas/${brandId}/modelos`);
    if (!m) return [];
    const list = m.modelos || m || [];
    modelsByBrand[brandId] = list;
    return list;
  }

  // Marca normalizada -> id v1 (maior casamento de nome)
  function pickBrand(vehicle) {
    const nb = norm(vehicle.brand);
    let best = null, bestScore = 0;
    for (const b of brands) {
      const score = nb.split(' ').filter((w) => norm(b.nome).includes(w)).length;
      if (score > bestScore) { bestScore = score; best = b; }
    }
    return best;
  }

  const out = [];
  for (const car of cars) {
    const brand = pickBrand(car);
    if (!brand) { out.push({ ...car, error: 'marca nao achada' }); continue; }
    const models = await getModels(brand.codigo);
    // candidatos: nomes contendo o modelo principal
    const nModel = norm(car.model).replace(/plus/, '');
    const candidates = models
      .map((m) => ({ ...m, n: norm(m.nome) }))
      .filter((m) => m.n.includes(nModel))
      .filter((m) => {
        // contém ao menos uma palavra-chave forte da versão?
        const vers = norm(car.version);
        const kw = vers.split(' ').filter((w) => w.length >= 3 && !['geracao', 'com', 'para', 'completo', 'linha', 'serie'].includes(w));
        if (kw.length === 0) return true;
        return kw.some((w) => m.n.includes(w));
      })
      .slice(0, 8);
    out.push({ ...car, brandV1: { codigo: brand.codigo, nome: brand.nome }, nCandidates: candidates.map((c) => ({ codigo: c.codigo, nome: c.nome })) });
  }
  console.log(JSON.stringify(out, null, 1));
})().catch((e) => { console.error('ERR', e); process.exit(1); });
