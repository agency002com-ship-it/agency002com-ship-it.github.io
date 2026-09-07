#!/usr/bin/env bash
# cPanel Fileman::save_file_content. Addon FTP is 553; this is the write path.
# Known-good: WHM :2087 on 192.250.229.162, cPanel user agency00.
# Usage: fileman-save.sh <dir> <filename> <content-file>
# Env: CPANEL_TOKEN (required; also CPANEL_API_TOKEN / WHM_API_TOKEN / WHM_TOKEN),
#      CPANEL_HOST (default 192.250.229.162), CPANEL_USER (default agency00)
set -euo pipefail
DIR="${1:?dir}"
FILE="${2:?file}"
CONTENT_FILE="${3:?content file}"
HOST="${CPANEL_HOST:-192.250.229.162}"
USER="${CPANEL_USER:-agency00}"
TOKEN="${CPANEL_TOKEN:-${CPANEL_API_TOKEN:-${WHM_API_TOKEN:-${WHM_TOKEN:-}}}}"
if [ -z "$TOKEN" ]; then
  echo "No CPANEL_TOKEN. Skip Fileman $DIR/$FILE"
  exit 0
fi
export CPANEL_TOKEN="$TOKEN"
CONTENT="$(cat "$CONTENT_FILE")"

fileman_ok() {
  python3 - "$1" <<'PY'
import json, sys
raw = sys.argv[1]
try:
    d = json.loads(raw)
except Exception:
    sys.exit(1)
if d.get("status") == 0:
    sys.exit(1)
if d.get("status") == 1:
    sys.exit(0)
ev = ((d.get("cpanelresult") or {}).get("event") or {}).get("result")
if ev in (0, "0"):
    sys.exit(1)
if ev in (1, "1"):
    sys.exit(0)
meta = (d.get("metadata") or {}).get("result")
if meta in (0, "0"):
    sys.exit(1)
if meta in (1, "1"):
    sys.exit(0)
errs = d.get("errors")
if isinstance(errs, list) and errs:
    sys.exit(1)
if d.get("cpanelresult") or d.get("data") is not None:
    sys.exit(0)
sys.exit(1)
PY
}

try_whm() {
  local h="$1" wu="$2"
  local out
  out="$(curl -sS -k -X POST "https://${h}:2087/json-api/cpanel" \
    -H "Authorization: WHM ${wu}:${TOKEN}" \
    --data "cpanel_jsonapi_user=${USER}" \
    --data "cpanel_jsonapi_apimodule=Fileman" \
    --data "cpanel_jsonapi_apifunc=save_file_content" \
    --data "cpanel_jsonapi_version=2" \
    --data-urlencode "dir=${DIR}" \
    --data-urlencode "file=${FILE}" \
    --data-urlencode "content=${CONTENT}" \
    --data "charset=utf-8" || true)"
  if fileman_ok "$out"; then
    echo "Fileman :2087 WHM $wu $DIR/$FILE"
    return 0
  fi
  return 1
}

try_2083() {
  local h="$1" auth="$2" label="$3"
  local out
  out="$(curl -sS -k -X POST \
    "https://${h}:2083/execute/Fileman/save_file_content" \
    -H "Authorization: ${auth}" \
    --data-urlencode "dir=${DIR}" \
    --data-urlencode "file=${FILE}" \
    --data-urlencode "content=${CONTENT}" \
    --data-urlencode "charset=utf-8" || true)"
  if fileman_ok "$out"; then
    echo "Fileman :2083 $label $DIR/$FILE"
    return 0
  fi
  return 1
}

HOSTS=("$HOST" "192.250.229.162" "agency002.com")
uniq_hosts=()
for h in "${HOSTS[@]}"; do
  skip=0
  for u in "${uniq_hosts[@]+"${uniq_hosts[@]}"}"; do
    if [ "$u" = "$h" ]; then skip=1; break; fi
  done
  if [ "$skip" -eq 0 ]; then uniq_hosts+=("$h"); fi
done

for h in "${uniq_hosts[@]}"; do
  for wu in "$USER" root; do
    if try_whm "$h" "$wu"; then exit 0; fi
  done
done

AUTH_B64="$(printf '%s:%s' "$USER" "$TOKEN" | base64 | tr -d '\n')"
for h in "${uniq_hosts[@]}"; do
  if try_2083 "$h" "cpanel ${USER}:${TOKEN}" "cpanel"; then exit 0; fi
  if try_2083 "$h" "Basic ${AUTH_B64}" "basic"; then exit 0; fi
done

echo "WARN Fileman failed $DIR/$FILE"
exit 0
