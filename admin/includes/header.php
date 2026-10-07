<?php
/**
 * TripSplit Admin Panel - Ultra User-Friendly SaaS Header Layout
 */

declare(strict_types=1);

require_once __DIR__ . '/auth.php';

requireAdminAuth();

$currentAdmin = getCurrentAdmin();
$currentPage = basename($_SERVER['PHP_SELF']);
$adminRoleInfo = ADMIN_ROLES[$currentAdmin['role']] ?? ['name' => $currentAdmin['role'], 'badge' => 'badge-primary'];
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TripSplit Admin — <?= ucwords(str_replace(['-', '_', '.php'], [' ', ' ', ''], $currentPage)) ?></title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <?php
    $cssFile = dirname(__DIR__) . '/assets/style.css';
    if (!file_exists($cssFile)) {
        $cssFile = dirname(__DIR__) . '/style.css';
    }
    $cssVersion = file_exists($cssFile) ? filemtime($cssFile) : time();
    $cssInline = file_exists($cssFile) ? file_get_contents($cssFile) : '';
    ?>
    <link rel="stylesheet" href="assets/style.css?v=<?= $cssVersion ?>">
    <link rel="stylesheet" href="style.css?v=<?= $cssVersion ?>">
    <?php if (!empty($cssInline)): ?>
    <style>
    <?= $cssInline ?>
    </style>
    <?php endif; ?>
    <script src="https://unpkg.com/lucide@0.460.0/dist/umd/lucide.min.js"></script>
