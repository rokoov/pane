// panee.app/download: send the visitor straight to the newest release download, the .dmg if
// the release has one, otherwise the .zip.
// Asks GitHub for the latest release (cached for five minutes at the edge) and falls back to the
// release page if GitHub does not answer or the release has neither yet.
//
// It also counts the download in the STATS KV namespace: the day, the source the page reports in
// ?from= (x, reddit, a news site, the app itself, ...) and the visitor's country. No IP address or other personal
// data is stored. panee.app/stats shows the counts.
const REPO = "rokoov/pane";
const BOTS = /bot|crawl|spider|slurp|preview|curl|wget|python|httpclient|headless|facebookexternalhit|slack|discord|whatsapp|telegram|lighthouse/i;

export async function onRequest({ request, env, waitUntil }) {
  let target = `https://github.com/${REPO}/releases/latest`;
  try {
    const res = await fetch(`https://api.github.com/repos/${REPO}/releases/latest`, {
      headers: { "User-Agent": "panee.app", Accept: "application/vnd.github+json" },
      cf: { cacheTtl: 300, cacheEverything: true },
    });
    if (res.ok) {
      const release = await res.json();
      const assets = release.assets || [];
      const file = assets.find((a) => /\.dmg$/i.test(a.name)) || assets.find((a) => /\.zip$/i.test(a.name));
      if (file) target = file.browser_download_url;
    }
  } catch {}

  if (env.STATS && request.method === "GET" && !BOTS.test(request.headers.get("User-Agent") || "")) {
    waitUntil(count(env.STATS, request).catch(() => {}));
  }

  return new Response(null, {
    status: 302,
    // no-store, so every click reaches this function and is counted
    headers: { Location: target, "Cache-Control": "no-store" },
  });
}

async function count(kv, request) {
  const url = new URL(request.url);
  const from = clean(url.searchParams.get("from")) || "direct";
  const country = clean(request.cf && request.cf.country) || "unknown";
  const day = new Date().toISOString().slice(0, 10);
  await Promise.all(
    ["t:all", `d:${day}`, `s:${from}`, `c:${country}`, `ds:${day}:${from}`].map((k) => bump(kv, k)),
  );
}

async function bump(kv, key) {
  const { value } = await kv.getWithMetadata(key);
  const n = (parseInt(value, 10) || 0) + 1;
  await kv.put(key, String(n), { metadata: { n } });
}

function clean(s) {
  return (s || "").toLowerCase().replace(/[^a-z0-9.-]/g, "").slice(0, 40);
}
