<?php
/**
 * TripSplit Admin Panel - Secure Authentication Core
 * Section 4, 4.1, 4.2, 4.3
 */

declare(strict_types=1);

// Configure secure session parameters if session not yet started
if (session_status() === PHP_SESSION_NONE) {
    ini_set('session.cookie_httponly', '1');
    ini_set('session.use_only_cookies', '1');
    if (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') {
        ini_set('session.cookie_secure', '1');
    }
    ini_set('session.cookie_samesite', 'Lax');
    session_start();
}

require_once __DIR__ . '/db.php';
require_once __DIR__ . '/permissions.php';
require_once __DIR__ . '/csrf.php';
require_once __DIR__ . '/audit.php';

const ADMIN_IDLE_TIMEOUT = 7200; // 2 hours

/**
 * Check if current admin session is valid and active
 */
function isAdminAuthenticated(): bool {
    if (empty($_SESSION['admin_id']) || empty($_SESSION['admin_username'])) {
        return false;
    }

    // Check idle session expiration (Section 4.3)
    $lastActivity = $_SESSION['admin_last_activity'] ?? 0;
    if ($lastActivity > 0 && (time() - $lastActivity) > ADMIN_IDLE_TIMEOUT) {
        adminLogout('Session expired due to inactivity');
        return false;
    }
    $_SESSION['admin_last_activity'] = time();

    return true;
}

/**
 * Require valid authenticated session or redirect to login
 */
function requireAdminAuth(): void {
    if (!isAdminAuthenticated()) {
        header('Location: login.php?msg=auth_required');
        exit;
    }

    // Require CSRF validation for state-changing POST requests
    requireCsrfToken();
}

/**
 * Get current admin user details
 */
function getCurrentAdmin(): array {
    return [
        'id' => (int)($_SESSION['admin_id'] ?? 0),
        'username' => $_SESSION['admin_username'] ?? '',
        'name' => $_SESSION['admin_name'] ?? 'Admin',
        'email' => $_SESSION['admin_email'] ?? '',
        'role' => $_SESSION['admin_role'] ?? 'SUPER_ADMIN'
    ];
}

/**
 * Check login throttling / brute-force protection
 */
function checkLoginThrottling(string $username, string $ip): ?string {
    try {
        $db = getDBConnection();
        ensureAdminTablesExist($db);

        $stmt = $db->prepare("
            SELECT COUNT(*) FROM admin_login_logs 
            WHERE (ip_address = ? OR username_attempted = ?) 
              AND status = 'failed' 
              AND created_at >= (NOW() - INTERVAL 15 MINUTE)
        ");
        $stmt->execute([$ip, $username]);
        $attempts = (int)$stmt->fetchColumn();

        if ($attempts >= 5) {
            return "Too many failed login attempts. Account temporarily locked for 15 minutes.";
        }
    } catch (Throwable $e) {
        error_log('Throttling check error: ' . $e->getMessage());
    }
    return null;
}

/**
 * Log admin login attempt
 */
function logLoginAttempt(?int $adminId, string $username, string $status, ?string $reason = null): void {
    try {
        $db = getDBConnection();
        ensureAdminTablesExist($db);

        $ipAddress = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
        $userAgent = substr($_SERVER['HTTP_USER_AGENT'] ?? '', 0, 500);

        $stmt = $db->prepare("
            INSERT INTO admin_login_logs (admin_id, username_attempted, ip_address, user_agent, status, failure_reason, created_at)
            VALUES (?, ?, ?, ?, ?, ?, NOW())
        ");
        $stmt->execute([$adminId, $username, $ipAddress, $userAgent, $status, $reason]);
    } catch (Throwable $e) {
        error_log('Failed to log login attempt: ' . $e->getMessage());
    }
}

/**
 * Perform admin logout and destroy session
 */
function adminLogout(?string $reason = null): void {
    if (!empty($_SESSION['admin_id'])) {
        logAdminAudit('LOGOUT', 'auth', 'admin_user', (string)$_SESSION['admin_id'], null, null, $reason ?? 'User logged out');
    }
    $_SESSION = [];
    if (ini_get("session.use_cookies")) {
        $params = session_get_cookie_params();
        setcookie(session_name(), '', time() - 42000,
            $params["path"], $params["domain"],
            $params["secure"], $params["httponly"]
        );
    }
    session_destroy();
    header('Location: login.php?logged_out=1');
    exit;
}
