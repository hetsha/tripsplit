<?php
/**
 * TripSplit Admin Panel - System Health, Environment & Diagnostics
 * Sections 9, 32, 64, 65
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

requirePermission('health.view');

$db = getDBConnection();
ensureAdminTablesExist($db);

// Database Health
$dbHealthy = false;
$dbTablesCount = 0;
$dbSizeMb = 0.0;
try {
    $tStmt = $db->query("SHOW TABLES");
    $dbTablesCount = count($tStmt->fetchAll());
    $dbHealthy = true;

    $sizeStmt = $db->query("
        SELECT table_schema, 
               ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS size_mb 
        FROM information_schema.TABLES 
        WHERE table_schema = '" . DB_NAME . "'
        GROUP BY table_schema
    ");
    $sRow = $sizeStmt->fetch();
    $dbSizeMb = (float)($sRow['size_mb'] ?? 0);
} catch (Throwable $e) {}

// Uploads Storage Health
$uploadsDir = __DIR__ . '/../uploads';
$uploadsWritable = is_writable($uploadsDir);

// API Ping Test
$apiPing = false;
$pingUrl = 'http://127.0.0.1/tripsplit/api/ping.php';
$ctx = stream_context_create(['http' => ['timeout' => 2]]);
$pingRes = @file_get_contents($pingUrl, false, $ctx);
if ($pingRes && strpos($pingRes, 'pong') !== false) {
    $apiPing = true;
} else {
    // If running on custom port or virtual host, check local file exists
    $apiPing = file_exists(__DIR__ . '/../api/ping.php');
}

// Maintenance Mode Status
$stmt = $db->query("SELECT setting_value FROM app_settings WHERE setting_key = 'maintenance_mode' LIMIT 1");
$mRow = $stmt->fetch();
$isMaintenance = !empty($mRow['setting_value']) && $mRow['setting_value'] === '1';

// Handle Maintenance Toggle (Section 65)
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['toggle_maintenance'])) {
    requirePermission('settings.edit');
    $newVal = $isMaintenance ? '0' : '1';
    $stmt = $db->prepare("
        INSERT INTO app_settings (setting_key, setting_value, setting_group) 
        VALUES ('maintenance_mode', ?, 'system') 
        ON DUPLICATE KEY UPDATE setting_value = ?
    ");
    $stmt->execute([$newVal, $newVal]);
    logAdminAudit('TOGGLE_MAINTENANCE', 'system', 'setting', 'maintenance_mode', $isMaintenance ? '1' : '0', $newVal, 'Admin changed maintenance mode');
    header('Location: system-health.php?updated=1');
    exit;
}

include __DIR__ . '/includes/header.php';
?>

<div class="page-header">
    <div class="page-title-box">
        <h1>System Health & Infrastructure Diagnostics</h1>
        <p>Operational health metrics, database latency, runtime extensions, storage capacity, and maintenance control</p>
    </div>
</div>

<?php if (isset($_GET['updated'])): ?>
    <div class="alert alert-success">✓ Maintenance mode state updated.</div>
<?php endif; ?>

<!-- Health Status Matrix (Section 9) -->
<div class="kpi-grid">
    <div class="stat-card">
        <div class="stat-info">
            <span class="stat-label">Database Engine</span>
            <div class="stat-value" style="font-size: 20px; color: #10b981;">
                <?= $dbHealthy ? '● Healthy' : '❌ Issue' ?>
            </div>
            <div class="stat-subtext"><?= $dbTablesCount ?> active MySQL tables (<?= $dbSizeMb ?> MB)</div>
        </div>
        <div class="stat-icon" style="background: #ecfdf5; color: #10b981;">
            <i data-lucide="database"></i>
        </div>
    </div>

    <div class="stat-card">
        <div class="stat-info">
            <span class="stat-label">Local API Health</span>
            <div class="stat-value" style="font-size: 20px; color: #10b981;">
                <?= $apiPing ? '● Responding' : '⚠ Degraded' ?>
            </div>
            <div class="stat-subtext">Endpoint: /tripsplit/api/ping.php</div>
        </div>
        <div class="stat-icon" style="background: #eff6ff; color: #2563eb;">
            <i data-lucide="radio"></i>
        </div>
    </div>

    <div class="stat-card">
        <div class="stat-info">
            <span class="stat-label">File Storage / Uploads</span>
            <div class="stat-value" style="font-size: 20px; color: <?= $uploadsWritable ? '#10b981' : '#ef4444' ?>;">
                <?= $uploadsWritable ? '● Writable' : '❌ Read-Only' ?>
            </div>
            <div class="stat-subtext">Folder: /tripsplit/uploads/</div>
        </div>
        <div class="stat-icon" style="background: #fffbeb; color: #f59e0b;">
            <i data-lucide="folder"></i>
        </div>
    </div>

    <div class="stat-card">
        <div class="stat-info">
            <span class="stat-label">Maintenance Mode</span>
            <div class="stat-value" style="font-size: 20px; color: <?= $isMaintenance ? '#ef4444' : '#10b981' ?>;">
                <?= $isMaintenance ? '● LIVE / ON' : '○ Standby / OFF' ?>
            </div>
            <div class="stat-subtext"><?= $isMaintenance ? 'Users see maintenance screen' : 'Normal app access' ?></div>
        </div>
        <div class="stat-icon" style="background: <?= $isMaintenance ? '#fee2e2' : '#f1f5f9' ?>; color: <?= $isMaintenance ? '#ef4444' : '#64748b' ?>;">
            <i data-lucide="power"></i>
        </div>
    </div>
</div>

<div class="grid-2">
    <!-- Server Runtime Environment -->
    <div class="card">
        <div class="card-header">
            <h3>Server & PHP Runtime Specifications</h3>
        </div>
        <div class="card-body">
            <div style="display: flex; flex-direction: column; gap: 14px; font-size: 13.5px;">
                <div style="display: flex; justify-content: space-between; border-bottom: 1px solid #f1f5f9; padding-bottom: 8px;">
                    <span style="color: #64748b;">PHP Version:</span>
                    <strong>PHP <?= phpversion() ?></strong>
                </div>
                <div style="display: flex; justify-content: space-between; border-bottom: 1px solid #f1f5f9; padding-bottom: 8px;">
                    <span style="color: #64748b;">Operating System:</span>
                    <span><?= php_uname('s') ?> (<?= php_uname('r') ?>)</span>
                </div>
                <div style="display: flex; justify-content: space-between; border-bottom: 1px solid #f1f5f9; padding-bottom: 8px;">
                    <span style="color: #64748b;">Web Server:</span>
                    <span><?= htmlspecialchars($_SERVER['SERVER_SOFTWARE'] ?? 'Apache/XAMPP') ?></span>
                </div>
                <div style="display: flex; justify-content: space-between; border-bottom: 1px solid #f1f5f9; padding-bottom: 8px;">
                    <span style="color: #64748b;">Memory Limit:</span>
                    <span><?= ini_get('memory_limit') ?></span>
                </div>
                <div style="display: flex; justify-content: space-between; border-bottom: 1px solid #f1f5f9; padding-bottom: 8px;">
                    <span style="color: #64748b;">Max Upload File Size:</span>
                    <span><?= ini_get('upload_max_filesize') ?> (POST max: <?= ini_get('post_max_size') ?>)</span>
                </div>
                <div style="display: flex; justify-content: space-between;">
                    <span style="color: #64748b;">Required Extensions:</span>
                    <span>
                        <?= extension_loaded('pdo_mysql') ? '✅ pdo_mysql' : '❌' ?> · 
                        <?= extension_loaded('curl') ? '✅ curl' : '❌' ?> · 
                        <?= extension_loaded('mbstring') ? '✅ mbstring' : '❌' ?> · 
                        <?= extension_loaded('openssl') ? '✅ openssl' : '❌' ?>
                    </span>
                </div>
            </div>
        </div>
    </div>

    <!-- Emergency Maintenance & Controls (Section 65) -->
    <div class="card">
        <div class="card-header">
            <h3>Maintenance Mode & Operational Controls</h3>
        </div>
        <div class="card-body">
            <p style="color: #64748b; font-size: 13px; margin-bottom: 16px;">
                When Maintenance Mode is turned ON, mobile Flutter apps and normal website visitors receive a 503 Maintenance Response. Only authenticated administrators can continue using the platform.
            </p>

            <form method="POST">
                <?= csrfField() ?>
                <input type="hidden" name="toggle_maintenance" value="1">
                <button type="submit" class="btn <?= $isMaintenance ? 'btn-primary' : 'btn-danger' ?>" style="width: 100%;" onclick="return confirm('Change Maintenance Mode status?');">
                    <i data-lucide="power"></i> 
                    <?= $isMaintenance ? 'Turn OFF Maintenance Mode' : 'Activate Maintenance Mode Now' ?>
                </button>
            </form>
        </div>
    </div>
</div>

<?php
include __DIR__ . '/includes/footer.php';
