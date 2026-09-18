# 01 — Features

This document is the complete inventory of every feature in TripBook. Each feature is classified by module, priority, platform support, and implementation status.

---

## Feature Priority Levels

| Priority | Meaning |
|----------|---------|
| **P0** | Must-have for launch. App is broken without it. |
| **P1** | Should-have for launch. Core user value. |
| **P2** | Important but can launch without it. Fast-follow. |
| **P3** | Nice to have. Future iteration. |

---

## Platform Availability

| Code | Platform |
|------|----------|
| W | Web Application |
| A | Flutter Android App |
| WA | WhatsApp Interface |
| B | Backend (API) |
| Admin | Admin Panel |

---

## 1. Authentication & User Management

| # | Feature | Priority | Platforms | Status | Spec |
|---|---------|----------|-----------|--------|------|
| 1.1 | Phone OTP login | P0 | W, A, B | Implemented | `05-AUTHENTICATION.md` |
| 1.2 | Google OAuth login | P1 | W, A, B | Partially implemented | `05-AUTHENTICATION.md` |
| 1.3 | Email OTP login | P2 | W, B | Partially implemented | `05-AUTHENTICATION.md` |
| 1.4 | User registration (name, phone/email) | P0 | W, A, B | Implemented | `05-AUTHENTICATION.md` |
| 1.5 | Profile editing (name, email, avatar) | P1 | W, A, B | Not started | `05-AUTHENTICATION.md` |
| 1.6 | Profile photo/avatar color | P2 | W, A, B | Partially (color only) | `05-AUTHENTICATION.md` |
| 1.7 | Session management | P0 | B | Implemented | `05-AUTHENTICATION.md` |
| 1.8 | CSRF protection | P0 | B | Implemented | `05-AUTHENTICATION.md` |
| 1.9 | Logout | P0 | W, A, B | Implemented | `05-AUTHENTICATION.md` |
| 1.10 | Account deletion | P1 | W, A, B | Partially implemented | `05-AUTHENTICATION.md` |
| 1.11 | Biometric lock (app) | P3 | A | Not started | `05-AUTHENTICATION.md` |
| 1.12 | Password-based login | P3 | W, A, B | Not started | `05-AUTHENTICATION.md` |

---

## 2. Groups (Trips)

| # | Feature | Priority | Platforms | Status | Spec |
|---|---------|----------|-----------|--------|------|
| 2.1 | Create group | P0 | W, A, B | Implemented | `06-GROUPS.md` |
| 2.2 | Edit group (name, description) | P1 | W, A, B | Not started | `06-GROUPS.md` |
| 2.3 | Delete/archive group | P1 | W, A, B | Partially implemented | `06-GROUPS.md` |
| 2.4 | Group types (trip, flat, event, custom) | P2 | W, A, B | Not started | `06-GROUPS.md` |
| 2.5 | Group photo/icon | P2 | W, A, B | Not started | `06-GROUPS.md` |
| 2.6 | Share group via invite code | P0 | W, A, B | Implemented | `06-GROUPS.md` |
| 2.7 | Join group by code | P0 | W, A, B | Implemented | `06-GROUPS.md` |
| 2.8 | Join group via URL token | P1 | W, A, B | Implemented | `06-GROUPS.md` |
| 2.9 | Member list with roles | P0 | W, A, B | Implemented | `06-GROUPS.md` |
| 2.10 | Add member | P0 | W, A, B | Implemented | `06-GROUPS.md` |
| 2.11 | Remove member | P1 | W, A, B | Partially implemented | `06-GROUPS.md` |
| 2.12 | Member roles (owner/admin/member) | P1 | W, A, B | Implemented | `06-GROUPS.md` |
| 2.13 | Group currency setting | P1 | W, A, B | Implemented | `06-GROUPS.md` |
| 2.14 | Starting money pool | P0 | W, A, B | Implemented | `06-GROUPS.md` |
| 2.15 | Group settings | P1 | W, A, B | Not started | `06-GROUPS.md` |
| 2.16 | Multiple groups per user | P0 | W, A, B | Implemented | `06-GROUPS.md` |
| 2.17 | Switch active group | P0 | W, A, B | Implemented | `06-GROUPS.md` |

---

## 3. Shared Expenses

