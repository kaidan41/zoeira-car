// Alinha thumbnail_url de TODAS as entradas do seed aos arquivos reais em
// assets/images/vehicles, usando a normalização canônica do projeto.
// - thumb existente e válido → mantém
// - thumb quebrado → substitui pelo canônico se existir, senão ''
// - thumb vazio → canônico se existir, senão '' (fallback sem erro)
// Uso: node .freebuff/fix_seed_thumbs.js
const fs = require('fs');
const path = require('path');
const FILE = path.join(__dirname, '..', 'scripts', 'data', 'vehicles.js');
const OUT_DIR = path.join(__dirname, '..', 'assets', 'images', 'vehicles');
const disk = new Set(fs.readdirSync(OUT_DIR));

function norm(s) {
  return String(s || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '').trim();
}
const canonical = (b, m) => `assets/images/vehicles/${norm(b)}_${norm(m)}.jpg`;

let text = fs.readFileSync(FILE, 'utf8');
const vehicles = require(FILE);
let changed = 0;
const reEntry = /(\n  \{\r?\n)([\s\S]*?)(\n  \},)/g; // bloco de uma entrada

// estratégia simples: por índice, refaz o texto bloco a bloco
const lines = text.split(/\r?\n/);
// localiza os índices de linha de cada entrada
const starts = [];
for (let i = 0; i < lines.length; i++) {
  if (/^\s*\{\s*$/.test(lines[i]) && i > 0) starts.push(i);
}

function replaceAt(target, idx, replacement) {
  return target.slice(0, idx) + replacement + target.slice(idx + 1);
}

// monta o texto bloco por bloco procurando a entrada pela sequência brand/model/version
for (const v of vehicles) {
  const want = canonical(v.brand, v.model);
  const cur = v.thumbnail_url || '';
  let next = cur;
  if (cur && cur.startsWith('assets/')) {
    const f = cur.split('/').pop();
    if (disk.has(f)) continue; // já ok
    next = disk.has(want.split('/').pop()) ? want : '';
  } else if (!cur) {
    next = disk.has(want.split('/').pop()) ? want : '';
  } else {
    continue; // http etc. — não mexe
  }
  if (next === cur) continue;
  changed++;
  // regex por entrada exata: brand/model/version em sequência no bloco
  const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const re = new RegExp(
    `(brand: '${esc(v.brand)}',\\s+model: '${esc(v.model)}',\\s+version: '${esc(v.version)}',[\\s\\S]*?thumbnail_url: )'[^']*'`
  );
  const m = text.match(re);
  if (m) {
    text = text.replace(re, `$1'${next}'`);
    console.log(`${v.brand} ${v.model} ${v.version}: '${cur}' → '${next}'`);
  } else {
    console.log(`⚠️  não achei bloco para ${v.brand} ${v.model} ${v.version}`);
  }
}
fs.writeFileSync(FILE, text, 'utf8');
console.log(`\n${changed} thumbnails ajustados.`);
