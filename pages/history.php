<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/auth.php';

if (!isAuthenticated()) { http_response_code(401); exit; }
?>
<div class="card" style="padding:14px;">
  <input type="text" id="tx-search-input" class="form-control" placeholder="🔍 Search expenses or notes...">

  <div style="display:flex; gap:6px; margin-top:10px; overflow-x:auto; padding-bottom:4px;">
    <button class="segmented-btn tx-filter-chip active" onclick="Transactions.setFilter('all', this)">All</button>
    <button class="segmented-btn tx-filter-chip" onclick="Transactions.setFilter('expense', this)">Expenses</button>
    <button class="segmented-btn tx-filter-chip" onclick="Transactions.setFilter('income', this)">Pool Cash</button>
    <button class="segmented-btn tx-filter-chip" onclick="Transactions.setFilter('settlement', this)">Settlements</button>
  </div>
</div>

<div class="tx-list" id="transactions-full-list"></div>