| # | Feature | Priority | Platforms | Status | Spec |
|---|---------|----------|-----------|--------|------|
| 3.1 | Add shared expense | P0 | W, A, B, WA | Implemented (W,A,B) | `07-EXPENSES.md` |
| 3.2 | Edit expense | P0 | W, A, B | Implemented | `07-EXPENSES.md` |
| 3.3 | Delete expense | P0 | W, A, B | Implemented | `07-EXPENSES.md` |
| 3.4 | Category selection | P0 | W, A, B | Implemented | `07-EXPENSES.md` |
| 3.5 | Custom category creation | P1 | W, A, B | Implemented | `07-EXPENSES.md` |
| 3.6 | Payer selection | P0 | W, A, B | Implemented | `07-EXPENSES.md` |
| 3.7 | Payment method (cash/upi/card/bank) | P0 | W, A, B | Implemented | `07-EXPENSES.md` |
| 3.8 | Participant selection | P0 | W, A, B | Implemented | `07-EXPENSES.md` |
| 3.9 | Split method selection | P0 | W, A, B | Implemented | `08-SPLIT-METHODS.md` |
| 3.10 | Receipt image attachment | P2 | W, A, B | Not started | `07-EXPENSES.md` |
| 3.11 | Expense notes | P1 | W, A, B | Implemented | `07-EXPENSES.md` |
| 3.12 | Expense date selection | P1 | W, A, B | Implemented | `07-EXPENSES.md` |
| 3.13 | Pre-trip vs during-trip flag | P1 | W, A, B | Implemented | `07-EXPENSES.md` |
| 3.14 | Idempotent creation (client_request_id) | P0 | W, A, B, WA | Implemented (W,A) | `07-EXPENSES.md` |

---

## 4. Split Methods

| # | Feature | Priority | Platforms | Status | Spec |
|---|---------|----------|-----------|--------|------|
| 4.1 | Equal split | P0 | W, A, B, WA | Implemented | `08-SPLIT-METHODS.md` |
| 4.2 | Exact amount split | P1 | W, A, B, WA | Implemented | `08-SPLIT-METHODS.md` |
| 4.3 | Percentage split | P2 | W, A, B, WA | Not started | `08-SPLIT-METHODS.md` |
| 4.4 | Shares/ratio split | P2 | W, A, B, WA | Not started | `08-SPLIT-METHODS.md` |
| 4.5 | Item-wise split | P3 | W, A, B | Not started | `08-SPLIT-METHODS.md` |
| 4.6 | Split validation (sum = total) | P0 | B | Implemented | `08-SPLIT-METHODS.md` |
| 4.7 | Rounding handling | P0 | B | Implemented | `08-SPLIT-METHODS.md` |

---

## 5. Balances & Settlements

| # | Feature | Priority | Platforms | Status | Spec |
|---|---------|----------|-----------|--------|------|
| 5.1 | View group balances | P0 | W, A, B | Implemented | `09-SETTLEMENTS.md` |
| 5.2 | Net balance per member | P0 | W, A, B | Implemented | `09-SETTLEMENTS.md` |
| 5.3 | Who-owes-whom calculation | P0 | W, A, B | Implemented | `09-SETTLEMENTS.md` |
| 5.4 | Debt simplification algorithm | P0 | B | Implemented | `09-SETTLEMENTS.md` |
| 5.5 | Record settlement | P0 | W, A, B, WA | Implemented (W,A,B) | `09-SETTLEMENTS.md` |
| 5.6 | Partial settlement | P1 | W, A, B, WA | Not started | `09-SETTLEMENTS.md` |
| 5.7 | Settlement payment method | P0 | W, A, B | Implemented | `09-SETTLEMENTS.md` |
| 5.8 | Settlement history | P1 | W, A, B | Implemented | `09-SETTLEMENTS.md` |
| 5.9 | Undo settlement | P2 | W, A, B | Partially implemented | `09-SETTLEMENTS.md` |
| 5.10 | Settlement notes | P2 | W, A, B | Not started | `09-SETTLEMENTS.md` |

---

## 6. Personal Expenses (First-Class Module)

