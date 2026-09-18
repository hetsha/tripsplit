<?php
/**
 * TripBook - Mobile-First Shared Trip Expense & CashBook App
 */

declare(strict_types=1);

require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/includes/functions.php';
require_once __DIR__ . '/includes/auth.php';

// Auto-check if database is initialized. If not, redirect to friendly installer setup.php
try {
    $db = getDBConnection();
    $test = $db->query("SELECT 1 FROM trips LIMIT 1");
} catch (Throwable $e) {
    header('Location: setup.php');
    exit;
}

// Check if user is authenticated
$isAuthenticated = isAuthenticated();
$currentUser = $isAuthenticated ? getCurrentUser() : null;
$csrfToken = getCsrfToken();
$activeTripId = $isAuthenticated ? getActiveTripId() : 0;

// Check for trip code in URL (for invite links) — ?invite=TRIP-CODE
$pendingTripCode = $_GET['invite'] ?? null;

// Check for trip url_token in URL — ?trip=TOKEN
$pendingTripToken = $_GET['trip'] ?? null;

// Resolve trip token to trip_id
if ($isAuthenticated && !empty($pendingTripToken)) {
    $tokenStmt = $db->prepare("SELECT id FROM trips WHERE url_token = ?");
    $tokenStmt->execute([$pendingTripToken]);
    $tokenRow = $tokenStmt->fetch();
    if ($tokenRow) {
        $resolvedTripId = (int)$tokenRow['id'];
        // Verify membership
        $memberStmt = $db->prepare("SELECT 1 FROM trip_members WHERE trip_id = ? AND user_id = ?");
        $memberStmt->execute([$resolvedTripId, (int)$currentUser['id']]);
        if ($memberStmt->fetch()) {
            setActiveTripId($resolvedTripId);
            $activeTripId = $resolvedTripId;
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
  <title>TripBook - Shared Trip Cash & Expenses</title>
  
  <!-- PWA & Theme -->
  <meta name="theme-color" content="#2563eb">
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="default">
  <link rel="manifest" href="manifest.json">
  
  <!-- Fonts: Plus Jakarta Sans -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">

  <!-- Lucide Icons -->
  <script src="https://unpkg.com/lucide@0.460.0/dist/umd/lucide.min.js"></script>

  <!-- App Stylesheets -->
  <link rel="stylesheet" href="assets/css/style.css?v=<?= time() ?>">
  <link rel="stylesheet" href="assets/css/responsive.css?v=<?= time() ?>">
  
  <script>
    (function() {
      const savedTheme = localStorage.getItem('theme');
      console.log('[Theme Blocker] Inline head script ran. savedTheme:', savedTheme);
      if (savedTheme === 'light') {
        document.documentElement.classList.add('light-theme');
        document.addEventListener('DOMContentLoaded', () => {
          document.body.classList.add('light-theme');
          console.log('[Theme Blocker] DOM loaded. Applied light-theme to body.');
        });
      }
    })();
  </script>  <style>
    /* Login Screen Styles */
    .login-screen,
    .onboarding-screen {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 24px;
      background-color: var(--bg-app);
      background-image: 
        radial-gradient(at 0% 0%, rgba(91, 92, 255, 0.04) 0px, transparent 50%),
        radial-gradient(at 100% 0%, rgba(139, 92, 246, 0.05) 0px, transparent 50%),
        radial-gradient(at 50% 100%, rgba(217, 70, 239, 0.03) 0px, transparent 50%);
      background-attachment: fixed;
    }
    
    .login-card,
    .onboarding-card {
      background: var(--bg-card);
      backdrop-filter: var(--glass-blur);
      -webkit-backdrop-filter: var(--glass-blur);
      border: 1px solid var(--border);
      border-radius: var(--radius-lg);
      padding: 32px 24px;
      width: 100%;
      max-width: 380px;
      box-shadow: var(--shadow-lg);
      color: var(--text-primary);
    }
    
    .login-logo {
      text-align: center;
      margin-bottom: 24px;
    }
    
    .login-logo-icon {
      font-size: 56px;
      margin-bottom: 12px;
    }
    
    .login-logo h1 {
      font-size: 28px;
      font-weight: 800;
      color: var(--text-primary);
      margin: 0;
    }
    
    .login-logo p {
      font-size: 14px;
      color: var(--text-secondary);
      margin: 4px 0 0;
    }
    
    .login-form {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    
    .phone-input-group {
      position: relative;
    }
    
    .phone-prefix {
      position: absolute;
      left: 14px;
      top: 50%;
      transform: translateY(-50%);
      font-size: 15px;
      font-weight: 600;
      color: var(--text-primary);
    }
    
    .phone-input-group .form-control {
      padding-left: 58px;
    }
    
    .otp-display {
      text-align: center;
      padding: 16px;
      background: var(--bg-secondary);
      border-radius: 12px;
      margin-bottom: 8px;
      border: 1px solid var(--border);
    }
    
    .otp-phone {
      font-size: 14px;
      color: var(--text-secondary);
    }
    
    .otp-phone strong {
      color: var(--text-primary);
    }
    
    .otp-timer {
      font-size: 13px;
      color: var(--primary);
      margin-top: 4px;
      font-weight: 600;
    }
    
    .otp-input {
      text-align: center;
      font-size: 24px;
      font-weight: 700;
      letter-spacing: 8px;
      padding: 16px;
    }
    
    .otp-actions {
      text-align: center;
    }
    
    .resend-link {
      background: none;
      border: none;
      color: var(--primary);
      font-weight: 600;
      cursor: pointer;
      display: none;
    }
    .resend-link:hover {
      text-decoration: underline;
    }
    
    .onboarding-icon {
      font-size: 64px;
      margin-bottom: 16px;
    }
    
    .onboarding-title {
      font-size: 24px;
      font-weight: 800;
      margin-bottom: 8px;
      color: var(--text-primary);
    }
    
    .onboarding-subtitle {
      font-size: 14px;
      color: var(--text-secondary);
      margin-bottom: 24px;
    }
    
    .onboarding-actions {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }
    
    .btn-onboarding {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 10px;
      padding: 16px;
      border-radius: 14px;
      font-size: 15px;
      font-weight: 700;
      border: none;
      cursor: pointer;
      transition: all 0.2s;
    }
    
    .btn-onboarding-primary {
      background: var(--brand-gradient);
      color: white;
      box-shadow: 0 4px 12px rgba(139, 92, 246, 0.25);
    }
    
    .btn-onboarding-primary:hover {
      transform: translateY(-1px);
      box-shadow: 0 6px 16px rgba(139, 92, 246, 0.35);
    }
    
    .btn-onboarding-secondary {
      background: var(--bg-secondary);
      border: 1px solid var(--border);
      color: var(--text-primary);
    }
    .btn-onboarding-secondary:hover {
      background: var(--bg-card);
    }
    
    .btn-onboarding-skip {
      background: none;
      border: none;
      color: var(--text-secondary);
      font-size: 14px;
      margin-top: 8px;
      cursor: pointer;
      font-weight: 600;
    }
    
    .btn-onboarding-skip:hover {
      color: var(--text-primary);
    }
    
    /* Auth Tabs */
    .auth-tabs {
      display: flex;
      gap: 0;
      border-bottom: 2px solid var(--border);
      margin-bottom: 20px;
    }
    
    .auth-tab {
      flex: 1;
      padding: 10px 8px;
      background: none;
      border: none;
      border-bottom: 2px solid transparent;
      margin-bottom: -2px;
      font-size: 13px;
      font-weight: 600;
      color: var(--text-secondary);
      cursor: pointer;
      transition: all 0.2s;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
    }
    
    .auth-tab.active {
      color: var(--primary);
      border-bottom-color: var(--primary);
    }
    
    .auth-tab:hover:not(.active) {
      color: var(--text-primary);
    }
    
    .auth-divider {
      display: flex;
      align-items: center;
      gap: 12px;
      color: var(--text-secondary);
      font-size: 13px;
      margin: 4px 0;
    }
    
    .auth-divider::before,
    .auth-divider::after {
      content: '';
      flex: 1;
      height: 1px;
      background: var(--border);
    }
    
    .google-login-section {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 12px;
    }
    
    #google-signin-btn {
      width: 100%;
    }
    
    #google-signin-btn > div {
      width: 100% !important;
    }
    
    .google-btn-fallback {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 10px;
      width: 100%;
      padding: 14px 16px;
      border: 1px solid var(--border);
      border-radius: 12px;
      background: var(--bg-secondary);
      font-size: 15px;
      font-weight: 600;
      color: var(--text-primary);
      cursor: pointer;
      transition: all 0.2s;
    }
    
    .google-btn-fallback:hover {
      background: var(--bg-card);
      box-shadow: var(--shadow-sm);
    }
    
    .google-btn-fallback img {
      width: 20px;
      height: 20px;
    }
    
    .spinner {
      display: inline-block;
      width: 16px;
      height: 16px;
      border: 2px solid transparent;
      border-top-color: currentColor;
      border-radius: 50%;
      animation: spin 0.6s linear infinite;
    }
    
    @keyframes spin {
      to { transform: rotate(360deg); }
    }
  </style>
</head>
<body>

<!-- LOGIN SCREEN (shown when not authenticated) -->
<div id="login-screen" class="login-screen" style="display: <?= $isAuthenticated ? 'none' : 'flex' ?>;">
  <div class="login-card">
    <div class="login-logo">
      <div class="login-logo-icon">🧳</div>
      <h1>TripBook</h1>
      <p>Split expenses, track spending</p>
    </div>

    <!-- Auth Method Tabs -->
    <div class="auth-tabs">
      <button type="button" class="auth-tab active" data-auth-tab="phone" onclick="Auth.switchTab('phone')">
        <i data-lucide="smartphone" style="width:14px;height:14px;"></i> Phone
      </button>
      <button type="button" class="auth-tab" data-auth-tab="email" onclick="Auth.switchTab('email')">
        <i data-lucide="mail" style="width:14px;height:14px;"></i> Email
      </button>
      <button type="button" class="auth-tab" data-auth-tab="google" onclick="Auth.switchTab('google')">
        <svg width="14" height="14" viewBox="0 0 24 24"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>
      </button>
    </div>

    <!-- Phone Number Screen -->
    <div id="phone-screen" class="login-form">
      <div class="phone-input-group">
        <span class="phone-prefix">+91</span>
        <input type="tel" id="phone-number" class="form-control" 
               placeholder="Enter your phone number" maxlength="10" 
               inputmode="numeric" pattern="[0-9]{10}" required>
      </div>
      <button type="button" id="btn-send-otp" class="btn-primary-large" onclick="Auth.handleSendOtp()">
        Send OTP
      </button>
    </div>

    <!-- OTP Verification Screen -->
    <div id="otp-screen" class="login-form" style="display: none;">
      <div class="otp-display">
        <div class="otp-phone">OTP sent to <strong id="otp-phone-display"></strong></div>
        <div class="otp-timer" id="otp-timer"></div>
      </div>
      <input type="tel" id="otp-code" class="form-control otp-input" 
             placeholder="000000" maxlength="6" inputmode="numeric" 
             pattern="[0-9]{6}" autocomplete="one-time-code" required>
      <button type="button" id="btn-verify-otp" class="btn-primary-large" onclick="Auth.handleVerifyOtp()">
        Verify OTP
      </button>
      <div class="otp-actions">
        <button type="button" id="btn-resend-otp" class="resend-link" onclick="Auth.resendOtp()">
          Resend OTP
        </button>
      </div>
    </div>

    <!-- Email OTP Screen -->
    <div id="email-input-screen" class="login-form" style="display: none;">
      <div class="phone-input-group">
        <input type="email" id="email-address" class="form-control" 
               placeholder="Enter your email address" required>
      </div>
      <button type="button" id="btn-send-email-otp" class="btn-primary-large" onclick="AuthEmail.handleSendEmailOtp()">
        Send OTP
      </button>
    </div>

    <!-- Email OTP Verification Screen -->
    <div id="email-otp-screen" class="login-form" style="display: none;">
      <div class="otp-display">
        <div class="otp-phone">OTP sent to <strong id="email-otp-display"></strong></div>
        <div class="otp-timer" id="email-otp-timer"></div>
      </div>
      <input type="tel" id="email-otp-code" class="form-control otp-input" 
             placeholder="000000" maxlength="6" inputmode="numeric" 
             pattern="[0-9]{6}" autocomplete="one-time-code" required>
      <button type="button" id="btn-verify-email-otp" class="btn-primary-large" onclick="AuthEmail.handleVerifyEmailOtp()">
        Verify OTP
      </button>
      <div class="otp-actions">
        <button type="button" id="btn-resend-email-otp" class="resend-link" onclick="AuthEmail.resendEmailOtp()">
          Resend OTP
        </button>
      </div>
    </div>

    <!-- Google Login Section -->
    <div id="google-login-section" class="google-login-section" style="display: none;">
      <div id="google-signin-btn"></div>
    </div>
  </div>
</div>

<!-- ONBOARDING SCREEN (shown for new users with no trips) -->
<div id="onboarding-screen" class="onboarding-screen" style="display: none;">
  <div class="onboarding-card">
    <div class="onboarding-icon">👋</div>
    <h2 class="onboarding-title">Welcome, <span id="onboarding-user-name"></span>!</h2>
    <p class="onboarding-subtitle">Start by creating a new trip or joining an existing one</p>
    
    <div class="onboarding-actions">
      <button type="button" class="btn-onboarding btn-onboarding-primary" onclick="More.openCreateTripModal(); Auth.initMainApp();">
        <span style="font-size: 20px;"><i data-lucide="plus" style="width:16px;height:16px;"></i></span>
        Create New Trip
      </button>
      <button type="button" class="btn-onboarding btn-onboarding-secondary" onclick="More.openJoinTripModal(); Auth.initMainApp();">
        <span style="font-size: 20px;"><i data-lucide="link" style="width:16px;height:16px;"></i></span>
        Join Trip by Code
      </button>
      <button type="button" class="btn-onboarding-skip" onclick="Auth.skipOnboarding()">
        Skip — Use CashBook Only
      </button>
    </div>
  </div>
</div>

<!-- TRIPS LIST (shown when user has trips) -->
<div id="trips-list-screen" class="onboarding-screen" style="display: none;">
  <div class="onboarding-card" style="max-height: 80vh; overflow-y: auto;">
    <div class="onboarding-icon">🧳</div>
    <h2 class="onboarding-title">Your Trips</h2>
    <p class="onboarding-subtitle">Select a trip to view expenses, or create a new one</p>

    <div id="trips-list-container" style="margin: 16px 0; display: flex; flex-direction: column; gap: 10px;">
      <!-- Trip cards populated by JS -->
    </div>

    <div class="onboarding-actions">
      <button type="button" class="btn-onboarding btn-onboarding-primary" onclick="Auth.initMainAppForTripsList(); setTimeout(() => More.openCreateTripModal(), 100);">
        <span style="font-size: 20px;"><i data-lucide="plus" style="width:16px;height:16px;"></i></span>
        Create New Trip
      </button>
      <button type="button" class="btn-onboarding btn-onboarding-secondary" onclick="Auth.initMainAppForTripsList(); setTimeout(() => More.openJoinTripModal(), 100);">
        <span style="font-size: 20px;"><i data-lucide="link" style="width:16px;height:16px;"></i></span>
        Join Trip by Code
      </button>
    </div>
  </div>
</div>

<!-- PHONE LINKING SCREEN (shown after Google/Email login if no phone) -->
<div id="phone-link-screen" class="onboarding-screen" style="display: none;">
  <div class="onboarding-card">
    <div class="onboarding-icon"><i data-lucide="smartphone" style="width:48px;height:48px;"></i></div>
    <h2 class="onboarding-title">Link Your Phone</h2>
    <p class="onboarding-subtitle">Your phone number connects you to trip members. It's required to join groups.</p>
    
    <!-- Phone Input -->
    <div id="link-phone-input" style="display: flex; flex-direction: column; gap: 14px; margin-top: 16px;">
      <div class="phone-input-group">
        <span class="phone-prefix">+91</span>
        <input type="tel" id="link-phone-number" class="form-control" 
               placeholder="Enter your phone number" maxlength="10" 
               inputmode="numeric" pattern="[0-9]{10}" required>
      </div>
      <button type="button" id="btn-link-send-otp" class="btn-primary-large" onclick="Auth.handleLinkSendOtp()">
        Send OTP
      </button>
    </div>

    <!-- OTP Input -->
    <div id="link-otp-input" style="display: none; margin-top: 16px;">
      <div class="otp-display">
        <div class="otp-phone">OTP sent to <strong id="link-otp-phone-display"></strong></div>
        <div class="otp-timer" id="link-otp-timer"></div>
      </div>
      <input type="tel" id="link-otp-code" class="form-control otp-input" 
             placeholder="000000" maxlength="6" inputmode="numeric" 
             pattern="[0-9]{6}" autocomplete="one-time-code" required>
      <button type="button" id="btn-link-verify-otp" class="btn-primary-large" onclick="Auth.handleLinkVerifyOtp()">
        Verify & Link
      </button>
      <div class="otp-actions">
        <button type="button" id="btn-link-resend-otp" class="resend-link" onclick="Auth.handleLinkResendOtp()">
          Resend OTP
        </button>
      </div>
    </div>
  </div>
</div>

<!-- MAIN APP (shown when authenticated) -->
<div id="app-content" class="app-container" style="display: <?= $isAuthenticated ? 'flex' : 'none' ?>;">

  <!-- Toast Notification Container -->
  <div class="toast-container" id="toast-container"></div>

  <!-- Left Sidebar (Visible on Desktop) -->
  <aside class="app-sidebar">
    <div class="sidebar-brand">
      <span class="brand-icon">🧳</span>
      <span class="brand-name">TripBook</span>
    </div>
    
    <!-- Trip Selector / Info -->
    <div class="sidebar-trip-info" onclick="App.showTripsList()" title="Switch Trip">
      <div class="trip-info-mini">
        <span class="sidebar-trip-name" id="sidebar-trip-name">TripBook</span>
        <span class="sidebar-trip-code" id="sidebar-trip-code"></span>
      </div>
      <i data-lucide="chevrons-up-down" style="width:16px;height:16px;color:var(--text-muted);"></i>
    </div>
    
    <nav class="sidebar-nav">
      <button class="sidebar-nav-item active" data-tab="home">
        <i data-lucide="layout-dashboard" style="width:18px;height:18px;"></i>
        <span>Overview</span>
      </button>
      <button class="sidebar-nav-item" data-tab="history">
        <i data-lucide="arrow-left-right" style="width:18px;height:18px;"></i>
        <span>Transactions</span>
      </button>
      <button class="sidebar-nav-item" data-tab="people">
        <i data-lucide="users" style="width:18px;height:18px;"></i>
        <span>People</span>
      </button>
      <button class="sidebar-nav-item" data-tab="settle">
        <i data-lucide="zap" style="width:18px;height:18px;"></i>
        <span>Settlements</span>
      </button>
      <button class="sidebar-nav-item" data-tab="more">
        <i data-lucide="settings" style="width:18px;height:18px;"></i>
        <span>Settings</span>
      </button>
    </nav>
    
    <div class="sidebar-footer">
      <button class="sidebar-user-btn" onclick="Profile.open()" title="My Profile">
        <div class="avatar-circle" id="sidebar-user-avatar">H</div>
        <div class="user-meta-mini">
          <span class="sidebar-username" id="sidebar-user-name-display">Het D</span>
          <span class="sidebar-user-role">Member</span>
        </div>
      </button>
      <button class="theme-toggle-btn" onclick="console.log('[Theme Button] Sidebar button clicked'); App.toggleTheme()" title="Toggle Dark/Light Mode">
        <i data-lucide="sun" class="sun-icon" style="width:16px;height:16px;"></i>
        <i data-lucide="moon" class="moon-icon" style="width:16px;height:16px;"></i>
      </button>
    </div>
  </aside>

  <!-- Main Scrollable Content Area and Header Wrapper -->
  <div class="main-wrapper">
    <!-- Top App Header -->
    <header class="app-header">
      <div class="header-left">
        <button class="btn-back-trips" onclick="App.showTripsList()" title="Back to all trips" style="background:none; border:none; padding:4px; cursor:pointer; display:flex; align-items:center; margin-right:4px;">
          <i data-lucide="chevron-left" style="width:20px; height:20px; color:var(--text-muted);"></i>
        </button>
        <div class="trip-badge">
          <span class="trip-title" id="header-trip-name"></span>
          <span class="trip-code-pill" id="header-trip-code" onclick="App.showTripsList()">
            <i data-lucide="list" style="width:11px;height:11px;"></i>
          </span>
        </div>
      </div>
      <div class="header-right">
        <div class="sync-status-dot" id="sync-dot" title="Live Auto-Sync Active"></div>
        <button onclick="Notifications.open()" style="background:none; border:none; padding:4px; cursor:pointer; position:relative; display:flex; align-items:center; justify-content:center;">
          <i data-lucide="bell" style="width:20px; height:20px; color:var(--text-muted);"></i>
          <span id="notif-badge" style="display:none; position:absolute; top:0; right:0; width:8px; height:8px; background:var(--danger); border-radius:50%; border:2px solid var(--bg-surface);"></span>
        </button>
        <button class="theme-toggle-btn mobile-theme-btn" onclick="console.log('[Theme Button] Mobile header button clicked'); App.toggleTheme()" title="Toggle Dark/Light Mode" style="background:none; border:none; padding:4px; cursor:pointer; display:flex; align-items:center; justify-content:center;">
          <i data-lucide="sun" class="sun-icon" style="width:20px; height:20px; color:var(--text-muted);"></i>
          <i data-lucide="moon" class="moon-icon" style="width:20px; height:20px; color:var(--text-muted);"></i>
        </button>
        <button class="user-avatar-btn" onclick="Profile.open()" title="My Profile">
          <div class="avatar-circle" id="header-user-avatar"></div>
          <span id="header-user-name"></span>
          <i data-lucide="chevron-down" style="width:14px;height:14px;color:var(--text-muted);"></i>
        </button>
      </div>
    </header>

    <!-- Main Scrollable Content Area -->
    <main class="app-content">
      <div id="tab-content" style="display:flex; flex-direction:column; gap:14px;"></div>
    </main>

    <!-- Floating Action Button (+ Expense) -->
    <div class="fab-container">
      <button class="fab-main-btn" onclick="Expenses.openAddModal()" title="Add Expense">
        <i data-lucide="plus" style="width:28px;height:28px;"></i>
      </button>
    </div>

    <!-- Sticky Mobile Bottom Navigation -->
    <nav class="bottom-nav">
      <button class="nav-item active" data-tab="home">
        <i data-lucide="home"></i>
        <span>Home</span>
      </button>
      <button class="nav-item" data-tab="history">
        <i data-lucide="arrow-left-right"></i>
        <span>History</span>
      </button>
      <button class="nav-item" data-tab="people">
        <i data-lucide="users"></i>
        <span>People</span>
      </button>
      <button class="nav-item" data-tab="settle">
        <i data-lucide="zap"></i>
        <span>Settle</span>
      </button>
      <button class="nav-item" data-tab="more">
        <i data-lucide="menu"></i>
        <span>More</span>
      </button>
    </nav>
  </div>


  <!-- MODALS & BOTTOM SHEETS -->

  <!-- 1. Add / Edit Expense Bottom Sheet -->
  <div class="modal-overlay" id="modal-expense-sheet">
    <div class="bottom-sheet">
      <div class="sheet-handle"></div>
      <div class="sheet-header">
        <h3 class="sheet-title" id="expense-sheet-title">Add Expense</h3>
        <button class="btn-close-sheet" onclick="UI.closeModal('modal-expense-sheet')">✕</button>
      </div>

      <form id="form-add-expense" style="display:flex; flex-direction:column; gap:14px;">
        <input type="hidden" id="expense-id">

        <!-- Expense Type Toggle -->
        <div class="form-group">
          <label class="form-label">Expense Type</label>
          <div class="segmented-control">
            <button type="button" class="segmented-btn expense-type-btn active" data-type="personal">Personal</button>
            <button type="button" class="segmented-btn expense-type-btn" data-type="shared">Shared with Trip</button>
          </div>
        </div>

        <!-- Amount -->
        <div class="form-group">
          <label class="form-label">Expense Amount</label>
          <div class="amount-input-box">
            <span class="amount-currency">₹</span>
            <input type="number" step="0.01" inputmode="decimal" class="form-control amount-input-hero" id="expense-amount" placeholder="0.00" required>
          </div>
        </div>

        <!-- Description -->
        <div class="form-group">
          <label class="form-label">Description</label>
          <input type="text" class="form-control" id="expense-desc" placeholder="e.g. Dinner, Auto, Tickets" required>
        </div>

        <!-- Payment Method -->
        <div class="form-group">
          <label class="form-label">Payment Method</label>
          <div class="payment-pills-row">
            <button type="button" class="pay-pill-btn expense-pay-pill active" data-method="cash"><i data-lucide="banknote" style="width:14px;height:14px;"></i> Cash</button>
            <button type="button" class="pay-pill-btn expense-pay-pill" data-method="bank"><i data-lucide="building" style="width:14px;height:14px;"></i> Bank</button>
          </div>
        </div>

        <!-- Paid By & Category -->
        <div style="display:grid; grid-template-columns:1fr 1fr; gap:10px;">
          <div class="form-group">
            <label class="form-label">Paid By</label>
            <select class="form-control" id="expense-payer"></select>
          </div>
          <div class="form-group">
            <label class="form-label">Category</label>
            <div style="display:flex; gap:6px; align-items:center;">
              <select class="form-control" id="expense-category" style="flex:1;"></select>
              <button type="button" class="btn-settle-action" onclick="Expenses.openAddCategoryModal()" style="padding:8px 12px; font-size:12px; white-space:nowrap;">+ New</button>
            </div>
          </div>
        </div>

        <!-- Split Options (only for shared expenses) -->
        <div class="form-group" id="expense-split-group">
          <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:4px;">
            <label class="form-label" style="margin-bottom:0;">Split Mode</label>
            <div class="segmented-control" style="width:160px; padding:2px;">
              <button type="button" class="segmented-btn split-type-btn active" data-type="equal">Equal</button>
              <button type="button" class="segmented-btn split-type-btn" data-type="custom">Custom</button>
            </div>
          </div>

          <div class="splits-card">
            <div id="split-members-list"></div>
            <div class="split-status-bar warning" id="split-status-bar">
              <span>Enter amount above</span>
            </div>
          </div>
        </div>

        <!-- Optional Notes -->
        <div class="form-group">
          <label class="form-label">Notes (Optional)</label>
          <input type="text" class="form-control" id="expense-notes" placeholder="Additional notes...">
        </div>

        <button type="submit" class="btn-primary-large" id="btn-save-expense">
          Save Expense
        </button>
      </form>
    </div>
  </div>

  <!-- 2. Add Money to Pool Bottom Sheet -->
  <div class="modal-overlay" id="modal-add-money">
    <div class="bottom-sheet">
      <div class="sheet-handle"></div>
      <div class="sheet-header">
        <h3 class="sheet-title">Add Money to Pool</h3>
        <button class="btn-close-sheet" onclick="UI.closeModal('modal-add-money')">✕</button>
      </div>

      <form id="form-add-money" style="display:flex; flex-direction:column; gap:14px;">
        <div class="form-group">
          <label class="form-label">Amount</label>
          <div class="amount-input-box">
            <span class="amount-currency">₹</span>
            <input type="number" step="0.01" inputmode="decimal" class="form-control amount-input-hero" id="add-money-amount" placeholder="2,000" required>
          </div>
        </div>

        <div class="form-group">
          <label class="form-label">Payment Method</label>
          <select class="form-control" id="add-money-method">
            <option value="cash">Cash</option>
            <option value="bank">Bank Transfer</option>
          </select>
        </div>

        <div class="form-group">
          <label class="form-label">Notes</label>
          <input type="text" class="form-control" id="add-money-notes" placeholder="e.g. Additional trip cash pool collection">
        </div>

        <button type="submit" class="btn-primary-large" style="background:var(--success);">
          + Add to Shared Pool
        </button>
      </form>
    </div>
  </div>

  <!-- 3. Settle Up Modal -->
  <div class="modal-overlay" id="modal-settle-up">
    <div class="bottom-sheet">
      <div class="sheet-handle"></div>
      <div class="sheet-header">
        <h3 class="sheet-title">Record Settlement Payment</h3>
        <button class="btn-close-sheet" onclick="UI.closeModal('modal-settle-up')">✕</button>
      </div>

      <div style="font-size:14px; color:var(--text-muted); margin-bottom:6px;" id="settle-modal-subtitle"></div>

      <form id="form-settle-up" style="display:flex; flex-direction:column; gap:14px;">
        <input type="hidden" id="settle-from-user">
        <input type="hidden" id="settle-to-user">

        <div class="form-group">
          <label class="form-label">Amount Paid</label>
          <div class="amount-input-box">
            <span class="amount-currency">₹</span>
            <input type="number" step="0.01" inputmode="decimal" class="form-control amount-input-hero" id="settle-amount" required>
          </div>
        </div>

        <div class="form-group">
          <label class="form-label">Payment Method Used</label>
          <select class="form-control" id="settle-method">
            <option value="cash">Cash</option>
            <option value="bank">Bank Transfer</option>
          </select>
        </div>

        <div class="form-group">
          <label class="form-label">Notes (Optional)</label>
          <input type="text" class="form-control" id="settle-notes" placeholder="e.g. Cleared dinner & train split debt">
        </div>

        <button type="submit" class="btn-primary-large">
          ✓ Mark Debt as Paid
        </button>
      </form>
    </div>
  </div>

  <!-- 4. Add Member Modal -->
  <div class="modal-overlay" id="modal-add-member">
    <div class="bottom-sheet">
      <div class="sheet-handle"></div>
      <div class="sheet-header">
        <h3 class="sheet-title">Add Trip Member</h3>
        <button class="btn-close-sheet" onclick="UI.closeModal('modal-add-member')">✕</button>
      </div>

      <form id="form-add-member" style="display:flex; flex-direction:column; gap:14px;">
        <div class="form-group">
          <label class="form-label">Member Name</label>
          <input type="text" class="form-control" id="new-member-name" placeholder="e.g. Yash, Priyansh" required>
        </div>
        <div class="form-group">
          <label class="form-label">Email (Optional)</label>
          <input type="email" class="form-control" id="new-member-email" placeholder="yash@example.com">
        </div>
        <div class="form-group">
          <label class="form-label">Phone (Optional)</label>
          <input type="tel" class="form-control" id="new-member-phone" placeholder="+91 98765 43210">
        </div>

        <button type="submit" class="btn-primary-large">
          Add Member
        </button>
      </form>
    </div>
  </div>

  <!-- 4b. Add Category Modal -->
  <div class="modal-overlay" id="modal-add-category">
    <div class="bottom-sheet">
      <div class="sheet-handle"></div>
      <div class="sheet-header">
        <h3 class="sheet-title">Add Custom Category</h3>
        <button class="btn-close-sheet" onclick="UI.closeModal('modal-add-category')">✕</button>
      </div>

      <form id="form-add-category" style="display:flex; flex-direction:column; gap:14px;">
        <div class="form-group">
          <label class="form-label">Category Name</label>
          <input type="text" class="form-control" id="new-category-name" placeholder="e.g. Tolls, Tips" required>
        </div>
        <div class="form-group">
          <label class="form-label">Icon (emoji)</label>
          <input type="text" class="form-control" id="new-category-icon" placeholder="e.g. 🛣️" value="📁" maxlength="4">
        </div>
        <div class="form-group">
          <label class="form-label">Color</label>
          <input type="color" class="form-control" id="new-category-color" value="#6366f1" style="height:44px; padding:4px;">
        </div>

        <button type="submit" class="btn-primary-large">
          Add Category
        </button>
      </form>
    </div>
  </div>

  <!-- 5. Create Trip Modal -->
  <div class="modal-overlay" id="modal-create-trip">
    <div class="bottom-sheet">
      <div class="sheet-handle"></div>
      <div class="sheet-header">
        <h3 class="sheet-title">Create New Trip</h3>
        <button class="btn-close-sheet" onclick="UI.closeModal('modal-create-trip')">✕</button>
      </div>

      <form id="form-create-trip" style="display:flex; flex-direction:column; gap:14px;">
        <div class="form-group">
          <label class="form-label">Trip Name</label>
          <input type="text" class="form-control" id="new-trip-name" placeholder="e.g. Goa Trip, Manali Weekend" required>
        </div>
        <div class="form-group">
          <label class="form-label">Currency Symbol</label>
          <input type="text" class="form-control" id="new-trip-currency" placeholder="₹" value="₹" maxlength="3">
        </div>

        <button type="submit" class="btn-primary-large">
          Create Trip
        </button>
      </form>
    </div>
  </div>

  <!-- 6. Join Trip Modal -->
  <div class="modal-overlay" id="modal-join-trip">
    <div class="bottom-sheet">
      <div class="sheet-handle"></div>
      <div class="sheet-header">
        <h3 class="sheet-title">Join Trip by Code</h3>
        <button class="btn-close-sheet" onclick="UI.closeModal('modal-join-trip')">✕</button>
      </div>

      <form id="form-join-trip" style="display:flex; flex-direction:column; gap:14px;">
        <div class="form-group">
          <label class="form-label">Trip Invite Code</label>
          <input type="text" class="form-control" id="join-trip-code" placeholder="e.g. TRIP-7F82K" required style="text-transform:uppercase; letter-spacing:1px; font-weight:700;">
        </div>

        <button type="submit" class="btn-primary-large">
          Join Trip
        </button>
      </form>
    </div>
  </div>

  <!-- 7. Profile Modal -->
  <div class="modal-overlay" id="modal-profile">
    <div class="bottom-sheet bottom-sheet-large">
      <div class="sheet-handle"></div>
      <div class="sheet-header">
        <h3 class="sheet-title">My Profile</h3>
        <button class="btn-close-sheet" onclick="UI.closeModal('modal-profile')">✕</button>
      </div>
      <div id="profile-content" style="display:flex; flex-direction:column; gap:16px;"></div>
    </div>
  </div>

  <!-- 8. Add Cash/Income Modal -->
  <div class="modal-overlay" id="modal-add-cash">
    <div class="bottom-sheet">
      <div class="sheet-handle"></div>
      <div class="sheet-header">
        <h3 class="sheet-title">Add Income</h3>
        <button class="btn-close-sheet" onclick="UI.closeModal('modal-add-cash')">✕</button>
      </div>
      <form id="form-add-cash" style="display:flex; flex-direction:column; gap:14px;">
        <input type="hidden" id="add-cash-type" value="income">
        <div class="form-group">
          <label class="form-label">Amount</label>
          <div class="amount-input-box">
            <span class="amount-currency">₹</span>
            <input type="number" step="0.01" inputmode="decimal" class="form-control amount-input-hero" id="add-cash-amount" placeholder="0.00" min="0.01" required>
          </div>
        </div>
        <div class="form-group">
          <label class="form-label">Description</label>
          <input type="text" class="form-control" id="add-cash-desc" placeholder="e.g. Salary, Petty cash, Refund" required>
        </div>
        <div class="form-group">
          <label class="form-label">Payment Method</label>
          <select class="form-control" id="add-cash-method">
            <option value="cash">Cash</option>
            <option value="bank">Bank Transfer</option>
          </select>
        </div>
        <button type="submit" class="btn-primary-large" style="background:var(--success);">
          + Add to CashBook
        </button>
      </form>
    </div>
  </div>

  <!-- 9. Trip Settings Modal -->
  <div class="modal-overlay" id="modal-trip-settings">
    <div class="bottom-sheet bottom-sheet-large">
      <div class="sheet-handle"></div>
      <div class="sheet-header">
        <h3 class="sheet-title">Trip Settings</h3>
        <button class="btn-close-sheet" onclick="UI.closeModal('modal-trip-settings')">✕</button>
      </div>

      <form id="form-trip-settings" style="display:flex; flex-direction:column; gap:14px;">
        <div class="form-group">
          <label class="form-label">Trip Name</label>
          <input type="text" class="form-control" id="settings-trip-name" required>
        </div>
        <div class="form-group">
          <label class="form-label">Currency Symbol</label>
          <input type="text" class="form-control" id="settings-trip-currency" maxlength="3">
        </div>
        <div class="form-group">
          <label class="form-label">Description</label>
          <textarea class="form-control" id="settings-trip-desc" rows="2" placeholder="Optional trip notes"></textarea>
        </div>

        <div style="border-top:1px solid var(--border); padding-top:14px; margin-top:4px;">
          <div style="font-size:12px; font-weight:700; color:var(--text-muted); text-transform:uppercase; margin-bottom:10px;">Danger Zone</div>
          <button type="button" class="btn-primary-large" style="background:var(--danger); width:100%;" onclick="More.deleteTrip()">
            <i data-lucide="trash-2" style="width:16px; height:16px;"></i> Delete This Trip
          </button>
        </div>

        <button type="submit" class="btn-primary-large">
          Save Settings
        </button>
      </form>
    </div>
  </div>

  <!-- 10. Notifications Panel -->
  <div class="modal-overlay" id="modal-notifications">
    <div class="bottom-sheet bottom-sheet-large">
      <div class="sheet-handle"></div>
      <div class="sheet-header">
        <h3 class="sheet-title">Notifications</h3>
        <button class="btn-close-sheet" onclick="UI.closeModal('modal-notifications')">✕</button>
      </div>
      <div id="notifications-list" style="max-height:60vh; overflow-y:auto;"></div>
    </div>
  </div>

  <!-- 8. Transaction Details Modal -->
  <div class="modal-overlay" id="modal-tx-details">
    <div class="bottom-sheet">
      <div class="sheet-handle"></div>
      <div class="sheet-header">
        <h3 class="sheet-title">Transaction Details</h3>
        <button class="btn-close-sheet" onclick="UI.closeModal('modal-tx-details')">✕</button>
      </div>
      <div id="tx-details-body"></div>
    </div>
  </div>

  <!-- 9. Personal CashBook Ledger Modal -->
  <div class="modal-overlay" id="modal-cashbook-ledger">
    <div class="bottom-sheet">
      <div class="sheet-handle"></div>
      <div class="sheet-header">
        <h3 class="sheet-title" id="cashbook-modal-title">Personal CashBook Ledger</h3>
        <button class="btn-close-sheet" onclick="UI.closeModal('modal-cashbook-ledger')">✕</button>
      </div>
      <div id="cashbook-details-body"></div>
    </div>
  </div>

  <!-- 10. CashBook Modal (All Expenses) -->
  <div class="modal-overlay" id="modal-cashbook">
    <div class="bottom-sheet bottom-sheet-large">
      <div class="sheet-handle"></div>
      <div class="sheet-header">
        <h3 class="sheet-title">My CashBook</h3>
        <button class="btn-close-sheet" onclick="UI.closeModal('modal-cashbook')">✕</button>
      </div>
      <div id="cashbook-list" style="max-height: 70vh; overflow-y: auto;"></div>
    </div>
  </div>

  <!-- 11. Passbook Modal (Bank Statement View) -->
  <div class="modal-overlay" id="modal-passbook">
    <div class="bottom-sheet bottom-sheet-large">
      <div class="sheet-handle"></div>
      <div class="sheet-header">
        <h3 class="sheet-title">Passbook</h3>
        <button class="btn-close-sheet" onclick="UI.closeModal('modal-passbook')">✕</button>
      </div>
      <div id="passbook-list" style="max-height: 70vh; overflow-y: auto;"></div>
    </div>
  </div>

</div>

<!-- Scripts -->
<script src="assets/js/api.js?v=<?= time() ?>"></script>
<script src="assets/js/auth.js?v=<?= time() ?>"></script>
<script src="assets/js/auth-email.js?v=<?= time() ?>"></script>
<script src="assets/js/profile.js?v=<?= time() ?>"></script>
<script src="assets/js/dashboard.js?v=<?= time() ?>"></script>
<script src="assets/js/expenses.js?v=<?= time() ?>"></script>
<script src="assets/js/transactions.js?v=<?= time() ?>"></script>
<script src="assets/js/settlements.js?v=<?= time() ?>"></script>
<script src="assets/js/people.js?v=<?= time() ?>"></script>
<script src="assets/js/more.js?v=<?= time() ?>"></script>
<script src="assets/js/cashbook.js?v=<?= time() ?>"></script>
<script src="assets/js/passbook.js?v=<?= time() ?>"></script>
<script src="assets/js/notifications.js?v=<?= time() ?>"></script>
<script src="assets/js/app.js?v=<?= time() ?>"></script>

<script>
  document.addEventListener('DOMContentLoaded', () => {
    if (window.App && typeof App.initTheme === 'function') {
      App.initTheme();
    }
    Auth.init();
    
    const addCashForm = document.getElementById('form-add-cash');
    if (addCashForm) {
      addCashForm.addEventListener('submit', (e) => {
        e.preventDefault();
        CashBook.handleAddCash(e);
      });
    }

    const addMoneyForm = document.getElementById('form-add-money');
    if (addMoneyForm) {
      addMoneyForm.addEventListener('submit', (e) => {
        e.preventDefault();
        Transactions.handleAddMoney(e);
      });
    }
    
    <?php if ($isAuthenticated): ?>
    <?php if ($activeTripId): ?>
    <?php
    $tripTokenStmt = $db->prepare("SELECT url_token FROM trips WHERE id = ?");
    $tripTokenStmt->execute([$activeTripId]);
    $tripTokenRow = $tripTokenStmt->fetch();
    $activeTripToken = $tripTokenRow ? ($tripTokenRow['url_token'] ?? '') : '';
    ?>
    App.init('<?= e($csrfToken) ?>', <?= (int)$activeTripId ?>, '<?= e($activeTripToken) ?>');
    <?php else: ?>
    Auth.authData = { csrf_token: '<?= e($csrfToken) ?>', user: <?= json_encode($currentUser) ?>, trips: [] };
    Auth.showTripsList([]);
    API.init('<?= e($csrfToken) ?>', 0);
    API.get('api/auth.php').then(res => {
      Auth.authData.trips = res.data.trips || [];
      Auth.showTripsList(Auth.authData.trips);
    }).catch(() => {});
    <?php endif; ?>
    
    <?php if ($pendingTripCode): ?>
    setTimeout(() => {
      API.post('api/trips.php?action=join', { trip_code: '<?= e($pendingTripCode) ?>' })
        .then(res => {
          if (res.success) {
            UI.showToast(res.message, 'success');
            window.location.href = '?trip=' + res.data.url_token;
          }
        })
        .catch(err => {});
    }, 1000);
    <?php endif; ?>
    
    <?php endif; ?>
  });
</script>

</body>
</html>
