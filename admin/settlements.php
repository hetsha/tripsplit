<?php
/**
 * TripSplit Admin Panel - Settlements & Debt Resolution
 * Sections 19 & 20
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

requirePermission('settlements.view');

$db = getDBConnection();
ensureAdminTablesExist($db);

$msg = '';
$error = '';

// Handle actions (Section 20)
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    requirePermission('settlements.manage');
    $action = $_POST['action'] ?? '';
    $settlementId = (int)($_POST['settlement_id'] ?? 0);
    $reason = trim($_POST['reason'] ?? 'Admin settlement reconciliation');

    if ($settlementId > 0) {
        $stStmt = $db->prepare("SELECT * FROM settlements WHERE id = ?");
        $stStmt->execute([$settlementId]);
        $targetSettlement = $stStmt->fetch();

        if ($targetSettlement) {
            if ($action === 'mark_paid') {
                $stmt = $db->prepare("UPDATE settlements SET status = 'paid', paid_at = NOW() WHERE id = ?");
                $stmt->execute([$settlementId]);
                logAdminAudit('SETTLE_DEBT', 'settlements', 'settlement', (string)$settlementId, $targetSettlement['status'], 'paid', $reason);
                $msg = "Settlement #$settlementId marked as paid.";
            } elseif ($action === 'mark_pending') {
                $stmt = $db->prepare("UPDATE settlements SET status = 'pending' WHERE id = ?");
                $stmt->execute([$settlementId]);
                logAdminAudit('DISPUTE_SETTLEMENT', 'settlements', 'settlement', (string)$settlementId, $targetSettlement['status'], 'pending', $reason);
                $msg = "Settlement #$settlementId marked as pending.";
            }
        }
    }
}

// KPI metrics (Section 19.1)
$stats = [];
$stmt = $db->query("
    SELECT 
        COUNT(*) as total_count,
        COALESCE(SUM(amount), 0) as total_volume,
        SUM(CASE WHEN status = 'paid' THEN 1 ELSE 0 END) as paid_count,
        SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending_count
    FROM settlements
");
$stats = $stmt->fetch();

// Filtering & Pagination
$statusFilter = trim($_GET['status'] ?? 'all');
$search = trim($_GET['search'] ?? '');
$page = max(1, (int)($_GET['page'] ?? 1));
$limit = 20;
$offset = ($page - 1) * $limit;

$where = ["1=1"];
$params = [];

if ($statusFilter !== 'all') {
    $where[] = "s.status = ?";
    $params[] = $statusFilter;
}

if (!empty($search)) {
    $where[] = "(u1.name LIKE ? OR u2.name LIKE ? OR t.name LIKE ?)";
    $like = "%$search%";
    $params[] = $like;
    $params[] = $like;
    $params[] = $like;
}

$whereClause = implode(' AND ', $where);

// Count
$countStmt = $db->prepare("
    SELECT COUNT(*) FROM settlements s
    LEFT JOIN users u1 ON u1.id = s.from_user
    LEFT JOIN users u2 ON u2.id = s.to_user
    LEFT JOIN trips t ON t.id = s.trip_id
    WHERE $whereClause
");
$countStmt->execute($params);
$totalRows = (int)$countStmt->fetchColumn();
$totalPages = max(1, (int)ceil($totalRows / $limit));

// Fetch settlements
$query = "
    SELECT s.*,
           u1.name as from_user_name,
           u2.name as to_user_name,
           t.name as trip_name
    FROM settlements s
    LEFT JOIN users u1 ON u1.id = s.from_user
    LEFT JOIN users u2 ON u2.id = s.to_user
    LEFT JOIN trips t ON t.id = s.trip_id
    WHERE $whereClause
    ORDER BY s.created_at DESC
    LIMIT $limit OFFSET $offset
";
$stmt = $db->prepare($query);
$stmt->execute($params);
$settlements = $stmt->fetchAll();

include __DIR__ . '/includes/header.php';
?>

<div class="page-header">
    <div class="page-title-box">
        <h1>Settlement & Debt Ledger</h1>
        <p>Monitor person-to-person debt clearance, UPI transfers, and pending balance reconciliations</p>
    </div>
    <div class="page-actions">
        <a href="reports.php?type=settlements" class="btn btn-secondary">
            <i data-lucide="download"></i>
            <span>Export Settlements CSV</span>
        </a>
    </div>
</div>

<?php if (!empty($msg)): ?>
    <div class="alert alert-success">✓ <?= htmlspecialchars($msg) ?></div>
<?php endif; ?>

<!-- KPI Summary Cards (Section 19.1) -->
<div class="kpi-grid">
    <div class="stat-card">
        <div class="stat-info">
            <span class="stat-label">Total Settlements</span>
            <div class="stat-value"><?= number_format((int)$stats['total_count']) ?></div>
            <div class="stat-subtext">All time debt actions</div>
        </div>
        <div class="stat-icon" style="background: #eff6ff; color: #2563eb;">
            <i data-lucide="hand-coins"></i>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-info">
            <span class="stat-label">Total Volume Settled</span>
            <div class="stat-value">₹<?= number_format((float)$stats['total_volume'], 0) ?></div>
            <div class="stat-subtext">Repayments between users</div>
        </div>
        <div class="stat-icon" style="background: #ecfdf5; color: #10b981;">
            <i data-lucide="wallet"></i>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-info">
            <span class="stat-label">Paid / Completed</span>
            <div class="stat-value"><?= number_format((int)$stats['paid_count']) ?></div>
            <div class="stat-subtext">Verified repayments</div>
        </div>
        <div class="stat-icon" style="background: #ecfdf5; color: #059669;">
            <i data-lucide="check-circle-2"></i>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-info">
            <span class="stat-label">Pending Settlements</span>
            <div class="stat-value"><?= number_format((int)$stats['pending_count']) ?></div>
            <div class="stat-subtext">Awaiting payment</div>
        </div>
        <div class="stat-icon" style="background: #fffbeb; color: #f59e0b;">
            <i data-lucide="clock"></i>
        </div>
    </div>
</div>

<!-- Filters -->
<form method="GET" action="settlements.php" class="filter-bar">
    <div style="flex: 1; min-width: 200px;">
        <input type="text" name="search" placeholder="Search by debtor, receiver, or trip name..." 
               value="<?= htmlspecialchars($search) ?>" style="width: 100%;">
    </div>
    <div>
        <select name="status" onchange="this.form.submit()">
            <option value="all" <?= $statusFilter === 'all' ? 'selected' : '' ?>>All Statuses</option>
            <option value="paid" <?= $statusFilter === 'paid' ? 'selected' : '' ?>>Completed / Paid</option>
            <option value="pending" <?= $statusFilter === 'pending' ? 'selected' : '' ?>>Pending Clearance</option>
        </select>
    </div>
    <button type="submit" class="btn btn-primary btn-sm">Filter</button>
    <?php if (!empty($search) || $statusFilter !== 'all'): ?>
        <a href="settlements.php" class="btn btn-secondary btn-sm">Reset</a>
    <?php endif; ?>
</form>

<!-- Settlements Table (Section 19.2) -->
<div class="card">
    <div class="table-responsive">
        <table class="data-table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Debtor (From)</th>
                    <th>Receiver (To)</th>
                    <th>Trip Group</th>
                    <th>Amount</th>
                    <th>Method</th>
                    <th>Status</th>
                    <th>Date</th>
                    <th style="text-align: right;">Action</th>
                </tr>
            </thead>
            <tbody>
                <?php if (empty($settlements)): ?>
                    <tr>
                        <td colspan="9" style="text-align: center; padding: 40px; color: #94a3b8;">
                            No settlement records found.
                        </td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($settlements as $st): ?>
                        <tr>
                            <td style="color: #64748b; font-weight: 600;">#<?= $st['id'] ?></td>
                            <td>
                                <strong><?= htmlspecialchars($st['from_user_name'] ?? 'User #' . $st['from_user']) ?></strong>
                            </td>
                            <td>
                                <strong><?= htmlspecialchars($st['to_user_name'] ?? 'User #' . $st['to_user']) ?></strong>
                            </td>
                            <td>
                                <?php if (!empty($st['trip_id'])): ?>
                                    <a href="trip-detail.php?id=<?= $st['trip_id'] ?>" style="color: #2563eb; text-decoration: none;">
                                        <?= htmlspecialchars($st['trip_name'] ?? 'Trip #' . $st['trip_id']) ?>
                                    </a>
                                <?php else: ?>
                                    <span style="color: #94a3b8;">Direct</span>
                                <?php endif; ?>
                            </td>
                            <td style="font-weight: 800; color: #059669;">
                                ₹<?= number_format((float)$st['amount'], 2) ?>
                            </td>
                            <td>
                                <span class="badge badge-secondary"><?= strtoupper(htmlspecialchars($st['payment_method'])) ?></span>
                            </td>
                            <td>
                                <span class="badge <?= $st['status'] === 'paid' ? 'badge-success' : 'badge-warning' ?>">
                                    <?= htmlspecialchars($st['status']) ?>
                                </span>
                            </td>
                            <td style="font-size: 12px; color: #64748b;">
                                <?= date('d M Y, H:i', strtotime($st['created_at'])) ?>
                            </td>
                            <td style="text-align: right;">
                                <?php if ($st['status'] === 'pending'): ?>
                                    <form method="POST" style="display:inline;" onsubmit="return confirm('Mark this settlement as PAID?');">
                                        <?= csrfField() ?>
                                        <input type="hidden" name="settlement_id" value="<?= $st['id'] ?>">
                                        <input type="hidden" name="action" value="mark_paid">
                                        <button type="submit" class="btn btn-secondary btn-sm" style="color: #059669;" title="Mark Paid">
                                            <i data-lucide="check" style="width: 14px; height: 14px;"></i> Mark Paid
                                        </button>
                                    </form>
                                <?php else: ?>
                                    <span style="color: #10b981; font-size: 12px; font-weight: 700;">✓ Settled</span>
                                <?php endif; ?>
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
                Showing page <?= $page ?> of <?= $totalPages ?> (<?= $totalRows ?> total settlements)
            </span>
            <div class="pagination-links">
                <?php for ($i = 1; $i <= $totalPages; $i++): ?>
                    <a href="settlements.php?page=<?= $i ?>&search=<?= urlencode($search) ?>&status=<?= urlencode($statusFilter) ?>" 
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
