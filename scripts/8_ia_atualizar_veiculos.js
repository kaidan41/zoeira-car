// =============================================================
// ZOEIRA CAR — Agente de IA: pesquisa e atualiza o catálogo
// -------------------------------------------------------------
// O que faz (a cada execução, ~8 carros):
//  1. Lê o catálogo atual no Firestore (modelos existentes).
//  2. Pede ao Gemini selecionar alvos: ~4 para revalidar (existentes
//     feitos pela IA) + ~4 novos modelos populares do Brasil.
//  3. Para cada alvo, o Gemini pesquisa na WEB (grounding Google)
//     e devolve a ficha em JSON com fontes citadas (sources[]).
//  4. Valida e faz upsert no Firestore. Tudo gerado por IA entra
//     com ai_reviewed: false (aguardando revisão humana).
//
// Regras editoriais (importantes):
//  - NENHUM problema crônico sem fonte confiável → se não achar,
//    escreva "Sem problemas crônicos documentados em fontes confiáveis."
//  - Recursos/recalls apenas de fonte oficial (gov.br/Consumidor,
//    montadoras) ou grande imprensa automotiva.
//  - FIPE: deixe vazio a menos que venha da Tabela FIPE oficial.
//  - Entradas já revisadas por humano (ai_reviewed != false) NÃO são
//    sobrescritas.
//
// Executar (local):
//   node scripts/8_ia_atualizar_veiculos.js
// Variáveis:
//   GEMINI_API_KEY            (obrigatório)
//   FIREBASE_SERVICE_ACCOUNT  (JSON da chave de serviço, opcional se
//                              scripts/serviceAccountKey.json existir)
//   MAX_ENTRIES               (máx de carros por execução, padrão 8)
// =============================================================

const { GoogleGenerativeAI } = require('@google/generative-ai');
const admin = require('firebase-admin');

// ─────────────────────────────────────────────
// Configuração
// ─────────────────────────────────────────────
const rawKey = String(process.env.GEMINI_API_KEY || '');
// Remove qualquer espaço/quebra de linha (acidentes de cópia/cola).
const API_KEY = rawKey.replace(/\s+/g, '');
console.log(`Chave API: ${rawKey.length} chars recebidos → ${API_KEY.length} chars limpos.`);
if (!API_KEY) {
  console.error('❌ Falta GEMINI_API_KEY no ambiente.');
  process.exit(1);
}
if (API_KEY.length > 150 || API_KEY.includes('{')) {
  console.error('❌ GEMINI_API_KEY não parece ser uma chave do Gemini (valor muito longo ou contém JSON).');
  console.error('   Confira o secret no GitHub: repo > Settings > Secrets and variables > Actions > GEMINI_API_KEY deve conter SÓ a chave (ex.: AIza...), uma linha.');
  process.exit(1);
}

const MAX_ENTRIES = Number(process.env.MAX_ENTRIES || 2);
const MODEL_NAME = 'gemini-3.6-flash';

let serviceAccount;
const saFromEnv = process.env.FIREBASE_SERVICE_ACCOUNT;
if (saFromEnv) {
  try {
    serviceAccount = JSON.parse(saFromEnv);
  } catch (e) {
    console.error('❌ FIREBASE_SERVICE_ACCOUNT não é um JSON válido. Confira o conteúdo no secret do GitHub (repo > Settings > Secrets and variables > Actions).');
    process.exit(1);
  }
} else {
  try {
    serviceAccount = require('./serviceAccountKey.json');
  } catch (e) {
    console.error('❌ Secret FIREBASE_SERVICE_ACCOUNT não definido no GitHub e arquivo serviceAccountKey.json ausente localmente.');
    console.error('   → No GitHub: repo Settings > Secrets and variables > Actions > New repository secret > Name: FIREBASE_SERVICE_ACCOUNT > cole o conteúdo do scripts/serviceAccountKey.json.');
    process.exit(1);
  }
}

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();
const genAI = new GoogleGenerativeAI(API_KEY);

