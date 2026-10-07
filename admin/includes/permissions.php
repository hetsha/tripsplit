<?php
/**
 * TripSplit Admin Panel - Role-Based Access Control (RBAC)
 * Section 5 & Section 75
 */

declare(strict_types=1);

const ADMIN_ROLES = [
    'SUPER_ADMIN' => [
        'name' => 'Super Administrator',
        'badge' => 'badge-danger',
        'permissions' => ['*']
    ],
    'ADMIN' => [
        'name' => 'Administrator',
        'badge' => 'badge-primary',
        'permissions' => [
            'dashboard.view',
            'users.view', 'users.create', 'users.edit', 'users.suspend',
            'trips.view', 'trips.edit', 'trips.archive',
            'transactions.view', 'transactions.edit',
            'settlements.view', 'settlements.manage',
            'categories.view', 'categories.create', 'categories.edit', 'categories.delete',
            'reports.view', 'reports.export',
            'notifications.view', 'notifications.create', 'notifications.send',
            'receipts.view', 'receipts.manage',
            'settings.view', 'settings.edit',
            'audit_logs.view', 'health.view'
        ]
    ],
    'SUPPORT' => [
        'name' => 'Support Specialist',
        'badge' => 'badge-warning',
        'permissions' => [
            'dashboard.view',
            'users.view', 'users.edit',
            'trips.view', 'trips.edit',
            'transactions.view',
            'settlements.view',
            'receipts.view',
            'reports.view'
        ]
    ],
    'VIEWER' => [
        'name' => 'Read-Only Viewer',
        'badge' => 'badge-secondary',
        'permissions' => [
            'dashboard.view',
            'users.view',
            'trips.view',
            'transactions.view',
            'settlements.view',
            'reports.view'
        ]
    ]
];

function getAdminRole(): string {
    return $_SESSION['admin_role'] ?? 'SUPER_ADMIN';
}

function hasPermission(string $permission): bool {
    $role = getAdminRole();
    if (!isset(ADMIN_ROLES[$role])) {
        return false;
    }

    $permissions = ADMIN_ROLES[$role]['permissions'];
    if (in_array('*', $permissions, true)) {
        return true;
    }

    if (in_array($permission, $permissions, true)) {
        return true;
    }

    // Module-level wildcard check (e.g., users.*)
    $parts = explode('.', $permission);
    if (count($parts) === 2 && in_array($parts[0] . '.*', $permissions, true)) {
        return true;
    }

    return false;
}

function requirePermission(string $permission): void {
    if (!hasPermission($permission)) {
        http_response_code(403);
        include __DIR__ . '/header.php';
        ?>
        <div class="card" style="margin-top: 20px; text-align: center; padding: 40px;">
            <div style="font-size: 48px; margin-bottom: 16px;">🚫</div>
            <h2>Access Denied</h2>
            <p style="color: #64748b; margin-top: 8px;">
                Your role (<strong><?= htmlspecialchars(ADMIN_ROLES[getAdminRole()]['name'] ?? getAdminRole()) ?></strong>) does not have permission for: <code><?= htmlspecialchars($permission) ?></code>.
            </p>
            <div style="margin-top: 24px;">
                <a href="index.php" class="btn btn-primary">Return to Dashboard</a>
            </div>
        </div>
        <?php
        include __DIR__ . '/footer.php';
        exit;
    }
}
