(function () {
    var KEYCHAIN = 'https://keychain.gr/api/owner-checkout.php';
    var PAGES = 'https://agency002com-ship-it.github.io';
    var y = document.getElementById('y');
    if (y) y.textContent = String(new Date().getFullYear());
    if (/checkout=cancelled/.test(location.search)) {
      var c = document.getElementById('cancel-msg');
      if (c) c.hidden = false;
    }
    var form = document.getElementById('brief-form');
    if (!form) return;
    var msg = document.getElementById('brief-msg');
    var cardBtn = document.getElementById('pay-card');
    var ppBtn = document.getElementById('pay-pp');
    function payload(rail) {
      return {
        businessName: (document.getElementById('biz').value || '').trim(),
        phone: (document.getElementById('phone').value || '').trim(),
        email: (document.getElementById('email').value || '').trim(),
        city: (document.getElementById('city').value || '').trim(),
        whatYouDo: (document.getElementById('what').value || '').trim(),
        rail: rail
      };
    }
    function encodeBrief(b) {
      var json = JSON.stringify({
        v: 1,
        n: b.businessName,
        w: b.whatYouDo,
        p: b.phone,
        e: b.email,
        c: b.city || 'Greece'
      });
      return btoa(unescape(encodeURIComponent(json)))
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=+$/g, '');
    }
    function postJson(url, body) {
      var ctrl = typeof AbortController === 'function' ? new AbortController() : null;
      var timer = ctrl ? setTimeout(function () { ctrl.abort(); }, 8000) : null;
      return fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
        signal: ctrl ? ctrl.signal : undefined
      }).then(function (r) {
        return r.json().then(function (j) { return { ok: r.ok, j: j }; }).catch(function () {
          return { ok: r.ok, j: {} };
        });
      }).finally(function () { if (timer) clearTimeout(timer); });
    }
    function fail(text) {
      cardBtn.disabled = false;
      ppBtn.disabled = false;
      msg.className = 'msg err';
      msg.textContent = text;
    }
    function keychainPay(body, rail) {
      var enc = encodeBrief(body);
      var desc = '120.cash night page — ' + body.businessName;
      if (rail === 'paypal') {
        return postJson(KEYCHAIN, {
          action: 'create',
          amount: 120,
          currency: 'EUR',
          description: desc,
          return_url: PAGES + '/thanks.html?rail=paypal&p=' + enc,
          cancel_url: location.origin + '/?checkout=cancelled'
        }).then(function (res) {
          if (res.j && res.j.approve_url) return res.j.approve_url;
          throw new Error((res.j && res.j.error) || 'PayPal did not open.');
        });
      }
      return postJson(KEYCHAIN, {
        action: 'stripe_checkout',
        plan: 'cash_120',
        description: desc,
        success_url: PAGES + '/thanks.html?session_id={CHECKOUT_SESSION_ID}&p=' + enc,
        cancel_url: location.origin + '/?checkout=cancelled'
      }).then(function (res) {
        var url = res.j && res.j.url ? String(res.j.url) : '';
        if (url.indexOf('https://checkout.stripe.com/') === 0) return url;
        throw new Error((res.j && res.j.error) || 'Card till did not open.');
      });
    }
    function pay(rail) {
      var body = payload(rail);
      msg.hidden = false;
      msg.className = 'msg';
      if (!body.businessName || !body.phone || !body.email || !body.whatYouDo) {
        msg.className = 'msg err';
        msg.textContent = 'Name, what you do, phone, and email are required.';
        return;
      }
      msg.textContent = 'Opening secure checkout…';
      cardBtn.disabled = true;
      ppBtn.disabled = true;
      postJson('/desk-checkout.php', body).then(function (res) {
        if (res.j && res.j.url) {
          location.href = res.j.url;
          return;
        }
        return keychainPay(body, rail).then(function (url) { location.href = url; });
      }).catch(function () {
        return keychainPay(body, rail).then(function (url) { location.href = url; });
      }).catch(function (err) {
        fail((err && err.message) ? err.message : 'Could not open checkout.');
      });
    }
    form.addEventListener('submit', function (e) {
      e.preventDefault();
      pay('stripe');
    });
    ppBtn.addEventListener('click', function () { pay('paypal'); });
  })();
