<?php
/**
 * TripBook Notifications API
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/auth.php';

header('Content-Type: application/json; charset=utf-8');

$currentUser = getCurrentUser();
$db = getDBConnection();
$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? $_POST['action'] ?? 'list';
$tripId = (int)($_GET['trip_id'] ?? $_POST['trip_id'] ?? getActiveTripId());

if ($method === 'GET') {
    $stmt = $db->prepare("
        SELECT n.id, n.type, n.message, n.is_read, n.created_at,
               DATE_FORMAT(n.created_at, '%b %d, %g:%i %p') AS formatted_date
        FROM notifications n
        JOIN trip_members tm ON tm.trip_id = n.trip_id
        WHERE n.trip_id = ? AND tm.user_id = ?
        ORDER BY n.created_at DESC
        LIMIT 50
    ");
    $stmt->execute([$tripId, $currentUser['id']]);
    $notifications = $stmt->fetchAll();

    jsonSuccess('Notifications list', ['notifications' => $notifications]);
}

if ($method === 'POST') {
    requireCsrf();
    $input = getJsonInput();
    $act = $input['action'] ?? $action;

    if ($act === 'mark_read') {
        $id = (int)($input['id'] ?? 0);
        if ($id > 0) {
            $stmt = $db->prepare("UPDATE notifications SET is_read = 1 WHERE id = ? AND trip_id = ?");
            $stmt->execute([$id, $tripId]);
        }
        jsonSuccess('Notification marked as read');
    }

    if ($act === 'mark_all_read') {
        $stmt = $db->prepare("UPDATE notifications SET is_read = 1 WHERE trip_id = ? AND is_read = 0");
        $stmt->execute([$tripId]);
        jsonSuccess('All notifications marked as read');
    }

    jsonError('Invalid action', 400);
}
