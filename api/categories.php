<?php
/**
 * TripBook Categories API
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
        SELECT id, name, icon, color, is_default, trip_id
        FROM categories
        WHERE trip_id = ? OR trip_id IS NULL
        ORDER BY is_default DESC, id ASC
    ");
    $stmt->execute([$tripId]);
    $categories = $stmt->fetchAll();

    jsonSuccess('Categories list', ['categories' => $categories]);
}

if ($method === 'POST') {
    requireCsrf();
    $input = getJsonInput();
    $act = $input['action'] ?? $action;

    if ($act === 'create') {
        $name = trim((string)($input['name'] ?? ''));
        $icon = trim((string)($input['icon'] ?? 'tag'));
        $color = trim((string)($input['color'] ?? '#3b82f6'));

        if (empty($name)) {
            jsonError('Category name is required', 422);
        }

        $stmt = $db->prepare("
            INSERT INTO categories (trip_id, name, icon, color, is_default)
            VALUES (?, ?, ?, ?, 0)
        ");
        $stmt->execute([$tripId, $name, $icon, $color]);
        $newId = (int)$db->lastInsertId();

        jsonSuccess('Category created successfully', ['category_id' => $newId]);
    }

    jsonError('Invalid action', 400);
}
