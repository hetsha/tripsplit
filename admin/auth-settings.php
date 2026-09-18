<?php
/**
 * TripBook Admin Panel - Authentication Settings
 * Configure login methods: Phone OTP, Email OTP, Google
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/includes/auth.php';

requireAdminAuth();

$db = getDBConnection();

// Get current settings
function getAuthSetting(string $key, string $default = ''): string {
    global $db;
    $stmt = $db->prepare("SELECT setting_value FROM app_settings WHERE setting_key = ?");
    $stmt->execute([$key]);
    $row = $stmt->fetch();
    return $row ? (string)$row['setting_value'] : $default;
}

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $settings = $_POST['settings'] ?? [];
    
    foreach ($settings as $key => $value) {
        $stmt = $db->prepare("
            INSERT INTO app_settings (setting_key, setting_value) 
            VALUES (?, ?) 
            ON DUPLICATE KEY UPDATE setting_value = ?
        ");
        $stmt->execute([$key, $value, $value]);
    }
    
    header('Location: auth-settings.php?saved=1');
    exit;
}

$authPhoneEnabled = getAuthSetting('auth_phone_enabled', '1');
$authGoogleEnabled = getAuthSetting('auth_google_enabled', '0');
$authEmailEnabled = getAuthSetting('auth_email_enabled', '0');

include 'includes/header.php';
?>

<style>
    .toggle-switch {
        position: relative;
        display: inline-block;
        width: 48px;
        height: 26px;
        flex-shrink: 0;
    }
    .toggle-switch input {
        opacity: 0;
        width: 0;
        height: 0;
    }
    .toggle-slider {
        position: absolute;
        cursor: pointer;
        top: 0; left: 0; right: 0; bottom: 0;
        background-color: #ccc;
        transition: 0.3s;
        border-radius: 26px;
    }
    .toggle-slider:before {
        position: absolute;
        content: "";
        height: 20px;
        width: 20px;
        left: 3px;
        bottom: 3px;
        background-color: white;
        transition: 0.3s;
        border-radius: 50%;
    }
    .toggle-switch input:checked + .toggle-slider {
        background-color: #2563eb;
    }
    .toggle-switch input:checked + .toggle-slider:before {
        transform: translateX(22px);
    }
    .auth-method-card {
        background: white;
        border-radius: 12px;
        border: 1px solid #e5e7eb;
        padding: 24px;
        margin-bottom: 20px;
    }
    .auth-method-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-bottom: 16px;
    }
    .auth-method-title {
        display: flex;
        align-items: center;
        gap: 12px;
    }
    .auth-method-icon {
        width: 44px;
        height: 44px;
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 20px;
    }
    .auth-method-name {
        font-size: 16px;
        font-weight: 700;
        color: #111827;
    }
    .auth-method-desc {
        font-size: 13px;
        color: #6b7280;
        margin-top: 2px;
    }
    .auth-method-fields {
        display: flex;
        flex-direction: column;
        gap: 12px;
        padding-top: 16px;
        border-top: 1px solid #f3f4f6;
    }
    .auth-method-fields.collapsed {
        display: none;
    }
    .form-group {
        display: flex;
        flex-direction: column;
        gap: 6px;
    }
    .form-group label {
        font-size: 13px;
        font-weight: 600;
        color: #374151;
    }
    .form-group input, .form-group select {
        padding: 10px 12px;
        border: 1px solid #d1d5db;
        border-radius: 8px;
        font-size: 14px;
        font-family: inherit;
    }
    .form-group input:focus, .form-group select:focus {
        outline: none;
        border-color: #2563eb;
        box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
    }
    .form-hint {
        font-size: 12px;
        color: #9ca3af;
    }
    .status-badge {
        display: inline-block;
        padding: 4px 10px;
        border-radius: 20px;
        font-size: 12px;
        font-weight: 600;
    }
    .status-enabled {
        background: #dcfce7;
        color: #166534;
    }
    .status-disabled {
        background: #f3f4f6;
        color: #6b7280;
    }
    .save-bar {
        position: fixed;
        bottom: 0;
        left: 0;
        right: 0;
        background: white;
        border-top: 1px solid #e5e7eb;
        padding: 16px 24px;
        display: flex;
        justify-content: flex-end;
        gap: 12px;
        z-index: 100;
    }
    .save-bar .btn {
        padding: 10px 24px;
        border-radius: 8px;
        font-weight: 600;
        font-size: 14px;
        border: none;
        cursor: pointer;
    }
    .save-bar .btn-primary {
        background: #2563eb;
        color: white;
    }
    .save-bar .btn-primary:hover {
        background: #1d4ed8;
    }
</style>

<div class="page-header">
    <h2>Authentication Settings</h2>
    <p style="color: #6b7280; font-size: 14px; margin-top: 4px;">Configure which login methods are available to users</p>
</div>

<?php if (isset($_GET['saved'])): ?>
    <div style="background: #dcfce7; color: #166534; padding: 12px 16px; border-radius: 8px; margin-bottom: 20px; font-size: 14px;">
        Settings saved successfully
    </div>
<?php endif; ?>

<form method="POST" id="auth-settings-form">

    <!-- Phone OTP -->
    <div class="auth-method-card">
        <div class="auth-method-header">
            <div class="auth-method-title">
                <div class="auth-method-icon" style="background: #dbeafe; color: #2563eb;">
                    <i data-lucide="smartphone" style="width:20px;height:20px;"></i>
                </div>
                <div>
                    <div class="auth-method-name">Phone OTP</div>
                    <div class="auth-method-desc">Users login with phone number and SMS OTP</div>
                </div>
            </div>
            <div style="display: flex; align-items: center; gap: 12px;">
                <span class="status-badge <?= $authPhoneEnabled === '1' ? 'status-enabled' : 'status-disabled' ?>">
                    <?= $authPhoneEnabled === '1' ? 'Enabled' : 'Disabled' ?>
                </span>
                <label class="toggle-switch">
                    <input type="checkbox" name="settings[auth_phone_enabled]" value="1" 
                           <?= $authPhoneEnabled === '1' ? 'checked' : '' ?>
                           onchange="toggleAuthMethod(this, 'phone-fields')">
                    <span class="toggle-slider"></span>
                </label>
            </div>
        </div>
        <div class="auth-method-fields" id="phone-fields" style="<?= $authPhoneEnabled !== '1' ? 'opacity:0.5' : '' ?>">
            <div class="form-group">
                <label>SMS API Provider</label>
                <input type="text" value="web.upparac.com" disabled class="form-control" style="background:#f9fafb;">
            </div>
            <div class="form-group">
                <label>API Key</label>
                <input type="text" name="settings[otp_api_key]" value="<?= htmlspecialchars(getAuthSetting('otp_api_key')) ?>" placeholder="Enter API key">
                <span class="form-hint">Your web.upparac.com API key</span>
            </div>
            <div class="form-group">
                <label>API URL</label>
                <input type="url" name="settings[otp_api_url]" value="<?= htmlspecialchars(getAuthSetting('otp_api_url', 'https://web.upparac.com/api')) ?>">
            </div>
            <div class="form-group">
                <label>Message Template</label>
                <input type="text" name="settings[otp_message_template]" value="<?= htmlspecialchars(getAuthSetting('otp_message_template', 'Your TripBook OTP is: {code}. Valid for 5 minutes.')) ?>" placeholder="Use {code} for OTP">
            </div>
            <div style="display:grid; grid-template-columns: 1fr 1fr; gap: 12px;">
                <div class="form-group">
                    <label>OTP Expiry (minutes)</label>
                    <input type="number" name="settings[otp_expiry_minutes]" value="<?= htmlspecialchars(getAuthSetting('otp_expiry_minutes', '5')) ?>" min="1" max="30">
                </div>
                <div class="form-group">
                    <label>Max Attempts</label>
                    <input type="number" name="settings[otp_max_attempts]" value="<?= htmlspecialchars(getAuthSetting('otp_max_attempts', '3')) ?>" min="1" max="10">
                </div>
            </div>
        </div>
    </div>

    <!-- Google Login -->
    <div class="auth-method-card">
        <div class="auth-method-header">
            <div class="auth-method-title">
                <div class="auth-method-icon" style="background: #f3f4f6;">
                    <svg width="22" height="22" viewBox="0 0 24 24"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>
                </div>
                <div>
                    <div class="auth-method-name">Google Login</div>
                    <div class="auth-method-desc">Users login with their Google account</div>
                </div>
            </div>
            <div style="display: flex; align-items: center; gap: 12px;">
                <span class="status-badge <?= $authGoogleEnabled === '1' ? 'status-enabled' : 'status-disabled' ?>">
                    <?= $authGoogleEnabled === '1' ? 'Enabled' : 'Disabled' ?>
                </span>
                <label class="toggle-switch">
                    <input type="checkbox" name="settings[auth_google_enabled]" value="1" 
                           <?= $authGoogleEnabled === '1' ? 'checked' : '' ?>
                           onchange="toggleAuthMethod(this, 'google-fields')">
                    <span class="toggle-slider"></span>
                </label>
            </div>
        </div>
        <div class="auth-method-fields <?= $authGoogleEnabled !== '1' ? 'collapsed' : '' ?>" id="google-fields">
            <div class="form-group">
                <label>Google Client ID</label>
                <input type="text" name="settings[google_client_id]" value="<?= htmlspecialchars(getAuthSetting('google_client_id')) ?>" placeholder="xxxx.apps.googleusercontent.com">
                <span class="form-hint">From Google Cloud Console > APIs & Credentials > OAuth 2.0</span>
            </div>
            <div class="form-group">
                <label>Google Client Secret</label>
                <input type="password" name="settings[google_client_secret]" value="<?= htmlspecialchars(getAuthSetting('google_client_secret')) ?>" placeholder="Enter client secret">
            </div>
            <div style="background: #f9fafb; border-radius: 8px; padding: 12px; font-size: 13px; color: #6b7280;">
                <strong>Setup Instructions:</strong>
                <ol style="margin: 8px 0 0 16px; padding: 0;">
                    <li>Go to <a href="https://console.cloud.google.com/apis/credentials" target="_blank">Google Cloud Console</a></li>
                    <li>Create OAuth 2.0 Client ID (Web application)</li>
                    <li>Add your domain to Authorized JavaScript origins</li>
                    <li>Copy the Client ID above</li>
                </ol>
            </div>
        </div>
    </div>

    <!-- Email OTP -->
    <div class="auth-method-card">
        <div class="auth-method-header">
            <div class="auth-method-title">
                <div class="auth-method-icon" style="background: #fef3c7; color: #d97706;">
                    ✉️
                </div>
                <div>
                    <div class="auth-method-name">Email OTP</div>
                    <div class="auth-method-desc">Users login with email and verification code</div>
                </div>
            </div>
            <div style="display: flex; align-items: center; gap: 12px;">
                <span class="status-badge <?= $authEmailEnabled === '1' ? 'status-enabled' : 'status-disabled' ?>">
                    <?= $authEmailEnabled === '1' ? 'Enabled' : 'Disabled' ?>
                </span>
                <label class="toggle-switch">
                    <input type="checkbox" name="settings[auth_email_enabled]" value="1" 
                           <?= $authEmailEnabled === '1' ? 'checked' : '' ?>
                           onchange="toggleAuthMethod(this, 'email-fields')">
                    <span class="toggle-slider"></span>
                </label>
            </div>
        </div>
        <div class="auth-method-fields <?= $authEmailEnabled !== '1' ? 'collapsed' : '' ?>" id="email-fields">
            <div class="form-group">
                <label>SMTP Host</label>
                <input type="text" name="settings[email_smtp_host]" value="<?= htmlspecialchars(getAuthSetting('email_smtp_host')) ?>" placeholder="smtp.gmail.com">
            </div>
            <div style="display:grid; grid-template-columns: 1fr 1fr; gap: 12px;">
                <div class="form-group">
                    <label>SMTP Port</label>
                    <input type="number" name="settings[email_smtp_port]" value="<?= htmlspecialchars(getAuthSetting('email_smtp_port', '587')) ?>">
                </div>
                <div class="form-group">
                    <label>Encryption</label>
                    <select name="settings[email_smtp_encryption]">
                        <option value="tls" <?= getAuthSetting('email_smtp_encryption', 'tls') === 'tls' ? 'selected' : '' ?>>TLS</option>
                        <option value="ssl" <?= getAuthSetting('email_smtp_encryption') === 'ssl' ? 'selected' : '' ?>>SSL</option>
                        <option value="none" <?= getAuthSetting('email_smtp_encryption') === 'none' ? 'selected' : '' ?>>None</option>
                    </select>
                </div>
            </div>
            <div class="form-group">
                <label>SMTP Username</label>
                <input type="text" name="settings[email_smtp_user]" value="<?= htmlspecialchars(getAuthSetting('email_smtp_user')) ?>" placeholder="your@email.com">
            </div>
            <div class="form-group">
                <label>SMTP Password</label>
                <input type="password" name="settings[email_smtp_pass]" value="<?= htmlspecialchars(getAuthSetting('email_smtp_pass')) ?>" placeholder="App password or SMTP password">
            </div>
            <div class="form-group">
                <label>Sender Email Address</label>
                <input type="email" name="settings[email_smtp_from]" value="<?= htmlspecialchars(getAuthSetting('email_smtp_from')) ?>" placeholder="noreply@yourdomain.com">
                <span class="form-hint">The "From" address for OTP emails</span>
            </div>
            <div style="background: #f9fafb; border-radius: 8px; padding: 12px; font-size: 13px; color: #6b7280;">
                <strong>Gmail Users:</strong> Use an <a href="https://myaccount.google.com/apppasswords" target="_blank">App Password</a> instead of your regular password.
                <br><br>
                <strong>If SMTP is empty:</strong> PHP's built-in <code>mail()</code> function will be used (may not work on all servers).
            </div>
        </div>
    </div>

    <div class="save-bar">
        <button type="submit" class="btn btn-primary">Save Authentication Settings</button>
    </div>

</form>

<script>
function toggleAuthMethod(checkbox, fieldsId) {
    const fields = document.getElementById(fieldsId);
    const card = fields.closest('.auth-method-card');
    const badge = card.querySelector('.status-badge');
    
    if (checkbox.checked) {
        fields.classList.remove('collapsed');
        fields.style.opacity = '1';
        badge.textContent = 'Enabled';
        badge.className = 'status-badge status-enabled';
    } else {
        fields.classList.add('collapsed');
        fields.style.opacity = '0.5';
        badge.textContent = 'Disabled';
        badge.className = 'status-badge status-disabled';
    }
}
</script>

<?php include 'includes/footer.php'; ?>
