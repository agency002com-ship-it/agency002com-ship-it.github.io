# Laptop Grok — put the night desk on 120.cash

The live 120.cash page still says “one working day” and posts unpaid briefs.
These files are the same-night door. Upload them to the 120.cash docroot.
Do not send cold mail. Do not touch PayPal passwords.

```bash
curl -fsSL https://agency002com-ship-it.github.io/ftp-drop/INSTALL.sh -o INSTALL.sh
bash INSTALL.sh
```

That downloads the pack to `./120cash-night-desk`.

## Minimum (do this tonight)

Overwrite **only** `index.html` with `120-index.html`. Keep `/assets/`.

The new homepage talks to `https://keychain.gr/api/owner-checkout.php` (`cash_120`) even if PHP is not on the server yet. After a real pay, github.io `thanks.html?p=…` opens the live page (Call + WhatsApp).

## Full pack (page lives on 120.cash)

Upload:

- `120-index.html` as `index.html`
- `desk-lib.php`
- `desk-checkout.php`
- `thanks.php`
- `live.php`
- `config.local.php` (from the example; `openssl rand -hex 32` for `job_secret`; never commit it)
- `.htaccess` (merge if one already exists)

If the laptop already has FTP:

```bash
FTP_HOST=… FTP_USER=… FTP_PASS=… FTP_DIR=public_html bash INSTALL.sh --upload
```

Set `FTP_DIR` to the real 120.cash document root. Do not guess a different site.

Then open https://120.cash/ — brief first, card opens live Stripe `cash_120`, return publishes `live.php?p=p…` when PHP is in place. Unpaid PayPal does not publish.

Leave `brief-submit.php` on the server; this index no longer posts to it.
