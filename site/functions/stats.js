// panee.app/stats: a private page with the download counts that /download keeps in the STATS KV
// namespace. The browser asks for a username and password (HTTP Basic auth). Only the SHA-256 of
// "username:password" is in this file; the password itself is not.
const LOGIN_SHA256 = "15d29902b37407f6b09ef538a49e0eec6d37aa7c0e70654c14259c06359a53f5";

export async function onRequest({ request, env }) {
  const auth = request.headers.get("Authorization") || "";
  let login = "";
  try { if (auth.startsWith("Basic ")) login = atob(auth.slice(6)); } catch {}
  if ((await sha256(login)) !== LOGIN_SHA256) {
    return new Response("Sign in to see the download counts.", {
      status: 401,
      headers: { "WWW-Authenticate": 'Basic realm="Pane stats", charset="UTF-8"', "Cache-Control": "no-store" },
    });
  }
  if (!env.STATS) return new Response("The STATS binding is missing.", { status: 500 });

  const counts = {};
  let cursor;
  do {
    const page = await env.STATS.list({ cursor });
    for (const k of page.keys) {
      counts[k.name] = (k.metadata && k.metadata.n) || 0;
    }
    cursor = page.list_complete ? undefined : page.cursor;
  } while (cursor);

  const group = (prefix) =>
    Object.entries(counts)
      .filter(([k]) => k.startsWith(prefix))
      .map(([k, n]) => [k.slice(prefix.length), n]);
  const byCount = (rows) => rows.sort((a, b) => b[1] - a[1]);

  const today = new Date().toISOString().slice(0, 10);
  const days = group("d:").sort((a, b) => (a[0] < b[0] ? 1 : -1));
  const last7 = days.filter(([d]) => d > new Date(Date.now() - 7 * 864e5).toISOString().slice(0, 10));
  const sum = (rows) => rows.reduce((t, r) => t + r[1], 0);

  const perDay = days.map(([d, n]) => {
    const srcs = byCount(group(`ds:${d}:`)).map(([s, m]) => `${esc(s)} ${m}`).join(" · ");
    return [d, n, srcs];
  });

  const table = (title, rows, third) =>
    `<h2>${title}</h2><table>${rows
      .map((r) => `<tr><td>${esc(r[0])}</td><td class="n">${r[1]}</td>${third ? `<td class="s">${r[2]}</td>` : ""}</tr>`)
      .join("")}${rows.length ? "" : `<tr><td>Nothing yet</td></tr>`}</table>`;

  const html = `<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex">
<title>Pane downloads</title>
<style>
body{font:15px/1.45 -apple-system,BlinkMacSystemFont,"Inter",system-ui,sans-serif;max-width:640px;margin:32px auto;padding:0 18px;color:#1d1d1f;background:#fbfbfd}
h1{font-size:22px;margin:0 0 18px}h2{font-size:15px;margin:28px 0 8px;color:#6e6e73}
.big{display:grid;grid-template-columns:repeat(3,1fr);gap:10px}
.big div{background:#fff;border:1px solid #e5e5ea;border-radius:14px;padding:14px}
.big b{display:block;font-size:28px;font-variant-numeric:tabular-nums}.big span{color:#6e6e73;font-size:13px}
table{width:100%;border-collapse:collapse;background:#fff;border:1px solid #e5e5ea;border-radius:14px;overflow:hidden}
td{padding:9px 14px;border-top:1px solid #f0f0f3}tr:first-child td{border-top:0}
.n{text-align:right;font-variant-numeric:tabular-nums;font-weight:600;width:60px}.s{color:#6e6e73;font-size:13px}
p{color:#6e6e73;font-size:13px}
</style></head><body>
<h1>Pane downloads</h1>
<div class="big"><div><b>${counts["d:" + today] || 0}</b><span>Today (UTC)</span></div>
<div><b>${sum(last7)}</b><span>Last 7 days</span></div><div><b>${counts["t:all"] || 0}</b><span>All time</span></div></div>
${table("Where they came from", byCount(group("s:")))}
${table("Countries", byCount(group("c:")))}
${table("By day", perDay, true)}
<p>Counted from clicks on panee.app/download since the counter was added, without bots. GitHub's own count also includes direct downloads and updates.</p>
</body></html>`;
  return new Response(html, {
    headers: { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-store", "X-Robots-Tag": "noindex" },
  });
}

async function sha256(s) {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

function esc(s) {
  return String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
}
