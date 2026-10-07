<?php
/**
 * TripBook Apple OAuth & Sign-In API
 * Handles Apple Sign-In and creates/finds user in database
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/auth.php';

header('Content-Type: application/json; charset=utf-8');

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? $_POST['action'] ?? '';

$db = getDBConnection();

// Ensure apple_id column exists in users table
try {
    $db->query("SELECT apple_id FROM users LIMIT 1");
} catch (PDOException $e) {
    try {
        $db->exec("ALTER TABLE users ADD COLUMN `apple_id` VARCHAR(100) NULL AFTER `google_id`");
    } catch (PDOException $ignored) {}
}

// Ensure auth_provider allows 'apple'
try {
    $db->exec("ALTER TABLE users MODIFY COLUMN `auth_provider` VARCHAR(30) NOT NULL DEFAULT 'phone'");
} catch (PDOException $ignored) {}

if ($method === 'POST' && $action === 'apple_login') {
    $input = getJsonInput();
    
    // Apple provides sub/user-id, identity_token, email, and user name object
    $appleId = trim((string)($input['apple_id'] ?? $input['credential'] ?? ''));
    $email = trim((string)($input['email'] ?? ''));
    $name = trim((string)($input['name'] ?? ''));
    $identityToken = trim((string)($input['identity_token'] ?? ''));

    // If an identityToken JWT was passed, attempt to parse sub and email from payload
    if (!empty($identityToken) && empty($appleId)) {
        $parts = explode('.', $identityToken);
        if (count($parts) >= 2) {
            $payloadJson = base64_decode(str_replace(['-', '_'], ['+', '/'], $parts[1]));
            if ($payloadJson) {
                $claims = json_decode($payloadJson, true);
                if (is_array($claims)) {
                    $appleId = $claims['sub'] ?? '';
                    if (empty($email) && !empty($claims['email'])) {
                        $email = (string)$claims['email'];
                    }
                }
            }
        }
    }

    if (empty($appleId) && empty($email)) {
        jsonError('Apple identifier or email is required', 422);
    }

    if (empty($name)) {
        $name = !empty($email) ? explode('@', $email)[0] : 'Apple Traveler';
    }

    // Find existing user by apple_id, or email
    $user = null;
    $isNewUser = false;

    if (!empty($appleId)) {
        $stmt = $db->prepare("SELECT id, name, email, phone, phone_verified, email_verified, google_id, apple_id, auth_provider, avatar_color, is_admin FROM users WHERE apple_id = ?");
        $stmt->execute([$appleId]);
        $user = $stmt->fetch();
    }

    if (!$user && !empty($email)) {
        $stmt = $db->prepare("SELECT id, name, email, phone, phone_verified, email_verified, google_id, apple_id, auth_provider, avatar_color, is_admin FROM users WHERE email = ?");
        $stmt->execute([$email]);
        $user = $stmt->fetch();
    }

    if ($user) {
        // Link apple_id if not present
        if (empty($user['apple_id']) && !empty($appleId)) {
            $stmt = $db->prepare("UPDATE users SET apple_id = ?, auth_provider = 'apple' WHERE id = ?");
            $stmt->execute([$appleId, $user['id']]);
            $user['apple_id'] = $appleId;
        }
        if (!empty($email) && (int)($user['email_verified'] ?? 0) === 0) {
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
            INSERT INTO users (name, email, email_verified, apple_id, auth_provider, password_hash, avatar_color) 
            VALUES (?, ?, 1, ?, 'apple', ?, ?)
        ");
        $stmt->execute([
            $name,
            !empty($email) ? $email : null,
            !empty($appleId) ? $appleId : bin2hex(random_bytes(10)),
            password_hash(bin2hex(random_bytes(16)), PASSWORD_DEFAULT),
            $avatarColor
        ]);

        $userId = (int)$db->lastInsertId();

        $stmt = $db->prepare("SELECT id, name, email, phone, phone_verified, email_verified, google_id, apple_id, auth_provider, avatar_color, is_admin FROM users WHERE id = ?");
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

    jsonSuccess($isNewUser ? 'Account created with Apple' : 'Apple login successful', [
        'user' => $user,
        'csrf_token' => $csrfToken,
        'trips' => $trips,
        'active_trip' => getActiveTripId(),
        'is_new_user' => $isNewUser,
        'needs_phone' => empty($user['phone'])
    ]);
}

jsonError('Invalid Apple authentication request', 400);
