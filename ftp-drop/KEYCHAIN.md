# Laptop Grok — keychain cash_120 return

Do not hand-edit `pay.html`. Do not send cold mail. Do not touch PayPal passwords.
Do not touch other plans (SitePilot, Intifrog, Ms King, MPG, Buy Link, …).

Live 120.cash “Pay €120” already opens `https://keychain.gr/pay.html?plan=cash_120`.
Grey apex after-pay still sends the buyer to `https://120.cash/#brief` (working day)
unless Fileman has patched it.

Already-orange pay desk (no Fileman needed for this host): `https://cash.keychain.gr/pay.html?plan=cash_120`.
grok-cf serves patched keychain pay there (`x-shift002: keychain-orange`); cash_120 return is github.io/paid.html.
Still Fileman the grey apex — that is what indexed catalogs link to.

One command does **both** the homepage and the grey-apex return, then leaves HubWatch
to retry every 3 hours:

```
powershell -File install-hub-hook.ps1
```

https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/main/ftp-drop/install-hub-hook.ps1

Fileman itself: https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/main/ftp-drop/upload-120cash.ps1
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
- https://cash.keychain.gr/pay.html?plan=cash_120 is 200 with `x-shift002: keychain-orange`
