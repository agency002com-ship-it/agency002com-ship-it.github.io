# Laptop Grok — one file onto 120.cash

Do not send cold mail. Do not touch PayPal passwords.

The live 120.cash page still says one working day and posts unpaid briefs.
The overnight door already works at https://agency002com-ship-it.github.io
This file is the same product, in 120.cash clothes, talking to the same till.

## What to upload

One file. No PHP. No config. Keep `/assets/`.

Addon-domain **FTP returns 553** on this account. Do not fight lftp. Use cPanel Fileman (same path as `GrokWork\ftp\`):

```
powershell -File upload-120cash.ps1
```

The script wget's `120-index.html` and writes `index.html` through Fileman.
It loads the existing laptop token from `GrokWork\ftp\config.cpanel.local.ps1` when that file is there.

Leave `brief-submit.php` on the server. This index does not post to it.

Then open https://120.cash/ — it must say brief then pay, not one working day.

Card and PayPal still go through keychain `cash_120`. The return opens the live page
on github.io (Call + WhatsApp). The brief travels in the return URL, so it works
even when the visitor started on 120.cash.

Optional later: the PHP files in this folder (`desk-checkout.php` etc.) keep the
live URL on 120.cash itself. Not required tonight.
