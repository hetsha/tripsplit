# 03 — Screen Specification

This document is the complete inventory of every screen in TripBook. For each screen, it specifies purpose, entry points, UI sections, components, actions, states, navigation, permissions, and API calls.

Screens are organized by module. Every screen uses components defined in `04-DESIGN-SYSTEM.md`.

---

## Screen Specification Format

Each screen entry follows this template:

```
### [Screen Name] (`route`)

**Purpose**: Why this screen exists
**Entry Points**: How users reach this screen
**Permission Requirements**: Who can see this screen
**API Calls**: Backend endpoints called on load

**UI Sections**:
1. [Section Name] — Content and components
2. ...

**Buttons/Actions**:
- [Action Name] — Behavior

**Navigation**:
- Forward: [Screen] → [Trigger]
- Back: [Screen] → [Trigger]

**States**:
- Empty: What to show when no data
- Loading: What to show while loading
- Error: What to show on failure
- Success: What to show after success

**Data Displayed**: What data populates this screen
```

---

## 1. Authentication Screens

### Splash Screen (`/splash`)

**Purpose**: App entry point, brand impression, session check.
**Entry Points**: App launch.
**API Calls**: None (checks local session cache).

**UI Sections**:
1. Logo centered (app icon + name)
2. Loading indicator

**States**:
- Loading: Spinner with app name
- Session valid: Redirect to Home Dashboard
- No session: Redirect to Welcome Screen

---

### Welcome Screen (`/welcome`)

**Purpose**: Introduce the app to first-time users.
**Entry Points**: Splash screen (no session).
**API Calls**: None.

**UI Sections**:
1. Hero illustration (expense/money concept)
2. App name and tagline
3. Feature highlights (3 cards: Split Expenses, Track Spending, WhatsApp)
4. Primary CTA: "Get Started"
5. Secondary CTA: "I already have an account"

**Buttons/Actions**:
- "Get Started" → Login Screen
- "I already have an account" → Login Screen

**Navigation**:
- Forward: Login Screen

---

### Login Screen (`/login`)

**Purpose**: Authenticate user via phone OTP, Google, or email.
**Entry Points**: Welcome Screen, Logout, Session expiry.
**API Calls**: `POST api/otp.php?action=send_otp`, `POST api/google-auth.php`.

**UI Sections**:
1. Header: "Welcome back" or "Create account"
2. Phone number input with country code (+91)
3. "Send OTP" button
4. Divider: "or"
5. Google OAuth button
6. Email OTP option (if enabled)

**Buttons/Actions**:
- "Send OTP" → sends OTP, shows OTP input
- "Continue with Google" → Google OAuth flow
- "Use email instead" → Email OTP flow

**States**:
- Empty: Phone input shown
- OTP sent: OTP input shown with countdown timer
- Error: "Invalid phone number" / "OTP send failed"
- Success: Redirect to Profile Setup or Home

**Navigation**:
- Forward: OTP Verification Screen → Profile Setup / Home

---

### OTP Verification Screen (`/otp-verify`)

**Purpose**: Verify OTP code and complete authentication.
**Entry Points**: Login Screen (after OTP sent).
**API Calls**: `POST api/otp.php?action=verify_otp`.

**UI Sections**:
1. Header: "Verify your phone number"
2. Phone number display (masked)
3. 6-digit OTP input (individual boxes)
4. Resend OTP link (with countdown)
5. "Verify" button

**Buttons/Actions**:
- "Verify" → validates OTP
- "Resend OTP" → sends new OTP (after countdown)

**States**:
- Loading: Verifying...
- Error: "Invalid OTP" / "OTP expired" / "Too many attempts"
- Success: Redirect to Profile Setup or Home
- New user: Profile Setup Screen
- Existing user: Home Dashboard

---

### Profile Setup Screen (`/profile-setup`)

