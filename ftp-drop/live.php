<?php
declare(strict_types=1);
require __DIR__ . '/desk-lib.php';

$page = (string) ($_GET['p'] ?? '');
$job = desk_load_job($page);
if (!$job) {
    http_response_code(404);
    echo '<!doctype html><meta charset="utf-8"><title>Nothing here</title><p>Nothing here. <a href="/">Back to 120.cash</a></p>';
    exit;
}

$name = desk_h((string) $job['businessName']);
$what = desk_h((string) $job['whatYouDo']);
$city = desk_h((string) ($job['city'] ?? ''));
$phone = (string) $job['phone'];
$tel = preg_replace('/[^\d+]/', '', $phone) ?? '';
$wa = ltrim($tel, '+');
$phoneH = desk_h($phone);
?><!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title><?= $name ?> · 120.cash</title>
  <style>
    body { margin:0; min-height:100dvh; background:#f2ead8; color:#1b140c;
      font-family: Figtree, system-ui, sans-serif; }
    main { max-width: 36rem; min-height:100dvh; margin:0 auto; padding:2.5rem 1.5rem;
      display:flex; flex-direction:column; justify-content:space-between; }
    .city { letter-spacing:.22em; text-transform:uppercase; font-size:.8rem; color:#7a5a32; }
    h1 { font-family: Fraunces, Georgia, serif; font-size: clamp(3rem, 12vw, 6rem);
      line-height:.9; font-weight:600; margin:3rem 0 1.5rem; }
    .what { font-size:1.15rem; line-height:1.6; max-width:28rem; }
    a.call, a.wa { display:flex; height:3.5rem; align-items:center; justify-content:center;
      border-radius:999px; text-decoration:none; font-size:1rem; margin-top:.75rem; }
    a.call { background:#1b140c; color:#f2ead8; }
    a.wa { border:1px solid rgba(27,20,12,.2); color:#1b140c; }
    .foot { text-align:center; font-size:.75rem; color:#7a5a32; margin-top:1.5rem; }
  </style>
</head>
<body>
  <main>
    <p class="city"><?= $city ?></p>
    <div>
      <h1><?= $name ?></h1>
      <p class="what"><?= $what ?></p>
    </div>
    <div>
      <a class="call" href="tel:<?= desk_h($tel) ?>">Call <?= $phoneH ?></a>
      <a class="wa" href="https://wa.me/<?= desk_h($wa) ?>">WhatsApp</a>
      <p class="foot">Built in the Athens night. Ready when you woke up.</p>
    </div>
  </main>
</body>
</html>
