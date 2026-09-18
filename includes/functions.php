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
