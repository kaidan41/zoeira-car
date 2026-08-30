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
const API_KEY = process.env.GEMINI_API_KEY;
if (!API_KEY) {
  console.error('❌ Falta GEMINI_API_KEY no ambiente.');
  process.exit(1);
}

const MAX_ENTRIES = Number(process.env.MAX_ENTRIES || 8);
const MODEL_NAME = 'gemini-2.0-flash';

let serviceAccount;
const saFromEnv = process.env.FIREBASE_SERVICE_ACCOUNT;
if (saFromEnv) {
  serviceAccount = JSON.parse(saFromEnv);
} else {
  serviceAccount = require('./serviceAccountKey.json');
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
  const result = await model.generateContent({
    contents: [{ role: 'user', parts: [{ text: prompt }] }],
  });
  return result.response.text();
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
// Passo 2: selecionar alvos
// ─────────────────────────────────────────────
async function selectTargets(current) {
  const existing = current.map(
    (v) => `${v.brand} ${v.model} ${v.version || ''}`.trim(),
  );
  const prompt = `
Você é o curador de dados do app Zoeira Car (mercado brasileiro de carros usados).
O catálogo atual tem estes veículos:
${existing.map((e, i) => `${i + 1}. ${e}`).join('\n')}

Selecione EXATAMENTE ${MAX_ENTRIES} veículos para pesquisa, sendo:
- até ${Math.max(2, Math.floor(MAX_ENTRIES / 2))} para REVALIDAR (escolha dentre os existentes que sejam os mais vendidos / de maior interesse no BR);
- o restante para ADICIONAR como novidade (modelos populares de 2015-2026 ainda não listados, incluindo pelo menos 1 SUV, 1 hatch e 1 pickup/do tipo mais vendido).

Responda APENAS com JSON na forma:
{"alvos":[{"brand":"...","model":"...","version":"...","novo":true|false}]}
Sem texto extra.`;
  const data = await callGeminiJson(prompt, false);
  const targets = Array.isArray(data.alvos) ? data.alvos.slice(0, MAX_ENTRIES) : [];
  if (targets.length === 0) throw new Error('A IA não retornou alvos.');
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
4. FIPE/preço: price_range em reais aproximado do mercado de usados (posicione pelo ano médio da versão). fipe_code deixe vazio a menos que você tenha o código exato da Tabela FIPE.
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

  console.log(`Selecionando ${MAX_ENTRIES} alvos...`);
  const targets = await selectTargets(current);

  let created = 0;
  let updated = 0;
  let skipped = 0;

  for (const t of targets) {
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
    } catch (err) {
      console.warn(`  ⚠️  Falha em ${t.brand} ${t.model}: ${err.message}`);
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