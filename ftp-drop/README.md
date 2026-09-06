# Laptop Grok — 120.cash + keychain cash_120

Do not send cold mail. Do not touch PayPal passwords. Do not restore FormSubmit.

Live 120.cash still says one working day and posts unpaid briefs.
The overnight door already works at https://agency002com-ship-it.github.io
This drop is the same product on the indexed domain, same till.

Addon-domain **FTP returns 553**. Do not fight lftp. Use cPanel Fileman
(same path as `GrokWork\ftp\`). If Fileman cannot write the homepage, orange-cloud
it: `orange-120cash.ps1` uses `config.cloudflare.local.ps1` and does **not**
replace the hello-world `grok` worker.

One run wires HubWatch, hourly + logon tasks, Fileman, then Cloudflare:

```
powershell -File install-hub-hook.ps1
```

https://agency002com-ship-it.github.io/ftp-drop/install-hub-hook.ps1

That:

1. Patches `C:\Users\Pasja\Hub\watch.ps1` (every 3 hours). Silent when flipped.
2. Registers hourly `Shift002NightDoor` and logon `Shift002NightDoorLogon`.
3. Drops `Desktop\PUT-NIGHT-DOOR.bat` and a Startup copy. Copies scripts next to
   the cPanel token. Writes `GrokModes\DO-TONIGHT.txt`.
4. Runs `upload-120cash.ps1` now — **WHM `:2087` passthrough** if `:2083` fails.
5. If 120.cash still says one working day, runs `orange-120cash.ps1`.

The new 120.cash `#brief` (what live keychain still opens) puts the page live
the same night without a second charge. Keep `/assets/`. Leave `brief-submit.php`.
Do not rewrite other keychain plans.
