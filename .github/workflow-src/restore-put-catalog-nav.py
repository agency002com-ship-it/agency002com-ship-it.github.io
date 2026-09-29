from pathlib import Path
import gzip, base64, hashlib

b64 = Path(".github/workflow-src/put-catalog-nav.0700.yml.gz.b64").read_text().strip()
raw = gzip.decompress(base64.b64decode(b64))
n = len(raw)
h = hashlib.sha256(raw).hexdigest()
print("LEN", n)
print("SHA", h)
assert n == 44780, n
assert h == "d975206436a4df7bc05534e1f7a55286f3d02a054ecebf488bd77c864c20c67b"
Path(".github/workflows/put-catalog-nav.yml").write_bytes(raw)
