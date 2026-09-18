# TripBook - Shared Expense Management

A mobile-first shared expense management and personal finance tracking web application built with **Core PHP 8+**, **MySQL**, **Vanilla JavaScript**, and **CSS3**.

---

## Key Features

1. **Shared Expense Management (Split Karo-style)**:
   - Add, edit, delete shared expenses with 5 split methods (equal, exact, percentage, shares, item-wise).
   - Track who paid, who participated, and how the expense is divided.
   - Smart greedy debt-simplification algorithm for minimal settlements.
2. **Personal Expense & Income Tracking**:
   - First-class personal finance module with categories, analytics, and running balance.
   - Independent of group expenses — tracked with `trip_id = NULL`.
3. **Settlement Recording**:
   - Record person-to-person payments (cash, UPI, card, bank).
   - Settlements adjust balances without creating new expenses.
   - Comprehensive formula: `net_balance = total_paid - total_share - settlements_received + settlements_sent`.
4. **Multiple Split Methods**:
   - Equal, exact amount, percentage, shares/ratio, and item-wise splitting.
   - Backend validates that all splits sum to the expense total (F1 invariant).
5. **Incremental Live Sync**:
   - Background polling every 6 seconds checks a lightweight hash token (`api/sync.php`) to refresh data without jarring full-page reloads.
6. **Mobile-First UX**:
   - Tailored for 360px, 375px, 390px, 412px, 430px, tablet, and desktop centered container.
   - Sticky bottom navigation: `Home`, `History`, `People`, `Settle`, `More`.
   - Floating Action Button (+ Expense), bottom sheets, and live custom split balance validation.
7. **WhatsApp Integration** (planned):
   - Manage expenses via WhatsApp messages with guided and natural-language flows.
8. **AI Assistance** (planned):
   - Hybrid AI layer for intent parsing, receipt OCR, and smart suggestions.

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

- **Backend**: PHP 8+, MySQL 8+
- **Frontend**: Vanilla JavaScript (ES6+), CSS3
- **PWA**: Service Worker for offline static asset caching
- **Icons**: Lucide Icons
- **Font**: Plus Jakarta Sans
