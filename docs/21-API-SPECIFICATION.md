# 21 — API Specification

This document specifies every REST API endpoint. For each: method, URL, authentication, request/response, validation, errors, authorization, idempotency, and pagination.

---

## Base Configuration

| Property | Value |
|----------|-------|
| Base URL | `/api/` |
| Protocol | HTTP/HTTPS |
| Content-Type | `application/json` |
| Authentication | Session cookies (`PHPSESSID`) |
| CSRF | `X-CSRF-Token` header for POST requests |
| Idempotency | `client_request_id` in request body |

---

## 1. Auth APIs

### `POST /api/otp.php?action=send_otp`

| Property | Value |
|----------|-------|
| Auth | None |
| Rate limit | 3 per 5 minutes per phone |

**Request**:
```json
{ "phone": "+919999999999" }
```

**Response 200**:
```json
{ "success": true, "message": "OTP sent successfully" }
```

**Errors**: 400 (invalid phone), 429 (rate limited), 500 (SMS failed)

---

### `POST /api/otp.php?action=verify_otp`

**Request**:
```json
{ "phone": "+919999999999", "otp_code": "123456" }
```

**Response 200**:
```json
{
  "success": true,
  "data": {
    "user": { "id": 1, "name": "Het", "email": "het@example.com", "phone": "+919999999999", "avatar_color": "#2563eb" },
    "trips": [{ "id": 12, "trip_code": "TRIP-DXQAT", "name": "Goa Trip", "currency_symbol": "₹", "role": "owner" }],
    "is_new_user": false,
    "csrf_token": "abc123..."
  }
}
```

**Errors**: 400 (invalid OTP, expired, max attempts)

---

### `GET /api/auth.php?action=me`

| Property | Value |
|----------|-------|
| Auth | Required |

**Response 200**:
```json
{
  "success": true,
  "data": {
    "user": { "id": 1, "name": "Het", "email": "het@example.com", "avatar_color": "#2563eb" },
    "csrf_token": "abc123...",
    "trips": [...],
    "active_trip": 12
  }
}
```

---

### `POST /api/auth.php?action=switch_trip`

**Request**: `{ "trip_id": 12 }`

**Response 200**: `{ "success": true, "data": { "active_trip_id": 12 } }`

---

### `POST /api/google-auth.php`

**Request**: `{ "id_token": "google_token_string" }`

**Response 200**: Same as verify_otp response

---

### `POST /api/email-otp.php?action=send_email_otp`

**Request**: `{ "email": "user@example.com" }`

**Response 200**: `{ "success": true, "message": "OTP sent to email" }`

---

### `POST /api/email-otp.php?action=verify_email_otp`

**Request**: `{ "email": "user@example.com", "otp_code": "123456" }`

**Response 200**: Same as verify_otp response

---

### `POST /api/auth.php?action=delete_account`

| Property | Value |
|----------|-------|
| Auth | Required |

**Response 200**: `{ "success": true, "message": "Account scheduled for deletion" }`

---

## 2. Group APIs

### `GET /api/trips.php`

| Property | Value |
|----------|-------|
| Auth | Required |

**Response 200**:
```json
{
  "success": true,
  "data": {
    "trips": [
      {
        "id": 12,
        "trip_code": "TRIP-DXQAT",
        "url_token": "a1b2c3d4",
        "name": "Goa Trip",
        "description": "...",
        "currency_symbol": "₹",
        "member_count": 5,
        "total_expenses": 15000.00,
        "role": "owner",
        "created_at": "2026-08-01"
      }
    ]
  }
}
```

---

### `POST /api/trips.php` (create)

**Request**:
```json
{
  "action": "create",
  "name": "Goa Trip",
  "description": "Trip to Goa",
  "starting_money": 8000.00,
  "starting_payment_method": "cash",
  "currency": "INR"
}
```

**Validation**: name required (1-150 chars), starting_money ≥ 0

**Response 200**: `{ "success": true, "data": { "trip": {...} } }`

---

### `POST /api/trips.php` (update)

**Request**: `{ "action": "update", "trip_id": 12, "name": "New Name" }`

**Authorization**: Owner or Admin

---

### `POST /api/trips.php` (join)

**Request**: `{ "action": "join", "trip_code": "TRIP-DXQAT" }`

**Response 200**: `{ "success": true, "data": { "trip": {...} } }`

