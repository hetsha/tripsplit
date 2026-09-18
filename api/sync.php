<?php
/**
 * TripBook Lightweight Sync & Incremental Polling API
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/auth.php';

header('Content-Type: application/json; charset=utf-8');

$currentUser = getCurrentUser();
$tripId = (int)($_GET['trip_id'] ?? getActiveTripId());
requireTripMembership($tripId, (int)$currentUser['id']);

$clientToken = trim((string)($_GET['version'] ?? ''));

$db = getDBConnection();

// Compute a fast MD5 checksum based on max(updated_at) and count(*) of transactions, settlements, and members
$stmt = $db->prepare("
    SELECT 
        (SELECT COUNT(*) FROM transactions WHERE trip_id = ?) as trans_count,
        (SELECT COALESCE(MAX(updated_at), '1970-01-01') FROM transactions WHERE trip_id = ?) as trans_last,
        (SELECT COUNT(*) FROM settlements WHERE trip_id = ?) as set_count,
        (SELECT COALESCE(MAX(created_at), '1970-01-01') FROM settlements WHERE trip_id = ?) as set_last,
        (SELECT COUNT(*) FROM trip_members WHERE trip_id = ?) as member_count
");
$stmt->execute([$tripId, $tripId, $tripId, $tripId, $tripId]);
$syncData = $stmt->fetch();

$versionHash = md5(implode('|', [
    $tripId,
    $syncData['trans_count'],
    $syncData['trans_last'],
    $syncData['set_count'],
    $syncData['set_last'],
    $syncData['member_count']
]));

$hasChanges = ($clientToken !== $versionHash);

jsonSuccess('Sync status', [
    'trip_id'     => $tripId,
    'has_changes' => $hasChanges,
    'version'     => $versionHash,
    'last_update' => max($syncData['trans_last'], $syncData['set_last'])
]);
