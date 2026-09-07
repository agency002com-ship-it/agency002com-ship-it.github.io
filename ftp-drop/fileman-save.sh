#!/usr/bin/env bash
# cPanel Fileman::save_file_content. Addon FTP is 553; this is the write path.
# Usage: fileman-save.sh <dir> <filename> <content-file>
# Env: CPANEL_TOKEN (required), CPANEL_HOST (default 192.250.229.162),
#      CPANEL_USER (default agency00)
set -euo pipefail
DIR="${1:?dir}"
FILE="${2:?file}"
CONTENT_FILE="${3:?content file}"
HOST="${CPANEL_HOST:-192.250.229.162}"
USER="${CPANEL_USER:-agency00}"
TOKEN="${CPANEL_TOKEN:-}"
if [ -z "$TOKEN" ]; then
  echo "No CPANEL_TOKEN. Skip Fileman $DIR/$FILE"
  exit 0
fi
CONTENT="$(cat "$CONTENT_FILE")"
post2083() {
  local auth="$1"
  curl -sS -k --fail-with-body -X POST \
    "https://${HOST}:2083/execute/Fileman/save_file_content" \
    -H "Authorization: ${auth}" \
    --data-urlencode "dir=${DIR}" \
    --data-urlencode "file=${FILE}" \
    --data-urlencode "content=${CONTENT}" \
    --data-urlencode "charset=utf-8"
}
if post2083 "cpanel ${USER}:${TOKEN}"; then
  echo "Fileman :2083 cpanel $DIR/$FILE"
  exit 0
fi
AUTH="$(printf '%s:%s' "$USER" "$TOKEN" | base64 | tr -d '\n')"
if post2083 "Basic ${AUTH}"; then
  echo "Fileman :2083 basic $DIR/$FILE"
  exit 0
fi
if curl -sS -k --fail-with-body -X POST "https://${HOST}:2087/json-api/cpanel" \
  -H "Authorization: WHM ${USER}:${TOKEN}" \
  --data "cpanel_jsonapi_user=${USER}" \
  --data "cpanel_jsonapi_apimodule=Fileman" \
  --data "cpanel_jsonapi_apifunc=save_file_content" \
  --data "cpanel_jsonapi_version=2" \
  --data-urlencode "dir=${DIR}" \
  --data-urlencode "file=${FILE}" \
  --data-urlencode "content=${CONTENT}" \
  --data "charset=utf-8"; then
  echo "Fileman :2087 WHM $DIR/$FILE"
  exit 0
fi
echo "WARN Fileman failed $DIR/$FILE"
exit 0
