-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Sep 25, 2026 at 09:25 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `tripbook`
--

-- --------------------------------------------------------

--
-- Table structure for table `admin_users`
--

CREATE TABLE `admin_users` (
  `id` int(10) UNSIGNED NOT NULL,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `name` varchar(100) NOT NULL,
  `last_login` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `admin_users`
--

INSERT INTO `admin_users` (`id`, `username`, `password_hash`, `name`, `last_login`, `created_at`) VALUES
(1, 'admin', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Administrator', '2026-08-24 18:24:31', '2026-08-24 05:39:57');

-- --------------------------------------------------------

--
-- Table structure for table `app_settings`
--

CREATE TABLE `app_settings` (
  `id` int(10) UNSIGNED NOT NULL,
  `setting_key` varchar(100) NOT NULL,
  `setting_value` text DEFAULT NULL,
  `setting_group` varchar(50) NOT NULL DEFAULT 'general',
  `description` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `app_settings`
--

INSERT INTO `app_settings` (`id`, `setting_key`, `setting_value`, `setting_group`, `description`, `created_at`, `updated_at`) VALUES
(1, 'app_name', 'TripBook', 'general', 'Application name', '2026-08-24 05:39:57', '2026-08-24 05:39:57'),
(2, 'currency', 'INR', 'general', 'Default currency', '2026-08-24 05:39:57', '2026-08-24 05:39:57'),
(3, 'currency_symbol', '???', 'general', 'Default currency symbol', '2026-08-24 05:39:57', '2026-08-24 05:39:57'),
(4, 'otp_api_key', '', 'otp', 'web.upparac.com API key', '2026-08-24 05:39:57', '2026-08-24 05:39:57'),
(5, 'otp_api_url', 'https://web.upparac.com/api', 'otp', 'OTP API endpoint', '2026-08-24 05:39:57', '2026-08-24 05:39:57'),
(6, 'otp_message_template', 'Your TripBook OTP is: {code}. Valid for 5 minutes.', 'otp', 'OTP message template', '2026-08-24 05:39:57', '2026-08-24 05:39:57'),
(7, 'otp_expiry_minutes', '5', 'otp', 'OTP expiry time in minutes', '2026-08-24 05:39:57', '2026-08-24 05:39:57'),
(8, 'otp_max_attempts', '3', 'otp', 'Maximum OTP verification attempts', '2026-08-24 05:39:57', '2026-08-24 05:39:57'),
(9, 'auth_phone_enabled', '1', 'auth', 'Enable phone OTP login', '2026-08-24 05:39:57', '2026-08-24 05:39:57'),
(10, 'auth_google_enabled', '1', 'auth', 'Enable Google login', '2026-08-24 05:39:57', '2026-08-24 05:40:24'),
(11, 'auth_email_enabled', '1', 'auth', 'Enable email OTP login', '2026-08-24 05:39:57', '2026-08-24 05:44:11'),
(12, 'google_client_id', '3441332026-gispcer16grdaqhm36lnm071ilj4s1kl.apps.googleusercontent.com', 'auth', 'Google OAuth Client ID', '2026-08-24 05:39:57', '2026-08-24 05:40:24'),
(13, 'google_client_secret', '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', 'auth', 'Google OAuth Client Secret', '2026-08-24 05:39:57', '2026-08-24 05:44:37'),
(14, 'email_smtp_host', 'smtp.gmail.com', 'auth', 'SMTP host for email OTP', '2026-08-24 05:39:57', '2026-08-24 05:44:11'),
(15, 'email_smtp_port', '587', 'auth', 'SMTP port', '2026-08-24 05:39:57', '2026-08-24 05:39:57'),
(16, 'email_smtp_user', 'hetshah6312@gmail.com', 'auth', 'SMTP username', '2026-08-24 05:39:57', '2026-08-24 05:44:11'),
(17, 'email_smtp_pass', 'iwkf nmmw evcv lvhg', 'auth', 'SMTP password', '2026-08-24 05:39:57', '2026-08-24 05:44:11'),
(18, 'email_smtp_from', 'noreply@upparac.com', 'auth', 'Sender email address', '2026-08-24 05:39:57', '2026-08-24 05:44:11'),
(19, 'email_smtp_encryption', 'tls', 'auth', 'SMTP encryption (tls/ssl/none)', '2026-08-24 05:39:57', '2026-08-24 05:39:57');

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `id` int(10) UNSIGNED NOT NULL,
  `trip_id` int(10) UNSIGNED DEFAULT NULL,
  `name` varchar(50) NOT NULL,
  `icon` varchar(50) NOT NULL DEFAULT 'tag',
  `color` varchar(20) NOT NULL DEFAULT '#64748b',
  `is_default` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`id`, `trip_id`, `name`, `icon`, `color`, `is_default`, `created_at`) VALUES
(1, NULL, 'Food & Drinks', 'utensils', '#ef4444', 1, '2026-08-24 05:39:57'),
(2, NULL, 'Hotel & Stay', 'bed', '#8b5cf6', 1, '2026-08-24 05:39:57'),
(3, NULL, 'Travel & Flights', 'plane', '#3b82f6', 1, '2026-08-24 05:39:57'),
(4, NULL, 'Local Transport', 'car', '#06b6d4', 1, '2026-08-24 05:39:57'),
(5, NULL, 'Tickets & Entry', 'ticket', '#f59e0b', 1, '2026-08-24 05:39:57'),
(6, NULL, 'Shopping', 'shopping-bag', '#ec4899', 1, '2026-08-24 05:39:57'),
(7, NULL, 'Activities', 'camera', '#10b981', 1, '2026-08-24 05:39:57'),
(8, NULL, 'Fuel', 'fuel', '#f97316', 1, '2026-08-24 05:39:57'),
(9, NULL, 'Parking & Toll', 'parking', '#64748b', 1, '2026-08-24 05:39:57'),
(10, NULL, 'General & Other', 'more-horizontal', '#6b7280', 1, '2026-08-24 05:39:57');

-- --------------------------------------------------------

--
-- Table structure for table `email_otp_sessions`
--

CREATE TABLE `email_otp_sessions` (
  `id` int(10) UNSIGNED NOT NULL,
  `email` varchar(191) NOT NULL,
  `otp_code` varchar(6) NOT NULL,
  `expires_at` datetime NOT NULL,
  `verified` tinyint(1) NOT NULL DEFAULT 0,
  `attempts` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `email_otp_sessions`
--

INSERT INTO `email_otp_sessions` (`id`, `email`, `otp_code`, `expires_at`, `verified`, `attempts`, `created_at`) VALUES
(1, 'hetshah6312@gmail.com', '439432', '2026-08-24 12:51:11', 1, 1, '2026-08-24 10:46:11'),
(2, 'upparactechnology@gmail.com', '770529', '2026-08-25 11:34:56', 0, 0, '2026-08-25 09:29:56');

-- --------------------------------------------------------

--
-- Table structure for table `expense_splits`
--

CREATE TABLE `expense_splits` (
  `id` int(10) UNSIGNED NOT NULL,
  `transaction_id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `expense_splits`
--

INSERT INTO `expense_splits` (`id`, `transaction_id`, `user_id`, `amount`, `created_at`) VALUES
(3, 7, 4, 50.00, '2026-08-24 10:02:54'),
(4, 7, 6, 50.00, '2026-08-24 10:02:54'),
(5, 8, 4, 100.00, '2026-08-24 10:30:09'),
(6, 8, 6, 100.00, '2026-08-24 10:30:09'),
(7, 9, 4, 250.00, '2026-08-24 10:30:47'),
(8, 9, 6, 250.00, '2026-08-24 10:30:47'),
(9, 10, 4, 150.00, '2026-08-24 10:31:32'),
(10, 10, 6, 150.00, '2026-08-24 10:31:32'),
(11, 11, 4, 100.00, '2026-08-24 10:40:26'),
(12, 11, 6, 100.00, '2026-08-24 10:40:26'),
(13, 12, 4, 100.00, '2026-08-24 10:40:46'),
(14, 12, 6, 100.00, '2026-08-24 10:40:46'),
(15, 14, 4, 100.00, '2026-08-25 09:31:10'),
(16, 14, 6, 100.00, '2026-08-25 09:31:10'),
(17, 15, 4, 50.00, '2026-08-25 09:40:06'),
(18, 15, 6, 50.00, '2026-08-25 09:40:06');

-- --------------------------------------------------------

--
-- Table structure for table `member_accounts`
--

CREATE TABLE `member_accounts` (
  `id` int(10) UNSIGNED NOT NULL,
  `trip_id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `payment_method` enum('cash','upi','card','bank','other') NOT NULL DEFAULT 'upi',
  `account_name` varchar(100) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `member_accounts`
--

INSERT INTO `member_accounts` (`id`, `trip_id`, `user_id`, `payment_method`, `account_name`, `created_at`) VALUES
(1, 1, 1, 'cash', 'Admin (Physical Cash)', '2026-08-24 05:39:57'),
(2, 1, 1, 'upi', 'Admin (UPI)', '2026-08-24 05:39:57'),
(3, 1, 2, 'upi', 'User 2 (UPI)', '2026-08-24 05:39:57'),
(4, 1, 3, 'upi', 'User 3 (UPI)', '2026-08-24 05:39:57');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` int(10) UNSIGNED NOT NULL,
  `trip_id` int(10) UNSIGNED NOT NULL,
  `type` varchar(50) NOT NULL,
  `message` text NOT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `trip_id`, `type`, `message`, `is_read`, `created_at`) VALUES
(1, 2, 'member_joined', 'upparac joined the trip', 1, '2026-08-24 12:57:57'),
(2, 2, 'expense_added', 'upparac added \"dinner\" for ₹100.00', 0, '2026-08-24 15:32:54'),
(3, 2, 'settlement_made', 'upparac paid upparac ₹50.00', 0, '2026-08-24 15:47:58'),
(4, 2, 'expense_added', 'E-22 Het shah added \"train\" for ₹200.00', 0, '2026-08-24 16:00:09'),
(5, 2, 'expense_added', 'upparac added \"dinner\" for ₹500.00', 0, '2026-08-24 16:00:47'),
(6, 2, 'expense_added', 'E-22 Het shah added \"advance hotel payment\" for ₹300.00', 0, '2026-08-24 16:01:32'),
(7, 2, 'member_joined', 'upparac added het to the trip', 0, '2026-08-24 16:07:51'),
(8, 2, 'member_joined', 'upparac added het to the trip', 0, '2026-08-24 16:07:51'),
(9, 2, 'expense_added', 'E-22 Het shah added \"advance hotel payment\" for ₹200.00', 0, '2026-08-24 16:10:26'),
(10, 2, 'expense_added', 'upparac added \"dinner\" for ₹200.00', 0, '2026-08-24 16:10:46'),
(11, 2, 'expense_added', 'E-22 Het shah added \"test\" for ₹200.00', 0, '2026-08-25 15:01:10'),
(12, 2, 'expense_added', 'E-22 Het shah added \"test 2\" for ₹100.00', 0, '2026-08-25 15:10:06');

-- --------------------------------------------------------

--
-- Table structure for table `otp_sessions`
--

CREATE TABLE `otp_sessions` (
  `id` int(10) UNSIGNED NOT NULL,
  `phone` varchar(30) NOT NULL,
  `otp_code` varchar(6) NOT NULL,
  `expires_at` datetime NOT NULL,
  `verified` tinyint(1) NOT NULL DEFAULT 0,
  `attempts` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `otp_sessions`
--

INSERT INTO `otp_sessions` (`id`, `phone`, `otp_code`, `expires_at`, `verified`, `attempts`, `created_at`) VALUES
(1, '+919427961426', '604850', '2026-08-24 09:29:30', 1, 1, '2026-08-24 07:24:30'),
(2, '+919313457713', '687048', '2026-08-24 09:32:38', 1, 1, '2026-08-24 07:27:38'),
(3, '+919313457713', '128174', '2026-08-24 10:14:42', 1, 1, '2026-08-24 08:09:42'),
(4, '+919427961426', '560253', '2026-08-24 14:38:52', 1, 1, '2026-08-24 12:33:52'),
(5, '+919313457713', '697227', '2026-08-25 11:35:11', 0, 0, '2026-08-25 09:30:11');

-- --------------------------------------------------------

--
-- Table structure for table `settlements`
--

CREATE TABLE `settlements` (
  `id` int(10) UNSIGNED NOT NULL,
  `trip_id` int(10) UNSIGNED NOT NULL,
  `transaction_id` int(10) UNSIGNED DEFAULT NULL,
  `from_user` int(10) UNSIGNED NOT NULL,
  `to_user` int(10) UNSIGNED NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `payment_method` enum('cash','upi','card','bank','other') NOT NULL DEFAULT 'upi',
  `status` enum('pending','paid') NOT NULL DEFAULT 'paid',
  `notes` text DEFAULT NULL,
  `paid_at` datetime NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `settlements`
--

INSERT INTO `settlements` (`id`, `trip_id`, `transaction_id`, `from_user`, `to_user`, `amount`, `payment_method`, `status`, `notes`, `paid_at`, `created_at`) VALUES
(1, 2, NULL, 4, 6, 50.00, 'cash', 'paid', NULL, '2026-08-24 12:17:58', '2026-08-24 10:17:58');

-- --------------------------------------------------------

--
-- Table structure for table `transactions`
--

CREATE TABLE `transactions` (
  `id` int(10) UNSIGNED NOT NULL,
  `trip_id` int(10) UNSIGNED DEFAULT NULL,
  `type` enum('expense','income','settlement') NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `description` varchar(255) NOT NULL,
  `category_id` int(10) UNSIGNED DEFAULT NULL,
  `paid_by` int(10) UNSIGNED DEFAULT NULL,
  `received_by` int(10) UNSIGNED DEFAULT NULL,
  `payment_method` enum('cash','upi','card','bank','other') NOT NULL DEFAULT 'cash',
  `paid_from_pool` tinyint(1) NOT NULL DEFAULT 1,
  `created_by` int(10) UNSIGNED NOT NULL,
  `transaction_date` datetime NOT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `transactions`
--

INSERT INTO `transactions` (`id`, `trip_id`, `type`, `amount`, `description`, `category_id`, `paid_by`, `received_by`, `payment_method`, `paid_from_pool`, `created_by`, `transaction_date`, `notes`, `created_at`, `updated_at`) VALUES
(3, NULL, 'income', 2000.00, 'cash', NULL, NULL, 6, 'cash', 0, 6, '2026-08-24 14:22:22', NULL, '2026-08-24 08:52:22', '2026-08-24 08:52:22'),
(4, NULL, 'income', 2000.00, 'cash', NULL, NULL, 6, 'cash', 0, 6, '2026-08-24 14:30:05', NULL, '2026-08-24 09:00:05', '2026-08-24 09:00:05'),
(5, NULL, 'income', 2000.00, 'cash', NULL, NULL, 4, 'cash', 0, 4, '2026-08-24 14:42:51', NULL, '2026-08-24 09:12:51', '2026-08-24 09:12:51'),
(7, 2, 'expense', 100.00, 'dinner', 1, 6, NULL, 'cash', 1, 6, '2026-08-24 12:02:54', NULL, '2026-08-24 10:02:54', '2026-08-24 10:02:54'),
(8, 2, 'expense', 200.00, 'train', 1, 4, NULL, 'cash', 1, 4, '2026-08-24 12:30:09', NULL, '2026-08-24 10:30:09', '2026-08-24 10:30:09'),
(9, 2, 'expense', 500.00, 'dinner', 1, 6, NULL, 'cash', 1, 6, '2026-08-24 12:30:47', NULL, '2026-08-24 10:30:47', '2026-08-24 10:30:47'),
(10, 2, 'expense', 300.00, 'advance hotel payment', 1, 4, NULL, 'cash', 1, 4, '2026-08-24 12:31:32', NULL, '2026-08-24 10:31:32', '2026-08-24 10:31:32'),
(11, 2, 'expense', 200.00, 'advance hotel payment', 1, 4, NULL, 'cash', 1, 4, '2026-08-24 12:40:26', NULL, '2026-08-24 10:40:26', '2026-08-24 10:40:26'),
(12, 2, 'expense', 200.00, 'dinner', 1, 6, NULL, 'cash', 1, 6, '2026-08-24 12:40:46', NULL, '2026-08-24 10:40:46', '2026-08-24 10:40:46'),
(13, NULL, 'expense', 10.00, 'car', 1, 6, NULL, 'cash', 0, 6, '2026-08-24 12:46:52', NULL, '2026-08-24 10:46:52', '2026-08-24 10:46:52'),
(14, 2, 'expense', 200.00, 'test', 1, 4, NULL, 'cash', 1, 4, '2026-08-25 11:31:10', NULL, '2026-08-25 09:31:10', '2026-08-25 09:31:10'),
(15, 2, 'expense', 100.00, 'test 2', 1, 4, NULL, 'cash', 1, 4, '2026-08-25 11:40:06', NULL, '2026-08-25 09:40:06', '2026-08-25 09:40:06');

-- --------------------------------------------------------

--
-- Table structure for table `trips`
--

CREATE TABLE `trips` (
  `id` int(10) UNSIGNED NOT NULL,
  `trip_code` varchar(20) NOT NULL,
  `url_token` varchar(12) DEFAULT NULL,
  `name` varchar(150) NOT NULL,
  `description` text DEFAULT NULL,
  `starting_money` decimal(12,2) NOT NULL DEFAULT 0.00,
  `starting_payer_id` int(10) UNSIGNED DEFAULT NULL,
  `starting_payment_method` enum('cash','upi','card','bank','other') NOT NULL DEFAULT 'cash',
  `currency` varchar(10) NOT NULL DEFAULT 'INR',
  `currency_symbol` varchar(5) NOT NULL DEFAULT '???',
  `created_by` int(10) UNSIGNED NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `trips`
--

INSERT INTO `trips` (`id`, `trip_code`, `url_token`, `name`, `description`, `starting_money`, `starting_payer_id`, `starting_payment_method`, `currency`, `currency_symbol`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'TRIP-00001', '1a202ac7', 'Sample Trip', 'A sample trip to get started', 0.00, 1, 'cash', 'INR', '???', 1, '2026-08-24 05:39:57', '2026-08-24 07:33:02'),
(2, 'TRIP-DXQAT', '6f408239', 'udaipur', NULL, 0.00, 4, 'cash', 'INR', '₹', 4, '2026-08-24 05:45:21', '2026-08-24 07:33:02'),
(3, 'TRIP-A4HYJ', '2c8da51a', 'te', NULL, 0.00, 4, 'cash', 'INR', '₹', 4, '2026-08-25 13:29:25', '2026-08-25 13:29:25');

-- --------------------------------------------------------

--
-- Table structure for table `trip_members`
--

CREATE TABLE `trip_members` (
  `id` int(10) UNSIGNED NOT NULL,
  `trip_id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `role` enum('owner','admin','member') NOT NULL DEFAULT 'member',
  `joined_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `trip_members`
--

INSERT INTO `trip_members` (`id`, `trip_id`, `user_id`, `role`, `joined_at`) VALUES
(1, 1, 1, 'owner', '2026-08-24 05:39:57'),
(2, 1, 2, 'member', '2026-08-24 05:39:57'),
(3, 1, 3, 'member', '2026-08-24 05:39:57'),
(4, 2, 4, 'owner', '2026-08-24 05:45:21'),
(5, 2, 6, 'member', '2026-08-24 07:27:57'),
(8, 3, 4, 'owner', '2026-08-25 13:29:25');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(191) DEFAULT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `phone_verified` tinyint(1) NOT NULL DEFAULT 0,
  `email_verified` tinyint(1) NOT NULL DEFAULT 0,
  `google_id` varchar(50) DEFAULT NULL,
  `auth_provider` enum('phone','google','email') NOT NULL DEFAULT 'phone',
  `password_hash` varchar(255) NOT NULL,
  `avatar_color` varchar(20) DEFAULT '#2563eb',
  `is_admin` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `phone`, `phone_verified`, `email_verified`, `google_id`, `auth_provider`, `password_hash`, `avatar_color`, `is_admin`, `created_at`) VALUES
(1, 'Admin', 'admin@tripbook.local', '+91 90000 00001', 1, 0, NULL, 'phone', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '#2563eb', 1, '2026-08-24 05:39:57'),
(2, 'User 2', 'user2@example.com', '+91 90000 00002', 1, 0, NULL, 'phone', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '#10b981', 0, '2026-08-24 05:39:57'),
(3, 'User 3', 'user3@example.com', '+91 90000 00003', 1, 0, NULL, 'phone', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '#f59e0b', 0, '2026-08-24 05:39:57'),
(4, 'E-22 Het shah', 'hetshah6312@gmail.com', '+919427961426', 1, 1, '114360233750934876131', 'google', '$2y$10$KGfRxShmN403V6symJEPDOnthB0M/RcK1PbPwc1yfd618WbDNYPM6', '#ec4899', 0, '2026-08-24 05:45:06'),
(5, 'het shah', 'hetshah6311@gmail.com', NULL, 0, 1, '103624471560079568248', 'google', '$2y$10$bRxrjnsl2fFQM00BOUuWiO5b6/gkcN.lakDtife4nVPA6cP6pyHR2', '#10b981', 0, '2026-08-24 07:20:51'),
(6, 'upparac', 'upparactechnology@gmail.com', '+919313457713', 1, 1, '101496448878097348434', 'google', '$2y$10$jSPHN8XFCx8bRdn66RptjOWUt0A.OfbfFqHO3kw3Slo0Y4KBYqvrG', '#ec4899', 0, '2026-08-24 07:27:33'),
(7, 'het', NULL, NULL, 0, 0, NULL, 'phone', '$2y$10$OdPm73zpqN/6PIGsHnoWCOYy4O/HM7BiPQTkQHjgmhn0xVGODf13S', '#f59e0b', 0, '2026-08-24 10:37:51');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admin_users`
--
ALTER TABLE `admin_users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Indexes for table `app_settings`
--
ALTER TABLE `app_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `setting_key` (`setting_key`);

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD KEY `trip_id` (`trip_id`);

--
-- Indexes for table `email_otp_sessions`
--
ALTER TABLE `email_otp_sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_email` (`email`),
  ADD KEY `idx_expires_email` (`expires_at`);

--
-- Indexes for table `expense_splits`
--
ALTER TABLE `expense_splits`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_split` (`transaction_id`,`user_id`),
  ADD KEY `idx_splits_trans` (`transaction_id`),
  ADD KEY `idx_splits_user` (`user_id`);

--
-- Indexes for table `member_accounts`
--
ALTER TABLE `member_accounts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `trip_id` (`trip_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_trip` (`trip_id`),
  ADD KEY `idx_read` (`is_read`);

--
-- Indexes for table `otp_sessions`
--
ALTER TABLE `otp_sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_phone` (`phone`),
  ADD KEY `idx_expires` (`expires_at`);

--
-- Indexes for table `settlements`
--
ALTER TABLE `settlements`
  ADD PRIMARY KEY (`id`),
  ADD KEY `transaction_id` (`transaction_id`),
  ADD KEY `to_user` (`to_user`),
  ADD KEY `idx_settlements_trip` (`trip_id`),
  ADD KEY `idx_settlements_users` (`from_user`,`to_user`);

--
-- Indexes for table `transactions`
--
ALTER TABLE `transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `category_id` (`category_id`),
  ADD KEY `paid_by` (`paid_by`),
  ADD KEY `received_by` (`received_by`),
  ADD KEY `idx_transactions_trip` (`trip_id`,`transaction_date`),
  ADD KEY `idx_transactions_user` (`created_by`,`transaction_date`),
  ADD KEY `idx_transactions_type` (`type`);

--
-- Indexes for table `trips`
--
ALTER TABLE `trips`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `trip_code` (`trip_code`),
  ADD UNIQUE KEY `idx_url_token` (`url_token`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `starting_payer_id` (`starting_payer_id`);

--
-- Indexes for table `trip_members`
--
ALTER TABLE `trip_members`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_trip_user` (`trip_id`,`user_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `phone` (`phone`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admin_users`
--
ALTER TABLE `admin_users`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `app_settings`
--
ALTER TABLE `app_settings`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=53;

--
-- AUTO_INCREMENT for table `categories`
--
ALTER TABLE `categories`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `email_otp_sessions`
--
ALTER TABLE `email_otp_sessions`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `expense_splits`
--
ALTER TABLE `expense_splits`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT for table `member_accounts`
--
ALTER TABLE `member_accounts`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `otp_sessions`
--
ALTER TABLE `otp_sessions`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `settlements`
--
ALTER TABLE `settlements`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `transactions`
--
ALTER TABLE `transactions`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `trips`
--
ALTER TABLE `trips`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `trip_members`
--
ALTER TABLE `trip_members`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `categories`
--
ALTER TABLE `categories`
  ADD CONSTRAINT `categories_ibfk_1` FOREIGN KEY (`trip_id`) REFERENCES `trips` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `expense_splits`
--
ALTER TABLE `expense_splits`
  ADD CONSTRAINT `expense_splits_ibfk_1` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `expense_splits_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `member_accounts`
--
ALTER TABLE `member_accounts`
  ADD CONSTRAINT `member_accounts_ibfk_1` FOREIGN KEY (`trip_id`) REFERENCES `trips` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `member_accounts_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`trip_id`) REFERENCES `trips` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `settlements`
--
ALTER TABLE `settlements`
  ADD CONSTRAINT `settlements_ibfk_1` FOREIGN KEY (`trip_id`) REFERENCES `trips` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `settlements_ibfk_2` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `settlements_ibfk_3` FOREIGN KEY (`from_user`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `settlements_ibfk_4` FOREIGN KEY (`to_user`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `transactions`
--
ALTER TABLE `transactions`
  ADD CONSTRAINT `transactions_ibfk_1` FOREIGN KEY (`trip_id`) REFERENCES `trips` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `transactions_ibfk_2` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `transactions_ibfk_3` FOREIGN KEY (`paid_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `transactions_ibfk_4` FOREIGN KEY (`received_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `transactions_ibfk_5` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `trips`
--
ALTER TABLE `trips`
  ADD CONSTRAINT `trips_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `trips_ibfk_2` FOREIGN KEY (`starting_payer_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `trip_members`
--
ALTER TABLE `trip_members`
  ADD CONSTRAINT `trip_members_ibfk_1` FOREIGN KEY (`trip_id`) REFERENCES `trips` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `trip_members_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
