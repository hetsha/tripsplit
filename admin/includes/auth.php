<?php
/**
 * TripBook Admin Panel - Authentication
 */

declare(strict_types=1);

// Start session if not already started
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

/**
 * Check if admin is authenticated
 */
function isAdminAuthenticated(): bool {
    return !empty($_SESSION['admin_id']) && !empty($_SESSION['admin_username']);
}

/**
 * Require admin authentication
 */
function requireAdminAuth(): void {
    if (!isAdminAuthenticated()) {
        header('Location: login.php');
        exit;
    }
}

/**
 * Get current admin info
 */
function getCurrentAdmin(): array {
    return [
        'id' => $_SESSION['admin_id'] ?? 0,
        'username' => $_SESSION['admin_username'] ?? '',
        'name' => $_SESSION['admin_name'] ?? 'Admin'
    ];
}

/**
 * Logout admin
 */
function adminLogout(): void {
    unset($_SESSION['admin_id'], $_SESSION['admin_username'], $_SESSION['admin_name']);
    header('Location: login.php');
    exit;
}
