# Implementation Plan - TripBook: CashBook + Splitwise

TripBook is a mobile-first financial management web application combining **CashBook** (real money & payment method tracking) and **Splitwise** (shared expense splitting, balance calculation, and smart debt settlement) for small groups traveling together.

## Key Principles & Design Decisions

1. **Clean Starting Money**: `starting_money` is stored directly on the `trips` record and attributed to the initial contributor, keeping the CashBook ledger pristine.
2. **Two Independent Accounting Engines**:
   - **Trip Cash / Money Ledger**: Starting Cash + Added Money - Total Expenses = Remaining Cash (also broken down by payment method: Cash, UPI, Card, Bank).
   - **Splitwise Ledger**: Net balance = `Paid - Benefited Share + Settlement Adjustments`. Settlements are strictly person-to-person transfers and never inflate total trip expenses or alter trip cash.
3. **Payment Methods**: Every transaction records payment method (`cash`, `upi`, `card`, `bank`).
4. **Incremental Live Sync**: Polling checks a lightweight version/timestamp token (`last_updated_at`), fetching and rendering only delta/updated sections without jarring full-page refreshes.
5. **Dual Prominent Dashboard Cards**:
   - **Trip Cash Card**: Remaining balance with quick payment method breakdown (Cash / UPI / Card).
   - **Who Owes Whom Card**: Direct simplified settlement summary with 1-tap "Settle Up" action.

---

## Proposed Changes & Architecture

### 1. Database & SQL Scripts (`/sql`)
- **`sql/schema.sql`**: Normalized tables with `DECIMAL(12,2)` precision:
  - `users` (id, name, email, phone, password_hash, avatar_color, created_at)
  - `trips` (id, trip_code, name, description, starting_money, starting_payer_id, currency, currency_symbol, created_by, created_at)
  - `trip_members` (id, trip_id, user_id, role, joined_at)
  - `categories` (id, trip_id, name, icon, color, is_default, created_at)
  - `transactions` (id, trip_id, type [expense|income|settlement], amount, description, category_id, paid_by, received_by, payment_method [cash|upi|card|bank|other], created_by, transaction_date, notes, created_at, updated_at)
  - `expense_splits` (id, transaction_id, user_id, amount, created_at)
  - `settlements` (id, trip_id, transaction_id, from_user, to_user, amount, payment_method, status [pending|paid], notes, paid_at, created_at)
- **`sql/seed.sql`**: Initial sample data with default users and categories.

---

### 2. Backend PHP Infrastructure (`/config`, `/includes`, `/api`)
- **`config/database.php`**: Secure PDO connection with utf8mb4, automatic DB creation helper if needed.
- **`includes/auth.php`**: Session management, user auth, user switching, CSRF token management.
- **`includes/calculations.php`**:
  - `getTripSummary($tripId)`: Calculates Trip Cash (Starting + Added Money - Expenses), Payment method totals.
  - `getMemberBalances($tripId)`: Computes Total Paid, Total Share, Settlements Sent/Received, and Net Balance for each member.
  - `calculateSettlementSuggestions($tripId)`: Greedy debt-settlement simplification algorithm minimizing total transactions.
  - `getCategorySpending($tripId)`: Category breakdown.
- **`includes/functions.php` & `includes/validation.php`**: Security filters, JSON responder, membership validation.
- **REST-like API Endpoints (`/api/*.php`)**:
  - `api/auth.php`: Login, switch user, session info.
  - `api/trips.php`: List, create, join trip by code, update settings, delete.
  - `api/dashboard.php`: Summary stats, payment method breakdown, who-owes-whom suggestions, recent transactions.
  - `api/sync.php`: Lightweight incremental polling endpoint returning last update timestamp and changelog token.
  - `api/expenses.php`: Add/edit expense with equal or custom splits and payment method.
  - `api/transactions.php`: Filterable transactions list, add money (income), delete, edit.
  - `api/settlements.php`: Settle debt, record payment method, settlement history.
  - `api/members.php`: Member list, add member, invite code info.
  - `api/export.php`: CSV and printable summary export.

---

### 3. Frontend Architecture (`/`, `/assets/css`, `/assets/js`)
- **Modern Mobile-First Navigation**:
  - Top header: Trip Selector, User Switcher, Live Sync Indicator.
  - Mobile Bottom Bar: `Home`, `Transactions`, `People`, `Settlement`, `More`.
  - Floating Action Button (+ Expense / + Money).
  - Bottom Sheets for Add Expense, Custom Split, Add Money, Settle Up, and Transaction Details.
- **Visual Design**:
  - Modern, clean financial app design with Plus Jakarta Sans font, blue accents, emerald green, and rose tones.
  - Quick-switch payment method pills (Cash, UPI, Card, Bank).
  - Live Custom Split calculator with remainder indicator.
- **Incremental JS State**:
  - `app.js` & `api.js`: Lightweight background polling checking `api/sync.php` every 6s without full DOM reload.
