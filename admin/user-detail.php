<?php
/**
 * TripSplit Admin Panel - User Details & 360 View
 * Sections 11 & 12
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

requirePermission('users.view');

$db = getDBConnection();
ensureAdminTablesExist($db);

$userId = (int)($_GET['id'] ?? 0);
if ($userId <= 0) {
    header('Location: users.php');
    exit;
}

$stmt = $db->prepare("SELECT * FROM users WHERE id = ?");
$stmt->execute([$userId]);
$user = $stmt->fetch();

if (!$user) {
    header('Location: users.php?error=not_found');
    exit;
}

// User's joined trips
$stmt = $db->prepare("
    SELECT t.id, t.name, t.trip_code, t.status, tm.role, tm.joined_at,
           (SELECT COUNT(*) FROM trip_members WHERE trip_id = t.id) as total_members
    FROM trip_members tm
    JOIN trips t ON t.id = tm.trip_id
    WHERE tm.user_id = ?
    ORDER BY tm.joined_at DESC
");
$stmt->execute([$userId]);
$userTrips = $stmt->fetchAll();

// User's transactions
$stmt = $db->prepare("
    SELECT tx.id, tx.description, tx.amount, tx.type, tx.payment_method, tx.transaction_date, t.name as trip_name
    FROM transactions tx
    LEFT JOIN trips t ON t.id = tx.trip_id
    WHERE tx.paid_by = ? OR tx.created_by = ?
    ORDER BY tx.transaction_date DESC
    LIMIT 20
");
$stmt->execute([$userId, $userId]);
$userTransactions = $stmt->fetchAll();

// User financial statistics
$stmt = $db->prepare("SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE paid_by = ?");
$stmt->execute([$userId]);
$totalPaid = (float)$stmt->fetchColumn();

include __DIR__ . '/includes/header.php';
?>

<div class="page-header">
    <div class="page-title-box">
        <h1>User Profile: <?= htmlspecialchars($user['name']) ?></h1>
        <p>Member ID #<?= $user['id'] ?> · Joined <?= date('d M, Y', strtotime($user['created_at'])) ?></p>
    </div>
    <div class="page-actions">
        <a href="users.php" class="btn btn-secondary">
            <i data-lucide="arrow-left"></i>
            <span>Back to Users</span>
        </a>
    </div>
</div>

<!-- Profile KPI Cards -->
<div class="kpi-grid">
    <div class="stat-card">
        <div class="stat-info">
            <span class="stat-label">Trips Enrolled</span>
            <div class="stat-value"><?= count($userTrips) ?></div>
        </div>
        <div class="stat-icon" style="background: #eff6ff; color: #2563eb;">
            <i data-lucide="map"></i>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-info">
            <span class="stat-label">Total Amount Paid</span>
            <div class="stat-value">₹<?= number_format($totalPaid, 2) ?></div>
        </div>
        <div class="stat-icon" style="background: #ecfdf5; color: #10b981;">
            <i data-lucide="wallet"></i>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-info">
            <span class="stat-label">Account Status</span>
            <div class="stat-value" style="font-size: 18px; text-transform: uppercase;">
                <span class="badge <?= ($user['status'] ?? 'active') === 'suspended' ? 'badge-danger' : 'badge-success' ?>">
                    <?= htmlspecialchars($user['status'] ?? 'active') ?>
                </span>
            </div>
        </div>
        <div class="stat-icon" style="background: #fffbeb; color: #f59e0b;">
            <i data-lucide="shield"></i>
        </div>
    </div>
</div>

<div class="grid-2">
    <!-- User Contact & Auth Details -->
    <div class="card">
        <div class="card-header">
            <h3>Identity & Contact Details</h3>
        </div>
        <div class="card-body">
            <div style="display: flex; flex-direction: column; gap: 14px; font-size: 14px;">
                <div style="display: flex; justify-content: space-between; border-bottom: 1px solid #f1f5f9; padding-bottom: 8px;">
                    <span style="color: #64748b;">Phone Number:</span>
                    <strong><?= htmlspecialchars($user['phone'] ?: 'None') ?></strong>
                </div>
                <div style="display: flex; justify-content: space-between; border-bottom: 1px solid #f1f5f9; padding-bottom: 8px;">
                    <span style="color: #64748b;">Email Address:</span>
                    <strong><?= htmlspecialchars($user['email'] ?: 'None') ?></strong>
                </div>
                <div style="display: flex; justify-content: space-between; border-bottom: 1px solid #f1f5f9; padding-bottom: 8px;">
                    <span style="color: #64748b;">Auth Provider:</span>
                    <span class="badge badge-secondary"><?= htmlspecialchars($user['auth_provider'] ?? 'phone') ?></span>
                </div>
                <div style="display: flex; justify-content: space-between; border-bottom: 1px solid #f1f5f9; padding-bottom: 8px;">
                    <span style="color: #64748b;">Phone Verified:</span>
                    <span><?= !empty($user['phone_verified']) ? '✅ Verified' : '❌ Unverified' ?></span>
                </div>
                <div style="display: flex; justify-content: space-between;">
                    <span style="color: #64748b;">Registered Date:</span>
                    <span><?= date('d M Y, H:i', strtotime($user['created_at'])) ?></span>
                </div>
            </div>
        </div>
    </div>

    <!-- Administrative Actions (Section 12) -->
    <div class="card">
        <div class="card-header">
            <h3>Administrative Actions</h3>
        </div>
        <div class="card-body">
            <div style="display: flex; flex-direction: column; gap: 16px;">
                <?php if (($user['status'] ?? 'active') === 'suspended'): ?>
                    <form method="POST" action="users.php" onsubmit="return confirm('Activate user account?');">
                        <?= csrfField() ?>
                        <input type="hidden" name="user_id" value="<?= $user['id'] ?>">
                        <input type="hidden" name="action" value="activate">
                        <input type="hidden" name="reason" value="Admin activated from profile view">
                        <button type="submit" class="btn btn-primary" style="width: 100%;">
                            <i data-lucide="check-circle"></i> Activate Account
                        </button>
                    </form>
                <?php else: ?>
                    <form method="POST" action="users.php" onsubmit="return confirm('Suspend user account? User will be blocked from logging in.');">
                        <?= csrfField() ?>
                        <input type="hidden" name="user_id" value="<?= $user['id'] ?>">
                        <input type="hidden" name="action" value="suspend">
                        <input type="hidden" name="reason" value="Suspended from profile view">
                        <button type="submit" class="btn btn-secondary" style="width: 100%; color: #d97706;">
                            <i data-lucide="ban"></i> Suspend Account
                        </button>
                    </form>
                <?php endif; ?>

                <div style="border-top: 1px solid #f1f5f9; padding-top: 14px;">
                    <p style="font-size: 12px; color: #dc2626; margin-bottom: 8px;">
                        <strong>Danger Zone:</strong> Permanent deletion removes all user references.
                    </p>
                    <form method="POST" action="users.php" onsubmit="return prompt('Type DELETE to confirm permanent account deletion:') === 'DELETE';">
                        <?= csrfField() ?>
                        <input type="hidden" name="user_id" value="<?= $user['id'] ?>">
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="confirm_text" value="DELETE">
                        <input type="hidden" name="reason" value="Permanent deletion requested by admin">
                        <button type="submit" class="btn btn-danger" style="width: 100%;">
                            <i data-lucide="trash-2"></i> Delete User Permanently
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Trips Joined Table -->
<div class="card">
    <div class="card-header">
        <h3>Trips Enrolled (<?= count($userTrips) ?>)</h3>
    </div>
    <div class="table-responsive">
        <table class="data-table">
            <thead>
                <tr>
                    <th>Trip ID</th>
                    <th>Trip Name</th>
                    <th>Role in Group</th>
                    <th>Total Members</th>
                    <th>Status</th>
                    <th>Joined At</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
                <?php if (empty($userTrips)): ?>
                    <tr><td colspan="7" style="text-align: center; color: #94a3b8;">User has not joined any trips yet.</td></tr>
                <?php else: ?>
                    <?php foreach ($userTrips as $trip): ?>
                        <tr>
                            <td>#<?= $trip['id'] ?></td>
                            <td>
                                <strong><?= htmlspecialchars($trip['name']) ?></strong>
                                <span style="font-size: 11px; color: #64748b;">(<?= htmlspecialchars($trip['trip_code']) ?>)</span>
                            </td>
                            <td><span class="badge badge-primary"><?= htmlspecialchars($trip['role']) ?></span></td>
                            <td><?= $trip['total_members'] ?> members</td>
                            <td><span class="badge badge-success"><?= htmlspecialchars($trip['status'] ?? 'active') ?></span></td>
                            <td><?= date('d M Y', strtotime($trip['joined_at'])) ?></td>
                            <td>
                                <a href="trip-detail.php?id=<?= $trip['id'] ?>" class="btn btn-secondary btn-sm">Inspect Trip</a>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php
include __DIR__ . '/includes/footer.php';
