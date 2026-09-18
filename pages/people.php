<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/auth.php';

if (!isAuthenticated()) { http_response_code(401); exit; }
?>
<div style="display:flex; justify-content:space-between; align-items:center;">
  <h2 style="font-size:18px; font-weight:800;">Trip Members</h2>
  <button class="btn-settle-action" onclick="People.openAddMemberModal()">
    <i data-lucide="user-plus" style="width:14px;height:14px;"></i> + Add Member
  </button>
</div>
<div id="people-members-list"></div>
