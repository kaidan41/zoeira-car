// =============================================================
// ZOEIRA CAR — Script 5: Sincroniza a base de veículos no Firestore
// Executar com: node scripts/5_popular_veiculos.js
// Precisa de: npm install firebase-admin (scripts/package.json)
// Dados: scripts/data/vehicles.js
// =============================================================

// ⚠️  Antes de rodar:
// 1. Baixe a chave de serviço em Firebase Console >
//    Configurações do projeto > Contas de serviço > Gerar nova chave privada
// 2. Salve como: scripts/serviceAccountKey.json

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const vehicles = require('./data/vehicles');

// Tipo de carroçaria por marca|modelo (usado pelas ilustrações: hatch, sedan,
// suv, pickup, classic). Normaliza acentos para o match ser seguro.
const BODY_TYPES = {
  'volkswagen|gol': 'classic',
  'volkswagen|fusca': 'classic',
  'chevrolet|chevette': 'classic',
  'volkswagen|santana': 'sedan',
  'chevrolet|opala': 'sedan',
  'volkswagen|brasilia': 'classic',
  'fiat|palio': 'hatch',
  'fiat|uno': 'hatch',
  'renault|sandero': 'hatch',
  'chevrolet|onix': 'hatch',
  'hyundai|hb20': 'hatch',
  'toyota|etios': 'hatch',
  'honda|fit': 'hatch',
  'chevrolet|onix plus': 'sedan',
  'chevrolet|cruze': 'sedan',
  'volkswagen|virtus': 'sedan',
  'volkswagen|voyage': 'sedan',
  'fiat|cronos': 'sedan',
  'toyota|corolla': 'sedan',
  'honda|civic': 'sedan',
  'nissan|versa': 'sedan',
  'nissan|sentra': 'sedan',
  'volkswagen|t-cross': 'suv',
  'volkswagen|nivus': 'suv',
  'chevrolet|tracker': 'suv',
  'nissan|kicks': 'suv',
  'honda|hr-v': 'suv',
  'hyundai|creta': 'suv',
  'jeep|renegade': 'suv',
  'jeep|compass': 'suv',
  'fiat|strada': 'pickup',
  'volkswagen|saveiro': 'pickup',
  'toyota|hilux': 'pickup',
  'chevrolet|s10': 'pickup',
  'ford|ranger': 'pickup',
  'fiat|toro': 'pickup',
  'fiat|marea': 'sedan',
  'renault|kardian': 'suv',
  'fiat|pulse': 'suv',
  'fiat|argo': 'hatch',
  'fiat|mobi': 'hatch',
  'volkswagen|polo': 'hatch',
  'toyota|yaris': 'hatch',
  'renault|kwid': 'hatch',
  'peugeot|208': 'hatch',
  'citroen|c3': 'hatch',
  'ford|ka': 'hatch',
  'nissan|march': 'hatch',
  'chevrolet|prisma': 'sedan',
  'volkswagen|jetta': 'sedan',
  'honda|city': 'sedan',
  'renault|logan': 'sedan',
  'hyundai|hb20s': 'sedan',
  'chevrolet|monza': 'sedan',
  'ford|escort': 'hatch',
  'volkswagen|parati': 'sedan',
  'ford|ecosport': 'suv',
  'renault|captur': 'suv',
  'peugeot|2008': 'suv',
  'citroen|c4 cactus': 'suv',
  'toyota|corolla cross': 'suv',
  'volkswagen|tiguan': 'suv',
  'chevrolet|montana': 'pickup',
  'ford|maverick': 'pickup',
  'mitsubishi|l200': 'pickup',
  'nissan|frontier': 'pickup',
  'renault|oroch': 'pickup',
  'chevrolet|spin': 'hatch',
  'fiat|punto': 'hatch',
  'renault|clio': 'hatch',
  'volkswagen|up': 'hatch',
  'ford|fiesta': 'hatch',
  'hyundai|i30': 'hatch',
  'chevrolet|celta': 'hatch',
  'volkswagen|golf': 'hatch',
  'chevrolet|corsa': 'hatch',
  'toyota|yaris seda': 'sedan',
  'fiat|siena': 'sedan',
  'toyota|camry': 'sedan',
  'renault|fluence': 'sedan',
  'peugeot|308': 'sedan',
  'citroen|c4 lounge': 'sedan',
  'toyota|rav4': 'suv',
  'honda|cr-v': 'suv',
  'volkswagen|taos': 'suv',
  'hyundai|tucson': 'suv',
  'kia|sportage': 'suv',
  'chevrolet|equinox': 'suv',
  'toyota|sw4': 'suv',
  'nissan|x-trail': 'suv',
  'citroen|c3 aircross': 'suv',
  'peugeot|3008': 'suv',
  'volkswagen|amarok': 'pickup',
  'ram|rampage': 'pickup',
  'fiat|fiorino': 'pickup',
  'volkswagen|kombi': 'classic',
  'chevrolet|camaro': 'sedan',
  'ford|mustang': 'sedan',
  'byd|dolphin': 'hatch',
  'fiat|500': 'hatch',
  'renault|duster': 'suv',
  'fiat|fastback': 'suv',
  'fiat|tipo': 'sedan',
  'ford|fusion': 'sedan',
  'honda|accord': 'sedan',
  'hyundai|elantra': 'sedan',
  'kia|cerato': 'sedan',
  'volkswagen|passat': 'sedan',
  'ford|galaxie': 'classic',
  'ford|territory': 'suv',
  'chevrolet|trailblazer': 'suv',
  'volvo|xc60': 'suv',
  'ford|focus': 'hatch',
  'chevrolet|astra': 'hatch',
  'chevrolet|omega': 'sedan',
  'volkswagen|bora': 'sedan',
  'mazda|mazda3': 'hatch',
  'mini|cooper': 'hatch',
  'byd|song plus': 'suv',
  'nissan|murano': 'suv',
  'byd|dolphin mini': 'hatch',
  'byd|seal': 'sedan',
  'byd|king': 'sedan',
  'byd|yuan pro': 'suv',
  'gwm|ora 03': 'hatch',
  'gwm|haval h6': 'suv',
  'caoa chery|icar': 'hatch',
  'chevrolet|bolt': 'hatch',
  'volvo|ex30': 'suv',
  'peugeot|e-2008': 'suv',
  'nissan|leaf': 'hatch',
  'ford|mustang mach-e': 'suv',
};

