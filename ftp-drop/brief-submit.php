<?php
declare(strict_types=1);

/**
 * 120.cash money-door briefs. Fileman this onto 120.cash docroots only.
 * Do not copy onto eidotevil / agency002 / sebarv (those forms are not cash_120).
 * POST JSON { email, biz, phone, message } → KV https://cash.120.cash/p/{slug}
 * plus NEW 120.cash BRIEF mail. GET stays 405 with kv:true so HubWatch can see it.
 */
header('Cache-Control: no-store');
header('X-Shift002: brief-kv');

$reqOrigin = (string) ($_SERVER['HTTP_ORIGIN'] ?? '');
$allow = [
    'https://120.cash',
    'https://www.120.cash',
    'https://tonight.agency002.com',
    'https://cash.120.cash',
    'https://cash.keychain.gr',
    'https://agency002com-ship-it.github.io',
    'https://eidotevil.com',
    'https://www.eidotevil.com',
    'https://agency002.com',
    'https://www.agency002.com',
    'https://sebarv.com',
    'https://www.sebarv.com',
];
if (in_array($reqOrigin, $allow, true)) {
    header('Access-Control-Allow-Origin: ' . $reqOrigin);
    header('Vary: Origin');
    header('Access-Control-Allow-Methods: POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type');
}

header('Content-Type: application/json; charset=utf-8');

if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed', 'kv' => true], JSON_UNESCAPED_UNICODE);
    exit;
}

function brief_out(int $code, array $body): never {
    http_response_code($code);
    echo json_encode($body, JSON_UNESCAPED_UNICODE);
    exit;
}

$raw = (string) file_get_contents('php://input');
$in = json_decode($raw, true);
if (!is_array($in)) {
    $in = $_POST;
}
if (!is_array($in)) {
    $in = [];
}

$email = strtolower(trim((string) ($in['email'] ?? $in['client'] ?? $in['contact_email'] ?? '')));
$biz = trim((string) ($in['biz'] ?? $in['businessName'] ?? $in['name'] ?? ''));
$phone = trim((string) ($in['phone'] ?? ''));
$message = trim((string) ($in['message'] ?? $in['whatYouDo'] ?? $in['what'] ?? ''));
$pkg = trim((string) ($in['pkg'] ?? $in['plan'] ?? $in['package'] ?? ''));
$city = trim((string) ($in['city'] ?? ''));
if ($city === '') {
    $city = 'Greece';
}
$language = strtolower(trim((string) ($in['language'] ?? '')));
if ($language !== 'el' && $language !== 'en') {
    $language = preg_match('/\p{Greek}/u', $biz . ' ' . $message) ? 'el' : 'en';
}
$paymentId = trim((string) ($in['paymentId'] ?? $in['payment_id'] ?? $in['session_id'] ?? $in['sessionId'] ?? ''));

$host = strtolower((string) ($_SERVER['HTTP_HOST'] ?? ''));
$host = preg_replace('/:\d+$/', '', $host) ?? $host;
$isDoorHost = (bool) preg_match('/(^|\.)(120\.cash|tonight\.agency002\.com)$/', $host);
$isCashPkg = (bool) preg_match('/cash_120|EUR 120 live page/i', $pkg);
if (!$isDoorHost && !$isCashPkg) {
    brief_out(400, ['error' => 'Not the 120.cash money door.']);
}

if ($email === '' || $biz === '' || $message === '') {
    brief_out(400, ['error' => 'Email, name, and what you do are required.']);
}
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    brief_out(400, ['error' => 'That email is not valid.']);
}

$blob = $email . ' ' . $biz . ' ' . $message;
$probe = (bool) (
    preg_match('/\b(probe|not a customer|not a real client|do-not-build|do not build)\b/i', $blob)
    || preg_match('/@(example\.com|example\.gr|agency002\.invalid)$/i', $email)
    || preg_match('/^(night hem|atelier limeni|atelier formcheck|rota keys|riza)\b/i', $biz)
    || preg_match('/^probe/i', $biz)
);
if ($probe) {
    brief_out(200, [
        'ok' => true,
        'skipped' => 'probe',
        'message' => 'Got it.',
        'kv' => true,
    ]);
}

$phoneLabel = $phone !== '' ? $phone : '(not provided)';
$pkgLabel = 'EUR 120 live page (plan=cash_120)';
$source = '120.cash';
$stamp = gmdate('Ymd-His');
$rand = bin2hex(random_bytes(3));
$saved = '';
$bodyFile =
    "Client: {$email}\n\nBRIEF SUMMARY\nSource: {$source}\nPackage: {$pkgLabel}\nBusiness name: {$biz}\nPhone / WhatsApp: {$phoneLabel}\nWhat they do / page must say:\n{$message}\nContact email: {$email}\nCity: {$city}\n";
if ($paymentId !== '') {
    $bodyFile .= "Payment id: {$paymentId}\n";
}

foreach (['/home/agency00/hosting-briefs', __DIR__ . '/hosting-briefs'] as $dir) {
    if (!is_dir($dir) || !is_writable($dir)) {
        continue;
    }
    $path = $dir . '/brief-' . $stamp . '-' . $rand . '.txt';
    if (@file_put_contents($path, $bodyFile) !== false) {
        $saved = $path;
        break;
    }
}

$mail = ($saved !== '' ? "Saved: {$saved}\n" : '') . $bodyFile;
$headers = "From: noreply@agency002.com\r\nReply-To: {$email}\r\nContent-Type: text/plain; charset=utf-8";
@mail('agency002.com@gmail.com', 'NEW 120.cash BRIEF (money door)', $mail, $headers);

$payload = json_encode([
    'businessName' => $biz,
    'whatYouDo' => $message,
    'phone' => $phone,
    'email' => $email,
    'city' => $city,
    'language' => $language,
    'pkg' => 'cash_120',
], JSON_UNESCAPED_UNICODE);

$url = '';
$ch = curl_init('https://cash.120.cash/api/publish');
if ($ch !== false) {
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
        CURLOPT_POSTFIELDS => $payload,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 12,
    ]);
    $out = curl_exec($ch);
    curl_close($ch);
    $json = json_decode((string) $out, true);
    if (
        is_array($json)
        && isset($json['url'])
        && is_string($json['url'])
        && preg_match('#^https://cash\.120\.cash/p/#', $json['url'])
    ) {
        $url = $json['url'];
    }
}

if ($url !== '') {
    brief_out(200, [
        'ok' => true,
        'kv' => true,
        'url' => $url,
        'message' => 'It is live tonight: ' . $url,
    ]);
}

brief_out(200, [
    'ok' => true,
    'kv' => true,
    'message' => 'Got it. Building tonight — not a working day.',
]);
