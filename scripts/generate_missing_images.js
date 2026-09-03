const fs   = require('fs');
const path = require('path');

const OUT_DIR = path.join(__dirname, '..', 'assets', 'images', 'vehicles');
if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });

const vehicles = require('./data/vehicles');

// =============================================================
// PROMPTS ESPECIFICOS POR MODELO
// Garante fidelidade visual ao carro real.
// Chave: "brand|model" em lowercase sem acentos.
// =============================================================
const PROMPTS = {
  // ── CLASSICOS ──
  'volkswagen|gol':        '1985 Volkswagen Gol Quadrado hatchback, red color, side 3/4 front view, white studio background, photorealistic car photography',
  'volkswagen|fusca':      '1970 Volkswagen Fusca Beetle, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'chevrolet|chevette':    '1980 Chevrolet Chevette hatchback, yellow color, side 3/4 front view, white studio background, photorealistic car photography',
  'volkswagen|santana':    '1990 Volkswagen Santana sedan, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'chevrolet|opala':       '1980 Chevrolet Opala SS coupe, dark blue color, side 3/4 front view, white studio background, photorealistic car photography',
  'volkswagen|brasilia':   '1975 Volkswagen Brasilia hatchback, orange color, side 3/4 front view, white studio background, photorealistic car photography',
  'volkswagen|kombi':      '1975 Volkswagen Kombi van, white and light blue color, side 3/4 front view, white studio background, photorealistic car photography',
  'volkswagen|parati':     '1998 Volkswagen Parati wagon, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'chevrolet|monza':       '1990 Chevrolet Monza sedan, red color, side 3/4 front view, white studio background, photorealistic car photography',
  'ford|escort':           '1995 Ford Escort hatchback, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'ford|maverick gt':      '1975 Ford Maverick GT muscle car V8, yellow color, side 3/4 front view, white studio background, photorealistic car photography',
  'ford|galaxie':          '1972 Ford Galaxie 500 sedan, black color, side 3/4 front view, white studio background, photorealistic car photography',

  // ── HATCHES POPULARES ──
  'fiat|palio':            '2010 Fiat Palio 1.0 hatchback, red color, side 3/4 front view, white studio background, photorealistic car photography',
  'fiat|uno':              '2015 Fiat Uno Attractive hatchback, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'fiat|argo':             '2020 Fiat Argo hatchback, orange color, side 3/4 front view, white studio background, photorealistic car photography',
  'fiat|mobi':             '2022 Fiat Mobi Like hatchback, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'fiat|punto':            '2014 Fiat Punto hatchback, red color, side 3/4 front view, white studio background, photorealistic car photography',
  'renault|sandero':       '2018 Renault Sandero Expression hatchback, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'renault|kwid':          '2022 Renault Kwid hatchback, orange color, side 3/4 front view, white studio background, photorealistic car photography',
  'renault|clio':          '2013 Renault Clio hatchback, red color, side 3/4 front view, white studio background, photorealistic car photography',
  'chevrolet|onix':        '2019 Chevrolet Onix hatchback, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'chevrolet|celta':       '2010 Chevrolet Celta hatchback, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'chevrolet|corsa':       '2005 Chevrolet Corsa hatchback, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'chevrolet|astra':       '2008 Chevrolet Astra hatchback, red color, side 3/4 front view, white studio background, photorealistic car photography',
  'chevrolet|spin':        '2020 Chevrolet Spin minivan, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'hyundai|hb20':          '2022 Hyundai HB20 1.0 turbo hatchback, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'hyundai|i30':           '2014 Hyundai i30 hatchback, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'toyota|etios':          '2018 Toyota Etios XLS hatchback, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'toyota|yaris':          '2022 Toyota Yaris XL hatchback, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'honda|fit':             '2020 Honda Fit EXL hatchback, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'volkswagen|polo':       '2022 Volkswagen Polo Track hatchback, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'volkswagen|up':         '2019 Volkswagen Up hatchback, red color, side 3/4 front view, white studio background, photorealistic car photography',
  'volkswagen|golf':       '2020 Volkswagen Golf GTI hatchback, red color, side 3/4 front view, white studio background, photorealistic car photography',
  'peugeot|208':           '2020 Peugeot 208 hatchback, red color, side 3/4 front view, white studio background, photorealistic car photography',
  'citroen|c3':            '2020 Citroen C3 hatchback, orange color, side 3/4 front view, white studio background, photorealistic car photography',
  'ford|ka':               '2019 Ford Ka hatchback, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'ford|fiesta':           '2013 Ford Fiesta hatchback, blue color, side 3/4 front view, white studio background, photorealistic car photography',
  'ford|focus':            '2015 Ford Focus hatchback, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'nissan|march':          '2018 Nissan March hatchback, orange color, side 3/4 front view, white studio background, photorealistic car photography',
  'mini|cooper':           '2022 Mini Cooper S hatchback, British Racing Green color, side 3/4 front view, white studio background, photorealistic car photography',
  'mazda|mazda3':          '2020 Mazda 3 hatchback, Soul Red Crystal color, side 3/4 front view, white studio background, photorealistic car photography',
  'byd|dolphin':           '2023 BYD Dolphin electric hatchback, blue color, side 3/4 front view, white studio background, photorealistic car photography',
  'byd|dolphin mini':      '2024 BYD Dolphin Mini electric hatchback, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'gwm|ora 03':            '2023 GWM ORA 03 electric hatchback, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'chevrolet|bolt':        '2022 Chevrolet Bolt EV electric hatchback, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'nissan|leaf':           '2022 Nissan Leaf electric hatchback, blue color, side 3/4 front view, white studio background, photorealistic car photography',
  'fiat|500':              '2020 Fiat 500 retro mini hatchback, red color, side 3/4 front view, white studio background, photorealistic car photography',

  // ── SEDAS ──
  'chevrolet|onix plus':   '2022 Chevrolet Onix Plus sedan, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'chevrolet|cruze':       '2022 Chevrolet Cruze LTZ sedan, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'chevrolet|prisma':      '2018 Chevrolet Prisma LT sedan, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'chevrolet|omega':       '2006 Chevrolet Omega CD V6 sedan, black color, side 3/4 front view, white studio background, photorealistic car photography',
  'volkswagen|virtus':     '2022 Volkswagen Virtus Highline sedan, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'volkswagen|voyage':     '2020 Volkswagen Voyage Comfortline sedan, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'volkswagen|jetta':      '2022 Volkswagen Jetta GLi sedan, dark grey color, side 3/4 front view, white studio background, photorealistic car photography',
  'volkswagen|bora':       '2008 Volkswagen Bora 2.0 sedan, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'volkswagen|passat':     '2018 Volkswagen Passat TSI sedan, dark blue color, side 3/4 front view, white studio background, photorealistic car photography',
  'fiat|cronos':           '2022 Fiat Cronos Precision sedan, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'fiat|siena':            '2012 Fiat Siena EL sedan, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'fiat|tipo':             '2020 Fiat Tipo sedan, red color, side 3/4 front view, white studio background, photorealistic car photography',
  'fiat|marea':            '2003 Fiat Marea Turbo sedan, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'honda|civic':           '2021 Honda Civic EXL 1.5 turbo sedan, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'honda|city':            '2022 Honda City EXL sedan, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'honda|accord':          '2020 Honda Accord 2.0 turbo sedan, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'toyota|corolla':        '2023 Toyota Corolla XEi 2.0 sedan, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'toyota|yaris seda':     '2022 Toyota Yaris XLS sedan, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'toyota|camry':          '2022 Toyota Camry XSE V6 sedan, black color, side 3/4 front view, white studio background, photorealistic car photography',
  'nissan|versa':          '2022 Nissan Versa SV sedan, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'nissan|sentra':         '2022 Nissan Sentra SV sedan, black color, side 3/4 front view, white studio background, photorealistic car photography',
  'renault|logan':         '2020 Renault Logan Intense sedan, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'renault|fluence':       '2013 Renault Fluence Dynamique sedan, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'hyundai|hb20s':         '2022 Hyundai HB20S 1.0 turbo sedan, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'hyundai|elantra':       '2022 Hyundai Elantra N sedan, grey color, side 3/4 front view, white studio background, photorealistic car photography',
  'kia|cerato':            '2022 Kia Cerato EX sedan, red color, side 3/4 front view, white studio background, photorealistic car photography',
  'peugeot|308':           '2015 Peugeot 308 sedan, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'citroen|c4 lounge':     '2020 Citroen C4 Lounge Feel sedan, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'ford|fusion':           '2018 Ford Fusion Titanium AWD sedan, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'byd|seal':              '2024 BYD Seal electric sedan, blue color, side 3/4 front view, white studio background, photorealistic car photography',
  'byd|king':              '2024 BYD King DM-i sedan, white color, side 3/4 front view, white studio background, photorealistic car photography',

  // ── SUVs ──
  'volkswagen|t-cross':    '2022 Volkswagen T-Cross Highline compact SUV, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'volkswagen|nivus':      '2022 Volkswagen Nivus Highline coupe SUV, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'volkswagen|tiguan':     '2022 Volkswagen Tiguan Allspace R-Line SUV, black color, side 3/4 front view, white studio background, photorealistic car photography',
  'volkswagen|taos':       '2022 Volkswagen Taos Highline SUV, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'chevrolet|tracker':     '2022 Chevrolet Tracker Premier Turbo compact SUV, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'chevrolet|equinox':     '2022 Chevrolet Equinox Premier SUV, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'chevrolet|trailblazer': '2022 Chevrolet Trailblazer Premier SUV, black color, side 3/4 front view, white studio background, photorealistic car photography',
  'chevrolet|blazer':      '1998 Chevrolet Blazer S10 SUV, dark green color, side 3/4 front view, white studio background, photorealistic car photography',
  'nissan|kicks':          '2022 Nissan Kicks SL compact SUV, orange color, side 3/4 front view, white studio background, photorealistic car photography',
  'nissan|x-trail':        '2022 Nissan X-Trail Exclusive SUV, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'nissan|murano':         '2020 Nissan Murano SL SUV, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'honda|hr-v':            '2020 Honda HR-V EXL compact SUV, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'honda|cr-v':            '2022 Honda CR-V EXL Turbo SUV, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'hyundai|creta':         '2022 Hyundai Creta Platinum SUV, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'hyundai|tucson':        '2022 Hyundai Tucson CRDI SUV, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'kia|sportage':          '2022 Kia Sportage SX compact SUV, red color, side 3/4 front view, white studio background, photorealistic car photography',
  'jeep|renegade':         '2022 Jeep Renegade Trailhawk compact SUV, granite gray color, side 3/4 front view, white studio background, photorealistic car photography',
  'jeep|compass':          '2022 Jeep Compass S 1.3 turbo SUV, black color, side 3/4 front view, white studio background, photorealistic car photography',
  'toyota|corolla cross':  '2023 Toyota Corolla Cross XRX compact SUV, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'toyota|rav4':           '2022 Toyota RAV4 Adventure AWD SUV, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'toyota|sw4':            '2022 Toyota SW4 Diamond 2.8 Diesel SUV, black color, side 3/4 front view, white studio background, photorealistic car photography',
  'renault|duster':        '2022 Renault Duster Iconic SUV, orange color, side 3/4 front view, white studio background, photorealistic car photography',
  'renault|captur':        '2022 Renault Captur Intense SUV, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'renault|kardian':       '2024 Renault Kardian Techno compact SUV, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'fiat|pulse':            '2023 Fiat Pulse Impetus 1.0 turbo compact SUV, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'fiat|fastback':         '2023 Fiat Fastback Audace coupe SUV, black color, side 3/4 front view, white studio background, photorealistic car photography',
  'peugeot|2008':          '2022 Peugeot 2008 Griffe compact SUV, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'peugeot|3008':          '2022 Peugeot 3008 Griffe THP SUV, dark grey color, side 3/4 front view, white studio background, photorealistic car photography',
  'citroen|c4 cactus':     '2020 Citroen C4 Cactus Feel compact SUV, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'citroen|c3 aircross':   '2022 Citroen C3 Aircross Shine compact SUV, orange color, side 3/4 front view, white studio background, photorealistic car photography',
  'ford|ecosport':         '2020 Ford EcoSport Titanium compact SUV, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'ford|territory':        '2022 Ford Territory Titanium SUV, black color, side 3/4 front view, white studio background, photorealistic car photography',
  'volvo|xc60':            '2022 Volvo XC60 T8 Inscription hybrid SUV, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'volvo|ex30':            '2024 Volvo EX30 electric compact SUV, blue color, side 3/4 front view, white studio background, photorealistic car photography',
  'peugeot|e-2008':        '2023 Peugeot e-2008 GT electric SUV, black color, side 3/4 front view, white studio background, photorealistic car photography',
  'ford|mustang mach-e':   '2023 Ford Mustang Mach-E GT electric SUV, dark red color, side 3/4 front view, white studio background, photorealistic car photography',
  'byd|song plus':         '2024 BYD Song Plus DM-i hybrid SUV, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'byd|yuan pro':          '2024 BYD Yuan Pro electric compact SUV, blue color, side 3/4 front view, white studio background, photorealistic car photography',
  'gwm|haval h6':          '2023 GWM Haval H6 SUV, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'chery|omoda 5':         '2023 Chery Omoda 5 1.5 turbo compact SUV, white color, side 3/4 front view, white studio background, photorealistic car photography',

  // ── PICAPES ──
  'fiat|strada':           '2022 Fiat Strada Endurance 1.4 pickup truck, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'fiat|toro':             '2022 Fiat Toro Freedom 1.3 turbo pickup truck, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'fiat|fiorino':          '2020 Fiat Fiorino Work pickup truck, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'volkswagen|saveiro':    '2022 Volkswagen Saveiro Trendline 1.6 pickup truck, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'volkswagen|amarok':     '2022 Volkswagen Amarok V6 Highline pickup truck, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'toyota|hilux':          '2023 Toyota Hilux SRX 2.8 Diesel double cab pickup truck, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'chevrolet|s10':         '2022 Chevrolet S10 LTZ 2.8 Diesel pickup truck, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'chevrolet|montana':     '2023 Chevrolet Montana Premier 1.2 turbo pickup truck, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'ford|ranger':           '2022 Ford Ranger XLS 2.5 flex pickup truck, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'ford|maverick':         '2023 Ford Maverick Lariat hybrid pickup truck, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'mitsubishi|l200':       '2023 Mitsubishi L200 Triton Sport HPE pickup truck, white color, side 3/4 front view, white studio background, photorealistic car photography',
  'nissan|frontier':       '2023 Nissan Frontier Platinum 2.3 biturbo pickup truck, black color, side 3/4 front view, white studio background, photorealistic car photography',
  'renault|oroch':         '2023 Renault Oroch Outsider pickup truck, orange color, side 3/4 front view, white studio background, photorealistic car photography',
  'ram|rampage':           '2023 RAM Rampage R/T pickup truck, red color, side 3/4 front view, white studio background, photorealistic car photography',

  // ── EXCLUSIVOS / GT ──
  'porsche|911 carrera':   '2022 Porsche 911 Carrera S 992 sports car, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'porsche|911 gt3':       '2022 Porsche 911 GT3 white race car, side 3/4 front view, white studio background, photorealistic car photography',
  'porsche|taycan':        '2023 Porsche Taycan Turbo S electric sedan, dark grey color, side 3/4 front view, white studio background, photorealistic car photography',
  'porsche|cayenne':       '2023 Porsche Cayenne GTS SUV, black color, side 3/4 front view, white studio background, photorealistic car photography',
  'porsche|panamera':      '2023 Porsche Panamera Turbo S executive sedan, silver color, side 3/4 front view, white studio background, photorealistic car photography',
  'porsche|macan':         '2023 Porsche Macan GTS compact SUV, red color, side 3/4 front view, white studio background, photorealistic car photography',
  'lamborghini|aventador': '2020 Lamborghini Aventador SVJ orange supercar, side 3/4 front view, white studio background, photorealistic car photography',
  'lamborghini|huracan':   '2022 Lamborghini Huracan EVO green supercar, side 3/4 front view, white studio background, photorealistic car photography',
  'lamborghini|urus':      '2023 Lamborghini Urus Pearl Capsule yellow SUV, side 3/4 front view, white studio background, photorealistic car photography',
  'lamborghini|revuelto':  '2023 Lamborghini Revuelto orange hybrid supercar, side 3/4 front view, white studio background, photorealistic car photography',
  'mclaren|720s':          '2021 McLaren 720S orange supercar, side 3/4 front view, white studio background, photorealistic car photography',
  'aston martin|db11':     '2021 Aston Martin DB11 AMR British racing green, side 3/4 front view, white studio background, photorealistic car photography',
  'bentley|continental gt':'2022 Bentley Continental GT Azure blue luxury coupe, side 3/4 front view, white studio background, photorealistic car photography',
  'maserati|mc20':         '2022 Maserati MC20 white supercar, side 3/4 front view, white studio background, photorealistic car photography',
  'chevrolet|camaro':      '2022 Chevrolet Camaro SS 6.2 V8 yellow muscle car, side 3/4 front view, white studio background, photorealistic car photography',
  'ford|mustang':          '2022 Ford Mustang GT 5.0 V8 dark blue muscle car, side 3/4 front view, white studio background, photorealistic car photography',
};