function normalizeKey(s) {
  return s
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim();
}

function bodyTypeFor(brand, model) {
  return BODY_TYPES[`${normalizeKey(brand)}|${normalizeKey(model)}`] || 'hatch';
}

// ─────────────────────────────────────────────
// Funções auxiliares
// ─────────────────────────────────────────────
function generateSlug(brand, model, version) {
  return `${brand.replace(/\s+/g, '-')};${model.replace(/\s+/g, '-')};${version.replace(/\s+/g, '-')}`.toLowerCase();
}

function generateSearchTokens(brand, model, version) {
  const text = `${brand} ${model} ${version}`.toLowerCase();
  const words = text.split(/\s+/).filter(w => w.length > 1);
  const tokens = new Set(words);

  // Adiciona combinações (ex: "gol", "gol quadrado", "vw gol")
  words.forEach((word, i) => {
    let combo = word;
    tokens.add(combo);
    for (let j = i + 1; j < Math.min(i + 3, words.length); j++) {
      combo += ` ${words[j]}`;
      tokens.add(combo);
    }
  });

  return Array.from(tokens);
}

// ─────────────────────────────────────────────
// Seed (upsert: atualiza pelo slug, não duplica)
// ─────────────────────────────────────────────
async function seedVehicles() {
  console.log('\n🚗 Zoeira Car — Sincronizando banco de veículos...\n');

  const batch = db.batch();

  for (const v of vehicles) {
    const slug = generateSlug(v.brand, v.model, v.version);
    const searchTokens = generateSearchTokens(v.brand, v.model, v.version);
    const brandModelLower = `${v.brand} ${v.model} ${v.version}`.toLowerCase();

    // Busca existente por slug (identificador único), com fallback para docs
    // antigos sem slug via brand_model_lower.
    let existing = null;
    const bySlug = await db.collection('vehicles').where('slug', '==', slug).limit(1).get();
    if (!bySlug.empty) {
      existing = bySlug.docs[0];
    } else {
      const byLower = await db.collection('vehicles').where('brand_model_lower', '==', brandModelLower).limit(1).get();
      if (!byLower.empty) existing = byLower.docs[0];
    }

    const data = {
      ...v,
      body_type: bodyTypeFor(v.brand, v.model),
      slug,
      search_tokens: searchTokens,
      brand_model_lower: brandModelLower,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (existing) {
      batch.update(existing.ref, data);
      console.log(`  🔄 ${v.brand} ${v.model} ${v.version} atualizado (${v.verdict})`);
    } else {
      batch.set(db.collection('vehicles').doc(), {
        ...data,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`  ✅ ${v.brand} ${v.model} ${v.version} adicionado (${v.verdict})`);
    }
  }

  await batch.commit();

  console.log(`\n🎉 ${vehicles.length} veículos sincronizados com sucesso!`);
  console.log('\nPRÓXIMO PASSO:');
  console.log('  Execute: scripts\\6_build_e_assinar.ps1\n');

  process.exit(0);
}

seedVehicles().catch(err => {
  console.error('❌ Erro ao popular veículos:', err);
  process.exit(1);
});