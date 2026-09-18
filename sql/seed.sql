-- TripBook Seed Data

-- 1. Insert Default Users
INSERT INTO `users` (`id`, `name`, `email`, `phone`, `phone_verified`, `password_hash`, `avatar_color`, `is_admin`) VALUES
(1, 'Admin', 'admin@tripbook.local', '+91 90000 00001', 1, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '#2563eb', 1),
(2, 'User 2', 'user2@example.com', '+91 90000 00002', 1, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '#10b981', 0),
(3, 'User 3', 'user3@example.com', '+91 90000 00003', 1, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '#f59e0b', 0);

-- 2. Insert Default Admin User (separate admin panel login)
INSERT INTO `admin_users` (`username`, `password_hash`, `name`) VALUES
('admin', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Administrator');

-- 3. Insert Default Global Categories with Lucide-compatible icon names
INSERT INTO `categories` (`id`, `trip_id`, `name`, `icon`, `color`, `is_default`) VALUES
(1, NULL, 'Food & Drinks', 'utensils', '#ef4444', 1),
(2, NULL, 'Hotel & Stay', 'bed', '#8b5cf6', 1),
(3, NULL, 'Travel & Flights', 'plane', '#3b82f6', 1),
(4, NULL, 'Local Transport', 'car', '#06b6d4', 1),
(5, NULL, 'Tickets & Entry', 'ticket', '#f59e0b', 1),
(6, NULL, 'Shopping', 'shopping-bag', '#ec4899', 1),
(7, NULL, 'Activities', 'camera', '#10b981', 1),
(8, NULL, 'Fuel', 'fuel', '#f97316', 1),
(9, NULL, 'Parking & Toll', 'parking', '#64748b', 1),
(10, NULL, 'General & Other', 'more-horizontal', '#6b7280', 1);

-- 4. Insert Sample Trip
INSERT INTO `trips` (`id`, `trip_code`, `name`, `description`, `starting_money`, `starting_payer_id`, `starting_payment_method`, `currency`, `currency_symbol`, `created_by`, `created_at`) VALUES
(1, 'TRIP-00001', 'Sample Trip', 'A sample trip to get started', 0.00, 1, 'cash', 'INR', '₹', 1, NOW());

-- 5. Insert Trip Members
INSERT INTO `trip_members` (`trip_id`, `user_id`, `role`, `joined_at`) VALUES
(1, 1, 'owner', NOW()),
(1, 2, 'member', NOW()),
(1, 3, 'member', NOW());

-- 6. Insert Member Accounts / Wallets
INSERT INTO `member_accounts` (`trip_id`, `user_id`, `payment_method`, `account_name`) VALUES
(1, 1, 'cash', 'Admin (Physical Cash)'),
(1, 1, 'upi', 'Admin (UPI)'),
(1, 2, 'upi', 'User 2 (UPI)'),
(1, 3, 'upi', 'User 3 (UPI)');

-- 7. Insert Default App Settings
INSERT INTO `app_settings` (`setting_key`, `setting_value`, `setting_group`, `description`) VALUES
('app_name', 'TripBook', 'general', 'Application name'),
('currency', 'INR', 'general', 'Default currency'),
('currency_symbol', '₹', 'general', 'Default currency symbol'),
('otp_api_key', '', 'otp', 'web.upparac.com API key'),
('otp_api_url', 'https://web.upparac.com/api', 'otp', 'OTP API endpoint'),
('otp_message_template', 'Your TripBook OTP is: {code}. Valid for 5 minutes.', 'otp', 'OTP message template'),
('otp_expiry_minutes', '5', 'otp', 'OTP expiry time in minutes'),
('otp_max_attempts', '3', 'otp', 'Maximum OTP verification attempts'),
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
