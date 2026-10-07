<?php
/**
 * TripSplit Admin Panel - Comprehensive Audit Trail
 * Sections 37, 38, 49
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

requirePermission('audit_logs.view');

$db = getDBConnection();
ensureAdminTablesExist($db);

$search = trim($_GET['search'] ?? '');
$moduleFilter = trim($_GET['module'] ?? 'all');
$page = max(1, (int)($_GET['page'] ?? 1));
$limit = 25;
$offset = ($page - 1) * $limit;

$where = ["1=1"];
$params = [];

if (!empty($search)) {
    $where[] = "(admin_email LIKE ? OR action LIKE ? OR reason LIKE ? OR ip_address LIKE ?)";
    $like = "%$search%";
    $params[] = $like;
    $params[] = $like;
    $params[] = $like;
    $params[] = $like;
}

if ($moduleFilter !== 'all') {
    $where[] = "module = ?";
    $params[] = $moduleFilter;
}

$whereClause = implode(' AND ', $where);

// Count
$countStmt = $db->prepare("SELECT COUNT(*) FROM admin_audit_logs WHERE $whereClause");
$countStmt->execute($params);
$totalRows = (int)$countStmt->fetchColumn();
$totalPages = max(1, (int)ceil($totalRows / $limit));

// Fetch logs
$query = "
    SELECT * FROM admin_audit_logs
    WHERE $whereClause
    ORDER BY created_at DESC
    LIMIT $limit OFFSET $offset
";
$stmt = $db->prepare($query);
$stmt->execute($params);
$logs = $stmt->fetchAll();

include __DIR__ . '/includes/header.php';
?>

<div class="page-header">
    <div class="page-title-box">
        <h1>Administrative Audit Trail</h1>
        <p>Immutable record of all administrative actions, data modifications, security changes, and IP addresses</p>
    </div>
</div>

<!-- Filters -->
<form method="GET" action="audit-logs.php" class="filter-bar">
    <div style="flex: 1; min-width: 200px;">
        <input type="text" name="search" placeholder="Search by admin email, action, reason, or IP..." 
               value="<?= htmlspecialchars($search) ?>" style="width: 100%;">
    </div>
    <div>
        <select name="module" onchange="this.form.submit()">
            <option value="all" <?= $moduleFilter === 'all' ? 'selected' : '' ?>>All Modules</option>
            <option value="auth" <?= $moduleFilter === 'auth' ? 'selected' : '' ?>>Auth</option>
            <option value="users" <?= $moduleFilter === 'users' ? 'selected' : '' ?>>Users</option>
            <option value="trips" <?= $moduleFilter === 'trips' ? 'selected' : '' ?>>Trips</option>
            <option value="settlements" <?= $moduleFilter === 'settlements' ? 'selected' : '' ?>>Settlements</option>
            <option value="categories" <?= $moduleFilter === 'categories' ? 'selected' : '' ?>>Categories</option>
            <option value="settings" <?= $moduleFilter === 'settings' ? 'selected' : '' ?>>Settings</option>
            <option value="security" <?= $moduleFilter === 'security' ? 'selected' : '' ?>>Security</option>
        </select>
    </div>
    <button type="submit" class="btn btn-primary btn-sm">Filter</button>
    <?php if (!empty($search) || $moduleFilter !== 'all'): ?>
        <a href="audit-logs.php" class="btn btn-secondary btn-sm">Reset</a>
    <?php endif; ?>
</form>

<!-- Audit Logs Table (Section 37) -->
<div class="card">
    <div class="table-responsive">
        <table class="data-table">
            <thead>
                <tr>
                    <th>Log ID</th>
                    <th>Administrator</th>
                    <th>Action</th>
                    <th>Module</th>
                    <th>Target</th>
                    <th>Reason / Details</th>
                    <th>IP Address</th>
                    <th>Timestamp</th>
                </tr>
            </thead>
            <tbody>
                <?php if (empty($logs)): ?>
                    <tr>
                        <td colspan="8" style="text-align: center; padding: 40px; color: #94a3b8;">
                            No audit log records found.
                        </td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($logs as $l): ?>
                        <tr>
                            <td style="color: #64748b; font-weight: 600;">#<?= $l['id'] ?></td>
                            <td>
                                <strong><?= htmlspecialchars($l['admin_email'] ?: 'System') ?></strong>
                            </td>
                            <td>
                                <span class="badge badge-purple"><?= htmlspecialchars($l['action']) ?></span>
                            </td>
                            <td>
                                <span class="badge badge-secondary"><?= htmlspecialchars($l['module']) ?></span>
                            </td>
                            <td>
                                <?php if (!empty($l['target_type'])): ?>
                                    <code><?= htmlspecialchars($l['target_type']) ?> #<?= htmlspecialchars((string)$l['target_id']) ?></code>
                                <?php else: ?>
                                    <span style="color: #94a3b8;">—</span>
                                <?php endif; ?>
                            </td>
                            <td>
                                <div style="max-width: 250px; font-size: 12.5px; color: #334155; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">
                                    <?= htmlspecialchars($l['reason'] ?: ($l['new_data'] ?: '—')) ?>
                                </div>
                            </td>
                            <td><code><?= htmlspecialchars($l['ip_address']) ?></code></td>
                            <td style="font-size: 12px; color: #64748b;">
                                <?= date('d M Y, H:i:s', strtotime($l['created_at'])) ?>
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
                    <a href="audit-logs.php?page=<?= $i ?>&search=<?= urlencode($search) ?>&module=<?= urlencode($moduleFilter) ?>" 
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
