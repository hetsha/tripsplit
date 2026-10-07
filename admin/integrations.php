<?php
/**
 * TripSplit Admin Panel - AI & WhatsApp Integrations Monitor
 * Sections 28, 29, 30, 31
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

requirePermission('dashboard.view');

$db = getDBConnection();
ensureAdminTablesExist($db);

// Feature flags status
$flags = [
    'whatsapp_enabled' => false,
    'ai_parser_enabled' => false,
    'ocr_scanner_enabled' => true,
];

$stmt = $db->query("SELECT setting_key, setting_value FROM app_settings WHERE setting_key IN ('feature_whatsapp', 'feature_ai_parser')");
while ($r = $stmt->fetch()) {
    if ($r['setting_key'] === 'feature_whatsapp') $flags['whatsapp_enabled'] = $r['setting_value'] === '1';
    if ($r['setting_key'] === 'feature_ai_parser') $flags['ai_parser_enabled'] = $r['setting_value'] === '1';
}

include __DIR__ . '/includes/header.php';
?>

<div class="page-header">
    <div class="page-title-box">
        <h1>AI & WhatsApp Integrations Monitor</h1>
        <p>Operational monitoring for intelligent expense extraction, automated WhatsApp bot parsing, and LLM providers</p>
    </div>
</div>

<!-- Architecture Status -->
<div class="kpi-grid">
    <div class="stat-card">
        <div class="stat-info">
            <span class="stat-label">WhatsApp Bot Connection</span>
            <div class="stat-value" style="font-size: 18px;">
                <span class="badge <?= $flags['whatsapp_enabled'] ? 'badge-success' : 'badge-secondary' ?>">
                    <?= $flags['whatsapp_enabled'] ? '● Connected' : '○ Standby / Module Ready' ?>
                </span>
            </div>
            <div class="stat-subtext">Section 28 Architecture Ready</div>
        </div>
        <div class="stat-icon" style="background: #ecfdf5; color: #10b981;">
            <i data-lucide="message-square"></i>
        </div>
    </div>

    <div class="stat-card">
        <div class="stat-info">
            <span class="stat-label">Natural Language AI Parser</span>
            <div class="stat-value" style="font-size: 18px;">
                <span class="badge <?= $flags['ai_parser_enabled'] ? 'badge-success' : 'badge-secondary' ?>">
                    <?= $flags['ai_parser_enabled'] ? '● Active' : '○ Standby / Schema Ready' ?>
                </span>
            </div>
            <div class="stat-subtext">Section 30 LLM Pipeline</div>
        </div>
        <div class="stat-icon" style="background: #eff6ff; color: #2563eb;">
            <i data-lucide="bot"></i>
        </div>
    </div>

    <div class="stat-card">
        <div class="stat-info">
            <span class="stat-label">Receipt Vision OCR</span>
            <div class="stat-value" style="font-size: 18px; color: #10b981;">
                ● Active
            </div>
            <div class="stat-subtext">Integrated via /api/scan_receipt.php</div>
        </div>
        <div class="stat-icon" style="background: #fffbeb; color: #f59e0b;">
            <i data-lucide="scan-line"></i>
        </div>
    </div>
</div>

<div class="grid-2">
    <!-- WhatsApp Integration Panel (Section 28 & 29) -->
    <div class="card">
        <div class="card-header">
            <h3>WhatsApp Expense Parser (Section 28 & 29)</h3>
        </div>
        <div class="card-body">
            <p style="color: #64748b; font-size: 13.5px; margin-bottom: 16px;">
                Allows travelers to forward WhatsApp group messages (e.g., <em>"Raj paid 1200 for dinner for 4 people"</em>) to the TripSplit WhatsApp bot to automatically parse amounts, payers, and splits.
            </p>
            <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; padding: 14px; font-size: 13px;">
                <strong>Sample Parsed Output Format:</strong>
                <pre style="margin-top: 8px; color: #0f172a; font-family: monospace; font-size: 12px;">{
  "detected_amount": 1200.00,
  "description": "Dinner",
  "detected_payer": "Raj",
  "participants": 4,
  "confidence": 0.96,
  "status": "ready_for_review"
}</pre>
            </div>
        </div>
    </div>

    <!-- AI Parser Engine (Section 30 & 31) -->
    <div class="card">
        <div class="card-header">
            <h3>AI Multi-Model Provider (Section 30 & 31)</h3>
        </div>
        <div class="card-body">
            <p style="color: #64748b; font-size: 13.5px; margin-bottom: 16px;">
                Monitors tokens, response times, model providers (Google Gemini / OpenAI), and parser confidence scores.
            </p>
            <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; padding: 14px; font-size: 13px;">
                <strong>Configured Provider:</strong> Google Gemini 1.5 / Vision OCR<br>
                <strong>Fallback Engine:</strong> Local Keyword & Regular Expression Parser<br>
                <strong>Logging Target:</strong> <code>admin_audit_logs</code>
            </div>
        </div>
    </div>
</div>

<?php
include __DIR__ . '/includes/footer.php';
