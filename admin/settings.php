<?php
/**
 * TripSplit Admin Panel - System Settings & Feature Flags
 * Sections 33, 34, 35, 71, 72
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

requirePermission('settings.view');

$db = getDBConnection();
ensureAdminTablesExist($db);

$msg = '';

// Handle save
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    requirePermission('settings.edit');
    $settings = $_POST['settings'] ?? [];

    foreach ($settings as $key => $val) {
        $stmt = $db->prepare("
            INSERT INTO app_settings (setting_key, setting_value, setting_group) 
            VALUES (?, ?, 'general') 
            ON DUPLICATE KEY UPDATE setting_value = ?
        ");
        $stmt->execute([$key, $val, $val]);
    }

    logAdminAudit('UPDATE_SETTINGS', 'settings', 'app_settings', 'all', null, $settings, 'Updated general app settings and feature flags');
    $msg = 'Settings saved successfully.';
}

// Helper to retrieve setting
function getSetting(string $key, string $default = ''): string {
    global $db;
    $stmt = $db->prepare("SELECT setting_value FROM app_settings WHERE setting_key = ?");
    $stmt->execute([$key]);
    $r = $stmt->fetch();
    return $r ? (string)$r['setting_value'] : $default;
}

include __DIR__ . '/includes/header.php';
?>

<div class="page-header">
    <div class="page-title-box">
        <h1>System Settings & Mobile Release Governance</h1>
        <p>Configure platform preferences, mobile version minimum thresholds, force-update URLs, and feature flags</p>
    </div>
</div>

<?php if (!empty($msg)): ?>
    <div class="alert alert-success">✓ <?= htmlspecialchars($msg) ?></div>
<?php endif; ?>

<form method="POST">
    <?= csrfField() ?>

    <div class="grid-2">
        <!-- General Preferences (Section 33) -->
        <div class="card">
            <div class="card-header">
                <h3>General System Preferences</h3>
            </div>
            <div class="card-body">
                <div style="margin-bottom: 16px;">
                    <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px;">Application Name</label>
                    <input type="text" name="settings[app_name]" value="<?= htmlspecialchars(getSetting('app_name', 'TripSplit')) ?>" class="form-control" style="width: 100%; padding: 10px; border: 1px solid #cbd5e1; border-radius: 8px;">
                </div>

                <div style="margin-bottom: 16px;">
                    <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px;">Support / Contact Email</label>
                    <input type="email" name="settings[support_email]" value="<?= htmlspecialchars(getSetting('support_email', 'support@tripsplit.com')) ?>" class="form-control" style="width: 100%; padding: 10px; border: 1px solid #cbd5e1; border-radius: 8px;">
                </div>

                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-bottom: 16px;">
                    <div>
                        <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px;">Default Currency</label>
                        <input type="text" name="settings[default_currency]" value="<?= htmlspecialchars(getSetting('default_currency', 'INR')) ?>" class="form-control" style="width: 100%; padding: 10px; border: 1px solid #cbd5e1; border-radius: 8px;">
                    </div>
                    <div>
                        <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px;">Currency Symbol</label>
                        <input type="text" name="settings[currency_symbol]" value="<?= htmlspecialchars(getSetting('currency_symbol', '₹')) ?>" class="form-control" style="width: 100%; padding: 10px; border: 1px solid #cbd5e1; border-radius: 8px;">
                    </div>
                </div>

                <div>
                    <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px;">System Timezone</label>
                    <input type="text" name="settings[timezone]" value="<?= htmlspecialchars(getSetting('timezone', 'Asia/Kolkata')) ?>" class="form-control" style="width: 100%; padding: 10px; border: 1px solid #cbd5e1; border-radius: 8px;">
                </div>
            </div>
        </div>

        <!-- Mobile App Version & Release Control (Section 72) -->
        <div class="card">
            <div class="card-header">
                <h3>Mobile App Version Governance (Section 72)</h3>
            </div>
            <div class="card-body">
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-bottom: 16px;">
                    <div>
                        <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px;">Minimum Supported App Version</label>
                        <input type="text" name="settings[min_app_version]" value="<?= htmlspecialchars(getSetting('min_app_version', '1.0.0')) ?>" class="form-control" placeholder="1.0.0" style="width: 100%; padding: 10px; border: 1px solid #cbd5e1; border-radius: 8px;">
                        <small style="color: #64748b; font-size: 11px;">Apps below this version are forced to update.</small>
                    </div>
                    <div>
                        <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px;">Latest Released App Version</label>
                        <input type="text" name="settings[latest_app_version]" value="<?= htmlspecialchars(getSetting('latest_app_version', '1.0.0')) ?>" class="form-control" placeholder="1.0.0" style="width: 100%; padding: 10px; border: 1px solid #cbd5e1; border-radius: 8px;">
                    </div>
                </div>

                <div style="margin-bottom: 16px;">
                    <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px;">Google Play Store Update URL</label>
                    <input type="url" name="settings[play_store_url]" value="<?= htmlspecialchars(getSetting('play_store_url', 'https://play.google.com/store/apps/details?id=com.tripbook.app')) ?>" class="form-control" style="width: 100%; padding: 10px; border: 1px solid #cbd5e1; border-radius: 8px;">
                </div>

                <div>
                    <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px;">Apple App Store Update URL</label>
                    <input type="url" name="settings[app_store_url]" value="<?= htmlspecialchars(getSetting('app_store_url', '')) ?>" class="form-control" placeholder="https://apps.apple.com/..." style="width: 100%; padding: 10px; border: 1px solid #cbd5e1; border-radius: 8px;">
                </div>
            </div>
        </div>
    </div>

    <!-- Feature Flags Matrix (Section 35) -->
    <div class="card">
        <div class="card-header">
            <h3>Feature Toggles & Remote Flags (Section 35)</h3>
        </div>
        <div class="card-body">
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 20px;">
                <label style="display: flex; align-items: center; gap: 12px; cursor: pointer;">
                    <input type="checkbox" name="settings[feature_ocr]" value="1" <?= getSetting('feature_ocr', '1') === '1' ? 'checked' : '' ?> style="width: 20px; height: 20px;">
                    <div>
                        <strong>Receipt OCR Bill Scanner</strong>
                        <div style="font-size: 12px; color: #64748b;">Allow users to scan receipts with camera</div>
                    </div>
                </label>

                <label style="display: flex; align-items: center; gap: 12px; cursor: pointer;">
                    <input type="checkbox" name="settings[feature_gallery]" value="1" <?= getSetting('feature_gallery', '1') === '1' ? 'checked' : '' ?> style="width: 20px; height: 20px;">
                    <div>
                        <strong>Trip Media Gallery</strong>
                        <div style="font-size: 12px; color: #64748b;">Allow trip members to upload shared photos</div>
                    </div>
                </label>

                <label style="display: flex; align-items: center; gap: 12px; cursor: pointer;">
                    <input type="checkbox" name="settings[feature_whatsapp]" value="1" <?= getSetting('feature_whatsapp', '0') === '1' ? 'checked' : '' ?> style="width: 20px; height: 20px;">
                    <div>
                        <strong>WhatsApp Integration Bot</strong>
                        <div style="font-size: 12px; color: #64748b;">Listen for forwarded messages & bot parses</div>
                    </div>
                </label>

                <label style="display: flex; align-items: center; gap: 12px; cursor: pointer;">
                    <input type="checkbox" name="settings[feature_ai_parser]" value="1" <?= getSetting('feature_ai_parser', '0') === '1' ? 'checked' : '' ?> style="width: 20px; height: 20px;">
                    <div>
                        <strong>Natural Language AI Parser</strong>
                        <div style="font-size: 12px; color: #64748b;">Process conversational expense entries</div>
                    </div>
                </label>
            </div>
        </div>
    </div>

    <div style="text-align: right; margin-bottom: 40px;">
        <button type="submit" class="btn btn-primary" style="padding: 12px 28px;">
            <i data-lucide="save"></i> Save All Settings
        </button>
    </div>
</form>

<?php
include __DIR__ . '/includes/footer.php';
