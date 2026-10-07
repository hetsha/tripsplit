<?php
/**
 * TripSplit Admin Panel - Secure Login
 * Section 4.2 & Section 4.3
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

$db = getDBConnection();
ensureAdminTablesExist($db);

// Already logged in
if (isAdminAuthenticated()) {
    header('Location: index.php');
    exit;
}

$error = '';
$ip = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // CSRF Check
    if (!verifyCsrfToken()) {
        $error = 'Invalid or expired session token. Please try again.';
    } else {
        $username = trim($_POST['username'] ?? '');
        $password = $_POST['password'] ?? '';

        if (empty($username) || empty($password)) {
            $error = 'Please enter both username/email and password';
        } else {
            // Check brute-force lockout
            $throttleError = checkLoginThrottling($username, $ip);
            if ($throttleError !== null) {
                $error = $throttleError;
                logLoginAttempt(null, $username, 'locked', 'Account temporarily throttled');
            } else {
                $stmt = $db->prepare("
                    SELECT id, username, email, password_hash, name, role, status 
                    FROM admin_users 
                    WHERE username = ? OR email = ? 
                    LIMIT 1
                ");
                $stmt->execute([$username, $username]);
                $admin = $stmt->fetch();

                if ($admin && password_verify($password, $admin['password_hash'])) {
                    if ($admin['status'] !== 'active') {
                        $error = 'Your administrator account has been disabled or suspended. Please contact support.';
                        logLoginAttempt((int)$admin['id'], $username, 'failed', 'Account inactive: ' . $admin['status']);
                    } else {
                        // Success: Regenerate session to prevent fixation
                        session_regenerate_id(true);

                        $_SESSION['admin_id'] = (int)$admin['id'];
                        $_SESSION['admin_username'] = $admin['username'];
                        $_SESSION['admin_name'] = $admin['name'];
                        $_SESSION['admin_email'] = $admin['email'] ?? '';
                        $_SESSION['admin_role'] = $admin['role'] ?? 'SUPER_ADMIN';
                        $_SESSION['admin_last_activity'] = time();

                        // Update last login in DB
                        $stmt = $db->prepare("UPDATE admin_users SET last_login = NOW(), last_login_ip = ? WHERE id = ?");
                        $stmt->execute([$ip, $admin['id']]);

                        // Log successful login
                        logLoginAttempt((int)$admin['id'], $username, 'success');
                        logAdminAudit('LOGIN', 'auth', 'admin_user', (string)$admin['id'], null, null, 'Successful admin login from ' . $ip);

                        header('Location: index.php');
                        exit;
                    }
                } else {
                    $error = 'Invalid username or password';
                    $adminId = $admin ? (int)$admin['id'] : null;
                    logLoginAttempt($adminId, $username, 'failed', 'Invalid credentials');
                }
            }
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TripSplit Admin - Secure Login</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif;
            background: #090d16;
            background-image: 
                radial-gradient(at 10% 20%, rgba(99, 102, 241, 0.25) 0px, transparent 45%),
                radial-gradient(at 90% 80%, rgba(168, 85, 247, 0.2) 0px, transparent 45%),
                radial-gradient(at 50% 50%, rgba(15, 23, 42, 0.8) 0px, transparent 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 24px;
            color: #0f172a;
        }
        .login-card {
            background: rgba(255, 255, 255, 0.96);
            backdrop-filter: blur(20px);
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 24px;
            box-shadow: 0 30px 60px -15px rgba(0, 0, 0, 0.5), 0 0 0 1px rgba(255, 255, 255, 0.1);
            width: 100%;
            max-width: 440px;
            padding: 44px 38px;
            position: relative;
        }
        .login-header {
            text-align: center;
            margin-bottom: 32px;
        }
        .login-logo {
            width: 64px;
            height: 64px;
            background: linear-gradient(135deg, #6366f1 0%, #4f46e5 50%, #7c3aed 100%);
            color: white;
            border-radius: 18px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 28px;
            margin-bottom: 18px;
            box-shadow: 0 12px 24px -4px rgba(99, 102, 241, 0.4);
            border: 1.5px solid rgba(255, 255, 255, 0.25);
        }
        .login-title {
            font-size: 25px;
            font-weight: 800;
            color: #0f172a;
            letter-spacing: -0.6px;
        }
        .login-subtitle {
            font-size: 13.5px;
            color: #64748b;
            margin-top: 6px;
            font-weight: 500;
        }
        .form-group {
            margin-bottom: 20px;
        }
        .form-label {
            display: block;
            font-size: 13px;
            font-weight: 600;
            color: #334155;
            margin-bottom: 8px;
        }
        .form-control {
            width: 100%;
            padding: 13px 16px;
            border: 1.5px solid #e2e8f0;
            border-radius: 12px;
            font-size: 15px;
            transition: all 0.2s;
            background: #f8fafc;
        }
        .form-control:focus {
            outline: none;
            border-color: #6366f1;
            background: #ffffff;
            box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.2);
        }
        .btn-submit {
            width: 100%;
            padding: 14px;
            font-size: 15px;
            font-weight: 700;
            color: white;
            background: linear-gradient(135deg, #6366f1 0%, #4f46e5 50%, #7c3aed 100%);
            border: none;
            border-radius: 12px;
            cursor: pointer;
            box-shadow: 0 8px 18px -4px rgba(99, 102, 241, 0.4);
            transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
        }
        .btn-submit:hover {
            transform: translateY(-2px);
            box-shadow: 0 14px 26px -4px rgba(99, 102, 241, 0.5);
        }
        .error-alert {
            background: #fef2f2;
            border: 1px solid #fecaca;
            color: #991b1b;
            padding: 12px 16px;
            border-radius: 10px;
            font-size: 13.5px;
            margin-bottom: 24px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .security-badge {
            margin-top: 24px;
            padding-top: 20px;
            border-top: 1px solid #f1f5f9;
            text-align: center;
            font-size: 12px;
            color: #94a3b8;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
        }
    </style>
</head>
<body>
    <div class="login-card">
        <div class="login-header">
            <div class="login-logo">🛡️</div>
            <h1 class="login-title">TripSplit Admin</h1>
            <p class="login-subtitle">Platform Management & Enterprise Control</p>
        </div>

        <?php if (!empty($error)): ?>
            <div class="error-alert">
                <span>⚠️</span>
                <span><?= htmlspecialchars($error) ?></span>
            </div>
        <?php endif; ?>

        <?php if (isset($_GET['logged_out'])): ?>
            <div style="background:#ecfdf5; border:1px solid #a7f3d0; color:#065f46; padding:12px; border-radius:10px; font-size:13.5px; margin-bottom:20px;">
                ✓ Logged out successfully.
            </div>
        <?php endif; ?>

        <form method="POST" action="login.php" autocomplete="off">
            <?= csrfField() ?>
            <div class="form-group">
                <label class="form-label" for="username">Username or Email</label>
                <input type="text" id="username" name="username" class="form-control" 
                       placeholder="admin or admin@tripsplit.local" required autofocus
                       value="<?= htmlspecialchars($_POST['username'] ?? '') ?>">
            </div>

            <div class="form-group">
                <label class="form-label" for="password">Password</label>
                <input type="password" id="password" name="password" class="form-control" 
                       placeholder="••••••••••••" required>
            </div>

            <button type="submit" class="btn-submit">Sign In to Admin Panel</button>
        </form>

        <div class="security-badge">
            🔒 Protected by RBAC, Audit Logging & Rate Limiting
        </div>
    </div>
</body>
</html>