**Purpose**: Collect basic user info after registration.
**Entry Points**: OTP Verification (new user).
**API Calls**: `POST api/auth.php?action=register`.

**UI Sections**:
1. Header: "Set up your profile"
2. Avatar color picker (circle of colors)
3. Name input
4. Email input (optional)
5. "Complete Setup" button

**Buttons/Actions**:
- "Complete Setup" → creates account, redirects to Groups List
- Color picker → updates avatar preview

**States**:
- Empty: Form shown
- Error: "Name is required" / "Email already in use"
- Success: Redirect to Groups List Screen

---

## 2. Main Navigation Screens

### Home Dashboard (`/home`)

**Purpose**: Central hub showing group overview, balances, and quick actions.
**Entry Points**: App launch, bottom nav "Home", after expense/settlement creation.
**Permission Requirements**: Must be member of at least one group.
**API Calls**: `GET api/dashboard.php`.

**UI Sections**:
1. **Group Selector** (top bar): Current group name, tap to switch
2. **Hero Balance Card**: Net balance (green if owed, red if owes), group name, currency
3. **Quick Actions Row**: Add Expense (FAB), Add Income, CashBook, Passbook, Settle Up
4. **Who Owes Whom Card**: Simplified settlement suggestions (from → to, amount)
5. **Category Spending**: Top categories with amounts and progress bars
6. **Member Balances**: List of members with net balance (color-coded)
7. **Recent Transactions**: Last 5-10 transactions with type, amount, description

**Buttons/Actions**:
- Group selector → Group switcher bottom sheet
- "Add Expense" (FAB) → Add Expense Screen
- "Add Income" → Add Income Bottom Sheet
- "Settle Up" → Settlement Screen
- Transaction item → Expense Detail Screen
- Member item → Person Detail Screen
- Category item → Category Detail (filtered transaction list)

**Navigation**:
- Forward: Add Expense, Settlement, Person Detail, Expense Detail
- Bottom nav: Transactions, People, Settle, More

**States**:
- Empty (no group): "Create or join a group" with CTAs
- Empty (no expenses): "No expenses yet. Add your first expense!"
- Loading: Skeleton loaders for all sections
- Error: "Failed to load dashboard. Tap to retry."
- Success: Full dashboard rendered

**Data Displayed**:
- Group name, currency symbol
- Net balance amount
- Who owes whom list
- Top 5 categories with amounts
- Member list with balances
- Last 10 transactions

---

### Transaction List (`/transactions`)

**Purpose**: Complete transaction history with search and filters.
**Entry Points**: Bottom nav "Transactions", Home Dashboard "See All".
**Permission Requirements**: Must be member of active group.
**API Calls**: `GET api/transactions.php`.

**UI Sections**:
1. **Search Bar**: Search input with filter icon
2. **Filter Chips**: All / Expenses / Income / Settlements
3. **Date Filter**: Today / This Week / This Month / Custom
4. **Transaction List**: Grouped by date, each item shows:
   - Type icon (expense/income/settlement)
   - Description
   - Amount (color-coded: green=income, red=expense, blue=settlement)
   - Category icon
   - Payer name
   - Date

**Buttons/Actions**:
- Search input → filters list in real-time
- Filter chips → filters by type
- Date filter → date range picker
- Transaction item → Expense Detail Screen
- FAB → Add Expense Screen

**Navigation**:
- Forward: Expense Detail Screen, Add Expense
- Back: Home Dashboard

**States**:
- Empty: "No transactions yet"
- Loading: Skeleton list (5 items)
- Error: "Failed to load transactions"
- No results: "No transactions match your filters"

---

### People List (`/people`)

**Purpose**: View all members of the active group with balances.
**Entry Points**: Bottom nav "People", Home Dashboard member section.
**Permission Requirements**: Must be member of active group.
**API Calls**: `GET api/members.php`.

