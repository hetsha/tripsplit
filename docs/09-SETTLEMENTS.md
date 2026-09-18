# 09 — Settlements

This document specifies how balances are calculated, how debts are simplified, and how settlements are recorded.

---

## Financial Invariants

### F2 — Settlement = Actual Recorded Transfer

> A settlement record represents a real-world payment. It does NOT create new debt or modify expense records. It only adjusts balances.

The app RECORDS that "User A paid User B ₹500 via UPI." It does NOT process the UPI transaction.

### F3 — Group Balance Formula

> **net_balance = total_paid - total_share - settlements_received + settlements_sent**

Where:
- `total_paid` = sum of all expense amounts this user paid for the group
- `total_share` = sum of this user's shares in all group expenses
- `settlements_received` = sum of settlements this user received from others
- `settlements_sent` = sum of settlements this user sent to others

**Interpretation**:
- Positive balance → user is **owed money** (creditor)
- Negative balance → user **owes money** (debtor)
- Zero balance → **settled up**

---

## 1. Balance Calculation

### Per-User Balance

For each member in a group:

```
total_paid = SUM(expenses.paid_by = user_id)
total_share = SUM(expense_splits.user_id = user_id)
settlements_sent = SUM(settlements.from_user = user_id AND status = 'paid')
settlements_received = SUM(settlements.to_user = user_id AND status = 'paid')

net_balance = (total_paid - total_share) - settlements_received + settlements_sent
```

### Example

Group: 3 members, ₹1,500 expense paid by A, split equally.

| Member | Total Paid | Total Share | Settlements Sent | Settlements Received | Net Balance |
|--------|-----------|-------------|-----------------|---------------------|-------------|
| A | ₹1,500 | ₹500 | ₹0 | ₹0 | +₹1,000 (owed) |
| B | ₹0 | ₹500 | ₹0 | ₹0 | -₹500 (owes) |
| C | ₹0 | ₹500 | ₹0 | ₹0 | -₹500 (owes) |

After B pays A ₹500:

| Member | Total Paid | Total Share | Settlements Sent | Settlements Received | Net Balance |
|--------|-----------|-------------|-----------------|---------------------|-------------|
| A | ₹1,500 | ₹500 | ₹0 | ₹500 | +₹500 |
| B | ₹0 | ₹500 | ₹500 | ₹0 | ₹0 (settled) |
| C | ₹0 | ₹500 | ₹0 | ₹0 | -₹500 |

---

## 2. Debt Simplification Algorithm

### Purpose

Minimize the total number of transactions needed to settle all debts.

### Algorithm (Greedy)

```
1. Calculate net_balance for all members
2. Separate into:
   - debtors: users with negative balance (owe money)
   - creditors: users with positive balance (are owed money)
3. Sort debtors by amount descending
4. Sort creditors by amount descending
5. While both lists non-empty:
   a. Take largest debtor and largest creditor
   b. settle_amount = min(debtor_amount, creditor_amount)
   c. Record: debtor → creditor, settle_amount
   d. Reduce both amounts by settle_amount
   e. Remove from list if amount reaches 0
```

### Example

4 members with balances:
- A: +₹800 (owed)
- B: +₹200 (owed)
- C: -₹600 (owes)
- D: -₹400 (owes)

Algorithm:
1. C owes ₹600, A is owed ₹800 → C pays A ₹600
2. D owes ₹400, A is owed ₹200 → D pays A ₹200
3. D still owes ₹200, B is owed ₹200 → D pays B ₹200

Result: 3 transactions (optimal for this scenario)

### Implementation

Located in `includes/calculations.php`:
- `getSplitwiseBalances($tripId)` — calculates F3 for all members
- `calculateSimplifiedSettlements($tripId)` — greedy algorithm

---

## 3. Record Settlement

### Rules

| Rule | Value |
|------|-------|
| Who can record | Any member involved in the settlement |
| Amount | Must be > 0, max 2 decimals |
| Payment method | Cash, UPI, Card, Bank, Other |
| Partial allowed | Yes — amount can be less than full debt |
| Notes | Optional text |
| Status | `paid` (recorded) or `pending` (requested) |

### Database: `settlements`

| Field | Type | Nullable | Default | Purpose |
|-------|------|----------|---------|---------|
| id | INT UNSIGNED PK | No | auto | Unique settlement ID |
| trip_id | INT UNSIGNED FK | No | — | Group ID |
| transaction_id | INT UNSIGNED FK | Yes | NULL | Linked transaction (if any) |
| from_user | INT UNSIGNED FK | No | — | Who paid |
| to_user | INT UNSIGNED FK | No | — | Who received |
| amount | DECIMAL(12,2) | No | — | Amount paid |
| payment_method | ENUM | No | 'upi' | How it was paid |
| status | ENUM | No | 'paid' | paid/pending |
| notes | TEXT | Yes | NULL | Additional notes |
| paid_at | DATETIME | No | — | When payment was made |
| created_at | TIMESTAMP | No | NOW() | Record creation time |

