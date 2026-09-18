# 12 — Analytics

This document specifies all analytics: personal, group, and combined. Every formula is explicitly defined.

---

## 1. Personal Analytics

### Income Total

```
monthly_income = SUM(transactions.amount)
  WHERE transactions.type = 'income'
  AND transactions.trip_id IS NULL
  AND transactions.created_by = user_id
  AND transactions.created_at >= month_start
  AND transactions.created_at < month_end
```

### Expense Total

```
monthly_expense = SUM(transactions.amount)
  WHERE transactions.type = 'expense'
  AND transactions.trip_id IS NULL
  AND transactions.created_by = user_id
  AND transactions.created_at >= month_start
  AND transactions.created_at < month_end
```

### Savings

```
savings = monthly_income - monthly_expense
savings_rate = (savings / monthly_income) × 100  // 0 if income = 0
```

### Category Breakdown

```sql
SELECT c.id, c.name, c.icon, c.color,
  SUM(t.amount) as total_amount,
  COUNT(t.id) as count,
  (SUM(t.amount) / @total_expense) × 100 as percentage
FROM transactions t
JOIN categories c ON c.id = t.category_id
WHERE t.trip_id IS NULL
  AND t.type = 'expense'
  AND t.created_by = user_id
  AND t.created_at BETWEEN @start AND @end
GROUP BY c.id
ORDER BY total_amount DESC
```

### Spending Trend (Last 6 Months)

```sql
SELECT DATE_FORMAT(created_at, '%Y-%m') as month,
  SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as expenses,
  SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as income
FROM transactions
WHERE trip_id IS NULL
  AND created_by = user_id
  AND created_at >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY month
ORDER BY month ASC
```

### Top Expenses

```sql
SELECT * FROM transactions
WHERE trip_id IS NULL
  AND type = 'expense'
  AND created_by = user_id
  AND created_at BETWEEN @start AND @end
ORDER BY amount DESC
LIMIT 10
```

### Monthly Comparison

```
month_over_month_change = ((current_month - previous_month) / previous_month) × 100
```

---

## 2. Group Analytics

### Total Group Expense

```
total_group_expense = SUM(transactions.amount)
  WHERE transactions.trip_id = group_id
  AND transactions.type = 'expense'
```

### Individual Contributions

```sql
SELECT u.id, u.name, u.avatar_color,
  SUM(t.amount) as total_paid
FROM transactions t
JOIN users u ON u.id = t.paid_by
WHERE t.trip_id = group_id
  AND t.type = 'expense'
GROUP BY u.id
ORDER BY total_paid DESC
```

### Individual Shares

```sql
SELECT u.id, u.name, u.avatar_color,
  SUM(es.amount) as total_share
FROM expense_splits es
JOIN users u ON u.id = es.user_id
JOIN transactions t ON t.id = es.transaction_id
WHERE t.trip_id = group_id
  AND t.type = 'expense'
GROUP BY u.id
ORDER BY total_share DESC
```

### Category Breakdown (Group)

```sql
SELECT c.id, c.name, c.icon, c.color,
  SUM(t.amount) as total_amount,
  COUNT(t.id) as count
FROM transactions t
JOIN categories c ON c.id = t.category_id
WHERE t.trip_id = group_id
  AND t.type = 'expense'
GROUP BY c.id
ORDER BY total_amount DESC
```

### Member Analytics

Per member in a group:
- Total paid
- Total share
- Net balance (F3 formula)
- Number of expenses created
- Average expense amount
- Most active category

### Settlement Analytics

```
total_settled = SUM(settlements.amount)
  WHERE settlements.trip_id = group_id
  AND settlements.status = 'paid'

pending_settlements = simplified_settlement_count
  (from calculateSimplifiedSettlements())
```

---

## 3. Combined Financial Picture

### Cross-Module Metrics

```json
{
  "personal": {
    "balance": 37500.00,
    "monthly_income": 50000.00,
    "monthly_expense": 12500.00
  },
  "groups": [
    {
      "group_id": 1,
      "group_name": "Goa Trip",
      "net_balance": 1200.00,
      "total_expenses": 15000.00
    }
  ],
  "overall": {
    "total_owed_to_you": 2500.00,
    "total_you_owe": 800.00,
    "net_position": 1700.00
  }
}
```

---

## 4. Chart Data Formats

### Donut Chart (Category Breakdown)

```json
{
  "labels": ["Food", "Transport", "Shopping"],
  "values": [5000, 3000, 2000],
  "colors": ["#ef4444", "#06b6d4", "#ec4899"],
  "total": 10000
}
```

### Bar Chart (Monthly Comparison)

```json
{
  "labels": ["Apr", "May", "Jun", "Jul", "Aug", "Sep"],
  "series": [
    { "name": "Income", "values": [48000, 50000, 50000, 52000, 50000, 50000] },
    { "name": "Expenses", "values": [15000, 12000, 18000, 11000, 14000, 12500] }
  ]
}
```

### Line Chart (Spending Trend)

```json
{
  "labels": ["Week 1", "Week 2", "Week 3", "Week 4"],
  "values": [3200, 2800, 4100, 2400]
}
```

---

## 5. Date Range Filters

| Preset | Start | End |
|--------|-------|-----|
| Today | CURDATE() | CURDATE() |
| This Week | Monday of current week | Sunday |
| This Month | 1st of current month | Last day |
| Last Month | 1st of previous month | Last day of previous |
| This Year | Jan 1 | Dec 31 |
| Custom | User-specified | User-specified |

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should analytics include spending predictions? | AI scope |
| OQ-2 | Should group analytics be visible to all members or only admins? | Permissions |
| OQ-3 | Should we support budget goals with alerts? | Feature scope |

---

## Dependencies

- `07-EXPENSES.md` — Expense data
- `10-PERSONAL-EXPENSES.md` — Personal finance data
- `09-SETTLEMENTS.md` — Settlement data

## Related Documents

- `03-SCREEN-SPECIFICATION.md` — Analytics screen spec
- `20-DATABASE-SCHEMA.md` — Data tables
- `21-API-SPECIFICATION.md` — Analytics API endpoints
