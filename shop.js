/* Shared night-desk helpers for the public GitHub Pages door. */
(function (root) {
  var KEYCHAIN = "https://keychain.gr/api/owner-checkout.php";
  var HERE = "https://agency002com-ship-it.github.io";
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
      var json = decodeURIComponent(
        escape(atob(s.replace(/-/g, "+").replace(/_/g, "/"))),
      );
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
    return HERE + "/live.html#" + encode(b);
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

  function postJson(url, body, ms) {
    var wait = ms || 15000;
    var ctrl = typeof AbortController === "function" ? new AbortController() : null;
    var timer = ctrl ? setTimeout(function () { ctrl.abort(); }, wait) : null;
    return fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
      signal: ctrl ? ctrl.signal : undefined,
    })
      .then(function (r) {
        return r
          .json()
          .then(function (j) {
            return { ok: r.ok, status: r.status, j: j };
          })
          .catch(function () {
            return { ok: r.ok, status: r.status, j: {} };
          });
      })
      .finally(function () {
        if (timer) clearTimeout(timer);
      });
  }

  async function openCheckout(brief, rail) {
    save(brief);
    var packed = encode(brief);
    var cancel = HERE + "/?checkout=cancelled";
    var desc = "120.cash night page — " + brief.businessName;
    if (rail === "paypal") {
      var pp = await postJson(KEYCHAIN, {
        action: "create",
        amount: 120,
        currency: "EUR",
        description: desc,
        return_url: HERE + "/thanks.html?rail=paypal&p=" + packed,
        cancel_url: cancel,
      });
      var approve = (pp.j && (pp.j.approve_url || pp.j.url)) || "";
      if (String(approve).indexOf("https://www.paypal.com/") === 0) {
        try {
          sessionStorage.setItem("shift002-paypal", pp.j.order_id || "");
        } catch (e) {}
        return approve;
      }
      throw new Error((pp.j && pp.j.error) || "PayPal did not open.");
    }
    var card = await postJson(KEYCHAIN, {
      action: "stripe_checkout",
      plan: "cash_120",
      description: desc,
      success_url: HERE + "/thanks.html?session_id={CHECKOUT_SESSION_ID}&p=" + packed,
      cancel_url: cancel,
    });
    var url = card.j && card.j.url ? String(card.j.url) : "";
    if (url.indexOf("https://checkout.stripe.com/") === 0) return url;
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

  async function stripePaid(sessionId) {
    if (!sessionId || sessionId.length < 20) return { paid: false, checked: false };
    if (!/^cs_(live|test)_/.test(sessionId)) return { paid: false, checked: true };
    try {
      var res = await postJson(KEYCHAIN, {
        action: "stripe_session",
        session_id: sessionId,
      });
      if (res.j && res.j.paid === true) return { paid: true, checked: true };
      if (res.j && res.j.paid === false) return { paid: false, checked: true };
      return { paid: false, checked: false };
    } catch (e) {
      return { paid: false, checked: false };
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
    stripePaid: stripePaid,
    digits: digits,
  };
})(window);
