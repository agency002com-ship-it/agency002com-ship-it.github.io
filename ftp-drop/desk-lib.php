<?php
declare(strict_types=1);

function desk_cfg(): array {
    $file = __DIR__ . '/config.local.php';
    if (!is_file($file)) {
        desk_fail(503, 'Desk is not configured yet.');
    }
    /** @var array $cfg */
    $cfg = require $file;
    if (empty($cfg['job_secret']) || strlen((string) $cfg['job_secret']) < 16) {
        desk_fail(503, 'Desk is not configured yet.');
    }
    return $cfg;
}

function desk_fail(int $status, string $error): never {
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['error' => $error], JSON_UNESCAPED_UNICODE);
    exit;
}

function desk_key(array $cfg): string {
    return hash('sha256', (string) $cfg['job_secret'], true);
}

function desk_page_token(): string {
    $abc = 'abcdefghijklmnopqrstuvwxyz';
    $out = 'p';
    for ($i = 0; $i < 20; $i++) {
        $out .= $abc[random_int(0, 25)];
    }
    return $out;
}

function desk_b64url(string $raw): string {
    return rtrim(strtr(base64_encode($raw), '+/', '-_'), '=');
}

function desk_b64url_decode(string $s): string {
    $pad = strlen($s) % 4;
    if ($pad) $s .= str_repeat('=', 4 - $pad);
    $out = base64_decode(strtr($s, '-_', '+/'), true);
    return $out === false ? '' : $out;
}

function desk_mint(array $cfg, array $payload): string {
    $raw = gzdeflate(json_encode($payload, JSON_UNESCAPED_UNICODE), 6);
    $iv = random_bytes(12);
    $tag = '';
    $cipher = openssl_encrypt($raw, 'aes-256-gcm', desk_key($cfg), OPENSSL_RAW_DATA, $iv, $tag);
    if ($cipher === false) desk_fail(500, 'Could not seal the brief.');
    return 't1.' . desk_b64url($iv . $tag . $cipher);
}

function desk_open(array $cfg, string $token): ?array {
    if (!str_starts_with($token, 't1.')) return null;
    $bin = desk_b64url_decode(substr($token, 3));
    if (strlen($bin) < 28) return null;
    $iv = substr($bin, 0, 12);
    $tag = substr($bin, 12, 16);
    $cipher = substr($bin, 28);
    $raw = openssl_decrypt($cipher, 'aes-256-gcm', desk_key($cfg), OPENSSL_RAW_DATA, $iv, $tag);
    if ($raw === false) return null;
    $json = gzinflate($raw);
    if ($json === false) return null;
    $payload = json_decode($json, true);
    if (!is_array($payload)) return null;
    if (($payload['exp'] ?? 0) < time()) return null;
    return $payload;
}

function desk_data_dir(): string {
    $dir = __DIR__ . '/desk-data';
    if (!is_dir($dir)) {
        mkdir($dir, 0700, true);
        file_put_contents($dir . '/.htaccess', "Require all denied\nDeny from all\n");
    }
    return $dir;
}

function desk_save_job(array $job): void {
    $page = $job['page'] ?? '';
    if (!preg_match('/^p[a-z]{20}$/', $page)) return;
    $dest = desk_data_dir() . '/' . $page . '.json';
    $tmp = $dest . '.' . getmypid() . '.tmp';
    file_put_contents($tmp, json_encode($job, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT));
    rename($tmp, $dest);
}

function desk_load_job(string $page): ?array {
    if (!preg_match('/^p[a-z]{20}$/', $page)) return null;
    $file = desk_data_dir() . '/' . $page . '.json';
    if (!is_file($file)) return null;
    $job = json_decode((string) file_get_contents($file), true);
    return is_array($job) ? $job : null;
}

function desk_keychain(array $cfg, array $body): array {
    $ch = curl_init((string) ($cfg['keychain'] ?? 'https://keychain.gr/api/owner-checkout.php'));
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
        CURLOPT_POSTFIELDS => json_encode($body, JSON_UNESCAPED_UNICODE),
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 15,
    ]);
    $out = curl_exec($ch);
    $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    $json = json_decode((string) $out, true);
    if ($code >= 400 || !is_array($json)) {
        $err = is_array($json) && isset($json['error']) ? (string) $json['error'] : 'Till did not answer.';
        desk_fail(502, $err);
    }
    return $json;
}

function desk_h(string $s): string {
    return htmlspecialchars($s, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}