// =============================================================
// Normaliza a chave para busca no dicionario
// =============================================================
function normalize(s) {
  return s.toLowerCase()
    .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
    .trim();
}

function getPrompt(brand, model, version) {
  const key = `${normalize(brand)}|${normalize(model)}`;
  if (PROMPTS[key]) return PROMPTS[key];
  // Fallback generico melhorado com ano e versao
  return `${brand} ${model} ${version} car, realistic side 3/4 front view, white studio background, photorealistic car photography, highly detailed`;
}

// =============================================================
// Filtra veiculos sem imagem LOCAL ou com URL externa (Wikimedia =
// direitos autorais). Esses entram na fila para ganhar imagem IA.
// =============================================================
const missing = vehicles
  .filter(v => !v.thumbnail_url || v.thumbnail_url === '' || v.thumbnail_url.startsWith('http'))
  // URLs externas (Wikimedia etc.) primeiro: removem o risco de copyright antes
  .sort((a, b) => {
    const ea = (a.thumbnail_url || '').startsWith('http') ? 0 : 1;
    const eb = (b.thumbnail_url || '').startsWith('http') ? 0 : 1;
    return ea - eb;
  });
console.log(`\nEncontrados ${missing.length} sem imagem local.`);

const BATCH = Number(process.env.BATCH || 10);
const batch = missing.slice(0, BATCH);
if (batch.length === 0) {
  console.log('Nenhum pendente. Todas as imagens estao geradas!');
  process.exit(0);
}

