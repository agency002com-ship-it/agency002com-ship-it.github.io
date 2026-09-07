/* Shift 002 — overwrite grey catalog /assets/nav.js (eidotevil, agency002, sebarv, 120.cash).
   Pay €120 (plan=cash_120 only) → already-patched cash.keychain.gr.
   Catalog brief form (cash_120 / empty pkg) → orange tonight KV.
   Paid till (#pay-card / #pay-pp) is desk.js: Stripe/PayPal first. Do not steal that form.
   Year stamp stays. Does not touch presence / page_100 / Printful / SitePilot. */
(function () {
  var y = document.getElementById("y");
  if (y) y.textContent = String(new Date().getFullYear());

  document.querySelectorAll('a[href*="keychain.gr/pay.html"]').forEach(function (a) {
    var href = a.getAttribute("href") || "";
    if (href.indexOf("plan=cash_120") === -1) return;
    try {
      var u = new URL(href, location.href);
      u.protocol = "https:";
      u.hostname = "cash.keychain.gr";
      a.setAttribute("href", u.toString());
    } catch (err) {}
  });

  document.querySelectorAll('a[href="https://120.cash/#brief"]').forEach(function (a) {
    a.setAttribute("href", "https://tonight.agency002.com/#book");
  });

  // agency002.com dropped the cash_120 card; the remaining 120.cash ghost link is the €120 door.
  if (location.hostname === "agency002.com" || location.hostname === "www.agency002.com") {
    document.querySelectorAll('a[href="https://120.cash/"]').forEach(function (a) {
      a.setAttribute("href", "https://tonight.agency002.com/");
    });
  }

  var swaps = [
    ["Only after payment. We answer within one working day.", "Pay €120. The page goes live tonight. Not a working day."],
    ["Form stays on eidotevil.com. We answer within one working day.", "Form stays on eidotevil.com. A €120 page goes live the same night you pay."],
    ["Form stays on agency002.com. We answer within one working day.", "Form stays on agency002.com. A €120 page goes live the same night you pay."],
    ["Use this form on sebarv.com. I answer within one working day.", "Use this form on sebarv.com. A €120 page goes live the same night you pay."],
    ["After pay: short brief on 120.cash", "After pay: same-night brief on tonight.agency002.com"],
    ["After pay: brief on 120.cash", "After pay: same-night brief on tonight.agency002.com"],
  ];
  document.querySelectorAll("p, li").forEach(function (el) {
    var t = el.textContent || "";
    var next = t;
    for (var i = 0; i < swaps.length; i++) {
      if (next.indexOf(swaps[i][0]) !== -1) {
        next = next.split(swaps[i][0]).join(swaps[i][1]);
      }
    }
    if (next !== t) el.textContent = next;
  });

  // tonight / 120-index till: Pay by card must open Stripe. This capture handler
  // used to preventDefault + stopImmediatePropagation, skip charge, and publish.
  if (document.getElementById("pay-card") || document.getElementById("pay-pp")) return;

  var form = document.getElementById("brief-form");
  if (!form || form.getAttribute("data-shift002") === "1") return;
  form.setAttribute("data-shift002", "1");

  function val(id) {
    return ((document.getElementById(id) || {}).value || "").trim();
  }

  function isProbe(email, biz) {
    var e = (email || "").toLowerCase();
    var b = (biz || "").toLowerCase();
    if (e.indexOf("probe-activate") !== -1) return true;
    if (e.indexOf(".invalid") !== -1) return true;
    if (e.indexOf("@example.com") !== -1) return true;
    if (b.indexOf("probe do not build") !== -1) return true;
    if (b.indexOf("not a customer") !== -1) return true;
    return false;
  }

  form.addEventListener(
    "submit",
    function (e) {
      var pkg = val("pkg") || "cash_120";
      if (pkg !== "cash_120" && pkg !== "cash120") return;

      e.preventDefault();
      e.stopImmediatePropagation();

      var email = val("email");
      var phone = val("phone");
      var biz = val("biz") || val("name");
      var what = val("what") || val("message");
      var msg = document.getElementById("brief-msg");
      var btn = document.getElementById("brief-send");

      function show(kind, text) {
        if (!msg) return;
        msg.hidden = false;
        msg.className = kind ? "msg " + kind : "msg";
        msg.textContent = text;
      }

      if (isProbe(email, biz)) {
        show("ok", "Got it.");
        form.reset();
        return;
      }

      show("", "Sending…");
      if (btn) btn.disabled = true;

      fetch("https://tonight.agency002.com/brief-submit.php", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: email,
          name: biz,
          biz: biz,
          pkg: "cash_120",
          phone: phone,
          message: what,
          businessName: biz,
          whatYouDo: what,
        }),
      })
        .then(function (r) {
          return r.json().then(function (j) {
            return { ok: r.ok, j: j };
          });
        })
        .then(function (res) {
          if (btn) btn.disabled = false;
          var j = res.j || {};
          if (j.url && /^https:\/\/cash\.120\.cash\/p\//.test(j.url)) {
            location.href = j.url;
            return;
          }
          show(j.ok ? "ok" : "err", j.message || j.error || "Got it.");
          if (j.ok) form.reset();
        })
        .catch(function () {
          if (btn) btn.disabled = false;
          show("err", "Connection failed. Try again in a moment.");
        });
    },
    true
  );
})();