</head>
<body class="top-nav-layout">
    <div class="admin-app-wrapper">
        <!-- Unified User-Friendly Top Navigation Bar -->
        <header class="app-top-console">
            <div class="console-nav-strip">
                <div class="strip-container">
                    <!-- Brand Section -->
                    <div class="console-brand-group">
                        <a href="index.php" class="brand-link">
                            <span class="brand-icon">🛡️</span>
                            <div class="brand-text">
                                <strong>TripSplit</strong>
                                <span class="brand-subtext">Admin</span>
                            </div>
                        </a>
                    </div>

                    <!-- Primary Navigation Links -->
                    <nav class="console-nav-menu" id="consoleNavMenu">
                        <a href="index.php" class="nav-link-item <?= $currentPage === 'index.php' ? 'active' : '' ?>">
                            <i data-lucide="layout-dashboard"></i>
                            <span>Dashboard</span>
                        </a>

                        <a href="users.php" class="nav-link-item <?= in_array($currentPage, ['users.php', 'user-detail.php']) ? 'active' : '' ?>">
                            <i data-lucide="users"></i>
                            <span>Users</span>
                        </a>

                        <a href="trips.php" class="nav-link-item <?= in_array($currentPage, ['trips.php', 'trip-detail.php']) ? 'active' : '' ?>">
                            <i data-lucide="map"></i>
                            <span>Trips</span>
                        </a>

                        <a href="transactions.php" class="nav-link-item <?= in_array($currentPage, ['transactions.php', 'transaction-detail.php']) ? 'active' : '' ?>">
                            <i data-lucide="receipt"></i>
                            <span>Expenses</span>
                        </a>

                        <a href="settlements.php" class="nav-link-item <?= $currentPage === 'settlements.php' ? 'active' : '' ?>">
                            <i data-lucide="hand-coins"></i>
                            <span>Settlements</span>
                        </a>

                        <a href="categories.php" class="nav-link-item <?= $currentPage === 'categories.php' ? 'active' : '' ?>">
                            <i data-lucide="tags"></i>
                            <span>Categories</span>
                        </a>

                        <!-- Operations Dropdown -->
                        <div class="nav-dropdown">
                            <button type="button" class="nav-link-item dropdown-trigger <?= in_array($currentPage, ['receipts.php', 'reports.php', 'notifications.php', 'integrations.php']) ? 'active' : '' ?>">
                                <i data-lucide="layers"></i>
                                <span>Operations</span>
                                <i data-lucide="chevron-down" class="dropdown-chevron-sm"></i>
                            </button>
                            <div class="nav-dropdown-content">
                                <a href="receipts.php" class="<?= $currentPage === 'receipts.php' ? 'active-dropdown-item' : '' ?>">
                                    <i data-lucide="scan-line"></i>
                                    <div>
                                        <strong>Receipts & OCR</strong>
                                        <small>Bill scanning & storage</small>
                                    </div>
                                </a>
                                <a href="reports.php" class="<?= $currentPage === 'reports.php' ? 'active-dropdown-item' : '' ?>">
                                    <i data-lucide="file-bar-chart-2"></i>
                                    <div>
                                        <strong>Reports & Export</strong>
                                        <small>CSV data downloads</small>
                                    </div>
                                </a>
                                <a href="notifications.php" class="<?= $currentPage === 'notifications.php' ? 'active-dropdown-item' : '' ?>">
                                    <i data-lucide="megaphone"></i>
                                    <div>
                                        <strong>Announcements</strong>
                                        <small>Broadcast in-app notices</small>
                                    </div>
                                </a>
                                <a href="integrations.php" class="<?= $currentPage === 'integrations.php' ? 'active-dropdown-item' : '' ?>">
                                    <i data-lucide="bot"></i>
                                    <div>
                                        <strong>AI & WhatsApp</strong>
                                        <small>Automated parser monitor</small>
                                    </div>
                                </a>
                            </div>
                        </div>

                        <!-- Settings & Governance Dropdown -->
                        <div class="nav-dropdown">
                            <button type="button" class="nav-link-item dropdown-trigger <?= in_array($currentPage, ['settings.php', 'auth-settings.php', 'system-health.php', 'admin-users.php', 'audit-logs.php', 'login-logs.php']) ? 'active' : '' ?>">
                                <i data-lucide="settings"></i>
                                <span>Settings</span>
                                <i data-lucide="chevron-down" class="dropdown-chevron-sm"></i>
                            </button>
                            <div class="nav-dropdown-content">
                                <a href="settings.php" class="<?= $currentPage === 'settings.php' ? 'active-dropdown-item' : '' ?>">
                                    <i data-lucide="sliders"></i>
                                    <div>
                                        <strong>App Settings</strong>
                                        <small>Remote flags & versions</small>
                                    </div>
                                </a>
                                <a href="auth-settings.php" class="<?= $currentPage === 'auth-settings.php' ? 'active-dropdown-item' : '' ?>">
                                    <i data-lucide="key-round"></i>
                                    <div>
                                        <strong>Auth Providers</strong>
                                        <small>Phone OTP, Email & Google</small>
                                    </div>
                                </a>
                                <a href="system-health.php" class="<?= $currentPage === 'system-health.php' ? 'active-dropdown-item' : '' ?>">
                                    <i data-lucide="activity"></i>
                                    <div>
                                        <strong>System Health</strong>
                                        <small>DB latency & maintenance</small>
                                    </div>
                                </a>
                                <?php if (hasPermission('admins.view') || $currentAdmin['role'] === 'SUPER_ADMIN'): ?>
                                <a href="admin-users.php" class="<?= $currentPage === 'admin-users.php' ? 'active-dropdown-item' : '' ?>">
                                    <i data-lucide="shield-alert"></i>
                                    <div>
                                        <strong>Admin Team</strong>
                                        <small>Manage roles & staff</small>
                                    </div>
                                </a>
                                <?php endif; ?>
                                <a href="audit-logs.php" class="<?= $currentPage === 'audit-logs.php' ? 'active-dropdown-item' : '' ?>">
                                    <i data-lucide="scroll-text"></i>
                                    <div>
                                        <strong>Audit Trail</strong>
                                        <small>Security change history</small>
                                    </div>
                                </a>
                                <a href="login-logs.php" class="<?= $currentPage === 'login-logs.php' ? 'active-dropdown-item' : '' ?>">
                                    <i data-lucide="log-in"></i>
                                    <div>
                                        <strong>Login Logs</strong>
                                        <small>Authentication sessions</small>
                                    </div>
                                </a>
                            </div>
                        </div>
                    </nav>

                    <!-- Right Controls: Search, Quick links, User -->
                    <div class="console-controls-group">
                        <!-- Compact Expandable Search -->
                        <form action="users.php" method="GET" class="search-capsule-form">
                            <i data-lucide="search" class="search-icon"></i>
                            <input type="text" name="search" id="global-search-input" placeholder="Search travelers, trips..." value="<?= htmlspecialchars($_GET['search'] ?? '') ?>">
                            <span class="search-shortcut-badge">⌘K</span>
                        </form>

                        <a href="../index.php" target="_blank" class="client-btn" title="View TripSplit Mobile Client Web Preview">
                            <i data-lucide="external-link"></i>
                            <span>App</span>
                        </a>

                        <!-- User Profile Pill & Dropdown -->
                        <div class="profile-dropdown-container">
                            <button type="button" class="user-avatar-pill" onclick="toggleProfileDropdown(event)">
                                <div class="avatar-letter"><?= strtoupper(substr($currentAdmin['name'], 0, 1)) ?></div>
                                <span class="user-name-label"><?= htmlspecialchars($currentAdmin['name']) ?></span>
                                <i data-lucide="chevron-down" class="chevron-user-icon"></i>
                            </button>
                            <div class="profile-dropdown-menu" id="profileDropdown">
                                <div class="dropdown-header">
                                    <strong><?= htmlspecialchars($currentAdmin['name']) ?></strong>
                                    <small><?= htmlspecialchars($currentAdmin['email'] ?: '@' . $currentAdmin['username']) ?></small>
                                    <span class="badge <?= $adminRoleInfo['badge'] ?>"><?= htmlspecialchars($currentAdmin['role']) ?></span>
                                </div>
                                <div class="dropdown-divider"></div>
                                <a href="settings.php"><i data-lucide="sliders"></i> App Preferences</a>
                                <a href="system-health.php"><i data-lucide="activity"></i> System Health</a>
                                <a href="audit-logs.php"><i data-lucide="scroll-text"></i> Security Audit Logs</a>
                                <div class="dropdown-divider"></div>
                                <a href="logout.php" class="logout-link"><i data-lucide="log-out"></i> Sign Out</a>
                            </div>
                        </div>

                        <!-- Mobile Hamburger Button -->
                        <button type="button" class="mobile-nav-toggle-btn" onclick="toggleMobileNavMenu()">
                            <i data-lucide="menu"></i>
                        </button>
                    </div>
                </div>
            </div>
        </header>

        <!-- Full-Width Workspace Canvas -->
        <main class="main-workspace">
            <div class="workspace-container">
