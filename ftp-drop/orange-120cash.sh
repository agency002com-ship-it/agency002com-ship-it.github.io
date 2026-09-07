#!/usr/bin/env bash
# Orange-cloud 120.cash, keychain.gr, eidotevil.com, agency002.com, and sebarv.com
# so existing grok-cf routes receive traffic.
# DNS proxy first. New workers only if live HTML still wait-a-day.
# Does not replace Workers grok / grok-cf. Does not invent tokens.
# Needs CLOUDFLARE_API_TOKEN. Empty token → exit 0.
set -euo pipefail

TOKEN="${CLOUDFLARE_API_TOKEN:-}"
if [ -z "$TOKEN" ]; then
  echo "No CLOUDFLARE_API_TOKEN. Skip."
  exit 0
fi

AUTH=( -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" )
here="$(cd "$(dirname "$0")" && pwd)"

upload_worker() {
  local account_id="$1" name="$2" file="$3"
  if [ ! -f "$file" ]; then
    echo "missing $file"
    return 1
  fi
  local meta
  meta="$(mktemp)"
  printf '%s' '{"main_module":"worker.js","bindings":[],"compatibility_date":"2026-09-01"}' >"$meta"
  local put
  put="$(curl -sS -X PUT "https://api.cloudflare.com/client/v4/accounts/${account_id}/workers/scripts/${name}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -F "worker.js=@${file};type=application/javascript+module" \
    -F "metadata=@${meta};type=application/json")"
  rm -f "$meta"
  python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d.get("success") else 1)' <<<"$put" \
    || { echo "Worker upload failed: $put"; return 1; }
  echo "Worker $name uploaded (did not replace grok / grok-cf)."
}

ensure_routes() {
  local zone_id="$1" script="$2"
  shift 2
  local routes
  routes="$(curl -sS "${AUTH[@]}" "https://api.cloudflare.com/client/v4/zones/${zone_id}/workers/routes" || true)"
  local pattern
  for pattern in "$@"; do
    local have
    have="$(python3 -c 'import json,sys; d=json.load(sys.stdin); print("yes" if any(r.get("pattern")==sys.argv[1] for r in (d.get("result") or [])) else "no")' "$pattern" <<<"$routes" 2>/dev/null || echo no)"
    if [ "$have" = "yes" ]; then
      echo "Route already present: $pattern"
      continue
    fi
    curl -sS -X POST "${AUTH[@]}" "https://api.cloudflare.com/client/v4/zones/${zone_id}/workers/routes" \
      --data "{\"pattern\":\"${pattern}\",\"script\":\"${script}\"}" >/dev/null \
      && echo "Added route $pattern" \
      || echo "WARN route $pattern failed"
  done
}

