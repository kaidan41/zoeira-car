// Configura os secrets de assinatura do GitHub Actions via API.
// Não imprime valores sensíveis (senhas) — só o status de cada secret.
const fs = require('fs');
const sodiumPath = 'F:/Kiro Projetcts/zoeira_car/scripts/node_modules/libsodium-wrappers';
const sodium = require(sodiumPath);

const REPO = 'kaidan41/zoeira-car';
const BASE = 'https://api.github.com';

function getGitToken() {
  // Token salvo em .freebuff/gh_token.tmp pelo bash (Windows nao tem printf)
  const out = fs.readFileSync('.freebuff/gh_token.tmp', 'utf8').trim();
  fs.rmSync('.freebuff/gh_token.tmp', { force: true });
  return out;
}

function readProp(key) {
  const props = fs.readFileSync('android/key.properties', 'utf8');
  const line = props.split('\n').find((l) => l.startsWith(key + '='));
  if (!line) return '';
  return line.split('=').slice(1).join('=').trim();
}

async function main() {
  await sodium.ready;
  const token = getGitToken();
  const headers = {
    Authorization: `token ${token}`,
    Accept: 'application/vnd.github+json',
  };

  const pkRes = await fetch(`${BASE}/repos/${REPO}/actions/secrets/public-key`, { headers });
  const { key_id, key } = await pkRes.json();
  if (!key_id) {
    console.error('Falha ao obter public key:', await pkRes.text());
    process.exit(1);
  }

  const seal = (value) => {
    const pk = sodium.from_base64(key, sodium.base64_variants.ORIGINAL);
    const enc = sodium.crypto_box_seal(Buffer.from(value, 'utf8'), pk);
    return sodium.to_base64(enc, sodium.base64_variants.ORIGINAL);
  };

  const secrets = {
    KEYSTORE_BASE64: fs.readFileSync('android/app/zoeira_car.jks').toString('base64'),
    KEY_STORE_PASSWORD: readProp('storePassword'),
    KEY_PASSWORD: readProp('keyPassword'),
    KEY_ALIAS: readProp('keyAlias') || 'zoeira_car',
  };

  for (const [name, value] of Object.entries(secrets)) {
    if (!value) {
      console.log(`${name}: SKIP (valor vazio)`);
      continue;
    }
    const body = JSON.stringify({ encrypted_value: seal(value), key_id });
    const res = await fetch(`${BASE}/repos/${REPO}/actions/secrets/${name}`, {
      method: 'PUT',
      headers: { ...headers, 'Content-Type': 'application/json' },
      body,
    });
    if (res.ok) {
      console.log(`${name}: OK ✓`);
    } else {
      console.log(`${name}: ERRO ${res.status} — ${await res.text()}`);
    }
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});