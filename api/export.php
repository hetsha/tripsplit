<?php
/**
 * TripBook Export API — CSV & PDF
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/auth.php';

$currentUser = getCurrentUser();
$db = getDBConnection();

$format = $_GET['format'] ?? 'csv';
$tripId = (int)($_GET['trip_id'] ?? getActiveTripId());

if ($tripId <= 0) {
    die('No active trip');
}

// Verify membership
requireTripMembership($tripId, (int)$currentUser['id']);

// Get trip info
$stmt = $db->prepare("SELECT * FROM trips WHERE id = ?");
$stmt->execute([$tripId]);
$trip = $stmt->fetch();

// Get all transactions
$stmt = $db->prepare("
    SELECT t.*, 
           c.name AS category_name,
           u.name AS payer_name,
           r.name AS receiver_name,
           DATE_FORMAT(t.transaction_date, '%Y-%m-%d %H:%i') AS formatted_date
    FROM transactions t
    LEFT JOIN categories c ON c.id = t.category_id
    LEFT JOIN users u ON u.id = t.paid_by
    LEFT JOIN users r ON r.id = t.received_by
    WHERE t.trip_id = ?
    ORDER BY t.transaction_date ASC
");
$stmt->execute([$tripId]);
$transactions = $stmt->fetchAll();

// Get splits
$stmt = $db->prepare("
    SELECT es.*, u.name AS user_name
    FROM expense_splits es
    JOIN users u ON u.id = es.user_id
    JOIN transactions t ON t.id = es.transaction_id
    WHERE t.trip_id = ?
");
$stmt->execute([$tripId]);
$splits = $stmt->fetchAll();

// Get members
$stmt = $db->prepare("
    SELECT u.id, u.name, u.email, tm.role
    FROM users u
    JOIN trip_members tm ON tm.user_id = u.id
    WHERE tm.trip_id = ?
");
$stmt->execute([$tripId]);
$members = $stmt->fetchAll();

// Build summary
$summary = [
    'total_expenses' => 0,
    'total_income' => 0,
    'total_settlements' => 0,
];

foreach ($transactions as $tx) {
    if ($tx['type'] === 'expense') $summary['total_expenses'] += (float)$tx['amount'];
    elseif ($tx['type'] === 'income') $summary['total_income'] += (float)$tx['amount'];
    elseif ($tx['type'] === 'settlement') $summary['total_settlements'] += (float)$tx['amount'];
}

if ($format === 'csv') {
    header('Content-Type: text/csv; charset=utf-8');
    header('Content-Disposition: attachment; filename="tripbook_' . preg_replace('/[^a-z0-9]/i', '_', $trip['name']) . '_' . date('Y-m-d') . '.csv"');

    $out = fopen('php://output', 'w');

    // Header row
    fputcsv($out, ['TripBook Export — ' . $trip['name']]);
    fputcsv($out, ['Date', 'Type', 'Description', 'Amount', 'Paid By', 'Received By', 'Category', 'Payment Method', 'Notes']);
    fputcsv($out, []);

    foreach ($transactions as $tx) {
        fputcsv($out, [
            $tx['formatted_date'],
            ucfirst($tx['type']),
            $tx['description'],
            number_format((float)$tx['amount'], 2),
            $tx['payer_name'] ?? '',
            $tx['receiver_name'] ?? '',
            $tx['category_name'] ?? '',
            ucfirst($tx['payment_method']),
            $tx['notes'] ?? '',
        ]);
    }

    fputcsv($out, []);
    fputcsv($out, ['--- Summary ---']);
    fputcsv($out, ['Total Expenses', number_format($summary['total_expenses'], 2)]);
    fputcsv($out, ['Total Income', number_format($summary['total_income'], 2)]);
    fputcsv($out, ['Total Settlements', number_format($summary['total_settlements'], 2)]);

    fclose($out);
    exit;
}

if ($format === 'pdf') {
    // Generate a simple HTML-based PDF using browser print
    header('Content-Type: text/html; charset=utf-8');

    $currency = $trip['currency_symbol'] ?? '₹';

    echo '<!DOCTYPE html><html><head>';
    echo '<meta charset="utf-8">';
    echo '<title>TripBook Export — ' . htmlspecialchars($trip['name']) . '</title>';
    echo '<style>
        body { font-family: Arial, sans-serif; padding: 30px; color: #1e293b; }
        h1 { font-size: 22px; margin-bottom: 4px; }
        .subtitle { color: #64748b; font-size: 13px; margin-bottom: 20px; }
        table { width: 100%; border-collapse: collapse; font-size: 12px; margin-bottom: 20px; }
        th { background: #f1f5f9; text-align: left; padding: 8px; border-bottom: 2px solid #e2e8f0; font-weight: 700; }
        td { padding: 7px 8px; border-bottom: 1px solid #e2e8f0; }
        .summary { margin-top: 20px; font-size: 13px; }
        .summary div { display: flex; justify-content: space-between; padding: 4px 0; }
        .total { font-weight: 800; border-top: 2px solid #e2e8f0; padding-top: 8px; margin-top: 8px; }
        @media print { body { padding: 15px; } }
    </style></head><body>';

    echo '<h1>🧳 ' . htmlspecialchars($trip['name']) . '</h1>';
    echo '<div class="subtitle">TripBook Export • ' . date('M d, Y') . ' • ' . count($transactions) . ' transactions</div>';

    echo '<table><thead><tr><th>Date</th><th>Type</th><th>Description</th><th>Amount</th><th>Paid By</th><th>Category</th></tr></thead><tbody>';

    foreach ($transactions as $tx) {
        $typeBadge = $tx['type'] === 'expense' ? '<i data-lucide="alert-triangle" style="width:14px;height:14px;"></i>' : ($tx['type'] === 'income' ? '<i data-lucide="trending-up" style="width:14px;height:14px;"></i>' : '<i data-lucide="check-circle" style="width:14px;height:14px;"></i>');
        echo '<tr>';
        echo '<td>' . htmlspecialchars($tx['formatted_date']) . '</td>';
        echo '<td>' . $typeBadge . ' ' . ucfirst(htmlspecialchars($tx['type'])) . '</td>';
        echo '<td>' . htmlspecialchars($tx['description']) . '</td>';
        echo '<td style="text-align:right; font-weight:700;">' . $currency . number_format((float)$tx['amount'], 2) . '</td>';
        echo '<td>' . htmlspecialchars($tx['payer_name'] ?? $tx['receiver_name'] ?? '-') . '</td>';
        echo '<td>' . htmlspecialchars($tx['category_name'] ?? '-') . '</td>';
        echo '</tr>';
    }

    echo '</tbody></table>';

    echo '<div class="summary">';
    echo '<div><span>Total Expenses</span><strong>' . $currency . number_format($summary['total_expenses'], 2) . '</strong></div>';
    echo '<div><span>Total Income</span><strong>' . $currency . number_format($summary['total_income'], 2) . '</strong></div>';
    echo '<div class="total"><span>Total Settlements</span><strong>' . $currency . number_format($summary['total_settlements'], 2) . '</strong></div>';
    echo '</div>';

    echo '<script>window.onload = function() { window.print(); }</script>';
    echo '</body></html>';
    exit;
}

die('Invalid format. Use ?format=csv or ?format=pdf');
