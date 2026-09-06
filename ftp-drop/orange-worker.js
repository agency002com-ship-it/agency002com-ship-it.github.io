// Orange-cloud 120.cash / tonight / now. Serves same-night HTML from github.io.
// Other paths go to origin IP so assets do not loop through this Worker.
// Does not replace Workers grok / grok-cf. orange-120cash.sh uploads this as shift002-120cash.
const ORIGIN_IP = "192.250.229.162";
const INDEX = "https://agency002com-ship-it.github.io/ftp-drop/120-index.html";
const INDEXNOW = "/7c2a9f1e4b8d0c3a5e6f7a8b9c0d1e2f.txt";
const INDEXNOW_KEY = "7c2a9f1e4b8d0c3a5e6f7a8b9c0d1e2f";

function isHome(url) {
  return url.pathname === "/" || url.pathname === "/index.html";
}

function isNightHost(host) {
  return (
    host === "120.cash" ||
    host === "www.120.cash" ||
    host === "tonight.120.cash" ||
    host === "now.120.cash" ||
    host.endsWith(".workers.dev")
  );
}

function originHostFor(host) {
  if (host === "keychain.gr" || host === "www.keychain.gr") return "keychain.gr";
  return "120.cash";
}

function originFetch(request) {
  const url = new URL(request.url);
  url.hostname = originHostFor(url.hostname);
  const init = {
    method: request.method,
    headers: request.headers,
    redirect: "manual",
    cf: { resolveOverride: ORIGIN_IP },
  };
  if (request.method !== "GET" && request.method !== "HEAD") {
    init.body = request.body;
  }
  return fetch(url.toString(), init);
}

function indexNowResponse(method) {
  const headers = { "content-type": "text/plain; charset=utf-8", "cache-control": "public, max-age=3600" };
  if (method === "HEAD") return new Response(null, { status: 200, headers });
  return new Response(INDEXNOW_KEY + "\n", { status: 200, headers });
}

function robotsFor(origin) {
  const body =
    "User-agent: *\nAllow: /\nSitemap: " + origin + "/sitemap.xml\n";
  return body;
}

function sitemapFor(origin) {
  return `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">
  <url>
    <loc>${origin}/</loc>
    <changefreq>daily</changefreq>
    <xhtml:link rel="alternate" hreflang="en" href="${origin}/" />
    <xhtml:link rel="alternate" hreflang="el" href="${origin}/?el=1" />
  </url>
</urlset>
`;
}

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const host = url.hostname;
    const method = request.method;

    if ((method === "GET" || method === "HEAD") && url.pathname === INDEXNOW && isNightHost(host)) {
      return indexNowResponse(method);
    }

    if ((method === "GET" || method === "HEAD") && url.pathname === "/robots.txt" && isNightHost(host)) {
      const body = robotsFor(url.origin);
      const headers = { "content-type": "text/plain; charset=utf-8", "cache-control": "public, max-age=300" };
      if (method === "HEAD") return new Response(null, { status: 200, headers });
      return new Response(body, { status: 200, headers });
    }

    if ((method === "GET" || method === "HEAD") && url.pathname === "/sitemap.xml" && isNightHost(host)) {
      const body = sitemapFor("https://tonight.120.cash");
      const headers = { "content-type": "application/xml; charset=utf-8", "cache-control": "public, max-age=300" };
      if (method === "HEAD") return new Response(null, { status: 200, headers });
      return new Response(body, { status: 200, headers });
    }

    if (method === "GET" && isHome(url) && isNightHost(host)) {
      const src = await fetch(INDEX, { cf: { cacheTtl: 30 } });
      const html = await src.text();
      return new Response(html, {
        status: 200,
        headers: {
          "content-type": "text/html; charset=utf-8",
          "cache-control": "no-store",
          "x-shift002": "orange",
        },
      });
    }

    if (method === "HEAD" && isHome(url) && isNightHost(host)) {
      return new Response(null, {
        status: 200,
        headers: {
          "content-type": "text/html; charset=utf-8",
          "cache-control": "no-store",
          "x-shift002": "orange",
        },
      });
    }

    const pay =
      method === "GET" &&
      (host === "keychain.gr" || host === "www.keychain.gr") &&
      (url.pathname === "/pay.html" || url.pathname === "/pay");
    if (pay) {
      const origin = await originFetch(request);
      const html = await origin.text();
      const patched = patchCash120(html);
      if (patched === html) {
        const headers = new Headers(origin.headers);
        return new Response(html, { status: origin.status, headers });
      }
      const headers = new Headers(origin.headers);
      headers.set("content-type", "text/html; charset=utf-8");
      headers.set("cache-control", "no-store");
      headers.set("x-shift002", "keychain-orange");
      return new Response(patched, { status: origin.status, headers });
    }

    return originFetch(request);
  },
};

