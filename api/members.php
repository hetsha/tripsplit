<?php
/**
 * TripBook Members & Roles API
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/calculations.php';

header('Content-Type: application/json; charset=utf-8');

$currentUser = getCurrentUser();
$db = getDBConnection();
$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? $_POST['action'] ?? 'list';

$tripId = (int)($_GET['trip_id'] ?? $_POST['trip_id'] ?? getActiveTripId());
$membership = requireTripMembership($tripId, (int)$currentUser['id']);

if ($method === 'GET') {
    if ($action === 'cashbook') {
        $cashbook = getUserCashbookLedger($tripId, (int)$currentUser['id']);

        jsonSuccess('Personal CashBook', [
            'user'     => $currentUser,
            'cashbook' => $cashbook
        ]);
    }

    $stmt = $db->prepare("
        SELECT u.id, u.name, u.email, u.phone, u.avatar_color, tm.role, tm.joined_at
        FROM trip_members tm
        JOIN users u ON u.id = tm.user_id
        WHERE tm.trip_id = ?
        ORDER BY tm.joined_at ASC
    ");
    $stmt->execute([$tripId]);
    $members = $stmt->fetchAll();

    $myBalance = null;
    $balances = getSplitwiseBalances($tripId);
    if (isset($balances[(int)$currentUser['id']])) {
        $myBalance = $balances[(int)$currentUser['id']];
    }

    foreach ($members as &$m) {
        $uid = (int)$m['id'];
        $m['balance_info'] = ($uid === (int)$currentUser['id']) ? ($balances[$uid] ?? null) : null;
    }
    unset($m);

    jsonSuccess('Trip members', [
        'members'     => $members,
        'my_balance'  => $myBalance,
        'trip_code'   => $membership['trip_code']
    ]);
}

if ($method === 'POST') {
    requireCsrf();
    $input = getJsonInput();
    $act = $input['action'] ?? $action;

    // Add Member by Name or Email
    if ($act === 'add') {
        $name = trim((string)($input['name'] ?? ''));
        $email = trim((string)($input['email'] ?? ''));
        $phone = trim((string)($input['phone'] ?? ''));

        if (empty($name)) {
            jsonError('Member name is required', 422);
        }

        // Check if user already exists
        $uStmt = $db->prepare("SELECT id FROM users WHERE LOWER(name) = LOWER(?) OR (email IS NOT NULL AND email = ?) LIMIT 1");
        $uStmt->execute([$name, $email ?: '']);
        $existing = $uStmt->fetch();

        if ($existing) {
            $memberUserId = (int)$existing['id'];
        } else {
            $colors = ['#2563eb', '#10b981', '#f59e0b', '#8b5cf6', '#ec4899', '#06b6d4', '#f97316'];
            $avatarColor = $colors[array_rand($colors)];
            $insStmt = $db->prepare("
                INSERT INTO users (name, email, phone, password_hash, avatar_color)
                VALUES (?, ?, ?, ?, ?)
            ");
            $insStmt->execute([
                $name,
                $email ?: null,
                $phone ?: null,
                password_hash(bin2hex(random_bytes(16)), PASSWORD_DEFAULT),
                $avatarColor
            ]);
            $memberUserId = (int)$db->lastInsertId();
        }

        // Add to trip
        $stmt = $db->prepare("INSERT IGNORE INTO trip_members (trip_id, user_id, role) VALUES (?, ?, 'member')");
        $stmt->execute([$tripId, $memberUserId]);

        // Create notification
        $adderName = $currentUser['name'];
        createNotification($tripId, 'member_joined', "$adderName added $name to the trip");

        jsonSuccess("Added {$name} to the trip!");
    }

    // Remove Member (if no expenses/splits tied to them)
    if ($act === 'remove') {
        $removeUserId = (int)($input['user_id'] ?? 0);
        if ($removeUserId <= 0) {
            jsonError('Invalid user ID', 422);
        }

        if ($membership['role'] !== 'owner') {
            jsonError('Only trip owner can remove members', 403);
        }

        // Check if user is payer in any transaction
        $chk = $db->prepare("SELECT COUNT(*) FROM transactions WHERE trip_id = ? AND paid_by = ?");
        $chk->execute([$tripId, $removeUserId]);
        if ((int)$chk->fetchColumn() > 0) {
            jsonError('Cannot remove member who has recorded paid transactions', 422);
        }

        $stmt = $db->prepare("DELETE FROM trip_members WHERE trip_id = ? AND user_id = ?");
        $stmt->execute([$tripId, $removeUserId]);

        jsonSuccess('Member removed successfully');
    }

    jsonError('Invalid action', 400);
}
