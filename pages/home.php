<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/auth.php';

if (!isAuthenticated()) { http_response_code(401); exit; }
$db = getDBConnection();
$currentUser = getCurrentUser();
$tripId = (int)($_GET['trip_id'] ?? getActiveTripId());
$membership = requireTripMembership($tripId, (int)$currentUser['id']);
$currency = $membership['currency_symbol'] ?? '₹';
?>
<div id="dashboard-hero-money"></div>

<div class="quick-actions-row">
  <button class="btn-quick" onclick="Expenses.openAddModal()">
    <span class="btn-quick-icon"><i data-lucide="plus" style="width:16px;height:16px;"></i></span>
    <span>Expense</span>
  </button>
  <button class="btn-quick" onclick="CashBook.openAddCash()">
    <span class="btn-quick-icon"><i data-lucide="banknote" style="width:16px;height:16px;"></i></span>
    <span>Add Income</span>
  </button>
  <button class="btn-quick" onclick="CashBook.openModal()">
    <span class="btn-quick-icon"><i data-lucide="folder" style="width:16px;height:16px;"></i></span>
    <span>CashBook</span>
  </button>
  <button class="btn-quick" onclick="Passbook.openModal()">
    <span class="btn-quick-icon"><i data-lucide="book" style="width:16px;height:16px;"></i></span>
    <span>Passbook</span>
  </button>
    <button class="btn-quick" onclick="App.switchTab('settle')">
    <span class="btn-quick-icon"><i data-lucide="zap" style="width:16px;height:16px;"></i></span>
    <span>Settle Up</span>
  </button>
</div>

<div id="dashboard-category-spending"></div>
<div id="dashboard-settlements"></div>
<div id="dashboard-member-balances"></div>
<div id="dashboard-recent-transactions"></div>
