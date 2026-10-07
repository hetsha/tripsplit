<?php
/**
 * TripSplit Admin Panel - Reports & Data Export Center
 * Sections 22 & 23
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

requirePermission('reports.view');

$db = getDBConnection();
ensureAdminTablesExist($db);

// Handle CSV Export
if (isset($_GET['export'])) {
    requirePermission('reports.export');
    $type = $_GET['export'];

    logAdminAudit('EXPORT_REPORT', 'reports', 'export', $type, null, null, "Exported $type report as CSV");

    header('Content-Type: text/csv; charset=utf-8');
    header("Content-Disposition: attachment; filename=\"tripsplit_{$type}_" . date('Y-m-d_His') . ".csv\"");
    $output = fopen('php://output', 'w');

    if ($type === 'users') {
        fputcsv($output, ['User ID', 'Name', 'Email', 'Phone', 'Status', 'Auth Provider', 'Created At']);
        $stmt = $db->query("SELECT id, name, email, phone, status, auth_provider, created_at FROM users ORDER BY id ASC");
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            fputcsv($output, $row);
        }
    } elseif ($type === 'trips') {
        fputcsv($output, ['Trip ID', 'Name', 'Trip Code', 'Currency', 'Starting Money', 'Status', 'Creator ID', 'Created At']);
        $stmt = $db->query("SELECT id, name, trip_code, currency, starting_money, status, created_by, created_at FROM trips ORDER BY id ASC");
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            fputcsv($output, $row);
        }
    } elseif ($type === 'transactions') {
        fputcsv($output, ['Tx ID', 'Trip ID', 'Description', 'Amount', 'Type', 'Payment Method', 'Paid By ID', 'Date']);
        $stmt = $db->query("SELECT id, trip_id, description, amount, type, payment_method, paid_by, transaction_date FROM transactions ORDER BY id DESC");
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            fputcsv($output, $row);
        }
    } elseif ($type === 'settlements') {
        fputcsv($output, ['Settlement ID', 'Trip ID', 'From User ID', 'To User ID', 'Amount', 'Payment Method', 'Status', 'Created At']);
        $stmt = $db->query("SELECT id, trip_id, from_user, to_user, amount, payment_method, status, created_at FROM settlements ORDER BY id DESC");
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            fputcsv($output, $row);
        }
    }
    fclose($output);
    exit;
}

include __DIR__ . '/includes/header.php';
?>

<div class="page-header">
    <div class="page-title-box">
        <h1>Reports & Export Center</h1>
        <p>Generate auditable CSV data reports for users, group trips, transactions, and peer debt settlements</p>
    </div>
</div>

<div class="grid-2">
    <!-- User Report Card -->
    <div class="card">
        <div class="card-header">
            <h3>Registered Users Report</h3>
        </div>
        <div class="card-body">
            <p style="color: #64748b; font-size: 13.5px; margin-bottom: 18px;">
                Complete ledger of registered users, verification badges, contact information, authentication provider, and account status.
            </p>
            <a href="reports.php?export=users" class="btn btn-primary">
                <i data-lucide="download"></i> Download Users CSV
            </a>
        </div>
    </div>

    <!-- Trip Report Card -->
    <div class="card">
        <div class="card-header">
            <h3>Trips & Groups Summary</h3>
        </div>
        <div class="card-body">
            <p style="color: #64748b; font-size: 13.5px; margin-bottom: 18px;">
                Complete record of group trips, invite codes, currency settings, starting pooled money, and active/archive status.
            </p>
            <a href="reports.php?export=trips" class="btn btn-primary">
                <i data-lucide="download"></i> Download Trips CSV
            </a>
        </div>
    </div>

    <!-- Transaction Report Card -->
    <div class="card">
        <div class="card-header">
            <h3>Financial Transactions Report</h3>
        </div>
        <div class="card-body">
            <p style="color: #64748b; font-size: 13.5px; margin-bottom: 18px;">
                All expense and income transactions, amount, payment method (Cash vs Bank/UPI), category ID, and primary payer.
            </p>
            <a href="reports.php?export=transactions" class="btn btn-primary">
                <i data-lucide="download"></i> Download Transactions CSV
            </a>
        </div>
    </div>

    <!-- Settlement Report Card -->
    <div class="card">
        <div class="card-header">
            <h3>Debt Settlements Report</h3>
        </div>
        <div class="card-body">
            <p style="color: #64748b; font-size: 13.5px; margin-bottom: 18px;">
                Person-to-person debt clearance history, debtors, receivers, repayment volume, and clearance status.
            </p>
            <a href="reports.php?export=settlements" class="btn btn-primary">
                <i data-lucide="download"></i> Download Settlements CSV
            </a>
        </div>
    </div>
</div>

<?php
include __DIR__ . '/includes/footer.php';
