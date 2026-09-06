#!/usr/bin/env python3
"""Rewrite only the €120 cash_120 cards on sebarv.com. Other prices stay."""
from __future__ import annotations

import sys

OLD_PAY = 'href="https://keychain.gr/pay.html?plan=cash_120"'
NEW_PAY = 'href="https://tonight.agency002.com/#book"'
OLD_HOME = 'href="https://120.cash/"'
NEW_HOME = 'href="https://tonight.agency002.com/"'


def already_ok(html: str) -> bool:
    return "tonight.agency002.com/#book" in html


def patch(html: str) -> str:
    if already_ok(html):
        raise SystemExit("sebarv.com already points cash_120 at tonight.agency002.com")
    if html.count(OLD_PAY) < 1 or html.count(OLD_HOME) != 1:
        raise SystemExit(
            "needles not unique (pay=%s home=%s); skip sebarv rewrite"
            % (html.count(OLD_PAY), html.count(OLD_HOME))
        )
    out = html.replace(OLD_PAY, NEW_PAY).replace(OLD_HOME, NEW_HOME)
    if "pay.html?plan=presence" not in out or "printful" not in out.lower():
        raise SystemExit("patch would drop another product; skip")
    if "pay.html?plan=sitepilot" not in out:
        raise SystemExit("patch would drop SitePilot; skip")
    if NEW_PAY not in out or OLD_PAY in out:
        raise SystemExit("cash_120 href not moved; skip")
    return out


def main() -> None:
    html = sys.stdin.read()
    sys.stdout.write(patch(html))


if __name__ == "__main__":
    main()
