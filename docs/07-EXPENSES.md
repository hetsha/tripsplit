# 07 — Expenses

This document specifies the complete expense lifecycle: creation, editing, deletion, categories, and the financial invariant that must always hold.

---

## Financial Invariant F1

> **expense_total = Σ(participant_shares)**

This invariant is enforced by the backend before every expense save. If rounding causes a discrepancy, the largest share is adjusted to ensure exact equality.

See `08-SPLIT-METHODS.md` for detailed rounding rules per split method.

---

## Expense Types

| Type | Description | Affects Group Pool | Affects Balances |
|------|-------------|-------------------|------------------|
| `expense` | Shared expense paid by one member | Yes (if during-trip) | Yes |
| `income` | Money added to shared pool | Yes | Yes (payer balance) |
| `settlement` | Payment between members | No | Yes (balances adjusted) |

---

## 1. Create Expense

### Required Fields

| Field | Type | Validation |
|-------|------|------------|
| amount | DECIMAL(12,2) | > 0, max 2 decimals, max 10,000,000 |
| description | VARCHAR(255) | Required, 1-255 characters |
| category_id | INT | Must exist in categories table |
| paid_by | INT | Must be group member |
| payment_method | ENUM | cash, upi, card, bank, other |
| splits | ARRAY | Required, at least 1 split |
| client_request_id | UUID | Required for idempotency |

### Optional Fields

| Field | Type | Default |
|-------|------|---------|
| notes | TEXT | NULL |
| transaction_date | DATETIME | NOW() |
| receipt_image | FILE | NULL |
| is_personal | BOOLEAN | false |

### Database: `transactions`

| Field | Type | Nullable | Default | Purpose |
|-------|------|----------|---------|---------|
| id | INT UNSIGNED PK | No | auto | Unique expense ID |
| trip_id | INT UNSIGNED FK | Yes | NULL | Group ID (NULL for personal) |
| type | ENUM | No | — | expense/income/settlement |
| amount | DECIMAL(12,2) | No | — | Total amount |
| description | VARCHAR(255) | No | — | Expense description |
| category_id | INT UNSIGNED FK | Yes | NULL | Category reference |
| paid_by | INT UNSIGNED FK | Yes | NULL | Who paid |
| received_by | INT UNSIGNED FK | Yes | NULL | Who received (income/settlement) |
| payment_method | ENUM | No | 'cash' | Payment method used |
| paid_from_pool | TINYINT(1) | No | 1 | Deducted from shared pool? |
| created_by | INT UNSIGNED FK | No | — | Who created the record |
| transaction_date | DATETIME | No | — | When expense occurred |
| notes | TEXT | Yes | NULL | Additional notes |
| client_request_id | VARCHAR(36) | Yes | NULL | Idempotency key |
| created_at | TIMESTAMP | No | NOW() | Record creation time |
| updated_at | TIMESTAMP | No | NOW() | Last update time |

### Database: `expense_splits`

| Field | Type | Nullable | Default | Purpose |
|-------|------|----------|---------|---------|
| id | INT UNSIGNED PK | No | auto | Unique split ID |
| transaction_id | INT UNSIGNED FK | No | — | Parent expense |
| user_id | INT UNSIGNED FK | No | — | Participant |
| amount | DECIMAL(12,2) | No | — | This user's share |
| created_at | TIMESTAMP | No | NOW() | Record creation time |

**Unique constraint**: (`transaction_id`, `user_id`) — one split per user per expense.

### Creation Process

```
Client sends expense creation request
  → Backend validates all fields
  → Backend validates splits sum = amount (F1 invariant)
  → Backend checks client_request_id for duplicates (F4)
  → Backend creates transaction record
  → Backend creates expense_splits records
  → Backend recalculates affected member balances
  → Backend returns success
```

### Categories

#### Global Default Categories

| ID | Name | Icon | Color |
|----|------|------|-------|
| 1 | Food & Drinks | utensils | #ef4444 |
| 2 | Hotel & Stay | bed | #8b5cf6 |
| 3 | Travel & Flights | plane | #3b82f6 |
| 4 | Local Transport | car | #06b6d4 |
| 5 | Tickets & Entry | ticket | #f59e0b |
| 6 | Shopping | shopping-bag | #ec4899 |
| 7 | Activities | camera | #10b981 |
| 8 | Fuel | fuel | #f97316 |
| 9 | Parking & Toll | parking | #64748b |
| 10 | General & Other | more-horizontal | #6b7280 |

#### Custom Categories

- Users can create custom categories per group
- Custom categories have: name, icon, color
- Custom categories appear alongside global categories
- Categories are shared across all members of a group

#### Category Selection Rules

