// smorza.app/download: send the visitor straight to the newest release download, the .dmg if
// the release has one, otherwise the .zip.
// Asks GitHub for the latest release (cached for five minutes at the edge) and falls back to the
// release page if GitHub does not answer or the release has neither yet.
const REPO = "rokoov/pane";

export async function onRequest({ request }) {
  let target = `https://github.com/${REPO}/releases/latest`;
  try {
    const res = await fetch(`https://api.github.com/repos/${REPO}/releases/latest`, {
      headers: { "User-Agent": "smorza.app", Accept: "application/vnd.github+json" },
      cf: { cacheTtl: 300, cacheEverything: true },
    });
    if (res.ok) {
      const release = await res.json();
      const assets = release.assets || [];
      const file = assets.find((a) => /\.dmg$/i.test(a.name)) || assets.find((a) => /\.zip$/i.test(a.name));
      if (file) target = file.browser_download_url;
    }
  } catch {}
  // ?where shows the target instead of redirecting, for checking the setup
  if (new URL(request.url).searchParams.has("where")) {
    return new Response(target + "\n", { headers: { "Content-Type": "text/plain; charset=utf-8", "Cache-Control": "no-store" } });
  }
  return new Response(null, {
    status: 302,
    headers: { Location: target, "Cache-Control": "public, max-age=300" },
  });
}
