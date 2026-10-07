<?php
/**
 * TripSplit Admin Panel - Trip Details & Inspector
 * Sections 14 & 15
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

requirePermission('trips.view');

$db = getDBConnection();
ensureAdminTablesExist($db);

$tripId = (int)($_GET['id'] ?? 0);
if ($tripId <= 0) {
    header('Location: trips.php');
    exit;
}

// 1. Fetch Trip Info
$stmt = $db->prepare("
    SELECT t.*, u.name as creator_name, u.phone as creator_phone, u.email as creator_email
    FROM trips t
    LEFT JOIN users u ON u.id = t.created_by
    WHERE t.id = ?
");
$stmt->execute([$tripId]);
$trip = $stmt->fetch();

if (!$trip) {
    header('Location: trips.php?error=not_found');
    exit;
}

// 2. Fetch Trip Members
$stmt = $db->prepare("
    SELECT tm.*, u.name, u.phone, u.email, u.avatar_color
    FROM trip_members tm
    JOIN users u ON u.id = tm.user_id
    WHERE tm.trip_id = ?
    ORDER BY tm.role = 'owner' DESC, tm.joined_at ASC
");
$stmt->execute([$tripId]);
$members = $stmt->fetchAll();

// 3. Fetch Trip Expenses
$stmt = $db->prepare("
    SELECT tx.*, u.name as paid_by_name, c.name as category_name
    FROM transactions tx
    LEFT JOIN users u ON u.id = tx.paid_by
    LEFT JOIN categories c ON c.id = tx.category_id
    WHERE tx.trip_id = ?
    ORDER BY tx.transaction_date DESC
    LIMIT 50
");
$stmt->execute([$tripId]);
$transactions = $stmt->fetchAll();

// 4. Fetch Trip Settlements
$stmt = $db->prepare("
    SELECT s.*, u1.name as from_user_name, u2.name as to_user_name
    FROM settlements s
    LEFT JOIN users u1 ON u1.id = s.from_user
    LEFT JOIN users u2 ON u2.id = s.to_user
    WHERE s.trip_id = ?
    ORDER BY s.created_at DESC
");
$stmt->execute([$tripId]);
$settlements = $stmt->fetchAll();

// Aggregate stats
$stmt = $db->prepare("SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE trip_id = ? AND type = 'expense'");
$stmt->execute([$tripId]);
$totalExpense = (float)$stmt->fetchColumn();

$stmt = $db->prepare("SELECT COALESCE(SUM(amount), 0) FROM settlements WHERE trip_id = ? AND status = 'paid'");
$stmt->execute([$tripId]);
$totalSettled = (float)$stmt->fetchColumn();

include __DIR__ . '/includes/header.php';
?>

<div class="page-header">
    <div class="page-title-box">
        <h1>Trip Inspector: <?= htmlspecialchars($trip['name']) ?></h1>
        <p>Invite Code: <code><?= htmlspecialchars($trip['trip_code']) ?></code> · Created by <?= htmlspecialchars($trip['creator_name'] ?? 'Unknown') ?> on <?= date('d M Y', strtotime($trip['created_at'])) ?></p>
    </div>
    <div class="page-actions">
        <a href="trips.php" class="btn btn-secondary">
            <i data-lucide="arrow-left"></i>
            <span>Back to Trips</span>
        </a>
    </div>
</div>

<!-- KPI Cards -->
<div class="kpi-grid">
    <div class="stat-card">
        <div class="stat-info">
            <span class="stat-label">Total Group Expenses</span>
            <div class="stat-value">₹<?= number_format($totalExpense, 2) ?></div>
            <div class="stat-subtext"><?= count($transactions) ?> bills logged</div>
        </div>
        <div class="stat-icon" style="background: #fef2f2; color: #ef4444;">
            <i data-lucide="receipt"></i>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-info">
            <span class="stat-label">Debts Settled</span>
            <div class="stat-value">₹<?= number_format($totalSettled, 2) ?></div>
            <div class="stat-subtext"><?= count($settlements) ?> transfers recorded</div>
        </div>
        <div class="stat-icon" style="background: #ecfdf5; color: #10b981;">
            <i data-lucide="check-check"></i>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-info">
            <span class="stat-label">Starting Pool Fund</span>
            <div class="stat-value">₹<?= number_format((float)$trip['starting_money'], 2) ?></div>
            <div class="stat-subtext">Method: <?= htmlspecialchars($trip['starting_payment_method'] ?? 'cash') ?></div>
        </div>
        <div class="stat-icon" style="background: #eff6ff; color: #2563eb;">
            <i data-lucide="coins"></i>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-info">
            <span class="stat-label">Total Members</span>
            <div class="stat-value"><?= count($members) ?></div>
            <div class="stat-subtext">Status: <?= htmlspecialchars($trip['status'] ?? 'active') ?></div>
        </div>
        <div class="stat-icon" style="background: #fffbeb; color: #f59e0b;">
            <i data-lucide="users"></i>
        </div>
    </div>
</div>

<!-- Members Table (Section 14) -->
<div class="card">
    <div class="card-header">
        <h3>Trip Roster (<?= count($members) ?> Members)</h3>
    </div>
    <div class="table-responsive">
        <table class="data-table">
            <thead>
                <tr>
                    <th>Member</th>
                    <th>Role in Group</th>
                    <th>Phone</th>
                    <th>Email</th>
                    <th>Joined At</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($members as $m): ?>
                    <tr>
                        <td>
                            <div style="display: flex; align-items: center; gap: 10px;">
                                <div style="width: 32px; height: 32px; border-radius: 50%; background: <?= htmlspecialchars($m['avatar_color'] ?? '#2563eb') ?>; color: white; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 13px;">
                                    <?= strtoupper(substr($m['name'] ?? 'M', 0, 1)) ?>
                                </div>
                                <a href="user-detail.php?id=<?= $m['user_id'] ?>" style="font-weight: 700; color: #0f172a; text-decoration: none;">
                                    <?= htmlspecialchars($m['name']) ?>
                                </a>
                            </div>
                        </td>
                        <td>
                            <span class="badge <?= $m['role'] === 'owner' ? 'badge-primary' : ($m['role'] === 'admin' ? 'badge-purple' : 'badge-secondary') ?>">
                                <?= htmlspecialchars($m['role']) ?>
                            </span>
                        </td>
                        <td><?= htmlspecialchars($m['phone'] ?: 'N/A') ?></td>
                        <td><?= htmlspecialchars($m['email'] ?: 'N/A') ?></td>
                        <td><?= date('d M Y, H:i', strtotime($m['joined_at'])) ?></td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>

<!-- Expenses and Settlements in Grid -->
<div class="grid-2">
    <!-- Transactions List -->
    <div class="card">
        <div class="card-header">
            <h3>Recent Expenses (<?= count($transactions) ?>)</h3>
        </div>
        <div class="table-responsive">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Description</th>
                        <th>Paid By</th>
                        <th>Amount</th>
                        <th>Method</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($transactions)): ?>
                        <tr><td colspan="4" style="text-align: center; color: #94a3b8;">No expenses recorded yet.</td></tr>
                    <?php else: ?>
                        <?php foreach ($transactions as $tx): ?>
                            <tr>
                                <td>
                                    <strong><?= htmlspecialchars($tx['description']) ?></strong>
                                    <div style="font-size: 11px; color: #64748b;"><?= htmlspecialchars($tx['category_name'] ?? 'General') ?></div>
                                </td>
                                <td><?= htmlspecialchars($tx['paid_by_name'] ?? 'Direct') ?></td>
                                <td style="font-weight: 700;">₹<?= number_format((float)$tx['amount'], 2) ?></td>
                                <td><span class="badge badge-secondary"><?= htmlspecialchars($tx['payment_method']) ?></span></td>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Settlements List -->
    <div class="card">
        <div class="card-header">
            <h3>Settlement Records (<?= count($settlements) ?>)</h3>
        </div>
        <div class="table-responsive">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>From $\rightarrow$ To</th>
                        <th>Amount</th>
                        <th>Method</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($settlements)): ?>
                        <tr><td colspan="4" style="text-align: center; color: #94a3b8;">No settlements recorded yet.</td></tr>
                    <?php else: ?>
                        <?php foreach ($settlements as $st): ?>
                            <tr>
                                <td>
                                    <strong><?= htmlspecialchars($st['from_user_name'] ?? 'Unknown') ?></strong>
                                    <span style="color: #64748b;">$\rightarrow$</span>
                                    <strong><?= htmlspecialchars($st['to_user_name'] ?? 'Unknown') ?></strong>
                                </td>
                                <td style="font-weight: 700; color: #059669;">₹<?= number_format((float)$st['amount'], 2) ?></td>
                                <td><?= htmlspecialchars($st['payment_method']) ?></td>
                                <td>
                                    <span class="badge <?= $st['status'] === 'paid' ? 'badge-success' : 'badge-warning' ?>">
                                        <?= htmlspecialchars($st['status']) ?>
                                    </span>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<?php
include __DIR__ . '/includes/footer.php';
