#!/usr/bin/env python3
"""Rewrite only the €120 card on agency002.com. Presence / Printful / DBYW stay."""
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


def already_ok(html: str) -> bool:
    return NEW_PAY in html or "cash.agency002.com/#book" in html


def patch(html: str) -> str:
    out = html
    if not already_ok(out):
        if out.count(OLD_PAY) != 1 or out.count(OLD_BRIEF) != 1 or out.count(OLD_HOME) != 1:
            raise SystemExit(
                "needles not unique (pay=%s brief=%s home=%s); skip brand rewrite"
                % (out.count(OLD_PAY), out.count(OLD_BRIEF), out.count(OLD_HOME))
            )
        out = out.replace(OLD_PAY, NEW_PAY).replace(OLD_BRIEF, NEW_BRIEF).replace(OLD_HOME, NEW_HOME)
        if NEW_PAY not in out or OLD_PAY in out:
            raise SystemExit("cash_120 href not moved; skip")
    out = out.replace(OLD_LINE, NEW_LINE).replace(OLD_HINT, NEW_HINT)
    if "pay.html?plan=presence" not in out or "eidotevil.com" not in out or "printful" not in out.lower():
        raise SystemExit("patch would drop another product; skip")
    if not already_ok(out):
        raise SystemExit("night till missing after patch; skip")
    return out


def main() -> None:
    html = sys.stdin.read()
    sys.stdout.write(patch(html))


if __name__ == "__main__":
    main()
