<?php
/**
 * TripBook Admin Panel - Trips Management
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
        $tripId = (int)($_POST['trip_id'] ?? 0);
        if ($tripId > 0) {
            $stmt = $db->prepare("DELETE FROM trips WHERE id = ?");
            $stmt->execute([$tripId]);
            header('Location: trips.php?deleted=1');
            exit;
        }
    }
}

// Get all trips with stats
$stmt = $db->query("
    SELECT t.*, 
           u.name as creator_name,
           (SELECT COUNT(*) FROM trip_members WHERE trip_id = t.id) as member_count,
           (SELECT COUNT(*) FROM transactions WHERE trip_id = t.id) as transaction_count,
           (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE trip_id = t.id AND type = 'expense') as total_expenses
    FROM trips t 
    JOIN users u ON u.id = t.created_by
    ORDER BY t.created_at DESC
");
$trips = $stmt->fetchAll();

include 'includes/header.php';
?>

<div class="page-header">
    <h2>All Trips (<?= count($trips) ?>)</h2>
</div>

<?php if (isset($_GET['deleted'])): ?>
    <div class="alert alert-success">Trip deleted successfully</div>
<?php endif; ?>

<div class="card">
    <div class="card-body">
        <table class="data-table full-width">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Name</th>
                    <th>Code</th>
                    <th>Creator</th>
                    <th>Members</th>
                    <th>Transactions</th>
                    <th>Total Expenses</th>
                    <th>Created</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($trips as $trip): ?>
                <tr>
                    <td><?= $trip['id'] ?></td>
                    <td><?= htmlspecialchars($trip['name']) ?></td>
                    <td><code><?= htmlspecialchars($trip['trip_code']) ?></code></td>
                    <td><?= htmlspecialchars($trip['creator_name']) ?></td>
                    <td><?= $trip['member_count'] ?></td>
                    <td><?= $trip['transaction_count'] ?></td>
                    <td>₹<?= number_format((float)$trip['total_expenses'], 2) ?></td>
                    <td><?= date('M d, Y', strtotime($trip['created_at'])) ?></td>
                    <td>
                        <div class="action-buttons">
                            <a href="../index.php?trip=<?= e($trip['url_token'] ?? '') ?>" class="btn-sm btn-outline" target="_blank" title="View Trip">
                                <i data-lucide="external-link"></i>
                            </a>
                            <form method="POST" style="display: inline;" 
                                  onsubmit="return confirm('Are you sure you want to delete this trip? This will also delete all associated transactions and splits.')">
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="trip_id" value="<?= $trip['id'] ?>">
                                <button type="submit" class="btn-sm btn-danger" title="Delete Trip">
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
