# 08 — Split Methods

This document specifies all supported expense split methods, their calculation rules, validation, rounding behavior, and edge cases.

---

## Financial Invariant F1

> **expense_total = Σ(participant_shares)**

This invariant must hold for every split method. The backend validates this before saving.

---

## Supported Split Methods

| Method | Description | Priority | Status |
|--------|-------------|----------|--------|
| Equal | Divide equally among participants | P0 | Implemented |
| Exact | Each participant pays a specific amount | P1 | Implemented |
| Percentage | Each participant pays a percentage of total | P2 | Not started |
| Shares | Each participant pays based on ratio/shares | P2 | Not started |
| Item-wise | Split by individual items on the bill | P3 | Not started |

---

## 1. Equal Split

### Description

The total amount is divided equally among all selected participants.

### Calculation

```
share_per_person = total_amount / number_of_participants
```

### Example

₹1,500 split among 3 people:
- A = ₹500.00
- B = ₹500.00
- C = ₹500.00
- Verification: ₹500 + ₹500 + ₹500 = ₹1,500 ✓

### Rounding Rules

When the amount doesn't divide evenly:

```
₹1,000 split among 3 people:
  share = 1000 / 3 = 333.333...
  → A = ₹333.34 (largest share gets the rounding remainder)
  → B = ₹333.33
  → C = ₹333.33
  → Verification: ₹333.34 + ₹333.33 + ₹333.33 = ₹1,000.00 ✓
```

**Rounding algorithm**:
1. Calculate `base_share = floor(total / count)` to 2 decimals
2. Calculate `remainder = total - (base_share × count)`
3. Distribute remainder (in smallest currency unit) to the first N participants
4. For INR: smallest unit is ₹0.01 (1 paisa)

### Edge Cases

| Case | Behavior |
|------|----------|
| 1 participant | Full amount assigned to that person |
| 0 participants | Error: "At least one participant required" |
| Participant is payer | Included in split (pays their own share) |
| Amount = ₹0 | Error: "Amount must be greater than 0" |
| Very large amount | Works with DECIMAL(12,2) precision |

### UI

- Default split method
- Shows: "Split equally among N people"
- Displays per-person amount prominently
- Allows removing/adding participants (recalculates automatically)

### Input

```json
{
  "split_method": "equal",
  "participant_ids": [1, 2, 3]
}
```

### Output (splits array)

```json
[
  { "user_id": 1, "amount": 500.00 },
  { "user_id": 2, "amount": 500.00 },
  { "user_id": 3, "amount": 500.00 }
]
```

---

## 2. Exact Amount Split

### Description

Each participant is assigned a specific amount. The sum must equal the total.

### Validation

| Rule | Value |
|------|-------|
| Sum of amounts | Must equal total expense amount |
| Each amount | ≥ 0, max 2 decimals |
| Minimum participants | 1 |
| Maximum participants | Same as group size |

### Example

₹1,500 with exact amounts:
- A = ₹600.00
- B = ₹400.00
- C = ₹500.00
- Verification: ₹600 + ₹400 + ₹500 = ₹1,500 ✓

### Validation Algorithm

```
sum = Σ(all_user_amounts)
if sum != total_amount:
    error = "Split amounts (₹{sum}) don't match total (₹{total}). Difference: ₹{abs(total - sum)}"
```

### Edge Cases

| Case | Behavior |
|------|----------|
| Sum ≠ total | Error with exact difference shown |
| Sum < total | "You need to allocate ₹{difference} more" |
| Sum > total | "You've allocated ₹{difference} too much" |
| One person gets full amount | Allowed (others get ₹0) |
| Negative amount | Error: "Amount cannot be negative" |

### UI

- Input fields for each participant
- Running total display: "Allocated: ₹1,500 / ₹1,500"
- Color indicator: Red if mismatch, green if matched
- Auto-assign remainder button

### Input

```json
{
  "split_method": "exact",
  "splits": [
    { "user_id": 1, "amount": 600.00 },
    { "user_id": 2, "amount": 400.00 },
    { "user_id": 3, "amount": 500.00 }
  ]
}
```

---

## 3. Percentage Split

### Description

Each participant pays a percentage of the total. Percentages must sum to 100%.

### Calculation

```
share = (percentage / 100) × total_amount
```

### Validation

| Rule | Value |
|------|-------|
| Sum of percentages | Must equal 100.00% |
| Each percentage | 0-100%, max 2 decimal places |
| Rounding | Applied to ensure sum = total |

### Example

₹1,500 with percentages:
- A = 40% → ₹600.00
- B = 35% → ₹525.00
- C = 25% → ₹375.00
- Verification: ₹600 + ₹525 + ₹375 = ₹1,500 ✓
- Percentage check: 40 + 35 + 25 = 100% ✓

### Rounding

Same algorithm as Equal split — largest share absorbs rounding remainder.

### Edge Cases

| Case | Behavior |
|------|----------|
| Percentages ≠ 100% | Error: "Percentages must sum to 100%" |
| One person = 100% | Full amount assigned to that person |
| 0% for someone | Allowed (effectively removes from split) |

### UI

- Slider or input for each participant's percentage
- Running total: "Total: 100%" with color indicator
- Real-time amount preview per person

### Input

```json
{
  "split_method": "percentage",
  "splits": [
    { "user_id": 1, "percentage": 40.00 },
    { "user_id": 2, "percentage": 35.00 },
    { "user_id": 3, "percentage": 25.00 }
  ]
}
```

---

## 4. Shares/Ratio Split

### Description

Each participant is assigned a number of shares. The amount is divided proportionally based on shares.

### Calculation

```
total_shares = Σ(all_shares)
share_per_unit = total_amount / total_shares
user_share = user_shares × share_per_unit
```

