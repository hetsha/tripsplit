<?php
/**
 * TripSplit Admin Panel - Transaction & Splits Detail Inspector
 * Sections 17 & 18
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

requirePermission('transactions.view');

$db = getDBConnection();
ensureAdminTablesExist($db);

$txId = (int)($_GET['id'] ?? 0);
if ($txId <= 0) {
    header('Location: transactions.php');
    exit;
}

// 1. Fetch Transaction
$stmt = $db->prepare("
    SELECT tx.*,
           t.name as trip_name,
           u_paid.name as paid_by_name,
           u_created.name as created_by_name,
           c.name as category_name
    FROM transactions tx
    LEFT JOIN trips t ON t.id = tx.trip_id
    LEFT JOIN users u_paid ON u_paid.id = tx.paid_by
    LEFT JOIN users u_created ON u_created.id = tx.created_by
    LEFT JOIN categories c ON c.id = tx.category_id
    WHERE tx.id = ?
");
$stmt->execute([$txId]);
$tx = $stmt->fetch();

if (!$tx) {
    header('Location: transactions.php?error=not_found');
    exit;
}

// 2. Fetch Beneficiary Splits (Section 18)
$stmt = $db->prepare("
    SELECT es.*, u.name as user_name, u.phone, u.avatar_color
    FROM expense_splits es
    JOIN users u ON u.id = es.user_id
    WHERE es.transaction_id = ?
    ORDER BY es.amount DESC
");
$stmt->execute([$txId]);
$splits = $stmt->fetchAll();

// 3. Fetch Multi-Payers (Section 17)
$stmt = $db->prepare("
    SELECT tp.*, u.name as user_name
    FROM transaction_payers tp
    JOIN users u ON u.id = tp.user_id
    WHERE tp.transaction_id = ?
    ORDER BY tp.amount DESC
");
$stmt->execute([$txId]);
$payers = $stmt->fetchAll();

include __DIR__ . '/includes/header.php';
?>

<div class="page-header">
    <div class="page-title-box">
        <h1>Transaction Inspector #<?= $tx['id'] ?>: <?= htmlspecialchars($tx['description']) ?></h1>
        <p>Recorded on <?= date('d M Y, H:i', strtotime($tx['transaction_date'])) ?> by <?= htmlspecialchars($tx['created_by_name'] ?? 'System') ?></p>
    </div>
    <div class="page-actions">
        <a href="transactions.php" class="btn btn-secondary">
            <i data-lucide="arrow-left"></i>
            <span>Back to Transactions</span>
        </a>
    </div>
</div>

<div class="grid-2">
    <!-- Transaction Overview Card -->
    <div class="card">
        <div class="card-header">
            <h3>Overview & Accounting</h3>
        </div>
        <div class="card-body">
            <div style="display: flex; flex-direction: column; gap: 14px; font-size: 14px;">
                <div style="display: flex; justify-content: space-between; border-bottom: 1px solid #f1f5f9; padding-bottom: 8px;">
                    <span style="color: #64748b;">Total Amount:</span>
                    <strong style="font-size: 18px; color: <?= $tx['type'] === 'expense' ? '#ef4444' : '#10b981' ?>;">
                        ₹<?= number_format((float)$tx['amount'], 2) ?>
                    </strong>
                </div>
                <div style="display: flex; justify-content: space-between; border-bottom: 1px solid #f1f5f9; padding-bottom: 8px;">
                    <span style="color: #64748b;">Transaction Type:</span>
                    <span class="badge <?= $tx['type'] === 'expense' ? 'badge-danger' : 'badge-primary' ?>">
                        <?= strtoupper($tx['type']) ?>
                    </span>
                </div>
                <div style="display: flex; justify-content: space-between; border-bottom: 1px solid #f1f5f9; padding-bottom: 8px;">
                    <span style="color: #64748b;">Associated Trip:</span>
                    <?php if (!empty($tx['trip_id'])): ?>
                        <a href="trip-detail.php?id=<?= $tx['trip_id'] ?>" style="color: #2563eb; font-weight: 700; text-decoration: none;">
                            <?= htmlspecialchars($tx['trip_name'] ?? 'Trip #' . $tx['trip_id']) ?>
                        </a>
                    <?php else: ?>
                        <span>Personal Expense (No Group)</span>
                    <?php endif; ?>
                </div>
                <div style="display: flex; justify-content: space-between; border-bottom: 1px solid #f1f5f9; padding-bottom: 8px;">
                    <span style="color: #64748b;">Category:</span>
                    <span class="badge badge-secondary"><?= htmlspecialchars($tx['category_name'] ?? 'General') ?></span>
                </div>
                <div style="display: flex; justify-content: space-between; border-bottom: 1px solid #f1f5f9; padding-bottom: 8px;">
                    <span style="color: #64748b;">Primary Payer:</span>
                    <strong><?= htmlspecialchars($tx['paid_by_name'] ?? 'Direct Transfer') ?></strong>
                </div>
                <div style="display: flex; justify-content: space-between; border-bottom: 1px solid #f1f5f9; padding-bottom: 8px;">
                    <span style="color: #64748b;">Payment Method:</span>
                    <span style="font-weight: 600; text-transform: uppercase;"><?= htmlspecialchars($tx['payment_method']) ?></span>
                </div>
                <div style="display: flex; justify-content: space-between;">
                    <span style="color: #64748b;">Notes / Memo:</span>
                    <span><?= htmlspecialchars($tx['notes'] ?: 'None') ?></span>
                </div>
            </div>
        </div>
    </div>

    <!-- Multi-Payers (Section 17) -->
    <div class="card">
        <div class="card-header">
            <h3>Payer Breakdown (<?= count($payers) ?: 1 ?>)</h3>
        </div>
        <div class="table-responsive">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Payer</th>
                        <th>Amount Paid</th>
                        <th>Share %</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($payers)): ?>
                        <tr>
                            <td><strong><?= htmlspecialchars($tx['paid_by_name'] ?? 'Primary Payer') ?></strong></td>
                            <td style="font-weight: 700;">₹<?= number_format((float)$tx['amount'], 2) ?></td>
                            <td><span class="badge badge-success">100%</span></td>
                        </tr>
                    <?php else: ?>
                        <?php foreach ($payers as $p): ?>
                            <?php $percent = $tx['amount'] > 0 ? round(($p['amount'] / $tx['amount']) * 100, 1) : 0; ?>
                            <tr>
                                <td><strong><?= htmlspecialchars($p['user_name']) ?></strong></td>
                                <td style="font-weight: 700;">₹<?= number_format((float)$p['amount'], 2) ?></td>
                                <td><span class="badge badge-primary"><?= $percent ?>%</span></td>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- Beneficiary Expense Splits (Section 18) -->
<div class="card">
    <div class="card-header">
        <h3>Who Owes What (<?= count($splits) ?> Participants Included in Split)</h3>
    </div>
    <div class="table-responsive">
        <table class="data-table">
            <thead>
                <tr>
                    <th>Participant</th>
                    <th>Phone</th>
                    <th>Owed Share</th>
                    <th>Percentage of Bill</th>
                </tr>
            </thead>
            <tbody>
                <?php if (empty($splits)): ?>
                    <tr>
                        <td colspan="4" style="text-align: center; padding: 30px; color: #94a3b8;">
                            No individual split records found for this transaction.
                        </td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($splits as $sp): ?>
                        <?php $sharePercent = $tx['amount'] > 0 ? round(($sp['amount'] / $tx['amount']) * 100, 1) : 0; ?>
                        <tr>
                            <td>
                                <div style="display: flex; align-items: center; gap: 8px;">
                                    <div style="width: 30px; height: 30px; border-radius: 50%; background: <?= htmlspecialchars($sp['avatar_color'] ?? '#2563eb') ?>; color: white; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 12px;">
                                        <?= strtoupper(substr($sp['user_name'] ?? 'U', 0, 1)) ?>
                                    </div>
                                    <a href="user-detail.php?id=<?= $sp['user_id'] ?>" style="font-weight: 700; color: #0f172a; text-decoration: none;">
                                        <?= htmlspecialchars($sp['user_name']) ?>
                                    </a>
                                </div>
                            </td>
                            <td><?= htmlspecialchars($sp['phone'] ?: 'N/A') ?></td>
                            <td style="font-weight: 700; color: #dc2626;">
                                ₹<?= number_format((float)$sp['amount'], 2) ?>
                            </td>
                            <td>
                                <span class="badge badge-secondary"><?= $sharePercent ?>%</span>
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
