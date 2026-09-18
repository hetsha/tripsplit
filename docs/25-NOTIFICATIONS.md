# 25 — Notifications

This document specifies the notification system: push, in-app, and WhatsApp notifications.

---

## 1. Notification Types

| Type | Trigger | Priority | Platforms |
|------|---------|----------|-----------|
| `expense_created` | New expense added to group | P0 | In-app, Push |
| `expense_edited` | Expense modified | P1 | In-app |
| `expense_deleted` | Expense removed | P1 | In-app |
| `settlement_recorded` | Settlement recorded | P1 | In-app, Push |
| `settlement_received` | You received a settlement | P0 | In-app, Push |
| `group_invitation` | Added to a group | P0 | In-app, Push |
| `member_joined` | New member joined group | P1 | In-app |
| `member_left` | Member left group | P2 | In-app |
| `bill_reminder` | Recurring bill due | P1 | In-app, Push, WhatsApp |
| `bill_overdue` | Bill past due | P1 | In-app, Push |
| `payment_reminder` | Someone reminded you to pay | P1 | In-app, Push, WhatsApp |

---

## 2. In-App Notifications

### Database: `notifications`

| Field | Type | Nullable | Default | Purpose |
|-------|------|----------|---------|---------|
| id | INT UNSIGNED PK | No | auto | Notification ID |
| user_id | INT UNSIGNED FK | No | — | Recipient |
| trip_id | INT UNSIGNED FK | Yes | NULL | Related group |
| type | VARCHAR(50) | No | — | Notification type |
| title | VARCHAR(255) | No | — | Notification title |
| message | TEXT | No | — | Notification body |
| data | JSON | Yes | NULL | Extra data (expense_id, etc.) |
| is_read | TINYINT(1) | No | 0 | Read status |
| created_at | TIMESTAMP | No | NOW() | Creation time |

### API Endpoints

| Endpoint | Method | Action |
|----------|--------|--------|
| `api/notifications.php` | GET | List notifications |
| `api/notifications.php` | POST (action=mark_read) | Mark as read |
| `api/notifications.php` | POST (action=mark_all_read) | Mark all as read |

### Notification List Response

```json
{
  "notifications": [
    {
      "id": 1,
      "type": "expense_created",
      "title": "New Expense",
      "message": "Akshat added 'Dinner' — ₹1,500",
      "data": { "expense_id": 45, "trip_id": 12 },
      "is_read": false,
      "created_at": "2026-09-15 19:30:00"
    }
  ],
  "unread_count": 3
}
```

---

## 3. Push Notifications

### Web Push

| Property | Value |
|----------|-------|
| API | Web Push API |
| Trigger | Browser notification permission granted |
| Delivery | Via service worker |
| Click action | Navigate to relevant screen |

### Android Push (Flutter)

| Property | Value |
|----------|-------|
| Provider | Firebase Cloud Messaging (FCM) |
| Trigger | App in background or killed |
| Delivery | FCM → Android notification tray |
| Click action | Deep link to relevant screen |

### Push Payload

```json
{
  "title": "New Expense",
  "body": "Akshat added 'Dinner' — ₹1,500",
  "data": {
    "type": "expense_created",
    "expense_id": 45,
    "trip_id": 12
  }
}
```

---

## 4. WhatsApp Notifications

### Trigger Events

| Event | WhatsApp Message |
|-------|-----------------|
| Bill reminder | "📋 Reminder: {name} due on {date}. Amount: ₹{amount}" |
| Bill overdue | "🔴 {name} is overdue! Was due on {date}." |
| Payment reminder | "Reminder: You owe ₹{amount} in {group}" |

### Delivery Rules

- Only sent if user has WhatsApp account linked
- Only sent for high/medium priority events
- Rate limit: 3 WhatsApp notifications per day per user
- User can opt out in settings

---

## 5. Notification Preferences

### Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `notify_expense_created` | ON | Expense added to my groups |
| `notify_settlement` | ON | Settlements involving me |
| `notify_group_invite` | ON | Group invitations |
| `notify_bill_reminder` | ON | Bill due reminders |
| `notify_push` | ON | Push notifications |
| `notify_whatsapp` | ON | WhatsApp notifications |

### API Endpoints

| Endpoint | Method | Action |
|----------|--------|--------|
| `api/settings.php` | GET/POST | Notification preferences |

---

## 6. Notification Creation

### Backend Helper

```php
function createNotification(
  int $userId,
  string $type,
  string $title,
  string $message,
  ?int $tripId = null,
  ?array $data = null
): void {
  // Insert into notifications table
  // Create push notification payload
  // Queue WhatsApp notification (if enabled)
}
```

### Creation Points

| Event | Where Created |
|-------|---------------|
| Expense added | `api/expenses.php` (create action) |
| Settlement recorded | `api/settlements.php` (settle action) |
| Member added | `api/members.php` (add action) |
| Bill due | Background worker (daily cron) |

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should email notifications be supported? | SMTP integration |
| OQ-2 | Should we support notification batching (daily digest)? | UX, delivery |
| OQ-3 | Should WhatsApp notifications include interactive buttons? | WhatsApp API scope |

---

## Dependencies

- `05-AUTHENTICATION.md` — User identity
- `15-WHATSAPP-INTEGRATION.md` — WhatsApp delivery
- `11-BILLS-AND-REMINDERS.md` — Bill reminder triggers

## Related Documents

- `03-SCREEN-SPECIFICATION.md` — Notification screen spec
- `20-DATABASE-SCHEMA.md` — notifications table
- `21-API-SPECIFICATION.md` — Notification API endpoints
- `22-BACKEND-ARCHITECTURE.md` — Notification worker
