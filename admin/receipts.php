<?php
/**
 * TripSplit Admin Panel - Receipts & OCR Processing Monitor
 * Sections 26 & 27
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

requirePermission('receipts.view');

$db = getDBConnection();
ensureAdminTablesExist($db);
if (function_exists('ensureReceiptColumns')) {
    ensureReceiptColumns();
}

// Check Gemini AI Key status in app_settings
$stmt = $db->query("SELECT setting_value FROM app_settings WHERE setting_key = 'gemini_api_key' LIMIT 1");
$row = $stmt->fetch();
$hasGemini = !empty($row['setting_value']) || !empty(getenv('GEMINI_API_KEY'));

// Storage usage in uploads/receipts
$receiptDir = __DIR__ . '/../uploads/receipts';
$fileCount = 0;
$totalBytes = 0;
if (is_dir($receiptDir)) {
    $files = scandir($receiptDir);
    foreach ($files as $f) {
        if ($f !== '.' && $f !== '..') {
            $fileCount++;
            $totalBytes += filesize($receiptDir . '/' . $f);
        }
    }
}
$mbUsed = round($totalBytes / (1024 * 1024), 2);

// Fetch receipts
$receipts = [];
try {
    $stmt = $db->query("
        SELECT r.*, u.name as user_name, tx.description as tx_description, tx.amount as tx_amount
        FROM receipts r
        LEFT JOIN users u ON u.id = r.user_id
        LEFT JOIN transactions tx ON tx.id = r.transaction_id
        ORDER BY r.created_at DESC
        LIMIT 50
    ");
    $receipts = $stmt->fetchAll();
} catch (Throwable $e) {
    // If receipts table is empty or just initialized
    $receipts = [];
}

include __DIR__ . '/includes/header.php';
?>

<div class="page-header">
    <div class="page-title-box">
        <h1>Receipts & OCR Processing Monitor</h1>
        <p>Monitor scanned bills, OCR confidence rates, extracted line items, and uploaded receipt images</p>
    </div>
</div>

<!-- KPI Cards (Section 27) -->
<div class="kpi-grid">
    <div class="stat-card">
        <div class="stat-info">
            <span class="stat-label">Total Uploaded Receipts</span>
            <div class="stat-value"><?= count($receipts) ?></div>
            <div class="stat-subtext"><?= $fileCount ?> files stored on disk</div>
        </div>
        <div class="stat-icon" style="background: #eff6ff; color: #2563eb;">
            <i data-lucide="receipt"></i>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-info">
            <span class="stat-label">AI OCR Engine Status</span>
            <div class="stat-value" style="font-size: 18px;">
                <span class="badge <?= $hasGemini ? 'badge-success' : 'badge-warning' ?>">
                    <?= $hasGemini ? '● Gemini AI Active' : '⚠ Rule-Based OCR' ?>
                </span>
            </div>
            <div class="stat-subtext"><?= $hasGemini ? 'Key configured in settings' : 'Configure key in Settings' ?></div>
        </div>
        <div class="stat-icon" style="background: #ecfdf5; color: #10b981;">
            <i data-lucide="sparkles"></i>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-info">
            <span class="stat-label">Disk Storage Used</span>
            <div class="stat-value"><?= $mbUsed ?> MB</div>
            <div class="stat-subtext">uploads/receipts directory</div>
        </div>
        <div class="stat-icon" style="background: #fffbeb; color: #f59e0b;">
            <i data-lucide="hard-drive"></i>
        </div>
    </div>
</div>

<!-- Receipts Table (Section 26) -->
<div class="card">
    <div class="card-header">
        <h3>Uploaded Receipt Records (<?= count($receipts) ?>)</h3>
    </div>
    <div class="table-responsive">
        <table class="data-table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Uploaded By</th>
                    <th>Linked Transaction</th>
                    <th>Image</th>
                    <th>OCR Confidence</th>
                    <th>Extracted Text / Items</th>
                    <th>Uploaded Date</th>
                </tr>
            </thead>
            <tbody>
                <?php if (empty($receipts)): ?>
                    <tr>
                        <td colspan="7" style="text-align: center; padding: 40px; color: #94a3b8;">
                            No receipts scanned or stored yet.
                        </td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($receipts as $rc): ?>
                        <tr>
                            <td style="font-weight: 600; color: #64748b;">#<?= $rc['id'] ?></td>
                            <td><?= htmlspecialchars($rc['user_name'] ?? 'User #' . $rc['user_id']) ?></td>
                            <td>
                                <?php if (!empty($rc['transaction_id'])): ?>
                                    <a href="transaction-detail.php?id=<?= $rc['transaction_id'] ?>" style="color: #2563eb; font-weight: 600; text-decoration: none;">
                                        <?= htmlspecialchars($rc['tx_description'] ?? 'Tx #' . $rc['transaction_id']) ?>
                                    </a>
                                    <div style="font-size: 11px; color: #64748b;">₹<?= number_format((float)($rc['tx_amount'] ?? 0), 2) ?></div>
                                <?php else: ?>
                                    <span style="color: #94a3b8;">Not linked</span>
                                <?php endif; ?>
                            </td>
                            <td>
                                <?php if (!empty($rc['image_url'])): ?>
                                    <a href="../<?= htmlspecialchars($rc['image_url']) ?>" target="_blank" class="btn btn-secondary btn-sm">
                                        <i data-lucide="image" style="width: 14px; height: 14px;"></i> View Bill
                                    </a>
                                <?php else: ?>
                                    <span style="color: #94a3b8;">No file</span>
                                <?php endif; ?>
                            </td>
                            <td>
                                <span class="badge badge-primary">
                                    <?= !empty($rc['confidence']) ? round((float)$rc['confidence'] * 100) . '%' : 'Auto' ?>
                                </span>
                            </td>
                            <td>
                                <div style="max-width: 300px; font-size: 12px; color: #475569; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">
                                    <?= htmlspecialchars(substr($rc['raw_text'] ?? 'No text', 0, 100)) ?>
                                </div>
                            </td>
                            <td style="font-size: 12px; color: #64748b;">
                                <?= date('d M Y, H:i', strtotime($rc['created_at'])) ?>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php
include __DIR__ . '/includes/footer.php';
