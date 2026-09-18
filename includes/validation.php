<?php
/**
 * TripBook Input & Transaction Validation
 */

declare(strict_types=1);

require_once __DIR__ . '/functions.php';

/**
 * Validate that an amount is a positive number with max 2 decimals.
 */
function validateAmount(mixed $amount, string $fieldName = 'Amount'): float {
    if ($amount === null || $amount === '' || !is_numeric($amount)) {
        jsonError("{$fieldName} must be a valid number", 422);
    }

    $floatVal = round((float)$amount, 2);

    if ($floatVal <= 0) {
        jsonError("{$fieldName} must be greater than 0", 422);
    }

    if ($floatVal > 10000000.00) {
        jsonError("{$fieldName} exceeds maximum allowable limit", 422);
    }

    return $floatVal;
}

/**
 * Validate payment method.
 */
function validatePaymentMethod(?string $method): string {
    $allowed = ['cash', 'upi', 'card', 'bank', 'other'];
    $method = strtolower(trim((string)$method));
    if (!in_array($method, $allowed, true)) {
        return 'cash';
    }
    return $method;
}



/**
 * Validate that sum of splits exactly equals total expense amount (within +/- 0.02 tolerance for rounding adjustments).
 * Adjusts penny discrepancy to the payer or first split if difference <= 0.05.
 */
function validateAndNormalizeSplits(float $totalAmount, array $splits): array {
    if (empty($splits)) {
        jsonError('At least one member must be included in the split', 422);
    }

    $normalizedSplits = [];
    $sum = 0.0;

    foreach ($splits as $split) {
        $userId = (int)($split['user_id'] ?? 0);
        $amount = (float)($split['amount'] ?? 0.0);

        if ($userId <= 0) {
            jsonError('Invalid member selected in split', 422);
        }

        if ($amount < 0) {
            jsonError('Split amount cannot be negative', 422);
        }

        $amount = round($amount, 2);
        $normalizedSplits[$userId] = $amount;
        $sum += $amount;
    }

    $sum = round($sum, 2);
    $diff = round($totalAmount - $sum, 2);

    // If difference is small rounding artifact (<= 0.05), adjust on the first participant
    if (abs($diff) > 0.00 && abs($diff) <= 0.05) {
        $firstUserId = array_key_first($normalizedSplits);
        $normalizedSplits[$firstUserId] = round($normalizedSplits[$firstUserId] + $diff, 2);
        $sum = $totalAmount;
    } elseif (abs($diff) > 0.05) {
        jsonError(
            sprintf('Split sum (%s) does not match total expense amount (%s). Difference: %s',
                formatMoney($sum), formatMoney($totalAmount), formatMoney(abs($diff))),
            422
        );
    }

    return $normalizedSplits;
}
