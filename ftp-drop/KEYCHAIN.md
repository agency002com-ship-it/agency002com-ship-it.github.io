# Laptop Grok — one line on keychain.gr

Live 120.cash “Pay €120” already opens `https://keychain.gr/pay.html?plan=cash_120`.
After pay, live keychain still sends the buyer to `https://120.cash/#brief` (“working day”).
That is the indexed money door. Do not invent a new funnel. Do not send cold mail.

On the keychain.gr document root, in `pay.html`, find:

```
a('https://120.cash/#brief', '120.cash');
```

inside the `kind === 'cash_120'` branch. Replace that branch with:

```
      } else if (kind === 'cash_120') {
        t('Next step: open ');
        var sid = (new URLSearchParams(location.search)).get('session_id') || '';
        var paid = 'https://agency002com-ship-it.github.io/paid.html';
        if (sid) paid += '?session_id=' + encodeURIComponent(sid);
        a(paid, 'the night desk');
        t(' and leave the brief. The page goes live the same night. Do not pay again.');
      }
```

Do not touch other plans. Do not touch PayPal passwords.

The night desk `paid.html` publishes the live page after a real Stripe session id or a captured PayPal order. No second charge.

Also still: overwrite 120.cash `index.html` with `120-index.html` when you can. That is brief-then-pay on the indexed domain.
