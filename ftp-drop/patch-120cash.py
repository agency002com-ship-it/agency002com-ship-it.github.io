#!/usr/bin/env python3
"""Point grey 120.cash brief form at orange grok-cf so KV can publish tonight."""
from __future__ import annotations

import sys

OLD_FETCH = "fetch('/brief-submit.php', {"
NEW_FETCH = "fetch('https://tonight.agency002.com/brief-submit.php', {"
NEW_NAV = 'src="https://agency002com-ship-it.github.io/ftp-drop/nav-night.js?v=20260907n"'
OLD_NAVS = ('src="/assets/nav.js?v=2"', 'src="/assets/nav.js?v=4"')


def rewrite_nav_src(html: str) -> str:
    if NEW_NAV in html:
        return html
    for old in OLD_NAVS:
        if html.count(old) == 1:
            return html.replace(old, NEW_NAV, 1)
    return html


def patch(html: str) -> str:
    out = html
    if NEW_FETCH not in out:
        if out.count(OLD_FETCH) != 1:
            raise SystemExit(
                "fetch needle not unique (n=%s); skip 120.cash rewrite" % out.count(OLD_FETCH)
            )
        out = out.replace(OLD_FETCH, NEW_FETCH)
    out = rewrite_nav_src(out)
    if "keychain.gr/pay.html?plan=cash_120" not in out:
        raise SystemExit("120.cash patch would drop cash_120 pay; skip")
    return out


def main() -> None:
    html = sys.stdin.read()
    sys.stdout.write(patch(html))


if __name__ == "__main__":
    main()
