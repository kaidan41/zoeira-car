// Read-only: distinct brand|model in seed + gap check for candidate models.
const vehicles = require('../scripts/data/vehicles.js');
const norm = (s) => String(s || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').trim();
const set = new Set(vehicles.map((v) => `${norm(v.brand)} ${norm(v.model)}`));

const candidates = [
  'Jeep Commander', 'Jeep Wrangler', 'Volkswagen Fox', 'Chevrolet Agile', 'Chevrolet Meriva',
  'Fiat Linea', 'Fiat Bravo', 'Honda WR-V', 'Hyundai ix35', 'Hyundai HB20X', 'Nissan Livina',
  'Ford Focus', 'Chevrolet Cobalt', 'Kia Soul', 'Kia Sorento', 'Mitsubishi ASX', 'Mitsubishi Outlander',
  'Mitsubishi Pajero Sport', 'BMW X1', 'Audi Q3', 'Audi A3', 'Mercedes-Benz GLA', 'Mercedes-Benz C 180',
  'Volvo XC40', 'RAM 1500', 'GWM Tank 300', 'BYD Yuan Plus', 'BYD King', 'Renault Kardian',
  'Citroën Basalt', 'Peugeot 408', 'Toyota Yaris Cross', 'Kia K3', 'Honda Civic Type R', 'Toyota GR Corolla',
  'Volkswagen Jetta GLI', 'Fiat Fastback', 'Caoa Chery Tiggo 7', 'Chevrolet Tracker', 'Nissan Kicks',
];
console.log('Candidatos que NÃO estão no catálogo (seed):');
const absent = [];
for (const c of candidates) {
  const n = norm(c);
  const inSet = [...set].some((s) => s === n || s.startsWith(n + ' ') || s.endsWith(' ' + n.split(' ').slice(1).join(' ')) && s.split(' ')[0] === n.split(' ')[0]);
  if (!inSet) { absent.push(c); console.log('  -', c); }
}
console.log('\nausentes:', absent.length);
console.log('\nTotal distinct models:', set.size);
