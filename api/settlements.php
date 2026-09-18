<?php
/**
 * TripBook Smart Settlements API
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

$tripId = (int)($_GET['trip_id'] ?? $_POST['trip_id'] ?? getActiveTripId());
$membership = requireTripMembership($tripId, (int)$currentUser['id']);

if ($method === 'GET') {
    // 1. Get simplified settlement suggestions
    $suggestions = calculateSimplifiedSettlements($tripId);

    // 2. Get member net balances
    $memberBalances = getSplitwiseBalances($tripId);

    // 3. Get settlement history
    $stmt = $db->prepare("
        SELECT 
            s.*,
            f.name as from_name, f.avatar_color as from_color,
            t.name as to_name, t.avatar_color as to_color
        FROM settlements s
        JOIN users f ON f.id = s.from_user
        JOIN users t ON t.id = s.to_user
        WHERE s.trip_id = ?
        ORDER BY s.paid_at DESC, s.id DESC
    ");
    $stmt->execute([$tripId]);
    $history = $stmt->fetchAll();

    foreach ($history as &$h) {
        $meta = getPaymentMethodMeta($h['payment_method'] ?? 'upi');
        $h['payment_method_label'] = $meta['label'];
        $h['payment_method_icon'] = $meta['icon'];
        $h['formatted_amount'] = formatMoney($h['amount'], $membership['currency_symbol']);
        $h['formatted_date'] = date('M d, g:i A', strtotime($h['paid_at']));
    }
    unset($h);

    jsonSuccess('Settlement data', [
        'suggestions'     => $suggestions,
        'member_balances' => array_values(array_filter($memberBalances, fn($b) => $b['user_id'] === (int)$currentUser['id'])),
        'history'         => $history
    ]);
}

if ($method === 'POST') {
    requireCsrf();
    $input = getJsonInput();
    $act = $input['action'] ?? $action;

    // Record a debt settlement
    if ($act === 'settle') {
        $fromUser = (int)($input['from_user'] ?? $currentUser['id']);
        $toUser = (int)($input['to_user'] ?? 0);
        $amount = validateAmount($input['amount'] ?? 0.0, 'Settlement Amount');
        $paymentMethod = validatePaymentMethod($input['payment_method'] ?? 'upi');
        $notes = trim((string)($input['notes'] ?? 'Direct debt settlement'));
        $paidAt = !empty($input['paid_at']) ? date('Y-m-d H:i:s', strtotime($input['paid_at'])) : date('Y-m-d H:i:s');

        if ($toUser <= 0 || $fromUser === $toUser) {
            jsonError('Invalid settlement recipient', 422);
        }

        // Insert settlement record
        $stmt = $db->prepare("
            INSERT INTO settlements (trip_id, from_user, to_user, amount, payment_method, status, notes, paid_at)
            VALUES (?, ?, ?, ?, ?, 'paid', ?, ?)
        ");
        $stmt->execute([
            $tripId,
            $fromUser,
            $toUser,
            $amount,
            $paymentMethod,
            $notes ?: null,
            $paidAt
        ]);

        // Create notification
        $fromName = $currentUser['name'];
        // Get receiver name
        $rStmt = $db->prepare("SELECT name FROM users WHERE id = ?");
        $rStmt->execute([$toUser]);
        $toName = ($rStmt->fetch())['name'] ?? 'someone';
        createNotification($tripId, 'settlement_made', "$fromName paid $toName " . formatMoney($amount, $currencySymbol ?? '₹'));

        jsonSuccess('Settlement marked as paid successfully!');
    }

    // Undo/Delete Settlement
    if ($act === 'undo') {
        $settlementId = (int)($input['id'] ?? 0);
        if ($settlementId <= 0) {
            jsonError('Invalid settlement ID', 422);
        }

        $stmt = $db->prepare("DELETE FROM settlements WHERE id = ? AND trip_id = ?");
        $stmt->execute([$settlementId, $tripId]);

        jsonSuccess('Settlement payment undone successfully');
    }

    jsonError('Invalid action', 400);
}