const VERDICTS = new Set(['recommended', 'ok_if_cheap', 'avoid']);
const BODY_TYPES = new Set(['hatch', 'sedan', 'suv', 'pickup', 'classic']);

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────
function normalizeKey(s) {
  return String(s || '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim();
}

function generateSlug(brand, model, version) {
  return `${brand.replace(/\s+/g, '-')};${model.replace(/\s+/g, '-')};${version.replace(/\s+/g, '-')}`
    .toLowerCase();
}

function generateSearchTokens(brand, model, version) {
  const text = `${brand} ${model} ${version}`.toLowerCase();
  const words = text.split(/\s+/).filter((w) => w.length > 1);
  const tokens = new Set(words);
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

function extractJson(text) {
  let t = text.trim();
  // Remove cercas de código (```json ... ```)
  t = t.replace(/^```(?:json)?/i, '').replace(/```$/, '').trim();
  const start = t.indexOf('{');
  const end = t.lastIndexOf('}');
  if (start === -1 || end === -1 || end <= start) {
    throw new Error('JSON não encontrado na resposta');
  }
  return JSON.parse(t.slice(start, end + 1));
}

async function callGemini(prompt, allowGrounding) {
  const model = genAI.getGenerativeModel(
    allowGrounding
      ? { model: MODEL_NAME, tools: [{ googleSearch: {} }] }
      : { model: MODEL_NAME },
  );

  let lastErr;
  for (let attempt = 1; attempt <= 5; attempt++) {
    try {
      const result = await model.generateContent({
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
      });
      return result.response.text();
    } catch (err) {
      lastErr = err;
      const status = err.status;
      const retriable =
        status === 429 || status === 503 || (status >= 500 && status < 600);
      if (retriable && attempt < 5) {
        const delay =
          Math.min(1000 * Math.pow(2, attempt), 8000) +
          Math.floor(Math.random() * 1000);
        console.log(
          `   ⏳ ${MODEL_NAME} pediu calma (HTTP ${status}); nova tentativa em ${Math.round(delay / 1000)}s...`,
        );
        await new Promise((r) => setTimeout(r, delay));
        continue;
      }
      throw err;
    }
  }
  throw lastErr;
}

async function callGeminiJson(prompt, allowGrounding) {
  const raw = await callGemini(prompt, allowGrounding);
  try {
    return extractJson(raw);
  } catch (_) {
    // Uma tentativa extra pedindo JSON puro.
    const retry = await callGemini(
      `${prompt}\n\nIMPORTANTE: responda APENAS com o objeto JSON, sem texto extra.`,
      allowGrounding,
    );
    return extractJson(retry);
  }
}

// ─────────────────────────────────────────────
// Passo 1: ler catálogo atual
// ─────────────────────────────────────────────
async function listCurrentVehicles() {
  const snap = await db.collection('vehicles').get();
  const items = [];
  for (const doc of snap.docs) {
    const d = doc.data();
    items.push({
      ref: doc.ref,
      brand: d.brand,
      model: d.model,
      version: d.version,
      aiReviewed: d.ai_reviewed !== false, // ausente = curado/revisado
    });
  }
  return items;
}

// ─────────────────────────────────────────────
// Passo 2: selecionar alvos (rotação local — sem gastar quota do Gemini)
// ─────────────────────────────────────────────
// Lista "programada" dos próximos carros a pesquisar (modelos populares BR
// ainda fora do catálogo). A cada run pegamos os primeiros que ainda não
// existem; quando a lista acabar, giramos por modelos existentes p/ revalidar.
const TARGET_ROTATION = [
  { brand: 'Chevrolet', model: 'Onix', version: '2ª Geração 1.0 Turbo LT', novo: true },
  { brand: 'Chevrolet', model: 'Montana', version: 'LTZ 1.2 Turbo', novo: true },
  { brand: 'Fiat', model: 'Argo', version: 'Drive 1.3', novo: true },
  { brand: 'Fiat', model: 'Mobi', version: 'Like 1.0', novo: true },
  { brand: 'Renault', model: 'Kwid', version: 'Outsider 1.0', novo: true },
  { brand: 'Renault', model: 'Logan', version: 'Zen 1.6', novo: true },
  { brand: 'Peugeot', model: '208', version: 'Active 1.6', novo: true },
  { brand: 'Peugeot', model: '2008', version: 'GT 1.6', novo: true },
  { brand: 'Citroën', model: 'C3', version: 'Feel 1.6', novo: true },
  { brand: 'Citroën', model: 'C4 Cactus', version: 'Feel 1.6', novo: true },
  { brand: 'Volkswagen', model: 'Polo', version: 'Highline 1.6 MSI', novo: true },
  { brand: 'Volkswagen', model: 'Jetta', version: 'GLI 2.0 TSI', novo: true },
  { brand: 'Ford', model: 'Ka', version: 'SEL 1.5', novo: true },
  { brand: 'Ford', model: 'EcoSport', version: 'Freestyle 1.5', novo: true },
  { brand: 'Chevrolet', model: 'Spin', version: 'Premier 1.8', novo: true },
  { brand: 'Toyota', model: 'Yaris', version: 'XL 1.5', novo: true },
  { brand: 'Toyota', model: 'Corolla Cross', version: 'XRV 2.0', novo: true },
  { brand: 'Honda', model: 'City', version: 'EXL 1.5', novo: true },
  { brand: 'Hyundai', model: 'HB20S', version: 'Platinum 1.6', novo: true },
  { brand: 'Hyundai', model: 'Creta', version: 'Prestige 2.0', novo: true },
  { brand: 'Nissan', model: 'Kicks', version: 'Advance 1.6', novo: false },
  { brand: 'Jeep', model: 'Compass', version: 'Limited 2.0 Diesel', novo: false },
  { brand: 'Fiat', model: 'Toro', version: 'Freedom 1.3 Turbo', novo: false },
  { brand: 'Volkswagen', model: 'Nivus', version: 'Highline 1.0 TSI', novo: false },
];

async function selectTargets(current, processedThisRun) {
  const exists = new Set(
    current.map((v) => generateSlug(v.brand, v.model, v.version || '')),
  );

  // Primeiro os novos; depois revalidações.
  const sorted = [
    ...TARGET_ROTATION.filter((t) => t.novo),
    ...TARGET_ROTATION.filter((t) => !t.novo),
  ];

  const targets = [];
  const seen = new Set(processedThisRun);
  for (const t of sorted) {
    const slug = generateSlug(t.brand, t.model, t.version || '');
    if (exists.has(slug) || seen.has(slug)) continue;
    targets.push(t);
    seen.add(slug);
    if (targets.length >= MAX_ENTRIES) break;
  }
  if (targets.length === 0) {
    throw new Error('Catálogo já completo para esta rodada — nenhum alvo pendente.');
  }
  return targets;
}

// ─────────────────────────────────────────────
// Passo 3: pesquisar e gerar a ficha de 1 veículo
// ─────────────────────────────────────────────
function fichaPrompt(brand, model, version, isNew) {
  return `
Pesquise na web (use busca do Google com grounding) e produza a ficha de carro usado para o app Zoeira Car.
Veículo: ${[brand, model, version].filter(Boolean).join(' ')}

REGRAS OBRIGATÓRIAS:
1. Vendas/confiabilidade: cada informação deve vir de fonte confiável (imprensa automotiva como Quatro Rodas, Autoesporte, Motor1, Jornal do Carro; ou montadora). Cite SEMPRE a fonte real com URL em "sources".
2. Problemas crônicos: SÓ liste o que estiver documentado em fonte confiável. Se não achar nada relevante, escreva: "Sem problemas crônicos documentados em fontes confiáveis." Não invente.
3. Recalls: inclua apenas se houver recall oficial (gov.br/Consumidor ou site da montadora) com a URL.
3b. Especificações técnicas e faixa de preço/FIPE: pode usar base de dados automotiva BR como Carweb (carweb.com.br) — é boa referência de valores e fichas — além da imprensa. fipe_code deixe vazio a menos que tenha o código exato da Tabela FIPE.
4. FIPE/preço: price_range em reais aproximado do mercado de usados (posicione pelo ano médio da versão), usando Carweb/imprensa como referência.
5. verdict: apenas um destes → "recommended" (recomendo comprar), "ok_if_cheap" (só se estiver barato), "avoid" (evite).
6. body_type: apenas → "hatch" | "sedan" | "suv" | "pickup" | "classic".
7. Meios técnicos: technical_specs em texto com linhas "Motor:...", "Potência:...", "Cambio:...", "Distribuição:" (mencione "CORREIA BANHADA A ÓLEO" se for o caso).
8. Tom zoeiro, direto e honesto, em pt-BR.

Responda APENAS com JSON:
{
  "brand": "...",
  "model": "...",
  "version": "...",
  "year_start": <ano>,
  "year_end": <ano ou 0 se ainda fabricado>,
  "price_range": "R$ ... - R$ ...",
  "verdict": "recommended|ok_if_cheap|avoid",
  "verdict_summary": "2-3 frases",
  "chronic_problems": "texto com alertas e fontes implícitas",
  "why_buy": "texto",
  "why_avoid": "texto",
  "technical_specs": "texto",
  "body_type": "hatch|sedan|suv|pickup|classic",
  "fipe_code": "",
  "sources": [{"title":"...","url":"https://..."}]
}
${isNew ? '(VEÍCULO NOVO — ainda não está no catálogo.)' : '(REVALIDAÇÃO — reescreva com dados atuais e fontes.)'}`;
}

function coerceFicha(f) {
  const brand = String(f.brand || '').trim();
  const model = String(f.model || '').trim();
  const version = String(f.version || '').trim();
  if (!brand || !model) throw new Error('IA não informou marca/modelo.');

  const verdict = VERDICTS.has(f.verdict) ? f.verdict : 'ok_if_cheap';
  const bodyType = BODY_TYPES.has(f.body_type) ? f.body_type : 'hatch';

  const yearStart = Math.max(1950, Math.min(2030, Number(f.year_start) || 2015));
  const yearEndRaw = Number(f.year_end) || 0;
  const yearEnd = yearEndRaw > 0 ? Math.min(2030, yearEndRaw) : 0;

  const sources = Array.isArray(f.sources) ? f.sources.filter((s) => s && s.url) : [];
  const cleanSources = sources.slice(0, 6).map((s) => ({
    title: String(s.title || s.url).slice(0, 200),
    url: String(s.url).slice(0, 300),
  }));

  return {
    brand,
    model,
    version: version || 'Versão única',
    year_start: yearStart,
    year_end: yearEnd,
    price_range: String(f.price_range || 'R$ sem informação'),
    verdict,
    verdict_summary: String(f.verdict_summary || '').slice(0, 400),
    chronic_problems: String(f.chronic_problems || 'Sem problemas crônicos documentados em fontes confiáveis.').slice(0, 800),
    why_buy: String(f.why_buy || '').slice(0, 500),
    why_avoid: String(f.why_avoid || '').slice(0, 500),
    technical_specs: String(f.technical_specs || '').slice(0, 600),
    body_type: bodyType,
    fipe_code: '',
    sources: cleanSources,
    ai_reviewed: false,
  };
}

// ─────────────────────────────────────────────
// Passo 4: upsert
// ─────────────────────────────────────────────
async function upsertVehicle(ficha, existingMap) {
  const slug = generateSlug(ficha.brand, ficha.model, ficha.version);
  const brandModelLower =
    `${ficha.brand} ${ficha.model} ${ficha.version}`.toLowerCase();

  const existing = existingMap[slug];
  if (existing && existing.aiReviewed) {
    console.log(`  ⏭️  ${ficha.brand} ${ficha.model} ${ficha.version} — já revisado por humano, mantido.`);
    return 'skipped';
  }

  const data = {
    ...ficha,
    thumbnail_url: '',
    featured: false,
    slug,
    search_tokens: generateSearchTokens(ficha.brand, ficha.model, ficha.version),
    brand_model_lower: brandModelLower,
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (existing) {
    await existing.ref.update(data);
    console.log(`  🔄 ${ficha.brand} ${ficha.model} ${ficha.version} revalidado (${ficha.verdict}).`);
    return 'updated';
  }
  await db.collection('vehicles').add({
    ...data,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`  ✅ ${ficha.brand} ${ficha.model} ${ficha.version} NOVO (${ficha.verdict}).`);
  return 'created';
}

// ─────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────
async function main() {
  console.log('\n🤖 Agente IA — pesquisando e atualizando o catálogo...\n');

  const current = await listCurrentVehicles();
  console.log(`Catálogo atual: ${current.length} veículos.`);
  const existingMap = {};
  for (const v of current) {
    existingMap[generateSlug(v.brand, v.model, v.version || '')] = v;
  }

  console.log(`Selecionando alvos (rotação local, máx ${MAX_ENTRIES})...`);
  const processedThisRun = new Set();
  let targets;
  try {
    targets = await selectTargets(current, processedThisRun);
  } catch (err) {
    console.log(`\nℹ️  ${err.message}`);
    console.log(`O catálogo já está completo para esta etapa — sem erro.`);
    process.exit(0);
  }

  let created = 0;
  let updated = 0;
  let skipped = 0;
  let consecutiveQuotaFailures = 0;

  for (const t of targets) {
    processedThisRun.add(generateSlug(t.brand, t.model, t.version || ''));
    console.log(`\n🔎 Pesquisando: ${[t.brand, t.model, t.version].filter(Boolean).join(' ')}...`);
    try {
      const raw = await callGeminiJson(
        fichaPrompt(t.brand, t.model, t.version || '', Boolean(t.novo)),
        true,
      );
      const ficha = coerceFicha(raw);
      const r = await upsertVehicle(ficha, existingMap);
      if (r === 'created') created++;
      if (r === 'updated') updated++;
      if (r === 'skipped') skipped++;
      consecutiveQuotaFailures = 0;

      // Respeita a quota grátis do Gemini: pausa entre carros.
      const pause = 10000 + Math.floor(Math.random() * 5000);
      console.log(`   💤 Aguardando ${Math.round(pause / 1000)}s pra economia de quota...`);
      await new Promise((res) => setTimeout(res, pause));
    } catch (err) {
      const status = err.status;
      if (status === 429 || status === 503) {
        consecutiveQuotaFailures++;
        console.warn(`   ⚠️  Quota demorou (HTTP ${status}) em ${t.brand} ${t.model}.`);
        if (consecutiveQuotaFailures >= 2) {
          console.log('\n📵 Quota diária do Gemini esgotada. O cron tentará novamente amanhã — nada foi quebrado.');
          console.log('Dica: habilitar billing na chave (AI Studio) aumenta muito o limite.');
          process.exit(0);
        }
      } else {
        console.warn(`  ⚠️  Falha em ${t.brand} ${t.model}: ${err.message}`);
      }
    }
  }

  console.log('\n────────────────────────────────────');
  console.log(`📊 Resumo: ${created} novos • ${updated} revalidados • ${skipped} mantidos (revisão humana).`);
  console.log(`Todos gerados por IA ficaram com ai_reviewed: false — revise antes de promover.`);
  console.log('────────────────────────────────────\n');
  process.exit(0);
}

main().catch((err) => {
  console.error('❌ Erro fatal no agente:', err);
  process.exit(1);
});