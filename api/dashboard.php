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

// Add payment method label & format
    foreach ($recentTransactions as &$tx) {
        $tx['expense_timing'] = 'during_trip';
        $meta = getPaymentMethodMeta($tx['payment_method'] ?? 'cash');
        $tx['payment_method_label'] = $meta['label'];
        $tx['payment_method_icon'] = $meta['icon'];
        $tx['formatted_amount'] = formatMoney($tx['amount'], $tripMoney['currency_symbol']);
        $tx['formatted_date'] = date('M d, g:i A', strtotime($tx['transaction_date']));
    }
unset($tx);

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
