<?php
/**
 * TripSplit Admin Panel - Audit Logging Helper
 * Section 37, 38, 49
 */

declare(strict_types=1);

require_once __DIR__ . '/db.php';

function logAdminAudit(
    string $action,
    string $module,
    ?string $targetType = null,
    ?string $targetId = null,
    $oldData = null,
    $newData = null,
    ?string $reason = null
): bool {
    try {
        $db = getDBConnection();
        ensureAdminTablesExist($db);

        $adminId = $_SESSION['admin_id'] ?? null;
        $adminEmail = $_SESSION['admin_email'] ?? ($_SESSION['admin_username'] ?? 'system');

        $ipAddress = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
        if (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
            $parts = explode(',', $_SERVER['HTTP_X_FORWARDED_FOR']);
            $ipAddress = trim($parts[0]);
        }
        $userAgent = substr($_SERVER['HTTP_USER_AGENT'] ?? '', 0, 500);

        $oldJson = is_array($oldData) || is_object($oldData) ? json_encode($oldData) : ($oldData !== null ? (string)$oldData : null);
        $newJson = is_array($newData) || is_object($newData) ? json_encode($newData) : ($newData !== null ? (string)$newData : null);

        $stmt = $db->prepare("
            INSERT INTO admin_audit_logs 
            (admin_id, admin_email, action, module, target_type, target_id, old_data, new_data, reason, ip_address, user_agent, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
        ");
        return $stmt->execute([
            $adminId,
            $adminEmail,
            strtoupper($action),
            strtolower($module),
            $targetType,
            $targetId,
            $oldJson,
            $newJson,
            $reason,
            $ipAddress,
            $userAgent
        ]);
    } catch (Throwable $e) {
        error_log('Failed to write admin audit log: ' . $e->getMessage());
        return false;
    }
}
