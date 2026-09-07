#!/usr/bin/env python3
"""Point grey 120.cash brief form at orange grok-cf so KV can publish tonight."""
from __future__ import annotations

import sys

OLD_FETCH = "fetch('/brief-submit.php', {"
NEW_FETCH = "fetch('https://tonight.agency002.com/brief-submit.php', {"


def patch(html: str) -> str:
    if NEW_FETCH in html:
        return html
    if html.count(OLD_FETCH) != 1:
        raise SystemExit(
            "fetch needle not unique (n=%s); skip 120.cash rewrite" % html.count(OLD_FETCH)
        )
    out = html.replace(OLD_FETCH, NEW_FETCH)
    if "keychain.gr/pay.html?plan=cash_120" not in out:
        raise SystemExit("120.cash patch would drop cash_120 pay; skip")
    return out


def main() -> None:
    html = sys.stdin.read()
    sys.stdout.write(patch(html))


if __name__ == "__main__":
    main()