**UI Sections**:
1. **Header**: "Members" with count badge
2. **Add Member Button**: Top-right
3. **Member List**: Each item shows:
   - Avatar (initials on colored background)
   - Name
   - Role badge (Owner/Admin/Member)
   - Net balance (color-coded)
   - "Owes you" / "You owe" amount

**Buttons/Actions**:
- "Add Member" → Add Member Bottom Sheet
- Member item → Person Detail Screen
- Long press → Member options (Remove, Change Role)

**Navigation**:
- Forward: Person Detail Screen, Add Member
- Back: Home Dashboard

**States**:
- Empty: "No members yet. Add someone!"
- Loading: Skeleton list
- Error: "Failed to load members"

---

### Settlement Screen (`/settle`)

**Purpose**: View balances, simplified settlements, and record payments.
**Entry Points**: Bottom nav "Settle", Home Dashboard "Settle Up".
**Permission Requirements**: Must be member of active group.
**API Calls**: `GET api/settlements.php?action=suggestions`, `GET api/settlements.php?action=history`.

**UI Sections**:
1. **Tab Bar**: Settlements / History
2. **Settlements Tab**:
   - Simplified settlement list: from_user → to_user, amount
   - Each item shows avatar, name, arrow, amount
   - "Record Payment" button on each
3. **History Tab**:
   - Past settlements list: date, from → to, amount, method, status

**Buttons/Actions**:
- "Record Payment" → Settle Up Bottom Sheet
- Settlement item → Settlement Detail
- Tab switch → toggles view

**Navigation**:
- Forward: Settle Up Bottom Sheet
- Back: Home Dashboard

**States**:
- Empty (no debts): "All settled up! 🎉"
- Empty (no history): "No settlements yet"
- Loading: Skeleton list
- Error: "Failed to load settlements"

---

### More Screen (`/more`)

**Purpose**: App settings, profile, group management, and utility actions.
**Entry Points**: Bottom nav "More".
**API Calls**: `GET api/auth.php?action=me`.

**UI Sections**:
1. **User Profile Card**: Avatar, name, email, "Edit Profile" link
2. **Group Info Card**: Group name, code, member count, "Share Invite"
3. **Quick Actions Grid**:
   - Profile
   - Create Group
   - Join Group
   - Settings
   - Export Data
   - Notifications
4. **Danger Zone**: Delete Group, Delete Account, Logout

**Buttons/Actions**:
- "Edit Profile" → Profile Edit Screen
- "Share Invite" → Share sheet
- "Create Group" → Create Group Bottom Sheet
- "Join Group" → Join Group Bottom Sheet
- "Settings" → Settings Screen
- "Export Data" → Export Screen
- "Notifications" → Notification List Screen
- "Logout" → Confirmation dialog → Welcome Screen

**Navigation**:
- Forward: Profile Edit, Settings, Export, Notifications
- Back: Home Dashboard

---

## 3. Group Screens

### Groups List Screen (`/groups`)

**Purpose**: List all groups the user belongs to, create or join new groups.
**Entry Points**: App launch (no active group), More → Switch Group.
**API Calls**: `GET api/trips.php`.

**UI Sections**:
1. **Header**: "My Groups"
2. **Create Group Card**: Dashed border, "+" icon, "Create New Group"
3. **Group Cards**: Each shows:
   - Group name
   - Member count
   - Total expenses
   - Net balance
   - Last activity date

**Buttons/Actions**:
- "Create Group" → Create Group Bottom Sheet
- Group card → sets as active, redirects to Home Dashboard
- Long press → Group options (Edit, Leave, Delete)

**Navigation**:
- Forward: Home Dashboard (after group selection)
- Back: Welcome Screen (if no session)

**States**:
- Empty: "No groups yet. Create or join one!"
- Loading: Skeleton cards
- Error: "Failed to load groups"

---

### Create Group Bottom Sheet

**Purpose**: Form to create a new group.
**Entry Points**: Groups List, More → Create Group.
**API Calls**: `POST api/trips.php` (create).

