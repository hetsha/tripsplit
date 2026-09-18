-- TripBook Database Schema
-- MySQL 5.7+ / 8.0+ Compatible

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `expense_splits`;
DROP TABLE IF EXISTS `settlements`;
DROP TABLE IF EXISTS `transactions`;
DROP TABLE IF EXISTS `categories`;
DROP TABLE IF EXISTS `member_accounts`;
DROP TABLE IF EXISTS `trip_members`;
DROP TABLE IF EXISTS `trips`;
DROP TABLE IF EXISTS `otp_sessions`;
DROP TABLE IF EXISTS `email_otp_sessions`;
DROP TABLE IF EXISTS `app_settings`;
DROP TABLE IF EXISTS `admin_users`;
DROP TABLE IF EXISTS `users`;

SET FOREIGN_KEY_CHECKS = 1;

-- 1. Users Table
CREATE TABLE `users` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `email` VARCHAR(191) UNIQUE NULL,
    `phone` VARCHAR(30) UNIQUE NULL,
    `phone_verified` TINYINT(1) NOT NULL DEFAULT 0,
    `email_verified` TINYINT(1) NOT NULL DEFAULT 0,
    `google_id` VARCHAR(50) NULL,
    `auth_provider` ENUM('phone','google','email') NOT NULL DEFAULT 'phone',
    `password_hash` VARCHAR(255) NOT NULL,
    `avatar_color` VARCHAR(20) DEFAULT '#2563eb',
    `is_admin` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Trips Table
CREATE TABLE `trips` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_code` VARCHAR(20) UNIQUE NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    `description` TEXT NULL,
    `starting_money` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `starting_payer_id` INT UNSIGNED NULL,
    `starting_payment_method` ENUM('cash', 'upi', 'card', 'bank', 'other') NOT NULL DEFAULT 'cash',
    `currency` VARCHAR(10) NOT NULL DEFAULT 'INR',
    `currency_symbol` VARCHAR(5) NOT NULL DEFAULT '₹',
    `created_by` INT UNSIGNED NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`starting_payer_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    
-- 3. Trip Members Table
CREATE TABLE `trip_members` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` INT UNSIGNED NOT NULL,
    `user_id` INT UNSIGNED NOT NULL,
    `role` ENUM('owner', 'admin', 'member') NOT NULL DEFAULT 'member',
    `joined_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_trip_user` (`trip_id`, `user_id`),
    FOREIGN KEY (`trip_id`) REFERENCES `trips`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Member Accounts / Wallets Table
CREATE TABLE `member_accounts` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` INT UNSIGNED NOT NULL,
    `user_id` INT UNSIGNED NOT NULL,
    `payment_method` ENUM('cash', 'upi', 'card', 'bank', 'other') NOT NULL DEFAULT 'upi',
    `account_name` VARCHAR(100) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`trip_id`) REFERENCES `trips`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Categories Table
CREATE TABLE `categories` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` INT UNSIGNED NULL,
    `name` VARCHAR(50) NOT NULL,
    `icon` VARCHAR(50) NOT NULL DEFAULT 'tag',
    `color` VARCHAR(20) NOT NULL DEFAULT '#64748b',
    `is_default` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`trip_id`) REFERENCES `trips`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Transactions Table (CashBook & Splitwise)
CREATE TABLE `transactions` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` INT UNSIGNED NULL,
    `type` ENUM('expense', 'income', 'settlement') NOT NULL,
    `amount` DECIMAL(12,2) NOT NULL,
    `description` VARCHAR(255) NOT NULL,
    `category_id` INT UNSIGNED NULL,
    `paid_by` INT UNSIGNED NULL,
    `received_by` INT UNSIGNED NULL,
    `payment_method` ENUM('cash', 'bank') NOT NULL DEFAULT 'cash',
    `paid_from_pool` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` INT UNSIGNED NOT NULL,
    `transaction_date` DATETIME NOT NULL,
    `notes` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`trip_id`) REFERENCES `trips`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`category_id`) REFERENCES `categories`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`paid_by`) REFERENCES `users`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`received_by`) REFERENCES `users`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. Expense Splits Table (Splitwise beneficiary shares)
CREATE TABLE `expense_splits` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `transaction_id` INT UNSIGNED NOT NULL,
    `user_id` INT UNSIGNED NOT NULL,
    `amount` DECIMAL(12,2) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_split` (`transaction_id`, `user_id`),
    FOREIGN KEY (`transaction_id`) REFERENCES `transactions`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. Settlements Table (Tracks person-to-person debt clearance)
CREATE TABLE `settlements` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` INT UNSIGNED NOT NULL,
    `transaction_id` INT UNSIGNED NULL,
    `from_user` INT UNSIGNED NOT NULL,
    `to_user` INT UNSIGNED NOT NULL,
    `amount` DECIMAL(12,2) NOT NULL,
    `payment_method` ENUM('cash', 'upi', 'card', 'bank', 'other') NOT NULL DEFAULT 'upi',
    `status` ENUM('pending', 'paid') NOT NULL DEFAULT 'paid',
    `notes` TEXT NULL,
    `paid_at` DATETIME NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`trip_id`) REFERENCES `trips`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`transaction_id`) REFERENCES `transactions`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`from_user`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`to_user`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. Notifications Table
CREATE TABLE `notifications` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` INT UNSIGNED NOT NULL,
    `type` VARCHAR(50) NOT NULL,
    `message` TEXT NOT NULL,
    `is_read` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_trip` (`trip_id`),
    INDEX `idx_read` (`is_read`),
    FOREIGN KEY (`trip_id`) REFERENCES `trips`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. OTP Sessions Table
CREATE TABLE `otp_sessions` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `phone` VARCHAR(30) NOT NULL,
    `otp_code` VARCHAR(6) NOT NULL,
    `expires_at` DATETIME NOT NULL,
    `verified` TINYINT(1) NOT NULL DEFAULT 0,
    `attempts` INT NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_phone` (`phone`),
    INDEX `idx_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 12. Email OTP Sessions Table
CREATE TABLE `email_otp_sessions` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `email` VARCHAR(191) NOT NULL,
    `otp_code` VARCHAR(6) NOT NULL,
    `expires_at` DATETIME NOT NULL,
    `verified` TINYINT(1) NOT NULL DEFAULT 0,
    `attempts` INT NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_email` (`email`),
    INDEX `idx_expires_email` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 12. App Settings Table
CREATE TABLE `app_settings` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `setting_key` VARCHAR(100) UNIQUE NOT NULL,
    `setting_value` TEXT,
    `setting_group` VARCHAR(50) NOT NULL DEFAULT 'general',
    `description` VARCHAR(255),
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 13. Admin Users Table (separate from regular users)
CREATE TABLE `admin_users` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(50) UNIQUE NOT NULL,
    `password_hash` VARCHAR(255) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `last_login` DATETIME,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes for optimal performance
CREATE INDEX `idx_transactions_trip` ON `transactions` (`trip_id`, `transaction_date`);
CREATE INDEX `idx_transactions_user` ON `transactions` (`created_by`, `transaction_date`);
CREATE INDEX `idx_transactions_type` ON `transactions` (`type`);
CREATE INDEX `idx_splits_trans` ON `expense_splits` (`transaction_id`);
CREATE INDEX `idx_splits_user` ON `expense_splits` (`user_id`);
CREATE INDEX `idx_settlements_trip` ON `settlements` (`trip_id`);
CREATE INDEX `idx_settlements_users` ON `settlements` (`from_user`, `to_user`);
