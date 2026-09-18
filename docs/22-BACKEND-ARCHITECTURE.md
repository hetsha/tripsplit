# 22 — Backend Architecture

This document specifies the PHP backend architecture: framework, modules, services, queues, and implementation patterns.

---

## 1. Technology Stack

| Component | Technology |
|-----------|-----------|
| Language | PHP 8+ |
| Database | MySQL 8+ (PDO) |
| Web Server | Apache (XAMPP) / Nginx |
| Session | PHP native sessions |
| File Storage | Local filesystem |
| Queue | Database-backed |
| OCR | Tesseract (exec) |
| LLM | Ollama / API fallback |

---

## 2. Directory Structure

```
tripsplit/
├── config/
│   └── database.php          # DB connection
├── includes/
│   ├── auth.php              # Session, CSRF, auth helpers
│   ├── calculations.php      # Financial calculations engine
│   ├── functions.php         # Utility functions
│   └── validation.php        # Input validation
├── api/
│   ├── auth.php              # Authentication endpoints
│   ├── trips.php             # Group CRUD
│   ├── members.php           # Member management
│   ├── expenses.php          # Expense CRUD
│   ├── transactions.php      # Transaction list/delete
│   ├── settlements.php       # Settlement operations
│   ├── dashboard.php         # Dashboard data
│   ├── cashbook.php          # Personal finance (LEGACY — will be replaced by personal-finance.php)
│   ├── passbook.php          # Passbook view
│   ├── categories.php        # Category management
│   ├── notifications.php     # Notifications
│   ├── settings.php          # App settings
│   ├── export.php            # CSV/PDF export
│   ├── sync.php              # Incremental sync
│   ├── otp.php               # Phone OTP
│   ├── email-otp.php         # Email OTP
│   ├── google-auth.php       # Google OAuth
│   └── bills.php             # Recurring bills (new)
├── workers/
│   ├── bill_reminder.php     # Daily bill reminders
│   ├── whatsapp_processor.php # WhatsApp message processing
│   └── notification_sender.php # Push notification delivery
├── services/
│   ├── whatsapp/
│   │   ├── TransportInterface.php
│   │   ├── OpenWAAdapter.php
│   │   └── MessageRouter.php
│   ├── ai/
│   │   ├── RuleEngine.php
│   │   ├── LLMService.php
│   │   └── IntentParser.php
│   ├── ocr/
│   │   └── TesseractService.php
│   └── notification/
│       ├── PushService.php
│       └── WhatsAppNotify.php
├── storage/
│   ├── receipts/
│   ├── exports/
│   └── whatsapp_media/
├── sql/
│   ├── schema.sql
│   ├── seed.sql
│   └── migrations/
└── admin/
    └── ...
```

---

## 3. Module Architecture

### Request Flow

```
HTTP Request
  → Apache/Nginx
  → PHP Router (index.php or direct API file)
  → Auth middleware (session check)
  → CSRF check (POST requests)
  → Input validation
  → Business logic (includes/functions)
  → Database query (PDO)
  → JSON response
```

### Service Layer Pattern

Each domain has a service class:

```php
class ExpenseService {
    private $db;
    
    public function create(array $data, int $userId): array {
        // 1. Validate input
        // 2. Check idempotency (client_request_id)
        // 3. Validate splits (F1 invariant)
        // 4. Insert transaction
        // 5. Insert expense_splits
        // 6. Recalculate balances
        // 7. Create notifications
        // 8. Return result
    }
}
```

---

## 4. Authentication Middleware

```php
function requireAuth(): array {
    session_start();
    if (!isset($_SESSION['user_id'])) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Unauthorized']);
        exit;
    }
    return getCurrentUser();
}

function requireCSRF(): void {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $token = $_SERVER['HTTP_X_CSRF_TOKEN'] ?? $_POST['csrf_token'] ?? '';
        if ($token !== $_SESSION['csrf_token']) {
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'Invalid CSRF token']);
            exit;
        }
    }
}

function requireTripMembership(int $tripId, int $userId): void {
    // Check user is member of the trip
}
```

---

## 5. Background Workers

### Worker Architecture

Workers are PHP CLI scripts run via cron or supervisor:

```bash
# Cron jobs
* * * * * php /var/www/tripsplit/workers/bill_reminder.php
*/5 * * * * php /var/www/tripsplit/workers/whatsapp_processor.php
*/1 * * * * php /var/www/tripsplit/workers/notification_sender.php
```

### Bill Reminder Worker

```
Daily at 8:00 AM:
  1. Query recurring_bills where next_due_date <= CURDATE() + reminder_days_before
  2. For each bill:
     - Create notification
     - Queue push notification
     - Queue WhatsApp reminder (if enabled)
```

### WhatsApp Message Processor

```
Every 5 minutes:
  1. Query whatsapp_message_queue where status = 'pending'
  2. For each message:
     - Process intent
     - Execute action
     - Send reply
     - Update status
```

---

## 6. File Storage

| Type | Path | Max Size |
|------|------|----------|
| Receipts | `/storage/receipts/{user_id}/` | 5 MB |
| Exports | `/storage/exports/{user_id}/` | 50 MB |
| WhatsApp media | `/storage/whatsapp_media/` | 10 MB |

---

## 7. Error Handling

### Global Error Handler

```php
function errorHandler($errno, $errstr, $errfile, $errline) {
    error_log("[$errno] $errstr in $errfile:$errline");
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Internal server error'
    ]);
    exit;
}
```

### API Error Response

```php
function jsonError(string $message, int $code = 400, array $errors = []): void {
    http_response_code($code);
    echo json_encode([
        'success' => false,
        'message' => $message,
        'errors' => $errors
    ]);
    exit;
}
```

---

## 8. Logging

| Log Type | File | Rotation |
|----------|------|----------|
| Access log | `/logs/access.log` | Daily |
| Error log | `/logs/error.log` | Daily |
| WhatsApp log | `/logs/whatsapp.log` | Daily |
| AI processing log | `/logs/ai.log` | Daily |

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should we use a PHP framework (Laravel, Slim)? | Development speed vs. control |
| OQ-2 | Should we implement rate limiting at nginx or PHP level? | Architecture |
| OQ-3 | Should we use Redis for caching? | Performance vs. complexity |

---

## Dependencies

- `20-DATABASE-SCHEMA.md` — Database tables
- `21-API-SPECIFICATION.md` — API endpoints
- `26-SECURITY-PRIVACY.md` — Security implementation

## Related Documents

- `21-API-SPECIFICATION.md` — API contracts
- `23-FRONTEND-ARCHITECTURE.md` — Web frontend
- `24-FLUTTER-ARCHITECTURE.md` — Flutter app
- `15-WHATSAPP-INTEGRATION.md` — WhatsApp service
- `17-AI-AND-LLM.md` — AI service
