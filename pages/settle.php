<?php
declare(strict_types=1);
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/auth.php';

if (!isAuthenticated()) { http_response_code(401); exit; }
?>
<div id="settlements-tab-suggestions"></div>
<div id="settlements-tab-history"></div>
