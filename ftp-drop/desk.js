(function () {
  var KEYCHAIN = 'https://cash.120.cash/api/owner-checkout.php';
  var PAGES = 'https://agency002com-ship-it.github.io';
  var y = document.getElementById('y');
  if (y) y.textContent = String(new Date().getFullYear());

  var q = new URLSearchParams(location.search);
  var sid = q.get('session_id') || q.get('checkout_session_id') || '';
  var tok = q.get('token') || q.get('order_id') || '';
  if (/^#brief/i.test(location.hash || '') && (sid || tok)) {
    var paid = PAGES + '/paid.html';
    if (sid) paid += '?session_id=' + encodeURIComponent(sid);
    else paid += '?token=' + encodeURIComponent(tok);
    location.replace(paid);
    return;
  }

  if (/checkout=cancelled/.test(location.search)) {
    var c = document.getElementById('cancel-msg');
    if (c) c.hidden = false;
  }

  function pageLang() {
    var el = document.getElementById('lang');
    if (el && el.value === 'el') return 'el';
    if (document.documentElement.lang === 'el') return 'el';
    return 'en';
  }

  function encodeBrief(b) {
    var json = JSON.stringify({
      v: 1,
      n: b.businessName,
      w: b.whatYouDo,
      p: b.phone,
      e: b.email,
      c: b.city || (pageLang() === 'el' ? '\u0395\u03bb\u03bb\u03ac\u03b4\u03b1' : 'Greece'),
      l: pageLang()
    });
    return btoa(unescape(encodeURIComponent(json)))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/g, '');
  }

  function postJson(url, body, ms) {
    var ctrl = typeof AbortController === 'function' ? new AbortController() : null;
    var timer = ctrl ? setTimeout(function () { ctrl.abort(); }, ms || 15000) : null;
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

  var form = document.getElementById('brief-form');
  var msg = document.getElementById('brief-msg');
  var cardBtn = document.getElementById('pay-card');
  var ppBtn = document.getElementById('pay-pp');

  function payload() {
    return {
      businessName: (document.getElementById('biz').value || '').trim(),
      phone: (document.getElementById('phone').value || '').trim(),
      email: (document.getElementById('email').value || '').trim(),
      city: (document.getElementById('city').value || '').trim(),
      whatYouDo: (document.getElementById('what').value || '').trim(),
      language: pageLang()
    };
  }

  function fail(text) {
    if (cardBtn) cardBtn.disabled = false;
    if (ppBtn) ppBtn.disabled = false;
    if (!msg) return;
    msg.hidden = false;
    msg.className = 'msg err';
    msg.textContent = text;
  }

  function keychainPay(body, rail) {
    var enc = encodeBrief(body);
    var desc = '120.cash night page \u2014 ' + body.businessName;
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
    var body = payload();
    if (msg) {
      msg.hidden = false;
      msg.className = 'msg';
    }
    if (!body.businessName || !body.email || !body.whatYouDo) {
      fail(pageLang() === 'el'
        ? '\u0398\u03ad\u03bb\u03c9 \u03cc\u03bd\u03bf\u03bc\u03b1, \u03c4\u03b9 \u03ba\u03ac\u03bd\u03b5\u03b9\u03c2, \u03ba\u03b1\u03b9 \u03ad\u03bd\u03b1 \u03c3\u03c9\u03c3\u03c4\u03cc email.'
        : 'Name, what you do, and email are required.');
      return;
    }
    if (msg) msg.textContent = 'Opening secure checkout\u2026';
    if (cardBtn) cardBtn.disabled = true;
    if (ppBtn) ppBtn.disabled = true;
    try {
      sessionStorage.setItem('shift002-brief', JSON.stringify(body));
    } catch (e) {}
    function go() {
      return keychainPay(body, rail).then(function (url) { location.href = url; });
    }
    var local = /(^|\.)120\.cash$/.test(location.hostname)
      ? postJson('/desk-checkout.php', body, 2500).then(function (res) {
          if (res.j && res.j.url) {
            location.href = res.j.url;
            return;
          }
          return go();
        }).catch(go)
      : go();
    local.catch(function (err) {
      fail((err && err.message) ? err.message : 'Could not open checkout.');
    });
  }

  if (form && cardBtn && ppBtn) {
    form.addEventListener('submit', function (e) {
      e.preventDefault();
      pay('stripe');
    });
    ppBtn.addEventListener('click', function () { pay('paypal'); });
  }

  var briefSec = document.getElementById('brief');
  function showPaid() {
    if (briefSec) briefSec.hidden = false;
  }
  if (briefSec && !/^#brief/i.test(location.hash || '')) briefSec.hidden = true;
  document.querySelectorAll('a[href="#brief"]').forEach(function (a) {
    a.addEventListener('click', function () { showPaid(); });
  });
  window.addEventListener('hashchange', function () {
    if (/^#brief/i.test(location.hash || '')) showPaid();
  });

  document.addEventListener('click', function (e) {
    var a = e.target && e.target.closest ? e.target.closest('a') : null;
    if (!a || !a.href) return;
    if (a.href.indexOf('pay.120.cash/pay.html') === -1) return;
    if (a.href.indexOf('p=') !== -1) return;
    if (!document.getElementById('biz')) return;
    var body = payload();
    if (!body.businessName || !body.email || !body.whatYouDo) return;
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(body.email)) return;
    e.preventDefault();
    try { sessionStorage.setItem('shift002-brief', JSON.stringify(body)); } catch (err) {}
    location.href = 'https://pay.120.cash/pay.html?plan=cash_120&p=' + encodeBrief(body);
  });

  // Live keychain still sends cash_120 to https://120.cash/#brief with no session id.
  // This form is that return: no second charge, page live on github.io.
  var paidForm = document.getElementById('paid-form');
  if (paidForm) {
    paidForm.addEventListener('submit', function (e) {
      e.preventDefault();
      var b = {
        businessName: (document.getElementById('paid-biz').value || '').trim(),
        phone: (document.getElementById('paid-phone').value || '').trim(),
        email: (document.getElementById('paid-email').value || '').trim(),
        city: (document.getElementById('paid-city').value || '').trim() || (pageLang() === 'el' ? '\u0395\u03bb\u03bb\u03ac\u03b4\u03b1' : 'Greece'),
        whatYouDo: (document.getElementById('paid-what').value || '').trim()
      };
      var pmsg = document.getElementById('paid-msg');
      if (!b.businessName || !b.email || !b.whatYouDo) {
        if (pmsg) {
          pmsg.hidden = false;
          pmsg.className = 'msg err';
          pmsg.textContent = pageLang() === 'el'
            ? '\u0398\u03ad\u03bb\u03c9 \u03cc\u03bd\u03bf\u03bc\u03b1, \u03c4\u03b9 \u03ba\u03ac\u03bd\u03b5\u03b9\u03c2, \u03ba\u03b1\u03b9 \u03ad\u03bd\u03b1 \u03c3\u03c9\u03c3\u03c4\u03cc email.'
            : 'Name, what you do, and email are required.';
        }
        return;
      }
      if (!/@(example\.com|example\.gr|agency002\.invalid)$/i.test(b.email) &&
          !/\b(probe|not a customer|do not build)\b/i.test(b.businessName + ' ' + b.whatYouDo)) {
        try {
          var message = b.whatYouDo;
          if (b.city) message += '\nCity: ' + b.city;
          var pay = sid || tok;
          if (pay) message += '\nPayment id: ' + pay;
          fetch('https://tonight.agency002.com/brief-submit.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              email: b.email,
              biz: b.businessName,
              phone: b.phone || '',
              message: message,
              city: b.city,
              language: pageLang(),
              pkg: 'cash_120',
              session_id: pay,
              paymentId: pay
            })
          }).catch(function () {});
        } catch (err) {}
        fetch('https://cash.120.cash/api/publish', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            businessName: b.businessName,
            whatYouDo: b.whatYouDo,
            phone: b.phone,
            email: b.email,
            city: b.city,
            language: pageLang(),
            pkg: 'cash_120',
            session_id: pay,
            paymentId: pay
          })
        }).then(function (r) {
          return r.json().catch(function () { return {}; });
        }).then(function (j) {
          if (j && j.url && /^https:\/\/cash\.120\.cash\/p\//.test(j.url)) {
            location.replace(j.url);
            return;
          }
          location.replace(PAGES + '/live.html#' + encodeBrief(b));
        }).catch(function () {
          location.replace(PAGES + '/live.html#' + encodeBrief(b));
        });
        return;
      }
      location.replace(PAGES + '/live.html#' + encodeBrief(b));
    });
  }
})();
