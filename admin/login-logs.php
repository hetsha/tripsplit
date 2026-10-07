<?php
/**
 * TripSplit Admin Panel - Login Activity Logs
 * Section 40
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

requirePermission('audit_logs.view');

$db = getDBConnection();
ensureAdminTablesExist($db);

$search = trim($_GET['search'] ?? '');
$statusFilter = trim($_GET['status'] ?? 'all');
$page = max(1, (int)($_GET['page'] ?? 1));
$limit = 25;
$offset = ($page - 1) * $limit;

$where = ["1=1"];
$params = [];

if (!empty($search)) {
    $where[] = "(username_attempted LIKE ? OR ip_address LIKE ?)";
    $like = "%$search%";
    $params[] = $like;
    $params[] = $like;
}

if ($statusFilter !== 'all') {
    $where[] = "status = ?";
    $params[] = $statusFilter;
}

$whereClause = implode(' AND ', $where);

// Count
$countStmt = $db->prepare("SELECT COUNT(*) FROM admin_login_logs WHERE $whereClause");
$countStmt->execute($params);
$totalRows = (int)$countStmt->fetchColumn();
$totalPages = max(1, (int)ceil($totalRows / $limit));

// Fetch
$query = "
    SELECT * FROM admin_login_logs
    WHERE $whereClause
    ORDER BY created_at DESC
    LIMIT $limit OFFSET $offset
";
$stmt = $db->prepare($query);
$stmt->execute($params);
$loginLogs = $stmt->fetchAll();

include __DIR__ . '/includes/header.php';
?>

<div class="page-header">
    <div class="page-title-box">
        <h1>Admin Authentication & Login Logs</h1>
        <p>Monitor successful logins, authentication failures, rate-limiting triggers, and brute-force events</p>
    </div>
</div>

<!-- Filters -->
<form method="GET" action="login-logs.php" class="filter-bar">
    <div style="flex: 1; min-width: 200px;">
        <input type="text" name="search" placeholder="Search by username attempted or IP address..." 
               value="<?= htmlspecialchars($search) ?>" style="width: 100%;">
    </div>
    <div>
        <select name="status" onchange="this.form.submit()">
            <option value="all" <?= $statusFilter === 'all' ? 'selected' : '' ?>>All Statuses</option>
            <option value="success" <?= $statusFilter === 'success' ? 'selected' : '' ?>>Successful Logins</option>
            <option value="failed" <?= $statusFilter === 'failed' ? 'selected' : '' ?>>Failed Attempts</option>
            <option value="locked" <?= $statusFilter === 'locked' ? 'selected' : '' ?>>Locked / Throttled</option>
        </select>
    </div>
    <button type="submit" class="btn btn-primary btn-sm">Filter</button>
    <?php if (!empty($search) || $statusFilter !== 'all'): ?>
        <a href="login-logs.php" class="btn btn-secondary btn-sm">Reset</a>
    <?php endif; ?>
</form>

<!-- Login Logs Table (Section 40) -->
<div class="card">
    <div class="table-responsive">
        <table class="data-table">
            <thead>
                <tr>
                    <th>Log ID</th>
                    <th>Username Attempted</th>
                    <th>IP Address</th>
                    <th>Status</th>
                    <th>Failure Reason</th>
                    <th>Timestamp</th>
                </tr>
            </thead>
            <tbody>
                <?php if (empty($loginLogs)): ?>
                    <tr>
                        <td colspan="6" style="text-align: center; padding: 40px; color: #94a3b8;">
                            No login attempt logs found.
                        </td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($loginLogs as $lg): ?>
                        <tr>
                            <td style="color: #64748b; font-weight: 600;">#<?= $lg['id'] ?></td>
                            <td><strong><?= htmlspecialchars($lg['username_attempted']) ?></strong></td>
                            <td><code><?= htmlspecialchars($lg['ip_address']) ?></code></td>
                            <td>
                                <span class="badge <?= $lg['status'] === 'success' ? 'badge-success' : ($lg['status'] === 'locked' ? 'badge-danger' : 'badge-warning') ?>">
                                    <?= htmlspecialchars($lg['status']) ?>
                                </span>
                            </td>
                            <td>
                                <span style="font-size: 12.5px; color: #64748b;"><?= htmlspecialchars($lg['failure_reason'] ?: '—') ?></span>
                            </td>
                            <td style="font-size: 12px; color: #64748b;">
                                <?= date('d M Y, H:i:s', strtotime($lg['created_at'])) ?>
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
                Showing page <?= $page ?> of <?= $totalPages ?> (<?= $totalRows ?> total logs)
            </span>
            <div class="pagination-links">
                <?php for ($i = 1; $i <= $totalPages; $i++): ?>
                    <a href="login-logs.php?page=<?= $i ?>&search=<?= urlencode($search) ?>&status=<?= urlencode($statusFilter) ?>" 
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