**Errors**: 404 (code not found), 409 (already member)

---

### `POST /api/trips.php` (delete)

**Request**: `{ "action": "delete", "trip_id": 12 }`

**Authorization**: Owner only, all balances must be settled

---

## 3. Member APIs

### `GET /api/members.php`

**Response 200**:
```json
{
  "success": true,
  "data": {
    "members": [
      {
        "user_id": 1,
        "name": "Het",
        "avatar_color": "#2563eb",
        "role": "owner",
        "net_balance": 800.00,
        "total_paid": 5000.00,
        "total_share": 4200.00
      }
    ]
  }
}
```

---

### `POST /api/members.php` (add)

**Request**: `{ "action": "add", "phone": "+919999999999" }`

**Authorization**: Owner or Admin

**Errors**: 404 (user not found), 409 (already member)

---

### `POST /api/members.php` (remove)

**Request**: `{ "action": "remove", "user_id": 3 }`

**Authorization**: Owner (any member), Admin (non-owners)

---

## 4. Expense APIs

### `GET /api/transactions.php`

**Query params**: `page`, `per_page`, `type`, `date_from`, `date_to`, `category_id`, `search`

**Response 200**:
```json
{
  "success": true,
  "data": {
    "transactions": [...],
    "pagination": { "page": 1, "per_page": 20, "total": 150 }
  }
}
```

---

### `POST /api/expenses.php` (create)

**Request**:
```json
{
  "action": "create",
  "amount": 1500.00,
  "description": "Dinner",
  "category_id": 1,
  "paid_by": 2,
  "payment_method": "upi",
  "transaction_date": "2026-09-15 19:30:00",
  "notes": "Had dinner at Lake View",
  "is_personal": false,
  "client_request_id": "uuid-1234-5678",
  "splits": [
    { "user_id": 1, "amount": 500.00 },
    { "user_id": 2, "amount": 500.00 },
    { "user_id": 3, "amount": 500.00 }
  ]
}
```

**Validation**:
- amount > 0, max 2 decimals
- description required
- splits must sum to amount (F1 invariant)
- all user_ids must be group members
- client_request_id checked for duplicates (F4)

**Response 200**: `{ "success": true, "message": "Expense saved successfully!" }`

**Errors**: 400 (validation failed), 409 (duplicate client_request_id)

---

### `POST /api/expenses.php` (update)

**Request**: Same as create, with `"action": "update"` and `"id": 45`

**Authorization**: Creator, Admin, or Owner

---

### `POST /api/transactions.php` (delete)

**Request**: `{ "action": "delete", "id": 45 }`

**Authorization**: Creator, Admin, or Owner

---

## 5. Settlement APIs

### `GET /api/settlements.php?action=suggestions`

**Response 200**:
```json
{
  "success": true,
  "data": {
    "simplified_settlements": [
      {
        "from_user_id": 2,
        "from_user_name": "Rahul",
        "to_user_id": 1,
        "to_user_name": "Het",
        "amount": 500.00
      }
    ]
  }
}
```

---

### `POST /api/settlements.php` (settle)

**Request**:
```json
{
  "action": "settle",
  "from_user": 2,
  "to_user": 1,
  "amount": 500.00,
  "payment_method": "upi",
  "notes": "Settled dinner debt",
  "client_request_id": "uuid-settle-1234"
}
```

**Validation**: amount > 0, from_user and to_user must be group members

---

### `GET /api/settlements.php?action=history`

**Response 200**: Array of settlement records

---

### `POST /api/settlements.php` (undo)

**Request**: `{ "action": "undo", "settlement_id": 1 }`

**Authorization**: Original recorder, within 24 hours

---

## 6. Personal Finance APIs

### `GET /api/cashbook.php`

**Response 200**:
```json
{
  "success": true,
  "data": {
    "user_id": 1,
    "currency_symbol": "₹",
    "total_in": 50000.00,
    "total_out": 12500.00,
    "net_outflow": 37500.00,
    "entries": [...]
  }
}
```

---

### `POST /api/cashbook.php` (add)

**Request**:
```json
{
  "action": "add",
  "type": "expense",
  "amount": 500.00,
  "description": "Groceries",
  "category_id": 101,
  "payment_method": "upi",
  "client_request_id": "uuid-personal-1234"
}
```

---

