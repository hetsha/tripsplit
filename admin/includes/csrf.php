<?php
/**
 * TripSplit Admin Panel - CSRF Protection
 * Section 43 & Section 76 Rule 7
 */

declare(strict_types=1);

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

/**
 * Generate or retrieve current CSRF token
 */
function getCsrfToken(): string {
    if (empty($_SESSION['admin_csrf_token'])) {
        $_SESSION['admin_csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['admin_csrf_token'];
}

/**
 * Output hidden CSRF form input field
 */
function csrfField(): string {
    $token = htmlspecialchars(getCsrfToken(), ENT_QUOTES, 'UTF-8');
    return '<input type="hidden" name="csrf_token" value="' . $token . '">';
}

/**
 * Verify CSRF token from request
 */
function verifyCsrfToken(?string $token = null): bool {
    $expected = $_SESSION['admin_csrf_token'] ?? '';
    if (empty($expected)) {
        return false;
    }
    $provided = $token ?? ($_POST['csrf_token'] ?? ($_SERVER['HTTP_X_CSRF_TOKEN'] ?? ''));
    return hash_equals($expected, (string)$provided);
}

/**
 * Require valid CSRF token on POST requests or terminate with 403
 */
function requireCsrfToken(): void {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        if (!verifyCsrfToken()) {
            http_response_code(403);
            die('<!DOCTYPE html><html><head><title>CSRF Error</title><link rel="stylesheet" href="assets/style.css"></head><body style="padding:40px;text-align:center;"><h2>403 - Invalid or Expired CSRF Token</h2><p>Please refresh the page and try again.</p><p><a href="javascript:history.back()">Go Back</a></p></body></html>');
        }
    }
}
