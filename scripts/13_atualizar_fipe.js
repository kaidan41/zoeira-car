// =============================================================
// ZOEIRA CAR — Sincroniza a FIPE (cache no Firestore)
// -------------------------------------------------------------
// Consulta a API da FIPE (BrasilAPI → fallback Parallelum v2) para
// TODOS os códigos FIPE do catálogo e grava no Firestore:
//   fipe_prices:     { "2020": 45000.0, "2021": 48000.0, ... }
//   fipe_reference:  "setembro/2026"
//   fipe_updated_at: Timestamp
// Assim o app lê do nosso banco (rápido e estável) e a API é
// consultada apenas aqui, periodicamente, sem impactar o app.
//
// Executar (local ou GitHub Actions):
//   node scripts/13_atualizar_fipe.js
// Requer: FIREBASE_SERVICE_ACCOUNT (secret) ou scripts/serviceAccountKey.json
// =============================================================

const admin = require('firebase-admin');

let serviceAccount;
const saFromEnv = process.env.FIREBASE_SERVICE_ACCOUNT;
if (saFromEnv) {
  try {
    serviceAccount = JSON.parse(saFromEnv);
  } catch (e) {
    console.error('❌ FIREBASE_SERVICE_ACCOUNT não é um JSON válido.');
    process.exit(1);
  }
} else {
  try {
    serviceAccount = require('./serviceAccountKey.json');
  } catch (e) {
    console.error('❌ serviceAccountKey.json ausente. Defina FIREBASE_SERVICE_ACCOUNT.');
    process.exit(1);
  }
}

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const MAX_CODES = Number(process.env.MAX_CODES || 100); // limite por execução
const DELAY_MS = 1500; // entre códigos, para não sobrecarregar a API

async function fetchJson(url, timeoutMs = 10000) {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res = await fetch(url, { signal: ctrl.signal });
    clearTimeout(t);
    if (!res.ok) return null;
    return await res.json();
  } catch {
    clearTimeout(t);
    return null;
  }
}

// Busca TODOS os anos/preços de um código FIPE
// BrasilAPI primeiro; fallback Parallelum v2.
async function fetchFipeByCode(cleanCode) {
  // 1. BrasilAPI (todos os anos de uma vez)
  const brasil = await fetchJson(
    `https://brasilapi.com.br/api/fipe/preco/v1/${cleanCode}`,
  );
  if (Array.isArray(brasil) && brasil.length > 0) {
    return brasil.map((r) => ({
      ano: Number(r.anoModelo ?? r.AnoModelo),
      valor: Number(
        String(r.valor ?? r.Valor ?? '0').replace(/[^0-9,]/g, '').replace(',', '.'),
      ),
      combustivel: String(r.combustivel ?? r.Combustivel ?? ''),
      referencia: String(r.mesReferencia ?? r.MesReferencia ?? ''),
    })).filter((r) => r.ano > 0 && r.ano < 32000 && r.valor > 0);
  }

  // 2. Fallback Parallelum v2
  const v2Base = 'https://fipe.parallelum.com.br/api/v2';
  const refs = await fetchJson(`${v2Base}/references`);
  const refCode = Array.isArray(refs) && refs.length > 0
    ? String(refs[0].code || '')
    : '';
  const refQuery = refCode ? `?reference=${refCode}` : '';

  const years = await fetchJson(`${v2Base}/cars/${cleanCode}/years${refQuery}`);
  if (!Array.isArray(years)) return [];

  const out = [];
  for (const y of years.slice(0, 25)) {
    const yearCode = String(y.code || '');
    const yearNum = Number(String(yearCode).split('-')[0]);
    if (!yearCode || yearNum >= 32000) continue; // pula "Zero KM"
    const d = await fetchJson(
      `${v2Base}/cars/${cleanCode}/years/${yearCode}${refQuery}`,
    );
    if (!d) continue;
    const valor = Number(String(d.price ?? '0').replace(/[^0-9,]/g, '').replace(',', '.'));
    if (valor > 0) {
      out.push({
        ano: yearNum,
        valor,
        combustivel: String(d.fuel ?? ''),
        referencia: String(d.referenceMonth ?? ''),
      });
    }
  }
  return out;
}

async function main() {
  console.log('\n💲 Zoeira Car — Sincronizando FIPE para o catálogo...\n');

  const snap = await db.collection('vehicles').get();
  const withCode = [];
  snap.forEach((d) => {
    const v = d.data();
    const code = String(v.fipe_code || '').trim();
    if (code) withCode.push({ ref: d.ref, brand: v.brand, model: v.model, version: v.version, code });
  });

  // Deduplica códigos (vários veículos podem compartilhar o mesmo)
  const codes = [...new Set(withCode.map((v) => v.code))].slice(0, MAX_CODES);
  console.log(`Veículos com código FIPE: ${withCode.length} | códigos únicos: ${codes.length}\n`);

  let ok = 0;
  let fail = 0;

  for (const code of codes) {
    const clean = code.replace(/[^0-9-]/g, '');
    const veiculos = withCode.filter((v) => v.code === code);
    console.log(`🔎 ${veiculos[0].brand} ${veiculos[0].model} (${code})...`);

    const prices = await fetchFipeByCode(clean);
    if (prices.length === 0) {
      fail++;
      console.log(`   ⚠️  sem dados (API fora do ar ou código inválido)`);
      await new Promise((r) => setTimeout(r, DELAY_MS));
      continue;
    }

    // Monta mapa ano → valor (mais recente por ano vence)
    const map = {};
    for (const p of prices) {
      if (map[p.ano] === undefined || p.valor > map[p.ano]) map[p.ano] = p.valor;
    }
    const reference = prices.find((p) => p.referencia)?.referencia || '';

    const batch = db.batch();
    for (const v of veiculos) {
      batch.update(v.ref, {
        fipe_prices: map,
        fipe_reference: reference,
        fipe_updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    ok++;
    const anos = Object.keys(map).sort((a, b) => b - a);
    console.log(`   ✅ ${anos.length} anos (${anos[0]}–${anos[anos.length - 1]}) | ref: ${reference || '?'}`);
    await new Promise((r) => setTimeout(r, DELAY_MS));
  }

  console.log(`\n🎉 FIPE sincronizada: ${ok} códigos OK, ${fail} falharam.`);
  console.log('Agora o app lê do Firestore (fipe_prices) — API consultada só aqui.\n');
  process.exit(0);
}

main().catch((e) => {
  console.error('❌ Erro:', e);
  process.exit(1);
});