from pathlib import Path
import gzip, base64, hashlib, json, os, urllib.request

b64 = Path(".github/workflow-src/put-catalog-nav.0700.yml.gz.b64").read_text().strip()
raw = gzip.decompress(base64.b64decode(b64))
n = len(raw)
h = hashlib.sha256(raw).hexdigest()
print("LEN", n)
print("SHA256", h)
assert n == 44780, n
assert h == "d975206436a4df7bc05534e1f7a55286f3d02a054ecebf488bd77c864c20c67b"
Path(".github/workflows/put-catalog-nav.yml").write_bytes(raw)
print("wrote local file")

tok = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
if not tok:
    raise SystemExit("no token")
url = "https://api.github.com/repos/agency002com-ship-it/agency002com-ship-it.github.io/contents/.github/workflows/put-catalog-nav.yml"
headers = {
    "Authorization": "Bearer " + tok,
    "Accept": "application/vnd.github+json",
    "User-Agent": "restore-0700",
}
req = urllib.request.Request(url, headers=headers)
with urllib.request.urlopen(req, timeout=30) as r:
    meta = json.load(r)
sha = meta["sha"]
print("remote_sha", sha)
payload = {
    "message": "ping 07:00 Sep 29 catalog-nav Fileman 02:20 5s",
    "content": base64.b64encode(raw).decode(),
    "sha": sha,
    "branch": "main",
}
req = urllib.request.Request(
    url,
    data=json.dumps(payload).encode(),
    headers={**headers, "Content-Type": "application/json"},
    method="PUT",
)
try:
    with urllib.request.urlopen(req, timeout=60) as r:
        out = json.load(r)
    print("commit", out.get("commit", {}).get("sha"))
    print("blob", out.get("content", {}).get("sha"))
    print("size", out.get("content", {}).get("size"))
except urllib.error.HTTPError as e:
    print("PUT_FAIL", e.code, e.read()[:500])
    raise
