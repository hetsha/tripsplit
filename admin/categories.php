<?php
/**
 * TripSplit Admin Panel - Master Categories Management
 * Section 21
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

requirePermission('categories.view');

$db = getDBConnection();
ensureAdminTablesExist($db);

$msg = '';
$error = '';

// Handle Actions (Add, Edit, Disable/Enable)
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    requirePermission('categories.create');
    $action = $_POST['action'] ?? '';

    if ($action === 'create') {
        $name = trim($_POST['name'] ?? '');
        $icon = trim($_POST['icon'] ?? 'tag');
        $color = trim($_POST['color'] ?? '#2563eb');

        if (!empty($name)) {
            $stmt = $db->prepare("INSERT INTO categories (name, icon, color, is_default, active, trip_id) VALUES (?, ?, ?, 1, 1, NULL)");
            $stmt->execute([$name, $icon, $color]);
            logAdminAudit('CREATE_CATEGORY', 'categories', 'category', (string)$db->lastInsertId(), null, ['name' => $name, 'icon' => $icon, 'color' => $color]);
            $msg = 'Category created successfully.';
        } else {
            $error = 'Category name cannot be empty.';
        }
    } elseif ($action === 'toggle_status') {
        requirePermission('categories.edit');
        $catId = (int)($_POST['category_id'] ?? 0);
        if ($catId > 0) {
            $stmt = $db->prepare("UPDATE categories SET active = NOT active WHERE id = ?");
            $stmt->execute([$catId]);
            logAdminAudit('TOGGLE_CATEGORY', 'categories', 'category', (string)$catId, null, null, 'Status toggled');
            $msg = 'Category status updated.';
        }
    }
}

// Fetch all global default categories with usage counts
$stmt = $db->query("
    SELECT c.*,
           (SELECT COUNT(*) FROM transactions WHERE category_id = c.id) as usage_count,
           (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE category_id = c.id) as total_spent
    FROM categories c
    WHERE c.trip_id IS NULL OR c.is_default = 1
    ORDER BY c.active DESC, c.name ASC
");
$categories = $stmt->fetchAll();

include __DIR__ . '/includes/header.php';
?>

<div class="page-header">
    <div class="page-title-box">
        <h1>Global Categories Management</h1>
        <p>Manage system-wide expense categories, icons, color badges, and active availability</p>
    </div>
</div>

<?php if (!empty($msg)): ?>
    <div class="alert alert-success">✓ <?= htmlspecialchars($msg) ?></div>
<?php endif; ?>
<?php if (!empty($error)): ?>
    <div class="alert alert-danger">⚠️ <?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<div class="grid-2">
    <!-- Categories List -->
    <div class="card">
        <div class="card-header">
            <h3>Active Categories (<?= count($categories) ?>)</h3>
        </div>
        <div class="table-responsive">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Category</th>
                        <th>Icon / Color</th>
                        <th>Usage Count</th>
                        <th>Total Volume</th>
                        <th>Status</th>
                        <th style="text-align: right;">Action</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($categories as $c): ?>
                        <tr>
                            <td>
                                <div style="display: flex; align-items: center; gap: 8px;">
                                    <span style="width: 14px; height: 14px; border-radius: 4px; background: <?= htmlspecialchars($c['color']) ?>; display: inline-block;"></span>
                                    <strong><?= htmlspecialchars($c['name']) ?></strong>
                                </div>
                            </td>
                            <td>
                                <code><?= htmlspecialchars($c['icon']) ?></code>
                            </td>
                            <td><?= $c['usage_count'] ?> bills</td>
                            <td style="font-weight: 700;">₹<?= number_format((float)$c['total_spent'], 0) ?></td>
                            <td>
                                <span class="badge <?= !empty($c['active']) ? 'badge-success' : 'badge-secondary' ?>">
                                    <?= !empty($c['active']) ? 'Active' : 'Disabled' ?>
                                </span>
                            </td>
                            <td style="text-align: right;">
                                <form method="POST" style="display:inline;">
                                    <?= csrfField() ?>
                                    <input type="hidden" name="action" value="toggle_status">
                                    <input type="hidden" name="category_id" value="<?= $c['id'] ?>">
                                    <button type="submit" class="btn btn-secondary btn-sm">
                                        <?= !empty($c['active']) ? 'Disable' : 'Enable' ?>
                                    </button>
                                </form>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Create New Category -->
    <div class="card">
        <div class="card-header">
            <h3>Add New Master Category</h3>
        </div>
        <div class="card-body">
            <form method="POST">
                <?= csrfField() ?>
                <input type="hidden" name="action" value="create">

                <div style="margin-bottom: 16px;">
                    <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px;">Category Name</label>
                    <input type="text" name="name" class="form-control" placeholder="e.g. Flight, Nightlife, Toll, Stay" required style="width: 100%; padding: 10px; border: 1px solid #cbd5e1; border-radius: 8px;">
                </div>

                <div style="margin-bottom: 16px;">
                    <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px;">Lucide Icon Name</label>
                    <input type="text" name="icon" class="form-control" value="tag" placeholder="tag, coffee, plane, hotel, fuel" required style="width: 100%; padding: 10px; border: 1px solid #cbd5e1; border-radius: 8px;">
                </div>

                <div style="margin-bottom: 20px;">
                    <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px;">Badge Color</label>
                    <input type="color" name="color" value="#2563eb" style="width: 100%; height: 44px; border: 1px solid #cbd5e1; border-radius: 8px; cursor: pointer; padding: 4px;">
                </div>

                <button type="submit" class="btn btn-primary" style="width: 100%;">
                    <i data-lucide="plus"></i> Create Category
                </button>
            </form>
        </div>
    </div>
</div>

<?php
include __DIR__ . '/includes/footer.php';
