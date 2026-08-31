import {
  jwtVerify,
  SignJWT,
  importPKCS8,
  createRemoteJWKSet,
} from "jose";

// ---------------------------------------------------------------
// Configuração do projeto
// ---------------------------------------------------------------

const PROJECT_ID = "zoeira-car";
const PACKAGE_NAME = "com.zoeiarcartv.app";
const SUBSCRIPTION_PRODUCT = "zoeira_car_mensal";
const CONSULTA_PRODUCT = "zoeira_consulta";
const TOKEN_COL = "purchase_tokens";

const FS_BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
const PUBLISHER_BASE = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE_NAME}`;

const firebaseJwks = createRemoteJWKSet(
  new URL(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  ),
);

const GOOGLE_CDN_KEYS = createRemoteJWKSet(
  new URL("https://www.googleapis.com/oauth2/v3/certs"),
);

let cachedToken = null;

// ---------------------------------------------------------------
// Helpers de resposta
// ---------------------------------------------------------------

function ok(payload = {}) {
  return new Response(JSON.stringify({ ok: true, ...payload }), {
    headers: { "content-type": "application/json" },
  });
}

function fail(code, message, status = 200) {
  return new Response(JSON.stringify({ ok: false, code, message }), {
    status,
    headers: { "content-type": "application/json" },
  });
}

// ---------------------------------------------------------------
// OAuth: service account (JSON da GCP) em access_token + cache
// ---------------------------------------------------------------

function extractCredential(env) {
  const raw = env.PLAY_SERVICE_ACCOUNT_JSON;
  if (!raw || !raw.trim()) {
    throw new Error("PLAY_SERVICE_ACCOUNT_JSON não configurado no Worker.");
  }
  return JSON.parse(raw);
}

async function accessToken(env) {
  const nowSec = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.exp > nowSec + 60) {
    return cachedToken.token;
  }

  const sa = extractCredential(env);
  const key = await importPKCS8(sa.private_key, "RS256");

  const jwt = await new SignJWT({
    scope:
      "https://www.googleapis.com/auth/androidpublisher https://www.googleapis.com/auth/datastore",
  })
    .setProtectedHeader({ alg: "RS256" })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(nowSec)
    .setExpirationTime(nowSec + 3600)
    .sign(key);

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${encodeURIComponent(jwt)}`,
  });

  const data = await res.json();
  if (!data.access_token) {
    throw new Error("Falha na troca do token OAuth com a GCP.");
  }

  cachedToken = {
    token: data.access_token,
    exp: nowSec + Number(data.expires_in || 3600) - 120,
  };
  return cachedToken.token;
}

// ---------------------------------------------------------------
// Autenticação do app: valida o ID token do Firebase Auth
// ---------------------------------------------------------------

async function verifyUser(authHeader) {
  const idToken = authHeader?.replace(/^Bearer\s+/i, "");
  if (!idToken) return null;
  try {
    const { payload } = await jwtVerify(idToken, firebaseJwks, {
      issuer: `https://securetoken.google.com/${PROJECT_ID}`,
      audience: PROJECT_ID,
    });
    if (!payload.uid) return null;
    return payload.uid;
  } catch {
    return null;
  }
}

// ---------------------------------------------------------------
// Firestore REST (com service account via *datastore* scope)
// ---------------------------------------------------------------

function docName(col, id) {
  return `${FS_BASE}/${col}/${encodeURIComponent(id)}`;
}

async function fsGet(token, col, id) {
  const res = await fetch(docName(col, id), {
    headers: { authorization: `Bearer ${token}` },
  });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`firestore get ${col}/${id} → ${res.status}`);
  return res.json();
}