| # | Feature | Priority | Platforms | Status | Spec |
|---|---------|----------|-----------|--------|------|
| 6.1 | Add personal expense | P0 | W, A, B | Partially (cashbook) | `10-PERSONAL-EXPENSES.md` |
| 6.2 | Add personal income | P0 | W, A, B | Partially (cashbook) | `10-PERSONAL-EXPENSES.md` |
| 6.3 | Personal expense categories | P0 | W, A, B | Partially | `10-PERSONAL-EXPENSES.md` |
| 6.4 | Custom personal categories | P1 | W, A, B | Not started | `10-PERSONAL-EXPENSES.md` |
| 6.5 | Transaction history (personal) | P0 | W, A, B | Partially (cashbook) | `10-PERSONAL-EXPENSES.md` |
| 6.6 | Monthly summary | P1 | W, A, B | Not started | `10-PERSONAL-EXPENSES.md` |
| 6.7 | Income vs expense view | P1 | W, A, B | Not started | `10-PERSONAL-EXPENSES.md` |
| 6.8 | Spending trends | P2 | W, A, B | Not started | `10-PERSONAL-EXPENSES.md` |
| 6.9 | Category analytics (personal) | P2 | W, A, B | Not started | `10-PERSONAL-EXPENSES.md` |
| 6.10 | Recurring personal expenses | P2 | W, A, B | Not started | `11-BILLS-AND-REMINDERS.md` |
| 6.11 | Search/filter personal transactions | P1 | W, A, B | Partially | `10-PERSONAL-EXPENSES.md` |
| 6.12 | Receipt attachment | P2 | W, A, B | Not started | `10-PERSONAL-EXPENSES.md` |
| 6.13 | Payment method tracking | P0 | W, A, B | Implemented | `10-PERSONAL-EXPENSES.md` |
| 6.14 | Running balance (cashbook) | P0 | W, A, B | Implemented | `10-PERSONAL-EXPENSES.md` |

---

## 7. Bills & Reminders

| # | Feature | Priority | Platforms | Status | Spec |
|---|---------|----------|-----------|--------|------|
| 7.1 | Add recurring bill | P1 | W, A, B | Not started | `11-BILLS-AND-REMINDERS.md` |
| 7.2 | Recurrence patterns (daily/weekly/monthly/yearly/custom) | P1 | W, A, B | Not started | `11-BILLS-AND-REMINDERS.md` |
| 7.3 | Due date tracking | P1 | W, A, B | Not started | `11-BILLS-AND-REMINDERS.md` |
| 7.4 | Payment reminders | P1 | W, A, B, WA | Not started | `11-BILLS-AND-REMINDERS.md` |
| 7.5 | Priority bills | P2 | W, A, B | Not started | `11-BILLS-AND-REMINDERS.md` |
| 7.6 | Paid/unpaid tracking | P1 | W, A, B | Not started | `11-BILLS-AND-REMINDERS.md` |
| 7.7 | Upcoming bills list | P1 | W, A, B | Not started | `11-BILLS-AND-REMINDERS.md` |
| 7.8 | Bill notification scheduling | P1 | B | Not started | `11-BILLS-AND-REMINDERS.md` |

---

## 8. Analytics

| # | Feature | Priority | Platforms | Status | Spec |
|---|---------|----------|-----------|--------|------|
| 8.1 | Personal income total | P1 | W, A, B | Not started | `12-ANALYTICS.md` |
| 8.2 | Personal expense total | P1 | W, A, B | Not started | `12-ANALYTICS.md` |
| 8.3 | Savings/remaining calculation | P1 | W, A, B | Not started | `12-ANALYTICS.md` |
| 8.4 | Category breakdown (personal) | P2 | W, A, B | Not started | `12-ANALYTICS.md` |
| 8.5 | Spending trend (personal) | P2 | W, A, B | Not started | `12-ANALYTICS.md` |
| 8.6 | Monthly comparison | P2 | W, A, B | Not started | `12-ANALYTICS.md` |
| 8.7 | Yearly comparison | P3 | W, A, B | Not started | `12-ANALYTICS.md` |
| 8.8 | Top categories | P2 | W, A, B | Not started | `12-ANALYTICS.md` |
| 8.9 | Top expenses | P2 | W, A, B | Not started | `12-ANALYTICS.md` |
| 8.10 | Group total expense | P1 | W, A, B | Implemented | `12-ANALYTICS.md` |
| 8.11 | Individual contributions (group) | P1 | W, A, B | Implemented | `12-ANALYTICS.md` |
| 8.12 | Individual shares (group) | P1 | W, A, B | Implemented | `12-ANALYTICS.md` |
| 8.13 | Category breakdown (group) | P1 | W, A, B | Implemented | `12-ANALYTICS.md` |
| 8.14 | Member analytics (group) | P2 | W, A, B | Not started | `12-ANALYTICS.md` |
| 8.15 | Settlement analytics | P2 | W, A, B | Not started | `12-ANALYTICS.md` |
| 8.16 | Combined financial picture | P3 | W, A, B | Not started | `12-ANALYTICS.md` |

