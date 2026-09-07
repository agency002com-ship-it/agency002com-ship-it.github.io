#!/usr/bin/env python3
"""Rewrite only cash_120 bounce on keychain.gr/pay.html. Other plans stay."""
from __future__ import annotations

import sys

PAID = "https://agency002com-ship-it.github.io/paid.html"

OLD_LINK = "a('https://120.cash/#brief', '120.cash');"
NEW_LINK = f"""        var sid = (new URLSearchParams(location.search)).get('session_id') || '';
        var tok = (new URLSearchParams(location.search)).get('token') || (new URLSearchParams(location.search)).get('order_id') || '';
        var paid = '{PAID}';
        if (sid) paid += '?session_id=' + encodeURIComponent(sid);
        else if (tok) paid += '?token=' + encodeURIComponent(tok);
        a(paid, 'the night desk');"""

OLD_BOUNCE = """        return false;
      }
      return false;
    }

    /* ---------------- return from PayPal / Stripe ---------------- */"""
NEW_BOUNCE = f"""        return false;
      }}
      if (kind === 'cash_120') {{
        var paid = '{PAID}';
        if (sid && /^cs_(live|test)_/.test(sid)) {{
          location.href = paid + '?session_id=' + encodeURIComponent(sid);
          return true;
        }}
        if (token) {{
          location.href = paid + '?token=' + encodeURIComponent(token);
          return true;
        }}
        return false;
      }}
      return false;
    }}

    /* ---------------- return from PayPal / Stripe ---------------- */"""

OLD_DONE = """      showProductNextStep(); // product-aware next step as soon as thank-you shows
      var oid = q.get('token') || q.get('order_id') || sessionStorage.getItem('a2_pp_order') || '';"""
NEW_DONE = """      showProductNextStep(); // product-aware next step as soon as thank-you shows
      if (productKind() === 'cash_120') {
        var sidNow = q.get('session_id') || q.get('checkout_session_id') || '';
        var tokNow = q.get('token') || q.get('order_id') || sessionStorage.getItem('a2_pp_order') || '';
        if (doorBounce(sidNow, tokNow)) return;
      }
      var oid = q.get('token') || q.get('order_id') || sessionStorage.getItem('a2_pp_order') || '';"""

OLD_SESSION = """      if (dKeep) base += '&desc=' + encodeURIComponent(dKeep);
      return base;"""
NEW_SESSION = """      if (dKeep) base += '&desc=' + encodeURIComponent(dKeep);
      if (base.indexOf('{CHECKOUT_SESSION_ID}') === -1) base += '&session_id={CHECKOUT_SESSION_ID}';
      return base;"""


def patch(html: str) -> str:
    out = html
    if html.count(OLD_LINK) == 1 and html.count(OLD_BOUNCE) == 1 and html.count(OLD_DONE) == 1:
        out = out.replace(OLD_LINK, NEW_LINK).replace(OLD_BOUNCE, NEW_BOUNCE).replace(OLD_DONE, NEW_DONE)
    if out.count(OLD_SESSION) == 1 and "{CHECKOUT_SESSION_ID}" not in out:
        out = out.replace(OLD_SESSION, NEW_SESSION)
    if out == html:
        raise SystemExit("needles not unique; skip keychain rewrite")
    if "intifrog.com" not in out or "msking.shop" not in out or "muslimpowergroup.com" not in out:
        raise SystemExit("patch would drop another plan; skip")
    if PAID not in out:
        raise SystemExit("paid.html missing after patch; skip")
    if "{CHECKOUT_SESSION_ID}" not in out:
        raise SystemExit("session_id missing after patch; skip")
    if OLD_LINK in out:
        raise SystemExit("old bounce still present; skip")
    return out


def main() -> None:
    html = sys.stdin.read()
    sys.stdout.write(patch(html))


if __name__ == "__main__":
    main()
