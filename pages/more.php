<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/auth.php';

if (!isAuthenticated()) { http_response_code(401); exit; }
$db = getDBConnection();
$currentUser = getCurrentUser();
$tripId = (int)($_GET['trip_id'] ?? getActiveTripId());
$tripStmt = $db->prepare("SELECT name, trip_code FROM trips WHERE id = ?");
$tripStmt->execute([$tripId]);
$trip = $tripStmt->fetch();
?>
<div class="card" style="padding:24px 20px; text-align:center; background: linear-gradient(135deg, rgba(91, 92, 255, 0.05), rgba(217, 70, 239, 0.05)); border: 1px solid var(--border);">
  <div style="font-size:44px; margin-bottom:12px;">🧳</div>
  <h2 style="font-size:20px; font-weight:800; color:var(--text-primary);" id="more-trip-name"><?= e($trip['name'] ?? '') ?></h2>
  <div style="font-size:13px; color:var(--text-secondary); margin-top:4px;">
    Trip Code: <strong id="more-trip-code" style="color:var(--primary); font-size:14px; letter-spacing:0.5px;"><?= e($trip['trip_code'] ?? '') ?></strong>
  </div>
  <div style="margin-top:16px; display:flex; gap:10px; justify-content:center;">
    <button class="btn-settle-action" onclick="App.shareTrip()">
      <i data-lucide="share-2" style="width:14px;height:14px;"></i> Share Invite
    </button>
    <button class="btn-settle-action" style="background:rgba(255,255,255,0.02); border:1px solid var(--border); color:var(--text-primary);" onclick="More.exportCSV()">
      <i data-lucide="download" style="width:14px;height:14px;"></i> CSV
    </button>
    <button class="btn-settle-action" style="background:rgba(255,255,255,0.02); border:1px solid var(--border); color:var(--text-primary);" onclick="More.exportPDF()">
      <i data-lucide="file-text" style="width:14px;height:14px;"></i> PDF
    </button>
  </div>
</div>

<div class="card" style="padding:16px;">
  <div style="font-size:11px; font-weight:800; color:var(--text-secondary); text-transform:uppercase; letter-spacing:0.5px; margin-bottom:12px;">Quick Trip Actions</div>
  <div style="display:flex; flex-direction:column; gap:8px;">
    <button class="tx-item" style="width:100%; border:none; text-align:left; background:transparent;" onclick="Profile.open()">
      <div class="tx-left">
        <div class="tx-icon-box" style="background:rgba(91,92,255,0.1); color:#8b5cf6; border:1px solid rgba(91,92,255,0.15);"><i data-lucide="user"></i></div>
        <div class="tx-details">
          <span class="tx-title" style="color:var(--text-primary); font-weight:700;">My Profile</span>
          <span class="tx-meta" style="color:var(--text-secondary);">View and edit your profile details</span>
        </div>
      </div>
      <i data-lucide="chevron-right" style="color:var(--text-secondary); width:16px; height:16px;"></i>
    </button>

    <button class="tx-item" style="width:100%; border:none; text-align:left; background:transparent;" onclick="More.openCreateTripModal()">
      <div class="tx-left">
        <div class="tx-icon-box" style="background:rgba(16,185,129,0.1); color:#10b981; border:1px solid rgba(16,185,129,0.15);"><i data-lucide="plus-circle"></i></div>
        <div class="tx-details">
          <span class="tx-title" style="color:var(--text-primary); font-weight:700;">Create New Trip</span>
          <span class="tx-meta" style="color:var(--text-secondary);">Start tracking another vacation group</span>
        </div>
      </div>
      <i data-lucide="chevron-right" style="color:var(--text-secondary); width:16px; height:16px;"></i>
    </button>

    <button class="tx-item" style="width:100%; border:none; text-align:left; background:transparent;" onclick="More.openJoinTripModal()">
      <div class="tx-left">
        <div class="tx-icon-box" style="background:rgba(217,70,239,0.1); color:#d946ef; border:1px solid rgba(217,70,239,0.15);"><i data-lucide="log-in"></i></div>
        <div class="tx-details">
          <span class="tx-title" style="color:var(--text-primary); font-weight:700;">Join Existing Trip</span>
          <span class="tx-meta" style="color:var(--text-secondary);">Enter a shared code to join trip</span>
        </div>
      </div>
      <i data-lucide="chevron-right" style="color:var(--text-secondary); width:16px; height:16px;"></i>
    </button>

    <button class="tx-item" style="width:100%; border:none; text-align:left; background:transparent;" onclick="More.openTripSettings()">
      <div class="tx-left">
        <div class="tx-icon-box" style="background:rgba(255,255,255,0.03); color:#94a3b8; border:1px solid var(--border);"><i data-lucide="settings"></i></div>
        <div class="tx-details">
          <span class="tx-title" style="color:var(--text-primary); font-weight:700;">Trip Settings</span>
          <span class="tx-meta" style="color:var(--text-secondary);">Edit name, currency, description</span>
        </div>
      </div>
      <i data-lucide="chevron-right" style="color:var(--text-secondary); width:16px; height:16px;"></i>
    </button>

    <button class="tx-item" style="width:100%; border:none; text-align:left; background:transparent;" onclick="More.deleteTrip()">
      <div class="tx-left">
        <div class="tx-icon-box" style="background:rgba(239,68,68,0.1); color:#ef4444; border:1px solid rgba(239,68,68,0.15);"><i data-lucide="trash-2"></i></div>
        <div class="tx-details">
          <span class="tx-title" style="color:var(--text-primary); font-weight:700;">Delete This Trip</span>
          <span class="tx-meta" style="color:var(--text-secondary);">Permanently remove trip and all data</span>
        </div>
      </div>
      <i data-lucide="chevron-right" style="color:var(--text-secondary); width:16px; height:16px;"></i>
    </button>

    <button class="tx-item" style="width:100%; border:none; text-align:left; background:transparent;" onclick="More.deleteAccount()">
      <div class="tx-left">
        <div class="tx-icon-box" style="background:rgba(239,68,68,0.1); color:#ef4444; border:1px solid rgba(239,68,68,0.15);"><i data-lucide="user-x"></i></div>
        <div class="tx-details">
          <span class="tx-title" style="color:var(--text-primary); font-weight:700;">Delete Account</span>
          <span class="tx-meta" style="color:var(--text-secondary);">Permanently delete your profile account</span>
        </div>
      </div>
      <i data-lucide="chevron-right" style="color:var(--text-secondary); width:16px; height:16px;"></i>
    </button>

    <button class="tx-item" style="width:100%; border:none; text-align:left; background:transparent;" onclick="Auth.logout()">
      <div class="tx-left">
        <div class="tx-icon-box" style="background:rgba(239,68,68,0.1); color:#ef4444; border:1px solid rgba(239,68,68,0.15);"><i data-lucide="log-out"></i></div>
        <div class="tx-details">
          <span class="tx-title" style="color:var(--text-primary); font-weight:700;">Logout</span>
          <span class="tx-meta" style="color:var(--text-secondary);">Sign out of your profile</span>
        </div>
      </div>
      <i data-lucide="chevron-right" style="color:var(--text-secondary); width:16px; height:16px;"></i>
    </button>
  </div>
</div>