console.log(`Gerando lote de ${batch.length}: ${batch.map(v => v.brand + ' ' + v.model).join(', ')}\n`);

// =============================================================
// Gera 1 imagem com retry
// =============================================================
async function genOne(v) {
  const brandSlug  = normalize(v.brand).replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '');
  const modelSlug  = normalize(v.model).replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '');
  const fileName   = `${brandSlug}_${modelSlug}.jpg`;
  const outPath    = path.join(OUT_DIR, fileName);

  // Se ja existe em disco, pula
  if (fs.existsSync(outPath) && fs.statSync(outPath).size > 10000) {
    console.log(`  SKIP ${fileName} (ja existe em disco)`);
    return fileName;
  }

  const prompt = getPrompt(v.brand, v.model, v.version);
  console.log(`  Gerando: ${v.brand} ${v.model}...`);
  console.log(`  Prompt: ${prompt.substring(0, 80)}...`);

  for (let attempt = 0; attempt < 3; attempt++) {
    const seed = Math.floor(Math.random() * 1000000);
    const url  = `https://image.pollinations.ai/prompt/${encodeURIComponent(prompt)}?width=1024&height=768&model=flux&seed=${seed}&nologo=true`;
    try {
      const r   = await fetch(url);
      const buf = Buffer.from(await r.arrayBuffer());

      if (buf.length < 10000) {
        console.log(`    Rate limit, aguardando 45s...`);
        await new Promise(r => setTimeout(r, 45000));
        continue;
      }

      fs.writeFileSync(outPath, buf);
      console.log(`    OK ${fileName} (${(buf.length / 1024).toFixed(0)}KB)`);
      await new Promise(r => setTimeout(r, 35000)); // respeita rate limit
      return fileName;
    } catch (e) {
      console.log(`    Erro: ${e.message}`);
      await new Promise(r => setTimeout(r, 10000));
    }
  }
  return null;
}

// =============================================================
// Loop principal: gera e atualiza vehicles.js
// =============================================================
(async () => {
  let text = fs.readFileSync(path.join(__dirname, 'data', 'vehicles.js'), 'utf8');
  let ok   = 0;

  for (const v of batch) {
    const fn = await genOne(v);
    if (fn) {
      const asset = `assets/images/vehicles/${fn}`;
      const escB  = v.brand.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const escM  = v.model.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const escV  = v.version.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const re    = new RegExp(
        `(brand: '${escB}',\\s+model: '${escM}',\\s+version: '${escV}',[\\s\\S]*?thumbnail_url: )'[^']*'`
      );
      text = text.replace(re, `$1'${asset}'`);
      ok++;
    }
  }

  fs.writeFileSync(path.join(__dirname, 'data', 'vehicles.js'), text, 'utf8');
  console.log(`\n${ok}/${batch.length} imagens geradas. Total em disco: ${fs.readdirSync(OUT_DIR).length}`);
  console.log('Rode novamente para gerar o proximo lote de 10.\n');
})();