**UI Sections**:
1. **Group Name Input**: Required, max 150 chars
2. **Description Input**: Optional, max 500 chars
3. **Starting Money Input**: Optional, with currency symbol
4. **Starting Payment Method**: Chips (Cash, UPI, Card, Bank)
5. **Currency Selector**: Default INR
6. **"Create Group" button**

**Buttons/Actions**:
- "Create Group" → creates group, closes sheet, navigates to Group Details
- Backdrop tap → closes sheet

**States**:
- Empty: Form shown
- Error: "Group name is required" / "Creation failed"
- Success: Sheet closes, new group appears in list

---

### Group Details Screen (`/group-details`)

**Purpose**: View and manage group settings, members, and analytics.
**Entry Points**: Group card tap, More → Group Info.
**Permission Requirements**: Must be member of group.
**API Calls**: `GET api/trips.php` (details).

**UI Sections**:
1. **Group Header**: Name, description, created date
2. **Member List**: Avatars, names, roles, balances
3. **Quick Actions**: Edit, Share Invite, Export
4. **Group Analytics**: Total expenses, per-member breakdown
5. **Settings**: Currency, payment methods, notifications
6. **Danger Zone**: Leave Group, Delete Group (owner only)

**Buttons/Actions**:
- "Edit" → Edit Group Bottom Sheet
- "Share Invite" → Share sheet
- "Export" → Export Screen
- "Leave Group" → Confirmation dialog
- "Delete Group" → Confirmation dialog (owner only)

---

### Add Member Bottom Sheet

**Purpose**: Add a new member to the group.
**Entry Points**: People List → "Add Member".
**API Calls**: `POST api/members.php` (add).

**UI Sections**:
1. **Phone Number Input**: With country code
2. **Search Results**: If user found, show profile
3. **"Add to Group" button**
4. **"Share Invite Link" option**: If user not found

**Buttons/Actions**:
- "Add to Group" → adds member, closes sheet
- "Share Invite" → opens share sheet

**States**:
- Empty: Phone input shown
- Found: User profile shown with "Add" button
- Not found: "User not registered" with share option
- Error: "Failed to add member" / "User already in group"

---

## 4. Expense Screens

### Add Expense Screen (`/add-expense`)

**Purpose**: Create a new shared expense with splits.
**Entry Points**: FAB → "Add Expense", WhatsApp flow, Receipt OCR.
**Permission Requirements**: Must be member of active group.
**API Calls**: `POST api/expenses.php` (create), `GET api/categories.php`.

**UI Sections**:
1. **Amount Display**: Large centered amount with currency symbol
2. **Amount Input**: Numeric keypad
3. **Description Input**: Text input
4. **Category Grid**: 2-column grid of category chips
5. **Payer Selector**: Member chips (who paid)
6. **Payment Method Chips**: Cash, UPI, Card, Bank
7. **Participant Selector**: Member checkboxes with amounts
8. **Split Method Chips**: Equal, Exact, %, Shares
9. **Split Breakdown**: Per-person amounts
10. **Notes Input**: Optional
11. **Receipt Upload**: Camera/gallery icon
12. **"Save Expense" button**

**Buttons/Actions**:
- Category chip → selects category, highlights
- Payer chip → selects payer
- Payment method chip → selects method
- Participant checkbox → toggles inclusion
- Split method chip → changes split UI
- Receipt icon → camera/gallery picker
- "Save Expense" → validates and creates expense

**Navigation**:
- Forward: Success confirmation → Home Dashboard
- Back: Home Dashboard (discard draft)

**States**:
- Empty: Form shown with defaults (all members, equal split)
- Invalid: Split validation error (sum ≠ total)
- Loading: "Saving..." overlay
- Error: "Failed to save expense. Draft saved locally."
- Success: Checkmark animation → redirect

