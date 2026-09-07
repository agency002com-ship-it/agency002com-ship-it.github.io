#!/usr/bin/env python3
"""Rewrite the €120 door on agency002.com. Live HTML may have no cash_120 card
(only a unique 120.cash home link). Presence / Printful / page_100 stay."""
from __future__ import annotations

import sys

OLD_PAY = 'href="https://keychain.gr/pay.html?plan=cash_120"'
NEW_PAY = 'href="https://tonight.agency002.com/#book"'
OLD_BRIEF = 'href="https://120.cash/#brief"'
NEW_BRIEF = 'href="https://tonight.agency002.com/"'
OLD_HOME = 'href="https://120.cash/"'
NEW_HOME = 'href="https://tonight.agency002.com/"'
OLD_LINE = "After pay: brief on 120.cash"
NEW_LINE = "After pay: same-night brief on tonight.agency002.com"
OLD_HINT = "Form stays on agency002.com. We answer within one working day."
NEW_HINT = "Form stays on agency002.com. A €120 page goes live the same night you pay."
OLD_FETCH = "fetch('/brief-submit.php', {"
NEW_FETCH = "fetch('https://tonight.agency002.com/brief-submit.php', {"
OLD_JS = "Got it. We will reply within one working day."
NEW_JS = "Got it. Live tonight after this brief."
NEW_NAV = 'src="https://agency002com-ship-it.github.io/ftp-drop/nav-night.js?v=20260907q"'
OLD_NAVS = ('src="/assets/nav.js?v=2"', 'src="/assets/nav.js?v=4"')


def already_ok(html: str) -> bool:
    return "tonight.agency002.com" in html or "cash.agency002.com/#book" in html


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
        n_pay, n_brief, n_home = out.count(OLD_PAY), out.count(OLD_BRIEF), out.count(OLD_HOME)
        if n_pay not in (0, 1) or n_brief not in (0, 1) or n_home not in (0, 1):
            raise SystemExit(
                "needles not unique (pay=%s brief=%s home=%s); skip brand rewrite"
                % (n_pay, n_brief, n_home)
            )
        if n_pay == 0 and n_brief == 0 and n_home == 0:
            raise SystemExit("no 120.cash or cash_120 needle; skip")
        if n_pay == 1:
            out = out.replace(OLD_PAY, NEW_PAY)
        if n_brief == 1:
            out = out.replace(OLD_BRIEF, NEW_BRIEF)
        if n_home == 1:
            out = out.replace(OLD_HOME, NEW_HOME)
        if OLD_PAY in out or (n_home == 1 and OLD_HOME in out):
            raise SystemExit("cash_120 / 120.cash href not moved; skip")
    out = out.replace(OLD_LINE, NEW_LINE).replace(OLD_HINT, NEW_HINT)
    if out.count(OLD_JS) == 1:
        out = out.replace(OLD_JS, NEW_JS)
    out = rewrite_fetch(out)
    out = rewrite_nav_src(out)
    if (
        "pay.html?plan=presence" not in out
        or "eidotevil.com" not in out
        or "printful" not in out.lower()
        or "page_100" not in out
    ):
        raise SystemExit("patch would drop another product; skip")
    if not already_ok(out):
        raise SystemExit("night till missing after patch; skip")
    return out


def main() -> None:
    html = sys.stdin.read()
    sys.stdout.write(patch(html))


if __name__ == "__main__":
    main()