---

## 9. People & Friends

| # | Feature | Priority | Platforms | Status | Spec |
|---|---------|----------|-----------|--------|------|
| 9.1 | People list (all contacts) | P1 | W, A, B | Partially | `13-PEOPLE-AND-FRIENDS.md` |
| 9.2 | Person details (shared expenses, balances) | P1 | W, A, B | Not started | `13-PEOPLE-AND-FRIENDS.md` |
| 9.3 | Add friend (by phone/email) | P2 | W, A, B | Not started | `13-PEOPLE-AND-FRIENDS.md` |
| 9.4 | Friend request/accept | P3 | W, A, B | Not started | `13-PEOPLE-AND-FRIENDS.md` |
| 9.5 | Send payment reminder | P2 | W, A, B, WA | Not started | `13-PEOPLE-AND-FRIENDS.md` |
| 9.6 | Mutual groups view | P2 | W, A, B | Not started | `13-PEOPLE-AND-FRIENDS.md` |

---

## 10. Reports & Import/Export

| # | Feature | Priority | Platforms | Status | Spec |
|---|---------|----------|-----------|--------|------|
| 10.1 | CSV export (group expenses) | P1 | W, A, B | Implemented | `14-REPORTS-IMPORT-EXPORT.md` |
| 10.2 | CSV export (personal expenses) | P1 | W, A, B | Not started | `14-REPORTS-IMPORT-EXPORT.md` |
| 10.3 | PDF export (group report) | P2 | W, B | Partially (print view) | `14-REPORTS-IMPORT-EXPORT.md` |
| 10.4 | PDF export (personal report) | P2 | W, B | Not started | `14-REPORTS-IMPORT-EXPORT.md` |
| 10.5 | Excel export | P3 | W, B | Not started | `14-REPORTS-IMPORT-EXPORT.md` |
| 10.6 | Date range filter (reports) | P1 | W, A, B | Not started | `14-REPORTS-IMPORT-EXPORT.md` |
| 10.7 | Category filter (reports) | P2 | W, A, B | Not started | `14-REPORTS-IMPORT-EXPORT.md` |
| 10.8 | Splitwise import | P2 | W, B | Not started | `14-REPORTS-IMPORT-EXPORT.md` |
| 10.9 | Tricount import | P3 | W, B | Not started | `14-REPORTS-IMPORT-EXPORT.md` |
| 10.10 | CSV import | P2 | W, B | Not started | `14-REPORTS-IMPORT-EXPORT.md` |

---

## 11. WhatsApp Integration

| # | Feature | Priority | Platforms | Status | Spec |
|---|---------|----------|-----------|--------|------|
| 11.1 | Incoming message handling | P0 | WA, B | Not started | `15-WHATSAPP-INTEGRATION.md` |
| 11.2 | Sender identification (phone lookup) | P0 | WA, B | Not started | `15-WHATSAPP-INTEGRATION.md` |
| 11.3 | Registration check + welcome message | P0 | WA, B | Not started | `15-WHATSAPP-INTEGRATION.md` |
| 11.4 | Guided expense flow (step-by-step) | P0 | WA, B | Not started | `16-WHATSAPP-CONVERSATION-FLOWS.md` |
| 11.5 | Natural language expense parsing | P1 | WA, B | Not started | `16-WHATSAPP-CONVERSATION-FLOWS.md` |
| 11.6 | Hindi/Hinglish support | P1 | WA, B | Not started | `16-WHATSAPP-CONVERSATION-FLOWS.md` |
| 11.7 | Multi-language support (English, Hindi, Hinglish) | P1 | WA, B | Not started | `16-WHATSAPP-CONVERSATION-FLOWS.md` |
| 11.8 | Group selection via WhatsApp | P0 | WA, B | Not started | `16-WHATSAPP-CONVERSATION-FLOWS.md` |
| 11.9 | Balance inquiry via WhatsApp | P1 | WA, B | Not started | `16-WHATSAPP-CONVERSATION-FLOWS.md` |
| 11.10 | Settlement recording via WhatsApp | P1 | WA, B | Not started | `16-WHATSAPP-CONVERSATION-FLOWS.md` |
| 11.11 | Bill reminders via WhatsApp | P2 | WA, B | Not started | `16-WHATSAPP-CONVERSATION-FLOWS.md` |
| 11.12 | Message deduplication | P0 | B | Not started | `15-WHATSAPP-INTEGRATION.md` |
| 11.13 | Transport layer adapter (replaceable) | P0 | B | Not started | `15-WHATSAPP-INTEGRATION.md` |

