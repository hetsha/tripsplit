<?php
/**
 * TripSplit Admin Panel - Transactions & Splits Explorer
 * Sections 16, 17, 18
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

requirePermission('transactions.view');

$db = getDBConnection();
ensureAdminTablesExist($db);

// Search & Filtering (Section 16.3)
$search = trim($_GET['search'] ?? '');
$typeFilter = trim($_GET['type'] ?? 'all');
$paymentFilter = trim($_GET['payment_method'] ?? 'all');
$tripId = (int)($_GET['trip_id'] ?? 0);
$page = max(1, (int)($_GET['page'] ?? 1));
$limit = 20;
$offset = ($page - 1) * $limit;

$where = ["1=1"];
$params = [];

if (!empty($search)) {
    $where[] = "(tx.description LIKE ? OR u.name LIKE ? OR t.name LIKE ?)";
    $like = "%$search%";
    $params[] = $like;
    $params[] = $like;
    $params[] = $like;
}

if ($typeFilter !== 'all' && in_array($typeFilter, ['expense', 'income', 'settlement'])) {
    $where[] = "tx.type = ?";
    $params[] = $typeFilter;
}

if ($paymentFilter !== 'all') {
    $where[] = "tx.payment_method = ?";
    $params[] = $paymentFilter;
}

if ($tripId > 0) {
    $where[] = "tx.trip_id = ?";
    $params[] = $tripId;
}

$whereClause = implode(' AND ', $where);

// Count
$countStmt = $db->prepare("
    SELECT COUNT(*) FROM transactions tx
    LEFT JOIN trips t ON t.id = tx.trip_id
    LEFT JOIN users u ON u.id = tx.paid_by
    WHERE $whereClause
");
$countStmt->execute($params);
$totalRows = (int)$countStmt->fetchColumn();
$totalPages = max(1, (int)ceil($totalRows / $limit));

// Fetch Transactions
$query = "
    SELECT tx.*,
           t.name as trip_name,
           u.name as paid_by_name,
           c.name as category_name,
           (SELECT COUNT(*) FROM expense_splits WHERE transaction_id = tx.id) as split_count
    FROM transactions tx
    LEFT JOIN trips t ON t.id = tx.trip_id
    LEFT JOIN users u ON u.id = tx.paid_by
    LEFT JOIN categories c ON c.id = tx.category_id
    WHERE $whereClause
    ORDER BY tx.transaction_date DESC
    LIMIT $limit OFFSET $offset
";
$stmt = $db->prepare($query);
$stmt->execute($params);
$transactions = $stmt->fetchAll();

// Available trips for dropdown
$tripsList = $db->query("SELECT id, name FROM trips ORDER BY name ASC LIMIT 50")->fetchAll();

include __DIR__ . '/includes/header.php';
?>

<div class="page-header">
    <div class="page-title-box">
        <h1>Transactions & Expense Ledger</h1>
        <p>Inspect group and individual spending, multi-payer contributions, and split proportions</p>
    </div>
    <div class="page-actions">
        <a href="reports.php?type=transactions" class="btn btn-secondary">
            <i data-lucide="download"></i>
            <span>Export Transactions CSV</span>
        </a>
    </div>
</div>

<!-- Filters -->
<form method="GET" action="transactions.php" class="filter-bar">
    <div style="flex: 1; min-width: 200px;">
        <input type="text" name="search" placeholder="Search by description, payer, or trip name..." 
               value="<?= htmlspecialchars($search) ?>" style="width: 100%;">
    </div>
    <div>
        <select name="type" onchange="this.form.submit()">
            <option value="all" <?= $typeFilter === 'all' ? 'selected' : '' ?>>All Types</option>
            <option value="expense" <?= $typeFilter === 'expense' ? 'selected' : '' ?>>Expense</option>
            <option value="income" <?= $typeFilter === 'income' ? 'selected' : '' ?>>Income</option>
            <option value="settlement" <?= $typeFilter === 'settlement' ? 'selected' : '' ?>>Settlement</option>
        </select>
    </div>
    <div>
        <select name="payment_method" onchange="this.form.submit()">
            <option value="all" <?= $paymentFilter === 'all' ? 'selected' : '' ?>>All Payment Methods</option>
            <option value="cash" <?= $paymentFilter === 'cash' ? 'selected' : '' ?>>Cash</option>
            <option value="bank" <?= $paymentFilter === 'bank' ? 'selected' : '' ?>>Bank / UPI</option>
        </select>
    </div>
    <div>
        <select name="trip_id" onchange="this.form.submit()">
            <option value="0">All Trips</option>
            <?php foreach ($tripsList as $tr): ?>
                <option value="<?= $tr['id'] ?>" <?= $tripId === (int)$tr['id'] ? 'selected' : '' ?>>
                    <?= htmlspecialchars($tr['name']) ?>
                </option>
            <?php endforeach; ?>
        </select>
    </div>
    <button type="submit" class="btn btn-primary btn-sm">Filter</button>
    <?php if (!empty($search) || $typeFilter !== 'all' || $paymentFilter !== 'all' || $tripId > 0): ?>
        <a href="transactions.php" class="btn btn-secondary btn-sm">Reset</a>
    <?php endif; ?>
</form>

<!-- Transactions Table (Section 16.2) -->
<div class="card">
    <div class="table-responsive">
        <table class="data-table">
            <thead>
                <tr>
                    <th>Tx ID</th>
                    <th>Description</th>
                    <th>Amount</th>
                    <th>Type</th>
                    <th>Trip</th>
                    <th>Paid By</th>
                    <th>Category</th>
                    <th>Method</th>
                    <th>Date</th>
                    <th style="text-align: right;">Action</th>
                </tr>
            </thead>
            <tbody>
                <?php if (empty($transactions)): ?>
                    <tr>
                        <td colspan="10" style="text-align: center; padding: 40px; color: #94a3b8;">
                            No transactions found matching your criteria.
                        </td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($transactions as $tx): ?>
                        <tr>
                            <td style="color: #64748b; font-weight: 600;">#<?= $tx['id'] ?></td>
                            <td>
                                <strong><?= htmlspecialchars($tx['description']) ?></strong>
                                <?php if ($tx['split_count'] > 0): ?>
                                    <span class="badge badge-purple" style="font-size: 10px; margin-left: 4px;">
                                        <?= $tx['split_count'] ?> splits
                                    </span>
                                <?php endif; ?>
                            </td>
                            <td style="font-weight: 800; color: <?= $tx['type'] === 'expense' ? '#ef4444' : '#10b981' ?>;">
                                ₹<?= number_format((float)$tx['amount'], 2) ?>
                            </td>
                            <td>
                                <span class="badge <?= $tx['type'] === 'expense' ? 'badge-danger' : 'badge-primary' ?>">
                                    <?= htmlspecialchars($tx['type']) ?>
                                </span>
                            </td>
                            <td>
                                <?php if (!empty($tx['trip_id'])): ?>
                                    <a href="trip-detail.php?id=<?= $tx['trip_id'] ?>" style="color: #2563eb; text-decoration: none; font-weight: 600;">
                                        <?= htmlspecialchars($tx['trip_name'] ?? 'Trip #' . $tx['trip_id']) ?>
                                    </a>
                                <?php else: ?>
                                    <span style="color: #94a3b8;">Personal</span>
                                <?php endif; ?>
                            </td>
                            <td><?= htmlspecialchars($tx['paid_by_name'] ?? 'Direct') ?></td>
                            <td>
                                <span class="badge badge-secondary"><?= htmlspecialchars($tx['category_name'] ?? 'General') ?></span>
                            </td>
                            <td><?= strtoupper(htmlspecialchars($tx['payment_method'])) ?></td>
                            <td style="font-size: 12px; color: #64748b;">
                                <?= date('d M Y, H:i', strtotime($tx['transaction_date'])) ?>
                            </td>
                            <td style="text-align: right;">
                                <a href="transaction-detail.php?id=<?= $tx['id'] ?>" class="btn btn-secondary btn-sm" title="Inspect Splits">
                                    <i data-lucide="eye" style="width: 14px; height: 14px;"></i>
                                </a>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>

    <!-- Pagination -->
    <?php if ($totalPages > 1): ?>
        <div class="pagination-wrapper">
            <span style="font-size: 13px; color: #64748b;">
                Showing page <?= $page ?> of <?= $totalPages ?> (<?= $totalRows ?> total transactions)
            </span>
            <div class="pagination-links">
                <?php for ($i = 1; $i <= $totalPages; $i++): ?>
                    <a href="transactions.php?page=<?= $i ?>&search=<?= urlencode($search) ?>&type=<?= urlencode($typeFilter) ?>&payment_method=<?= urlencode($paymentFilter) ?>&trip_id=<?= $tripId ?>" 
                       class="page-num <?= $i === $page ? 'active' : '' ?>">
                        <?= $i ?>
                    </a>
                <?php endfor; ?>
            </div>
        </div>
    <?php endif; ?>
</div>

<?php
include __DIR__ . '/includes/footer.php';
