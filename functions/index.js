const { onCall, HttpsError, onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');
const crypto = require('crypto');
const { google } = require('googleapis');
const { OAuth2Client } = require('google-auth-library');

admin.initializeApp();

const PLAY_SCOPE = 'https://www.googleapis.com/auth/androidpublisher';
const PACKAGE_NAME = 'com.zoeiarcartv.app';
const SUBSCRIPTION_PRODUCT = 'zoeira_car_mensal';
const CONSULTA_PRODUCT = 'zoeira_consulta';

const playSecret = defineSecret('PLAY_SERVICE_ACCOUNT_JSON');

// ---------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------

function userRef(uid) {
  return admin.firestore().collection('users').doc(uid);
}

function subRef(uid) {
  return admin.firestore().collection('subscriptions').doc(uid);
}

function tokenId(productId, token) {
  return crypto.createHash('sha256').update(`${productId}|${token}`).digest('hex');
}

async function publisherClient() {
  const raw = process.env.PLAY_SERVICE_ACCOUNT_JSON;
  const auth = raw && raw.trim()
    ? new google.auth.GoogleAuth({
        credentials: JSON.parse(raw),
        scopes: [PLAY_SCOPE],
      })
    : new google.auth.GoogleAuth({ scopes: [PLAY_SCOPE] });
  return google.androidpublisher({ version: 'v3', auth });
}

function mapPlayError(e) {
  const statusCode = Number(e?.status ?? 0);
  const details = String(e?.errors?.[0]?.message ?? e?.message ?? '');
  if (statusCode === 401 || statusCode === 403) {
    return new HttpsError(
      'permission-denied',
      'Não foi possível validar com o Google Play (verifique a service account).',
    );
  }
  if (statusCode === 400 || statusCode === 404) {
    return new HttpsError(
      'failed-precondition',
      'Token de compra inválido ou produto não encontrado.',
    );
  }
  return new HttpsError('internal', `Erro ao validar com o Google Play: ${details}`);
}

function subscriptionStatusValue(expiryMillis, autoRenewing) {
  return {
    status: expiryMillis > Date.now() ? 'active' : 'expired',
    auto_renewing: Boolean(autoRenewing),
    expiry_date: admin.firestore.Timestamp.fromMillis(expiryMillis),
  };
}

// ---------------------------------------------------------------
// completePurchase — valida o recibo na API do Google Play e
// concede o acesso (idempotente por token).
// ---------------------------------------------------------------

exports.completePurchase = onCall({ secrets: [playSecret] }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Faça login para validar a compra.');
  }

  const productId = request.data?.productId;
  const token = request.data?.purchaseToken;
  if (!productId || !token) {
    throw new HttpsError('invalid-argument', 'Dados da compra incompletos.');
  }

  const publisher = await publisherClient();

  if (productId === SUBSCRIPTION_PRODUCT) {
    let purchase;
    try {
      const res = await publisher.purchases.subscriptions.get({
        packageName: PACKAGE_NAME,
        subscriptionId: SUBSCRIPTION_PRODUCT,
        token,
      });
      purchase = res.data;
    } catch (e) {
      throw mapPlayError(e);
    }

    const paymentState = Number(purchase.paymentState ?? 0);
    if (paymentState === 0) {
      throw new HttpsError(
        'failed-precondition',
        'Pagamento ainda pendente na Play Store. Conclua e tente de novo.',
      );
    }

    const expiryMillis = Number(purchase.expiryTimeMillis || 0);
    const startsMillis = Number(purchase.startTimeMillis || Date.now());
    const next = subscriptionStatusValue(expiryMillis, purchase.autoRenewing);

    await subRef(uid).set({
      status: next.status,
      purchase_token: token,
      product_id: SUBSCRIPTION_PRODUCT,
      start_date: admin.firestore.Timestamp.fromMillis(startsMillis),
      expiry_date: next.expiry_date,
      auto_renewing: next.auto_renewing,
      verified_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    try {
      await publisher.purchases.subscriptions.acknowledge({
        packageName: PACKAGE_NAME,
        subscriptionId: SUBSCRIPTION_PRODUCT,
        token,
        requestBody: { developerPayload: uid },
      });
    } catch (_) {}

    return {
      productId: SUBSCRIPTION_PRODUCT,
      status: next.status,
      expiryTimeMillis: expiryMillis,
      autoRenewing: next.auto_renewing,
    };
  }

  if (productId === CONSULTA_PRODUCT) {
    const key = tokenId(CONSULTA_PRODUCT, token);
    const tokenDoc = admin.firestore().collection('purchase_tokens').doc(key);

    const existing = await tokenDoc.get();
    if (existing.exists) {
      const access = (await userRef(uid).get()).data?.() ?? {};
      return {
        productId: CONSULTA_PRODUCT,
        alreadyGranted: true,
        credits: Number(access.consulta_credits ?? 0),
      };
    }

    let purchase;
    try {
      const res = await publisher.purchases.products.get({
        packageName: PACKAGE_NAME,
        productId: CONSULTA_PRODUCT,
        token,
      });
      purchase = res.data;
    } catch (e) {
      throw mapPlayError(e);
    }

    if (Number(purchase.purchaseState ?? 1) !== 0) {
      throw new HttpsError(
        'failed-precondition',
        'Compra cancelada ou não concluída na Play Store.',
      );
    }

    try {
      await publisher.purchases.products.acknowledge({
        packageName: PACKAGE_NAME,
        productId: CONSULTA_PRODUCT,
        token,
        requestBody: { developerPayload: uid },
      });
    } catch (_) {}

    let credits = 1;
    await admin.firestore().runTransaction(async (tx) => {
      const snap = await tx.get(userRef(uid));
      const current = Number(snap.data?.()?.consulta_credits ?? 0);
      credits = current + 1;
      tx.set(userRef(uid), {
        consulta_credits: credits,
        last_product_id: CONSULTA_PRODUCT,
        last_purchase_at: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      tx.set(tokenDoc, {
        uid,
        productId: CONSULTA_PRODUCT,
        purchaseToken: token,
        granted_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    return { productId: CONSULTA_PRODUCT, alreadyGranted: false, credits };
  }

  throw new HttpsError('failed-precondition', `Produto não suportado: ${productId}`);
});

// ---------------------------------------------------------------
// unlockVehicle — desbloqueia 1 veículo gastando crédito (ou
// de graça se houver assinatura ativa). Transação no servidor.
// ---------------------------------------------------------------

exports.unlockVehicle = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Faça login para desbloquear a nave.');
  }

  const vehicleId = request.data?.vehicleId;
  if (!vehicleId || typeof vehicleId !== 'string' || vehicleId.length > 120) {
    throw new HttpsError('invalid-argument', 'Veículo inválido.');
  }

  const subSnap = await subRef(uid).get();
  const sub = subSnap.exists ? subSnap.data() : null;
  const subExpiry = sub?.expiry_date ? sub.expiry_date.toMillis() : 0;
  if (sub && sub.status === 'active' && subExpiry > Date.now()) {
    return { unlocked: true, method: 'subscription' };
  }

  let unlocked = false;
  let method = 'no_credits';

  await admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(userRef(uid));
    const data = snap.data?.();
    const unlockedIds = data?.unlocked_vehicle_ids ?? [];
    if (unlockedIds.includes(vehicleId)) {
      unlocked = true;
      method = 'already';
      return;
    }
    const credits = Number(data?.consulta_credits ?? 0);
    if (credits < 1) return;

    tx.set(userRef(uid), {
      consulta_credits: credits - 1,
      unlocked_vehicle_ids: admin.firestore.FieldValue.arrayUnion(vehicleId),
    }, { merge: true });
    unlocked = true;
    method = 'credit';
  });

  if (!unlocked && method === 'no_credits') {
    throw new HttpsError(
      'failed-precondition',
      'Sem créditos de consulta avulsa. Compre uma consulta ou assine.',
    );
  }

  return { unlocked, method };
});

// ---------------------------------------------------------------
// verifyEntitlements — revalida o token atual com o Google Play
// (com cache) e devolve o estado real. Usado no start e restore.
// ---------------------------------------------------------------

exports.verifyEntitlements = onCall({ secrets: [playSecret] }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Faça login para verificar o acesso.');
  }

  const subSnap = await subRef(uid).get();
  const result = { hasSubscription: false, subscription: null, credits: 0, unlockedVehicleIds: [] };

  const accessSnap = await userRef(uid).get();
  const access = accessSnap.data?.();
  result.credits = Number(access?.consulta_credits ?? 0);
  result.unlockedVehicleIds = access?.unlocked_vehicle_ids ?? [];

  if (!subSnap.exists) return result;

  const sub = subSnap.data();
  const subExpiry = sub.expiry_date ? sub.expiry_date.toMillis() : 0;
  const verifiedAt = sub.verified_at ? sub.verified_at.toMillis() : 0;
  const cacheFresh =
    sub.status === 'active' &&
    Date.now() - verifiedAt < 6 * 60 * 60 * 1000 &&
    subExpiry - Date.now() > 24 * 60 * 60 * 1000;

  let next = sub;
  if (sub.purchase_token && !cacheFresh) {
    try {
      const publisher = await publisherClient();
      const res = await publisher.purchases.subscriptions.get({
        packageName: PACKAGE_NAME,
        subscriptionId: sub.product_id || SUBSCRIPTION_PRODUCT,
        token: sub.purchase_token,
      });
      const updated = subscriptionStatusValue(
        Number(res.data.expiryTimeMillis || 0),
        res.data.autoRenewing,
      );
      next = { ...sub, ...updated, verified_at: admin.firestore.FieldValue.serverTimestamp() };
      await subRef(uid).set({ ...updated, verified_at: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    } catch (_) {}
  }

  result.hasSubscription = next.status === 'active' && (next.expiry_date ? next.expiry_date.toMillis() > Date.now() : false);
  if (result.hasSubscription) {
    result.subscription = {
      status: 'active',
      productId: next.product_id,
      expiryTimeMillis: next.expiry_date ? next.expiry_date.toMillis() : 0,
      autoRenewing: Boolean(next.auto_renewing),
    };
  }
  return result;
});

// ---------------------------------------------------------------
// playDeveloperNotification — RTDN (Webhook) do Google Play:
// renovações/cancelamentos chegam por Pub/Sub e atualizam o
// Firestore sem depender do app abrir. Opcional.
// ---------------------------------------------------------------

function extractJsonPayload(req) {
  const encoded = req.body?.message?.data;
  if (!encoded) return null;
  try {
    return JSON.parse(Buffer.from(encoded, 'base64').toString('utf8'));
  } catch (_) {
    return null;
  }
}

async function verifyPubSubToken(bearer) {
  const idToken = bearer?.replace(/^Bearer\s+/i, '');
  if (!idToken) return null;
  const client = new OAuth2Client();
  const ticket = await client.verifyIdToken({ idToken });
  const payload = ticket.getPayload();
  const emailOk = payload.email === 'cloud-pubsub@system.gserviceaccount.com';
  const audOk = String(payload.aud ?? '').includes('cloudfunctions.net');
  return emailOk && audOk ? payload : null;
}

exports.playDeveloperNotification = onRequest(
  { secrets: [playSecret] },
  async (req, res) => {
    const claim = await verifyPubSubToken(req.headers.authorization).catch(() => null);
    if (!claim) {
      res.status(403).send('unauthorized');
      return;
    }

    const data = extractJsonPayload(req);
    if (!data || !data.subscriptionNotification) {
      res.status(200).send('ok');
      return;
    }

    const { purchaseToken, subscriptionId } = data.subscriptionNotification;
    const matches = await admin
      .firestore()
      .collectionGroup('subscriptions')
      .where('purchase_token', '==', purchaseToken)
      .limit(1)
      .get();

    if (matches.empty) {
      res.status(200).send('ok');
      return;
    }

    try {
      const publisher = await publisherClient();
      const resApi = await publisher.purchases.subscriptions.get({
        packageName: PACKAGE_NAME,
        subscriptionId: subscriptionId || SUBSCRIPTION_PRODUCT,
        token: purchaseToken,
      });
      const updated = subscriptionStatusValue(
        Number(resApi.data.expiryTimeMillis || 0),
        resApi.data.autoRenewing,
      );
      await Promise.all(matches.docs.map((doc) =>
        doc.ref.set({ ...updated, updated_at: admin.firestore.FieldValue.serverTimestamp() }, { merge: true }),
      ));
    } catch (_) {}

    res.status(200).send('ok');
  },
);