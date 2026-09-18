<?php
/**
 * TripBook Auth & User API
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/auth.php';

header('Content-Type: application/json; charset=utf-8');

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? $_POST['action'] ?? 'me';

$db = getDBConnection();

// GET: Current user session info
if ($method === 'GET') {
    if ($action === 'me') {
        $currentUser = getCurrentUser();
        $csrfToken = getCsrfToken();

        // Get user's trips
        $tripStmt = $db->prepare("
            SELECT t.id, t.trip_code, t.url_token, t.name, t.currency_symbol, tm.role 
            FROM trips t
            JOIN trip_members tm ON tm.trip_id = t.id
            WHERE tm.user_id = ?
            ORDER BY t.created_at DESC
        ");
        $tripStmt->execute([$currentUser['id']]);
        $trips = $tripStmt->fetchAll();

        jsonSuccess('User profile', [
            'user'         => $currentUser,
            'csrf_token'   => $csrfToken,
            'trips'        => $trips,
            'active_trip'  => getActiveTripId()
        ]);
    }
}

// POST Actions
if ($method === 'POST') {
    requireCsrf();
    $input = getJsonInput();
    $act = $input['action'] ?? $action;

    // Set active trip
    if ($act === 'switch_trip') {
        $tripId = (int)($input['trip_id'] ?? 0);
        $user = getCurrentUser();
        requireTripMembership($tripId, (int)$user['id']);
        setActiveTripId($tripId);
        jsonSuccess('Switched trip', ['active_trip_id' => $tripId]);
    }

    // Register / Create User
    if ($act === 'register') {
        $name = trim((string)($input['name'] ?? ''));
        $email = trim((string)($input['email'] ?? ''));
        $phone = trim((string)($input['phone'] ?? ''));
        $password = (string)($input['password'] ?? '');

        if (empty($name)) {
            jsonError('Name is required', 422);
        }

        $colors = ['#2563eb', '#10b981', '#f59e0b', '#8b5cf6', '#ec4899', '#06b6d4', '#f97316'];
        $avatarColor = $colors[array_rand($colors)];

        $stmt = $db->prepare("
            INSERT INTO users (name, email, phone, password_hash, avatar_color)
            VALUES (?, ?, ?, ?, ?)
        ");
        $stmt->execute([
            $name,
            $email ?: null,
            $phone ?: null,
            password_hash($password, PASSWORD_DEFAULT),
            $avatarColor
        ]);

        $newUserId = (int)$db->lastInsertId();

        // Set session for new user
        $_SESSION['user_id'] = $newUserId;
        $_SESSION['user_name'] = $name;
        $_SESSION['authenticated'] = true;

        $user = getCurrentUser();

        jsonSuccess('Account created successfully', ['user' => $user]);
    }

    // Delete Account
    if ($act === 'delete_account') {
        $currentUser = getCurrentUser();
        $userId = (int)$currentUser['id'];

        // Remove user from all trips
        $db->prepare("DELETE FROM trip_members WHERE user_id = ?")->execute([$userId]);

        // Delete expenses created by user
        $db->prepare("DELETE FROM expenses WHERE created_by = ?")->execute([$userId]);

        // Delete settlements involving user
        $db->prepare("DELETE FROM settlements WHERE from_user_id = ? OR to_user_id = ?")->execute([$userId, $userId]);

        // Delete OTP sessions
        $db->prepare("DELETE FROM phone_otp_sessions WHERE user_id = ?")->execute([$userId]);
        $db->prepare("DELETE FROM email_otp_sessions WHERE user_id = ?")->execute([$userId]);

        // Delete user
        $db->prepare("DELETE FROM users WHERE id = ?")->execute([$userId]);

        // Destroy session
        session_destroy();

        jsonSuccess('Account deleted successfully');
    }

    jsonError('Invalid action', 400);
}
