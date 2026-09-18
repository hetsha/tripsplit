<?php
/**
 * TripBook Admin Panel - Header Template
 */
$admin = getCurrentAdmin();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TripBook Admin - <?= basename($_SERVER['PHP_SELF'], '.php') ?></title>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="assets/style.css">
</head>
<body>
    <div class="admin-layout">
        <aside class="sidebar">
            <div class="sidebar-header">
                <div class="logo">🛡️</div>
                <span class="logo-text">TripBook Admin</span>
            </div>
            
            <nav class="sidebar-nav">
                <a href="index.php" class="nav-item <?= basename($_SERVER['PHP_SELF']) === 'index.php' ? 'active' : '' ?>">
                    <i data-lucide="layout-dashboard"></i>
                    <span>Dashboard</span>
                </a>
                <a href="users.php" class="nav-item <?= basename($_SERVER['PHP_SELF']) === 'users.php' ? 'active' : '' ?>">
                    <i data-lucide="users"></i>
                    <span>Users</span>
                </a>
                <a href="trips.php" class="nav-item <?= basename($_SERVER['PHP_SELF']) === 'trips.php' ? 'active' : '' ?>">
                    <i data-lucide="map"></i>
                    <span>Trips</span>
                </a>
                <a href="auth-settings.php" class="nav-item <?= basename($_SERVER['PHP_SELF']) === 'auth-settings.php' ? 'active' : '' ?>">
                    <i data-lucide="shield"></i>
                    <span>Auth Settings</span>
                </a>
                <a href="settings.php" class="nav-item <?= basename($_SERVER['PHP_SELF']) === 'settings.php' ? 'active' : '' ?>">
                    <i data-lucide="settings"></i>
                    <span>Settings</span>
                </a>
            </nav>
            
            <div class="sidebar-footer">
                <div class="admin-info">
                    <div class="admin-avatar"><?= strtoupper(substr($admin['name'], 0, 1)) ?></div>
                    <span class="admin-name"><?= htmlspecialchars($admin['name']) ?></span>
                </div>
                <a href="logout.php" class="logout-btn">
                    <i data-lucide="log-out"></i>
                </a>
            </div>
        </aside>
        
        <main class="main-content">
            <header class="top-bar">
                <button class="menu-toggle" onclick="toggleSidebar()">
                    <i data-lucide="menu"></i>
                </button>
                <h1 class="page-title"><?= ucwords(basename($_SERVER['PHP_SELF'], '.php')) ?></h1>
                <a href="../index.php" class="btn-view-site" target="_blank">
                    <i data-lucide="external-link"></i>
                    View Site
                </a>
            </header>
            
            <div class="content-wrapper">
