<?php
/**
 * TripSplit Admin Panel - User Management
 * Sections 10, 11, 12, 50, 51
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

requirePermission('users.view');

$db = getDBConnection();
ensureAdminTablesExist($db);

$msg = '';
$error = '';

// Handle Administrative Actions (Section 12)
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    $userId = (int)($_POST['user_id'] ?? 0);
    $reason = trim($_POST['reason'] ?? 'Admin action');

    if ($userId > 0) {
        $userStmt = $db->prepare("SELECT * FROM users WHERE id = ?");
        $userStmt->execute([$userId]);
        $targetUser = $userStmt->fetch();

        if ($targetUser) {
            if ($action === 'suspend') {
                requirePermission('users.suspend');
                $stmt = $db->prepare("UPDATE users SET status = 'suspended' WHERE id = ?");
                $stmt->execute([$userId]);
                logAdminAudit('SUSPEND_USER', 'users', 'user', (string)$userId, $targetUser['status'], 'suspended', $reason);
                $msg = 'User account suspended successfully.';
            } elseif ($action === 'activate') {
                requirePermission('users.edit');
                $stmt = $db->prepare("UPDATE users SET status = 'active' WHERE id = ?");
                $stmt->execute([$userId]);
                logAdminAudit('ACTIVATE_USER', 'users', 'user', (string)$userId, $targetUser['status'], 'active', $reason);
                $msg = 'User account activated successfully.';
            } elseif ($action === 'delete') {
                requirePermission('users.delete');
                $confirmText = trim($_POST['confirm_text'] ?? '');
                if ($confirmText !== 'DELETE') {
                    $error = 'You must type DELETE to confirm permanent account deletion.';
                } else {
                    $stmt = $db->prepare("DELETE FROM users WHERE id = ?");
                    $stmt->execute([$userId]);
                    logAdminAudit('DELETE_USER', 'users', 'user', (string)$userId, $targetUser, null, $reason);
                    $msg = 'User deleted permanently.';
                }
            }
        }
    }
}

// Search & Filtering (Section 10.2 & 10.3)
$search = trim($_GET['search'] ?? '');
$statusFilter = trim($_GET['status'] ?? 'all');
$page = max(1, (int)($_GET['page'] ?? 1));
$limit = 15;
$offset = ($page - 1) * $limit;

$where = ["1=1"];
$params = [];

if (!empty($search)) {
    $where[] = "(u.name LIKE ? OR u.email LIKE ? OR u.phone LIKE ? OR u.id = ?)";
    $like = "%$search%";
    $params[] = $like;
    $params[] = $like;
    $params[] = $like;
    $params[] = is_numeric($search) ? (int)$search : 0;
}

if ($statusFilter === 'active') {
    $where[] = "(u.status = 'active' OR u.status IS NULL)";
} elseif ($statusFilter === 'suspended') {
    $where[] = "u.status = 'suspended'";
}

$whereClause = implode(' AND ', $where);

// Total count for pagination
$countStmt = $db->prepare("SELECT COUNT(*) FROM users u WHERE $whereClause");
$countStmt->execute($params);
$totalRows = (int)$countStmt->fetchColumn();
$totalPages = max(1, (int)ceil($totalRows / $limit));

// Fetch users with trip & spend counts
$query = "
    SELECT u.*,
           (SELECT COUNT(*) FROM trip_members WHERE user_id = u.id) as trips_joined,
           (SELECT COUNT(*) FROM transactions WHERE created_by = u.id) as transactions_logged,
           (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE paid_by = u.id) as total_paid
    FROM users u
    WHERE $whereClause
    ORDER BY u.created_at DESC
    LIMIT $limit OFFSET $offset
";
$stmt = $db->prepare($query);
$stmt->execute($params);
$users = $stmt->fetchAll();

include __DIR__ . '/includes/header.php';
?>

<div class="page-header">
    <div class="page-title-box">
        <h1>User Management</h1>
        <p>Oversee registered travelers, manage account statuses, and review activity history</p>
    </div>
    <div class="page-actions">
        <a href="reports.php?type=users" class="btn btn-secondary">
            <i data-lucide="download"></i>
            <span>Export Users CSV</span>
        </a>
    </div>
</div>

<?php if (!empty($msg)): ?>
    <div class="alert alert-success">✓ <?= htmlspecialchars($msg) ?></div>
<?php endif; ?>
<?php if (!empty($error)): ?>
    <div class="alert alert-danger">⚠️ <?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<!-- Filter & Search Bar (Section 10.2 & 10.3) -->
<form method="GET" action="users.php" class="filter-bar">
    <div style="flex: 1; min-width: 200px;">
        <input type="text" name="search" placeholder="Search by name, email, phone, or ID..." 
               value="<?= htmlspecialchars($search) ?>" style="width: 100%;">
    </div>
    <div>
        <select name="status" onchange="this.form.submit()">
            <option value="all" <?= $statusFilter === 'all' ? 'selected' : '' ?>>All Statuses</option>
            <option value="active" <?= $statusFilter === 'active' ? 'selected' : '' ?>>Active Only</option>
            <option value="suspended" <?= $statusFilter === 'suspended' ? 'selected' : '' ?>>Suspended Only</option>
        </select>
    </div>
    <button type="submit" class="btn btn-primary btn-sm">Filter</button>
    <?php if (!empty($search) || $statusFilter !== 'all'): ?>
        <a href="users.php" class="btn btn-secondary btn-sm">Reset</a>
    <?php endif; ?>
</form>

<!-- Users Data Table (Section 10.1) -->
<div class="card">
    <div class="table-responsive">
        <table class="data-table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>User</th>
                    <th>Contact</th>
                    <th>Status</th>
                    <th>Trips Joined</th>
                    <th>Total Spend</th>
                    <th>Joined Date</th>
                    <th style="text-align: right;">Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php if (empty($users)): ?>
                    <tr>
                        <td colspan="8" style="text-align: center; padding: 40px; color: #94a3b8;">
                            No users found matching your criteria.
                        </td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($users as $u): ?>
                        <tr>
                            <td style="color: #64748b; font-weight: 600;">#<?= $u['id'] ?></td>
                            <td>
                                <div style="display: flex; align-items: center; gap: 10px;">
                                    <div style="width: 34px; height: 34px; border-radius: 50%; background: <?= htmlspecialchars($u['avatar_color'] ?? '#2563eb') ?>; color: white; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 13px;">
                                        <?= strtoupper(substr($u['name'] ?? 'U', 0, 1)) ?>
                                    </div>
                                    <div>
                                        <a href="user-detail.php?id=<?= $u['id'] ?>" style="font-weight: 700; color: #0f172a; text-decoration: none;">
                                            <?= htmlspecialchars($u['name']) ?>
                                        </a>
                                        <?php if (!empty($u['is_admin'])): ?>
                                            <span class="badge badge-purple" style="font-size: 10px; margin-left: 4px;">App Admin</span>
                                        <?php endif; ?>
                                    </div>
                                </div>
                            </td>
                            <td>
                                <div><?= htmlspecialchars($u['phone'] ?: 'No Phone') ?></div>
                                <div style="font-size: 11px; color: #64748b;"><?= htmlspecialchars($u['email'] ?: 'No Email') ?></div>
                            </td>
                            <td>
                                <span class="badge <?= ($u['status'] ?? 'active') === 'suspended' ? 'badge-danger' : 'badge-success' ?>">
                                    <?= htmlspecialchars($u['status'] ?? 'active') ?>
                                </span>
                            </td>
                            <td><?= $u['trips_joined'] ?> trips</td>
                            <td style="font-weight: 700;">₹<?= number_format((float)$u['total_paid'], 0) ?></td>
                            <td style="font-size: 12px; color: #64748b;">
                                <?= date('d M, Y', strtotime($u['created_at'])) ?>
                            </td>
                            <td style="text-align: right;">
                                <div style="display: inline-flex; gap: 6px;">
                                    <a href="user-detail.php?id=<?= $u['id'] ?>" class="btn btn-secondary btn-sm" title="View Profile">
                                        <i data-lucide="eye" style="width: 14px; height: 14px;"></i>
                                    </a>

                                    <?php if (($u['status'] ?? 'active') === 'suspended'): ?>
                                        <form method="POST" style="display:inline;" onsubmit="return confirm('Activate user account?');">
                                            <?= csrfField() ?>
                                            <input type="hidden" name="user_id" value="<?= $u['id'] ?>">
                                            <input type="hidden" name="action" value="activate">
                                            <button type="submit" class="btn btn-secondary btn-sm" style="color: #059669;" title="Activate">
                                                <i data-lucide="check-circle" style="width: 14px; height: 14px;"></i>
                                            </button>
                                        </form>
                                    <?php else: ?>
                                        <form method="POST" style="display:inline;" onsubmit="return confirm('Suspend user account?');">
                                            <?= csrfField() ?>
                                            <input type="hidden" name="user_id" value="<?= $u['id'] ?>">
                                            <input type="hidden" name="action" value="suspend">
                                            <input type="hidden" name="reason" value="Administrative suspension">
                                            <button type="submit" class="btn btn-secondary btn-sm" style="color: #d97706;" title="Suspend">
                                                <i data-lucide="ban" style="width: 14px; height: 14px;"></i>
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

    <!-- Pagination (Section 50) -->
    <?php if ($totalPages > 1): ?>
        <div class="pagination-wrapper">
            <span style="font-size: 13px; color: #64748b;">
                Showing page <?= $page ?> of <?= $totalPages ?> (<?= $totalRows ?> total users)
            </span>
            <div class="pagination-links">
                <?php for ($i = 1; $i <= $totalPages; $i++): ?>
                    <a href="users.php?page=<?= $i ?>&search=<?= urlencode($search) ?>&status=<?= urlencode($statusFilter) ?>" 
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
