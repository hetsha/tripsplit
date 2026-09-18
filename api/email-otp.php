<?php
/**
 * TripBook Email OTP API
 * Handles email OTP generation, sending, and verification
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/auth.php';

header('Content-Type: application/json; charset=utf-8');

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? $_POST['action'] ?? '';

$db = getDBConnection();

function getSetting(string $key, string $default = ''): string {
    $db = getDBConnection();
    $stmt = $db->prepare("SELECT setting_value FROM app_settings WHERE setting_key = ?");
    $stmt->execute([$key]);
    $row = $stmt->fetch();
    return $row ? (string)$row['setting_value'] : $default;
}

function generateOtp(): string {
    return str_pad((string)random_int(100000, 999999), 6, '0', STR_PAD_LEFT);
}

/**
 * Send OTP via email using PHP mail() with optional SMTP config
 */
function sendEmailOtp(string $email, string $otpCode): array {
    $smtpHost = getSetting('email_smtp_host');
    $smtpPort = (int)getSetting('email_smtp_port', '587');
    $smtpUser = getSetting('email_smtp_user');
    $smtpPass = getSetting('email_smtp_pass');
    $smtpFrom = getSetting('email_smtp_from');
    $encryption = getSetting('email_smtp_encryption', 'tls');

    $appName = getSetting('app_name', 'TripBook');
    $subject = "$appName - Your Verification Code";
    $message = "Your verification code is: $otpCode\n\nThis code is valid for 5 minutes.\n\nIf you didn't request this code, please ignore this email.";
    $headers = "From: " . ($smtpFrom ?: "noreply@$appName.com") . "\r\n";
    $headers .= "Reply-To: " . ($smtpFrom ?: "noreply@$appName.com") . "\r\n";
    $headers .= "Content-Type: text/plain; charset=UTF-8\r\n";

    // If SMTP is configured, use it via fsockopen
    if (!empty($smtpHost)) {
        return sendViaSmtp($email, $subject, $message, $headers, $smtpHost, $smtpPort, $smtpUser, $smtpPass, $encryption);
    }

    // Fallback to PHP mail()
    $sent = @mail($email, $subject, $message, $headers);
    if ($sent) {
        return ['success' => true, 'message' => 'OTP sent to your email'];
    }

    error_log("TripBook Email OTP: mail() failed for $email");
    return ['success' => false, 'message' => 'Failed to send email. Please try again.'];
}

/**
 * Send email via SMTP socket
 */
function sendViaSmtp(string $to, string $subject, string $body, string $headers, string $host, int $port, string $user, string $pass, string $encryption): array {
    $errno = 0;
    $errstr = '';
    
    $timeout = 10;
    $fp = @fsockopen($host, $port, $errno, $errstr, $timeout);
    
    if (!$fp) {
        error_log("TripBook Email SMTP: Connection failed to $host:$port - $errstr ($errno)");
        return ['success' => false, 'message' => 'SMTP connection failed'];
    }
    
    // Read banner
    $banner = fgets($fp, 512);
    
    // EHLO
    fputs($fp, "EHLO tripbook\r\n");
    $response = '';
    while ($line = fgets($fp, 512)) {
        $response .= $line;
        if (substr($line, 3, 1) === ' ') break;
    }
    
    // STARTTLS if needed
    if ($encryption === 'tls' && $port === 587) {
        fputs($fp, "STARTTLS\r\n");
        $response = fgets($fp, 512);
        if (strpos($response, '220') === 0) {
            stream_context_set_option($fp, 'ssl', 'verify_peer', true);
            stream_context_set_option($fp, 'ssl', 'verify_peer_name', true);
            $crypto = stream_socket_enable_crypto($fp, true, STREAM_CRYPTO_METHOD_TLSv1_2_CLIENT);
            if (!$crypto) {
                fclose($fp);
                return ['success' => false, 'message' => 'STARTTLS failed'];
            }
            // Re-EHLO after STARTTLS
            fputs($fp, "EHLO tripbook\r\n");
            while ($line = fgets($fp, 512)) {
                if (substr($line, 3, 1) === ' ') break;
            }
        }
    }
    
    // AUTH LOGIN
    fputs($fp, "AUTH LOGIN\r\n");
    fgets($fp, 512);
    fputs($fp, base64_encode($user) . "\r\n");
    fgets($fp, 512);
    fputs($fp, base64_encode($pass) . "\r\n");
    $response = fgets($fp, 512);
    if (strpos($response, '235') !== 0) {
        fclose($fp);
        error_log("TripBook Email SMTP: Auth failed - $response");
        return ['success' => false, 'message' => 'SMTP authentication failed'];
    }
    
    // MAIL FROM
    fputs($fp, "MAIL FROM:<" . ($user ?: 'noreply@tripbook.com') . ">\r\n");
    fgets($fp, 512);
    
    // RCPT TO
    fputs($fp, "RCPT TO:<$to>\r\n");
    fgets($fp, 512);
    
    // DATA
    fputs($fp, "DATA\r\n");
    fgets($fp, 512);
    fputs($fp, "Subject: $subject\r\n$headers\r\n$body\r\n.\r\n");
    fgets($fp, 512);
    
    // QUIT
    fputs($fp, "QUIT\r\n");
    fclose($fp);
    
    return ['success' => true, 'message' => 'OTP sent to your email'];
}

