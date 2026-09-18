<?php
/**
 * TripBook Transactions & CashBook API
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/validation.php';
require_once __DIR__ . '/../includes/calculations.php';

header('Content-Type: application/json; charset=utf-8');

$currentUser = getCurrentUser();
$db = getDBConnection();
$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? $_POST['action'] ?? 'list';

$tripId = (int)($_GET['trip_id'] ?? $_POST['trip_id'] ?? getActiveTripId());
$membership = requireTripMembership($tripId, (int)$currentUser['id']);

if ($method === 'GET') {
    // Filters
    $type = trim((string)($_GET['type'] ?? 'all'));
    $categoryId = (int)($_GET['category_id'] ?? 0);
    $userId = (int)($_GET['user_id'] ?? 0);
    $search = trim((string)($_GET['search'] ?? ''));

    $sql = "
        SELECT 
            t.id, t.type, t.trip_id, t.amount, t.description, t.payment_method, 
            t.transaction_date, t.notes, t.created_at, t.created_by,
            c.id as category_id, c.name as category_name, c.icon as category_icon, c.color as category_color,
            u.id as payer_id, u.name as payer_name, u.avatar_color as payer_color,
            r.id as receiver_id, r.name as receiver_name, r.avatar_color as receiver_color
        FROM transactions t
        LEFT JOIN categories c ON c.id = t.category_id
        LEFT JOIN users u ON u.id = t.paid_by
        LEFT JOIN users r ON r.id = t.received_by
        WHERE t.trip_id = ?
    ";
    $params = [$tripId];

    if ($type !== 'all' && in_array($type, ['expense', 'income', 'settlement'], true)) {
        $sql .= " AND t.type = ?";
        $params[] = $type;
    }

    if ($categoryId > 0) {
        $sql .= " AND t.category_id = ?";
        $params[] = $categoryId;
    }

    if ($userId > 0) {
        $sql .= " AND (t.paid_by = ? OR t.received_by = ? OR EXISTS (SELECT 1 FROM expense_splits es WHERE es.transaction_id = t.id AND es.user_id = ?))";
        $params[] = $userId;
        $params[] = $userId;
        $params[] = $userId;
    }

    if (!empty($search)) {
        $sql .= " AND (t.description LIKE ? OR t.notes LIKE ?)";
        $params[] = '%' . $search . '%';
        $params[] = '%' . $search . '%';
    }

    $sql .= " ORDER BY t.transaction_date DESC, t.id DESC";

    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $transactions = $stmt->fetchAll();

    // Attach split info for each transaction
    foreach ($transactions as &$tx) {
        $tx['expense_timing'] = 'during_trip';
        $meta = getPaymentMethodMeta($tx['payment_method'] ?? 'cash');
        $tx['payment_method_label'] = $meta['label'];
        $tx['payment_method_icon'] = $meta['icon'];
        $tx['formatted_amount'] = formatMoney($tx['amount'], $membership['currency_symbol']);
        $tx['formatted_date'] = date('M d, g:i A', strtotime($tx['transaction_date']));

        if ($tx['type'] === 'expense') {
            $sStmt = $db->prepare("
                SELECT es.user_id, es.amount, u.name, u.avatar_color
                FROM expense_splits es
                JOIN users u ON u.id = es.user_id
                WHERE es.transaction_id = ?
            ");
            $sStmt->execute([$tx['id']]);
            $tx['splits'] = $sStmt->fetchAll();
        }
    }
    unset($tx);

    jsonSuccess('Transactions list', [
        'transactions' => $transactions,
        'count'        => count($transactions)
    ]);
}

if ($method === 'POST') {
    requireCsrf();
    $input = getJsonInput();
    $act = $input['action'] ?? $action;

    // Add Money (Income to Shared Trip Pool)
    if ($act === 'add_money') {
        $amount = validateAmount($input['amount'] ?? 0.0, 'Add Money Amount');
        $receivedBy = (int)($input['received_by'] ?? $currentUser['id']);
        $paymentMethod = validatePaymentMethod($input['payment_method'] ?? 'cash');
        $note = trim((string)($input['notes'] ?? 'Trip pool contribution'));
        $txDate = !empty($input['transaction_date']) ? date('Y-m-d H:i:s', strtotime($input['transaction_date'])) : date('Y-m-d H:i:s');

        $stmt = $db->prepare("
            INSERT INTO transactions (trip_id, type, amount, description, received_by, payment_method, paid_from_pool, created_by, transaction_date, notes)
            VALUES (?, 'income', ?, 'Added Money to Pool', ?, ?, 0, ?, ?, ?)
        ");
        $stmt->execute([
            $tripId,
            $amount,
            $receivedBy,
            $paymentMethod,
            $currentUser['id'],
            $txDate,
            $note ?: null
        ]);

        jsonSuccess('Money added to shared pool successfully!');
    }

    // Delete Transaction
    if ($act === 'delete') {
        $id = (int)($input['id'] ?? 0);
        if ($id <= 0) {
            jsonError('Invalid transaction ID', 422);
        }

        $stmt = $db->prepare("DELETE FROM transactions WHERE id = ? AND trip_id = ?");
        $stmt->execute([$id, $tripId]);

        jsonSuccess('Transaction deleted successfully');
    }

    jsonError('Invalid action', 400);
}
