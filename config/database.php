<?php
/**
 * TripBook Database Configuration
 * Supports standard XAMPP / WAMP / Linux MySQL configuration
 */

declare(strict_types=1);

// Database connection parameters
define('DB_HOST', getenv('DB_HOST') ?: '127.0.0.1');
define('DB_PORT', getenv('DB_PORT') ?: '3306');
define('DB_NAME', getenv('DB_NAME') ?: 'tripbook');
define('DB_USER', getenv('DB_USER') ?: 'root');
define('DB_PASS', getenv('DB_PASS') !== false ? getenv('DB_PASS') : '');
define('DB_CHARSET', 'utf8mb4');

/**
 * Returns a singleton PDO connection to the application database.
 */
function getDBConnection(): PDO {
    static $pdo = null;

    if ($pdo === null) {
        $dsn = sprintf(
            'mysql:host=%s;port=%s;dbname=%s;charset=%s',
            DB_HOST,
            DB_PORT,
            DB_NAME,
            DB_CHARSET
        );

        $options = [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
            PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci"
        ];

        try {
            $pdo = new PDO($dsn, DB_USER, DB_PASS, $options);
        } catch (PDOException $e) {
            // Code 1049 indicates database does not exist
            if ($e->getCode() === 1049) {
                throw new PDOException("Database '" . DB_NAME . "' does not exist. Please run setup.php to initialize it.", 1049);
            }
            throw $e;
        }
    }

    return $pdo;
}

/**
 * Returns a PDO connection to MySQL server without selecting a specific database.
 * Used for database setup / migrations in setup.php.
 */
function getServerConnection(): PDO {
    $dsn = sprintf(
        'mysql:host=%s;port=%s;charset=%s',
        DB_HOST,
        DB_PORT,
        DB_CHARSET
    );

    $options = [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ];

    return new PDO($dsn, DB_USER, DB_PASS, $options);
}
