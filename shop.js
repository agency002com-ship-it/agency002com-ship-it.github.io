/* Shared night-desk helpers for the public GitHub Pages door. */
(function (root) {
  var KEYCHAIN = "https://keychain.gr/api/owner-checkout.php";
  var DESK = "https://120.cash/desk-checkout.php";
  var STORE = "shift002-brief";

  function trim(s, n) {
    return String(s || "").trim().slice(0, n);
  }

  function briefFromForm(ids) {
    return {
      businessName: trim(document.getElementById(ids.biz).value, 80),
      phone: trim(document.getElementById(ids.phone).value, 40),
      email: trim(document.getElementById(ids.email).value, 120).toLowerCase(),
      city: trim(document.getElementById(ids.city).value, 80) || "Greece",
      whatYouDo: trim(document.getElementById(ids.what).value, 450),
    };
  }

  function valid(b) {
    if (!b.businessName || !b.phone || !b.whatYouDo) return false;
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(b.email || "")) return false;
    return true;
  }

  function save(b) {
    try {
      sessionStorage.setItem(STORE, JSON.stringify(b));
    } catch (e) {}
  }

  function load() {
    try {
      var raw = sessionStorage.getItem(STORE);
      if (!raw) return null;
      var b = JSON.parse(raw);
      return valid(b) ? b : null;
    } catch (e) {
      return null;
    }
  }

  function encode(b) {
    var json = JSON.stringify({
      v: 1,
      n: b.businessName,
      w: b.whatYouDo,
      p: b.phone,
      e: b.email,
      c: b.city || "Greece",
    });
    return btoa(unescape(encodeURIComponent(json)))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/g, "");
  }

  function decode(hash) {
    var s = String(hash || "").replace(/^#/, "");
    if (!s) return null;
    try {
      var pad = s.length % 4;
      if (pad) s += "====".slice(pad);
      var json = decodeURIComponent(escape(atob(s.replace(/-/g, "+").replace(/_/g, "/"))));
      var o = JSON.parse(json);
      var b = {
        businessName: trim(o.n, 80),
        whatYouDo: trim(o.w, 450),
        phone: trim(o.p, 40),
        email: trim(o.e, 120),
        city: trim(o.c, 80) || "Greece",
      };
      return valid(b) ? b : null;
    } catch (e) {
      return null;
    }
  }

  function digits(phone) {
    return String(phone || "").replace(/[^\d+]/g, "");
  }

  function liveUrl(b) {
    var origin = location.origin + location.pathname.replace(/[^/]+$/, "");
    return origin + "live.html#" + encode(b);
  }

  function esc(s) {
    return String(s)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function renderShop(el, b) {
    var tel = digits(b.phone);
    var wa = tel.replace(/^\+/, "");
    el.innerHTML =
      "<main>" +
      '<p class="city">' +
      esc(b.city) +
      "</p><div><h1>" +
      esc(b.businessName) +
      '</h1><p class="offer">' +
      esc(b.whatYouDo) +
      '</p></div><div class="actions"><a class="call" href="tel:' +
      esc(tel) +
      '">Call ' +
      esc(b.phone) +
      '</a><a class="wa" href="https://wa.me/' +
      esc(wa) +
      '">WhatsApp</a><p class="note">Built in the Athens night. Ready when you woke up.</p></div></main>';
  }

  function origin() {
    return "https://agency002com-ship-it.github.io";
  }

  async function postJson(url, body) {
    var r = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    var j = {};
    try {
      j = await r.json();
    } catch (e) {}
    return { ok: r.ok, status: r.status, j: j };
  }

  async function openCheckout(brief, rail) {
    save(brief);
    try {
      var desk = await postJson(DESK, Object.assign({ rail: rail }, brief));
      if (desk.j && desk.j.url) return desk.j.url;
    } catch (e) {}

    var here = origin();
    if (rail === "paypal") {
      var pp = await postJson(KEYCHAIN, {
        action: "create",
        amount: 120,
        currency: "EUR",
        description: "120.cash night page — " + brief.businessName,
        return_url: here + "/thanks.html?rail=paypal",
        cancel_url: here + "/?checkout=cancelled",
      });
      if (pp.j && pp.j.approve_url) {
        try {
          sessionStorage.setItem("shift002-paypal", pp.j.order_id || "");
        } catch (e) {}
        return pp.j.approve_url;
      }
      throw new Error((pp.j && pp.j.error) || "PayPal did not open.");
    }

    var card = await postJson(KEYCHAIN, {
      action: "stripe_checkout",
      plan: "cash_120",
      description: "120.cash night page — " + brief.businessName,
      success_url: here + "/thanks.html?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: here + "/?checkout=cancelled",
    });
    if (card.j && card.j.url && String(card.j.url).indexOf("https://checkout.stripe.com/") === 0) {
      return card.j.url;
    }
    throw new Error((card.j && card.j.error) || "Card till did not open.");
  }

  async function paypalCaptured(orderId) {
    if (!orderId || orderId.length < 8) return false;
    try {
      var res = await postJson(KEYCHAIN, { action: "capture", order_id: orderId });
      return !!(res.j && res.j.ok === true);
    } catch (e) {
      return false;
    }
  }

  root.NightDesk = {
    briefFromForm: briefFromForm,
    valid: valid,
    save: save,
    load: load,
    encode: encode,
    decode: decode,
    liveUrl: liveUrl,
    renderShop: renderShop,
    openCheckout: openCheckout,
    paypalCaptured: paypalCaptured,
    digits: digits,
  };
})(window);
