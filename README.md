# TripBook - CashBook + Splitwise

A mobile-first shared trip expense management and cash tracking web application built with **Core PHP 8+**, **MySQL**, **Vanilla JavaScript**, and **CSS3**.

---

## Key Features

1. **Dual Independent Accounting Engines**:
   - **CashBook Engine (Shared Trip Money)**: Tracks starting cash pool, money added, and on-trip spend with exact payment method breakdown (Cash, UPI, Card, Bank).
   - **Splitwise Engine (Who Owes Whom)**: Tracks member expense payments, equal and custom splits, net balances, and smart greedy debt-simplification settlements.
2. **Pre-Trip vs During-Trip Expense Scope**:
   - **Pre-Trip Advance Expenses**: Updates Splitwise balances & settlements without deducting from the active Shared Trip Money pool.
   - **During-Trip Expenses**: Deducts from the Shared Trip Money pool and updates Splitwise balances.
3. **Member Personal Wallets**:
   - Tracks each member's personal spend across payment channels (Cash, UPI, Card, Bank).
4. **Smart Settlement Engine**:
   - Minimal transactions algorithm matching debtors and creditors.
   - Settlements clear debt without double-counting as a new expense or altering the Shared Trip Money pool.
   - Comprehensive formula: `net_balance = (total_paid - total_share) + settlements_received - settlements_sent`.
5. **Incremental Live Sync**:
   - Background polling every 6 seconds checks a lightweight hash token (`api/sync.php`) to refresh data without jarring full-page reloads.
6. **Mobile-First UX**:
   - Tailored for 360px, 375px, 390px, 412px, 430px, tablet, and desktop centered container.
   - Sticky bottom navigation: `Home`, `History`, `People`, `Settle`, `More`.
   - Floating Action Button (+ Expense), bottom sheets, and live custom split balance validation.
   - 1-tap fast user switcher between members.

---

## Quick Setup & Installation

1. **Place Code in your web server's root directory**:
   ```
   your-server-root/tripsplit/
   ```
2. **Start Apache & MySQL** (or equivalent).
3. **1-Click Database Setup**:
   Open your browser and visit:
   ```
   http://localhost/tripsplit/setup.php
   ```
   Click **"Initialize & Seed Database"**. This will automatically create the database, tables, and sample data.
4. **Open the Application**:
   Visit:
   ```
   http://localhost/tripsplit/
   ```

---

## Tech Stack

- **Backend**: PHP 8+, MySQL 5.7+ / 8.0+
- **Frontend**: Vanilla JavaScript (ES6+), CSS3
- **PWA**: Service Worker for offline static asset caching
- **Icons**: Lucide Icons
- **Font**: Plus Jakarta Sans
