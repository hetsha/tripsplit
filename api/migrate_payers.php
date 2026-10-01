<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';

ensureTransactionPayersTable();
echo json_encode(['success' => true, 'message' => 'transaction_payers table ready']);
