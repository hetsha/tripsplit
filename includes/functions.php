<?php
/**
 * TripBook Helper Functions
 */

declare(strict_types=1);

/**
 * Send a JSON success response and terminate execution.
 */
function jsonSuccess(string $message = 'Success', array $data = [], int $statusCode = 200): void {
    http_response_code($statusCode);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'success' => true,
        'message' => $message,
        'data'    => $data
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit;
}

/**
 * Send a JSON error response and terminate execution.
 */
function jsonError(string $message = 'An error occurred', int $statusCode = 400, array $errors = []): void {
    http_response_code($statusCode);
    header('Content-Type: application/json; charset=utf-8');
    $response = [
        'success' => false,
        'message' => $message
    ];
    if (!empty($errors)) {
        $response['errors'] = $errors;
    }
    echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit;
}

/**
 * Escape HTML output securely.
 */
function e(?string $string): string {
    return htmlspecialchars($string ?? '', ENT_QUOTES, 'UTF-8');
}

/**
 * Format decimal money to currency format with 2 decimal places.
 */
function formatMoney(float|int|string $amount, string $symbol = '₹'): string {
    $num = (float)$amount;
    return $symbol . number_format($num, 2, '.', ',');
}

/**
 * Parse JSON request body.
 */
function getJsonInput(): array {
    $raw = file_get_contents('php://input');
    if (empty($raw)) {
        return $_POST;
    }
    $decoded = json_decode($raw, true);
    return is_array($decoded) ? $decoded : [];
}

/**
 * Generate a random unique trip invite code.
 */
function generateTripCode(): string {
    $chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    $code = '';
    for ($i = 0; $i < 5; $i++) {
        $code .= $chars[random_int(0, strlen($chars) - 1)];
    }
    return 'TRIP-' . $code;
}

/**
 * Return payment method icon name & label.
 */
function getPaymentMethodMeta(string $method): array {
    $map = [
        'cash'  => ['label' => 'Cash', 'icon' => 'banknote'],
        'bank'  => ['label' => 'Bank Transfer', 'icon' => 'building'],
    ];
    return $map[strtolower($method)] ?? ['label' => 'Cash', 'icon' => 'banknote'];
}

/**
 * Create a notification for a trip event.
 */
