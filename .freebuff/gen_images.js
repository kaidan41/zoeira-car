// =============================================================
// Gerador de imagens IA (Pollinations) — cobre TODOS os carros
// sem imagem: docs do Firestore (ref quebrada ou thumbnail vazio)
// + entradas do seed (vehicles.js) sem asset local.
// - Retomável: pula arquivos já existentes em disco.
// - Escreve APENAS em assets/images/vehicles/*.jpg (sem Firestore).
// - Nome SEMPRE canônico brand_model.jpg (normalização do 11/12_sync).
// Uso: node .freebuff/gen_images.js [--dry]  |  env GEN_CONC=4 ...
// =============================================================
const fs = require('fs');
const path = require('path');
const OUT_DIR = path.join(__dirname, '..', 'assets', 'images', 'vehicles');
if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });

const seedVehicles = require(path.join(__dirname, '..', 'scripts', 'data', 'vehicles.js'));

let db = null;
try {
  const admin = require('firebase-admin');
  const SA = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'scripts', 'serviceAccountKey.json'), 'utf8'));
  admin.initializeApp({ credential: admin.credential.cert(SA) });
  db = admin.firestore();
} catch (e) { /* sem Firestore: cobre só o seed */ }

function normalize(s) {
  return String(s || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '').trim();
}
function fileNameFor(brand, model) {
  return `${normalize(brand)}_${normalize(model)}.jpg`;
}

// prompts específicos (importantes): marca|modelo normalizado
const PROMPTS = {
  'chery|omoda 5': '2023 Chery Omoda 5 1.5 turbo compact SUV, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'volkswagen|t-cross': '2022 Volkswagen T-Cross Highline compact SUV, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'volkswagen|golf gti': '2016 Volkswagen Golf GTI MK7 2.0 TSI hatchback, red color, side 3/4 front view, white studio background, photorealistic car photography',
  'jeep|commander': '2022 Jeep Commander 1.3 turbo 7-seat midsize SUV, dark gray color, side 3/4 front view, white studio background, photorealistic car photography',
  'ram|1500': '2023 RAM 1500 Laramie 5.7 V8 full-size pickup truck, dark blue color, side 3/4 front view, white studio background, photorealistic car photography',
  'toyota|yaris cross': '2025 Toyota Yaris Cross hybrid compact SUV, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'citroen|basalt': '2025 Citroen Basalt coupe-style compact crossover SUV, orange color, side 3/4 front view, white studio background, photorealistic car photography',
  'gwm|tank 300': '2024 GWM Tank 300 boxy off-road SUV, green color, side 3/4 front view, white studio background, photorealistic car photography',
  'hyundai|hb20x': '2018 Hyundai HB20X crossover hatchback, red color, side 3/4 front view, white studio background, photorealistic car photography',
  'bmw|x1': '2023 BMW X1 xDrive sport utility vehicle, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'audi|q3': '2021 Audi Q3 compact luxury SUV, gray color, side 3/4 front view, white studio background, photorealistic car photography',
  'volvo|xc40': '2021 Volvo XC40 compact luxury SUV, blue color, side 3/4 front view, white studio background, photorealistic car photography',
  'peugeot|408': '2023 Peugeot 408 fastback crossover, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'kia|k3': '2024 Kia K3 sedan, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'mitsubishi|asx': '2016 Mitsubishi ASX compact SUV, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'cherry|omoda 5': '2023 Chery Omoda 5 1.5 turbo compact SUV, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'chery|tiggo': '2015 Chery Tiggo compact SUV, silver color, side 3/4 front view, white studio background, photorealistic car photography',
};
function getPrompt(brand, model, version) {
  const k = `${normalize(brand)}|${normalize(model)}`;
  if (PROMPTS[k]) return PROMPTS[k];
  return `${brand} ${model} ${version} car, realistic side 3/4 front view, white studio background, photorealistic car photography, highly detailed`;
}

async function buildNeeds() {
  const needs = new Map(); // fileName -> {brand, model, version}
  const add = (brand, model, version) => {
    const f = fileNameFor(brand, model);
    const p = path.join(OUT_DIR, f);
    if (fs.existsSync(p) && fs.statSync(p).size > 10000) return;
    if (!needs.has(f)) needs.set(f, { brand, model, version: version || '' });
  };
  if (db) {
    const snap = await db.collection('vehicles').get();
    for (const d of snap.docs) {
      const v = d.data();
      const t = String(v.thumbnail_url || '');
      if (t.startsWith('assets/')) {
        const f = t.split('/').pop();
        const p = path.join(OUT_DIR, f);
        if (!(fs.existsSync(p) && fs.statSync(p).size > 10000)) add(v.brand, v.model, v.version);
      } else if (!t) add(v.brand, v.model, v.version);
    }
  }
  for (const v of seedVehicles) {
    const t = String(v.thumbnail_url || '');
    if (t.startsWith('assets/')) {
      const f = t.split('/').pop();
      const p = path.join(OUT_DIR, f);
      if (!(fs.existsSync(p) && fs.statSync(p).size > 10000)) add(v.brand, v.model, v.version);
    } else if (!t) add(v.brand, v.model, v.version);
  }
  return needs;
}

async function genOne(key, need) {
  const outPath = path.join(OUT_DIR, key);
  const prompt = getPrompt(need.brand, need.model, need.version);
  for (let attempt = 0; attempt < 4; attempt++) {
    const seed = Math.floor(Math.random() * 1000000);
    const url = `https://image.pollinations.ai/prompt/${encodeURIComponent(prompt)}?width=640&height=480&model=turbo&seed=${seed}&nologo=true`;
    try {
      const r = await fetch(url);
      const buf = Buffer.from(await r.arrayBuffer());
      if (buf.length < 10000) {
        console.log(`    ${key} resposta pequena (${buf.length}b); aguardando 15s...`);
        await new Promise((res) => setTimeout(res, 15000));
        continue;
      }
      fs.writeFileSync(outPath, buf);
      console.log(`  OK ${key} (${(buf.length / 1024).toFixed(0)}KB) — ${need.brand} ${need.model} ${need.version || ''}`);
      return true;
    } catch (e) {
      console.log(`    ${key} erro: ${e.message}`);
      await new Promise((res) => setTimeout(res, 12000));
    }
  }
  console.log(`  FALHOU ${key} — ${need.brand} ${need.model}`);
  return false;
}

(async () => {
  const needs = await buildNeeds();
  const list = [...needs.entries()];
  console.log(`Total a gerar: ${list.length}`);
  if (process.argv.includes('--dry')) {
    for (const [k, n] of list) console.log(`  ${k} ← ${n.brand} ${n.model} ${n.version || ''}`);
    process.exit(0);
  }
  const CONC = Number(process.env.GEN_CONC || 1);
  let idx = 0, ok = 0;
  async function worker() {
    while (idx < list.length) {
      const [key, need] = list[idx++];
      console.log(`🎨 [${idx}/${list.length}] ${key}`);
      if (await genOne(key, need)) ok++;
      await new Promise((res) => setTimeout(res, 1500));
    }
  }
  const t0 = Date.now();
  const workers = [];
  for (let i = 0; i < Math.min(CONC, list.length); i++) workers.push(worker());
  await Promise.all(workers);
  console.log(`\n✅ ${ok}/${list.length} geradas em ${((Date.now() - t0) / 60000).toFixed(1)}min.`);
  process.exit(0);
})().catch((e) => { console.error('ERRO FATAL', e); process.exit(1); });
