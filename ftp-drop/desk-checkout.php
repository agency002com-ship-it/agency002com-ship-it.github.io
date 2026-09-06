<?php
declare(strict_types=1);
require __DIR__ . '/desk-lib.php';

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
$doors = [
    'https://120.cash',
    'https://www.120.cash',
    'https://agency002com-ship-it.github.io',
];
if (in_array($origin, $doors, true)) {
    header('Access-Control-Allow-Origin: ' . $origin);
    header('Access-Control-Allow-Headers: Content-Type');
    header('Access-Control-Allow-Methods: POST, OPTIONS');
    header('Vary: Origin');
}
if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    desk_fail(405, 'POST a brief.');
}

$cfg = desk_cfg();
$in = json_decode((string) file_get_contents('php://input'), true);
if (!is_array($in)) desk_fail(400, 'Send JSON.');

$biz = trim((string) ($in['businessName'] ?? $in['biz'] ?? ''));
$what = trim((string) ($in['whatYouDo'] ?? $in['what'] ?? $in['message'] ?? ''));
$phone = trim((string) ($in['phone'] ?? ''));
$email = strtolower(trim((string) ($in['email'] ?? '')));
$city = trim((string) ($in['city'] ?? 'Greece'));
$rail = (($in['rail'] ?? '') === 'paypal') ? 'paypal' : 'stripe';

if ($biz === '' || $what === '' || $phone === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    desk_fail(400, 'Name, what you do, phone, and a valid email are required.');
}
$biz = mb_substr($biz, 0, 80);
$what = mb_substr($what, 0, 450);
$phone = mb_substr($phone, 0, 40);
$email = mb_substr($email, 0, 120);
$city = mb_substr($city === '' ? 'Greece' : $city, 0, 80);

$page = desk_page_token();
$origin = 'https://120.cash';
$host = $_SERVER['HTTP_HOST'] ?? '120.cash';
$https = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') || (($_SERVER['SERVER_PORT'] ?? '') === '443');
$origin = ($https ? 'https' : 'http') . '://' . $host;

$ticket = desk_mint($cfg, [
    'v' => 1,
    'rail' => $rail,
    'page' => $page,
    'brief' => [
        'businessName' => $biz,
        'whatYouDo' => $what,
        'phone' => $phone,
        'email' => $email,
        'city' => $city,
        'language' => 'en',
    ],
    'exp' => time() + 60 * 60 * 48,
]);

$cancel = $origin . '/?checkout=cancelled';
$desc = 'Shift 002 night page ' . $page . ' — ' . $biz;

if ($rail === 'paypal') {
    $res = desk_keychain($cfg, [
        'action' => 'create',
        'amount' => 120,
        'currency' => 'EUR',
        'description' => $desc,
        'return_url' => $origin . '/thanks.php?t=' . rawurlencode($ticket) . '&rail=paypal',
        'cancel_url' => $cancel,
    ]);
    $url = (string) ($res['approve_url'] ?? '');
    if ($url === '') desk_fail(502, 'PayPal did not open.');
    echo json_encode(['url' => $url, 'rail' => 'paypal']);
    exit;
}

$res = desk_keychain($cfg, [
    'action' => 'stripe_checkout',
    'plan' => 'cash_120',
    'description' => $desc,
    'success_url' => $origin . '/thanks.php?t=' . rawurlencode($ticket) . '&session_id={CHECKOUT_SESSION_ID}',
    'cancel_url' => $cancel,
]);
$url = (string) ($res['url'] ?? '');
if (!str_starts_with($url, 'https://checkout.stripe.com/')) {
    desk_fail(502, 'Card till did not open.');
}
echo json_encode(['url' => $url, 'rail' => 'keychain-stripe']);
