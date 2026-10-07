<?php
/**
 * TripSplit Admin Panel - Trips & Groups Management
 * Sections 13, 14, 15
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

requirePermission('trips.view');

$db = getDBConnection();
ensureAdminTablesExist($db);

$msg = '';
$error = '';

// Handle actions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    $tripId = (int)($_POST['trip_id'] ?? 0);
    $reason = trim($_POST['reason'] ?? 'Admin action on trip');

    if ($tripId > 0) {
        $tripStmt = $db->prepare("SELECT * FROM trips WHERE id = ?");
        $tripStmt->execute([$tripId]);
        $targetTrip = $tripStmt->fetch();

        if ($targetTrip) {
            if ($action === 'archive') {
                requirePermission('trips.archive');
                $stmt = $db->prepare("UPDATE trips SET status = 'archived' WHERE id = ?");
                $stmt->execute([$tripId]);
                logAdminAudit('ARCHIVE_TRIP', 'trips', 'trip', (string)$tripId, $targetTrip['status'] ?? 'active', 'archived', $reason);
                $msg = 'Trip archived successfully.';
            } elseif ($action === 'restore') {
                requirePermission('trips.edit');
                $stmt = $db->prepare("UPDATE trips SET status = 'active' WHERE id = ?");
                $stmt->execute([$tripId]);
                logAdminAudit('RESTORE_TRIP', 'trips', 'trip', (string)$tripId, $targetTrip['status'] ?? 'archived', 'active', $reason);
                $msg = 'Trip restored to active status.';
            } elseif ($action === 'delete') {
                requirePermission('trips.delete');
                $confirmText = trim($_POST['confirm_text'] ?? '');
                if ($confirmText !== 'DELETE') {
                    $error = 'You must type DELETE to confirm permanent deletion.';
                } else {
                    $stmt = $db->prepare("DELETE FROM trips WHERE id = ?");
                    $stmt->execute([$tripId]);
                    logAdminAudit('DELETE_TRIP', 'trips', 'trip', (string)$tripId, $targetTrip, null, $reason);
                    $msg = 'Trip deleted permanently.';
                }
            }
        }
    }
}

// Search & Filtering (Section 13.2 & 13.3)
$search = trim($_GET['search'] ?? '');
$statusFilter = trim($_GET['status'] ?? 'all');
$page = max(1, (int)($_GET['page'] ?? 1));
$limit = 15;
$offset = ($page - 1) * $limit;

$where = ["1=1"];
$params = [];

if (!empty($search)) {
    $where[] = "(t.name LIKE ? OR t.trip_code LIKE ? OR u.name LIKE ? OR t.id = ?)";
    $like = "%$search%";
    $params[] = $like;
    $params[] = $like;
    $params[] = $like;
    $params[] = is_numeric($search) ? (int)$search : 0;
}

if ($statusFilter === 'active') {
    $where[] = "(t.status = 'active' OR t.status IS NULL)";
} elseif ($statusFilter === 'archived') {
    $where[] = "t.status = 'archived'";
} elseif ($statusFilter === 'completed') {
    $where[] = "t.status = 'completed'";
}

$whereClause = implode(' AND ', $where);

// Count
$countStmt = $db->prepare("
    SELECT COUNT(*) FROM trips t 
    LEFT JOIN users u ON u.id = t.created_by 
    WHERE $whereClause
");
$countStmt->execute($params);
$totalRows = (int)$countStmt->fetchColumn();
$totalPages = max(1, (int)ceil($totalRows / $limit));

// Fetch trips with aggregated statistics
$query = "
    SELECT t.*,
           u.name as creator_name,
           (SELECT COUNT(*) FROM trip_members WHERE trip_id = t.id) as member_count,
           (SELECT COUNT(*) FROM transactions WHERE trip_id = t.id) as transaction_count,
           (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE trip_id = t.id AND type = 'expense') as total_expenses,
           (SELECT COALESCE(SUM(amount), 0) FROM settlements WHERE trip_id = t.id) as total_settled
    FROM trips t
    LEFT JOIN users u ON u.id = t.created_by
    WHERE $whereClause
    ORDER BY t.created_at DESC
    LIMIT $limit OFFSET $offset
";
$stmt = $db->prepare($query);
$stmt->execute($params);
$trips = $stmt->fetchAll();

include __DIR__ . '/includes/header.php';
?>

<div class="page-header">
    <div class="page-title-box">
        <h1>Trips & Groups Explorer</h1>
        <p>Monitor shared travel groups, member counts, pooled starting money, and total expenditures</p>
    </div>
    <div class="page-actions">
        <a href="reports.php?type=trips" class="btn btn-secondary">
            <i data-lucide="download"></i>
            <span>Export Trips CSV</span>
        </a>
    </div>
</div>

<?php if (!empty($msg)): ?>
    <div class="alert alert-success">✓ <?= htmlspecialchars($msg) ?></div>
<?php endif; ?>
<?php if (!empty($error)): ?>
    <div class="alert alert-danger">⚠️ <?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<!-- Filters -->
<form method="GET" action="trips.php" class="filter-bar">
    <div style="flex: 1; min-width: 200px;">
        <input type="text" name="search" placeholder="Search by trip name, invite code, owner, or ID..." 
               value="<?= htmlspecialchars($search) ?>" style="width: 100%;">
    </div>
    <div>
        <select name="status" onchange="this.form.submit()">
            <option value="all" <?= $statusFilter === 'all' ? 'selected' : '' ?>>All Statuses</option>
            <option value="active" <?= $statusFilter === 'active' ? 'selected' : '' ?>>Active Trips</option>
            <option value="completed" <?= $statusFilter === 'completed' ? 'selected' : '' ?>>Completed</option>
            <option value="archived" <?= $statusFilter === 'archived' ? 'selected' : '' ?>>Archived</option>
        </select>
    </div>
    <button type="submit" class="btn btn-primary btn-sm">Filter</button>
    <?php if (!empty($search) || $statusFilter !== 'all'): ?>
        <a href="trips.php" class="btn btn-secondary btn-sm">Reset</a>
    <?php endif; ?>
</form>

<!-- Trips Table (Section 13.1) -->
<div class="card">
    <div class="table-responsive">
        <table class="data-table">
            <thead>
                <tr>
                    <th>Trip ID</th>
                    <th>Trip Name & Code</th>
                    <th>Owner / Creator</th>
                    <th>Members</th>
                    <th>Transactions</th>
                    <th>Total Expenses</th>
                    <th>Settled</th>
                    <th>Status</th>
                    <th style="text-align: right;">Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php if (empty($trips)): ?>
                    <tr>
                        <td colspan="9" style="text-align: center; padding: 40px; color: #94a3b8;">
                            No trips found matching your criteria.
                        </td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($trips as $t): ?>
                        <tr>
                            <td style="color: #64748b; font-weight: 600;">#<?= $t['id'] ?></td>
                            <td>
                                <a href="trip-detail.php?id=<?= $t['id'] ?>" style="font-weight: 700; color: #2563eb; text-decoration: none;">
                                    <?= htmlspecialchars($t['name']) ?>
                                </a>
                                <div style="font-size: 11px; color: #64748b;">
                                    Code: <code><?= htmlspecialchars($t['trip_code'] ?? 'N/A') ?></code> · <?= htmlspecialchars($t['currency_symbol'] ?? '₹') ?> <?= htmlspecialchars($t['currency'] ?? 'INR') ?>
                                </div>
                            </td>
                            <td>
                                <?= htmlspecialchars($t['creator_name'] ?? 'Unknown') ?>
                            </td>
                            <td>
                                <span class="badge badge-secondary"><?= $t['member_count'] ?> pax</span>
                            </td>
                            <td>
                                <?= $t['transaction_count'] ?> bills
                            </td>
                            <td style="font-weight: 700;">
                                <?= htmlspecialchars($t['currency_symbol'] ?? '₹') ?><?= number_format((float)$t['total_expenses'], 0) ?>
                            </td>
                            <td style="color: #059669; font-weight: 600;">
                                <?= htmlspecialchars($t['currency_symbol'] ?? '₹') ?><?= number_format((float)$t['total_settled'], 0) ?>
                            </td>
                            <td>
                                <span class="badge <?= ($t['status'] ?? 'active') === 'archived' ? 'badge-warning' : 'badge-success' ?>">
                                    <?= htmlspecialchars($t['status'] ?? 'active') ?>
                                </span>
                            </td>
                            <td style="text-align: right;">
                                <div style="display: inline-flex; gap: 6px;">
                                    <a href="trip-detail.php?id=<?= $t['id'] ?>" class="btn btn-secondary btn-sm" title="Inspect">
                                        <i data-lucide="eye" style="width: 14px; height: 14px;"></i>
                                    </a>

                                    <?php if (($t['status'] ?? 'active') === 'archived'): ?>
                                        <form method="POST" style="display:inline;" onsubmit="return confirm('Restore trip to active?');">
                                            <?= csrfField() ?>
                                            <input type="hidden" name="trip_id" value="<?= $t['id'] ?>">
                                            <input type="hidden" name="action" value="restore">
                                            <button type="submit" class="btn btn-secondary btn-sm" title="Restore" style="color: #059669;">
                                                <i data-lucide="archive-restore" style="width: 14px; height: 14px;"></i>
                                            </button>
                                        </form>
                                    <?php else: ?>
                                        <form method="POST" style="display:inline;" onsubmit="return confirm('Archive this trip?');">
                                            <?= csrfField() ?>
                                            <input type="hidden" name="trip_id" value="<?= $t['id'] ?>">
                                            <input type="hidden" name="action" value="archive">
                                            <button type="submit" class="btn btn-secondary btn-sm" title="Archive" style="color: #d97706;">
                                                <i data-lucide="archive" style="width: 14px; height: 14px;"></i>
                                            </button>
                                        </form>
                                    <?php endif; ?>
                                </div>
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
                Showing page <?= $page ?> of <?= $totalPages ?> (<?= $totalRows ?> total trips)
            </span>
            <div class="pagination-links">
                <?php for ($i = 1; $i <= $totalPages; $i++): ?>
                    <a href="trips.php?page=<?= $i ?>&search=<?= urlencode($search) ?>&status=<?= urlencode($statusFilter) ?>" 
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