### Example

₹1,500 with shares:
- A = 3 shares
- B = 2 shares
- C = 1 share
- Total shares = 6
- Value per share = ₹1,500 / 6 = ₹250
- A = 3 × ₹250 = ₹750.00
- B = 2 × ₹250 = ₹500.00
- C = 1 × ₹250 = ₹250.00
- Verification: ₹750 + ₹500 + ₹250 = ₹1,500 ✓

### Validation

| Rule | Value |
|------|-------|
| Minimum total shares | 1 |
| Each share count | ≥ 1 (integer) |
| Rounding | Largest share absorbs remainder |

### Edge Cases

| Case | Behavior |
|------|----------|
| All same shares | Equal split |
| One person has all shares | Full amount to that person |
| Very uneven shares | Works correctly with decimal calculation |

### UI

- Increment/decrement buttons for each participant's shares
- Shows real-time amount preview
- Shows ratio visualization (e.g., "3:2:1")

### Input

```json
{
  "split_method": "shares",
  "splits": [
    { "user_id": 1, "shares": 3 },
    { "user_id": 2, "shares": 2 },
    { "user_id": 3, "shares": 1 }
  ]
}
```

---

## 5. Item-Wise Split

### Description

Individual items on a bill are assigned to specific participants. Each person pays for the items they consumed.

### Data Model

In addition to the main expense, item-wise splits use `expense_items` and `expense_item_splits` tables.

#### Database: `expense_items`

| Field | Type | Purpose |
|-------|------|---------|
| id | INT UNSIGNED PK | Item ID |
| expense_id | INT UNSIGNED FK | Parent expense |
| name | VARCHAR(255) | Item name (e.g., "Paneer Tikka") |
| quantity | INT | Quantity |
| unit_price | DECIMAL(12,2) | Price per unit |
| total_price | DECIMAL(12,2) | quantity × unit_price |

#### Database: `expense_item_splits`

| Field | Type | Purpose |
|-------|------|---------|
| id | INT UNSIGNED PK | Split ID |
| item_id | INT UNSIGNED FK | Parent item |
| user_id | INT UNSIGNED FK | Participant |
| amount | DECIMAL(12,2) | This user's share of this item |

### Validation

| Rule | Value |
|------|-------|
| Items required | At least 1 item |
| Item splits sum | Must equal item total_price |
| Expense total | Must equal sum of all item total_prices |
| Each item | Has at least 1 participant |

### Example

Restaurant bill:
- Item 1: Paneer Tikka × 1 = ₹300 → Split between A and B (₹150 each)
- Item 2: Naan × 2 = ₹120 → A only (₹120)
- Item 3: Coke × 3 = ₹150 → All three (₹50 each)

Totals:
- A = ₹150 + ₹120 + ₹50 = ₹320
- B = ₹150 + ₹0 + ₹50 = ₹200
- C = ₹0 + ₹0 + ₹50 = ₹50
- Expense total = ₹300 + ₹120 + ₹150 = ₹570
- Verification: ₹320 + ₹200 + ₹50 = ₹570 ✓

### Edge Cases

| Case | Behavior |
|------|----------|
| Item with no participants | Error: "Each item must have at least one participant" |
| Shared item, uneven split | Allowed (exact amounts per item) |
| Tax/tip distribution | Added as separate item, split equally or by ratio |
| Discount applied | Reduces total, proportional adjustment |

### UI

- Item list with name, quantity, price
- Per-item participant selector
- Running total per participant
- Grand total validation

### Input

```json
{
  "split_method": "item-wise",
  "items": [
    {
      "name": "Paneer Tikka",
      "quantity": 1,
      "unit_price": 300.00,
      "splits": [
        { "user_id": 1, "amount": 150.00 },
        { "user_id": 2, "amount": 150.00 }
      ]
    },
    {
      "name": "Naan",
      "quantity": 2,
      "unit_price": 60.00,
      "splits": [
        { "user_id": 1, "amount": 120.00 }
      ]
    }
  ]
}
```

---

## Split Method Comparison

| Feature | Equal | Exact | Percentage | Shares | Item-wise |
|---------|-------|-------|------------|--------|-----------|
| Complexity | Low | Medium | Medium | Medium | High |
| Input required | Participants | Amounts | Percentages | Share counts | Items + participants |
| Validation | Sum = total | Sum = total | Sum = 100% | Shares > 0 | Items + splits |
| Common use | Most expenses | Custom splits | Recurring bills | Uneven contributions | Restaurant bills |
| Rounding | Auto | N/A | Auto | Auto | Per item |

---

## Backend Calculation Responsibility

The backend MUST:
1. Validate that splits sum equals expense total (F1 invariant)
2. Apply rounding to ensure exact equality
3. Never trust client-side calculations
4. Recalculate on every edit

The backend MUST NOT:
1. Allow splits that don't sum to the total
2. Trust client-provided split amounts without validation
3. Skip rounding validation

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should item-wise splits support shared items (one item, multiple people)? | Already supported, confirm UX |
| OQ-2 | Should percentage split allow "remainder" assignment (last person gets whatever's left)? | Edge case UX |
| OQ-3 | Should we support mixed split methods within a single expense? | Complexity vs. flexibility |

---

## Dependencies

- `07-EXPENSES.md` — Expense creation, F1 invariant definition
- `04-DESIGN-SYSTEM.md` — Split method UI components

## Related Documents

- `07-EXPENSES.md` — Expense lifecycle
- `09-SETTLEMENTS.md` — How splits affect balances
- `12-ANALYTICS.md` — Split analytics
- `20-DATABASE-SCHEMA.md` — expense_splits, expense_items, expense_item_splits tables
- `21-API-SPECIFICATION.md` — Split validation in API