| Rule | Value |
|------|-------|
| Required | Yes |
| Default | "General & Other" if not specified |
| Icon library | Lucide Icons |
| Color format | Hex (#rrggbb) |

---

## 2. Edit Expense

### Permissions

| Who Can Edit | Rule |
|-------------|------|
| Expense creator | Always |
| Group admin | Always |
| Group owner | Always |
| Other members | No |

### Editable Fields

All fields from creation are editable except:
- `client_request_id` (immutable after creation)
- `created_by` (immutable)
- `created_at` (immutable)

### Balance Recalculation

When an expense is edited:
1. Reverse the old splits from member balances
2. Apply the new splits to member balances
3. If the group pool is affected, recalculate pool balance

### API Endpoints

| Endpoint | Method | Action |
|----------|--------|--------|
| `api/expenses.php` | POST (action=update) | Update expense |

---

## 3. Delete Expense

### Permissions

| Who Can Delete | Rule |
|---------------|------|
| Expense creator | Always |
| Group admin | Always |
| Group owner | Always |
| Other members | No |

### Deletion Rules

| Rule | Value |
|------|-------|
| Cascade | Deletes associated expense_splits |
| Balance impact | Reverses splits from member balances |
| Pool impact | If paid from pool, restores amount to pool |
| Settlement impact | Does NOT auto-reverse settlements |
| Soft delete | Record marked as deleted, preserved for audit |

### API Endpoints

| Endpoint | Method | Action |
|----------|--------|--------|
| `api/transactions.php` | POST (action=delete) | Delete expense |

---

## 4. Expense List & Filtering

### Filter Options

| Filter | Type | Values |
|--------|------|--------|
| type | ENUM | all, expense, income, settlement |
| date_from | DATE | Start date |
| date_to | DATE | End date |
| category_id | INT | Category ID |
| paid_by | INT | User ID |
| min_amount | DECIMAL | Minimum amount |
| max_amount | DECIMAL | Maximum amount |
| search | VARCHAR | Text search in description |

### Sorting

| Sort | Default | Direction |
|------|---------|-----------|
| transaction_date | Yes | DESC (newest first) |
| amount | No | ASC or DESC |
| description | No | ASC |

### Pagination

| Parameter | Default | Max |
|-----------|---------|-----|
| page | 1 | — |
| per_page | 20 | 100 |

### API Endpoints

| Endpoint | Method | Action |
|----------|--------|--------|
| `api/transactions.php` | GET | List expenses with filters |

---

## 5. Pre-Trip vs During-Trip Expenses

### Pre-Trip Expenses

- Expenses created before the trip officially starts
- Update Splitwise balances (who owes whom)
- Do NOT deduct from the shared money pool
- `paid_from_pool = 0`

### During-Trip Expenses

- Expenses created during the trip
- Update Splitwise balances
- Deduct from the shared money pool
- `paid_from_pool = 1`

### Balance Impact Summary

| Expense Type | Splitwise Balances | Shared Pool |
|-------------|-------------------|-------------|
| Pre-trip expense | Adjusted | Not affected |
| During-trip expense | Adjusted | Deducted |
| Income | Adjusted (payer) | Added |
| Settlement | Adjusted | Not affected |

---

## 6. Receipt Attachment

### Rules

| Rule | Value |
|------|-------|
| Supported formats | JPG, PNG, PDF |
| Max file size | 5 MB |
| Storage | Local filesystem (configurable to S3) |
| OCR processing | Optional, via Tesseract |
| Access | Only group members can view |

### Upload Flow

```
User selects image/PDF
  → Frontend compresses if needed
  → Frontend uploads to backend
  → Backend stores file, creates receipt record
  → Backend optionally runs OCR
  → Backend returns receipt URL
  → Expense linked to receipt
```

---

## 7. Idempotency (F4)

### Client Request ID

- Every create/update request must include `client_request_id` (UUID v4)
- Server checks for existing record with same `client_request_id`
- If found: returns existing record (no new creation)
- If not found: creates new record

### Deduplication Scenarios

| Scenario | Protection |
|----------|-----------|
| Flutter offline retry | `client_request_id` prevents duplicate |
| WhatsApp message replay | `whatsapp_message_id` prevents duplicate |
| Network timeout retry | `client_request_id` prevents duplicate |
| Live sync race condition | `client_request_id` prevents duplicate |

---

## 8. Expense Response Format

```json
{
  "id": 45,
  "trip_id": 12,
  "type": "expense",
  "amount": 1500.00,
  "description": "Dinner at Hotel",
  "category": {
    "id": 1,
    "name": "Food & Drinks",
    "icon": "utensils",
    "color": "#ef4444"
  },
  "paid_by": {
    "id": 2,
    "name": "Akshat",
    "avatar_color": "#10b981"
  },
  "payment_method": "upi",
  "splits": [
    { "user_id": 1, "name": "Het", "amount": 500.00 },
    { "user_id": 2, "name": "Akshat", "amount": 500.00 },
    { "user_id": 3, "name": "Priya", "amount": 500.00 }
  ],
  "total_splits": 3,
  "transaction_date": "2026-08-24 19:30:00",
  "notes": "Had dinner at Lake View",
  "created_by": 2,
  "created_at": "2026-08-24 19:35:00"
}
```

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should expenses support recurring patterns (shared monthly bills)? | Feature scope |
| OQ-2 | Should we support multi-currency expenses within a single group? | Complexity |
| OQ-3 | Should expense creation support bulk entry (multiple expenses at once)? | UX |
| OQ-4 | Should there be an expense approval flow for large amounts? | Business rules |

---

## Dependencies

- `06-GROUPS.md` — Group membership, authorization
- `04-DESIGN-SYSTEM.md` — Expense screen components
- `05-AUTHENTICATION.md` — User identity

## Related Documents

- `08-SPLIT-METHODS.md` — Split calculation rules
- `09-SETTLEMENTS.md` — Settlement recording
- `10-PERSONAL-EXPENSES.md` — Personal expense module
- `20-DATABASE-SCHEMA.md` — transactions, expense_splits tables
- `21-API-SPECIFICATION.md` — Expense API endpoint details
- `18-RECEIPT-OCR.md` — Receipt processing
