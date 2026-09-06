#!/usr/bin/env bash
# Laptop Grok: put the same-night €120 door on 120.cash.
# Does not send mail. Does not touch PayPal passwords.
set -euo pipefail

BASE="https://agency002com-ship-it.github.io/ftp-drop"
DEST="${DEST:-./120cash-night-desk}"
UPLOAD=0
for arg in "$@"; do
  case "$arg" in
    --upload) UPLOAD=1 ;;
    *) DEST="$arg" ;;
  esac
done

mkdir -p "$DEST"
cd "$DEST"

files=(
  120-index.html
  desk-lib.php
  desk-checkout.php
  thanks.php
  live.php
  config.example.php
  .htaccess
  README.md
)

echo "Downloading night desk files from $BASE"
for f in "${files[@]}"; do
  echo "  $f"
  curl -fsSL "$BASE/$f" -o "$f"
done

if [[ ! -f config.local.php ]]; then
  cp config.example.php config.local.php
  if command -v openssl >/dev/null 2>&1; then
    secret="$(openssl rand -hex 32)"
    if sed --version >/dev/null 2>&1; then
      sed -i "s/REPLACE_WITH_32_PLUS_HEX/$secret/" config.local.php
    else
      sed -i '' "s/REPLACE_WITH_32_PLUS_HEX/$secret/" config.local.php
    fi
    echo "Wrote config.local.php with a new job_secret. Do not commit it."
  else
    echo "Fill job_secret in config.local.php (openssl rand -hex 32)."
  fi
fi

echo
echo "Minimum (indexed door takes card tonight, live page on github.io):"
echo "  upload 120-index.html  →  index.html   (overwrite 120.cash homepage only)"
echo "  keep /assets/"
echo
echo "Full pack (live page on 120.cash/live.php after pay):"
echo "  120-index.html     → index.html"
echo "  desk-lib.php"
echo "  desk-checkout.php"
echo "  thanks.php"
echo "  live.php"
echo "  config.local.php"
echo "  .htaccess          → merge; do not wipe existing rules"
echo "Leave brief-submit.php in place. Do not touch PayPal passwords."

if [[ "$UPLOAD" -eq 1 ]]; then
  : "${FTP_HOST:?Set FTP_HOST to the 120.cash FTP host}"
  : "${FTP_USER:?Set FTP_USER}"
  : "${FTP_PASS:?Set FTP_PASS}"
  : "${FTP_DIR:?Set FTP_DIR to the 120.cash document root (example: public_html)}"
  if ! command -v lftp >/dev/null 2>&1; then
    echo "lftp is required for --upload. Install it or upload the files by hand." >&2
    exit 1
  fi
  echo
  echo "Uploading to $FTP_HOST:$FTP_DIR"
  lftp -c "
    set ssl:verify-certificate no;
    set ftp:ssl-allow yes;
    open -u ${FTP_USER},${FTP_PASS} ${FTP_HOST};
    cd ${FTP_DIR};
    put 120-index.html -o index.html;
    put desk-lib.php;
    put desk-checkout.php;
    put thanks.php;
    put live.php;
    put config.local.php;
    put .htaccess -o .htaccess.night-desk;
  "
  echo "Uploaded. Merge .htaccess.night-desk into the live .htaccess if one already exists."
  echo "Open https://120.cash/ — it must say same night, not one working day."
  exit 0
fi

echo
echo "This script did not FTP. To upload from the laptop:"
echo "  FTP_HOST=… FTP_USER=… FTP_PASS=… FTP_DIR=public_html \\"
echo "  bash INSTALL.sh --upload"
echo "Or copy the files with the existing cPanel File Manager."
echo "Then open https://120.cash/ and pay with a test card only if the owner asked."
