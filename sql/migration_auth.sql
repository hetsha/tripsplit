-- TripBook Multi-Auth Migration
-- Adds Google login, Email OTP, and auth settings

-- 1. Add new columns to users table
ALTER TABLE `users` ADD COLUMN `google_id` VARCHAR(50) NULL AFTER `phone_verified`;
ALTER TABLE `users` ADD COLUMN `email_verified` TINYINT(1) NOT NULL DEFAULT 0 AFTER `phone_verified`;
ALTER TABLE `users` ADD COLUMN `auth_provider` ENUM('phone','google','email') NOT NULL DEFAULT 'phone' AFTER `password_hash`;

-- 2. Create email_otp_sessions table
CREATE TABLE IF NOT EXISTS `email_otp_sessions` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `email` VARCHAR(191) NOT NULL,
    `otp_code` VARCHAR(6) NOT NULL,
    `expires_at` DATETIME NOT NULL,
    `verified` TINYINT(1) NOT NULL DEFAULT 0,
    `attempts` INT NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_email` (`email`),
    INDEX `idx_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Insert auth settings (ignore if already exist)
INSERT IGNORE INTO `app_settings` (`setting_key`, `setting_value`, `setting_group`, `description`) VALUES
('auth_phone_enabled', '1', 'auth', 'Enable phone OTP login'),
('auth_google_enabled', '0', 'auth', 'Enable Google login'),
('auth_email_enabled', '0', 'auth', 'Enable email OTP login'),
('google_client_id', '', 'auth', 'Google OAuth Client ID'),
('google_client_secret', '', 'auth', 'Google OAuth Client Secret'),
('email_smtp_host', '', 'auth', 'SMTP host for email OTP'),
('email_smtp_port', '587', 'auth', 'SMTP port'),
('email_smtp_user', '', 'auth', 'SMTP username'),
('email_smtp_pass', '', 'auth', 'SMTP password'),
('email_smtp_from', '', 'auth', 'Sender email address'),
('email_smtp_encryption', 'tls', 'auth', 'SMTP encryption (tls/ssl/none)');

-- 4. Add url_token to trips for obfuscated URLs
ALTER TABLE `trips` ADD COLUMN `url_token` VARCHAR(12) NULL AFTER `trip_code`;
CREATE UNIQUE INDEX IF NOT EXISTS `idx_url_token` ON `trips` (`url_token`);
UPDATE `trips` SET `url_token` = LOWER(SUBSTRING(MD5(RAND()) FROM 1 FOR 8)) WHERE `url_token` IS NULL;