**Financial Invariants**:
- F1: `sum(participant_shares) == expense_total` (validated before save)
- F4: `client_request_id` generated and sent with request

---

### Expense Detail Screen (`/expense-detail`)

**Purpose**: View full details of an expense.
**Entry Points**: Transaction list item tap, Home Dashboard recent transaction.
**API Calls**: `GET api/transactions.php` (detail).

**UI Sections**:
1. **Amount Display**: Large amount with currency
2. **Description and Notes**
3. **Category Badge**: Icon + name
4. **Payer Info**: Avatar + name
5. **Payment Method**: Icon + label
6. **Date and Time**
7. **Split Breakdown**: List of participants with their shares
8. **Receipt Image** (if attached)
9. **Action Buttons**: Edit, Delete

**Buttons/Actions**:
- "Edit" → Edit Expense Screen
- "Delete" → Confirmation dialog → delete
- Payer avatar → Person Detail Screen
- Participant avatar → Person Detail Screen

**Navigation**:
- Forward: Edit Expense, Person Detail
- Back: Transaction List, Home Dashboard

**States**:
- Loading: Skeleton layout
- Error: "Expense not found"
- Success: Full detail rendered

---

### Edit Expense Screen (`/edit-expense`)

**Purpose**: Modify an existing expense.
**Entry Points**: Expense Detail → "Edit".
**API Calls**: `POST api/expenses.php` (update).

**UI Sections**: Same as Add Expense Screen, pre-filled with existing data.

**Buttons/Actions**: Same as Add Expense Screen.

**Financial Invariants**:
- F1: Recalculated on every change
- F4: Same `client_request_id` not reused; edit creates new version

---

## 5. Settlement Screens

### Settle Up Bottom Sheet

**Purpose**: Record a payment between two users.
**Entry Points**: Settlement Screen → "Record Payment", Home Dashboard settlement suggestion.
**API Calls**: `POST api/settlements.php` (settle).

**UI Sections**:
1. **From/To Display**: "You pay Akshat" with avatars
2. **Amount Display**: ₹300 (full or editable for partial)
3. **Payment Method Chips**: UPI, Cash, Card, Bank
4. **Notes Input**: Optional
5. **"Record Payment" button**

**Buttons/Actions**:
- Payment method chip → selects method
- Amount input → allows partial amount
- "Record Payment" → confirms and records

**Navigation**:
- Forward: Success confirmation → Settlement Screen
- Back: Settlement Screen (cancel)

**States**:
- Empty: Form shown
- Error: "Failed to record settlement"
- Success: Checkmark → closes sheet

---

## 6. Personal Finance Screens

### Personal Dashboard (`/personal`)

**Purpose**: Overview of personal finances.
**Entry Points**: Tab or navigation from main dashboard.
**API Calls**: `GET api/cashbook.php`.

**UI Sections**:
1. **Balance Card**: Total balance (income - expenses)
2. **Quick Actions**: Add Expense, Add Income, View All
3. **Income vs Expense Summary**: Side by side comparison
4. **Recent Personal Transactions**: Last 5-10 items
5. **Top Categories**: Spending by category

**Buttons/Actions**:
- "Add Expense" → Add Personal Expense Screen
- "Add Income" → Add Personal Income Screen
- "View All" → Personal Transaction List
- Category item → Category Detail

---

### Add Personal Expense Screen (`/add-personal-expense`)

**Purpose**: Create a personal expense.
**Entry Points**: Personal Dashboard → "Add Expense".
**API Calls**: `POST api/expenses.php` (create, is_personal=true), `GET api/categories.php`.

**UI Sections**:
1. **Amount Input**
2. **Description Input**
3. **Category Grid** (personal categories)
4. **Payment Method Chips**
5. **Date Picker**
6. **Receipt Upload** (optional)
7. **"Save" button**

**Financial Invariants**:
- F4: `client_request_id` generated
- Personal expenses have `trip_id = NULL` in database

