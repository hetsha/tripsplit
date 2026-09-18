# 11 — Bills and Reminders

This document specifies the recurring bills, due dates, and reminder system.

---

## 1. Recurring Bills

### Supported Recurrence Patterns

| Pattern | Description | Example |
|---------|-------------|---------|
| `daily` | Every day | Daily milk delivery |
| `weekly` | Same day each week | Weekly grocery |
| `monthly` | Same date each month | Rent on 1st |
| `yearly` | Same date each year | Annual subscription |
| `custom` | Custom interval (every N days) | Every 15 days |

### Database: `recurring_bills`

| Field | Type | Nullable | Default | Purpose |
|-------|------|----------|---------|---------|
| id | INT UNSIGNED PK | No | auto | Bill ID |
| user_id | INT UNSIGNED FK | No | — | Owner |
| trip_id | INT UNSIGNED FK | Yes | NULL | Group context (NULL = personal) |
| name | VARCHAR(255) | No | — | Bill name |
| amount | DECIMAL(12,2) | Yes | NULL | Fixed amount (NULL = variable) |
| category_id | INT UNSIGNED FK | Yes | NULL | Category |
| recurrence | ENUM | No | — | daily/weekly/monthly/yearly/custom |
| custom_interval_days | INT | Yes | NULL | For custom pattern |
| due_day | INT | Yes | NULL | Day of month/week |
| next_due_date | DATE | No | — | Next occurrence |
| reminder_days_before | INT | No | 1 | Days before due to remind |
| priority | ENUM | No | 'medium' | high/medium/low |
| is_active | TINYINT(1) | No | 1 | Active/paused |
| payment_method | ENUM | Yes | NULL | Preferred payment method |
| notes | TEXT | Yes | NULL | Notes |
| created_at | TIMESTAMP | No | NOW() | Creation time |
| updated_at | TIMESTAMP | No | NOW() | Last update |

### Create Recurring Bill

| Field | Validation |
|-------|-----------|
| name | Required, 1-255 chars |
| amount | ≥ 0 (optional for variable bills) |
| recurrence | Required |
| next_due_date | Required, ≥ today |
| reminder_days_before | 0-30 |

### Next Due Date Calculation

```
monthly: next_due_date = today + 1 month (clamped to month end)
weekly: next_due_date = today + 7 days
yearly: next_due_date = today + 1 year
daily: next_due_date = today + 1
custom: next_due_date = today + custom_interval_days
```

After payment: `next_due_date` advances to next occurrence.

### API Endpoints

| Endpoint | Method | Action |
|----------|--------|--------|
| `api/bills.php` | POST | Create recurring bill |
| `api/bills.php` | GET | List bills |
| `api/bills.php` | POST (action=update) | Update bill |
| `api/bills.php` | POST (action=delete) | Delete bill |
| `api/bills.php` | POST (action=pay) | Mark as paid |

---

## 2. Due Date Tracking

### Bill States

| State | Description |
|-------|-------------|
| `upcoming` | Due date is in the future |
| `due_today` | Due date is today |
| `overdue` | Due date has passed |
| `paid` | Marked as paid for current period |

### Overdue Detection

Background worker runs daily:
1. Query all active bills where `next_due_date <= CURDATE()`
2. For unpaid bills: mark as overdue
3. Send reminder notification if `reminder_days_before` matches

---

## 3. Priority Bills

| Priority | Color | Notification Behavior |
|----------|-------|----------------------|
| `high` | `#F43F5E` (negative) | Daily reminder when due/overdue |
| `medium` | `#F59E0B` (warning) | Reminder on due date |
| `low` | `#06B6D4` (info) | Reminder 1 day before |

---

## 4. Reminders

### Notification Trigger

```
Background worker checks daily:
  FOR each active bill:
    days_until_due = next_due_date - CURDATE()
    IF days_until_due <= reminder_days_before:
      IF bill has not been reminded for this period:
        Create notification
        Send push notification (if enabled)
        Send WhatsApp reminder (if enabled)
```

### Notification Content

```
High priority: "⚠️ {name} is due tomorrow! Amount: ₹{amount}"
Medium: "📋 Reminder: {name} due on {date}. Amount: ₹{amount}"
Low: "ℹ️ {name} upcoming on {date}. Amount: ₹{amount}"
Overdue: "🔴 {name} is overdue! Was due on {date}. Amount: ₹{amount}"
```

### API Endpoints

| Endpoint | Method | Action |
|----------|--------|--------|
| `api/notifications.php` | GET | List bill reminders |

---

## 5. Paid/Unpaid Tracking

### Mark as Paid

```
User marks bill as paid
  → System records payment date
  → System advances next_due_date to next occurrence
  → System creates transaction record (if amount is fixed)
  → System updates bill status
```

### Payment Recording

When a bill is marked paid:
- If `amount` is set: creates a transaction in the appropriate module (personal or group)
- If `amount` is NULL: just advances the due date (variable amount bills)

---

## 6. Upcoming Bills View

### Response Format

```json
{
  "upcoming": [
    {
      "id": 1,
      "name": "Rent",
      "amount": 15000.00,
      "next_due_date": "2026-10-01",
      "days_until_due": 13,
      "priority": "high",
      "recurrence": "monthly",
      "is_paid": false
    }
  ],
  "overdue": [],
  "paid_this_month": [
    {
      "id": 2,
      "name": "Internet",
      "amount": 999.00,
      "paid_on": "2026-09-15",
      "priority": "medium"
    }
  ]
}
```

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should bills auto-create expenses on due date? | Automation scope |
| OQ-2 | Should shared bills (group context) auto-split? | Feature complexity |
| OQ-3 | Should we support bill attachments (invoices)? | Feature scope |

---

## Dependencies

- `10-PERSONAL-EXPENSES.md` — Personal bill linkage
- `25-NOTIFICATIONS.md` — Reminder delivery

## Related Documents

- `10-PERSONAL-EXPENSES.md` — Personal finance module
- `12-ANALYTICS.md` — Bill analytics
- `20-DATABASE-SCHEMA.md` — recurring_bills table
- `21-API-SPECIFICATION.md` — Bills API endpoints
