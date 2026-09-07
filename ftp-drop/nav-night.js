/* Shift 002 — overwrite grey catalog /assets/nav.js (eidotevil, agency002, sebarv, 120.cash).
   Pay €120 (plan=cash_120 only) → already-patched cash.keychain.gr (Stripe, then github.io/paid.html).
   Do not publish unpaid briefs to KV. After-pay #brief-form stays on origin mail.
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
    ["We answer within one working day.", "A €120 page goes live the same night you pay."],
  ];
  document.querySelectorAll("p, li, h1, h2, .hint, .lead").forEach(function (el) {
    var t = el.textContent || "";
    var next = t;
    for (var i = 0; i < swaps.length; i++) {
      if (next.indexOf(swaps[i][0]) !== -1) {
        next = next.split(swaps[i][0]).join(swaps[i][1]);
      }
    }
    if (next !== t) el.textContent = next;
  });

  // tonight / 120-index till: Pay by card must open Stripe (desk.js).
  if (document.getElementById("pay-card") || document.getElementById("pay-pp")) return;

  // Wait-a-day 120.cash / catalogs: do not preventDefault the after-pay form.
  // Origin mail + 15-min fulfill covers people who already paid. Charging here
  // would double-charge. Free KV publish would skip the €120.
})();
