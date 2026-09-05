// Configura o secret PLAY_STORE_SERVICE_ACCOUNT_JSON no GitHub Actions via API.
const fs = require('fs');
const sodium = require('F:/Kiro Projetcts/zoeira_car/scripts/node_modules/libsodium-wrappers');

const REPO = 'kaidan41/zoeira-car';
const BASE = 'https://api.github.com';
const SA_FILE = 'C:/Users/MLTEC/Downloads/zoeira-car-27d7431011f8.json';

async function main() {
  await sodium.ready;
  const token = fs.readFileSync('.freebuff/gh_token.tmp', 'utf8').trim();
  const headers = {
    Authorization: `token ${token}`,
    Accept: 'application/vnd.github+json',
  };

  // Valida o JSON da conta de serviço antes de enviar
  let saJson;
  try {
    saJson = fs.readFileSync(SA_FILE, 'utf8');
    const parsed = JSON.parse(saJson);
    if (parsed.type !== 'service_account' || !parsed.client_email) {
      console.error('JSON inválido: não parece uma conta de serviço.');
      process.exit(1);
    }
    console.log('Conta de serviço lida:', parsed.client_email);
  } catch (e) {
    console.error('Erro ao ler o JSON:', e.message);
    process.exit(1);
  }

  const pkRes = await fetch(`${BASE}/repos/${REPO}/actions/secrets/public-key`, { headers });
  const { key_id, key } = await pkRes.json();
  if (!key_id) {
    console.error('Falha ao obter public key:', await pkRes.text());
    process.exit(1);
  }

  const pk = sodium.from_base64(key, sodium.base64_variants.ORIGINAL);
  const enc = sodium.crypto_box_seal(Buffer.from(saJson, 'utf8'), pk);
  const encrypted_value = sodium.to_base64(enc, sodium.base64_variants.ORIGINAL);

  const res = await fetch(`${BASE}/repos/${REPO}/actions/secrets/PLAY_STORE_SERVICE_ACCOUNT_JSON`, {
    method: 'PUT',
    headers: { ...headers, 'Content-Type': 'application/json' },
    body: JSON.stringify({ encrypted_value, key_id }),
  });

  if (res.ok) {
    console.log('PLAY_STORE_SERVICE_ACCOUNT_JSON: OK ✓');
  } else {
    console.log(`ERRO ${res.status} — ${await res.text()}`);
    process.exit(1);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});