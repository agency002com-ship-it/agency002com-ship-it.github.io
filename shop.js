/* Shared night-desk helpers for the public GitHub Pages door. */
(function (root) {
  var KEYCHAIN = "https://cash.120.cash/api/owner-checkout.php";
  var HERE = "https://agency002com-ship-it.github.io";
  var STORE = "shift002-brief";

  function trim(s, n) {
    return String(s || "").trim().slice(0, n);
  }

  function briefFromForm(ids) {
    var langEl = document.getElementById(ids.lang || "lang");
    var lang = langEl ? trim(langEl.value, 8) : "";
    if (lang !== "el") lang = document.documentElement.lang === "el" ? "el" : "en";
    return {
      businessName: trim(document.getElementById(ids.biz).value, 80),
      phone: trim(document.getElementById(ids.phone).value, 40),
      email: trim(document.getElementById(ids.email).value, 120).toLowerCase(),
      city: trim(document.getElementById(ids.city).value, 80) || (lang === "el" ? "\u0395\u03bb\u03bb\u03ac\u03b4\u03b1" : "Greece"),
      whatYouDo: trim(document.getElementById(ids.what).value, 450),
      language: lang,
    };
  }

  function usablePhone(phone) {
    return digits(phone).replace(/\D/g, "").length >= 8;
  }

  function valid(b) {
    if (!b.businessName || !b.whatYouDo) return false;
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
      l: b.language === "el" ? "el" : "en",
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
        language: o.l === "el" ? "el" : "en",
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
      .replace(/\u003c/g, "&lt;")
      .replace(/\u003e/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function renderShop(el, b) {
    var tel = digits(b.phone);
    var wa = tel.replace(/^\+/, "");
    var greek = b.language === "el";
    var call = greek ? "\u039a\u03bb\u03ae\u03c3\u03b7 " : "Call ";
    var mail = greek ? "Email " : "Email ";
    var note = greek
      ? "\u03a6\u03c4\u03b9\u03ac\u03c7\u03c4\u03b7\u03ba\u03b5 \u03c4\u03b7 \u03bd\u03cd\u03c7\u03c4\u03b1 \u03c3\u03c4\u03b7\u03bd \u0391\u03b8\u03ae\u03bd\u03b1. \u0388\u03c4\u03bf\u03b9\u03bc\u03bf \u03c4\u03bf \u03c0\u03c1\u03c9\u03af."
      : "Built in the Athens night. Ready when you woke up.";
    var hasPhone = usablePhone(b.phone);
    var actions = "";
    if (hasPhone) {
      actions +=
        '\u003ca class="call" href="tel:' +
        esc(tel) +
        '"\u003e' +
        call +
        esc(b.phone) +
        '\u003c/a\u003e\u003ca class="wa" href="https://wa.me/' +
        esc(wa) +
        '"\u003eWhatsApp\u003c/a\u003e';
    }
    if (b.email) {
      actions +=
        '\u003ca class="' +
        (hasPhone ? "wa" : "call") +
        '" href="mailto:' +
        esc(b.email) +
        '"\u003e' +
        mail +
        esc(b.email) +
        "\u003c/a\u003e";
    }
    el.innerHTML =
      "\u003cmain\u003e" +
      '\u003cp class="city"\u003e' +
      esc(b.city) +
      "\u003c/p\u003e\u003cdiv\u003e\u003ch1\u003e" +
      esc(b.businessName) +
      '\u003c/h1\u003e\u003cp class="offer"\u003e' +
      esc(b.whatYouDo) +
      '\u003c/p\u003e\u003c/div\u003e\u003cdiv class="actions"\u003e' +
      actions +
      '\u003cp class="note"\u003e' +
      note +
      "\u003c/p\u003e\u003c/div\u003e\u003c/main\u003e";
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
    var payDoor = "https://pay.120.cash/pay.html?plan=cash_120&p=" + packed;
    var cancel = HERE + "/?checkout=cancelled";
    var desc = "120.cash night page \u2014 " + brief.businessName;
    try {
      if (rail === "paypal") {
        var returns = [
          HERE + "/thanks.html?rail=paypal&p=" + packed,
          HERE + "/thanks.html?rail=paypal",
        ];
        for (var i = 0; i \u003c returns.length; i++) {
          var pp = await postJson(KEYCHAIN, {
            action: "create",
            amount: 120,
            currency: "EUR",
            description: desc,
            return_url: returns[i],
            cancel_url: cancel,
          }, 25000);
          var approve = (pp.j && (pp.j.approve_url || pp.j.url)) || "";
          if (/^https:\/\/(www\.)?(sandbox\.)?paypal\.com\//.test(String(approve))) {
            try {
              sessionStorage.setItem("shift002-paypal", pp.j.order_id || "");
            } catch (e) {}
            return approve;
          }
        }
        return payDoor;
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
    } catch (e) {}
    return payDoor;
  }

  async function paypalCaptured(orderId) {
    if (!orderId || orderId.length \u003c 8) return false;
    try {
      var res = await postJson(KEYCHAIN, { action: "capture", order_id: orderId });
      return !!(res.j && res.j.ok === true);
    } catch (e) {
      return false;
    }
  }

  async function stripePaid(sessionId) {
    if (!sessionId || sessionId.length \u003c 20) return { paid: false, checked: false };
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

  function notifyDesk(brief, paymentId) {
    if (!valid(brief)) return;
    if (/@(example\.com|example\.gr|agency002\.invalid)$/i.test(brief.email || "")) return;
    if (/\b(probe|not a customer|do not build)\b/i.test(brief.businessName + " " + brief.whatYouDo)) return;
    var pay = trim(paymentId, 80);
    var message = trim(brief.whatYouDo, 3500);
    if (brief.city) message += "\nCity: " + trim(brief.city, 80);
    if (pay) message += "\nPayment id: " + pay;
    var body = JSON.stringify({
      email: brief.email,
      biz: brief.businessName,
      phone: brief.phone,
      message: message,
      city: brief.city,
      language: brief.language,
      pkg: "cash_120",
      session_id: pay,
      paymentId: pay,
    });
    try {
      fetch("https://tonight.agency002.com/brief-submit.php", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: body,
      }).catch(function () {});
    } catch (e) {}
  }

  function publishPage(brief, paymentId) {
    notifyDesk(brief, paymentId);
    if (!valid(brief)) {
      return Promise.resolve(liveUrl(brief));
    }
    return fetch("https://cash.120.cash/api/publish", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        businessName: brief.businessName,
        whatYouDo: brief.whatYouDo,
        phone: brief.phone,
        email: brief.email,
        city: brief.city,
        language: brief.language,
        pkg: "cash_120",
        session_id: trim(paymentId, 80),
        paymentId: trim(paymentId, 80),
      }),
    })
      .then(function (r) {
        return r.json().catch(function () {
          return {};
        });
      })
      .then(function (j) {
        if (j && /^https:\/\/cash\.120\.cash\/p\/[a-z0-9-]+$/.test(String(j.url || ""))) {
          return j.url;
        }
        return liveUrl(brief);
      })
      .catch(function () {
        return liveUrl(brief);
      });
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
    notifyDesk: notifyDesk,
    publishPage: publishPage,
    digits: digits,
    usablePhone: usablePhone,
  };

  document.addEventListener("click", function (e) {
    var a = e.target && e.target.closest ? e.target.closest("a") : null;
    if (!a || !a.href) return;
    if (a.href.indexOf("p=") !== -1) return;
    var cash120Pay = a.href.indexOf("pay.120.cash/pay.html") !== -1 ||
      (a.href.indexOf("pay.html") !== -1 && a.href.indexOf("plan=cash_120") !== -1);
    if (!cash120Pay) return;
    if (!document.getElementById("biz")) return;
    var brief;
    try {
      brief = briefFromForm({
        biz: "biz",
        phone: "phone",
        email: "email",
        city: "city",
        what: "what",
        lang: "lang",
      });
    } catch (err) {
      return;
    }
    if (!valid(brief)) return;
    e.preventDefault();
    save(brief);
    location.href = "https://pay.120.cash/pay.html?plan=cash_120&p=" + encode(brief);
  });
})(window);
