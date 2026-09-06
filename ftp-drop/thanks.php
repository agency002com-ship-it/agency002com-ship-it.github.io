<?php
declare(strict_types=1);
require __DIR__ . '/desk-lib.php';

$cfg = desk_cfg();
$token = (string) ($_GET['t'] ?? '');
$payload = desk_open($cfg, $token);
if (!$payload) {
    http_response_code(400);
    echo '<!doctype html><meta charset="utf-8"><title>Payment not confirmed</title><p>Payment not confirmed. If you just paid, use the return link again.</p>';
    exit;
}

$rail = (string) ($payload['rail'] ?? 'stripe');
if ($rail === 'paypal') {
    $order = (string) ($_GET['order_id'] ?? $_GET['token'] ?? '');
    $cap = desk_keychain($cfg, ['action' => 'capture', 'order_id' => $order]);
    if (empty($cap['ok'])) {
        http_response_code(402);
        echo '<!doctype html><meta charset="utf-8"><title>Payment not confirmed</title><p>PayPal has not captured this yet. Nothing was published.</p>';
        exit;
    }
}

$brief = $payload['brief'] ?? [];
$page = (string) ($payload['page'] ?? '');
$job = [
    'page' => $page,
    'businessName' => (string) ($brief['businessName'] ?? ''),
    'whatYouDo' => (string) ($brief['whatYouDo'] ?? ''),
    'phone' => (string) ($brief['phone'] ?? ''),
    'email' => (string) ($brief['email'] ?? ''),
    'city' => (string) ($brief['city'] ?? 'Greece'),
    'paidAt' => gmdate('c'),
    'rail' => $rail,
];
desk_save_job($job);

$live = '/live.php?p=' . rawurlencode($page);
$to = (string) ($brief['email'] ?? '');
if (filter_var($to, FILTER_VALIDATE_EMAIL)) {
    $host = $_SERVER['HTTP_HOST'] ?? '120.cash';
    $https = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') || (($_SERVER['SERVER_PORT'] ?? '') === '443');
    $abs = ($https ? 'https' : 'http') . '://' . $host . $live;
    $headers = 'From: ' . ($cfg['mail_from'] ?? 'desk@120.cash') . "\r\nContent-Type: text/plain; charset=utf-8";
    if (!empty($cfg['mail_bcc'])) {
        $headers .= "\r\nBcc: " . $cfg['mail_bcc'];
    }
    @mail($to, 'Your page is live', "It is live:\n$abs\n", $headers);
}

header('Location: ' . $live, true, 303);
exit;