### Balance Impact

When settlement is recorded:
1. `from_user`'s `settlements_sent` increases by amount
2. `to_user`'s `settlements_received` increases by amount
3. Both users' `net_balance` is recalculated per F3

### API Endpoints

| Endpoint | Method | Action |
|----------|--------|--------|
| `api/settlements.php` | POST (action=settle) | Record settlement |
| `api/settlements.php` | GET (action=suggestions) | Get simplified settlements |
| `api/settlements.php` | GET (action=history) | Get settlement history |
| `api/settlements.php` | POST (action=undo) | Undo settlement |

---

## 4. Partial Settlement

### Description

A user can pay part of their debt. The remaining balance stays until fully settled.

### Example

B owes A ₹1,000:
- B pays A ₹400 (partial)
- B still owes A ₹600
- Simplified settlements update to reflect new balance

### Validation

| Rule | Value |
|------|-------|
| Amount > 0 | Yes |
| Amount ≤ remaining debt | Yes (error if exceeds) |
| Multiple partials | Allowed |

---

## 5. Settlement History

### Response Format

```json
{
  "settlements": [
    {
      "id": 1,
      "from_user": {
        "id": 2,
        "name": "B"
      },
      "to_user": {
        "id": 1,
        "name": "A"
      },
      "amount": 500.00,
      "payment_method": "upi",
      "status": "paid",
      "paid_at": "2026-08-25 14:30:00",
      "notes": "Settled dinner debt"
    }
  ]
}
```

---

## 6. Undo Settlement

### Rules

| Rule | Value |
|------|-------|
| Who can undo | The user who recorded the settlement |
| Time limit | Within 24 hours (configurable) |
| Effect | Reverses balance adjustment |
| Audit | Undo is logged in audit trail |

### API Endpoints

| Endpoint | Method | Action |
|----------|--------|--------|
| `api/settlements.php` | POST (action=undo) | Undo settlement |

---

## 7. Settlement Visualization

### Who Owes Whom

Display as directed graph:
- Nodes: group members
- Edges: arrows from debtor to creditor with amount
- Color: red for debtor, green for creditor

### Simplified View

List format:
```
C → A: ₹600
D → A: ₹200
D → B: ₹200
```

---

## 8. Edge Cases

| Case | Behavior |
|------|----------|
| All settled (all balances = 0) | "All settled up! No payments needed." |
| One person owes everyone | Simple 1:N settlements |
| Everyone owes one person | Simple N:1 settlements |
| Circular debts | Simplified by algorithm (A→B, B→C, C→A → net out) |
| Very small amounts (< ₹1) | Treated as settled (threshold: ₹0.01) |
| Settlement after member removed | Allowed, balances preserved |
| Settlement with wrong payment method | Can be edited within time limit |

---

## 9. WhatsApp Settlement Flow

```
User: "Rahul ko 500 de diya"
  → System parses: amount=500, to_user=Rahul
  → System identifies active group
  → System checks remaining debt to Rahul
  → Decision: Amount ≤ remaining debt?
    → YES: Record settlement
    → NO: "You only owe Rahul ₹{remaining}. Record ₹{remaining} instead?"
  → System records settlement
  → System: "✅ Recorded! You paid Rahul ₹500 via cash."
```

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should UPI deep-linking be supported for 1-tap settlement? | Payment integration scope |
| OQ-2 | Should settlements support recurring patterns (monthly rent)? | Feature scope |
| OQ-3 | Should we support multi-currency settlements? | Exchange rate complexity |
| OQ-4 | Should settlement records include payment proof (screenshot)? | Feature scope |

---

## Dependencies

- `07-EXPENSES.md` — Expenses that create debts
- `08-SPLIT-METHODS.md` — How expenses are split
- `06-GROUPS.md` — Group membership

## Related Documents

- `07-EXPENSES.md` — Expenses
- `08-SPLIT-METHODS.md` — Split calculations
- `12-ANALYTICS.md` — Settlement analytics
- `20-DATABASE-SCHEMA.md` — settlements table
- `21-API-SPECIFICATION.md` — Settlement API endpoints
- `16-WHATSAPP-CONVERSATION-FLOWS.md` — WhatsApp settlement flow