// POST Actions
if ($method === 'POST') {
    $input = getJsonInput();

    // Send Email OTP
    if ($action === 'send_email_otp') {
        if (getSetting('auth_email_enabled', '0') !== '1') {
            jsonError('Email login is disabled', 403);
        }

        $email = strtolower(trim((string)($input['email'] ?? '')));
        if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            jsonError('Valid email address is required', 422);
        }

        // Rate limiting (max 3 per 10 minutes)
        $stmt = $db->prepare("
            SELECT COUNT(*) as cnt FROM email_otp_sessions 
            WHERE email = ? AND created_at > DATE_SUB(NOW(), INTERVAL 10 MINUTE)
        ");
        $stmt->execute([$email]);
        $count = (int)$stmt->fetch()['cnt'];

        if ($count >= 3) {
            jsonError('Too many requests. Please try again after 10 minutes.', 429);
        }

        // Invalidate existing unverified OTPs
        $stmt = $db->prepare("UPDATE email_otp_sessions SET verified = 1 WHERE email = ? AND verified = 0");
        $stmt->execute([$email]);

        // Generate and store OTP
        $otpCode = generateOtp();
        $expiryMinutes = (int)getSetting('otp_expiry_minutes', '5');
        $expiresAt = date('Y-m-d H:i:s', time() + ($expiryMinutes * 60));

        $stmt = $db->prepare("
            INSERT INTO email_otp_sessions (email, otp_code, expires_at, verified) 
            VALUES (?, ?, ?, 0)
        ");
        $stmt->execute([$email, $otpCode, $expiresAt]);

        // Send OTP
        $sendResult = sendEmailOtp($email, $otpCode);

        if ($sendResult['success']) {
            jsonSuccess('OTP sent to your email', [
                'email' => $email,
                'expires_in' => $expiryMinutes * 60
            ]);
        } else {
            jsonError($sendResult['message'], 500);
        }
    }

    // Verify Email OTP
    if ($action === 'verify_email_otp') {
        if (getSetting('auth_email_enabled', '0') !== '1') {
            jsonError('Email login is disabled', 403);
        }

        $email = strtolower(trim((string)($input['email'] ?? '')));
        $otpCode = trim((string)($input['otp_code'] ?? ''));

        if (empty($email) || empty($otpCode)) {
            jsonError('Email and OTP code are required', 422);
        }

        // Find valid OTP session
        $stmt = $db->prepare("
            SELECT id, otp_code, expires_at, attempts 
            FROM email_otp_sessions 
            WHERE email = ? AND verified = 0 
            ORDER BY id DESC LIMIT 1
        ");
        $stmt->execute([$email]);
        $session = $stmt->fetch();

        if (!$session) {
            jsonError('No OTP found. Please request a new one.', 404);
        }

        // Check expiry
        if (strtotime($session['expires_at']) < time()) {
            jsonError('OTP has expired. Please request a new one.', 410);
        }

        // Check max attempts
        $maxAttempts = (int)getSetting('otp_max_attempts', '3');
        if ((int)$session['attempts'] >= $maxAttempts) {
            jsonError('Maximum verification attempts exceeded. Please request a new OTP.', 429);
        }

        // Increment attempts
        $stmt = $db->prepare("UPDATE email_otp_sessions SET attempts = attempts + 1 WHERE id = ?");
        $stmt->execute([$session['id']]);

        // Verify OTP
        if ($session['otp_code'] !== $otpCode) {
            jsonError('Invalid OTP code', 401);
        }

        // Mark as verified
        $stmt = $db->prepare("UPDATE email_otp_sessions SET verified = 1 WHERE id = ?");
        $stmt->execute([$session['id']]);

        // Find or create user by email
        $stmt = $db->prepare("SELECT id, name, email, phone, phone_verified, email_verified, avatar_color FROM users WHERE email = ?");
        $stmt->execute([$email]);
        $user = $stmt->fetch();

        $isNewUser = false;
        if (!$user) {
            $isNewUser = true;
            $colors = ['#2563eb', '#10b981', '#f59e0b', '#8b5cf6', '#ec4899', '#06b6d4', '#f97316'];
            $avatarColor = $colors[array_rand($colors)];
            $name = explode('@', $email)[0];

            $stmt = $db->prepare("
                INSERT INTO users (name, email, email_verified, auth_provider, password_hash, avatar_color) 
                VALUES (?, ?, 1, 'email', ?, ?)
            ");
            $stmt->execute([
                $name,
                $email,
                password_hash(bin2hex(random_bytes(16)), PASSWORD_DEFAULT),
                $avatarColor
            ]);

            $userId = (int)$db->lastInsertId();

            $stmt = $db->prepare("SELECT id, name, email, phone, phone_verified, email_verified, avatar_color FROM users WHERE id = ?");
            $stmt->execute([$userId]);
            $user = $stmt->fetch();
        } else {
            if (!$user['email_verified']) {
                $stmt = $db->prepare("UPDATE users SET email_verified = 1 WHERE id = ?");
                $stmt->execute([$user['id']]);
                $user['email_verified'] = 1;
            }
        }

        // Set session
        $_SESSION['user_id'] = (int)$user['id'];
        $_SESSION['user_name'] = $user['name'];
        $_SESSION['authenticated'] = true;

        // Get user's trips
        $tripStmt = $db->prepare("
                SELECT t.id, t.trip_code, t.url_token, t.name, t.currency_symbol, tm.role 
            FROM trips t
            JOIN trip_members tm ON tm.trip_id = t.id
            WHERE tm.user_id = ?
            ORDER BY t.created_at DESC
        ");
        $tripStmt->execute([$user['id']]);
        $trips = $tripStmt->fetchAll();

        // Set active trip
        if (!empty($trips)) {
            if (empty($_SESSION['active_trip_id'])) {
                $_SESSION['active_trip_id'] = (int)$trips[0]['id'];
            }
            $validTripIds = array_column($trips, 'id');
            if (!in_array((int)($_SESSION['active_trip_id'] ?? 0), $validTripIds)) {
                $_SESSION['active_trip_id'] = (int)$trips[0]['id'];
            }
        } else {
            unset($_SESSION['active_trip_id']);
        }

        $csrfToken = getCsrfToken();

        jsonSuccess($isNewUser ? 'Account created successfully' : 'Login successful', [
            'user' => $user,
            'csrf_token' => $csrfToken,
            'trips' => $trips,
            'active_trip' => getActiveTripId(),
            'is_new_user' => $isNewUser,
            'needs_phone' => empty($user['phone'])
        ]);
    }

    jsonError('Invalid action', 400);
}

jsonError('Method not allowed', 405);
