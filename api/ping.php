<?php
header('Content-Type: application/json');
$clientIp = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
$logEntry = date('Y-m-d H:i:s') . " | Request from: $clientIp | Method: " . $_SERVER['REQUEST_METHOD'] . " | Path: " . ($_SERVER['REQUEST_URI'] ?? '') . "\n";
file_put_contents(__DIR__ . '/../network_log.txt', $logEntry, FILE_APPEND);

echo json_encode([
    'status' => 'ok',
    'message' => 'TripSplit API reachable!',
    'your_ip' => $clientIp,
    'time' => date('Y-m-d H:i:s')
]);
