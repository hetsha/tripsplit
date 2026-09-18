<?php
/**
 * TripBook OTP API
 * Handles OTP generation, sending, and verification
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/auth.php';

header('Content-Type: application/json; charset=utf-8');

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? $_POST['action'] ?? '';

$db = getDBConnection();

/**
 * Get app setting value
 */
function getSetting(string $key, string $default = ''): string {
    $db = getDBConnection();
    $stmt = $db->prepare("SELECT setting_value FROM app_settings WHERE setting_key = ?");
    $stmt->execute([$key]);
    $row = $stmt->fetch();
    return $row ? (string)$row['setting_value'] : $default;
}

/**
 * Generate 6-digit OTP
 */
function generateOtp(): string {
    return str_pad((string)random_int(100000, 999999), 6, '0', STR_PAD_LEFT);
}

/**
 * Send OTP via web.upparac.com API
 */
function sendOtpSms(string $phone, string $otpCode): array {
    $apiKey = getSetting('otp_api_key');
    $apiUrl = getSetting('otp_api_url', 'https://web.upparac.com/api');
    $template = getSetting('otp_message_template', 'Your TripBook OTP is: {code}. Valid for 5 minutes.');
    
    $message = str_replace('{code}', $otpCode, $template);
    
    // If no API key configured, simulate sending (log to console)
    if (empty($apiKey)) {
        error_log("TripBook OTP Simulation - Phone: $phone, OTP: $otpCode");
        return [
            'success' => true,
            'message' => 'OTP sent successfully (simulated)',
            'simulated' => true
        ];
    }
    
    // Send via web.upparac.com API
    $ch = curl_init($apiUrl);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'phone' => $phone,
        'message' => $message
    ]));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        "Authorization: Bearer $apiKey"
    ]);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    
    $rawResponse = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);
    
    if ($rawResponse === false) {
        error_log("TripBook OTP cURL error: $curlError");
        return ['success' => false, 'message' => 'Network error: ' . $curlError];
    }
    
    $response = json_decode($rawResponse, true);
    
    if ($httpCode >= 200 && $httpCode < 300 && isset($response['success']) && $response['success']) {
        return ['success' => true, 'message' => 'OTP sent successfully'];
    }
    
    $errorMsg = $response['message'] ?? $response['error'] ?? "API returned HTTP $httpCode";
    error_log("TripBook OTP API error ($httpCode): $errorMsg");
    return ['success' => false, 'message' => $errorMsg];
}