---

### Add Personal Income Screen (`/add-personal-income`)

**Purpose**: Record personal income.
**Entry Points**: Personal Dashboard → "Add Income".
**API Calls**: `POST api/transactions.php` (add_money).

**UI Sections**:
1. **Amount Input**
2. **Description Input**
3. **Category** (Salary, Freelance, Gift, Other)
4. **Payment Method Chips**
5. **Date Picker**
6. **"Save" button**

---

### Personal Transaction List (`/personal-transactions`)

**Purpose**: Complete personal transaction history.
**Entry Points**: Personal Dashboard → "View All".
**API Calls**: `GET api/cashbook.php`.

**UI Sections**:
1. **Running Balance Header**: Total in, total out, net
2. **Filter Chips**: All / Income / Expense
3. **Transaction List**: Each item shows:
   - Type icon
   - Description
   - Amount (color-coded)
   - Category
   - Payment method
   - Date

---

## 7. Bills & Reminders Screens

### Bills List Screen (`/bills`)

**Purpose**: View all recurring bills and their status.
**Entry Points**: Navigation from dashboard or settings.
**API Calls**: `GET api/bills.php` (list).

**UI Sections**:
1. **Tab Bar**: Upcoming / Paid / All
2. **Bill Cards**: Each shows:
   - Bill name
   - Amount
   - Due date
   - Recurrence pattern
   - Priority badge (High/Medium/Low)
   - Status (Paid/Unpaid)
3. **"Add Bill" FAB**

**Buttons/Actions**:
- "Add Bill" → Add Bill Screen
- Bill card → Bill Detail Screen
- "Mark as Paid" → records payment

---

### Add Bill Screen (`/add-bill`)

**Purpose**: Create a new recurring bill.
**Entry Points**: Bills List → "Add Bill".
**API Calls**: `POST api/bills.php` (create).

**UI Sections**:
1. **Bill Name Input**
2. **Amount Input**
3. **Recurrence Picker**: Daily / Weekly / Monthly / Yearly / Custom
4. **Due Date Picker**
5. **Reminder Settings**: Days before due date
6. **Priority Selector**: High / Medium / Low
7. **Category** (optional)
8. **"Save Bill" button**

---

## 8. Analytics Screens

### Analytics Dashboard (`/analytics`)

**Purpose**: Visual analytics for personal and group finances.
**Entry Points**: Dashboard analytics card, navigation menu.
**API Calls**: `GET api/dashboard.php`, personal analytics endpoint.

**UI Sections**:
1. **Tab Bar**: Personal / Group
2. **Personal Analytics**:
   - Monthly income vs expense (bar chart)
   - Category breakdown (donut chart)
   - Spending trend (line chart)
   - Top categories list
   - Top expenses list
3. **Group Analytics**:
   - Total group expense
   - Per-member contribution (bar chart)
   - Category breakdown (donut chart)
   - Settlement analytics

**Charts**: Use components from `04-DESIGN-SYSTEM.md` Section 7.

---

## 9. Settings & Profile Screens

### Profile Screen (`/profile`)

**Purpose**: View and edit user profile.
**Entry Points**: More → Profile.
**API Calls**: `GET api/auth.php?action=me`.

**UI Sections**:
1. **Avatar Display**: Large, colored circle with initials
2. **Name**: Editable
3. **Email**: Editable
4. **Phone**: Display only (with change option)
5. **"Save Changes" button**

---

### Settings Screen (`/settings`)

**Purpose**: App-level settings and preferences.
**Entry Points**: More → Settings.
**API Calls**: `GET api/settings.php`.

**UI Sections**:
1. **Appearance**: Theme toggle (Light/Dark/System)
2. **Notifications**: Toggle switches for each type
3. **Security**: Biometric lock, change password
4. **Data**: Export, Import, Clear cache
5. **About**: Version, privacy policy, terms

