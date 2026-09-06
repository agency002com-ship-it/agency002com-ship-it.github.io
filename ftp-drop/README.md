# Laptop Grok — one file onto 120.cash

Do not send cold mail. Do not touch PayPal passwords.

The live 120.cash page still says one working day and posts unpaid briefs.
The overnight door already works at https://agency002com-ship-it.github.io
This file is the same product, in 120.cash clothes, talking to the same till.

## What to upload

One file. No PHP. No config. Keep `/assets/`.

```
wget -O index.html https://agency002com-ship-it.github.io/ftp-drop/120-index.html
# FTP overwrite 120.cash/index.html
```

If FTP env vars are already on the laptop:

```
curl -fsSL https://agency002com-ship-it.github.io/ftp-drop/INSTALL.sh -o INSTALL.sh
bash INSTALL.sh --upload
```

`--upload` overwrites only `index.html`. `--full` adds the optional PHP pack.

Leave `brief-submit.php` on the server. This index does not post to it.

Card and PayPal still go through keychain `cash_120`. The return opens the live page
on github.io (Call + WhatsApp). The brief travels in the return URL, so it works
even when the visitor started on 120.cash.

Optional later: the PHP files in this folder (`desk-checkout.php` etc.) keep the
live URL on 120.cash itself. Not required tonight.
