# 14 — Reports and Import/Export

This document specifies report generation, export formats, and data import capabilities.

---

## 1. Export Formats

### CSV Export

| Property | Value |
|----------|-------|
| Delimiter | Comma (,) |
| Encoding | UTF-8 with BOM |
| Date format | YYYY-MM-DD HH:mm:ss |
| Amount format | Raw decimal (no currency symbol) |
| Filename | `{type}_{group_name}_{date}.csv` |

### PDF Export

| Property | Value |
|----------|-------|
| Page size | A4 |
| Orientation | Portrait |
| Header | App logo, group name, date range |
| Sections | Summary, expense table, category breakdown |
| Footer | Page numbers, generation timestamp |

### Excel Export (Future)

| Property | Value |
|----------|-------|
| Format | .xlsx |
| Sheets | Summary, Expenses, Settlements |

---

## 2. Export Scope

### Personal Export

Includes:
- All personal expenses
- All personal income
- Category breakdown
- Monthly summary

### Group Export

Includes:
- All group expenses
- All settlements
- Member balances
- Category breakdown
- Summary statistics

---

## 3. Date and Category Filters

### Date Range

| Preset | Description |
|--------|-------------|
| All time | No date filter |
| This month | Current month |
| Last 3 months | Current + 2 previous |
| Last 6 months | Current + 5 previous |
| Custom | User-specified start/end |

### Category Filter

- Select specific categories or all
- Multiple selection supported

### API Endpoints

| Endpoint | Method | Action |
|----------|--------|--------|
| `api/export.php` | GET | Generate and download export |

---

## 4. Splitwise Import

### Supported Format

Splitwise CSV export columns:
- `date`, `description`, `amount`, `currency`, `group`, `added_by`, `split_by`, `category`

### Import Process

```
User uploads Splitwise CSV
  → System parses CSV
  → System validates columns
  → System maps:
    - Splitwise groups → TripBook groups
    - Splitwise users → TripBook users (by email/phone)
    - Splitwise categories → TripBook categories
  → System shows preview:
    "Found 45 expenses, 3 groups, 8 members"
  → User confirms import
  → System imports:
    - Creates groups if not exists
    - Maps users
    - Creates expenses with splits
    - Creates settlements
  → System shows summary:
    "Imported 45 expenses across 3 groups"
```

### Conflict Detection

| Conflict | Resolution |
|----------|-----------|
| Duplicate expense | Skip (check description + date + amount) |
| Unknown user | Create placeholder or skip |
| Unknown category | Map to "General" |
| Currency mismatch | Use group currency, log warning |

---

## 5. Tricount Import

### Status

Future support. Similar architecture to Splitwise import.

---

## 6. CSV Import

### Generic CSV Import

Users can import any CSV that contains:
- Amount column (required)
- Description column (required)
- Date column (required)
- Category column (optional)
- Payer column (optional)

### Mapping Interface

```
System shows column mapping:
  Column 1 → Amount ✓
  Column 2 → Description ✓
  Column 3 → Date ✓
  Column 4 → Category (skip)
  Preview: First 5 rows
```

---

## 7. Import Validation

| Rule | Value |
|------|-------|
| Max file size | 10 MB |
| Max rows | 10,000 |
| Required columns | Amount, Description, Date |
| Date formats | YYYY-MM-DD, DD/MM/YYYY, MM/DD/YYYY |
| Amount formats | Plain decimal, with currency symbol |

---

## 8. Rollback

### Import Rollback

If import fails or user cancels:
1. Delete all imported records
2. Restore previous state
3. Show "Import cancelled" confirmation

### Partial Import

If import partially fails:
1. Import successful records
2. Log failed records
3. Show "Imported X of Y records. Z failed."
4. Provide downloadable error log

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should exports include receipt images? | File size, storage |
| OQ-2 | Should we support JSON export for developer users? | Feature scope |
| OQ-3 | Should import support duplicate detection across all historical data? | Accuracy vs. performance |

---

## Dependencies

- `07-EXPENSES.md` — Expense data for export
- `06-GROUPS.md` — Group data for export
- `10-PERSONAL-EXPENSES.md` — Personal data for export

## Related Documents

- `03-SCREEN-SPECIFICATION.md` — Export screen spec
- `20-DATABASE-SCHEMA.md` — Data tables
- `21-API-SPECIFICATION.md` — Export API endpoints
- `28-ADMIN-PANEL.md` — Admin export capabilities
