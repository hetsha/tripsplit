<?php
/**
 * TripSplit Admin Panel - Database Helper & Schema Auto-Sync
 */

declare(strict_types=1);

require_once __DIR__ . '/../../config/database.php';

function ensureAdminTablesExist(PDO $db): void {
    static $synced = false;
    if ($synced) return;

    try {
        // 1. Ensure admin_users has all specification columns
        $db->exec("CREATE TABLE IF NOT EXISTS `admin_users` (
            `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `username` VARCHAR(50) UNIQUE NOT NULL,
            `email` VARCHAR(191) UNIQUE NULL,
            `password_hash` VARCHAR(255) NOT NULL,
            `name` VARCHAR(100) NOT NULL,
            `role` ENUM('SUPER_ADMIN', 'ADMIN', 'SUPPORT', 'VIEWER') NOT NULL DEFAULT 'SUPER_ADMIN',
            `status` ENUM('active', 'inactive', 'suspended') NOT NULL DEFAULT 'active',
            `last_login` DATETIME DEFAULT NULL,
            `last_login_ip` VARCHAR(45) DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");

        // Safely add missing columns if table existed prior to migration
        $cols = $db->query("SHOW COLUMNS FROM admin_users")->fetchAll(PDO::FETCH_COLUMN);
        if (!in_array('email', $cols)) {
            $db->exec("ALTER TABLE admin_users ADD COLUMN `email` VARCHAR(191) UNIQUE NULL AFTER `username`");
        }
        if (!in_array('role', $cols)) {
            $db->exec("ALTER TABLE admin_users ADD COLUMN `role` ENUM('SUPER_ADMIN', 'ADMIN', 'SUPPORT', 'VIEWER') NOT NULL DEFAULT 'SUPER_ADMIN' AFTER `name`");
        }
        if (!in_array('status', $cols)) {
            $db->exec("ALTER TABLE admin_users ADD COLUMN `status` ENUM('active', 'inactive', 'suspended') NOT NULL DEFAULT 'active' AFTER `role`");
        }
        if (!in_array('last_login_ip', $cols)) {
            $db->exec("ALTER TABLE admin_users ADD COLUMN `last_login_ip` VARCHAR(45) DEFAULT NULL AFTER `last_login`");
        }

        // 2. Audit logs
        $db->exec("CREATE TABLE IF NOT EXISTS `admin_audit_logs` (
            `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `admin_id` INT UNSIGNED NULL,
            `admin_email` VARCHAR(191) NULL,
            `action` VARCHAR(100) NOT NULL,
            `module` VARCHAR(50) NOT NULL,
            `target_type` VARCHAR(50) NULL,
            `target_id` VARCHAR(50) NULL,
            `old_data` LONGTEXT NULL,
            `new_data` LONGTEXT NULL,
            `reason` VARCHAR(255) NULL,
            `ip_address` VARCHAR(45) NULL,
            `user_agent` TEXT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_admin_audit_admin` (`admin_id`),
            INDEX `idx_admin_audit_module` (`module`),
            INDEX `idx_admin_audit_action` (`action`),
            INDEX `idx_admin_audit_date` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");

        // 3. Login logs
        $db->exec("CREATE TABLE IF NOT EXISTS `admin_login_logs` (
            `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `admin_id` INT UNSIGNED NULL,
            `username_attempted` VARCHAR(100) NOT NULL,
            `ip_address` VARCHAR(45) NOT NULL,
            `user_agent` TEXT NULL,
            `status` ENUM('success', 'failed', 'locked') NOT NULL,
            `failure_reason` VARCHAR(255) NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_login_ip` (`ip_address`),
            INDEX `idx_login_user` (`username_attempted`),
            INDEX `idx_login_date` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");

        // 4. Admin sessions
        $db->exec("CREATE TABLE IF NOT EXISTS `admin_sessions` (
            `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `admin_id` INT UNSIGNED NOT NULL,
            `session_token` VARCHAR(128) NOT NULL,
            `ip_address` VARCHAR(45) NULL,
            `user_agent` TEXT NULL,
            `last_activity` DATETIME NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_session_token` (`session_token`),
            INDEX `idx_session_admin` (`admin_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");

        // 5. Admin Announcements
        $db->exec("CREATE TABLE IF NOT EXISTS `admin_announcements` (
            `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `title` VARCHAR(200) NOT NULL,
            `message` TEXT NOT NULL,
            `type` ENUM('system', 'maintenance', 'feature', 'general') NOT NULL DEFAULT 'general',
            `target_audience` VARCHAR(50) NOT NULL DEFAULT 'all',
            `is_active` TINYINT(1) NOT NULL DEFAULT 1,
            `created_by` INT UNSIGNED NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_announcement_active` (`is_active`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");

        // 6. Ensure default admin user exists
        $stmt = $db->query("SELECT COUNT(*) FROM admin_users");
        if ((int)$stmt->fetchColumn() === 0) {
            $defaultHash = password_hash('password', PASSWORD_BCRYPT);
            $ins = $db->prepare("INSERT INTO admin_users (username, email, password_hash, name, role, status) VALUES (?, ?, ?, ?, 'SUPER_ADMIN', 'active')");
            $ins->execute(['admin', 'admin@tripsplit.local', $defaultHash, 'Administrator']);
        }

        // 7. Check users table for status column
        $userCols = $db->query("SHOW COLUMNS FROM users")->fetchAll(PDO::FETCH_COLUMN);
        if (!in_array('status', $userCols)) {
            $db->exec("ALTER TABLE users ADD COLUMN `status` ENUM('active', 'suspended', 'deleted') NOT NULL DEFAULT 'active'");
        }

        // 8. Check trips table for status column
        $tripCols = $db->query("SHOW COLUMNS FROM trips")->fetchAll(PDO::FETCH_COLUMN);
        if (!in_array('status', $tripCols)) {
            $db->exec("ALTER TABLE trips ADD COLUMN `status` ENUM('active', 'completed', 'archived') NOT NULL DEFAULT 'active'");
        }

        // 9. Check categories table for active column
        $catCols = $db->query("SHOW COLUMNS FROM categories")->fetchAll(PDO::FETCH_COLUMN);
        if (!in_array('active', $catCols)) {
            $db->exec("ALTER TABLE categories ADD COLUMN `active` TINYINT(1) NOT NULL DEFAULT 1");
        }

        $synced = true;
    } catch (Throwable $e) {
        // Log or silently continue if tables already present
        error_log('Admin schema sync error: ' . $e->getMessage());
    }
}
