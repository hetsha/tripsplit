# 10 — Personal Expenses

This document specifies the Personal Expense module. Personal expenses are a **first-class financial module** — they are NOT simulated via fake groups. They track an individual's income, expenses, and financial health independently of any shared group.

---

## Design Principle

> Personal expenses are stored with `trip_id = NULL` in the `transactions` table. They are a distinct use case from group expenses, not a workaround.

---

## 1. Personal Expense Types

| Type | Description | Impact on Balance |
|------|-------------|------------------|
| `expense` (personal) | Money spent by the user | Decreases balance |
| `income` (personal) | Money received by the user | Increases balance |

### Balance Formula

```
personal_balance = total_income - total_expenses
```

---

## 2. Add Personal Expense

### Required Fields

| Field | Type | Validation |
|-------|------|------------|
| amount | DECIMAL(12,2) | > 0, max 2 decimals |
| description | VARCHAR(255) | Required, 1-255 characters |
| category_id | INT | Must exist in categories (personal or global) |
| payment_method | ENUM | cash, upi, card, bank, other |

### Optional Fields

| Field | Type | Default |
|-------|------|---------|
| transaction_date | DATETIME | NOW() |
| notes | TEXT | NULL |
| receipt_image | FILE | NULL |

### Database Representation

```sql
INSERT INTO transactions (trip_id, type, amount, description, category_id, 
  paid_by, payment_method, created_by, transaction_date)
VALUES (NULL, 'expense', 500.00, 'Groceries', 1, 1, 'upi', 1, NOW());
```

Key: `trip_id = NULL` distinguishes personal from group expenses.

### API Endpoints

| Endpoint | Method | Action |
|----------|--------|--------|
| `api/cashbook.php` | POST | Add personal expense/income (**LEGACY** — will be replaced by `api/personal-finance.php`) |
| `api/expenses.php` | POST (is_personal=true) | Add personal expense |

---

## 3. Add Personal Income

### Required Fields

| Field | Type | Validation |
|-------|------|------------|
| amount | DECIMAL(12,2) | > 0 |
| description | VARCHAR(255) | Required |
| payment_method | ENUM | cash, upi, card, bank, other |

### Income Categories

| Category | Description |
|----------|-------------|
| Salary | Regular employment income |
| Freelance | Freelance/contract work |
| Gift | Gift received |
| Refund | Money refunded |
| Other | Miscellaneous income |

### Database Representation

```sql
INSERT INTO transactions (trip_id, type, amount, description, 
  received_by, payment_method, created_by, transaction_date)
VALUES (NULL, 'income', 50000.00, 'Monthly Salary', 1, 'bank', 1, NOW());
```

---

## 4. Personal Categories

### Default Personal Categories

| ID | Name | Icon | Color | Type |
|----|------|------|-------|------|
| 101 | Food & Dining | utensils | #ef4444 | expense |
| 102 | Transportation | car | #06b6d4 | expense |
| 103 | Shopping | shopping-bag | #ec4899 | expense |
| 104 | Entertainment | film | #8b5cf6 | expense |
| 105 | Bills & Utilities | zap | #f59e0b | expense |
| 106 | Health | heart | #10b981 | expense |
| 107 | Education | book-open | #3b82f6 | expense |
| 108 | Personal Care | sparkles | #d946ef | expense |
| 109 | Home | home | #64748b | expense |
| 110 | Other | more-horizontal | #6b7280 | expense |
| 201 | Salary | briefcase | #10b981 | income |
| 202 | Freelance | coffee | #8b5cf6 | income |
| 203 | Gift | gift | #ec4899 | income |
| 204 | Refund | rotate-ccw | #06b6d4 | income |
| 205 | Other Income | more-horizontal | #6b7280 | income |

### Custom Categories

- Users can create custom personal categories
- Categories have: name, icon, color, type (expense/income)
- Custom categories are personal (not shared across users)

---

## 5. Transaction History

### Personal Transaction Ledger

The personal transaction history shows all income and expenses with a running balance.

### Response Format

```json
{
  "user_id": 1,
  "currency_symbol": "₹",
  "total_in": 50000.00,
  "total_out": 12500.00,
  "net_outflow": 37500.00,
  "in_by_method": {
    "bank": 50000.00,
    "cash": 0.00,
    "upi": 0.00
  },
  "out_by_method": {
    "upi": 4500.00,
    "cash": 2500.00,
    "card": 2000.00
  },
  "entries": [
    {
      "type": "in",
      "flow_type": "income",
      "amount": 50000.00,
      "description": "Monthly Salary",
      "payment_method": "bank",
      "date": "2026-09-01 10:00:00",
      "category_name": "Salary",
      "category_icon": "briefcase"
    },
    {
      "type": "out",
      "flow_type": "expense",
      "amount": 2500.00,
      "description": "Groceries",
      "payment_method": "upi",
      "date": "2026-09-05 18:30:00",
      "category_name": "Food & Dining",
      "category_icon": "utensils"
    }
  ]
}
```

### Transaction Entry Types

| flow_type | Description |
|-----------|-------------|
| `income` | Money received |
| `expense` | Money spent |
| `settlement_received` | Received settlement from group member |
| `settlement_sent` | Sent settlement to group member |

---

## 6. Monthly Summary

### Metrics

| Metric | Formula |
|--------|---------|
| Monthly Income | SUM(income transactions in month) |
| Monthly Expense | SUM(expense transactions in month) |
| Savings | Monthly Income - Monthly Expense |
| Savings Rate | (Savings / Monthly Income) × 100 |
| Top Category | Category with highest spending |
| Transaction Count | COUNT(transactions in month) |

