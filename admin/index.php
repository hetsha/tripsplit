<?php
/**
 * TripBook Admin Panel - Dashboard
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/includes/auth.php';

// Check admin authentication
if (!isAdminAuthenticated()) {
    header('Location: login.php');
    exit;
}

$db = getDBConnection();

// Get statistics
$stats = [];

// Total users
$stmt = $db->query("SELECT COUNT(*) as cnt FROM users");
$stats['total_users'] = (int)$stmt->fetch()['cnt'];

// Total trips
$stmt = $db->query("SELECT COUNT(*) as cnt FROM trips");
$stats['total_trips'] = (int)$stmt->fetch()['cnt'];

// Total transactions
$stmt = $db->query("SELECT COUNT(*) as cnt FROM transactions");
$stats['total_transactions'] = (int)$stmt->fetch()['cnt'];

// Total expenses
$stmt = $db->query("SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'expense'");
$stats['total_expenses'] = (float)$stmt->fetch()['total'];

// Recent users
$stmt = $db->query("SELECT id, name, phone, created_at FROM users ORDER BY created_at DESC LIMIT 5");
$recent_users = $stmt->fetchAll();

// Recent trips
$stmt = $db->query("SELECT t.id, t.name, t.trip_code, u.name as creator_name, t.created_at FROM trips t JOIN users u ON u.id = t.created_by ORDER BY t.created_at DESC LIMIT 5");
$recent_trips = $stmt->fetchAll();

include 'includes/header.php';
?>

<div class="dashboard">
    <h1>Admin Dashboard</h1>
    
    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-icon" style="background: #eff6ff; color: #2563eb;">
                <i data-lucide="users"></i>
            </div>
            <div class="stat-info">
                <div class="stat-value"><?= $stats['total_users'] ?></div>
                <div class="stat-label">Total Users</div>
            </div>
        </div>
        
        <div class="stat-card">
            <div class="stat-icon" style="background: #ecfdf5; color: #10b981;">
                <i data-lucide="map"></i>
            </div>
            <div class="stat-info">
                <div class="stat-value"><?= $stats['total_trips'] ?></div>
                <div class="stat-label">Total Trips</div>
            </div>
        </div>
        
        <div class="stat-card">
            <div class="stat-icon" style="background: #fffbeb; color: #f59e0b;">
                <i data-lucide="receipt"></i>
            </div>
            <div class="stat-info">
                <div class="stat-value"><?= $stats['total_transactions'] ?></div>
                <div class="stat-label">Transactions</div>
            </div>
        </div>
        
        <div class="stat-card">
            <div class="stat-icon" style="background: #fef2f2; color: #ef4444;">
                <i data-lucide="indian-rupee"></i>
            </div>
            <div class="stat-info">
                <div class="stat-value">₹<?= number_format($stats['total_expenses'], 0) ?></div>
                <div class="stat-label">Total Expenses</div>
            </div>
        </div>
    </div>
    
    <div class="content-grid">
        <div class="card">
            <div class="card-header">
                <h2>Recent Users</h2>
                <a href="users.php" class="btn-link">View All</a>
            </div>
            <div class="card-body">
                <?php if (empty($recent_users)): ?>
                    <p class="empty-state">No users yet</p>
                <?php else: ?>
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Phone</th>
                                <th>Joined</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($recent_users as $user): ?>
                            <tr>
                                <td><?= htmlspecialchars($user['name']) ?></td>
                                <td><?= htmlspecialchars($user['phone'] ?? 'N/A') ?></td>
                                <td><?= date('M d, Y', strtotime($user['created_at'])) ?></td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                <?php endif; ?>
            </div>
        </div>
        
        <div class="card">
            <div class="card-header">
                <h2>Recent Trips</h2>
                <a href="trips.php" class="btn-link">View All</a>
            </div>
            <div class="card-body">
                <?php if (empty($recent_trips)): ?>
                    <p class="empty-state">No trips yet</p>
                <?php else: ?>
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Code</th>
                                <th>Created By</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($recent_trips as $trip): ?>
                            <tr>
                                <td><?= htmlspecialchars($trip['name']) ?></td>
                                <td><code><?= htmlspecialchars($trip['trip_code']) ?></code></td>
                                <td><?= htmlspecialchars($trip['creator_name']) ?></td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                <?php endif; ?>
            </div>
        </div>
    </div>
</div>

<?php include 'includes/footer.php'; ?>
