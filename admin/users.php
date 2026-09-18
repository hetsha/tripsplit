<?php
/**
 * TripBook Admin Panel - Users Management
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/includes/auth.php';

requireAdminAuth();

$db = getDBConnection();

// Handle actions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    
    if ($action === 'delete') {
        $userId = (int)($_POST['user_id'] ?? 0);
        if ($userId > 0) {
            $stmt = $db->prepare("DELETE FROM users WHERE id = ?");
            $stmt->execute([$userId]);
            header('Location: users.php?deleted=1');
            exit;
        }
    }
    
    if ($action === 'toggle_admin') {
        $userId = (int)($_POST['user_id'] ?? 0);
        if ($userId > 0) {
            $stmt = $db->prepare("UPDATE users SET is_admin = NOT is_admin WHERE id = ?");
            $stmt->execute([$userId]);
            header('Location: users.php?updated=1');
            exit;
        }
    }
}

// Get all users
$stmt = $db->query("
    SELECT u.*, 
           (SELECT COUNT(*) FROM trip_members WHERE user_id = u.id) as trip_count,
           (SELECT COUNT(*) FROM transactions WHERE created_by = u.id) as transaction_count
    FROM users u 
    ORDER BY u.created_at DESC
");
$users = $stmt->fetchAll();

include 'includes/header.php';
?>

<div class="page-header">
    <h2>All Users (<?= count($users) ?>)</h2>
</div>

<?php if (isset($_GET['deleted'])): ?>
    <div class="alert alert-success">User deleted successfully</div>
<?php endif; ?>

<?php if (isset($_GET['updated'])): ?>
    <div class="alert alert-success">User updated successfully</div>
<?php endif; ?>

<div class="card">
    <div class="card-body">
        <table class="data-table full-width">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Name</th>
                    <th>Phone</th>
                    <th>Email</th>
                    <th>Trips</th>
                    <th>Transactions</th>
                    <th>Admin</th>
                    <th>Joined</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($users as $user): ?>
                <tr>
                    <td><?= $user['id'] ?></td>
                    <td>
                        <div class="user-cell">
                            <div class="avatar-sm" style="background: <?= $user['avatar_color'] ?>">
                                <?= strtoupper(substr($user['name'], 0, 1)) ?>
                            </div>
                            <?= htmlspecialchars($user['name']) ?>
                        </div>
                    </td>
                    <td><?= htmlspecialchars($user['phone'] ?? 'N/A') ?></td>
                    <td><?= htmlspecialchars($user['email'] ?? 'N/A') ?></td>
                    <td><?= $user['trip_count'] ?></td>
                    <td><?= $user['transaction_count'] ?></td>
                    <td>
                        <?php if ($user['is_admin']): ?>
                            <span class="badge badge-success">Admin</span>
                        <?php else: ?>
                            <span class="badge badge-secondary">User</span>
                        <?php endif; ?>
                    </td>
                    <td><?= date('M d, Y', strtotime($user['created_at'])) ?></td>
                    <td>
                        <div class="action-buttons">
                            <form method="POST" style="display: inline;">
                                <input type="hidden" name="action" value="toggle_admin">
                                <input type="hidden" name="user_id" value="<?= $user['id'] ?>">
                                <button type="submit" class="btn-sm btn-outline" title="<?= $user['is_admin'] ? 'Remove Admin' : 'Make Admin' ?>">
                                    <i data-lucide="<?= $user['is_admin'] ? 'user-minus' : 'user-plus' ?>"></i>
                                </button>
                            </form>
                            <form method="POST" style="display: inline;" 
                                  onsubmit="return confirm('Are you sure you want to delete this user?')">
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="user_id" value="<?= $user['id'] ?>">
                                <button type="submit" class="btn-sm btn-danger" title="Delete User">
                                    <i data-lucide="trash-2"></i>
                                </button>
                            </form>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>

<?php include 'includes/footer.php'; ?>
