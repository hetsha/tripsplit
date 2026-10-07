<?php
/**
 * TripSplit Admin Panel - Admin Staff & RBAC Management
 * Sections 5 & 36.1
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

requirePermission('admins.view');

$db = getDBConnection();
ensureAdminTablesExist($db);

$msg = '';
$error = '';

// Handle actions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    requirePermission('admins.create');
    $action = $_POST['action'] ?? '';

    if ($action === 'create_admin') {
        $username = trim($_POST['username'] ?? '');
        $email = trim($_POST['email'] ?? '');
        $name = trim($_POST['name'] ?? '');
        $password = $_POST['password'] ?? '';
        $role = trim($_POST['role'] ?? 'ADMIN');

        if (empty($username) || empty($password) || empty($name)) {
            $error = 'Username, password, and name are required.';
        } else {
            $hash = password_hash($password, PASSWORD_BCRYPT);
            $stmt = $db->prepare("
                INSERT INTO admin_users (username, email, name, password_hash, role, status)
                VALUES (?, ?, ?, ?, ?, 'active')
            ");
            try {
                $stmt->execute([$username, $email ?: null, $name, $hash, $role]);
                logAdminAudit('CREATE_ADMIN', 'security', 'admin_user', (string)$db->lastInsertId(), null, [
                    'username' => $username, 'role' => $role
                ], 'Created new admin account');
                $msg = 'Administrator created successfully.';
            } catch (Throwable $e) {
                $error = 'Username or email already exists.';
            }
        }
    } elseif ($action === 'toggle_status') {
        requirePermission('admins.edit');
        $adminId = (int)($_POST['admin_id'] ?? 0);
        if ($adminId === (int)$_SESSION['admin_id']) {
            $error = 'You cannot disable your own active administrator account.';
        } else {
            $stmt = $db->prepare("UPDATE admin_users SET status = IF(status = 'active', 'inactive', 'active') WHERE id = ?");
            $stmt->execute([$adminId]);
            logAdminAudit('TOGGLE_ADMIN_STATUS', 'security', 'admin_user', (string)$adminId, null, null, 'Toggled status');
            $msg = 'Admin account status updated.';
        }
    }
}

// Fetch all admins
$stmt = $db->query("SELECT * FROM admin_users ORDER BY id ASC");
$admins = $stmt->fetchAll();

include __DIR__ . '/includes/header.php';
?>

<div class="page-header">
    <div class="page-title-box">
        <h1>Administrative Staff & Role Governance</h1>
        <p>Manage internal administrative team members, grant role-based privileges, and control access</p>
    </div>
</div>

<?php if (!empty($msg)): ?>
    <div class="alert alert-success">✓ <?= htmlspecialchars($msg) ?></div>
<?php endif; ?>
<?php if (!empty($error)): ?>
    <div class="alert alert-danger">⚠️ <?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<div class="grid-2">
    <!-- Admin List -->
    <div class="card">
        <div class="card-header">
            <h3>Registered Admin Accounts (<?= count($admins) ?>)</h3>
        </div>
        <div class="table-responsive">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Admin</th>
                        <th>Role</th>
                        <th>Status</th>
                        <th>Last Login</th>
                        <th style="text-align: right;">Action</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($admins as $adm): ?>
                        <tr>
                            <td>
                                <strong><?= htmlspecialchars($adm['name']) ?></strong>
                                <div style="font-size: 11px; color: #64748b;">@<?= htmlspecialchars($adm['username']) ?> · <?= htmlspecialchars($adm['email'] ?: 'No email') ?></div>
                            </td>
                            <td>
                                <span class="badge <?= ADMIN_ROLES[$adm['role']]['badge'] ?? 'badge-primary' ?>">
                                    <?= htmlspecialchars($adm['role']) ?>
                                </span>
                            </td>
                            <td>
                                <span class="badge <?= $adm['status'] === 'active' ? 'badge-success' : 'badge-danger' ?>">
                                    <?= htmlspecialchars($adm['status']) ?>
                                </span>
                            </td>
                            <td style="font-size: 12px; color: #64748b;">
                                <?= !empty($adm['last_login']) ? date('d M Y, H:i', strtotime($adm['last_login'])) : 'Never' ?>
                            </td>
                            <td style="text-align: right;">
                                <?php if ($adm['id'] !== (int)$_SESSION['admin_id']): ?>
                                    <form method="POST" style="display:inline;" onsubmit="return confirm('Toggle admin status?');">
                                        <?= csrfField() ?>
                                        <input type="hidden" name="action" value="toggle_status">
                                        <input type="hidden" name="admin_id" value="<?= $adm['id'] ?>">
                                        <button type="submit" class="btn btn-secondary btn-sm">
                                            <?= $adm['status'] === 'active' ? 'Deactivate' : 'Activate' ?>
                                        </button>
                                    </form>
                                <?php else: ?>
                                    <span style="font-size: 12px; color: #94a3b8;">Current</span>
                                <?php endif; ?>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Create Admin Account -->
    <div class="card">
        <div class="card-header">
            <h3>Add New Administrator Account</h3>
        </div>
        <div class="card-body">
            <form method="POST">
                <?= csrfField() ?>
                <input type="hidden" name="action" value="create_admin">

                <div style="margin-bottom: 14px;">
                    <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px;">Full Name</label>
                    <input type="text" name="name" class="form-control" placeholder="e.g. Het Shah" required style="width: 100%; padding: 10px; border: 1px solid #cbd5e1; border-radius: 8px;">
                </div>

                <div style="margin-bottom: 14px;">
                    <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px;">Username</label>
                    <input type="text" name="username" class="form-control" placeholder="e.g. hetsha" required style="width: 100%; padding: 10px; border: 1px solid #cbd5e1; border-radius: 8px;">
                </div>

                <div style="margin-bottom: 14px;">
                    <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px;">Email Address</label>
                    <input type="email" name="email" class="form-control" placeholder="admin@example.com" style="width: 100%; padding: 10px; border: 1px solid #cbd5e1; border-radius: 8px;">
                </div>

                <div style="margin-bottom: 14px;">
                    <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px;">Secure Password</label>
                    <input type="password" name="password" class="form-control" placeholder="••••••••••••" required style="width: 100%; padding: 10px; border: 1px solid #cbd5e1; border-radius: 8px;">
                </div>

                <div style="margin-bottom: 20px;">
                    <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px;">Assign Administrative Role</label>
                    <select name="role" style="width: 100%; padding: 10px; border: 1px solid #cbd5e1; border-radius: 8px;">
                        <option value="ADMIN">ADMIN (Full management except Super Admin settings)</option>
                        <option value="SUPER_ADMIN">SUPER_ADMIN (Complete unrestricted access)</option>
                        <option value="SUPPORT">SUPPORT (User & Trip troubleshooting)</option>
                        <option value="VIEWER">VIEWER (Read-only analytics and inspection)</option>
                    </select>
                </div>

                <button type="submit" class="btn btn-primary" style="width: 100%;">
                    <i data-lucide="shield-check"></i> Create Admin User
                </button>
            </form>
        </div>
    </div>
</div>

<?php
include __DIR__ . '/includes/footer.php';
