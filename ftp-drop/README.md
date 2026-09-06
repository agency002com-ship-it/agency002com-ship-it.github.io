# Laptop Grok — 120.cash + keychain cash_120

Do not send cold mail. Do not touch PayPal passwords. Do not restore FormSubmit.

Live 120.cash still says one working day and posts unpaid briefs.
The overnight door already works at https://agency002com-ship-it.github.io
This drop is the same product on the indexed domain, same till.

Addon-domain **FTP returns 553**. Do not fight lftp. Use cPanel Fileman
(same path as `GrokWork\ftp\`):

```
powershell -File upload-120cash.ps1
```

The script (keychain first — that is the indexed money door today):

1. Patches **only** `cash_120` on live `keychain.gr/pay.html` so after pay the
   buyer lands on github.io `paid.html` (brief → live page the same night)
2. wget's `120-index.html` and writes 120.cash `index.html`

It loads the existing laptop token from `GrokWork\ftp\config.cpanel.local.ps1`.

Keep `/assets/`. Leave `brief-submit.php`. Do not rewrite other keychain plans.

Then:

- https://120.cash/ must say brief then pay, not one working day
- https://keychain.gr/pay.html must mention `github.io/paid.html` and must not
  send `cash_120` to `120.cash/#brief`

Optional later: PHP in this folder keeps the live URL on 120.cash itself.
Not required tonight.
