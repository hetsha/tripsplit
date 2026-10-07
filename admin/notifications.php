<?php
/**
 * TripSplit Admin Panel - Announcements & Notifications Center
 * Sections 24, 25, 73
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

requirePermission('notifications.view');

$db = getDBConnection();
ensureAdminTablesExist($db);

$msg = '';
$error = '';

// Handle Create Announcement
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    requirePermission('notifications.create');
    $action = $_POST['action'] ?? '';

    if ($action === 'create') {
        $title = trim($_POST['title'] ?? '');
        $message = trim($_POST['message'] ?? '');
        $type = trim($_POST['type'] ?? 'general');
        $target = trim($_POST['target_audience'] ?? 'all');

        if (!empty($title) && !empty($message)) {
            $stmt = $db->prepare("
                INSERT INTO admin_announcements (title, message, type, target_audience, is_active, created_by)
                VALUES (?, ?, ?, ?, 1, ?)
            ");
            $stmt->execute([$title, $message, $type, $target, $_SESSION['admin_id'] ?? null]);

            logAdminAudit('CREATE_ANNOUNCEMENT', 'notifications', 'announcement', (string)$db->lastInsertId(), null, [
                'title' => $title, 'type' => $type, 'target' => $target
            ], 'Created platform broadcast');

            $msg = 'Announcement broadcast created successfully.';
        } else {
            $error = 'Title and message cannot be empty.';
        }
    } elseif ($action === 'toggle_active') {
        $annId = (int)($_POST['announcement_id'] ?? 0);
        if ($annId > 0) {
            $stmt = $db->prepare("UPDATE admin_announcements SET is_active = NOT is_active WHERE id = ?");
            $stmt->execute([$annId]);
            $msg = 'Announcement status updated.';
        }
    } elseif ($action === 'delete') {
        $annId = (int)($_POST['announcement_id'] ?? 0);
        if ($annId > 0) {
            $stmt = $db->prepare("DELETE FROM admin_announcements WHERE id = ?");
            $stmt->execute([$annId]);
            $msg = 'Announcement deleted.';
        }
    }
}

// Fetch announcements
$announcements = $db->query("SELECT * FROM admin_announcements ORDER BY created_at DESC")->fetchAll();

// Fetch recent trip notifications from `notifications` table if exists
$recentNotifications = [];
try {
    $stmt = $db->query("SELECT * FROM notifications ORDER BY created_at DESC LIMIT 20");
    $recentNotifications = $stmt->fetchAll();
} catch (Throwable $e) {}

include __DIR__ . '/includes/header.php';
?>

<div class="page-header">
    <div class="page-title-box">
        <h1>Announcements & Notifications Center</h1>
        <p>Broadcast system-wide alerts, maintenance notices, new feature promotions, and trip alerts</p>
    </div>
</div>

<?php if (!empty($msg)): ?>
    <div class="alert alert-success">✓ <?= htmlspecialchars($msg) ?></div>
<?php endif; ?>
<?php if (!empty($error)): ?>
    <div class="alert alert-danger">⚠️ <?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<div class="grid-2">
    <!-- Broadcast Announcements List (Section 73) -->
    <div class="card">
        <div class="card-header">
            <h3>Active Broadcast Announcements (<?= count($announcements) ?>)</h3>
        </div>
        <div class="table-responsive">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Title & Message</th>
                        <th>Type</th>
                        <th>Target</th>
                        <th>Status</th>
                        <th style="text-align: right;">Action</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($announcements)): ?>
                        <tr><td colspan="5" style="text-align: center; color: #94a3b8; padding: 30px;">No broadcast notices configured.</td></tr>
                    <?php else: ?>
                        <?php foreach ($announcements as $ann): ?>
                            <tr>
                                <td>
                                    <strong><?= htmlspecialchars($ann['title']) ?></strong>
                                    <div style="font-size: 12px; color: #64748b;"><?= htmlspecialchars($ann['message']) ?></div>
                                </td>
                                <td>
                                    <span class="badge <?= $ann['type'] === 'maintenance' ? 'badge-danger' : ($ann['type'] === 'system' ? 'badge-warning' : 'badge-primary') ?>">
                                        <?= htmlspecialchars($ann['type']) ?>
                                    </span>
                                </td>
                                <td><?= htmlspecialchars($ann['target_audience']) ?></td>
                                <td>
                                    <span class="badge <?= !empty($ann['is_active']) ? 'badge-success' : 'badge-secondary' ?>">
                                        <?= !empty($ann['is_active']) ? 'Live' : 'Paused' ?>
                                    </span>
                                </td>
                                <td style="text-align: right;">
                                    <form method="POST" style="display:inline;">
                                        <?= csrfField() ?>
                                        <input type="hidden" name="action" value="toggle_active">
                                        <input type="hidden" name="announcement_id" value="<?= $ann['id'] ?>">
                                        <button type="submit" class="btn btn-secondary btn-sm">
                                            <?= !empty($ann['is_active']) ? 'Pause' : 'Activate' ?>
                                        </button>
                                    </form>
                                    <form method="POST" style="display:inline;" onsubmit="return confirm('Delete announcement?');">
                                        <?= csrfField() ?>
                                        <input type="hidden" name="action" value="delete">
                                        <input type="hidden" name="announcement_id" value="<?= $ann['id'] ?>">
                                        <button type="submit" class="btn btn-secondary btn-sm" style="color: #ef4444;">
                                            <i data-lucide="trash-2" style="width: 14px; height: 14px;"></i>
                                        </button>
                                    </form>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Create New Announcement Form -->
    <div class="card">
        <div class="card-header">
            <h3>Publish New Broadcast Announcement</h3>
        </div>
        <div class="card-body">
            <form method="POST">
                <?= csrfField() ?>
                <input type="hidden" name="action" value="create">

                <div style="margin-bottom: 16px;">
                    <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px;">Announcement Title</label>
                    <input type="text" name="title" class="form-control" placeholder="e.g. Scheduled Maintenance Tonight at 2:00 AM" required style="width: 100%; padding: 10px; border: 1px solid #cbd5e1; border-radius: 8px;">
                </div>

                <div style="margin-bottom: 16px;">
                    <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px;">Message Body</label>
                    <textarea name="message" rows="3" class="form-control" placeholder="Brief announcement details visible to users in app..." required style="width: 100%; padding: 10px; border: 1px solid #cbd5e1; border-radius: 8px; font-family: inherit;"></textarea>
                </div>

                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-bottom: 20px;">
                    <div>
                        <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px;">Notification Type</label>
                        <select name="type" style="width: 100%; padding: 10px; border: 1px solid #cbd5e1; border-radius: 8px;">
                            <option value="general">General</option>
                            <option value="feature">New Feature</option>
                            <option value="system">System Notice</option>
                            <option value="maintenance">Maintenance</option>
                        </select>
                    </div>
                    <div>
                        <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px;">Target Audience</label>
                        <select name="target_audience" style="width: 100%; padding: 10px; border: 1px solid #cbd5e1; border-radius: 8px;">
                            <option value="all">All Users</option>
                            <option value="active">Active Travelers</option>
                            <option value="trip_owners">Trip Admins Only</option>
                        </select>
                    </div>
                </div>

                <button type="submit" class="btn btn-primary" style="width: 100%;">
                    <i data-lucide="send"></i> Broadcast Announcement
                </button>
            </form>
        </div>
    </div>
</div>

<?php
include __DIR__ . '/includes/footer.php';