---

## 12. AI & LLM

| # | Feature | Priority | Platforms | Status | Spec |
|---|---------|----------|-----------|--------|------|
| 12.1 | Rule-based intent parsing | P0 | B, WA | Not started | `17-AI-AND-LLM.md` |
| 12.2 | Local LLM for complex messages | P1 | B | Not started | `17-AI-AND-LLM.md` |
| 12.3 | Cloud LLM fallback | P2 | B | Not started | `17-AI-AND-LLM.md` |
| 12.4 | Structured JSON output extraction | P0 | B | Not started | `17-AI-AND-LLM.md` |
| 12.5 | Confidence scoring | P1 | B | Not started | `17-AI-AND-LLM.md` |
| 12.6 | Fallback on low confidence | P0 | B, WA | Not started | `17-AI-AND-LLM.md` |
| 12.7 | Receipt OCR (Tesseract) | P1 | B, W, A | Not started | `18-RECEIPT-OCR.md` |
| 12.8 | Merchant extraction from receipt | P2 | B | Not started | `18-RECEIPT-OCR.md` |
| 12.9 | Date extraction from receipt | P2 | B | Not started | `18-RECEIPT-OCR.md` |
| 12.10 | Total extraction from receipt | P1 | B | Not started | `18-RECEIPT-OCR.md` |
| 12.11 | Item extraction from receipt | P2 | B | Not started | `18-RECEIPT-OCR.md` |
| 12.12 | Tax/discount extraction | P3 | B | Not started | `18-RECEIPT-OCR.md` |
| 12.13 | OCR confidence scoring | P1 | B | Not started | `18-RECEIPT-OCR.md` |

---

## 13. Notifications

| # | Feature | Priority | Platforms | Status | Spec |
|---|---------|----------|-----------|--------|------|
| 13.1 | In-app notifications | P0 | W, A, B | Implemented | `25-NOTIFICATIONS.md` |
| 13.2 | Expense added notification | P0 | W, A, B | Partially | `25-NOTIFICATIONS.md` |
| 13.3 | Expense edited notification | P1 | W, A, B | Not started | `25-NOTIFICATIONS.md` |
| 13.4 | Settlement notification | P1 | W, A, B | Not started | `25-NOTIFICATIONS.md` |
| 13.5 | Payment reminder notification | P1 | W, A, B, WA | Not started | `25-NOTIFICATIONS.md` |
| 13.6 | Group invitation notification | P0 | W, A, B | Not started | `25-NOTIFICATIONS.md` |
| 13.7 | Recurring bill reminder | P1 | W, A, B, WA | Not started | `25-NOTIFICATIONS.md` |
| 13.8 | Push notifications (web) | P2 | W | Not started | `25-NOTIFICATIONS.md` |
| 13.9 | Push notifications (Android) | P1 | A | Not started | `25-NOTIFICATIONS.md` |
| 13.10 | Mark as read | P0 | W, A, B | Implemented | `25-NOTIFICATIONS.md` |
| 13.11 | Mark all as read | P1 | W, A, B | Implemented | `25-NOTIFICATIONS.md` |

---

## 14. Search