proxy_names() {
  local zone_id="$1"
  shift
  local name recs
  for name in "$@"; do
    recs="$(curl -sS -H "Authorization: Bearer ${TOKEN}" "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?name=${name}" || true)"
    ZONE_ID="$zone_id" CF_TOKEN="$TOKEN" DNS_JSON="$recs" python3 <<'PY'
import json, os, urllib.request
raw = os.environ.get("DNS_JSON") or "{}"
try:
    data = json.loads(raw)
except Exception as e:
    print(f"WARN DNS list parse: {e}")
    raise SystemExit(0)
if not data.get("success", True) and not data.get("result"):
    err = (data.get("errors") or [{}])[0]
    print(f"WARN DNS list: {err.get('message') or data}")
    raise SystemExit(0)
zone = os.environ["ZONE_ID"]
token = os.environ["CF_TOKEN"]
for rec in data.get("result") or []:
    if rec.get("type") not in ("A", "AAAA", "CNAME"):
        continue
    if rec.get("proxied"):
        print(f"{rec.get('type')} {rec.get('name')} already proxied")
        continue
    body = json.dumps({
        "proxied": True,
        "type": rec.get("type"),
        "name": rec.get("name"),
        "content": rec.get("content"),
    }).encode()
    req = urllib.request.Request(
        f"https://api.cloudflare.com/client/v4/zones/{zone}/dns_records/{rec['id']}",
        data=body, method="PATCH",
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            out = json.load(resp)
        print(f"Proxied {rec.get('type')} {rec.get('name')}: {out.get('success')}")
    except Exception as e:
        print(f"WARN DNS proxy {rec.get('name')}: {e}")
PY
  done
}

zone_info() {
  local name="$1"
  local zones
  zones="$(curl -sS "${AUTH[@]}" "https://api.cloudflare.com/client/v4/zones?name=${name}" || true)"
  python3 -c 'import json,sys
d=json.load(sys.stdin)
r=d.get("result") or []
print((r[0]["id"]+" "+r[0]["account"]["id"]) if r else " ")' <<<"$zones" 2>/dev/null || echo " "
}

cash_night() {
  local page
  page="$(curl -fsSL https://120.cash/ || true)"
  echo "$page" | grep -q '#book' && ! echo "$page" | grep -q 'one working day'
}

pay_night() {
  local pay
  pay="$(curl -fsSL https://keychain.gr/pay.html || true)"
  echo "$pay" | grep -q 'github.io/paid.html' && ! echo "$pay" | grep -Fq "a('https://120.cash/#brief'"
}

eido_night() {
  local page
  page="$(curl -fsSL https://eidotevil.com/ || true)"
  echo "$page" | grep -Fq 'tonight.agency002.com/#book'
}

agency_night() {
  local page
  page="$(curl -fsSL -A 'Mozilla/5.0' https://agency002.com/ || true)"
  echo "$page" | grep -Fq 'tonight.agency002.com'
}

sebarv_night() {
  local page
  page="$(curl -fsSL https://sebarv.com/ || true)"
  echo "$page" | grep -Fq 'tonight.agency002.com/#book'
}

read -r zone_id account_id <<<"$(zone_info 120.cash)"
if [ -n "${zone_id:-}" ] && [ "$zone_id" != "" ]; then
  echo "Orange-cloud 120.cash DNS first (do not replace grok-cf). zone=$zone_id"
  proxy_names "$zone_id" "120.cash" "www.120.cash" || true
  ensure_routes "$zone_id" "grok-cf" '120.cash/*' 'www.120.cash/*' || true
else
  echo "No Cloudflare zone 120.cash on this token."
fi

read -r kzone kaccount <<<"$(zone_info keychain.gr)"
if [ -n "${kzone:-}" ] && [ "$kzone" != "" ]; then
  echo "Orange-cloud keychain.gr DNS first (do not replace grok-cf). zone=$kzone"
  proxy_names "$kzone" "keychain.gr" "www.keychain.gr" || true
  ensure_routes "$kzone" "grok-cf" 'keychain.gr/pay.html*' 'www.keychain.gr/pay.html*' || true
else
  echo "No Cloudflare zone keychain.gr on this token."
fi

read -r ezone eaccount <<<"$(zone_info eidotevil.com)"
if [ -n "${ezone:-}" ] && [ "$ezone" != "" ]; then
  echo "Orange-cloud eidotevil.com DNS (indexed catalog). Do not overlay 120-index. zone=$ezone"
  proxy_names "$ezone" "eidotevil.com" "www.eidotevil.com" || true
  ensure_routes "$ezone" "grok-cf" 'eidotevil.com/*' 'www.eidotevil.com/*' || true
else
  echo "No Cloudflare zone eidotevil.com on this token."
fi

read -r azone aaccount <<<"$(zone_info agency002.com)"
if [ -n "${azone:-}" ] && [ "$azone" != "" ]; then
  echo "Orange-cloud agency002.com apex/www (indexed catalog). Do not overlay 120-index. zone=$azone"
  proxy_names "$azone" "agency002.com" "www.agency002.com" || true
  ensure_routes "$azone" "grok-cf" 'agency002.com/*' 'www.agency002.com/*' || true
else
  echo "No Cloudflare zone agency002.com on this token."
fi

read -r szone saccount <<<"$(zone_info sebarv.com)"
if [ -n "${szone:-}" ] && [ "$szone" != "" ]; then
  echo "Orange-cloud sebarv.com apex/www (indexed catalog). Do not overlay 120-index. zone=$szone"
  proxy_names "$szone" "sebarv.com" "www.sebarv.com" || true
  ensure_routes "$szone" "grok-cf" 'sebarv.com/*' 'www.sebarv.com/*' || true
else
  echo "No Cloudflare zone sebarv.com on this token."
fi

sleep 5
if cash_night; then
  echo "https://120.cash/ is brief then pay (grok-cf / orange DNS)."
else
  echo "120.cash still wait-a-day after DNS. Fallback Worker shift002-120cash (origin IP, not grok-cf)."
  if [ -n "${zone_id:-}" ] && [ -n "${account_id:-}" ]; then
    upload_worker "$account_id" "shift002-120cash" "$here/orange-worker.js" || echo "WARN 120.cash worker upload failed"
    ensure_routes "$zone_id" "shift002-120cash" '120.cash/*' 'www.120.cash/*' || true
    proxy_names "$zone_id" "120.cash" "www.120.cash" || true
  fi
fi

if pay_night; then
  echo "keychain cash_120 already returns to paid.html."
else
  echo "keychain still old bounce after DNS. Fallback Worker shift002-keychain."
  if [ -n "${kzone:-}" ] && [ -n "${kaccount:-}" ]; then
    upload_worker "$kaccount" "shift002-keychain" "$here/orange-keychain-worker.js" || echo "WARN keychain worker upload failed"
    ensure_routes "$kzone" "shift002-keychain" 'keychain.gr/pay.html*' 'www.keychain.gr/pay.html*' || true
    proxy_names "$kzone" "keychain.gr" "www.keychain.gr" || true
  fi
fi

sleep 3
if cash_night; then echo "https://120.cash/ is brief then pay via Cloudflare."
else echo "WARN: 120.cash HTML not flipped yet (DNS/cache or token lacks Zone DNS Edit)."; fi
if pay_night; then echo "https://keychain.gr/pay.html cash_120 now returns to paid.html."
else echo "WARN: keychain cash_120 bounce not flipped yet (DNS/cache or zone token)."; fi
if eido_night; then echo "https://eidotevil.com/ cash_120 now opens tonight.agency002.com."
else echo "WARN: eidotevil.com still sends cash_120 to wait-a-day (need orange DNS or Fileman)."; fi
if agency_night; then echo "https://agency002.com/ cash_120 now opens tonight.agency002.com."
else echo "WARN: agency002.com still sends cash_120 to wait-a-day (need orange DNS or Fileman)."; fi
if sebarv_night; then echo "https://sebarv.com/ cash_120 now opens tonight.agency002.com."
else echo "WARN: sebarv.com still sends cash_120 to wait-a-day (need orange DNS or Fileman)."; fi
