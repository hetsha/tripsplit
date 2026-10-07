<?php
/**
 * TripSplit Admin Panel - Comprehensive Dashboard
 * Sections 6, 7, 8, 9, 56
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

$db = getDBConnection();
ensureAdminTablesExist($db);

// 1. Gather Platform KPIs (Section 6.1)
$stats = [];

// Users stats
$stmt = $db->query("SELECT 
    COUNT(*) as total_users,
    SUM(CASE WHEN created_at >= CURDATE() THEN 1 ELSE 0 END) as users_today,
    SUM(CASE WHEN status = 'suspended' THEN 1 ELSE 0 END) as suspended_users
FROM users");
$uRow = $stmt->fetch();
$stats['total_users'] = (int)($uRow['total_users'] ?? 0);
$stats['users_today'] = (int)($uRow['users_today'] ?? 0);
$stats['suspended_users'] = (int)($uRow['suspended_users'] ?? 0);

// Trips stats
$stmt = $db->query("SELECT 
    COUNT(*) as total_trips,
    SUM(CASE WHEN created_at >= CURDATE() THEN 1 ELSE 0 END) as trips_today
FROM trips");
$tRow = $stmt->fetch();
$stats['total_trips'] = (int)($tRow['total_trips'] ?? 0);
$stats['trips_today'] = (int)($tRow['trips_today'] ?? 0);

// Transactions stats
$stmt = $db->query("SELECT 
    COUNT(*) as total_transactions,
    COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) as total_expenses,
    SUM(CASE WHEN created_at >= CURDATE() THEN 1 ELSE 0 END) as tx_today
FROM transactions");
$txRow = $stmt->fetch();
$stats['total_transactions'] = (int)($txRow['total_transactions'] ?? 0);
$stats['total_expenses'] = (float)($txRow['total_expenses'] ?? 0);
$stats['tx_today'] = (int)($txRow['tx_today'] ?? 0);

// Settlements stats
$stmt = $db->query("SELECT 
    COUNT(*) as total_settlements,
    COALESCE(SUM(amount), 0) as total_settled,
    SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending_settlements
FROM settlements");
$sRow = $stmt->fetch();
$stats['total_settlements'] = (int)($sRow['total_settlements'] ?? 0);
$stats['total_settled'] = (float)($sRow['total_settled'] ?? 0);
$stats['pending_settlements'] = (int)($sRow['pending_settlements'] ?? 0);

// 2. Recent Users (Section 8)
$stmt = $db->query("SELECT id, name, email, phone, status, created_at FROM users ORDER BY created_at DESC LIMIT 5");
$recent_users = $stmt->fetchAll();

// 3. Recent Trips (Section 8)
$stmt = $db->query("
    SELECT t.id, t.name, t.trip_code, t.status, u.name as creator_name, t.created_at,
           (SELECT COUNT(*) FROM trip_members WHERE trip_id = t.id) as member_count,
           (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE trip_id = t.id AND type = 'expense') as total_spend
    FROM trips t 
    LEFT JOIN users u ON u.id = t.created_by 
    ORDER BY t.created_at DESC LIMIT 5
");
$recent_trips = $stmt->fetchAll();

// 4. Recent Transactions (Section 8)
$stmt = $db->query("
    SELECT tx.id, tx.description, tx.amount, tx.type, tx.payment_method, tx.created_at,
           t.name as trip_name, u.name as paid_by_name
    FROM transactions tx
    LEFT JOIN trips t ON t.id = tx.trip_id
    LEFT JOIN users u ON u.id = tx.paid_by
    ORDER BY tx.created_at DESC LIMIT 5
");
$recent_transactions = $stmt->fetchAll();

// 5. Recent Admin Audit Activity (Section 8)
$stmt = $db->query("SELECT admin_email, action, module, reason, ip_address, created_at FROM admin_audit_logs ORDER BY created_at DESC LIMIT 5");
$recent_audits = $stmt->fetchAll();

include __DIR__ . '/includes/header.php';
?>

<div class="page-header">
    <div class="page-title-box">
        <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 6px;">
            <h1>Welcome back, <?= htmlspecialchars($currentAdmin['name']) ?> 👋</h1>
            <div class="live-status-chip">
                <span class="pulse-dot"></span> All Systems Operational
            </div>
        </div>
        <p>Platform status for today, <?= date('l, F j, Y') ?> · Overview of travelers, shared expenses, and debts</p>
    </div>
    <div class="page-actions">
        <a href="reports.php" class="btn btn-secondary">
            <i data-lucide="download"></i>
            <span>Export Reports</span>
        </a>
        <a href="system-health.php" class="btn btn-primary">
            <i data-lucide="activity"></i>
            <span>Health Status</span>
        </a>
    </div>
</div>

<!-- Quick Actions Bar (Section 56) -->
<div class="quick-actions-bar">
    <a href="users.php" class="quick-action-item">
        <i data-lucide="user-plus"></i>
        <span>Manage Users</span>
    </a>
    <a href="trips.php" class="quick-action-item">
        <i data-lucide="map-pin"></i>
        <span>Explore Trips</span>
    </a>
    <a href="transactions.php" class="quick-action-item">
        <i data-lucide="receipt"></i>
        <span>Inspect Transactions</span>
    </a>
    <a href="settlements.php" class="quick-action-item">
        <i data-lucide="hand-coins"></i>
        <span>Settlement Ledger</span>
    </a>
    <a href="receipts.php" class="quick-action-item">
        <i data-lucide="scan-line"></i>
        <span>OCR Bill Monitor</span>
    </a>
    <a href="notifications.php" class="quick-action-item">
        <i data-lucide="megaphone"></i>
        <span>Broadcast Notice</span>
    </a>
</div>

<!-- KPI Cards (Section 6.1) -->
<div class="kpi-grid">
    <!-- Total Users -->
    <a href="users.php" class="stat-card" title="View all registered users">
        <div class="stat-info">
            <span class="stat-label">Total Users</span>
            <div class="stat-value"><?= number_format($stats['total_users']) ?></div>
            <div class="stat-subtext">
                <span class="badge badge-success" style="font-size: 11px; padding: 2px 7px;">+<?= $stats['users_today'] ?> today</span>
                <span>registered</span>
            </div>
        </div>
        <div class="stat-icon" style="background: #eef2ff; color: #4f46e5;">
            <i data-lucide="users"></i>
        </div>
    </a>

    <!-- Total Trips -->
    <a href="trips.php" class="stat-card" title="View all trips & groups">
        <div class="stat-info">
            <span class="stat-label">Total Trips & Groups</span>
            <div class="stat-value"><?= number_format($stats['total_trips']) ?></div>
            <div class="stat-subtext">
                <span class="badge badge-success" style="font-size: 11px; padding: 2px 7px;">+<?= $stats['trips_today'] ?> today</span>
                <span>created</span>
            </div>
        </div>
        <div class="stat-icon" style="background: #ecfdf5; color: #10b981;">
            <i data-lucide="map"></i>
        </div>
    </a>

    <!-- Total Expenses Tracked -->
    <a href="transactions.php" class="stat-card" title="View all expense transactions">
        <div class="stat-info">
            <span class="stat-label">Total Expenses Tracked</span>
            <div class="stat-value">₹<?= number_format($stats['total_expenses'], 0) ?></div>
            <div class="stat-subtext">
                <span class="badge badge-purple" style="font-size: 11px; padding: 2px 7px;"><?= number_format($stats['total_transactions']) ?> txns</span>
                <span>logged</span>
            </div>
        </div>
        <div class="stat-icon" style="background: #f5f3ff; color: #8b5cf6;">
            <i data-lucide="receipt"></i>
        </div>
    </a>

    <!-- Settlements Processed -->
    <a href="settlements.php" class="stat-card" title="View settlement ledger">
        <div class="stat-info">
            <span class="stat-label">Debts Settled</span>
            <div class="stat-value">₹<?= number_format($stats['total_settled'], 0) ?></div>
            <div class="stat-subtext">
                <span class="badge badge-warning" style="font-size: 11px; padding: 2px 7px;"><?= $stats['pending_settlements'] ?> pending</span>
                <span>clearances</span>
            </div>
        </div>
        <div class="stat-icon" style="background: #fffbeb; color: #f59e0b;">
            <i data-lucide="hand-coins"></i>
        </div>
    </a>
</div>

<!-- System Health Alert Bar (Section 9) -->
<div class="card" style="padding: 16px 20px; margin-bottom: 24px; background: #ffffff; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 14px;">
    <div style="display: flex; align-items: center; gap: 20px; flex-wrap: wrap;">
        <span style="font-weight: 700; font-size: 13px; color: #0f172a; display: flex; align-items: center; gap: 6px;">
            <i data-lucide="server" style="width: 16px; height: 16px; color: #2563eb;"></i> System Status:
        </span>
        <span class="badge badge-success">● Database: Healthy</span>
        <span class="badge badge-success">● Local API: Active</span>
        <span class="badge badge-primary">PHP <?= phpversion() ?></span>
        <span class="badge badge-secondary">MySQL Connected</span>
    </div>
    <div>
        <a href="system-health.php" style="font-size: 12.5px; font-weight: 700; color: #2563eb; text-decoration: none;">View Detailed Health →</a>
    </div>
</div>

<!-- Grid: Recent Trips & Recent Users -->
<div class="grid-2">
    <!-- Recent Trips -->
    <div class="card">
        <div class="card-header">
            <h3>Recent Trips</h3>
            <a href="trips.php" class="btn btn-secondary btn-sm">View All</a>
        </div>
        <div class="table-responsive">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Trip Name</th>
                        <th>Owner</th>
                        <th>Members</th>
                        <th>Total Spend</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($recent_trips)): ?>
                        <tr><td colspan="5" style="text-align:center; color:#94a3b8;">No trips registered yet</td></tr>
                    <?php else: ?>
                        <?php foreach ($recent_trips as $t): ?>
                            <tr>
                                <td>
                                    <a href="trip-detail.php?id=<?= $t['id'] ?>" style="font-weight:700; color:#2563eb; text-decoration:none;">
                                        <?= htmlspecialchars($t['name']) ?>
                                    </a>
                                    <div style="font-size: 11px; color:#94a3b8;">Code: <?= htmlspecialchars($t['trip_code'] ?? 'N/A') ?></div>
                                </td>
                                <td><?= htmlspecialchars($t['creator_name'] ?? 'Unknown') ?></td>
                                <td><?= $t['member_count'] ?> pax</td>
                                <td>₹<?= number_format((float)$t['total_spend'], 0) ?></td>
                                <td>
                                    <span class="badge badge-success"><?= htmlspecialchars($t['status'] ?? 'active') ?></span>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Recent Users -->
    <div class="card">
        <div class="card-header">
            <h3>Recent Users</h3>
            <a href="users.php" class="btn btn-secondary btn-sm">View All</a>
        </div>
        <div class="table-responsive">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>User</th>
                        <th>Phone / Email</th>
                        <th>Status</th>
                        <th>Joined</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($recent_users)): ?>
                        <tr><td colspan="4" style="text-align:center; color:#94a3b8;">No users registered yet</td></tr>
                    <?php else: ?>
                        <?php foreach ($recent_users as $u): ?>
                            <tr>
                                <td>
                                    <a href="user-detail.php?id=<?= $u['id'] ?>" style="font-weight:700; color:#0f172a; text-decoration:none;">
                                        <?= htmlspecialchars($u['name']) ?>
                                    </a>
                                </td>
                                <td>
                                    <div style="font-size: 12.5px;"><?= htmlspecialchars($u['phone'] ?: ($u['email'] ?: 'No contact')) ?></div>
                                </td>
                                <td>
                                    <span class="badge <?= ($u['status'] ?? 'active') === 'suspended' ? 'badge-danger' : 'badge-success' ?>">
                                        <?= htmlspecialchars($u['status'] ?? 'active') ?>
                                    </span>
                                </td>
                                <td style="font-size: 12px; color: #64748b;">
                                    <?= date('d M, Y', strtotime($u['created_at'])) ?>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- Grid: Recent Transactions & Audit Trail -->
<div class="grid-2">
    <!-- Recent Transactions -->
    <div class="card">
        <div class="card-header">
            <h3>Recent Transactions</h3>
            <a href="transactions.php" class="btn btn-secondary btn-sm">View All</a>
        </div>
        <div class="table-responsive">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Description</th>
                        <th>Trip</th>
                        <th>Paid By</th>
                        <th>Amount</th>
                        <th>Type</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($recent_transactions)): ?>
                        <tr><td colspan="5" style="text-align:center; color:#94a3b8;">No transactions found</td></tr>
                    <?php else: ?>
                        <?php foreach ($recent_transactions as $tx): ?>
                            <tr>
                                <td>
                                    <strong><?= htmlspecialchars($tx['description']) ?></strong>
                                    <div style="font-size: 11px; color:#94a3b8;"><?= date('d M H:i', strtotime($tx['created_at'])) ?></div>
                                </td>
                                <td><?= htmlspecialchars($tx['trip_name'] ?? 'Personal') ?></td>
                                <td><?= htmlspecialchars($tx['paid_by_name'] ?? 'Direct') ?></td>
                                <td style="font-weight:700;">₹<?= number_format((float)$tx['amount'], 2) ?></td>
                                <td>
                                    <span class="badge <?= $tx['type'] === 'expense' ? 'badge-danger' : 'badge-primary' ?>">
                                        <?= htmlspecialchars($tx['type']) ?>
                                    </span>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Recent Audit Logs (Section 8) -->
    <div class="card">
        <div class="card-header">
            <h3>Recent Security Audit Activity</h3>
            <a href="audit-logs.php" class="btn btn-secondary btn-sm">Audit Trail</a>
        </div>
        <div class="table-responsive">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Admin</th>
                        <th>Action</th>
                        <th>Module</th>
                        <th>Time</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($recent_audits)): ?>
                        <tr><td colspan="4" style="text-align:center; color:#94a3b8;">No administrative audits logged yet</td></tr>
                    <?php else: ?>
                        <?php foreach ($recent_audits as $audit): ?>
                            <tr>
                                <td>
                                    <strong><?= htmlspecialchars($audit['admin_email']) ?></strong>
                                    <div style="font-size: 11px; color:#94a3b8;"><?= htmlspecialchars($audit['ip_address']) ?></div>
                                </td>
                                <td>
                                    <span class="badge badge-purple"><?= htmlspecialchars($audit['action']) ?></span>
                                </td>
                                <td><?= htmlspecialchars($audit['module']) ?></td>
                                <td style="font-size: 12px; color: #64748b;">
                                    <?= date('d M H:i', strtotime($audit['created_at'])) ?>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<?php
include __DIR__ . '/includes/footer.php';