const PAID = "https://agency002com-ship-it.github.io/paid.html";
const OLD_LINK = "a('https://120.cash/#brief', '120.cash');";
const NEW_LINK =
  "var sid = (new URLSearchParams(location.search)).get('session_id') || '';\n" +
  "        var tok = (new URLSearchParams(location.search)).get('token') || (new URLSearchParams(location.search)).get('order_id') || '';\n" +
  "        var paid = '" +
  PAID +
  "';\n" +
  "        if (sid) paid += '?session_id=' + encodeURIComponent(sid);\n" +
  "        else if (tok) paid += '?token=' + encodeURIComponent(tok);\n" +
  "        a(paid, 'the night desk');";
const OLD_BOUNCE =
  "        return false;\n" +
  "      }\n" +
  "      return false;\n" +
  "    }\n" +
  "\n" +
  "    /* ---------------- return from PayPal / Stripe ---------------- */";
const NEW_BOUNCE =
  "        return false;\n" +
  "      }\n" +
  "      if (kind === 'cash_120') {\n" +
  "        var paid = '" +
  PAID +
  "';\n" +
  "        if (sid && /^cs_(live|test)_/.test(sid)) {\n" +
  "          location.href = paid + '?session_id=' + encodeURIComponent(sid);\n" +
  "          return true;\n" +
  "        }\n" +
  "        if (token) {\n" +
  "          location.href = paid + '?token=' + encodeURIComponent(token);\n" +
  "          return true;\n" +
  "        }\n" +
  "        return false;\n" +
  "      }\n" +
  "      return false;\n" +
  "    }\n" +
  "\n" +
  "    /* ---------------- return from PayPal / Stripe ---------------- */";
const OLD_DONE =
  "      showProductNextStep(); // product-aware next step as soon as thank-you shows\n" +
  "      var oid = q.get('token') || q.get('order_id') || sessionStorage.getItem('a2_pp_order') || '';";
const NEW_DONE =
  "      showProductNextStep(); // product-aware next step as soon as thank-you shows\n" +
  "      if (productKind() === 'cash_120') {\n" +
  "        var sidNow = q.get('session_id') || q.get('checkout_session_id') || '';\n" +
  "        var tokNow = q.get('token') || q.get('order_id') || sessionStorage.getItem('a2_pp_order') || '';\n" +
  "        if (doorBounce(sidNow, tokNow)) return;\n" +
  "      }\n" +
  "      var oid = q.get('token') || q.get('order_id') || sessionStorage.getItem('a2_pp_order') || '';";

function once(hay, needle) {
  let n = 0;
  let i = 0;
  while ((i = hay.indexOf(needle, i)) !== -1) {
    n++;
    i += needle.length;
  }
  return n === 1;
}

function patchCash120(html) {
  if (!once(html, OLD_LINK) || !once(html, OLD_BOUNCE) || !once(html, OLD_DONE)) {
    return html;
  }
  const out = html.replace(OLD_LINK, NEW_LINK).replace(OLD_BOUNCE, NEW_BOUNCE).replace(OLD_DONE, NEW_DONE);
  if (
    out.indexOf("intifrog.com") === -1 ||
    out.indexOf("msking.shop") === -1 ||
    out.indexOf("muslimpowergroup.com") === -1
  ) {
    return html;
  }
  return out;
}
