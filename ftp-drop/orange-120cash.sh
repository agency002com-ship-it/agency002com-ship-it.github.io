#!/usr/bin/env bash
# Orange-cloud 120.cash and intercept GET / with the same-night page.
# Does not replace Workers grok / grok-cf. Does not touch keychain.gr.
# Needs CLOUDFLARE_API_TOKEN. Does not invent one.
set -euo pipefail

TOKEN="${CLOUDFLARE_API_TOKEN:-}"
if [ -z "$TOKEN" ]; then
  echo "No CLOUDFLARE_API_TOKEN. Skip."
  exit 0
fi

page="$(curl -fsSL https://120.cash/ || true)"
if echo "$page" | grep -q '#book' && ! echo "$page" | grep -q 'one working day'; then
  echo "120.cash already same-night. Skip."
  exit 0
fi

AUTH=( -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" )
zones="$(curl -fsS "${AUTH[@]}" "https://api.cloudflare.com/client/v4/zones?name=120.cash")"
zone_id="$(python3 -c 'import json,sys; d=json.load(sys.stdin); r=d.get("result") or []; print(r[0]["id"] if r else "")' <<<"$zones")"
account_id="$(python3 -c 'import json,sys; d=json.load(sys.stdin); r=d.get("result") or []; print(r[0]["account"]["id"] if r else "")' <<<"$zones")"
if [ -z "$zone_id" ] || [ -z "$account_id" ]; then
  echo "No Cloudflare zone 120.cash on this token."
  exit 1
fi
echo "zone=$zone_id account=$account_id"

here="$(cd "$(dirname "$0")" && pwd)"
worker="$here/orange-worker.js"
if [ ! -f "$worker" ]; then
  echo "missing orange-worker.js"
  exit 1
fi
meta="$(mktemp)"
printf '%s' '{"main_module":"worker.js","bindings":[],"compatibility_date":"2026-09-01"}' >"$meta"
put="$(curl -sS -X PUT "https://api.cloudflare.com/client/v4/accounts/${account_id}/workers/scripts/shift002-120cash" \
  -H "Authorization: Bearer ${TOKEN}" \
  -F "worker.js=@${worker};type=application/javascript+module" \
  -F "metadata=@${meta};type=application/json")"
rm -f "$meta"
python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d.get("success") else 1)' <<<"$put" \
  || { echo "Worker upload failed: $put"; exit 1; }
echo "Worker shift002-120cash uploaded (did not replace grok / grok-cf)."

routes="$(curl -fsS "${AUTH[@]}" "https://api.cloudflare.com/client/v4/zones/${zone_id}/workers/routes")"
for pattern in '120.cash/*' 'www.120.cash/*'; do
  have="$(python3 -c 'import json,sys; d=json.load(sys.stdin); print("yes" if any(r.get("pattern")==sys.argv[1] for r in (d.get("result") or [])) else "no")' "$pattern" <<<"$routes")"
  if [ "$have" = "yes" ]; then
    echo "Route already present: $pattern"
    continue
  fi
  curl -fsS -X POST "${AUTH[@]}" "https://api.cloudflare.com/client/v4/zones/${zone_id}/workers/routes" \
    --data "{\"pattern\":\"${pattern}\",\"script\":\"shift002-120cash\"}" >/dev/null \
    && echo "Added route $pattern" \
    || echo "WARN route $pattern failed"
done

dns="$(curl -fsS -H "Authorization: Bearer ${TOKEN}" "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?type=A&name=120.cash")"
ZONE_ID="$zone_id" CF_TOKEN="$TOKEN" DNS_JSON="$dns" python3 <<'PY'
import json, os, urllib.request
data = json.loads(os.environ["DNS_JSON"])
zone = os.environ["ZONE_ID"]
token = os.environ["CF_TOKEN"]
for rec in data.get("result") or []:
    if rec.get("proxied"):
        print(f"A {rec.get('name')} already proxied")
        continue
    body = json.dumps({
        "proxied": True,
        "type": rec.get("type", "A"),
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
        print(f"Proxied A {rec.get('name')}: {out.get('success')}")
    except Exception as e:
        print(f"WARN DNS proxy {rec.get('name')}: {e}")
PY

sleep 3
live="$(curl -fsSL https://120.cash/ || true)"
if echo "$live" | grep -q '#book' && ! echo "$live" | grep -q 'one working day'; then
  echo "https://120.cash/ is brief then pay via Cloudflare Worker."
else
  echo "WARN: 120.cash HTML not flipped yet (DNS/cache). Worker is uploaded."
fi
