// Gera ilustrações vetoriais realistas para os 22 exclusive via Hugging Face (grátis)
// Uso: HF_TOKEN=hf_xxx node scripts/generate_vehicle_images.js
// Sem token tenta anônimo (fila maior). Salva em assets/images/vehicles/

const fs = require('fs');
const path = require('path');

const HF_MODEL = 'stabilityai/stable-diffusion-xl-base-1.0';
const HF_TOKEN = process.env.HF_TOKEN || process.env.HUGGINGFACE_TOKEN || '';

const OUTFILE_DIR = path.join(__dirname, '..', 'assets', 'images', 'vehicles');
if (!fs.existsSync(OUTFILE_DIR)) fs.mkdirSync(OUTFILE_DIR, { recursive: true });

// 22 exclusivos — primeiro lote 5 Ferraris pra teste
const BATCH = [
  { slug: 'ferrari_f8_tributo', prompt: 'Ferrari F8 Tributo red supercar side view, realistic vector illustration, flat design, transparent background, studio lighting, highly detailed, 4k' },
  { slug: 'ferrari_488_gtb', prompt: 'Ferrari 488 GTB red supercar side view, realistic vector illustration, flat design, transparent background' },
  { slug: 'ferrari_roma', prompt: 'Ferrari Roma elegant GT coupe side view, realistic vector illustration, flat design, cream background' },
  { slug: 'ferrari_sf90_stradale', prompt: 'Ferrari SF90 Stradale hybrid hypercar side view, realistic vector illustration, flat design' },
  { slug: 'ferrari_296_gtb', prompt: 'Ferrari 296 GTB yellow hybrid supercar side view, realistic vector illustration' },
];

async function generateOne({ slug, prompt }) {
  console.log(`\n🎨 Gerando ${slug}...`);
  const url = `https://api-inference.huggingface.co/models/${HF_MODEL}`;
  const headers = { 'Content-Type': 'application/json' };
  if (HF_TOKEN) headers['Authorization'] = `Bearer ${HF_TOKEN}`;

  const res = await fetch(url, {
    method: 'POST',
    headers,
    body: JSON.stringify({ inputs: prompt }),
  });

  if (res.status === 503) {
    const j = await res.json().catch(()=>({}));
    const wait = j.estimated_time ? Math.ceil(j.estimated_time) : 20;
    console.log(`  ⏳ Modelo carregando, aguardando ${wait}s...`);
    await new Promise(r=>setTimeout(r, wait*1000));
    return generateOne({ slug, prompt });
  }

  if (!res.ok) {
    const txt = await res.text();
    console.log(`  ❌ Erro ${res.status}: ${txt.slice(0,300)}`);
    return false;
  }

  const buf = Buffer.from(await res.arrayBuffer());
  const out = path.join(OUTFILE_DIR, `${slug}.png`);
  fs.writeFileSync(out, buf);
  console.log(`  ✅ Salvo ${out} (${(buf.length/1024).toFixed(0)}KB)`);
  return true;
}

(async()=>{
  console.log(`Hugging Face model: ${HF_MODEL} ${HF_TOKEN ? '(com token)' : '(anônimo)'}`);
  for (const item of BATCH) {
    await generateOne(item);
    await new Promise(r=>setTimeout(r, 2000));
  }
  console.log('\nPronto! Próximo lote: porsche, lamborghini etc.');
})();