<?php
$host = gethostname();
$ips = gethostbynamel($host);
$ipStr = implode(',', $ips ?: []);
echo json_encode([
    'hostname' => $host,
    'ips' => $ips,
    'primary' => gethostbyname($host),
]);
