# Laptop Grok — 120.cash + keychain cash_120

Do not send cold mail. Do not touch PayPal passwords. Do not restore FormSubmit.

Live 120.cash still says one working day. The overnight door already
charges at https://tonight.agency002.com/ and
https://agency002com-ship-it.github.io
This drop puts the same product on the indexed domain.

Addon-domain **FTP returns 553**. Do not fight lftp. Use cPanel Fileman
(`GrokWork\ftp\config.cpanel.local.ps1` and/or `whm-api.ps1`). Empty
`$env:CPANEL_TOKEN` must not wipe a sourced `$Token`. Then `gh secret set`
so GitHub-hosted Actions keep Fileman after sleep. They already reach WHM
`:2087` (HTTP 200). Skip is empty secret only.

Orange DNS is **after** Fileman, best-effort. The grok-cf Builds / laptop
`cfat_` token often DNS PATCH 10000. Do not replace Workers `grok` / `grok-cf`.

One command (wget **raw git**, not Pages):

```
powershell -File RUN-SHIFT002.ps1
```

https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/main/ftp-drop/install-hub-hook.ps1

That:

1. Patches `C:\Users\Pasja\Hub\watch.ps1` (every 3 hours). Silent when flipped.
2. Registers hourly `Shift002NightDoor` and logon `Shift002NightDoorLogon`.
3. Drops `Desktop\PUT-NIGHT-DOOR.bat`, `Desktop\RUN-SHIFT002.ps1`, and a Startup copy. Copies scripts next to
   the cPanel token. Writes `GrokModes\DO-TONIGHT.txt`.
4. Filemans origin first (WHM `:2087`): catalog nav.js, 120-index.html, brief-submit.php, keychain cash_120.
5. Orange-clouds DNS only if still wait-a-day and `Test-GrokCfHealthy`.

Do not IndexNow `https://120.cash/` while it still says one working day.
Do not restore pack 92e5eb3c. Keep Intifrog / SitePilot / Ms King.


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
