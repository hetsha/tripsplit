<?php
/**
 * TripBook CashBook API
 * Shows all expenses (personal + shared) for a user with running balance
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/auth.php';

header('Content-Type: application/json; charset=utf-8');

$currentUser = getCurrentUser();
$db = getDBConnection();
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $userId = (int)($_GET['user_id'] ?? $currentUser['id']);
    $tripId = (int)($_GET['trip_id'] ?? getActiveTripId());
    $startDate = $_GET['start_date'] ?? null;
    $endDate = $_GET['end_date'] ?? null;
    $type = $_GET['type'] ?? 'all'; // 'all', 'personal', 'shared'
    
    // Build query - show user's expenses AND income
    $where = "((t.type = 'expense' AND (t.created_by = ? OR t.paid_by = ?)) OR (t.type = 'income' AND t.received_by = ?))";
    $params = [$userId, $userId, $userId];
    
    // Filter by trip
    if ($tripId > 0) {
        if ($type === 'personal') {
            $where .= " AND t.trip_id IS NULL";
        } elseif ($type === 'shared') {
            $where .= " AND t.trip_id = ? AND t.type = 'expense'";
            $params[] = $tripId;
        } else {
            // All: show income (always personal) + personal expenses + shared expenses for this trip
            $where .= " AND (t.trip_id IS NULL OR t.trip_id = ?)";
            $params[] = $tripId;
        }
    } elseif ($type === 'personal') {
        $where .= " AND t.trip_id IS NULL";
    } elseif ($type === 'shared') {
        $where .= " AND t.trip_id IS NOT NULL AND t.type = 'expense'";
    }
    
    if ($startDate) {
        $where .= " AND t.transaction_date >= ?";
        $params[] = $startDate;
    }
    if ($endDate) {
        $where .= " AND t.transaction_date <= ?";
        $params[] = $endDate . ' 23:59:59';
    }
    
    // Get all transactions ordered by date
    $stmt = $db->prepare("
        SELECT t.*, 
               c.name as category_name, c.icon as category_icon, c.color as category_color,
               u.name as payer_name, u.avatar_color as payer_color,
               tr.name as trip_name, tr.trip_code
        FROM transactions t
        LEFT JOIN categories c ON c.id = t.category_id
        LEFT JOIN users u ON u.id = t.paid_by
        LEFT JOIN trips tr ON tr.id = t.trip_id
        WHERE {$where}
        ORDER BY t.transaction_date ASC, t.id ASC
    ");
    $stmt->execute($params);
    $transactions = $stmt->fetchAll();
    
    // Get settlements for this user in this trip (paid + received) as cashbook entries
    $settlementRows = [];
    if ($tripId > 0 && $type !== 'personal') {
        $settleStmt = $db->prepare("
            SELECT s.*, 
               fu.name as from_user_name, fu.avatar_color as from_user_color,
               tu.name as to_user_name, tu.avatar_color as to_user_color
            FROM settlements s
            JOIN users fu ON fu.id = s.from_user
            JOIN users tu ON tu.id = s.to_user
            WHERE s.trip_id = ? AND s.status = 'paid' AND (s.from_user = ? OR s.to_user = ?)
            ORDER BY s.paid_at ASC, s.id ASC
        ");
        $settleStmt->execute([$tripId, $userId, $userId]);
        foreach ($settleStmt->fetchAll() as $s) {
            $isSent = (int)$s['from_user'] === (int)$userId;
            $settlementRows[] = [
                'id' => 'settle_' . $s['id'],
                'transaction_date' => $s['paid_at'],
                'description' => $isSent
                    ? ('Settlement paid to ' . $s['to_user_name'])
                    : ('Settlement received from ' . $s['from_user_name']),
                'amount' => $s['amount'],
                'type' => $isSent ? 'settlement_paid' : 'settlement_received',
                'category_name' => $isSent ? 'Settlement Out' : 'Settlement In',
                'category_icon' => $isSent ? 'arrow-up-right' : 'arrow-down-left',
                'category_color' => $isSent ? '#ef4444' : '#10b981',
                'payment_method' => $s['payment_method'],
                'trip_name' => null,
                'trip_code' => null
            ];
        }
    }
    
    // Merge settlements into transactions and sort chronologically
    $transactions = array_merge($transactions, $settlementRows);
    usort($transactions, function ($a, $b) {
        $cmp = strcmp((string)$a['transaction_date'], (string)$b['transaction_date']);
        return $cmp !== 0 ? $cmp : ((int)$a['id'] <=> (int)$b['id']);
    });
    
    // Calculate running balance
    $balance = 0;
    $entries = [];
    
    foreach ($transactions as $tx) {
        $amount = (float)$tx['amount'];
        
        if ($tx['type'] === 'income' || $tx['type'] === 'settlement_received') {
            $balance += $amount;
        } elseif ($tx['type'] === 'settlement_paid' || ($tx['type'] === 'expense' && ($tx['paid_by'] ?? null) == $userId)) {
            $balance -= $amount;
        }
        
        $entries[] = [
            'id' => $tx['id'],
            'date' => $tx['transaction_date'],
            'description' => $tx['description'],
            'amount' => $amount,
            'type' => $tx['type'],
            'category' => $tx['category_name'] ?? 'General',
            'category_icon' => $tx['category_icon'] ?? 'tag',
            'category_color' => $tx['category_color'] ?? '#64748b',
            'payment_method' => $tx['payment_method'],
            'trip_name' => $tx['trip_name'] ?? null,
            'trip_code' => $tx['trip_code'] ?? null,
            'balance' => $balance
        ];
    }
    
    // Get summary stats
    $totalPersonal = 0;
    $totalShared = 0;
    
    foreach ($transactions as $tx) {
        if (($tx['type'] ?? '') === 'expense' && ($tx['paid_by'] ?? null) == $userId) {
            if ($tx['trip_id']) {
                $totalShared += (float)$tx['amount'];
            } else {
                $totalPersonal += (float)$tx['amount'];
            }
        }
    }
    
    // Get total income for the user (personal income has trip_id = NULL)
    $incomeStmt = $db->prepare("
        SELECT COALESCE(SUM(amount), 0) as total
        FROM transactions 
        WHERE type = 'income' AND received_by = ? AND trip_id IS NULL
    ");
    $incomeStmt->execute([$userId]);
    $totalIncome = (float)$incomeStmt->fetch()['total'];
    
    // Get settlements paid by user in this trip
    $settlementStmt = $db->prepare("
        SELECT COALESCE(SUM(amount), 0) as total
        FROM settlements 
        WHERE from_user = ? AND trip_id = ?
    ");
    $settlementStmt->execute([$userId, $tripId]);
    $totalSettlementsPaid = (float)$settlementStmt->fetch()['total'];
    
    // Get settlements received by user in this trip
    $settlementReceivedStmt = $db->prepare("
        SELECT COALESCE(SUM(amount), 0) as total
        FROM settlements 
        WHERE to_user = ? AND trip_id = ?
    ");
    $settlementReceivedStmt->execute([$userId, $tripId]);
    $totalSettlementsReceived = (float)$settlementReceivedStmt->fetch()['total'];
    
    jsonSuccess('CashBook loaded', [
        'entries' => array_reverse($entries), // Reverse to show newest first
        'summary' => [
            'total_expenses' => $totalPersonal + $totalShared,
            'total_personal' => $totalPersonal,
            'total_shared' => $totalShared,
            'total_income' => $totalIncome,
            'total_settlements_paid' => $totalSettlementsPaid,
            'total_settlements_received' => $totalSettlementsReceived,
            'net_balance' => $totalIncome - $totalPersonal - $totalShared - $totalSettlementsPaid + $totalSettlementsReceived
        ],
        'user_id' => $userId
    ]);
}

// POST: Add personal cash/income
if ($method === 'POST') {
    $input = getJsonInput();
    $action = $_GET['action'] ?? '';

    if ($action === 'add') {
        $type = $input['type'] ?? 'income'; // 'income' or 'expense'
        $amount = (float)($input['amount'] ?? 0);
        $description = trim((string)($input['description'] ?? ''));
        $paymentMethod = $input['payment_method'] ?? 'cash';

        if ($amount <= 0) {
            jsonError('Amount must be greater than 0', 422);
        }
        if (empty($description)) {
            jsonError('Description is required', 422);
        }
        if (!in_array($type, ['income', 'expense'])) {
            jsonError('Type must be income or expense', 422);
        }

        $validMethods = ['cash', 'upi', 'card', 'bank', 'other'];
        if (!in_array($paymentMethod, $validMethods)) {
            $paymentMethod = 'cash';
        }

        $userId = $currentUser['id'];

        if ($type === 'income') {
            // Insert as income transaction (trip_id is NULL for personal)
            $stmt = $db->prepare("
                INSERT INTO transactions (trip_id, type, amount, description, paid_by, received_by, payment_method, paid_from_pool, created_by, transaction_date)
                VALUES (NULL, 'income', ?, ?, NULL, ?, ?, 0, ?, NOW())
            ");
            $stmt->execute([$amount, $description, $userId, $paymentMethod, $userId]);
        } else {
            // Insert as personal expense (trip_id is NULL)
            // Find the "General & Other" category or use first available
            $catStmt = $db->prepare("SELECT id FROM categories WHERE is_default = 1 AND trip_id IS NULL ORDER BY id ASC LIMIT 1");
            $catStmt->execute();
            $cat = $catStmt->fetch();
            $categoryId = $cat ? (int)$cat['id'] : null;

            $stmt = $db->prepare("
                INSERT INTO transactions (trip_id, type, amount, description, category_id, paid_by, payment_method, paid_from_pool, created_by, transaction_date)
                VALUES (NULL, 'expense', ?, ?, ?, ?, ?, 0, ?, NOW())
            ");
            $stmt->execute([$amount, $description, $categoryId, $userId, $paymentMethod, $userId]);
        }

        $newId = (int)$db->lastInsertId();

        jsonSuccess(($type === 'income' ? 'Income' : 'Expense') . ' added successfully', [
            'id' => $newId,
            'type' => $type,
            'amount' => $amount
        ]);
    }

    jsonError('Invalid action', 400);
}

jsonError('Method not allowed', 405);
