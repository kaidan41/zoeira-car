// Diagnóstico revisitado — compara canal vs. vídeo-controle com 3 métodos:
// oEmbed, innertube (client WEB) e página watch (ytInitialPlayerResponse).
// Uso: node scripts/check_embeds.js
const CHANNEL_RSS = 'https://www.youtube.com/feeds/videos.xml?channel_id=UCJHq9RfDWdnnI_eJV-_C13g';
const CONTROL = 'dQw4w9WgXcQ';

function feedIds(xml) {
  const parts = xml.split(/<entry>|<\/entry>/);
  const list = [];
  for (let i = 1; i < parts.length; i += 2) {
    if (!parts[i]) continue;
    const id = (parts[i].match(/<yt:videoId>(.*?)<\/yt:videoId>/) || [])[1];
    const title = (parts[i].match(/<title>(.*?)<\/title>/) || [])[1];
    if (id) list.push({ id, title });
  }
  return list;
}

async function oembed(id) {
  const u = `https://www.youtube.com/oembed?url=${encodeURIComponent('https://www.youtube.com/watch?v=' + id)}&format=json`;
  const res = await fetch(u);
  const t = await res.text();
  let json = null;
  try { json = JSON.parse(t); } catch (_) {}
  return { status: res.status, ok: json != null, title: json?.title, body: t.slice(0, 80) };
}

async function innertube(id) {
  const body = {
    context: { client: { clientName: 'WEB', clientVersion: '2.20240101.00.00', hl: 'pt-BR', gl: 'BR' } },
    videoId: id,
  };
  const res = await fetch('https://www.youtube.com/youtubei/v1/player?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const json = await res.json();
  const ps = json.playabilityStatus || {};
  const playErr = (ps.playabilityError || {}).reasons;
  const issues = [];
  if (Array.isArray(playErr)) issues.push(playErr.join('; '));
  return {
    status: ps.status,
    reason: ps.reason,
    issues,
    allowEmbed: json.videoDetails?.allowEmbed,
    familySafe: json.microformat?.playerMicroformatRenderer?.isFamilySafe,
  };
}

async function watchPage(id) {
  const res = await fetch(`https://www.youtube.com/watch?v=${id}&hl=pt-BR`, {
    headers: { 'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8' },
  });
  const t = await res.text();
  const m = t.match(/ytInitialPlayerResponse\s*=\s*(\{.+?\})\s*;\s*(?:<\/script>|var)/s);
  let info = '(ytInitialPlayerResponse nao encontrado)';
  if (m) {
    try {
      const j = JSON.parse(m[1]);
      const ps = j.playabilityStatus || {};
      info = `status=${ps.status} reason=${ps.reason} allowEmbed=${j.videoDetails?.allowEmbed} familySafe=${j.microformat?.playerMicroformatRenderer?.isFamilySafe}`;
    } catch (_) { info = '(falha ao parsear ytInitialPlayerResponse)'; }
  }
  return { http: res.status, len: t.length, info };
}

async function main() {
  console.log('--- FEED AGORA ---');
  const r = await fetch(CHANNEL_RSS);
  const xml = await r.text();
  const videos = feedIds(xml);
  console.log(`videos no feed agora: ${videos.length} (antes eram 15)`);
  videos.slice(0, 6).forEach((v, i) => console.log(`  ${i + 1}. ${v.id} — ${v.title}`));

  const tests = [
    ['CONTROLE (Rick Astley)', CONTROL],
    ...videos.slice(0, 5).map((v) => [v.title, v.id]),
  ];

  for (const [nome, id] of tests) {
    console.log('\n========================================');
    console.log(nome, '| id:', id);
    try {
      const oe = await oembed(id);
      console.log('oEmbed        :', oe.status, oe.ok ? `OK -> ${oe.title}` : 'FALHOU', oe.status === 200 ? '' : '(' + oe.body.replace(/\n/g, ' ') + ')');
    } catch (e) { console.log('oEmbed        : ERRO', e.message); }
    try {
      const it = await innertube(id);
      console.log('innertube WEB :', JSON.stringify(it));
    } catch (e) { console.log('innertube     : ERRO', e.message); }
    try {
      const wp = await watchPage(id);
      console.log('watch page    : http=' + wp.http, 'len=' + wp.len, '|', wp.info);
    } catch (e) { console.log('watch page    : ERRO', e.message); }
    await new Promise((r) => setTimeout(r, 800));
  }
}

main().catch((e) => { console.error(e); process.exit(1); });