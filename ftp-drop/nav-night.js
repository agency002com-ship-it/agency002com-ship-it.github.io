/* Shift 002 — overwrite grey 120.cash /assets/nav.js.
   Pay €120 → already-patched cash.keychain.gr. #brief → KV live URL.
   Does not touch other keychain plans. Year stamp stays. */
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

  var form = document.getElementById("brief-form");
  if (!form || form.getAttribute("data-shift002") === "1") return;
  form.setAttribute("data-shift002", "1");
  form.addEventListener(
    "submit",
    function (e) {
      e.preventDefault();
      e.stopImmediatePropagation();
      var email = ((document.getElementById("email") || {}).value || "").trim();
      var biz = ((document.getElementById("biz") || {}).value || "").trim();
      var phone = ((document.getElementById("phone") || {}).value || "").trim();
      var what = ((document.getElementById("what") || {}).value || "").trim();
      var msg = document.getElementById("brief-msg");
      var btn = document.getElementById("brief-send");
      if (msg) {
        msg.hidden = false;
        msg.className = "msg";
        msg.textContent = "Sending…";
      }
      if (btn) btn.disabled = true;
      fetch("https://cash.120.cash/brief-submit.php", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: email,
          biz: biz,
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
          if (msg) {
            msg.className = j.ok ? "msg ok" : "msg err";
            msg.textContent = j.message || j.error || "Got it.";
          }
          if (j.ok) form.reset();
        })
        .catch(function () {
          if (btn) btn.disabled = false;
          if (msg) {
            msg.className = "msg err";
            msg.textContent = "Connection failed. Try again in a moment.";
          }
        });
    },
    true
  );
})();