### `GET /api/passbook.php`

**Response 200**: Bank-style passbook with running balance

---

## 7. Category APIs

### `GET /api/categories.php`

**Response 200**:
```json
{
  "success": true,
  "data": {
    "categories": [
      { "id": 1, "name": "Food & Drinks", "icon": "utensils", "color": "#ef4444", "is_default": true }
    ]
  }
}
```

---

### `POST /api/categories.php` (create)

**Request**: `{ "name": "Gym", "icon": "dumbbell", "color": "#8b5cf6", "type": "expense" }`

---

## 8. Dashboard API

### `GET /api/dashboard.php`

**Response 200**:
```json
{
  "success": true,
  "data": {
    "trip_money": { "starting_money": 8000, "total_added_money": 0, "total_spent": 900, "available_shared_money": 7100, "payment_breakdown": {...} },
    "expense_summary": { "total_all_expenses": 900, "expense_count": 1 },
    "member_balances": [...],
    "who_owes_whom": [...],
    "recent_transactions": [...],
    "category_spending": [...]
  }
}
```

---

## 9. Notification APIs

### `GET /api/notifications.php`

**Response 200**:
```json
{
  "success": true,
  "data": {
    "notifications": [...],
    "unread_count": 3
  }
}
```

---

### `POST /api/notifications.php` (mark_read)

**Request**: `{ "action": "mark_read", "id": 1 }`

---

### `POST /api/notifications.php` (mark_all_read)

**Request**: `{ "action": "mark_all_read" }`

---

## 10. Export API

### `GET /api/export.php`

**Query params**: `type` (csv/pdf), `scope` (personal/group), `trip_id`, `date_from`, `date_to`

**Response**: File download (CSV) or HTML (PDF print view)

---

## 11. Bills API

### `GET /api/bills.php`

**Response 200**:
```json
{
  "success": true,
  "data": {
    "upcoming": [...],
    "overdue": [...],
    "paid_this_month": [...]
  }
}
```

---

### `POST /api/bills.php` (create)

**Request**:
```json
{
  "name": "Rent",
  "amount": 15000.00,
  "recurrence": "monthly",
  "next_due_date": "2026-10-01",
  "reminder_days_before": 3,
  "priority": "high"
}
```

---

### `POST /api/bills.php` (pay)

**Request**: `{ "action": "pay", "bill_id": 1 }`

---

## 12. Sync API

### `GET /api/sync.php`

**Query params**: `trip_id`, `version`

**Response 200**:
```json
{
  "success": true,
  "data": {
    "trip_id": 12,
    "has_changes": true,
    "version": "60a4f553a...",
    "last_update": "2026-09-15 16:30:00"
  }
}
```

---

## 13. Settings API

### `GET /api/settings.php`

**Response 200**: App settings and user preferences

---

### `POST /api/settings.php` (update_profile)

**Request**: `{ "action": "update_profile", "name": "New Name", "email": "new@example.com", "avatar_color": "#10b981" }`

---

## 14. Search API

### `GET /api/transactions.php` (with search)

**Query params**: `search=dinner`, `type=expense`, `date_from=2026-09-01`

**Response**: Filtered transaction list

---

## Common Response Formats

### Success
```json
{ "success": true, "message": "...", "data": {...} }
```

### Error
```json
{ "success": false, "message": "Error description", "errors": {...} }
```

### Pagination
```json
{
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 150,
    "total_pages": 8
  }
}
```

---

## HTTP Status Codes

| Code | Usage |
|------|-------|
| 200 | Success |
| 201 | Created |
| 400 | Validation error |
| 401 | Unauthorized (no session) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Not found |
| 409 | Conflict (duplicate, already exists) |
| 429 | Rate limited |
| 500 | Server error |

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should we version the API (v1, v2)? | Breaking change management |
| OQ-2 | Should we support GraphQL in the future? | API architecture |
| OQ-3 | Should we implement API rate limiting per user? | Security |

---

## Dependencies

- `20-DATABASE-SCHEMA.md` — Data structures
- All module documents define business rules for these endpoints

## Related Documents

- `20-DATABASE-SCHEMA.md` — Database tables
- `22-BACKEND-ARCHITECTURE.md` — Backend implementation
- `26-SECURITY-PRIVACY.md` — Security rules
- `27-SYNC-OFFLINE.md` — Sync API details
