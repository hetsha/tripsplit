<?php
/**
 * TripBook Settings API
 * Handles app settings and user profile
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/auth.php';

header('Content-Type: application/json; charset=utf-8');

$currentUser = getCurrentUser();
$db = getDBConnection();
$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? $_POST['action'] ?? 'get';

// GET Actions
if ($method === 'GET') {
    // Get app settings
    if ($action === 'get') {
        $stmt = $db->query("SELECT setting_key, setting_value FROM app_settings");
        $settings = [];
        while ($row = $stmt->fetch()) {
            $settings[$row['setting_key']] = $row['setting_value'];
        }
        
        jsonSuccess('Settings loaded', [
            'settings' => $settings,
            'user' => $currentUser
        ]);
    }
    
    jsonError('Invalid action', 400);
}

// POST Actions
if ($method === 'POST') {
    requireCsrf();
    $input = getJsonInput();
    
    // Update user profile
    if ($action === 'update_profile') {
        $name = trim((string)($input['name'] ?? ''));
        $email = trim((string)($input['email'] ?? ''));
        
        if (empty($name)) {
            jsonError('Name is required', 422);
        }
        
        $stmt = $db->prepare("UPDATE users SET name = ?, email = ? WHERE id = ?");
        $stmt->execute([$name, $email ?: null, $currentUser['id']]);
        
        $_SESSION['user_name'] = $name;
        
        jsonSuccess('Profile updated successfully');
    }
    
    // Update OTP settings (admin only)
    if ($action === 'update_otp_settings') {
        if (empty($currentUser['is_admin'])) {
            jsonError('Unauthorized', 403);
        }
        
        $apiKey = $input['otp_api_key'] ?? null;
        $apiUrl = $input['otp_api_url'] ?? null;
        $template = $input['otp_message_template'] ?? null;
        
        $updates = [];
        $params = [];
        
        if ($apiKey !== null) {
            $updates[] = "setting_value = ?";
            $params[] = $apiKey;
            $params[] = 'otp_api_key';
        }
        
        if ($apiUrl !== null) {
            $updates[] = "setting_value = ?";
            $params[] = $apiUrl;
            $params[] = 'otp_api_url';
        }
        
        if ($template !== null) {
            $updates[] = "setting_value = ?";
            $params[] = $template;
            $params[] = 'otp_message_template';
        }
        
        if (!empty($updates)) {
            foreach ($updates as $i => $update) {
                $key = $params[count($params) - count($updates) + $i];
                $value = $params[$i];
                $stmt = $db->prepare("UPDATE app_settings SET setting_value = ? WHERE setting_key = ?");
                $stmt->execute([$value, $key]);
            }
        }
        
        jsonSuccess('OTP settings updated successfully');
    }
    
    jsonError('Invalid action', 400);
}