| # | Feature | Priority | Platforms | Status | Spec |
|---|---------|----------|-----------|--------|------|
| 14.1 | Global search (expenses, groups, people) | P2 | W, A, B | Not started | See `02-USER-FLOWS.md` |
| 14.2 | Expense search by description | P1 | W, A, B | Partially | See `02-USER-FLOWS.md` |
| 14.3 | Filter by date range | P1 | W, A, B | Partially | See `02-USER-FLOWS.md` |
| 14.4 | Filter by amount range | P2 | W, A, B | Not started | See `02-USER-FLOWS.md` |
| 14.5 | Filter by category | P1 | W, A, B | Not started | See `02-USER-FLOWS.md` |
| 14.6 | Filter by group | P2 | W, A, B | Not started | See `02-USER-FLOWS.md` |
| 14.7 | Filter by person | P2 | W, A, B | Not started | See `02-USER-FLOWS.md` |
| 14.8 | Filter by type (expense/income/settlement) | P1 | W, A, B | Partially | See `02-USER-FLOWS.md` |

---

## 15. Online Bill Import

| # | Feature | Priority | Platforms | Status | Spec |
|---|---------|----------|-----------|--------|------|
| 15.1 | Import from Swiggy | P3 | W, B | Not started | `19-ONLINE-BILL-IMPORT.md` |
| 15.2 | Import from Zomato | P3 | W, B | Not started | `19-ONLINE-BILL-IMPORT.md` |
| 15.3 | Import from Blinkit | P3 | W, B | Not started | `19-ONLINE-BILL-IMPORT.md` |
| 15.4 | Screenshot/PDF import | P2 | W, A, B | Not started | `19-ONLINE-BILL-IMPORT.md` |
| 15.5 | Shared invoice import | P2 | W, A, B | Not started | `19-ONLINE-BILL-IMPORT.md` |
| 15.6 | Vendor integration architecture | P2 | B | Not started | `19-ONLINE-BILL-IMPORT.md` |

---

## 16. Admin Panel

| # | Feature | Priority | Platforms | Status | Spec |
|---|---------|----------|-----------|--------|------|
| 16.1 | Admin authentication | P0 | Admin | Implemented | `28-ADMIN-PANEL.md` |
| 16.2 | Dashboard stats | P0 | Admin | Implemented | `28-ADMIN-PANEL.md` |
| 16.3 | User management | P1 | Admin | Partially implemented | `28-ADMIN-PANEL.md` |
| 16.4 | Group management | P1 | Admin | Partially implemented | `28-ADMIN-PANEL.md` |
| 16.5 | Expense oversight | P2 | Admin | Not started | `28-ADMIN-PANEL.md` |
| 16.6 | WhatsApp connection status | P1 | Admin | Not started | `28-ADMIN-PANEL.md` |
| 16.7 | AI processing logs | P2 | Admin | Not started | `28-ADMIN-PANEL.md` |
| 16.8 | OCR job monitoring | P2 | Admin | Not started | `28-ADMIN-PANEL.md` |
| 16.9 | System health | P1 | Admin | Not started | `28-ADMIN-PANEL.md` |
| 16.10 | Audit logs | P1 | Admin | Not started | `28-ADMIN-PANEL.md` |
| 16.11 | Rate-limit monitoring | P1 | Admin | Not started | `28-ADMIN-PANEL.md` |
| 16.12 | App settings management | P1 | Admin | Implemented | `28-ADMIN-PANEL.md` |

---

## 17. Sync & Offline

| # | Feature | Priority | Platforms | Status | Spec |
|---|---------|----------|-----------|--------|------|
| 17.1 | Incremental sync (hash polling) | P0 | W, A, B | Implemented | `27-SYNC-OFFLINE.md` |
| 17.2 | Optimistic UI updates | P1 | W, A | Not started | `27-SYNC-OFFLINE.md` |
| 17.3 | Offline expense creation | P2 | A | Not started | `27-SYNC-OFFLINE.md` |
| 17.4 | Conflict resolution | P2 | W, A, B | Not started | `27-SYNC-OFFLINE.md` |
| 17.5 | Retry queue | P1 | W, A | Not started | `27-SYNC-OFFLINE.md` |
| 17.6 | Duplicate prevention | P0 | W, A, B, WA | Partially | `27-SYNC-OFFLINE.md` |
| 17.7 | Real-time WebSocket updates | P3 | W, A, B | Not started | `27-SYNC-OFFLINE.md` |

---

## 18. Security & Privacy

