# Implementation Plan - TripBook

TripBook is a mobile-first financial management web application combining **shared expense management** (Split Karo/Splitwise-style expense splitting, balance calculation, and smart debt settlement) with **personal expense and income tracking** for individuals and groups.

> **Note**: This plan was originally written for the old "CashBook + Splitwise" product concept. The current product direction is a Split Karo-style expense sharing app + personal finance tracker. The `starting_money` / CashBook concepts have been removed from the product. This plan is preserved for reference but the product definition has changed.

## Key Principles & Design Decisions

1. **Single Source of Truth**: The backend (PHP + MySQL) is the single source of truth for all financial calculations. Clients never compute authoritative financial balances independently.
2. **Expense Splitting**: Net balance = `total_paid - total_share - settlements_received + settlements_sent`. Settlements are strictly person-to-person transfers and never create new expenses.
3. **Payment Methods**: Every transaction records payment method (`cash`, `upi`, `card`, `bank`).
4. **Incremental Live Sync**: Polling checks a lightweight version/timestamp token (`last_updated_at`), fetching and rendering only delta/updated sections without jarring full-page refreshes.
5. **Dashboard Cards**:
   - **Balance Card**: Net balance for the active group (green if owed, red if owes).
   - **Who Owes Whom Card**: Simplified settlement summary with 1-tap "Settle Up" action.

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
  - `getTripSummary($tripId)`: Calculates group expense totals and summary statistics.
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
