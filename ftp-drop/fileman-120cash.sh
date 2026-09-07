#!/bin/bash
# Fileman 120.cash onto every known origin path, including the live addon docroot.
# Empty CPANEL_TOKEN (and laptop aliases) → exit 0. Does not replace grok / grok-cf.
set -euo pipefail
chmod +x ftp-drop/fileman-save.sh
HOST="${CPANEL_HOST:-192.250.229.162}"
WHM_CODE="$(curl -k -sS -o /dev/null -w '%{http_code}' --max-time 8 "https://${HOST}:2087/" || true)"
echo "WHM :2087 HTTP ${WHM_CODE:-fail}"
echo "::notice::WHM :2087 HTTP ${WHM_CODE:-fail}"
if [ -z "${CPANEL_TOKEN:-}" ]; then
  CPANEL_TOKEN="${CPANEL_API_TOKEN:-${WHM_API_TOKEN:-${WHM_TOKEN:-}}}"
  export CPANEL_TOKEN
fi
if [ -z "${CPANEL_TOKEN:-}" ]; then
  echo "No CPANEL_TOKEN secret. Skip 120.cash Fileman."
  exit 0
fi
NAV_BYTES="$(wc -c < ftp-drop/nav-night.js | tr -d ' ')"
if [ "${NAV_BYTES:-0}" -lt 500 ] || ! grep -Fq 'cash.keychain.gr' ftp-drop/nav-night.js; then
  echo "nav-night.js is not the night rewrite (bytes=${NAV_BYTES}). Refusing to overwrite 120.cash /assets/nav.js with a year stamp."
  exit 0
fi
if ! grep -q '#book' ftp-drop/120-index.html || grep -q 'one working day' ftp-drop/120-index.html; then
  echo "120-index.html is not the same-night door. Refusing origin index.html write."
  exit 0
fi
USER="${CPANEL_USER:-agency00}"
DIR="${CPANEL_DIR:-/home/${USER}/domains/120.cash/public_html}"
ROOTS="${DIR} /home/${USER}/120.cash /home/${USER}/public_html/120.cash /home/${USER}/domains/120.cash/public_html"
for ROOT in $ROOTS; do
  ftp-drop/fileman-save.sh "${ROOT}/assets" nav.js ftp-drop/nav-night.js
  ftp-drop/fileman-save.sh "${ROOT}" index.html ftp-drop/120-index.html
done
if grep -Fq 'cash.120.cash/api/publish' ftp-drop/brief-submit.php; then
  for ROOT in $ROOTS; do
    ftp-drop/fileman-save.sh "${ROOT}" brief-submit.php ftp-drop/brief-submit.php
  done
fi
sleep 3
page="$(curl -fsSL -A 'Mozilla/5.0' https://120.cash/ || true)"
if echo "$page" | grep -q '#book' && ! echo "$page" | grep -q 'one working day'; then
  STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  sed "s/LASTMOD/${STAMP}/" ftp-drop/120-sitemap.xml.tpl > /tmp/120-sitemap.xml
  printf '%s' '7c2a9f1e4b8d0c3a5e6f7a8b9c0d1e2f' > /tmp/120-indexnow.txt
  for ROOT in $ROOTS; do
    ftp-drop/fileman-save.sh "${ROOT}" sitemap.xml /tmp/120-sitemap.xml
    ftp-drop/fileman-save.sh "${ROOT}" 7c2a9f1e4b8d0c3a5e6f7a8b9c0d1e2f.txt /tmp/120-indexnow.txt
  done
else
  echo "Skip origin sitemap/IndexNow while 120.cash still wait-a-day."
fi