### Response Format

```json
{
  "month": "2026-09",
  "income": 50000.00,
  "expenses": 12500.00,
  "savings": 37500.00,
  "savings_rate": 75.0,
  "top_category": {
    "name": "Food & Dining",
    "amount": 5000.00
  },
  "transaction_count": 28
}
```

---

## 7. Income vs Expense View

### Visualization

- Bar chart: Monthly income (green) vs expense (red)
- Line chart: Savings trend over time
- Donut chart: Category breakdown of expenses

### Data

Last 6 months comparison:

```json
{
  "months": [
    { "month": "2026-04", "income": 48000, "expenses": 15000 },
    { "month": "2026-05", "income": 50000, "expenses": 12000 },
    { "month": "2026-06", "income": 50000, "expenses": 18000 },
    { "month": "2026-07", "income": 52000, "expenses": 11000 },
    { "month": "2026-08", "income": 50000, "expenses": 14000 },
    { "month": "2026-09", "income": 50000, "expenses": 12500 }
  ]
}
```

---

## 8. Spending Trends

### Metrics

| Metric | Description |
|--------|-------------|
| Daily average | Monthly expense / days in month |
| Weekly trend | Expense per week |
| Category trend | Spending per category over time |
| Month-over-month | % change from previous month |

---

## 9. Category Analytics (Personal)

### Per-Category Breakdown

```json
{
  "categories": [
    {
      "id": 101,
      "name": "Food & Dining",
      "icon": "utensils",
      "color": "#ef4444",
      "total_amount": 5000.00,
      "percentage": 40.0,
      "transaction_count": 15,
      "average_per_transaction": 333.33
    }
  ]
}
```

### Top Categories

Sorted by total amount descending. Shows top 5 or all if fewer.

---

## 10. Search & Filter

### Filter Options

| Filter | Type | Values |
|--------|------|--------|
| type | ENUM | all, expense, income |
| date_from | DATE | Start date |
| date_to | DATE | End date |
| category_id | INT | Category ID |
| min_amount | DECIMAL | Minimum amount |
| max_amount | DECIMAL | Maximum amount |
| payment_method | ENUM | cash, upi, card, bank, other |
| search | VARCHAR | Text search in description |

### API Endpoints

| Endpoint | Method | Action |
|----------|--------|--------|
| `api/cashbook.php` | GET | List personal transactions with filters (**LEGACY** — will be replaced by `api/personal-finance.php`) |
| `api/transactions.php` | GET (trip_id=NULL) | List personal transactions |

---

## 11. Recurring Personal Expenses

### Use Case

Track regular personal bills: rent, utilities, subscriptions.

### Rules

| Rule | Value |
|------|-------|
| Recurrence patterns | Daily, Weekly, Monthly, Yearly, Custom |
| Auto-create | Optional — auto-add to transaction list on due date |
| Reminder | Optional — notify before due date |
| Linked to bills | Can be linked to Bills & Reminders module (11) |

See `11-BILLS-AND-REMINDERS.md` for detailed recurring bill specification.

---

## 12. Receipt Attachment

### Rules

| Rule | Value |
|------|-------|
| Supported formats | JPG, PNG, PDF |
| Max file size | 5 MB |
| Storage | Local filesystem |
| Access | Only the user |

### OCR Integration

When receipt is attached:
1. System runs OCR (Tesseract)
2. Extracts: merchant, date, total, items
3. Pre-fills expense form with extracted data
4. User reviews and confirms

See `18-RECEIPT-OCR.md` for OCR processing details.

---

## 13. Running Balance (Personal)

### Purpose

Track the user's cash flow across all personal financial activities.

### Components

| Component | Type | Description |
|-----------|------|-------------|
| Starting balance | Amount | Balance at beginning of period |
| Income | +Amount | Money received |
| Expenses | -Amount | Money spent |
| Settlements received | +Amount | Money received from settlements |
| Settlements sent | -Amount | Money sent as settlements |
| Running total | Amount | Cumulative balance |

### API Endpoints

| Endpoint | Method | Action |
|----------|--------|--------|
| `api/cashbook.php` | GET | Get full cashbook ledger (**LEGACY** — will be replaced by `api/personal-finance.php`) |
| `api/passbook.php` | GET | Get bank-style passbook view |

---

## 14. Personal vs Group Expense Distinction

| Aspect | Personal Expense | Group Expense |
|--------|-----------------|---------------|
| trip_id | NULL | Group ID |
| Splits | None | One or more participants |
| Balance impact | Personal balance only | Group member balances |
| Pool impact | None | Deducts from group pool (if during-trip) |
| Visibility | Only the user | All group members |
| Categories | Personal categories | Group categories |

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should personal expenses be exportable in group reports? | Report scope |
| OQ-2 | Should there be a "transfer to group" action (personal → group)? | UX flow |
| OQ-3 | Should personal income support recurring patterns? | Feature scope |
| OQ-4 | Should personal analytics include budget goals? | Feature scope |

---

## Dependencies

- `05-AUTHENTICATION.md` — User identity
- `04-DESIGN-SYSTEM.md` — Personal finance screen components
- `07-EXPENSES.md` — Expense data model

## Related Documents

- `07-EXPENSES.md` — Shared expense module
- `11-BILLS-AND-REMINDERS.md` — Recurring personal bills
- `12-ANALYTICS.md` — Personal analytics formulas
- `18-RECEIPT-OCR.md` — Receipt processing
- `20-DATABASE-SCHEMA.md` — transactions table (trip_id=NULL)
- `21-API-SPECIFICATION.md` — Cashbook API endpoints