// POST Actions
if ($method === 'POST') {
    $input = getJsonInput();
    
    // Send OTP
    if ($action === 'send_otp') {
        if (getSetting('auth_phone_enabled', '1') !== '1') {
            jsonError('Phone login is disabled', 403);
        }

        $phone = trim((string)($input['phone'] ?? ''));
        
        if (empty($phone)) {
            jsonError('Phone number is required', 422);
        }
        
        // Normalize phone number (remove spaces, dashes)
        $phone = preg_replace('/[\s\-\(\)]/', '', $phone);
        
        // Ensure starts with country code
        if (strlen($phone) === 10) {
            $phone = '+91' . $phone;
        } elseif (strlen($phone) === 12 && substr($phone, 0, 2) === '91') {
            $phone = '+' . $phone;
        }
        
        // Validate phone format
        if (!preg_match('/^\+[1-9]\d{6,14}$/', $phone)) {
            jsonError('Invalid phone number format', 422);
        }
        
        // Check rate limiting (max 3 OTPs per phone per 10 minutes)
        $stmt = $db->prepare("
            SELECT COUNT(*) as cnt FROM otp_sessions 
            WHERE phone = ? AND created_at > DATE_SUB(NOW(), INTERVAL 10 MINUTE)
        ");
        $stmt->execute([$phone]);
        $count = (int)$stmt->fetch()['cnt'];
        
        if ($count >= 3) {
            jsonError('Too many OTP requests. Please try again after 10 minutes.', 429);
        }
        
        // Invalidate any existing unverified OTPs for this phone
        $stmt = $db->prepare("UPDATE otp_sessions SET verified = 1 WHERE phone = ? AND verified = 0");
        $stmt->execute([$phone]);
        
        // Generate and store OTP
        $otpCode = generateOtp();
        $expiryMinutes = (int)getSetting('otp_expiry_minutes', '5');
        $expiresAt = date('Y-m-d H:i:s', time() + ($expiryMinutes * 60));
        
        $stmt = $db->prepare("
            INSERT INTO otp_sessions (phone, otp_code, expires_at, verified) 
            VALUES (?, ?, ?, 0)
        ");
        $stmt->execute([$phone, $otpCode, $expiresAt]);
        
        // Send OTP
        $sendResult = sendOtpSms($phone, $otpCode);
        
        if ($sendResult['success']) {
            jsonSuccess('OTP sent to your phone', [
                'phone' => $phone,
                'expires_in' => $expiryMinutes * 60,
                'simulated' => $sendResult['simulated'] ?? false
            ]);
        } else {
            jsonError($sendResult['message'], 500);
        }
    }
    
    // Verify OTP
    if ($action === 'verify_otp') {
        $phone = trim((string)($input['phone'] ?? ''));
        $otpCode = trim((string)($input['otp_code'] ?? ''));
        
        if (empty($phone) || empty($otpCode)) {
            jsonError('Phone number and OTP code are required', 422);
        }
        
        // Normalize phone
        $phone = preg_replace('/[\s\-\(\)]/', '', $phone);
        if (strlen($phone) === 10) {
            $phone = '+91' . $phone;
        } elseif (strlen($phone) === 12 && substr($phone, 0, 2) === '91') {
            $phone = '+' . $phone;
        }
        
        // Find valid OTP session
        $stmt = $db->prepare("
            SELECT id, otp_code, expires_at, attempts 
            FROM otp_sessions 
            WHERE phone = ? AND verified = 0 
            ORDER BY id DESC LIMIT 1
        ");
        $stmt->execute([$phone]);
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
        $stmt = $db->prepare("UPDATE otp_sessions SET attempts = attempts + 1 WHERE id = ?");
        $stmt->execute([$session['id']]);
        
        // Verify OTP
        if ($session['otp_code'] !== $otpCode) {
            jsonError('Invalid OTP code', 401);
        }
        
        // Mark as verified
        $stmt = $db->prepare("UPDATE otp_sessions SET verified = 1 WHERE id = ?");
        $stmt->execute([$session['id']]);
        
        // Find or create user
        $stmt = $db->prepare("SELECT id, name, email, phone, phone_verified, avatar_color FROM users WHERE phone = ?");
        $stmt->execute([$phone]);
        $user = $stmt->fetch();
        
        $isNewUser = false;
        if (!$user) {
            // Create new user
            $isNewUser = true;
            $colors = ['#2563eb', '#10b981', '#f59e0b', '#8b5cf6', '#ec4899', '#06b6d4', '#f97316'];
            $avatarColor = $colors[array_rand($colors)];
            
            $stmt = $db->prepare("
                INSERT INTO users (name, phone, phone_verified, password_hash, avatar_color) 
                VALUES (?, ?, 1, ?, ?)
            ");
            $stmt->execute([
                'User ' . substr($phone, -4),
                $phone,
                password_hash(bin2hex(random_bytes(16)), PASSWORD_DEFAULT),
                $avatarColor
            ]);
            
            $userId = (int)$db->lastInsertId();
            
            $stmt = $db->prepare("SELECT id, name, email, phone, phone_verified, avatar_color FROM users WHERE id = ?");
            $stmt->execute([$userId]);
            $user = $stmt->fetch();
        } else {
            // Update phone_verified if not already
            if (!$user['phone_verified']) {
                $stmt = $db->prepare("UPDATE users SET phone_verified = 1 WHERE id = ?");
                $stmt->execute([$user['id']]);
                $user['phone_verified'] = 1;
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
        
        // Set active trip if user has trips, otherwise clear stale value
        if (!empty($trips)) {
            if (empty($_SESSION['active_trip_id'])) {
                $_SESSION['active_trip_id'] = (int)$trips[0]['id'];
            }
            // Verify the stored active trip is one the user belongs to
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
            'is_new_user' => $isNewUser
        ]);
    }

    // Link phone number to existing account (after Google/Email login)
    if ($action === 'link_phone') {
        if (getSetting('auth_phone_enabled', '1') !== '1') {
            jsonError('Phone login is disabled', 403);
        }

        // Must be logged in
        if (empty($_SESSION['authenticated']) || empty($_SESSION['user_id'])) {
            jsonError('Authentication required', 401);
        }

        $phone = trim((string)($input['phone'] ?? ''));
        $otpCode = trim((string)($input['otp_code'] ?? ''));

        if (empty($phone) || empty($otpCode)) {
            jsonError('Phone number and OTP code are required', 422);
        }

        // Normalize phone
        $phone = preg_replace('/[\s\-\(\)]/', '', $phone);
        if (strlen($phone) === 10) {
            $phone = '+91' . $phone;
        } elseif (strlen($phone) === 12 && substr($phone, 0, 2) === '91') {
            $phone = '+' . $phone;
        }

        if (!preg_match('/^\+[1-9]\d{6,14}$/', $phone)) {
            jsonError('Invalid phone number format', 422);
        }

        // Check if phone is already used by another user
        $stmt = $db->prepare("SELECT id FROM users WHERE phone = ? AND id != ?");
        $stmt->execute([$phone, $_SESSION['user_id']]);
        if ($stmt->fetch()) {
            jsonError('This phone number is already linked to another account', 409);
        }

        // Find valid OTP session
        $stmt = $db->prepare("
            SELECT id, otp_code, expires_at, attempts 
            FROM otp_sessions 
            WHERE phone = ? AND verified = 0 
            ORDER BY id DESC LIMIT 1
        ");
        $stmt->execute([$phone]);
        $session = $stmt->fetch();

        if (!$session) {
            jsonError('No OTP found. Please request a new one.', 404);
        }

        if (strtotime($session['expires_at']) < time()) {
            jsonError('OTP has expired. Please request a new one.', 410);
        }

        $maxAttempts = (int)getSetting('otp_max_attempts', '3');
        if ((int)$session['attempts'] >= $maxAttempts) {
            jsonError('Maximum verification attempts exceeded.', 429);
        }

        $stmt = $db->prepare("UPDATE otp_sessions SET attempts = attempts + 1 WHERE id = ?");
        $stmt->execute([$session['id']]);

        if ($session['otp_code'] !== $otpCode) {
            jsonError('Invalid OTP code', 401);
        }

        // Mark OTP verified
        $stmt = $db->prepare("UPDATE otp_sessions SET verified = 1 WHERE id = ?");
        $stmt->execute([$session['id']]);

        // Link phone to current user
        $stmt = $db->prepare("UPDATE users SET phone = ?, phone_verified = 1 WHERE id = ?");
        $stmt->execute([$phone, $_SESSION['user_id']]);

        $user = getCurrentUser();

        jsonSuccess('Phone number linked successfully', [
            'user' => $user
        ]);
    }
    
    jsonError('Invalid action', 400);
}

// GET: Check auth status
if ($method === 'GET') {
    if ($action === 'check') {
        $isAuthenticated = !empty($_SESSION['authenticated']) && !empty($_SESSION['user_id']);
        
        if ($isAuthenticated) {
            $user = getCurrentUser();
            $trips = [];
            
            $tripStmt = $db->prepare("
                SELECT t.id, t.trip_code, t.url_token, t.name, t.currency_symbol, tm.role 
                FROM trips t
                JOIN trip_members tm ON tm.trip_id = t.id
                WHERE tm.user_id = ?
                ORDER BY t.created_at DESC
            ");
            $tripStmt->execute([$user['id']]);
            $trips = $tripStmt->fetchAll();
            
            jsonSuccess('Authenticated', [
                'authenticated' => true,
                'user' => $user,
                'trips' => $trips,
                'active_trip' => getActiveTripId()
            ]);
        } else {
            jsonSuccess('Not authenticated', [
                'authenticated' => false
            ]);
        }
    }
    
    if ($action === 'logout') {
        session_destroy();
        jsonSuccess('Logged out successfully');
    }

    if ($action === 'get_auth_methods') {
        jsonSuccess('Auth methods', [
            'phone_enabled' => getSetting('auth_phone_enabled', '1') === '1',
            'google_enabled' => getSetting('auth_google_enabled', '0') === '1',
            'email_enabled' => getSetting('auth_email_enabled', '0') === '1',
            'google_client_id' => getSetting('google_client_id', ''),
        ]);
    }
    
    jsonError('Invalid action', 400);
}

jsonError('Method not allowed', 405);
