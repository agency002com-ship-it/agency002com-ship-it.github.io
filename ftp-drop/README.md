# Laptop Grok — 120.cash + keychain cash_120

Do not send cold mail. Do not touch PayPal passwords. Do not restore FormSubmit.

Live 120.cash still says one working day and posts unpaid briefs.
The overnight door already works at https://agency002com-ship-it.github.io
This drop is the same product on the indexed domain, same till.

Addon-domain **FTP returns 553**. Do not fight lftp. Use cPanel Fileman
(same path as `GrokWork\ftp\`). If Fileman cannot write the homepage, orange-cloud
it: `orange-120cash.ps1` uses `config.cloudflare.local.ps1` and does **not**
replace the hello-world `grok` / `grok-cf` workers. Same script orange-clouds
`keychain.gr/pay.html` (also on Cloudflare NS) so `cash_120` returns to paid.html
without waiting on origin Fileman.

One run wires HubWatch, hourly + logon tasks, Fileman, then Cloudflare:

```
powershell -File install-hub-hook.ps1
```

https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/main/ftp-drop/install-hub-hook.ps1

That:

1. Patches `C:\Users\Pasja\Hub\watch.ps1` (every 3 hours). Silent when flipped.
2. Registers hourly `Shift002NightDoor` and logon `Shift002NightDoorLogon`.
3. Drops `Desktop\PUT-NIGHT-DOOR.bat`, `Desktop\RUN-SHIFT002.ps1`, and a Startup copy. Copies scripts next to
   the cPanel token. Writes `GrokModes\DO-TONIGHT.txt`.
4. Orange-clouds DNS first so existing grok-cf routes on `120.cash/*` and
   `keychain.gr/pay.html*` start receiving traffic. Fallback Workers only if
   live HTML is still wait-a-day.
5. Runs `upload-120cash.ps1` — **WHM `:2087` passthrough** if `:2083` fails.

`upload-120cash.ps1` (nav.js first, then 120.cash index, then keychain after-pay):

1. Writes catalog `/assets/nav.js` (cash_120 Pay → cash.keychain.gr).
2. Patches 120.cash `index.html` so source is same-night (curl/Google see HTML, not JS).
3. **Only after** live 120.cash no longer says “one working day”: Fileman
   `sitemap.xml` (lastmod + hourly) and IndexNow key
   `7c2a9f1e4b8d0c3a5e6f7a8b9c0d1e2f.txt`, then ping IndexNow for
   `https://120.cash/` only. Do not IndexNow the wait-a-day page.
4. Patches **only** `cash_120` on live `keychain.gr/pay.html` so after pay the
   buyer lands on github.io `paid.html` (brief → live page the same night).

The new 120.cash `#brief` (what live keychain still opens) puts the page live
the same night without a second charge. Keep `/assets/`. Leave `brief-submit.php`.
Do not rewrite other keychain plans.

Then:

- https://120.cash/ must say brief then pay, not one working day
- https://120.cash/ `#brief` must say “You paid. Leave the brief.”
- https://keychain.gr/pay.html should mention `github.io/paid.html` and should not
  send `cash_120` to `120.cash/#brief` — but `#brief` now delivers even if that
  patch misses
