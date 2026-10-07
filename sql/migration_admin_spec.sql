-- TripSplit Admin Panel Migration according to Feature Specification
-- Safe execution with idempotent checks

-- 1. Upgrade admin_users table
CREATE TABLE IF NOT EXISTS `admin_users` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Audit Logs
CREATE TABLE IF NOT EXISTS `admin_audit_logs` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Login Logs
CREATE TABLE IF NOT EXISTS `admin_login_logs` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Admin Sessions
CREATE TABLE IF NOT EXISTS `admin_sessions` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `admin_id` INT UNSIGNED NOT NULL,
  `session_token` VARCHAR(128) NOT NULL,
  `ip_address` VARCHAR(45) NULL,
  `user_agent` TEXT NULL,
  `last_activity` DATETIME NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_session_token` (`session_token`),
  INDEX `idx_session_admin` (`admin_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Announcements / System Broadcasts
CREATE TABLE IF NOT EXISTS `admin_announcements` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `title` VARCHAR(200) NOT NULL,
  `message` TEXT NOT NULL,
  `type` ENUM('system', 'maintenance', 'feature', 'general') NOT NULL DEFAULT 'general',
  `target_audience` VARCHAR(50) NOT NULL DEFAULT 'all',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_announcement_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
