<?php
/**
 * TripBook Financial Calculations Engine
 * Single Source of Truth for:
 * 1. Shared Trip Money (CashBook)
 * 2. Expense Summary (Pre-Trip vs During-Trip)
 * 3. Member Wallets / Accounts
 * 4. Splitwise Balances & Smart Settlements
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/functions.php';

/**
 * 1. Calculate Shared Trip Money / CashBook Summary.
 * Shared Trip Money = Starting Pool + Money Added - During-Trip Expenses.
 * Pre-trip expenses do NOT deduct from the shared pool.
 */
function getTripMoneySummary(int $tripId): array {
    $db = getDBConnection();

    // Fetch trip starting money & method
    $stmt = $db->prepare("
        SELECT starting_money, starting_payer_id, starting_payment_method, currency_symbol 
        FROM trips WHERE id = ?
    ");
    $stmt->execute([$tripId]);
    $trip = $stmt->fetch();

    $startingMoney = (float)($trip['starting_money'] ?? 0.0);
    $startingMethod = strtolower($trip['starting_payment_method'] ?? 'cash');
    $currencySymbol = $trip['currency_symbol'] ?? '₹';

    // Fetch total money added (income) to the shared pool
    $stmt = $db->prepare("
        SELECT COALESCE(SUM(amount), 0) as total_added, payment_method
        FROM transactions 
        WHERE trip_id = ? AND type = 'income'
        GROUP BY payment_method
    ");
    $stmt->execute([$tripId]);
    $addedByMethod = ['cash' => 0.0, 'upi' => 0.0, 'card' => 0.0, 'bank' => 0.0, 'other' => 0.0];
    $totalAdded = 0.0;
    while ($row = $stmt->fetch()) {
        $m = strtolower($row['payment_method'] ?? 'cash');
        $amt = (float)$row['total_added'];
        $addedByMethod[$m] = ($addedByMethod[$m] ?? 0.0) + $amt;
        $totalAdded += $amt;
    }

    // Fetch All Expenses
    $stmt = $db->prepare("
        SELECT COALESCE(SUM(amount), 0) as total_spent, payment_method
        FROM transactions 
        WHERE trip_id = ? AND type = 'expense'
        GROUP BY payment_method
    ");
    $stmt->execute([$tripId]);
    $spentByMethod = ['cash' => 0.0, 'upi' => 0.0, 'card' => 0.0, 'bank' => 0.0, 'other' => 0.0];
    $totalSpent = 0.0;
    while ($row = $stmt->fetch()) {
        $m = strtolower($row['payment_method'] ?? 'cash');
        $amt = (float)$row['total_spent'];
        $spentByMethod[$m] = ($spentByMethod[$m] ?? 0.0) + $amt;
        $totalSpent += $amt;
    }

    $availableSharedMoney = round($startingMoney + $totalAdded - $totalSpent, 2);

    // Method breakdown of available pool
    $poolByMethod = ['cash' => 0.0, 'upi' => 0.0, 'card' => 0.0, 'bank' => 0.0, 'other' => 0.0];
    if (isset($poolByMethod[$startingMethod])) {
        $poolByMethod[$startingMethod] += $startingMoney;
    }
    foreach ($addedByMethod as $m => $amt) {
        $poolByMethod[$m] = ($poolByMethod[$m] ?? 0.0) + $amt;
    }
    foreach ($spentByMethod as $m => $amt) {
        $poolByMethod[$m] = round(($poolByMethod[$m] ?? 0.0) - $amt, 2);
    }

    return [
        'currency_symbol'         => $currencySymbol,
        'starting_money'          => round($startingMoney, 2),
        'starting_payment_method' => $startingMethod,
        'total_added_money'       => round($totalAdded, 2),
        'during_trip_spent'       => round($totalSpent, 2),
        'total_spent'             => round($totalSpent, 2),
        'available_shared_money'  => $availableSharedMoney,
        'payment_breakdown'       => $poolByMethod
    ];
}

/**
 * 2. Calculate Comprehensive Expense Breakdown (All, Pre-Trip, During-Trip).
 */
function getExpenseBreakdown(int $tripId): array {
    $db = getDBConnection();

    $stmt = $db->prepare("
        SELECT 
            COALESCE(SUM(amount), 0) as total_all,
            COUNT(*) as total_count
        FROM transactions
        WHERE trip_id = ? AND type = 'expense'
    ");
    $stmt->execute([$tripId]);
    $res = $stmt->fetch();

    $totalVal = round((float)($res['total_all'] ?? 0.0), 2);
    return [
        'total_all_expenses'   => $totalVal,
        'total_pre_trip'       => 0.0,
        'total_during_trip'    => $totalVal,
        'expense_count'        => (int)($res['total_count'] ?? 0)
    ];
}

/**
 * 3. Calculate Member Personal Wallets / Accounts Spend Breakdown.
 */
function getMemberWallets(int $tripId): array {
    $db = getDBConnection();

    // Get all trip members
    $stmt = $db->prepare("
        SELECT u.id, u.name, u.avatar_color
        FROM trip_members tm
        JOIN users u ON u.id = tm.user_id
        WHERE tm.trip_id = ?
        ORDER BY u.name ASC
    ");
    $stmt->execute([$tripId]);
    $members = $stmt->fetchAll();

    // Get starting payer
    $tripStmt = $db->prepare("SELECT starting_payer_id, starting_money, starting_payment_method FROM trips WHERE id = ?");
    $tripStmt->execute([$tripId]);
    $trip = $tripStmt->fetch();
    $startingPayerId = (int)($trip['starting_payer_id'] ?? 0);
    $startingMoney = (float)($trip['starting_money'] ?? 0.0);
    $startingMethod = strtolower($trip['starting_payment_method'] ?? 'cash');

    // Aggregate spending & contributions per user per method
    $stmt = $db->prepare("
        SELECT paid_by, payment_method, COALESCE(SUM(amount), 0) as total_spent
        FROM transactions
        WHERE trip_id = ? AND type = 'expense' AND paid_by IS NOT NULL
        GROUP BY paid_by, payment_method
    ");
    $stmt->execute([$tripId]);
    $spending = [];
    while ($row = $stmt->fetch()) {
        $uid = (int)$row['paid_by'];
        $method = strtolower($row['payment_method'] ?? 'cash');
        $spending[$uid][$method] = round((float)$row['total_spent'], 2);
    }

    $wallets = [];
    foreach ($members as $m) {
        $uid = (int)$m['id'];
        $methods = ['cash' => 0.0, 'upi' => 0.0, 'card' => 0.0, 'bank' => 0.0];

        // If user contributed starting pool, record in their wallet summary
        if ($uid === $startingPayerId && isset($methods[$startingMethod])) {
            $methods[$startingMethod] += $startingMoney;
        }

        // Add expense spending
        if (isset($spending[$uid])) {
            foreach ($spending[$uid] as $meth => $amt) {
                $methods[$meth] = round(($methods[$meth] ?? 0.0) + $amt, 2);
            }
        }

        $wallets[] = [
            'user_id'      => $uid,
            'name'         => $m['name'],
            'avatar_color' => $m['avatar_color'],
            'methods'      => $methods,
            'total_spent'  => round(array_sum($methods), 2)
        ];
    }

    return $wallets;
}

/**
 * 4. Calculate Splitwise Balances for all members.
 * Formula:
 * net_balance = (total_paid - total_share) + settlements_received - settlements_sent
 */
function getSplitwiseBalances(int $tripId): array {
    $db = getDBConnection();

    // Get all members
    $stmt = $db->prepare("
        SELECT u.id, u.name, u.email, u.phone, u.avatar_color, tm.role
        FROM trip_members tm
        JOIN users u ON u.id = tm.user_id
        WHERE tm.trip_id = ?
        ORDER BY tm.joined_at ASC
    ");
    $stmt->execute([$tripId]);
    $members = $stmt->fetchAll();

    // Calculate Total Paid per user across ALL expenses
    $stmt = $db->prepare("
        SELECT paid_by, COALESCE(SUM(amount), 0) as total_paid
        FROM transactions
        WHERE trip_id = ? AND type = 'expense' AND paid_by IS NOT NULL
        GROUP BY paid_by
    ");
    $stmt->execute([$tripId]);
    $paidMap = [];
    while ($row = $stmt->fetch()) {
        $paidMap[(int)$row['paid_by']] = (float)$row['total_paid'];
    }

    // Calculate Total Share benefited per user across ALL expense splits
    $stmt = $db->prepare("
        SELECT es.user_id, COALESCE(SUM(es.amount), 0) as total_share
        FROM expense_splits es
        JOIN transactions t ON t.id = es.transaction_id
        WHERE t.trip_id = ? AND t.type = 'expense'
        GROUP BY es.user_id
    ");
    $stmt->execute([$tripId]);
    $shareMap = [];
    while ($row = $stmt->fetch()) {
        $shareMap[(int)$row['user_id']] = (float)$row['total_share'];
    }

    // Calculate Settlements Sent (debts paid to others)
    $stmt = $db->prepare("
        SELECT from_user, COALESCE(SUM(amount), 0) as settlements_sent
        FROM settlements
        WHERE trip_id = ? AND status = 'paid'
        GROUP BY from_user
    ");
    $stmt->execute([$tripId]);
    $sentMap = [];
    while ($row = $stmt->fetch()) {
        $sentMap[(int)$row['from_user']] = (float)$row['settlements_sent'];
    }

    // Calculate Settlements Received (credits collected from others)
    $stmt = $db->prepare("
        SELECT to_user, COALESCE(SUM(amount), 0) as settlements_received
        FROM settlements
        WHERE trip_id = ? AND status = 'paid'
        GROUP BY to_user
    ");
    $stmt->execute([$tripId]);
    $receivedMap = [];
    while ($row = $stmt->fetch()) {
        $receivedMap[(int)$row['to_user']] = (float)$row['settlements_received'];
    }

    $balances = [];
    foreach ($members as $m) {
        $uid = (int)$m['id'];
        $paid = round($paidMap[$uid] ?? 0.0, 2);
        $share = round($shareMap[$uid] ?? 0.0, 2);
        $sent = round($sentMap[$uid] ?? 0.0, 2);
        $received = round($receivedMap[$uid] ?? 0.0, 2);

        // Authoritative Net Balance Formula:
        // Debtors paying settlement reduce debt (+sent). Creditors receiving settlement collect credit (-received).
        $netBalance = round(($paid - $share) + $sent - $received, 2);

        $balances[$uid] = [
            'user_id'              => $uid,
            'name'                 => $m['name'],
            'email'                => $m['email'],
            'phone'                => $m['phone'],
            'avatar_color'         => $m['avatar_color'],
            'role'                 => $m['role'],
            'total_paid'           => $paid,
            'total_share'          => $share,
            'settlements_sent'     => $sent,
            'settlements_received' => $received,
            'net_balance'          => $netBalance
        ];
    }

    return $balances;
}

/**
 * 5. Greedy Debt Settlement Minimization Algorithm.
 * Returns minimal list of direct transfers [from_user -> to_user, amount] required to settle all debts.
 */
function calculateSimplifiedSettlements(int $tripId): array {
    $memberBalances = getSplitwiseBalances($tripId);

    $debtors = [];  // People with negative balance (owe money)
    $creditors = []; // People with positive balance (are owed money)

    foreach ($memberBalances as $b) {
        $net = $b['net_balance'];
        if ($net < -0.01) {
            $debtors[] = [
                'user_id' => $b['user_id'],
                'name'    => $b['name'],
                'amount'  => abs($net)
            ];
        } elseif ($net > 0.01) {
            $creditors[] = [
                'user_id' => $b['user_id'],
                'name'    => $b['name'],
                'amount'  => $net
            ];
        }
    }

    // Sort descending to optimize matches
    usort($debtors, fn($a, $b) => $b['amount'] <=> $a['amount']);
    usort($creditors, fn($a, $b) => $b['amount'] <=> $a['amount']);

    $settlements = [];
    $i = 0; // debtor index
    $j = 0; // creditor index

    while ($i < count($debtors) && $j < count($creditors)) {
        $debtorAmount = $debtors[$i]['amount'];
        $creditorAmount = $creditors[$j]['amount'];

        $settleAmount = round(min($debtorAmount, $creditorAmount), 2);

        if ($settleAmount > 0.00) {
            $settlements[] = [
                'from_user_id'   => $debtors[$i]['user_id'],
                'from_user_name' => $debtors[$i]['name'],
                'to_user_id'     => $creditors[$j]['user_id'],
                'to_user_name'   => $creditors[$j]['name'],
                'amount'         => $settleAmount
            ];

            $debtors[$i]['amount'] = round($debtors[$i]['amount'] - $settleAmount, 2);
            $creditors[$j]['amount'] = round($creditors[$j]['amount'] - $settleAmount, 2);
        }

        if ($debtors[$i]['amount'] <= 0.01) {
            $i++;
        }
        if ($creditors[$j]['amount'] <= 0.01) {
            $j++;
        }
    }

    return $settlements;
}

/**
 * 6. Get Spending Breakdown by Category.
 */
function getCategorySpending(int $tripId): array {
    $db = getDBConnection();

    $stmt = $db->prepare("
        SELECT 
            c.id, c.name, c.icon, c.color,
            COALESCE(SUM(t.amount), 0) as total_amount,
            COUNT(t.id) as count
        FROM categories c
        LEFT JOIN transactions t ON t.category_id = c.id AND t.trip_id = ? AND t.type = 'expense'
        WHERE c.trip_id = ? OR c.trip_id IS NULL
        GROUP BY c.id, c.name, c.icon, c.color
        HAVING total_amount > 0
        ORDER BY total_amount DESC
    ");
    $stmt->execute([$tripId, $tripId]);
    $categories = $stmt->fetchAll();

    $totalSpend = 0.0;
    foreach ($categories as $cat) {
        $totalSpend += (float)$cat['total_amount'];
    }

    $result = [];
    foreach ($categories as $cat) {
        $amt = round((float)$cat['total_amount'], 2);
        $percentage = $totalSpend > 0 ? round(($amt / $totalSpend) * 100, 1) : 0;
        $result[] = [
            'id'         => (int)$cat['id'],
            'name'       => $cat['name'],
            'icon'       => $cat['icon'],
            'color'      => $cat['color'],
            'amount'     => $amt,
            'count'      => (int)$cat['count'],
            'percentage' => $percentage
        ];
    }

    return $result;
}

/**
 * 7. Get Personal CashBook Ledger for a Specific User (Money In vs Money Out).
 */
function getUserCashbookLedger(int $tripId, int $userId): array {
    $db = getDBConnection();

    // Check if user contributed starting money
    $tripStmt = $db->prepare("SELECT starting_payer_id, starting_money, starting_payment_method, currency_symbol, created_at FROM trips WHERE id = ?");
    $tripStmt->execute([$tripId]);
    $trip = $tripStmt->fetch();

    $currencySymbol = $trip['currency_symbol'] ?? '₹';
    $entries = [];
    $totalIn = 0.0;
    $totalOut = 0.0;
    $inByMethod = ['cash' => 0.0, 'upi' => 0.0, 'card' => 0.0, 'bank' => 0.0, 'other' => 0.0];
    $outByMethod = ['cash' => 0.0, 'upi' => 0.0, 'card' => 0.0, 'bank' => 0.0, 'other' => 0.0];

    // 1. If starting pool was contributed by this user (Money Out from personal wallet into trip pool)
    if ((int)($trip['starting_payer_id'] ?? 0) === $userId && (float)($trip['starting_money'] ?? 0) > 0) {
        $amt = (float)$trip['starting_money'];
        $meth = strtolower($trip['starting_payment_method'] ?? 'cash');
        $totalOut += $amt;
        $outByMethod[$meth] = ($outByMethod[$meth] ?? 0.0) + $amt;
        $entries[] = [
            'type'            => 'out',
            'flow_type'       => 'starting_contribution',
            'amount'          => $amt,
            'description'     => 'Trip Starting Cash Contribution',
            'payment_method'  => $meth,
            'date'            => $trip['created_at'],
            'formatted_date'  => date('M d, g:i A', strtotime($trip['created_at'])),
            'category_name'   => 'Starting Pool',
            'category_icon'   => 'vault'
        ];
    }

    // 2. Added Money (Pool Income) where received_by = userId (Money In)
    // Includes personal income (trip_id IS NULL) added via CashBook
    $stmt = $db->prepare("
        SELECT id, amount, description, payment_method, transaction_date, notes
        FROM transactions 
        WHERE type = 'income' AND received_by = ? AND (trip_id = ? OR trip_id IS NULL)
    ");
    $stmt->execute([$userId, $tripId]);
    while ($row = $stmt->fetch()) {
        $amt = (float)$row['amount'];
        $meth = strtolower($row['payment_method'] ?? 'cash');
        $totalIn += $amt;
        $inByMethod[$meth] = ($inByMethod[$meth] ?? 0.0) + $amt;
        $entries[] = [
            'type'            => 'in',
            'flow_type'       => 'added_money',
            'amount'          => $amt,
            'description'     => $row['description'] ?: 'Added Pool Cash',
            'payment_method'  => $meth,
            'date'            => $row['transaction_date'],
            'formatted_date'  => date('M d, g:i A', strtotime($row['transaction_date'])),
            'category_name'   => 'Cash Received',
            'category_icon'   => 'wallet'
        ];
    }

    // 3. Expenses paid by this user (Money Out from personal wallet)
    $stmt = $db->prepare("
        SELECT t.id, t.amount, t.description, t.payment_method, t.transaction_date, t.notes,
               c.name as category_name, c.icon as category_icon, c.color as category_color
        FROM transactions t
        LEFT JOIN categories c ON c.id = t.category_id
        WHERE t.trip_id = ? AND t.type = 'expense' AND t.paid_by = ?
    ");
    $stmt->execute([$tripId, $userId]);
    $expenseRows = $stmt->fetchAll();

    // Find which expenses have splits (shared) vs no splits (personal)
    $expenseIds = array_map(fn($r) => (int)$r['id'], $expenseRows);
    $hasSplitIds = [];
    if (!empty($expenseIds)) {
        $placeholders = implode(',', array_fill(0, count($expenseIds), '?'));
        $splitStmt = $db->prepare("SELECT DISTINCT transaction_id FROM expense_splits WHERE transaction_id IN ($placeholders)");
        $splitStmt->execute($expenseIds);
        while ($sRow = $splitStmt->fetch()) {
            $hasSplitIds[] = (int)$sRow['transaction_id'];
        }
    }

    foreach ($expenseRows as $row) {
        $amt = (float)$row['amount'];
        $meth = strtolower($row['payment_method'] ?? 'cash');
        $totalOut += $amt;
        $outByMethod[$meth] = ($outByMethod[$meth] ?? 0.0) + $amt;
        $isPersonal = !in_array((int)$row['id'], $hasSplitIds);

        $entries[] = [
            'type'            => 'out',
            'flow_type'       => 'expense',
            'is_personal'     => $isPersonal,
            'expense_timing'  => 'during_trip',
            'amount'          => $amt,
            'description'     => $row['description'],
            'payment_method'  => $meth,
            'date'            => $row['transaction_date'],
            'formatted_date'  => date('M d, g:i A', strtotime($row['transaction_date'])),
            'category_name'   => $row['category_name'] ?: 'Expense',
            'category_icon'   => $row['category_icon'] ?: 'receipt',
            'category_color'  => $row['category_color'] ?? null,
        ];
    }

    // 4. Settlements Received (Money In from other members)
    $stmt = $db->prepare("
        SELECT s.id, s.amount, s.payment_method, s.paid_at, s.notes, u.name as from_user_name
        FROM settlements s
        JOIN users u ON u.id = s.from_user
        WHERE s.trip_id = ? AND s.to_user = ? AND s.status = 'paid'
    ");
    $stmt->execute([$tripId, $userId]);
    while ($row = $stmt->fetch()) {
        $amt = (float)$row['amount'];
        $meth = strtolower($row['payment_method'] ?? 'upi');
        $totalIn += $amt;
        $inByMethod[$meth] = ($inByMethod[$meth] ?? 0.0) + $amt;
        $entries[] = [
            'type'            => 'in',
            'flow_type'       => 'settlement_received',
            'amount'          => $amt,
            'description'     => "Settlement received from {$row['from_user_name']}",
            'payment_method'  => $meth,
            'date'            => $row['paid_at'],
            'formatted_date'  => date('M d, g:i A', strtotime($row['paid_at'])),
            'category_name'   => 'Settlement In',
            'category_icon'   => 'arrow-down-left'
        ];
    }

    // 5. Settlements Sent (Money Out paid to other members)
    $stmt = $db->prepare("
        SELECT s.id, s.amount, s.payment_method, s.paid_at, s.notes, u.name as to_user_name
        FROM settlements s
        JOIN users u ON u.id = s.to_user
        WHERE s.trip_id = ? AND s.from_user = ? AND s.status = 'paid'
    ");
    $stmt->execute([$tripId, $userId]);
    while ($row = $stmt->fetch()) {
        $amt = (float)$row['amount'];
        $meth = strtolower($row['payment_method'] ?? 'upi');
        $totalOut += $amt;
        $outByMethod[$meth] = ($outByMethod[$meth] ?? 0.0) + $amt;
        $entries[] = [
            'type'            => 'out',
            'flow_type'       => 'settlement_sent',
            'amount'          => $amt,
            'description'     => "Settlement paid to {$row['to_user_name']}",
            'payment_method'  => $meth,
            'date'            => $row['paid_at'],
            'formatted_date'  => date('M d, g:i A', strtotime($row['paid_at'])),
            'category_name'   => 'Settlement Out',
            'category_icon'   => 'arrow-up-right'
        ];
    }

    // Sort entries newest first
    usort($entries, fn($a, $b) => strcmp($b['date'], $a['date']));

    // Attach payment meta to entries
    foreach ($entries as &$entry) {
        $meta = getPaymentMethodMeta($entry['payment_method']);
        $entry['payment_method_label'] = $meta['label'];
        $entry['payment_method_icon'] = $meta['icon'];
    }
    unset($entry);

    return [
        'user_id'          => $userId,
        'currency_symbol'  => $currencySymbol,
        'total_in'         => round($totalIn, 2),
        'total_out'        => round($totalOut, 2),
        'net_outflow'      => round($totalOut - $totalIn, 2),
        'in_by_method'     => $inByMethod,
        'out_by_method'    => $outByMethod,
        'entries'          => $entries
    ];
}