async function fsCommit(token, writes) {
  const res = await fetch(`${FS_BASE}:commit`, {
    method: "POST",
    headers: {
      authorization: `Bearer ${token}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({ writes }),
  });
  if (!res.ok) {
    const text = await res.text();
    const e = new Error(`firestore commit → ${res.status} ${text.slice(0, 200)}`);
    e.status = res.status;
    throw e;
  }
  return res.json();
}

function fieldValue(doc, field) {
  const f = doc?.fields?.[field];
  if (f === undefined || f === null) return undefined;
  if (f.stringValue !== undefined) return f.stringValue;
  if (f.integerValue !== undefined) return Number(f.integerValue);
  if (f.booleanValue !== undefined) return f.booleanValue;
  if (f.doubleValue !== undefined) return Number(f.doubleValue);
  if (f.timestampValue !== undefined) return f.timestampValue;
  if (f.arrayValue !== undefined) {
    return (f.arrayValue.values ?? []).map((v) => v.stringValue ?? v.integerValue ?? v.booleanValue);
  }
  return undefined;
}

function arrayField(doc, field) {
  const v = fieldValue(doc, field);
  return Array.isArray(v) ? v : [];
}

async function getUserCredits(token, uid) {
  const doc = await fsGet(token, "users", uid);
  return Number(fieldValue(doc, "consulta_credits") ?? 0);
}

// ---------------------------------------------------------------
// API do Google Play (Android Publisher v3)
// ---------------------------------------------------------------

async function playGet(token, path) {
  const res = await fetch(`${PUBLISHER_BASE}/${path}`, {
    headers: { authorization: `Bearer ${token}` },
  });
  if (res.status === 200) return res.json();
  const text = await res.text();
  const e = new Error(`play ${res.status} ${text.slice(0, 300)}`);
  e.status = res.status;
  throw e;
}

async function playAck(token, path, uid) {
  await fetch(`${PUBLISHER_BASE}/${path}/acknowledgements`, {
    method: "POST",
    headers: {
      authorization: `Bearer ${token}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({ developerPayload: uid }),
  });
}

// ---------------------------------------------------------------
// /purchase — valida o recibo e concede o acesso (idempotente)
// ---------------------------------------------------------------

async function completePurchase(uid, { productId, purchaseToken }, env) {
  const token = await accessToken(env);

  if (productId === SUBSCRIPTION_PRODUCT) {
    const subPath = `purchases/subscriptions/${SUBSCRIPTION_PRODUCT}/tokens/${encodeURIComponent(purchaseToken)}`;
    let p;
    try {
      p = await playGet(token, subPath);
    } catch (e) {
      const err = new Error(
        "Token de compra inválido ou não reconhecido pela Play Store.",
      );
      err.invalidToken = true;
      throw err;
    }

    if (Number(p.paymentState ?? 0) === 0) {
      const e = new Error(
        "Pagamento ainda pendente na Play Store. Conclua e tente de novo.",
      );
      e.pending = true;
      throw e;
    }

    const now = Date.now();
    const expiryMs = Number(p.expiryTimeMillis || now);
    const status = expiryMs > now ? "active" : "expired";

    await fsCommit(token, [
      {
        update: {
          name: docName("subscriptions", uid),
          fields: {
            status: { stringValue: status },
            purchase_token: { stringValue: purchaseToken },
            product_id: { stringValue: SUBSCRIPTION_PRODUCT },
            start_date: {
              timestampValue: new Date(Number(p.startTimeMillis) || now).toISOString(),
            },
            expiry_date: { timestampValue: new Date(expiryMs).toISOString() },
            auto_renewing: { booleanValue: Boolean(p.autoRenewing) },
            verified_at: { timestampValue: new Date().toISOString() },
            updated_at: { timestampValue: new Date().toISOString() },
          },
        },
      },
    ]);

    await playAck(token, subPath, uid);

    return {
      productId,
      status,
      expiryTimeMillis: expiryMs,
      autoRenewing: Boolean(p.autoRenewing),
    };
  }

  if (productId === CONSULTA_PRODUCT) {
    const productPath = `purchases/products/${CONSULTA_PRODUCT}/tokens/${encodeURIComponent(purchaseToken)}`;
    let p;
    try {
      p = await playGet(token, productPath);
    } catch (e) {
      const err = new Error(
        "Token de compra inválido ou não reconhecido pela Play Store.",
      );
      err.invalidToken = true;
      throw err;
    }

    if (Number(p.purchaseState ?? 1) !== 0) {
      const e = new Error("Compra cancelada ou não concluída na Play Store.");
      e.invalidToken = true;
      throw e;
    }

    const key = await sha256(`${CONSULTA_PRODUCT}|${purchaseToken}`);
    const tokenDoc = docName(TOKEN_COL, key);

    try {
      await fsCommit(token, [
        {
          update: {
            name: tokenDoc,
            fields: {
              uid: { stringValue: uid },
              productId: { stringValue: CONSULTA_PRODUCT },
              purchaseToken: { stringValue: purchaseToken },
              granted_at: { timestampValue: new Date().toISOString() },
            },
          },
          currentDocument: { exists: false },
        },
        {
          update: {
            name: docName("users", uid),
            fields: {
              last_product_id: { stringValue: CONSULTA_PRODUCT },
              last_purchase_at: { timestampValue: new Date().toISOString() },
            },
          },
        },
        {
          transform: {
            document: docName("users", uid),
            fieldTransforms: [{ fieldPath: "consulta_credits", increment: 1 }],
          },
        },
      ]);
    } catch (e) {
      if (e.status === 409 || e.status === 412) {
        return {
          productId,
          alreadyGranted: true,
          credits: await getUserCredits(token, uid),
        };
      }
      throw e;
    }

    await playAck(token, productPath, uid);

    return {
      productId,
      alreadyGranted: false,
      credits: await getUserCredits(token, uid),
    };
  }

  const e = new Error(`Produto não suportado: ${productId}`);
  e.invalidToken = true;
  throw e;
}

// ---------------------------------------------------------------
// /unlock — transação no servidor: crédito → desbloqueio
// ---------------------------------------------------------------

async function unlockVehicle(uid, { vehicleId }, env) {
  const token = await accessToken(env);

  if (!vehicleId || typeof vehicleId !== "string" || vehicleId.length > 120) {
    throw new Error("Veículo inválido.");
  }

  const sub = await fsGet(token, "subscriptions", uid);
  const subExpiry = sub
    ? new Date(fieldValue(sub, "expiry_date") || 0).getTime()
    : 0;
  if (fieldValue(sub, "status") === "active" && subExpiry > Date.now()) {
    return { unlocked: true, method: "subscription" };
  }

  for (let attempt = 0; attempt < 5; attempt++) {
    const doc = await fsGet(token, "users", uid);
    if (arrayField(doc, "unlocked_vehicle_ids").includes(vehicleId)) {
      return { unlocked: true, method: "already" };
    }
    const credits = Number(fieldValue(doc, "consulta_credits") ?? 0);
    if (credits < 1) {
      const e = new Error(
        "Sem créditos de consulta avulsa. Compre uma consulta ou assine.",
      );
      e.noCredits = true;
      throw e;
    }

    const precondition = doc?.updateTime
      ? { currentDocument: { updateTime: doc.updateTime } }
      : undefined;

    try {
      await fsCommit(token, [
        {
          transform: {
            document: docName("users", uid),
            fieldTransforms: [
              { fieldPath: "consulta_credits", increment: -1 },
              {
                fieldPath: "unlocked_vehicle_ids",
                appendMissingElements: { values: [{ stringValue: vehicleId }] },
              },
            ],
          },
          ...precondition,
        },
      ]);
      return { unlocked: true, method: "credit" };
    } catch (e) {
      if (attempt === 4) throw e;
    }
  }

  throw new Error("Falha ao desbloquear a nave. Tente de novo.");
}

// ---------------------------------------------------------------
// /verify — revalida e devolve o estado real (start/restore)
// ---------------------------------------------------------------

async function verifyEntitlements(uid, env) {
  const token = await accessToken(env);

  const userDoc = await fsGet(token, "users", uid);
  const credits = Number(fieldValue(userDoc, "consulta_credits") ?? 0);
  const unlockedVehicleIds = arrayField(userDoc, "unlocked_vehicle_ids");

  const subDoc = await fsGet(token, "subscriptions", uid);
  if (!subDoc?.fields?.purchase_token) {
    return { hasSubscription: false, subscription: null, credits, unlockedVehicleIds };
  }

  const verifiedAt = subDoc.fields.verified_at?.timestampValue
    ? new Date(subDoc.fields.verified_at.timestampValue).getTime()
    : 0;
  let expiryMs = subDoc.fields.expiry_date?.timestampValue
    ? new Date(subDoc.fields.expiry_date.timestampValue).getTime()
    : 0;

  const stale =
    !verifiedAt ||
    Date.now() - verifiedAt > 6 * 60 * 60 * 1000 ||
    expiryMs - Date.now() < 24 * 60 * 60 * 1000;

  if (stale) {
    const purchaseToken = subDoc.fields.purchase_token.stringValue;
    const productId = subDoc.fields.product_id?.stringValue || SUBSCRIPTION_PRODUCT;
    try {
      const p = await playGet(
        token,
        `purchases/subscriptions/${productId}/tokens/${encodeURIComponent(purchaseToken)}`,
      );
      expiryMs = Number(p.expiryTimeMillis || expiryMs);
      const now = Date.now();
      const status = expiryMs > now ? "active" : "expired";
      await fsCommit(token, [
        {
          update: {
            name: docName("subscriptions", uid),
            fields: {
              status: { stringValue: status },
              expiry_date: { timestampValue: new Date(expiryMs).toISOString() },
              auto_renewing: { booleanValue: Boolean(p.autoRenewing) },
              verified_at: { timestampValue: new Date().toISOString() },
              updated_at: { timestampValue: new Date().toISOString() },
            },
          },
        },
      ]);
    } catch {
      // API indisponível: mantém o que está no Firestore
    }
  }

  const hasSubscription =
    fieldValue(subDoc, "status") === "active" && expiryMs > Date.now();

  return {
    hasSubscription,
    subscription: hasSubscription
      ? {
          status: "active",
          productId: subDoc.fields.product_id?.stringValue,
          expiryTimeMillis: expiryMs,
          autoRenewing: Boolean(fieldValue(subDoc, "auto_renewing")),
        }
      : null,
    credits,
    unlockedVehicleIds,
  };
}

// ---------------------------------------------------------------
// /webhook/play — RTDN do Google Play (Pub/Sub push). Opcional:
// renovações/cancelamentos atualizam o Firestore sozinhas.
// ---------------------------------------------------------------

async function webhookPlay(request, env) {
  const bearer = request.headers.get("authorization")?.replace(/^Bearer\s+/i, "");
  if (!bearer) return fail("unauthorized", "sem token", 401);

  let claim;
  try {
    const { payload } = await jwtVerify(bearer, GOOGLE_CDN_KEYS, {
      issuer: "https://accounts.google.com",
    });
    claim = payload;
  } catch {
    return fail("unauthorized", "token inválido", 401);
  }

  const audOk =
    claim.email_verified === true &&
    claim.email === "cloud-pubsub@system.gserviceaccount.com" &&
    typeof claim.aud === "string" &&
    claim.aud.indexOf(new URL(request.url).origin) === 0;
  if (!audOk) return fail("unauthorized", "chamador não permitido", 401);

  let envelope;
  try {
    envelope = await request.json();
  } catch {
    return fail("invalid", "JSON inválido no webhook.", 200);
  }

  let message = null;
  try {
    const data64 = envelope?.message?.data ?? "";
    message = JSON.parse(atob(data64));
  } catch {
    /* ignore */
  }

  if (!message?.subscriptionNotification) return ok();

  const { purchaseToken, subscriptionId } = message.subscriptionNotification;
  const token = await accessToken(env);

  const docs = await fsQuery(token, "subscriptions", "purchase_token", purchaseToken);
  if (!docs.length) return ok();

  try {
    const p = await playGet(
      token,
      `purchases/subscriptions/${subscriptionId || SUBSCRIPTION_PRODUCT}/tokens/${encodeURIComponent(purchaseToken)}`,
    );
    const now = Date.now();
    const expiryMs = Number(p.expiryTimeMillis || now);
    const status = expiryMs > now ? "active" : "expired";

    await fsCommit(
      token,
      docs.map((doc) => ({
        update: {
          name: doc.name,
          fields: {
            status: { stringValue: status },
            expiry_date: { timestampValue: new Date(expiryMs).toISOString() },
            auto_renewing: { booleanValue: Boolean(p.autoRenewing) },
            verified_at: { timestampValue: new Date().toISOString() },
            updated_at: { timestampValue: new Date().toISOString() },
          },
        },
      })),
    );
  } catch {
    // Webhook fire-and-forget: falhas não derrubam o app.
  }

  return ok();
}

async function fsQuery(token, collectionId, field, value) {
  const res = await fetch(`${FS_BASE}:runQuery`, {
    method: "POST",
    headers: {
      authorization: `Bearer ${token}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      structuredQuery: {
        from: [{ collectionId }],
        where: {
          fieldFilter: {
            field: { fieldPath: field },
            op: "EQUAL",
            value: { stringValue: value },
          },
        },
        limit: 10,
      },
    }),
  });
  if (!res.ok) return [];
  const rows = await res.json();
  return rows.filter((r) => r.document).map((r) => r.document);
}

// ---------------------------------------------------------------
// Util + roteador
// ---------------------------------------------------------------

async function sha256(text) {
  const data = new TextEncoder().encode(text);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === "/webhook/play") return webhookPlay(request, env);
    if (request.method !== "POST") return fail("not_found", "rota não encontrada", 404);

    let body = {};
    try {
      body = await request.json();
    } catch {
      return fail("invalid", "JSON inválido no corpo da requisição.");
    }

    const uid = await verifyUser(request.headers.get("authorization"));
    if (!uid) return fail("unauthenticated", "Faça login para continuar.", 401);

    try {
      if (url.pathname === "/purchase") return ok(await completePurchase(uid, body, env));
      if (url.pathname === "/unlock") return ok(await unlockVehicle(uid, body, env));
      if (url.pathname === "/verify") return ok(await verifyEntitlements(uid, env));
    } catch (e) {
      if (e.pending) return fail("pending", e.message);
      if (e.noCredits) return fail("no_credits", e.message);
      if (e.invalidToken) return fail("invalid_token", e.message);
      console.error(e);
      return fail("internal", "Falha na validação com o Google Play.", 500);
    }

    return fail("not_found", "rota não encontrada", 404);
  },
};