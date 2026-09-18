<?php
/**
 * TripBook Authentication & Session Management
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/functions.php';

// Start secure session if not already started
if (session_status() === PHP_SESSION_NONE) {
    ini_set('session.cookie_httponly', '1');
    ini_set('session.use_only_cookies', '1');
    ini_set('session.cookie_samesite', 'Lax');
    session_start();
}

/**
 * Generate or get existing CSRF token.
 */
function getCsrfToken(): string {
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

/**
 * Validate CSRF token from header or request body.
 */
function validateCsrfToken(?string $token): bool {
    if (empty($token) || empty($_SESSION['csrf_token'])) {
        return false;
    }
    return hash_equals($_SESSION['csrf_token'], $token);
}

/**
 * Require valid CSRF token for state-changing requests.
 */
function requireCsrf(): void {
    $token = $_SERVER['HTTP_X_CSRF_TOKEN'] ?? null;
    if (!$token) {
        $body = getJsonInput();
        $token = $body['csrf_token'] ?? $_POST['csrf_token'] ?? null;
    }
    if (!validateCsrfToken($token)) {
        jsonError('CSRF token validation failed', 403);
    }
}

/**
 * Check if user is authenticated via OTP
 */
function isAuthenticated(): bool {
    return !empty($_SESSION['authenticated']) && !empty($_SESSION['user_id']);
}

/**
 * Require authentication - redirects to login if not authenticated
 */
function requireAuth(): void {
    if (!isAuthenticated()) {
        // For API calls, return JSON error
        if (strpos($_SERVER['REQUEST_URI'] ?? '', '/api/') !== false) {
            jsonError('Authentication required', 401);
        }
        // For page loads, will be handled by frontend
        header('Location: index.php');
        exit;
    }
}

/**
 * Get the currently logged-in user.
 * Returns empty array if not authenticated.
 */
function getCurrentUser(): array {
    // Check if authenticated
    if (empty($_SESSION['user_id'])) {
        return [
            'id' => 0,
            'name' => 'Guest',
            'email' => null,
            'phone' => null,
            'phone_verified' => 0,
            'avatar_color' => '#2563eb',
            'is_admin' => 0
        ];
    }

    $db = getDBConnection();
    
    $stmt = $db->prepare("SELECT id, name, email, phone, phone_verified, email_verified, google_id, auth_provider, avatar_color, is_admin FROM users WHERE id = ?");
    $stmt->execute([$_SESSION['user_id']]);
    $user = $stmt->fetch();

    if (!$user) {
        // User not found, clear session
        unset($_SESSION['user_id'], $_SESSION['user_name'], $_SESSION['authenticated']);
        return [
            'id' => 0,
            'name' => 'Guest',
            'email' => null,
            'phone' => null,
            'phone_verified' => 0,
            'avatar_color' => '#2563eb',
            'is_admin' => 0
        ];
    }

    return $user;
}

/**
 * Switch active session user.
 */
function switchUser(int $userId): array {
    $db = getDBConnection();
    $stmt = $db->prepare("SELECT id, name, email, phone, phone_verified, email_verified, google_id, auth_provider, avatar_color, is_admin FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    $user = $stmt->fetch();

    if (!$user) {
        jsonError('User not found', 404);
    }

    $_SESSION['user_id'] = (int)$user['id'];
    $_SESSION['user_name'] = $user['name'];

    return $user;
}

/**
 * Get active trip ID from session or query parameter.
 */
function getActiveTripId(): int {
    if (isset($_GET['trip_id']) && is_numeric($_GET['trip_id'])) {
        $_SESSION['active_trip_id'] = (int)$_GET['trip_id'];
    } elseif (isset($_POST['trip_id']) && is_numeric($_POST['trip_id'])) {
        $_SESSION['active_trip_id'] = (int)$_POST['trip_id'];
    }

    return (int)($_SESSION['active_trip_id'] ?? 0);
}

/**
 * Set active trip ID.
 */
function setActiveTripId(int $tripId): void {
    $_SESSION['active_trip_id'] = $tripId;
}

/**
 * Guard that verifies the logged-in user belongs to the specified trip.
 */
function requireTripMembership(int $tripId, int $userId): array {
    $db = getDBConnection();
    $stmt = $db->prepare("
        SELECT tm.role, t.id, t.trip_code, t.url_token, t.name, t.currency, t.currency_symbol, t.starting_money, t.starting_payment_method
        FROM trip_members tm
        JOIN trips t ON t.id = tm.trip_id
        WHERE tm.trip_id = ? AND tm.user_id = ?
    ");
    $stmt->execute([$tripId, $userId]);
    $membership = $stmt->fetch();

    if (!$membership) {
        jsonError('Unauthorized: You are not a member of this trip.', 403);
    }

    return $membership;
}