---

### Notification List Screen (`/notifications`)

**Purpose**: View all in-app notifications.
**Entry Points**: More → Notifications, notification bell icon.
**API Calls**: `GET api/notifications.php`.

**UI Sections**:
1. **"Mark All as Read" button**
2. **Notification List**: Each item shows:
   - Type icon
   - Message text
   - Timestamp
   - Read/unread indicator (dot)

**Buttons/Actions**:
- "Mark All as Read" → marks all read
- Notification item → navigates to relevant screen
- Swipe to dismiss

**States**:
- Empty: "No notifications yet"
- All read: "You're all caught up!"

---

## 10. Report & Export Screens

### Export Screen (`/export`)

**Purpose**: Generate and download reports.
**Entry Points**: More → Export Data.
**API Calls**: `GET api/export.php`.

**UI Sections**:
1. **Export Type**: CSV / PDF
2. **Scope**: Personal / Group (select group)
3. **Date Range**: Start date, End date
4. **Filters**: Category, type
5. **"Generate Report" button**
6. **Recent Exports**: List of previous downloads

**Buttons/Actions**:
- "Generate Report" → generates file, triggers download
- Export item → downloads file again

---

## 11. Utility Screens

### Search Screen (`/search`)

**Purpose**: Global search across expenses, groups, people.
**Entry Points**: Search icon in header, pull-down on lists.
**API Calls**: `GET api/transactions.php` (with search param).

**UI Sections**:
1. **Search Input**: Auto-focus, clear button
2. **Recent Searches**: List of recent queries
3. **Search Results**: Grouped by type (Expenses, Groups, People)
4. **Filter Chips**: Type filters

---

### Activity History Screen (`/activity`)

**Purpose**: Chronological activity feed across all groups.
**Entry Points**: Dashboard activity section, navigation.
**API Calls**: `GET api/notifications.php` (activity type).

**UI Sections**:
1. **Activity Feed**: Timeline of events:
   - Expense added
   - Settlement recorded
   - Member joined
   - Group created
2. **Each item**: Icon, description, timestamp, user avatar

---

## Screen Count Summary

| Category | Screens | Bottom Sheets | Total |
|----------|---------|---------------|-------|
| Authentication | 5 | 0 | 5 |
| Main Navigation | 5 | 0 | 5 |
| Groups | 2 | 2 | 4 |
| Expenses | 3 | 0 | 3 |
| Settlements | 1 | 1 | 2 |
| Personal Finance | 4 | 0 | 4 |
| Bills & Reminders | 2 | 0 | 2 |
| Analytics | 1 | 0 | 1 |
| Settings & Profile | 3 | 0 | 3 |
| Reports & Export | 1 | 0 | 1 |
| Utility | 2 | 0 | 2 |
| **TOTAL** | **29** | **3** | **32** |

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should expense creation be a single screen or multi-step wizard? | Screen complexity, UX |
| OQ-2 | Should analytics have a dedicated tab or be part of the dashboard? | Navigation structure |
| OQ-3 | Should the app support split-screen on tablets? | Responsive design |
| OQ-4 | Should there be a dedicated "Friends" screen separate from "People"? | Screen count |
| OQ-5 | Should bill reminders have a dedicated dashboard card? | Dashboard density |

---

## Dependencies

- `04-DESIGN-SYSTEM.md` — Component specifications for all UI elements
- `02-USER-FLOWS.md` — User journeys that traverse these screens

## Related Documents

- `01-FEATURES.md` — Feature inventory mapped to these screens
- `07-EXPENSES.md` — Expense creation rules
- `20-DATABASE-SCHEMA.md` — Data behind these screens
- `21-API-SPECIFICATION.md` — API calls for each screen
- `23-FRONTEND-ARCHITECTURE.md` — Web implementation routing
- `24-FLUTTER-ARCHITECTURE.md` — Flutter implementation routing
