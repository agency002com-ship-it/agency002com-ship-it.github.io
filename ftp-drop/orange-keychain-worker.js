// Intercept GET /pay.html only. Other keychain plans stay on origin IP.
// Does not replace Workers grok / grok-cf.
const ORIGIN_IP = "192.250.229.162";
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
const OLD_SESSION =
  "      if (dKeep) base += '&desc=' + encodeURIComponent(dKeep);\n" +
  "      return base;";
const NEW_SESSION =
  "      if (dKeep) base += '&desc=' + encodeURIComponent(dKeep);\n" +
  "      if (base.indexOf('{CHECKOUT_SESSION_ID}') === -1) base += '&session_id={CHECKOUT_SESSION_ID}';\n" +
  "      return base;";

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
  let out = html;
  if (once(out, OLD_LINK) && once(out, OLD_BOUNCE) && once(out, OLD_DONE)) {
    out = out.replace(OLD_LINK, NEW_LINK).replace(OLD_BOUNCE, NEW_BOUNCE).replace(OLD_DONE, NEW_DONE);
  }
  if (once(out, OLD_SESSION)) {
    out = out.replace(OLD_SESSION, NEW_SESSION);
  }
  if (out === html) return html;
  if (
    out.indexOf("intifrog.com") === -1 ||
    out.indexOf("msking.shop") === -1 ||
    out.indexOf("muslimpowergroup.com") === -1
  ) {
    return html;
  }
  return out;
}

function originFetch(request) {
  const url = new URL(request.url);
  url.hostname = "keychain.gr";
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

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const pay =
      request.method === "GET" &&
      (url.pathname === "/pay.html" || url.pathname === "/pay");
    if (!pay) return originFetch(request);

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
  },
};