| # | Feature | Priority | Platforms | Status | Spec |
|---|---------|----------|-----------|--------|------|
| 18.1 | Password hashing (bcrypt) | P0 | B | Implemented | `26-SECURITY-PRIVACY.md` |
| 18.2 | OTP expiry and attempt limits | P0 | B | Implemented | `26-SECURITY-PRIVACY.md` |
| 18.3 | Session expiry | P0 | B | Not started | `26-SECURITY-PRIVACY.md` |
| 18.4 | Device management | P2 | B | Not started | `26-SECURITY-PRIVACY.md` |
| 18.5 | API rate limiting | P0 | B | Not started | `26-SECURITY-PRIVACY.md` |
| 18.6 | Input sanitization | P0 | B | Partially | `26-SECURITY-PRIVACY.md` |
| 18.7 | SQL injection prevention | P0 | B | Implemented (PDO) | `26-SECURITY-PRIVACY.md` |
| 18.8 | XSS prevention | P0 | W, B | Partially | `26-SECURITY-PRIVACY.md` |
| 18.9 | Data encryption at rest | P1 | B | Not started | `26-SECURITY-PRIVACY.md` |
| 18.10 | Data encryption in transit | P0 | B | Depends on HTTPS | `26-SECURITY-PRIVACY.md` |
| 18.11 | Privacy policy | P1 | W, A | Not started | `26-SECURITY-PRIVACY.md` |
| 18.12 | Account deletion (data cleanup) | P1 | B | Partially | `26-SECURITY-PRIVACY.md` |
| 18.13 | Audit logs | P1 | B | Not started | `26-SECURITY-PRIVACY.md` |
| 18.14 | WhatsApp session security | P0 | B | Not started | `26-SECURITY-PRIVACY.md` |

---

## Feature Count Summary

| Module | Total | P0 | P1 | P2 | P3 | Implemented |
|--------|-------|----|----|----|----|-------------|
| Authentication | 12 | 5 | 3 | 2 | 2 | 6 |
| Groups | 17 | 7 | 7 | 3 | 0 | 9 |
| Shared Expenses | 14 | 8 | 4 | 2 | 0 | 10 |
| Split Methods | 7 | 3 | 1 | 2 | 1 | 4 |
| Settlements | 10 | 4 | 3 | 3 | 0 | 6 |
| Personal Expenses | 14 | 5 | 4 | 5 | 0 | 5 |
| Bills & Reminders | 8 | 0 | 6 | 2 | 0 | 0 |
| Analytics | 16 | 0 | 6 | 7 | 3 | 4 |
| People & Friends | 6 | 0 | 2 | 3 | 1 | 1 |
| Reports & Import | 10 | 0 | 3 | 5 | 2 | 2 |
| WhatsApp | 13 | 5 | 5 | 3 | 0 | 0 |
| AI & LLM | 13 | 3 | 5 | 4 | 1 | 0 |
| Notifications | 11 | 3 | 5 | 2 | 1 | 4 |
| Search | 8 | 0 | 4 | 4 | 0 | 2 |
| Online Bill Import | 6 | 0 | 0 | 3 | 3 | 0 |
| Admin Panel | 12 | 3 | 5 | 4 | 0 | 5 |
| Sync & Offline | 7 | 2 | 2 | 3 | 1 | 2 |
| Security & Privacy | 14 | 6 | 4 | 3 | 1 | 4 |
| **TOTAL** | **198** | **54** | **73** | **57** | **16** | **64** |

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should search support voice input? | Search UX, AI complexity |
| OQ-2 | Should group analytics be available to all members or only admins? | Permission model |
| OQ-3 | Should personal expense analytics include predictions? | AI scope |
| OQ-4 | What is the maximum number of groups a user can belong to? | Performance, UI |
| OQ-5 | Should WhatsApp support media messages (receipt images)? | WhatsApp scope |

---

## Dependencies

- `00-PROJECT-OVERVIEW.md` — Product vision and locked decisions

## Related Documents

- `02-USER-FLOWS.md` — User journey maps for these features
- `03-SCREEN-SPECIFICATION.md` — Screen inventory for these features
- `20-DATABASE-SCHEMA.md` — Database tables supporting these features
- `21-API-SPECIFICATION.md` — API endpoints for these features
- `31-IMPLEMENTATION-ROADMAP.md` — Phased implementation plan
