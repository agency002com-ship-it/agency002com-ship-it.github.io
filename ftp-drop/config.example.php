<?php
/**
 * Copy to config.local.php on 120.cash (same folder as these files).
 * gitignore already drops *.local.* — this never leaves the box.
 */
return [
    // openssl rand -hex 32
    'job_secret' => 'REPLACE_WITH_32_PLUS_HEX',
    'keychain'   => 'https://keychain.gr/api/owner-checkout.php',
    // You get a copy when a page goes live. Transactional, not outreach.
    'mail_bcc'   => 'agency002.com@gmail.com',
    'mail_from'  => 'desk@120.cash',
];
