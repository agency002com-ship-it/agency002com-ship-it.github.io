#!/usr/bin/env python3
"""Rewrite only the €120 cash_120 card on eidotevil.com. Other prices stay."""
from __future__ import annotations

import sys

OLD_PAY = 'href="https://keychain.gr/pay.html?plan=cash_120"'
NEW_PAY = 'href="https://tonight.agency002.com/#book"'
OLD_BRIEF = 'href="https://120.cash/#brief"'
NEW_BRIEF = 'href="https://tonight.agency002.com/"'
OLD_HOME = 'href="https://120.cash/"'
NEW_HOME = 'href="https://tonight.agency002.com/"'
OLD_LINE = "After pay: short brief on 120.cash"
NEW_LINE = "After pay: same-night brief on tonight.agency002.com"
OLD_HINT = "Form stays on eidotevil.com. We answer within one working day."
NEW_HINT = "Form stays on eidotevil.com. A €120 page goes live the same night you pay."
OLD_FETCH = "fetch('/brief-submit.php', {"
NEW_FETCH = "fetch('https://tonight.agency002.com/brief-submit.php', {"
NEW_NAV = 'src="https://agency002com-ship-it.github.io/ftp-drop/nav-night.js?v=20260907n"'
OLD_NAVS = ('src="/assets/nav.js?v=2"', 'src="/assets/nav.js?v=4"')


def already_ok(html: str) -> bool:
    return NEW_PAY in html


def rewrite_fetch(html: str) -> str:
    if NEW_FETCH in html:
        return html
    if html.count(OLD_FETCH) != 1:
        return html
    return html.replace(OLD_FETCH, NEW_FETCH)


def rewrite_nav_src(html: str) -> str:
    if NEW_NAV in html:
        return html
    for old in OLD_NAVS:
        if html.count(old) == 1:
            return html.replace(old, NEW_NAV, 1)
    return html


def patch(html: str) -> str:
    out = html
    if not already_ok(out):
        if out.count(OLD_PAY) != 1 or out.count(OLD_BRIEF) != 1 or out.count(OLD_HOME) != 1:
            raise SystemExit(
                "needles not unique (pay=%s brief=%s home=%s); skip eidotevil rewrite"
                % (out.count(OLD_PAY), out.count(OLD_BRIEF), out.count(OLD_HOME))
            )
        out = out.replace(OLD_PAY, NEW_PAY).replace(OLD_BRIEF, NEW_BRIEF).replace(OLD_HOME, NEW_HOME)
        if NEW_PAY not in out or OLD_PAY in out:
            raise SystemExit("cash_120 href not moved; skip")
    out = out.replace(OLD_LINE, NEW_LINE).replace(OLD_HINT, NEW_HINT)
    out = rewrite_fetch(out)
    out = rewrite_nav_src(out)
    if "pay.html?plan=presence" not in out or "page_100" not in out or "printful" not in out.lower():
        raise SystemExit("patch would drop another product; skip")
    if not already_ok(out):
        raise SystemExit("cash_120 href not moved; skip")
    return out


def main() -> None:
    html = sys.stdin.read()
    sys.stdout.write(patch(html))


if __name__ == "__main__":
    main()
