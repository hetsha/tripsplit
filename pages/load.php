<?php
/**
 * AJAX Page Loader - Returns page HTML for SPA navigation
 */
declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/auth.php';

header('Content-Type: text/html; charset=utf-8');

if (!isAuthenticated()) {
    http_response_code(401);
    exit('Unauthorized');
}

$page = $_GET['page'] ?? 'home';
$tripToken = $_GET['trip'] ?? '';
$tripId = 0;

$allowedPages = ['home', 'history', 'people', 'settle', 'more'];

if (!in_array($page, $allowedPages, true)) {
    http_response_code(400);
    exit('Invalid page');
}

if (!empty($tripToken)) {
    $db = getDBConnection();
    $stmt = $db->prepare("SELECT id FROM trips WHERE url_token = ?");
    $stmt->execute([$tripToken]);
    $row = $stmt->fetch();
    $tripId = $row ? (int)$row['id'] : 0;
}

if ($tripId <= 0) {
    $tripId = (int)getActiveTripId();
}

if ($tripId <= 0) {
    http_response_code(400);
    exit('No active trip');
}

$filePath = __DIR__ . '/' . $page . '.php';

if (!file_exists($filePath)) {
    http_response_code(404);
    exit('Page not found');
}

$_GET['trip_id'] = $tripId;

ob_start();
include $filePath;
ob_end_flush();
