<?php
/**
 * TripBook Expense Management API
 * Handles both personal (CashBook) and shared (Splitwise) expenses
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
$action = $_GET['action'] ?? $_POST['action'] ?? 'get';

if ($method === 'GET') {
    $expenseId = (int)($_GET['id'] ?? 0);
    $tripId = (int)($_GET['trip_id'] ?? getActiveTripId());
    
    // Only require trip membership for trip expenses
    if ($tripId > 0) {
        requireTripMembership($tripId, (int)$currentUser['id']);
    }

    if ($expenseId > 0) {
        $stmt = $db->prepare("
            SELECT t.*, c.name as category_name, c.icon as category_icon, c.color as category_color,
                   u.name as payer_name, u.avatar_color as payer_color
            FROM transactions t
            LEFT JOIN categories c ON c.id = t.category_id
            LEFT JOIN users u ON u.id = t.paid_by
            WHERE t.id = ? AND t.type = 'expense' AND (t.trip_id = ? OR t.created_by = ?)
        ");
        $stmt->execute([$expenseId, $tripId, $currentUser['id']]);
        $expense = $stmt->fetch();

        if (!$expense) {
            jsonError('Expense not found', 404);
        }

        // Get splits (only for shared expenses)
        $splits = [];
        if ($expense['trip_id']) {
            $splitStmt = $db->prepare("
                SELECT es.user_id, es.amount, u.name, u.avatar_color
                FROM expense_splits es
                JOIN users u ON u.id = es.user_id
                WHERE es.transaction_id = ?
            ");
            $splitStmt->execute([$expenseId]);
            $splits = $splitStmt->fetchAll();
        }

        $expense['splits'] = $splits;
        jsonSuccess('Expense details', ['expense' => $expense]);
    }
    
    // List expenses (personal + shared for current user)
    if ($expenseId === 0) {
        $page = max(1, (int)($_GET['page'] ?? 1));
        $limit = 50;
        $offset = ($page - 1) * $limit;
        
        $stmt = $db->prepare("
            SELECT t.*, c.name as category_name, c.icon as category_icon, c.color as category_color,
                   u.name as payer_name, u.avatar_color as payer_color
            FROM transactions t
            LEFT JOIN categories c ON c.id = t.category_id
            LEFT JOIN users u ON u.id = t.paid_by
            WHERE t.type = 'expense' AND (t.created_by = ? OR t.paid_by = ?)
            ORDER BY t.transaction_date DESC
            LIMIT ? OFFSET ?
        ");
        $stmt->execute([$currentUser['id'], $currentUser['id'], $limit, $offset]);
        $expenses = $stmt->fetchAll();
        
        // Get total count
        $countStmt = $db->prepare("
            SELECT COUNT(*) as cnt FROM transactions 
            WHERE type = 'expense' AND (created_by = ? OR paid_by = ?)
        ");
        $countStmt->execute([$currentUser['id'], $currentUser['id']]);
        $total = (int)$countStmt->fetch()['cnt'];
        
        jsonSuccess('Expenses loaded', [
            'expenses' => $expenses,
            'total' => $total,
            'page' => $page,
            'has_more' => ($offset + $limit) < $total
        ]);
    }
}

if ($method === 'POST') {
    requireCsrf();
    $input = getJsonInput();
    $act = $input['action'] ?? $action;
    $isPersonal = !empty($input['is_personal']);
    $tripId = (int)($input['trip_id'] ?? getActiveTripId());
    
    // Only require trip membership for shared expenses
    if (!$isPersonal && $tripId > 0) {
        requireTripMembership($tripId, (int)$currentUser['id']);
    }

    // Create Expense
    if ($act === 'create') {
        $amount = validateAmount($input['amount'] ?? 0.0, 'Expense Amount');
        $description = trim((string)($input['description'] ?? ''));
        $categoryId = (int)($input['category_id'] ?? 0);
        $paidBy = (int)($input['paid_by'] ?? $currentUser['id']);
        $paymentMethod = validatePaymentMethod($input['payment_method'] ?? 'cash');
        $txDate = !empty($input['transaction_date']) ? date('Y-m-d H:i:s', strtotime($input['transaction_date'])) : date('Y-m-d H:i:s');
        $notes = trim((string)($input['notes'] ?? ''));
        $rawSplits = $input['splits'] ?? [];
        $requestId = trim((string)($input['client_request_id'] ?? ''));

        if (empty($description)) {
            jsonError('Description is required', 422);
        }

        // Idempotency check
        if (!empty($requestId)) {
            if (isset($_SESSION['processed_requests'][$requestId])) {
                jsonSuccess('Expense already saved (duplicate request ignored)', ['id' => $_SESSION['processed_requests'][$requestId]]);
            }
        }

        // For personal expenses, trip_id should be NULL
        $finalTripId = $isPersonal ? null : $tripId;
        
        // Validate splits only for shared expenses
        $normalizedSplits = [];
        if (!$isPersonal) {
            $normalizedSplits = validateAndNormalizeSplits($amount, $rawSplits);
        }

        // Check if category exists
        if ($categoryId > 0) {
            $catStmt = $db->prepare("SELECT id FROM categories WHERE id = ?");
            $catStmt->execute([$categoryId]);
            if (!$catStmt->fetch()) {
                $categoryId = null;
            }
        } else {
            $categoryId = null;
        }

        $db->beginTransaction();
        try {
            $stmt = $db->prepare("
                INSERT INTO transactions (trip_id, type, amount, description, category_id, paid_by, payment_method, paid_from_pool, created_by, transaction_date, notes)
                VALUES (?, 'expense', ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $paidFromPool = ($isPersonal) ? 0 : 1;
            $stmt->execute([
                $finalTripId,
                $amount,
                $description,
                $categoryId,
                $paidBy,
                $paymentMethod,
                $paidFromPool,
                $currentUser['id'],
                $txDate,
                $notes ?: null
            ]);
            $transactionId = (int)$db->lastInsertId();

            // Insert splits only for shared expenses
            if (!$isPersonal && !empty($normalizedSplits)) {
                $splitStmt = $db->prepare("INSERT INTO expense_splits (transaction_id, user_id, amount) VALUES (?, ?, ?)");
                foreach ($normalizedSplits as $userId => $splitAmount) {
                    $splitStmt->execute([$transactionId, $userId, $splitAmount]);
                }
            }

            $db->commit();

            // Store request ID in session
            if (!empty($requestId)) {
                if (!isset($_SESSION['processed_requests'])) {
                    $_SESSION['processed_requests'] = [];
                }
                if (count($_SESSION['processed_requests']) > 100) {
                    array_shift($_SESSION['processed_requests']);
                }
                $_SESSION['processed_requests'][$requestId] = $transactionId;
            }

            // Create notification for shared expenses
            if (!$isPersonal && $tripId > 0) {
                $payerName = $currentUser['name'];
                createNotification($tripId, 'expense_added', "$payerName added \"{$description}\" for " . formatMoney($amount, $membership['currency_symbol'] ?? '₹'));
            }

            jsonSuccess('Expense added successfully!', [
                'expense_id' => $transactionId,
                'is_personal' => $isPersonal
            ]);
        } catch (Throwable $e) {
            $db->rollBack();
            jsonError('Failed to save expense: ' . $e->getMessage(), 500);
        }
    }

    // Update Expense
    if ($act === 'update') {
        $expenseId = (int)($input['id'] ?? 0);
        $amount = validateAmount($input['amount'] ?? 0.0, 'Expense Amount');
        $description = trim((string)($input['description'] ?? ''));
        $categoryId = (int)($input['category_id'] ?? 0);
        $paidBy = (int)($input['paid_by'] ?? $currentUser['id']);
        $paymentMethod = validatePaymentMethod($input['payment_method'] ?? 'cash');
        $txDate = !empty($input['transaction_date']) ? date('Y-m-d H:i:s', strtotime($input['transaction_date'])) : date('Y-m-d H:i:s');
        $notes = trim((string)($input['notes'] ?? ''));
        $rawSplits = $input['splits'] ?? [];

        if ($expenseId <= 0) {
            jsonError('Invalid expense ID', 422);
        }

        if (empty($description)) {
            jsonError('Description is required', 422);
        }

        $finalTripId = $isPersonal ? null : $tripId;
        $normalizedSplits = $isPersonal ? [] : validateAndNormalizeSplits($amount, $rawSplits);

        $db->beginTransaction();
        try {
            $stmt = $db->prepare("
                UPDATE transactions 
                SET trip_id = ?, amount = ?, description = ?, category_id = ?, paid_by = ?, payment_method = ?, paid_from_pool = ?, transaction_date = ?, notes = ?
                WHERE id = ? AND type = 'expense' AND created_by = ?
            ");
            $paidFromPool = ($isPersonal) ? 0 : 1;
            $stmt->execute([
                $finalTripId,
                $amount,
                $description,
                $categoryId,
                $paidBy,
                $paymentMethod,
                $paidFromPool,
                $txDate,
                $notes ?: null,
                $expenseId,
                $currentUser['id']
            ]);

            // Re-create splits only for shared expenses
            $delStmt = $db->prepare("DELETE FROM expense_splits WHERE transaction_id = ?");
            $delStmt->execute([$expenseId]);

            if (!$isPersonal && !empty($normalizedSplits)) {
                $splitStmt = $db->prepare("INSERT INTO expense_splits (transaction_id, user_id, amount) VALUES (?, ?, ?)");
                foreach ($normalizedSplits as $userId => $splitAmount) {
                    $splitStmt->execute([$expenseId, $userId, $splitAmount]);
                }
            }

            $db->commit();
            jsonSuccess('Expense updated successfully');
        } catch (Throwable $e) {
            $db->rollBack();
            jsonError('Failed to update expense: ' . $e->getMessage(), 500);
        }
    }

    // Delete Expense
    if ($act === 'delete') {
        $expenseId = (int)($input['id'] ?? 0);
        if ($expenseId <= 0) {
            jsonError('Invalid expense ID', 422);
        }

        $stmt = $db->prepare("DELETE FROM transactions WHERE id = ? AND type = 'expense' AND created_by = ?");
        $stmt->execute([$expenseId, $currentUser['id']]);

        jsonSuccess('Expense deleted successfully');
    }

    jsonError('Invalid action', 400);
}
