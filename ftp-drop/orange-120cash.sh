#!/usr/bin/env bash
# Orange-cloud 120.cash (same-night homepage) and keychain.gr/pay.html (cash_120 bounce).
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
  routes="$(curl -fsS "${AUTH[@]}" "https://api.cloudflare.com/client/v4/zones/${zone_id}/workers/routes")"
  local pattern
  for pattern in "$@"; do
    local have
    have="$(python3 -c 'import json,sys; d=json.load(sys.stdin); print("yes" if any(r.get("pattern")==sys.argv[1] for r in (d.get("result") or [])) else "no")' "$pattern" <<<"$routes")"
    if [ "$have" = "yes" ]; then
      echo "Route already present: $pattern"
      continue
    fi
    curl -fsS -X POST "${AUTH[@]}" "https://api.cloudflare.com/client/v4/zones/${zone_id}/workers/routes" \
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
    recs="$(curl -fsS -H "Authorization: Bearer ${TOKEN}" "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?name=${name}")"
    ZONE_ID="$zone_id" CF_TOKEN="$TOKEN" DNS_JSON="$recs" python3 <<'PY'
import json, os, urllib.request
data = json.loads(os.environ["DNS_JSON"])
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
  local zones zone_id account_id
  zones="$(curl -sS "${AUTH[@]}" "https://api.cloudflare.com/client/v4/zones?name=${name}" || true)"
  zone_id="$(python3 -c 'import json,sys; d=json.load(sys.stdin); r=d.get("result") or []; print(r[0]["id"] if r else "")' <<<"$zones")"
  account_id="$(python3 -c 'import json,sys; d=json.load(sys.stdin); r=d.get("result") or []; print(r[0]["account"]["id"] if r else "")' <<<"$zones")"
  printf '%s %s' "$zone_id" "$account_id"
}

page="$(curl -fsSL https://120.cash/ || true)"
if echo "$page" | grep -q '#book' && ! echo "$page" | grep -q 'one working day'; then
  echo "120.cash already same-night. Skip homepage Worker."
else
  read -r zone_id account_id <<<"$(zone_info 120.cash)"
  if [ -z "$zone_id" ] || [ -z "$account_id" ]; then
    echo "No Cloudflare zone 120.cash on this token."
  else
    echo "120.cash zone=$zone_id account=$account_id"
    upload_worker "$account_id" "shift002-120cash" "$here/orange-worker.js" || echo "WARN 120.cash worker upload failed"
    ensure_routes "$zone_id" "shift002-120cash" '120.cash/*' 'www.120.cash/*' || true
    proxy_names "$zone_id" "120.cash" "www.120.cash" || true
  fi
fi

pay="$(curl -fsSL https://keychain.gr/pay.html || true)"
if echo "$pay" | grep -q 'github.io/paid.html' && ! echo "$pay" | grep -Fq "a('https://120.cash/#brief'"; then
  echo "keychain cash_120 already returns to paid.html. Skip pay.html Worker."
else
  read -r kzone kaccount <<<"$(zone_info keychain.gr)"
  if [ -z "$kzone" ] || [ -z "$kaccount" ]; then
    echo "No Cloudflare zone keychain.gr on this token. Fileman still needed for the till."
  else
    echo "keychain.gr zone=$kzone account=$kaccount"
    upload_worker "$kaccount" "shift002-keychain" "$here/orange-keychain-worker.js" || echo "WARN keychain worker upload failed"
    ensure_routes "$kzone" "shift002-keychain" 'keychain.gr/pay.html*' 'www.keychain.gr/pay.html*' || true
    proxy_names "$kzone" "keychain.gr" "www.keychain.gr" || true
  fi
fi

sleep 3
live="$(curl -fsSL https://120.cash/ || true)"
if echo "$live" | grep -q '#book' && ! echo "$live" | grep -q 'one working day'; then
  echo "https://120.cash/ is brief then pay via Cloudflare Worker."
else
  echo "WARN: 120.cash HTML not flipped yet (DNS/cache). Worker may still be uploading."
fi
khtml="$(curl -fsSL https://keychain.gr/pay.html || true)"
if echo "$khtml" | grep -q 'github.io/paid.html' && ! echo "$khtml" | grep -Fq "a('https://120.cash/#brief'"; then
  echo "https://keychain.gr/pay.html cash_120 now returns to paid.html."
else
  echo "WARN: keychain cash_120 bounce not flipped yet (DNS/cache or zone token)."
fi
