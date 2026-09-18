<?php
/**
 * TripBook Database Installer & Auto-Seeder
 * Run this once via browser or CLI to create the MySQL database and sample data.
 */

declare(strict_types=1);

require_once __DIR__ . '/config/database.php';

$message = '';
$status = '';
$logs = [];

if (($_SERVER['REQUEST_METHOD'] ?? '') === 'POST' || PHP_SAPI === 'cli' || isset($_GET['auto'])) {
    try {
        $serverPdo = getServerConnection();
        $dbName = DB_NAME;

        // 1. Create Database if not exists
        $serverPdo->exec("CREATE DATABASE IF NOT EXISTS `{$dbName}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
        $logs[] = "✓ Database `{$dbName}` ready.";

        // 2. Connect to the database
        $appPdo = getDBConnection();

        // 3. Execute schema.sql
        $schemaSql = file_get_contents(__DIR__ . '/sql/schema.sql');
        if (!$schemaSql) {
            throw new Exception("schema.sql not found");
        }
        $appPdo->exec($schemaSql);
        $logs[] = "✓ Schema tables created successfully.";

        // 4. Execute seed.sql
        $seedSql = file_get_contents(__DIR__ . '/sql/seed.sql');
        if (!$seedSql) {
            throw new Exception("seed.sql not found");
        }
        $appPdo->exec($seedSql);
        $logs[] = "✓ Seed data loaded (sample users, trip, and transactions).";

        // 5. Execute auth migration (safe for existing installations)
        $migrationFile = __DIR__ . '/sql/migration_auth.sql';
        if (file_exists($migrationFile)) {
            $migrationSql = file_get_contents($migrationFile);
            // Split by semicolons and execute each statement
            $statements = array_filter(array_map('trim', explode(';', $migrationSql)));
            foreach ($statements as $stmt) {
                if (!empty($stmt) && $stmt !== '--') {
                    try {
                        $appPdo->exec($stmt);
                    } catch (PDOException $e) {
                        // Ignore duplicate column/table errors (already migrated)
                        if ($e->getCode() != '42S21' && $e->getCode() != '42S02') {
                            $logs[] = "⚠ Migration note: " . $e->getMessage();
                        }
                    }
                }
            }
            $logs[] = "✓ Auth migration applied (Google, Email OTP, Auth settings).";
        }

        $status = 'success';
        $message = "TripBook Database initialized successfully!";

        if (PHP_SAPI === 'cli') {
            echo implode("\n", $logs) . "\n" . $message . "\n";
            exit(0);
        }

        if (isset($_GET['auto'])) {
            header('Location: index.php?installed=1');
            exit;
        }
    } catch (Throwable $e) {
        $status = 'error';
        $message = "Installation failed: " . $e->getMessage();
        $logs[] = "✗ Error: " . $e->getMessage();
        if (PHP_SAPI === 'cli') {
            echo $message . "\n";
            exit(1);
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TripBook - Database Setup</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary: #2563eb;
            --primary-hover: #1d4ed8;
            --bg: #f8fafc;
            --card-bg: #ffffff;
            --text-main: #0f172a;
            --text-muted: #64748b;
            --success: #10b981;
            --danger: #ef4444;
            --border: #e2e8f0;
            --radius: 16px;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif;
            background: var(--bg);
            color: var(--text-main);
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            padding: 20px;
        }
        .setup-card {
            background: var(--card-bg);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            padding: 32px;
            max-width: 480px;
            width: 100%;
            box-shadow: 0 10px 25px -5px rgba(0,0,0,0.05);
            text-align: center;
        }
        .icon {
            font-size: 48px;
            margin-bottom: 16px;
        }
        h1 {
            font-size: 24px;
            font-weight: 800;
            margin-bottom: 8px;
            color: var(--text-main);
        }
        p {
            color: var(--text-muted);
            font-size: 14px;
            line-height: 1.5;
            margin-bottom: 24px;
        }
        .config-box {
            background: #f1f5f9;
            border-radius: 12px;
            padding: 14px;
            text-align: left;
            font-size: 13px;
            margin-bottom: 24px;
            line-height: 1.8;
        }
        .btn {
            display: inline-block;
            width: 100%;
            background: var(--primary);
            color: #fff;
            padding: 14px 20px;
            border-radius: 12px;
            font-weight: 700;
            font-size: 15px;
            border: none;
            cursor: pointer;
            text-decoration: none;
            transition: all 0.2s;
        }
        .btn:hover { background: var(--primary-hover); transform: translateY(-1px); }
        .btn-success { background: var(--success); }
        .logs {
            margin-top: 20px;
            padding: 12px;
            background: #0f172a;
            color: #38bdf8;
            border-radius: 10px;
            font-family: monospace;
            font-size: 12px;
            text-align: left;
        }
        .alert {
            padding: 12px;
            border-radius: 10px;
            margin-bottom: 20px;
            font-size: 14px;
            font-weight: 600;
        }
        .alert-success { background: #dcfce7; color: #166534; }
        .alert-error { background: #fee2e2; color: #991b1b; }
    </style>
</head>
<body>

<div class="setup-card">
    <div class="icon">🧳</div>
    <h1>TripBook Setup</h1>
    <p>Initialize and seed your shared expense & cashbook database.</p>

    <?php if ($status === 'success'): ?>
        <div class="alert alert-success"><i data-lucide="check-circle" style="width:16px;height:16px;"></i> <?= htmlspecialchars($message) ?></div>
        <a href="index.php" class="btn btn-success">Open TripBook App →</a>
    <?php else: ?>
        <?php if ($status === 'error'): ?>
            <div class="alert alert-error"><i data-lucide="alert-triangle" style="width:16px;height:16px;"></i> <?= htmlspecialchars($message) ?></div>
        <?php endif; ?>

        <div class="config-box">
            <strong>Database Settings:</strong><br>
            • Host: <code><?= htmlspecialchars(DB_HOST) ?>:<?= htmlspecialchars(DB_PORT) ?></code><br>
            • Database: <code><?= htmlspecialchars(DB_NAME) ?></code><br>
            • User: <code><?= htmlspecialchars(DB_USER) ?></code>
        </div>

        <form method="POST">
            <button type="submit" class="btn">🚀 Initialize & Seed Database</button>
        </form>
    <?php endif; ?>

    <?php if (!empty($logs)): ?>
        <div class="logs">
            <?php foreach ($logs as $log): ?>
                <div><?= htmlspecialchars($log) ?></div>
            <?php endforeach; ?>
        </div>
    <?php endif; ?>
</div>

</body>
</html>
