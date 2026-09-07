# Laptop Grok — keychain cash_120 return

Do not hand-edit `pay.html`. Do not send cold mail. Do not touch PayPal passwords.
Do not touch other plans (SitePilot, Intifrog, Ms King, MPG, Buy Link, …).

Live 120.cash “Pay €120” already opens `https://keychain.gr/pay.html?plan=cash_120`.
After pay, live keychain still sends the buyer to `https://120.cash/#brief`.
The new 120.cash homepage treats `#brief` as after-pay: no second charge, live
page the same night. Fileman still patches `cash_120` to github.io `paid.html`
when the needles are unique.

One command does **both** the homepage (Fileman, then Cloudflare orange-cloud)
and this return, then leaves HubWatch / hourly / logon to retry:

```
powershell -File install-hub-hook.ps1
```

https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/main/ftp-drop/install-hub-hook.ps1

Fileman itself: https://agency002com-ship-it.github.io/ftp-drop/upload-120cash.ps1
(`:2083`, then **WHM `:2087`**). Loads `GrokWork\ftp\config.cpanel.local.ps1`,
patches `cash_120` on `keychain.gr/pay.html` first (thank-you + `doorBounce`),
then writes 120.cash `index.html`. Same cPanel account, same IP.

After a real card pay, keychain must bounce to:

`https://agency002com-ship-it.github.io/paid.html?session_id=…`

`paid.html` opens the brief form on a `cs_live_` / `cs_test_` session id, or after
PayPal capture. The page goes live the same night. No second charge.

Verify before claiming done:

- https://120.cash/ has `#book` and does **not** say “one working day”
- https://keychain.gr/pay.html contains `github.io/paid.html`
- https://keychain.gr/pay.html does **not** contain `a('https://120.cash/#brief'`
- Intifrog / SitePilot / Ms King strings are still in `pay.html`
- After 120.cash is same-night: origin `sitemap.xml` has lastmod + hourly, and
  `https://120.cash/7c2a9f1e4b8d0c3a5e6f7a8b9c0d1e2f.txt` exists. Do not IndexNow
  120.cash while it still says one working day.
