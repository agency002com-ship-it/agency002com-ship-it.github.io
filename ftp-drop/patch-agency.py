#!/usr/bin/env python3
"""Rewrite only the €120 card on agency002.com. Presence / Printful / DBYW stay."""
from __future__ import annotations

import sys

OLD_PAY = 'href="https://keychain.gr/pay.html?plan=cash_120"'
NEW_PAY = 'href="https://cash.agency002.com/#book"'
OLD_BRIEF = 'href="https://120.cash/#brief"'
NEW_BRIEF = 'href="https://agency002com-ship-it.github.io/paid.html"'
OLD_HOME = 'href="https://120.cash/"'
NEW_HOME = 'href="https://cash.agency002.com/"'


def already_ok(html: str) -> bool:
    return "cash.agency002.com/#book" in html or "now.agency002.com/#book" in html


def patch(html: str) -> str:
    if already_ok(html):
        raise SystemExit("agency002.com already points cash_120 at an orange night till")
    if html.count(OLD_PAY) != 1 or html.count(OLD_BRIEF) != 1 or html.count(OLD_HOME) != 1:
        raise SystemExit(
            "needles not unique (pay=%s brief=%s home=%s); skip brand rewrite"
            % (html.count(OLD_PAY), html.count(OLD_BRIEF), html.count(OLD_HOME))
        )
    out = html.replace(OLD_PAY, NEW_PAY).replace(OLD_BRIEF, NEW_BRIEF).replace(OLD_HOME, NEW_HOME)
    if "pay.html?plan=presence" not in out or "eidotevil.com" not in out or "printful" not in out.lower():
        raise SystemExit("patch would drop another product; skip")
    if NEW_PAY not in out:
        raise SystemExit("night till missing after patch; skip")
    if OLD_PAY in out:
        raise SystemExit("old cash_120 href still present; skip")
    return out


def main() -> None:
    html = sys.stdin.read()
    sys.stdout.write(patch(html))


if __name__ == "__main__":
    main()
