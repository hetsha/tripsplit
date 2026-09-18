# 19 — Online Bill Import

This document specifies the extensible architecture for importing bills and invoices from online services.

---

## Architecture Principle

> The import system uses an **adapter pattern**. Each vendor integration is an independent adapter. Adding a new vendor does not affect existing integrations.

---

## 1. Import Methods

| Method | Description | Priority | Status |
|--------|-------------|----------|--------|
| Screenshot/PDF import | OCR-based extraction | P2 | Not started |
| Shared invoice import | Manual data entry from reference | P2 | Not started |
| Swiggy API | Official/partner API | P3 | Not started |
| Zomato API | Official/partner API | P3 | Not started |
| Blinkit API | Official/partner API | P3 | Not started |
| Zepto API | Official/partner API | P3 | Not started |

---

## 2. Vendor Adapter Interface

```php
interface VendorAdapter {
    public function getVendorName(): string;
    public function isAvailable(): bool;
    public function importOrder(string $referenceId): ?ImportedOrder;
    public function validateCredentials(): bool;
}
```

### ImportedOrder Schema

```json
{
  "vendor": "swiggy",
  "order_id": "SW123456",
  "date": "2026-09-15",
  "total": 450.00,
  "items": [
    { "name": "Paneer Tikka", "quantity": 1, "price": 300.00 },
    { "name": "Naan", "quantity": 2, "price": 60.00 }
  ],
  "tax": 22.50,
  "discount": 0.00,
  "delivery_fee": 30.00,
  "restaurant": "Hotel Lake View"
}
```

---

## 3. Screenshot/PDF Import

### Flow

```
User uploads screenshot/PDF
  → System runs OCR (Tesseract)
  → System extracts order data
  → System shows preview for review
  → User confirms or edits
  → System creates expense
```

### Supported Services (OCR-based)

| Service | Recognition |
|---------|-------------|
| Swiggy | Order ID, restaurant, items, total |
| Zomato | Order ID, restaurant, items, total |
| Blinkit | Store, items, total |
| Generic | Amount, merchant, date |

---

## 4. Shared Invoice Import

### Flow

```
User shares invoice via WhatsApp or upload
  → System receives image/PDF
  → System runs OCR
  → System extracts data
  → System creates expense with extracted data
```

---

## 5. Import Process

### Step 1: Upload

User provides:
- Screenshot, PDF, or order reference
- Optional: vendor selection

### Step 2: Parse

System:
- Runs OCR on image/PDF
- Extracts structured data
- Maps to expense fields

### Step 3: Validate

| Rule | Value |
|------|-------|
| Amount > 0 | Required |
| Date valid | Required |
| Merchant identifiable | Optional |

### Step 4: Preview

System shows:
- Original image
- Extracted data
- Mapped expense fields
- Edit capability

### Step 5: Confirm

User confirms:
- Data accuracy
- Group assignment
- Split method
- Category

### Step 6: Save

System:
- Creates expense
- Attaches receipt image
- Stores OCR data

---

## 6. Conflict Detection

| Conflict | Resolution |
|----------|-----------|
| Duplicate order | Skip (check vendor + order_id) |
| Amount mismatch | Show warning, user decides |
| Unknown vendor | Use generic extraction |

---

## 7. Vendor Integration Architecture

### Adding a New Vendor

1. Create adapter class implementing `VendorAdapter`
2. Register in vendor registry
3. Add to import UI options
4. Test with sample data

### Vendor Registry

```php
$vendors = [
    'swiggy' => SwiggyAdapter::class,
    'zomato' => ZomatoAdapter::class,
    'blinkit' => BlinkitAdapter::class,
    // Add new vendors here
];
```

---

## 8. Database: `imported_bills`

| Field | Type | Purpose |
|-------|------|---------|
| id | INT UNSIGNED PK | Import ID |
| user_id | INT UNSIGNED FK | Importer |
| vendor | VARCHAR(50) | Vendor name |
| order_id | VARCHAR(100) | Vendor order ID |
| raw_data | JSON | Original OCR/API data |
| mapped_data | JSON | Mapped expense fields |
| expense_id | INT UNSIGNED FK | Created expense |
| status | ENUM | pending/imported/failed |
| created_at | TIMESTAMP | Import time |

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should we support official APIs for Swiggy/Zomato? | API access, cost |
| OQ-2 | Should imported bills auto-create expenses? | Automation scope |
| OQ-3 | Should we support recurring order imports? | Feature scope |

---

## Dependencies

- `07-EXPENSES.md` — Expense creation from imported data
- `18-RECEIPT-OCR.md` — OCR processing
- `22-BACKEND-ARCHITECTURE.md` — Vendor adapter system

## Related Documents

- `07-EXPENSES.md` — Expense creation
- `18-RECEIPT-OCR.md` — OCR processing
- `20-DATABASE-SCHEMA.md` — imported_bills table
- `19-ONLINE-BILL-IMPORT.md` — This document
