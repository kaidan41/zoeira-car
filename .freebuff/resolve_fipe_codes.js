// Resolve códigos FIPE corretos para os 5 veículos que têm fipe_code no Firestore.
// Usa Parallelum v1: marcas -> modelos -> anos -> preço (que traz CodigoFipe).
const admin = require('F:/Kiro Projetcts/zoeira_car/scripts/node_modules/firebase-admin');

const norm = (s) =>
  String(s).toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');

const BASE = 'https://parallelum.com.br/fipe/api/v1/carros';

async function get(url) {
  const r = await fetch(url);
  if (!r.ok) throw new Error(`${r.status} ${url}`);
  return r.json();
}

// brand | filtros de modelo | ano preferido
const ALVOS = [
  { brand: 'volkswagen', modelKeys: ['gol', '1.6', 'mi', '8v'], year: 1994, nome: 'VW Gol Quadrado' },
  { brand: 'fiat', modelKeys: ['marea', 'turbo'], year: 2003, nome: 'Fiat Marea Turbo' },
  { brand: 'honda', modelKeys: ['civic', 'turbo'], year: 2020, nome: 'Honda Civic 1.5 Turbo' },
  { brand: 'chevrolet', modelKeys: ['onix', 'tb'], year: 2020, nome: 'Chevrolet Onix 1.0 TB' },
  { brand: 'toyota', modelKeys: ['corolla', 'xei', '2.0'], year: 2020, nome: 'Toyota Corolla XEi 2.0' },
];

(async () => {
  const marcas = await get(`${BASE}/marcas`);
  const resultado = [];

  for (const alvo of ALVOS) {
    const marca = marcas.find((m) => norm(m.nome).includes(alvo.brand));
    if (!marca) { console.log(`${alvo.nome}: MARCA NAO ACHADA`); continue; }

    const { modelos } = await get(`${BASE}/marcas/${marca.codigo}/modelos`);
    const cands = modelos.filter((m) =>
      alvo.modelKeys.every((k) => norm(m.nome).includes(k)),
    );
    if (cands.length === 0) {
      console.log(`${alvo.nome}: NENHUM MODELO com ${alvo.modelKeys.join('+')}`);
      continue;
    }

    let achou = null;
    for (const m of cands.slice(0, 5)) {
      try {
        const anos = await get(`${BASE}/marcas/${marca.codigo}/modelos/${m.codigo}/anos`);
        // Ano preferido ou o mais próximo abaixo dele
        let best = anos[0];
        for (const a of anos) {
          const y = parseInt(a.nome, 10);
          if (!isNaN(y)) {
            if (best === anos[0]) best = a;
            if (Math.abs(y - alvo.year) < Math.abs(parseInt(best.nome, 10) - alvo.year)) {
              best = a;
            }
          }
        }
        const preco = await get(
          `${BASE}/marcas/${marca.codigo}/modelos/${m.codigo}/anos/${best.codigo}`,
        );
        achou = { modelo: m.nome, ano: best.nome, codigoFipe: preco.CodigoFipe, valor: preco.Valor };
        break;
      } catch (e) {
        // tenta próximo modelo
      }
    }

    if (achou) {
      resultado.push({ nome: alvo.nome, ...achou });
      console.log(`✅ ${alvo.nome}: ${achou.modelo} (${achou.ano}) => FIPE ${achou.codigoFipe} ${achou.valor}`);
    } else {
      console.log(`❌ ${alvo.nome}: nao resolveu`);
    }
  }

  // Grava resultado num arquivo temporário para o próximo passo
  require('fs').writeFileSync(
    'F:/Kiro Projetcts/zoeira_car/.freebuff/fipe_resolved.json',
    JSON.stringify(resultado, null, 2),
  );
  console.log('\nResultado salvo em .freebuff/fipe_resolved.json');
})().catch((e) => { console.error('ERRO:', e.message); process.exit(1); });