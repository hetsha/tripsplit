<?php
/**
 * TripBook Consolidated Dashboard API
 * Single Source of Truth response for the mobile app shell
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/calculations.php';

header('Content-Type: application/json; charset=utf-8');

$currentUser = getCurrentUser();
$tripId = (int)($_GET['trip_id'] ?? getActiveTripId());
$membership = requireTripMembership($tripId, (int)$currentUser['id']);

$db = getDBConnection();

// 1. Calculations
$tripMoney = getTripMoneySummary($tripId);
$expenseSummary = getExpenseBreakdown($tripId);
$memberWallets = getMemberWallets($tripId);
$memberBalances = getSplitwiseBalances($tripId);
$simplifiedSettlements = calculateSimplifiedSettlements($tripId);
$categorySpending = getCategorySpending($tripId);

// 2. Fetch Recent Transactions (last 6)
$stmt = $db->prepare("
    SELECT 
        t.id, t.type, t.amount, t.description, t.payment_method, 
        t.transaction_date, t.notes,
        c.name as category_name, c.icon as category_icon, c.color as category_color,
        u.id as payer_id, u.name as payer_name, u.avatar_color as payer_color,
        r.id as receiver_id, r.name as receiver_name
    FROM transactions t
    LEFT JOIN categories c ON c.id = t.category_id
    LEFT JOIN users u ON u.id = t.paid_by
    LEFT JOIN users r ON r.id = t.received_by
    WHERE t.trip_id = ?
    ORDER BY t.transaction_date DESC, t.id DESC
    LIMIT 6
");
$stmt->execute([$tripId]);
$recentTransactions = $stmt->fetchAll();

// Attach splits and user position
if (!empty($recentTransactions)) {
    $txIds = array_column($recentTransactions, 'id');
    $placeholders = implode(',', array_fill(0, count($txIds), '?'));
    $splitStmt = $db->prepare("
        SELECT es.transaction_id, es.user_id, es.amount, u.name, u.avatar_color
        FROM expense_splits es
        JOIN users u ON u.id = es.user_id
        WHERE es.transaction_id IN ($placeholders)
    ");
    $splitStmt->execute($txIds);
    $allSplits = $splitStmt->fetchAll();

    $splitsByTx = [];
    foreach ($allSplits as $s) {
        $splitsByTx[(int)$s['transaction_id']][] = $s;
    }

    ensureTransactionPayersTable();
    $payerStmt = $db->prepare("
        SELECT tp.transaction_id, tp.user_id, tp.amount, u.name, u.avatar_color
        FROM transaction_payers tp
        JOIN users u ON u.id = tp.user_id
        WHERE tp.transaction_id IN ($placeholders)
    ");
    $payerStmt->execute($txIds);
    $allPayers = $payerStmt->fetchAll();

    $payersByTx = [];
    foreach ($allPayers as $p) {
        $payersByTx[(int)$p['transaction_id']][] = $p;
    }

    $currentUserId = (int)$currentUser['id'];

    foreach ($recentTransactions as &$tx) {
        $txId = (int)$tx['id'];
        $tx['splits'] = $splitsByTx[$txId] ?? [];
        $tx['payers'] = $payersByTx[$txId] ?? [];
        if (!empty($tx['payers']) && count($tx['payers']) > 1) {
            $tx['is_multi_payer'] = true;
            $tx['payer_name'] = count($tx['payers']) . ' people';
        } else {
            $tx['is_multi_payer'] = false;
        }

        $tx['expense_timing'] = 'during_trip';
        $meta = getPaymentMethodMeta($tx['payment_method'] ?? 'cash');
        $tx['payment_method_label'] = $meta['label'];
        $tx['payment_method_icon'] = $meta['icon'];
        $tx['formatted_amount'] = formatMoney($tx['amount'], $tripMoney['currency_symbol']);
        $tx['formatted_date'] = date('M d, g:i A', strtotime($tx['transaction_date']));

        attachUserTransactionPosition($tx, $currentUserId, $tripMoney['currency_symbol']);
    }
    unset($tx);
}

// Compute current user's individual position & cashbook ledger
$myBalance = $memberBalances[(int)$currentUser['id']] ?? null;
$myCashbook = getUserCashbookLedger($tripId, (int)$currentUser['id']);

// Total expenses paid by current user (shared + personal)
$stmt = $db->prepare("
    SELECT COALESCE(SUM(amount), 0) as total
    FROM transactions
    WHERE type = 'expense' AND paid_by = ? AND (trip_id = ? OR trip_id IS NULL)
");
$stmt->execute([(int)$currentUser['id'], $tripId]);
$myTotalExpenses = (float)$stmt->fetch()['total'];

jsonSuccess('Dashboard data loaded', [
    'trip_info' => [
        'id'              => $tripId,
        'trip_code'       => $membership['trip_code'],
        'url_token'       => $membership['url_token'],
        'name'            => $membership['name'],
        'currency_symbol' => $membership['currency_symbol'],
        'role'            => $membership['role']
    ],
    'current_user'          => $currentUser,
    'my_balance'            => $myBalance,
    'my_cashbook'           => $myCashbook,
    'my_total_expenses'     => $myTotalExpenses,
    'trip_money'            => $tripMoney,
    'expense_summary'       => $expenseSummary,
    'member_wallets'        => $memberWallets,
    'who_owes_whom'         => $simplifiedSettlements,
    'member_balances'       => array_values($memberBalances),
    'recent_transactions'   => $recentTransactions,
    'category_spending'     => $categorySpending
]);