function createNotification(int $tripId, string $type, string $message): void
{
    $db = getDBConnection();
    $stmt = $db->prepare("
        INSERT INTO notifications (trip_id, type, message, is_read, created_at)
        VALUES (?, ?, ?, 0, NOW())
    ");
    $stmt->execute([$tripId, $type, $message]);
}

/**
 * Ensure transaction_payers table exists in the database.
 */
function ensureTransactionPayersTable(): void {
    static $ensured = false;
    if ($ensured) return;
    try {
        $db = getDBConnection();
        $db->exec("
            CREATE TABLE IF NOT EXISTS `transaction_payers` (
                `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                `transaction_id` INT UNSIGNED NOT NULL,
                `user_id` INT UNSIGNED NOT NULL,
                `amount` DECIMAL(12,2) NOT NULL,
                `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE KEY `unique_payer_split` (`transaction_id`, `user_id`),
                FOREIGN KEY (`transaction_id`) REFERENCES `transactions`(`id`) ON DELETE CASCADE,
                FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ");
        $ensured = true;
    } catch (Throwable $e) {
        $ensured = true;
    }
}

/**
 * Ensure receipts table and receipt_url column exist in transactions.
 */
function ensureReceiptColumns(): void {
    static $ensured = false;
    if ($ensured) return;
    try {
        $db = getDBConnection();
        $colCheck = $db->query("SHOW COLUMNS FROM `transactions` LIKE 'receipt_url'")->fetch();
        if (!$colCheck) {
            $db->exec("ALTER TABLE `transactions` ADD COLUMN `receipt_url` VARCHAR(500) NULL AFTER `notes`");
        }

        $db->exec("
            CREATE TABLE IF NOT EXISTS `receipts` (
                `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                `transaction_id` INT UNSIGNED NULL,
                `user_id` INT UNSIGNED NOT NULL,
                `image_url` VARCHAR(500) NOT NULL,
                `file_path` VARCHAR(500) NOT NULL,
                `raw_text` MEDIUMTEXT NULL,
                `parsed_data` JSON NULL,
                `confidence` DECIMAL(3,2) NULL,
                `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX (`transaction_id`),
                INDEX (`user_id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ");
        $ensured = true;
    } catch (Throwable $e) {
        $ensured = true;
    }
}

/**
 * Compute and attach individual user lent/owe position for a transaction.
 */
function attachUserTransactionPosition(array &$tx, int $currentUserId, string $currencySymbol = '₹'): void {
    $txAmount = (float)($tx['amount'] ?? 0.0);
    $type = $tx['type'] ?? 'expense';
    $splits = $tx['splits'] ?? [];
    $payers = $tx['payers'] ?? [];

    // Find current user's paid amount
    $myPaid = 0.0;
    $hasPayerList = !empty($payers);
    if ($hasPayerList) {
        foreach ($payers as $p) {
            if ((int)($p['user_id'] ?? 0) === $currentUserId) {
                $myPaid += (float)($p['amount'] ?? 0.0);
            }
        }
    } else {
        $payerId = (int)($tx['payer_id'] ?? 0);
        if ($payerId === $currentUserId) {
            $myPaid = $txAmount;
        }
    }

    // Find current user's split amount (share)
    $mySplit = 0.0;
    $userInSplit = false;
    foreach ($splits as $sp) {
        if ((int)($sp['user_id'] ?? 0) === $currentUserId) {
            $mySplit = (float)($sp['amount'] ?? 0.0);
            $userInSplit = true;
            break;
        }
    }

    if ($type === 'expense') {
        if ($hasPayerList && count($payers) > 1) {
            // Multi-payer expense: Net = Paid - Share
            $userNet = $myPaid - $mySplit;
            if ($userNet > 0.001) {
                $tx['user_status'] = 'lent';
                $tx['user_status_label'] = 'You lent';
                $tx['user_net'] = round($userNet, 2);
                $tx['formatted_user_amount'] = '+' . formatMoney($userNet, $currencySymbol);
            } elseif ($userNet < -0.001) {
                $tx['user_status'] = 'owe';
                $tx['user_status_label'] = 'You owe';
                $tx['user_net'] = round($userNet, 2);
                $tx['formatted_user_amount'] = '-' . formatMoney(abs($userNet), $currencySymbol);
            } else {
                if ($myPaid > 0.001 || $userInSplit) {
                    $tx['user_status'] = 'paid';
                    $tx['user_status_label'] = 'Settled';
                    $tx['user_net'] = 0.0;
                    $tx['formatted_user_amount'] = formatMoney(0, $currencySymbol);
                } else {
                    $tx['user_status'] = 'none';
                    $tx['user_status_label'] = 'Not involved';
                    $tx['user_net'] = 0.0;
                    $tx['formatted_user_amount'] = formatMoney(0, $currencySymbol);
                }
            }
        } else {
            // Single payer
            $isPayer = ($myPaid > 0.001);
            if ($isPayer) {
                $lent = !empty($splits) ? max(0.0, $txAmount - $mySplit) : 0.0;
                if ($lent > 0.001) {
                    $tx['user_status'] = 'lent';
                    $tx['user_status_label'] = 'You lent';
                    $tx['user_net'] = round($lent, 2);
                    $tx['formatted_user_amount'] = '+' . formatMoney($lent, $currencySymbol);
                } else {
                    $tx['user_status'] = 'paid';
                    $tx['user_status_label'] = 'You paid';
                    $tx['user_net'] = 0.0;
                    $tx['formatted_user_amount'] = formatMoney($txAmount, $currencySymbol);
                }
            } else {
                if ($userInSplit && $mySplit > 0.001) {
                    $tx['user_status'] = 'owe';
                    $tx['user_status_label'] = 'You owe';
                    $tx['user_net'] = -round($mySplit, 2);
                    $tx['formatted_user_amount'] = '-' . formatMoney($mySplit, $currencySymbol);
                } else {
                    $tx['user_status'] = 'none';
                    $tx['user_status_label'] = 'Not involved';
                    $tx['user_net'] = 0.0;
                    $tx['formatted_user_amount'] = formatMoney(0, $currencySymbol);
                }
            }
        }
    } elseif ($type === 'settlement') {
        $receiverId = (int)($tx['receiver_id'] ?? 0);
        $isPayer = ($myPaid > 0.001);
        if ($isPayer) {
            $tx['user_status'] = 'settled_paid';
            $tx['user_status_label'] = 'You paid';
            $tx['user_net'] = -round($txAmount, 2);
            $tx['formatted_user_amount'] = '-' . formatMoney($txAmount, $currencySymbol);
        } elseif ($receiverId === $currentUserId) {
            $tx['user_status'] = 'settled_received';
            $tx['user_status_label'] = 'You received';
            $tx['user_net'] = round($txAmount, 2);
            $tx['formatted_user_amount'] = '+' . formatMoney($txAmount, $currencySymbol);
        } else {
            $tx['user_status'] = 'none';
            $tx['user_status_label'] = 'Not involved';
            $tx['user_net'] = 0.0;
            $tx['formatted_user_amount'] = formatMoney(0, $currencySymbol);
        }
    } else {
        $tx['user_status'] = 'income';
        $tx['user_status_label'] = 'Added';
        $tx['user_net'] = round($txAmount, 2);
        $tx['formatted_user_amount'] = '+' . formatMoney($txAmount, $currencySymbol);
    }
}

