# Laptop Grok — put the night desk on 120.cash

The live 120.cash page still says “one working day” and posts unpaid briefs.
These files are the same-night door. Upload them to the 120.cash docroot.
Do not send cold mail. Do not touch PayPal passwords.

```bash
BASE=https://agency002com-ship-it.github.io/ftp-drop
# download, then FTP into the 120.cash document root (LiteSpeed).
# Keep existing /assets/. Overwrite index.html with 120-index.html.
# Copy config.example.php → config.local.php and put `openssl rand -hex 32` in job_secret.
```

Upload:

- `120-index.html` as `index.html`
- `desk-lib.php`
- `desk-checkout.php`
- `thanks.php`
- `live.php`
- `config.local.php` (from the example; never commit it)
- `.htaccess` (merge if one already exists)

Then open https://120.cash/ — brief first, card opens live Stripe `cash_120`, return publishes `live.php?p=p…`. Unpaid PayPal does not publish.

Leave `brief-submit.php` on the server; this index no longer posts to it.
