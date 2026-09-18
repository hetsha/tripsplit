<?php
/**
 * TripBook Admin Panel - Settings
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/includes/auth.php';

requireAdminAuth();

$db = getDBConnection();

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
    
    header('Location: settings.php?saved=1');
    exit;
}

// Get all settings grouped
$stmt = $db->query("SELECT * FROM app_settings ORDER BY setting_group, setting_key");
$allSettings = $stmt->fetchAll();

$grouped = [];
foreach ($allSettings as $setting) {
    $grouped[$setting['setting_group']][] = $setting;
}

include 'includes/header.php';
?>

<div class="page-header">
    <h2>App Settings</h2>
</div>

<div style="background: #eff6ff; border: 1px solid #bfdbfe; border-radius: 8px; padding: 16px; margin-bottom: 20px;">
    <strong style="color: #1e40af;">Auth Settings Moved</strong>
    <p style="color: #1e40af; margin: 4px 0 0; font-size: 14px;">
        Login method settings (Phone OTP, Email OTP, Google) have been moved to 
        <a href="auth-settings.php" style="font-weight: 600; text-decoration: underline;">Auth Settings</a>.
    </p>
</div>

<?php if (isset($_GET['saved'])): ?>
    <div class="alert alert-success">Settings saved successfully</div>
<?php endif; ?>

<form method="POST">
    <?php foreach ($grouped as $group => $settings): ?>
    <div class="card" style="margin-bottom: 20px;">
        <div class="card-header">
            <h3><?= ucfirst(htmlspecialchars($group)) ?> Settings</h3>
        </div>
        <div class="card-body">
            <?php foreach ($settings as $setting): ?>
            <div class="form-group">
                <label class="form-label">
                    <?= htmlspecialchars($setting['description'] ?: $setting['setting_key']) ?>
                </label>
                <?php if (strpos($setting['setting_key'], 'password') !== false || strpos($setting['setting_key'], 'key') !== false): ?>
                    <input type="password" 
                           name="settings[<?= htmlspecialchars($setting['setting_key']) ?>]" 
                           class="form-control"
                           value="<?= htmlspecialchars($setting['setting_value']) ?>"
                           placeholder="Enter value...">
                <?php elseif (strpos($setting['setting_key'], 'url') !== false): ?>
                    <input type="url" 
                           name="settings[<?= htmlspecialchars($setting['setting_key']) ?>]" 
                           class="form-control"
                           value="<?= htmlspecialchars($setting['setting_value']) ?>"
                           placeholder="https://...">
                <?php elseif (strpos($setting['setting_key'], 'template') !== false): ?>
                    <textarea name="settings[<?= htmlspecialchars($setting['setting_key']) ?>]" 
                              class="form-control"
                              rows="3"
                              placeholder="Use {code} for OTP code"><?= htmlspecialchars($setting['setting_value']) ?></textarea>
                <?php else: ?>
                    <input type="text" 
                           name="settings[<?= htmlspecialchars($setting['setting_key']) ?>]" 
                           class="form-control"
                           value="<?= htmlspecialchars($setting['setting_value']) ?>">
                <?php endif; ?>
                <small class="form-hint">Key: <?= htmlspecialchars($setting['setting_key']) ?></small>
            </div>
            <?php endforeach; ?>
        </div>
    </div>
    <?php endforeach; ?>
    
    <div class="form-actions">
        <button type="submit" class="btn-primary">Save Settings</button>
    </div>
</form>

<?php include 'includes/footer.php'; ?>
