// Cria o índice composto do Firestore para a tela de categorias:
//   vehicles: verdict ASC + brand_model_lower ASC
// Usa scripts/serviceAccountKey.json (Firebase Admin) para obter o token OAuth.
const fs = require('fs');
const path = require('path');
const { JWT } = require('F:/Kiro Projetcts/zoeira_car/scripts/node_modules/google-auth-library');

const SA = JSON.parse(
  fs.readFileSync('F:/Kiro Projetcts/zoeira_car/scripts/serviceAccountKey.json', 'utf8'),
);

const PROJECT = SA.project_id;
const BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/collectionGroups/vehicles/indexes`;

async function main() {
  const client = new JWT({
    email: SA.client_email,
    key: SA.private_key,
    scopes: ['https://www.googleapis.com/auth/datastore'],
  });
  const token = await client.getAccessToken();
  const headers = { Authorization: `Bearer ${token.token}` };

  // 1. Lista índices atuais
  const listRes = await fetch(BASE, { headers });
  const list = await listRes.json();
  const indexes = list.indexes || [];
  console.log('Índices existentes:', indexes.length);

  const exists = indexes.some((idx) =>
    idx.queryScope === 'COLLECTION' &&
    idx.fields.length === 2 &&
    idx.fields[0].fieldPath === 'verdict' &&
    idx.fields[0].order === 'ASCENDING' &&
    idx.fields[1].fieldPath === 'brand_model_lower' &&
    idx.fields[1].order === 'ASCENDING',
  );

  if (exists) {
    console.log('✅ Índice verdict+brand_model_lower já existe (ou está criando).');
    return;
  }

  // 2. Cria o índice
  const body = {
    queryScope: 'COLLECTION',
    fields: [
      { fieldPath: 'verdict', order: 'ASCENDING' },
      { fieldPath: 'brand_model_lower', order: 'ASCENDING' },
    ],
  };
  const createRes = await fetch(BASE, {
    method: 'POST',
    headers: { ...headers, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const created = await createRes.json();
  if (createRes.ok) {
    console.log('✅ Índice criado! Estado:', created.state, '| Nome:', created.name);
    console.log('   (Fica READY em ~1-2 minutos; enquanto isso a tela pode dar erro)');
  } else {
    console.error('❌ Erro ao criar índice:', JSON.stringify(created));
    process.exit(1);
  }
}

main().catch((e) => {
  console.error('Erro:', e.message);
  process.exit(1);
});