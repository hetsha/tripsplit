<?php
/**
 * TripBook Google OAuth API
 * Verifies Google ID token and creates/finds user
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/auth.php';

header('Content-Type: application/json; charset=utf-8');

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? $_POST['action'] ?? '';

$db = getDBConnection();

function getSetting(string $key, string $default = ''): string {
    $db = getDBConnection();
    $stmt = $db->prepare("SELECT setting_value FROM app_settings WHERE setting_key = ?");
    $stmt->execute([$key]);
    $row = $stmt->fetch();
    return $row ? (string)$row['setting_value'] : $default;
}

if ($method === 'POST' && $action === 'google_login') {
    $input = getJsonInput();
    $idToken = trim($input['credential'] ?? '');

    if (empty($idToken)) {
        jsonError('Google credential is required', 422);
    }

    $googleClientId = getSetting('google_client_id');
    if (empty($googleClientId)) {
        jsonError('Google login is not configured', 500);
    }

    // Verify token with Google
    $ch = curl_init('https://oauth2.googleapis.com/tokeninfo?id_token=' . urlencode($idToken));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);

    if ($response === false || $httpCode !== 200) {
        error_log("TripBook Google Auth: Token verification failed - HTTP $httpCode - $curlError");
        jsonError('Invalid Google token', 401);
    }

    $googleUser = json_decode($response, true);
    if (!$googleUser || !isset($googleUser['sub'])) {
        jsonError('Invalid Google token data', 401);
    }

    // Verify audience matches our client ID
    if (isset($googleUser['aud']) && $googleUser['aud'] !== $googleClientId) {
        jsonError('Token audience mismatch', 401);
    }

    // Check if auth_google_enabled
    if (getSetting('auth_google_enabled', '0') !== '1') {
        jsonError('Google login is disabled', 403);
    }

    $googleId = $googleUser['sub'];
    $email = $googleUser['email'] ?? null;
    $name = $googleUser['name'] ?? ($email ? explode('@', $email)[0] : 'Google User');

    // Check if new columns exist
    $hasNewColumns = true;
    try {
        $db->query("SELECT google_id, email_verified, auth_provider FROM users LIMIT 1");
    } catch (PDOException $e) {
        $hasNewColumns = false;
        error_log("TripBook Google Auth: New columns missing - run migration_auth.sql");
    }

    if (!$hasNewColumns) {
        jsonError('Database not migrated. Please run sql/migration_auth.sql', 500);
    }

    // Find existing user by google_id or email
    $user = null;
    $isNewUser = false;

    if ($email) {
        $stmt = $db->prepare("SELECT id, name, email, phone, phone_verified, email_verified, google_id, auth_provider, avatar_color, is_admin FROM users WHERE email = ? OR google_id = ?");
        $stmt->execute([$email, $googleId]);
        $user = $stmt->fetch();
    }

    if ($user) {
        // Update google_id if not set
        if (empty($user['google_id'])) {
            $stmt = $db->prepare("UPDATE users SET google_id = ?, auth_provider = 'google' WHERE id = ?");
            $stmt->execute([$googleId, $user['id']]);
        }
        // Update email_verified if email matches
        if ($email && (int)($user['email_verified'] ?? 0) === 0) {
            $stmt = $db->prepare("UPDATE users SET email_verified = 1 WHERE id = ?");
            $stmt->execute([$user['id']]);
            $user['email_verified'] = 1;
        }
    } else {
        // Create new user
        $isNewUser = true;
        $colors = ['#2563eb', '#10b981', '#f59e0b', '#8b5cf6', '#ec4899', '#06b6d4', '#f97316'];
        $avatarColor = $colors[array_rand($colors)];

        $stmt = $db->prepare("
            INSERT INTO users (name, email, email_verified, google_id, auth_provider, password_hash, avatar_color) 
            VALUES (?, ?, 1, ?, 'google', ?, ?)
        ");
        $stmt->execute([
            $name,
            $email,
            $googleId,
            password_hash(bin2hex(random_bytes(16)), PASSWORD_DEFAULT),
            $avatarColor
        ]);

        $userId = (int)$db->lastInsertId();

        $stmt = $db->prepare("SELECT id, name, email, phone, phone_verified, email_verified, google_id, auth_provider, avatar_color, is_admin FROM users WHERE id = ?");
        $stmt->execute([$userId]);
        $user = $stmt->fetch();
    }

    // Set session
    $_SESSION['user_id'] = (int)$user['id'];
    $_SESSION['user_name'] = $user['name'];
    $_SESSION['authenticated'] = true;

    // Get user's trips
    $tripStmt = $db->prepare("
        SELECT t.id, t.trip_code, t.url_token, t.name, t.currency_symbol, tm.role 
        FROM trips t
        JOIN trip_members tm ON tm.trip_id = t.id
        WHERE tm.user_id = ?
        ORDER BY t.created_at DESC
    ");
    $tripStmt->execute([$user['id']]);
    $trips = $tripStmt->fetchAll();

    // Set active trip
    if (!empty($trips)) {
        if (empty($_SESSION['active_trip_id'])) {
            $_SESSION['active_trip_id'] = (int)$trips[0]['id'];
        }
        $validTripIds = array_column($trips, 'id');
        if (!in_array((int)($_SESSION['active_trip_id'] ?? 0), $validTripIds)) {
            $_SESSION['active_trip_id'] = (int)$trips[0]['id'];
        }
    } else {
        unset($_SESSION['active_trip_id']);
    }

    $csrfToken = getCsrfToken();

    jsonSuccess($isNewUser ? 'Account created successfully' : 'Login successful', [
        'user' => $user,
        'csrf_token' => $csrfToken,
        'trips' => $trips,
        'active_trip' => getActiveTripId(),
        'is_new_user' => $isNewUser,
        'needs_phone' => empty($user['phone'])
    ]);
}

jsonError('Invalid request', 400);
