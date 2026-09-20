from pathlib import Path
import gzip, base64, hashlib

b64 = Path(".github/workflow-src/put-catalog-nav.1618.yml.gz.b64").read_text().strip()
raw = gzip.decompress(base64.b64decode(b64))
n = len(raw)
h = hashlib.sha256(raw).hexdigest()
print("LEN", n)
print("SHA", h)
assert n == 105220, n
assert h == "a3b3c0556b1d5fbcb89d8d61fa56b35a8b98fbed8b45c02e4ecdbea1fbdd54fb"
Path(".github/workflows/put-catalog-nav.yml").write_bytes(raw)
