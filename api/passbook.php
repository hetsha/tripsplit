<?php
/**
 * TripBook Passbook API
 * Shows all transactions in chronological order with running balance (like bank passbook)
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
    $tripId = (int)($_GET['trip_id'] ?? 0);
    $startDate = $_GET['start_date'] ?? null;
    $endDate = $_GET['end_date'] ?? null;
    $type = $_GET['type'] ?? 'all'; // 'all', 'expense', 'income', 'settlement'
    
    // Build query
    $where = "(t.created_by = ? OR t.paid_by = ? OR t.received_by = ?)";
    $params = [$userId, $userId, $userId];
    
    if ($tripId > 0) {
        $where .= " AND (t.trip_id = ? OR (t.trip_id IS NULL AND t.type = 'income'))";
        $params[] = $tripId;
    }
    
    if ($type !== 'all') {
        $where .= " AND t.type = ?";
        $params[] = $type;
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
               ru.name as receiver_name,
               tr.name as trip_name, tr.trip_code
        FROM transactions t
        LEFT JOIN categories c ON c.id = t.category_id
        LEFT JOIN users u ON u.id = t.paid_by
        LEFT JOIN users ru ON ru.id = t.received_by
        LEFT JOIN trips tr ON tr.id = t.trip_id
        WHERE {$where}
        ORDER BY t.transaction_date ASC, t.id ASC
    ");
    $stmt->execute($params);
    $transactions = $stmt->fetchAll();
    
    // Calculate running balance (like bank passbook)
    $balance = 0;
    $entries = [];
    
    foreach ($transactions as $tx) {
        $amount = (float)$tx['amount'];
        $credit = 0;
        $debit = 0;
        
        // Determine credit or debit based on transaction type and user involvement
        if ($tx['type'] === 'income') {
            // Income received by user
            if ($tx['received_by'] == $userId) {
                $credit = $amount;
            } else {
                $debit = $amount;
            }
        } elseif ($tx['type'] === 'expense') {
            // Expense paid by user
            if ($tx['paid_by'] == $userId) {
                $debit = $amount;
            } else {
                // Expense paid by others but user's share
                // Check if user is in splits
                $splitStmt = $db->prepare("
                    SELECT amount FROM expense_splits 
                    WHERE transaction_id = ? AND user_id = ?
                ");
                $splitStmt->execute([$tx['id'], $userId]);
                $split = $splitStmt->fetch();
                if ($split) {
                    $credit = (float)$split['amount']; // Credit because someone else paid for you
                }
            }
        } elseif ($tx['type'] === 'settlement') {
            // Settlement
            if ($tx['from_user'] == $userId) {
                // User paid settlement
                $debit = $amount;
            } elseif ($tx['to_user'] == $userId) {
                // User received settlement
                $credit = $amount;
            }
        }
        
        $balance = $balance + $credit - $debit;
        
        $entries[] = [
            'id' => $tx['id'],
            'date' => $tx['transaction_date'],
            'description' => $tx['description'],
            'type' => $tx['type'],
            'amount' => $amount,
            'credit' => $credit,
            'debit' => $debit,
            'balance' => $balance,
            'category' => $tx['category_name'] ?? null,
            'category_icon' => $tx['category_icon'] ?? null,
            'category_color' => $tx['category_color'] ?? null,
            'payment_method' => $tx['payment_method'],
            'payer_name' => $tx['payer_name'] ?? null,
            'receiver_name' => $tx['receiver_name'] ?? null,
            'trip_name' => $tx['trip_name'] ?? null,
            'trip_code' => $tx['trip_code'] ?? null,
            'notes' => $tx['notes'] ?? null
        ];
    }
    
    // Get summary
    $totalCredits = array_sum(array_column($entries, 'credit'));
    $totalDebits = array_sum(array_column($entries, 'debit'));
    
    jsonSuccess('Passbook loaded', [
        'entries' => $entries,
        'summary' => [
            'total_credits' => $totalCredits,
            'total_debits' => $totalDebits,
            'final_balance' => $balance,
            'total_entries' => count($entries)
        ],
        'user_id' => $userId,
        'trip_id' => $tripId
    ]);
}

jsonError('Method not allowed', 405);
