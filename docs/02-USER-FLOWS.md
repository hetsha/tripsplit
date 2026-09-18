# 02 — User Flows

This document maps every user journey through the application. Each flow is defined as a sequence of steps, decision points, and outcomes. These flows are the source of truth for how users interact with the product.

---

## Flow Notation

```
[Screen Name]     → User sees this screen
  → User Action   → What the user does
  → System Action → What the system does
  → Decision      → Branching point
  → API Call      → Backend endpoint called
  → Error         → Failure path
```

---

## 1. First-Time User Experience

### Flow 1.1: New User Registration

```
[Welcome Screen]
  → User opens app for first time
  → System shows welcome screen with app description
  → User taps "Get Started"

[Login Screen]
  → User enters phone number
  → System sends OTP via SMS
  → User enters 6-digit OTP
  → System verifies OTP
  → Decision: Is phone number already registered?
    → YES: [Home Dashboard] (skip to Flow 2.1)
    → NO: Continue below

[Profile Setup Screen]
  → System shows form: Name, Email (optional)
  → User enters name
  → User optionally enters email
  → User taps "Complete Setup"
  → System creates user account
  → System creates session
  → System redirects to [Groups List Screen]
```

### Flow 1.2: Google OAuth Registration

```
[Welcome Screen]
  → User taps "Continue with Google"
  → System opens Google OAuth consent screen
  → User selects Google account
  → System receives Google ID token
  → System verifies token with Google
  → Decision: Google ID exists in database?
    → YES: [Home Dashboard]
    → NO: Continue below

[Profile Setup Screen]
  → System pre-fills name and email from Google
  → User confirms or edits name
  → User taps "Complete Setup"
  → System creates user account with google_id
  → System creates session
  → System redirects to [Groups List Screen]
```

---

## 2. Home & Navigation

### Flow 2.1: App Launch (Returning User)

```
[App Launch]
  → System checks for valid session
  → Decision: Session valid?
    → NO: [Welcome Screen] (Flow 1.1)
    → YES: Continue below
  → System checks for active group
    → NO active group: [Groups List Screen] (Flow 3.1)
    → Has active group: [Home Dashboard]

[Home Dashboard]
  → System loads:
    - Group balance (who owes whom)
    - Recent transactions
    - Category spending
    - Member balances
    - Quick action buttons
  → User can navigate via:
    - Bottom nav (Home, Transactions, People, Settle, More)
    - FAB (Quick Add Expense)
    - Cards (tap to drill down)
```

### Flow 2.2: Switch Active Group

```
[Home Dashboard]
  → User taps group selector (top of screen)
  → System shows group list bottom sheet
  → User selects a different group
  → System sets new active group (API: switch_trip)
  → System reloads [Home Dashboard] with new group data
```

---

## 3. Group Management

### Flow 3.1: Create New Group

```
[Groups List Screen]
  → User taps "Create Group" button
  → System shows [Create Group Bottom Sheet]

[Create Group Bottom Sheet]
  → User enters group name (e.g., "Goa Trip")
  → User optionally enters description
  → User optionally sets starting money amount
  → User optionally selects starting payment method
  → User taps "Create"
  → System creates group (API: create trip)
  → System adds user as owner
  → System shows [Group Details Screen]
  → System shows group invite code
```

### Flow 3.2: Join Existing Group

```
[Groups List Screen]
  → User taps "Join Group" button
  → System shows [Join Group Bottom Sheet]

[Join Group Bottom Sheet]
  → User enters 5-character group code
  → System validates code (API: join trip)
  → Decision: Code valid?
    → NO: Show error "Invalid group code"
    → YES: Continue below
  → System adds user as member
  → System sets group as active
  → System redirects to [Home Dashboard]
```

### Flow 3.3: Add Member to Group

```
[Group Members Screen]
  → User taps "Add Member" button
  → System shows [Add Member Bottom Sheet]

[Add Member Bottom Sheet]
  → User enters member's phone number
  → System checks if phone number is registered
  → Decision: User registered?
    → YES: Show user profile, confirm add
    → NO: Show "User not registered" with share options
  → System adds member to group (API: add member)
  → System shows success toast
  → Member list updates
```

### Flow 3.4: Share Group Invite

```
[Group Details Screen]
  → User taps "Share Invite" button
  → System generates share link with group code
  → System opens native share sheet
  → User selects sharing method (WhatsApp, SMS, copy link)
  → Recipient receives invite link
  → Recipient taps link → opens app → [Join Group Flow] (3.2)
```

---

## 4. Expense Management

### Flow 4.1: Add Shared Expense (Guided)

```
[Home Dashboard]
  → User taps FAB → "Add Expense"

[Add Expense Screen]
  → Step 1: Amount
    - User enters amount (e.g., ₹1,500)
    - System shows large amount display with currency
  → Step 2: Description
    - User enters description (e.g., "Dinner at Hotel")
    - User optionally adds notes
  → Step 3: Category
    - System shows category grid (Food, Hotel, Travel, etc.)
    - User selects category
    - User optionally creates custom category
  → Step 4: Payer
    - System shows group members
    - User selects who paid
    - Default: current user
  → Step 5: Payment Method
    - System shows payment method chips (Cash, UPI, Card, Bank)
    - User selects payment method
  → Step 6: Participants
    - System shows all group members with checkboxes
    - Default: all members selected
    - User adds/removes participants
  → Step 7: Split Method
    - System shows split method chips (Equal, Exact, %, Shares)
    - User selects split method
    - System shows split breakdown
    - User adjusts amounts if needed
  → Step 8: Review
    - System shows summary: amount, payer, participants, splits
    - User taps "Save Expense"
  → System validates splits sum = total (F1 invariant)
  → System creates expense (API: create expense)
  → System creates expense splits
  → System shows success confirmation
  → System returns to [Home Dashboard]
  → Dashboard refreshes with new data
```

### Flow 4.2: Add Expense via Quick Entry

```
[Home Dashboard]
  → User taps FAB → "Quick Expense"
  → System shows compact expense form
  → User enters: amount, description, payer, splits
  → System auto-splits equally among all members
  → User taps "Save"
  → System creates expense (same as Flow 4.1, Steps 7-8)
```

### Flow 4.3: Edit Expense

```
[Transaction List / Expense Detail]
  → User taps expense → [Expense Detail Screen]
  → User taps "Edit" button

[Edit Expense Screen]
  → System loads existing expense data
  → User modifies fields (amount, description, category, payer, splits)
  → User taps "Save Changes"
  → System validates splits sum = total (F1 invariant)
  → System updates expense (API: update expense)
  → System recalculates affected balances
  → System shows success confirmation
```

### Flow 4.4: Delete Expense

```
[Expense Detail Screen]
  → User taps "Delete" button
  → System shows confirmation dialog: "Delete this expense?"
  → User taps "Delete"
  → System deletes expense (API: delete transaction)
  → System recalculates affected balances
  → System returns to previous screen
  → Screen refreshes with updated data
```

### Flow 4.5: Add Expense via Receipt OCR

```
[Add Expense Screen]
  → User taps "Scan Receipt" button
  → System opens camera / file picker
  → User captures or selects receipt image
  → System uploads image to backend
  → System runs OCR (Tesseract)
  → System extracts: merchant, date, total, items
  → System shows [Review Bill Screen]
  → User reviews and corrects extracted data
  → User selects participants and split method
  → User taps "Save Expense"
  → System creates expense (same as Flow 4.1)
```

---

## 5. Settlements

### Flow 5.1: View Balances

```
[Settlement Screen]
  → System loads:
    - Net balance per member
    - Who owes whom list
    - Simplified settlements
  → User sees clear visual:
    - Green: user is owed money
    - Red: user owes money
    - Gray: settled up
```

### Flow 5.2: Record Settlement

```
[Settlement Screen]
  → User taps "Settle Up" button
  → System shows simplified settlement list

[Settle Up Bottom Sheet]
  → System shows: "You owe Akshat ₹300"
  → User selects payment method (UPI, Cash, etc.)
  → User optionally adds notes
  → User taps "Record Payment"
  → System shows confirmation dialog
  → User confirms
  → System records settlement (API: record settlement)
  → System updates balances
  → System shows success confirmation
  → Settlement list updates
```

### Flow 5.3: Partial Settlement

```
[Settlement Screen]
  → User taps "Settle Up" → owes ₹500
  → User enters partial amount: ₹200
  → User taps "Record Partial Payment"
  → System records partial settlement
  → System updates remaining balance: ₹300
```

---

## 6. Personal Expenses

### Flow 6.1: Add Personal Expense

```
[Personal Dashboard]
  → User taps "Add Expense" button

[Add Personal Expense Screen]
  → User enters amount
  → User enters description
  → User selects category (personal categories)
  → User selects payment method
  → User optionally adds receipt image
  → User taps "Save"
  → System creates personal transaction (trip_id = NULL)
  → System updates personal balance
  → System shows success confirmation
```

### Flow 6.2: Add Personal Income

```
[Personal Dashboard]
  → User taps "Add Income" button

[Add Personal Income Screen]
  → User enters amount
  → User enters description (e.g., "Salary")
  → User selects category (Salary, Freelance, Gift, etc.)
  → User selects payment method
  → User taps "Save"
  → System creates income transaction
  → System updates personal balance
```

### Flow 6.3: View Personal Analytics

```
[Personal Dashboard]
  → User taps "Analytics" tab or card
  → System loads:
    - Monthly income vs expense
    - Category breakdown (donut chart)
    - Spending trend (line chart)
    - Top categories
    - Top expenses
  → User can filter by date range
  → User can tap category for detailed breakdown
```

---

## 7. Bills & Reminders

### Flow 7.1: Add Recurring Bill

```
[Bills Screen]
  → User taps "Add Bill" button

[Add Bill Screen]
  → User enters bill name (e.g., "Rent")
  → User enters amount
  → User selects recurrence (Monthly, Weekly, etc.)
  → User sets due date
  → User sets reminder (1 day before, 3 days before, etc.)
  → User selects priority (High, Medium, Low)
  → User taps "Save"
  → System creates recurring bill
  → System schedules reminders
```

### Flow 7.2: Mark Bill as Paid

```
[Bills Screen]
  → System shows upcoming bills with due dates
  → User taps bill → marks as "Paid"
  → System records payment
  → System schedules next occurrence
  → System updates bill status
```

---

## 8. WhatsApp Flows

### Flow 8.1: First WhatsApp Contact

```
[WhatsApp Message Received]
  → System receives message from unknown number
  → System checks database for phone number
  → Decision: User registered?
    → NO: System sends welcome message:
      "Welcome to TripBook! 🎉
       To manage expenses via WhatsApp, you need to register first.
       📱 Android: [install link]
       🌐 Web: [signup link]
       Register with this phone number to get started!"
    → YES: Continue below

[System identifies user]
  → System sends greeting:
    "Hi [Name]! 👋
     How can I help you today?
     1. Add Expense
     2. Check Balances
     3. Record Settlement
     4. View Recent Activity"
```

### Flow 8.2: Guided Expense Flow via WhatsApp

```
[User sends: "Add expense"]
  → System: "What type of expense?"
    "1. Personal Expense
     2. Group Expense"
  → User: "Group"
  → System: "Which group?"
    "1. Goa Trip
     2. Flat Expenses
     3. College Friends"
  → User: "1"
  → System: "Who paid?"
    "1. You
     2. Rahul
     3. Priya"
  → User: "1"
  → System: "How much?"
  → User: "1500"
  → System: "Split among?"
    "1. Everyone (3 members)
     2. Select members"
  → User: "1"
  → System: "Split method?"
    "1. Equal (₹500 each)
     2. You specify amounts"
  → User: "1"
  → System: "Description?"
  → User: "Dinner"
  → System: "Confirm:
    💰 Amount: ₹1,500
    👤 Paid by: You
    👥 Split: Equal among 3 (₹500 each)
    📝 Dinner
    ✅ Confirm / ❌ Cancel"
  → User: "Confirm"
  → System creates expense (API)
  → System: "✅ Expense added!
    You paid ₹1,500 for Dinner.
    Rahul owes you ₹500.
    Priya owes you ₹500."
```

### Flow 8.3: Natural Language Expense

```
[User sends: "Maine dinner ke 1500 diye Rahul aur Priya ke saath"]
  → System AI layer parses:
    - amount: 1500
    - description: dinner
    - participants: [user, Rahul, Priya]
    - split: equal
    - language: Hinglish
  → System: "Found:
    💰 ₹1,500 for dinner
    👥 With Rahul and Priya
    🔄 Split equally? (₹500 each)
    ✅ Yes / ❌ No, let me adjust"
  → User: "Yes"
  → System creates expense
  → System confirms
```

### Flow 8.4: Balance Inquiry via WhatsApp

```
[User sends: "Balance check karo"]
  → System looks up user's active groups
  → System calculates balances
  → System: "📊 Your Balances:
    Goa Trip:
    ✅ Rahul owes you ₹800
    ❌ You owe Priya ₹200
    Net: You're owed ₹600
    
    Flat Expenses:
    ❌ You owe Amit ₹1,500"
```

---

## 9. Reports & Export

### Flow 9.1: Export Group Report

```
[Group Details Screen]
  → User taps "Export" button
  → System shows export options: CSV, PDF
  → User selects CSV
  → System shows date range picker
  → User selects date range
  → System generates CSV file
  → System triggers download
  → User receives file
```

### Flow 9.2: Import from Splitwise

```
[Settings Screen]
  → User taps "Import Data"
  → User selects "Splitwise"
  → System shows instructions:
    "Export your Splitwise data as CSV, then upload here"
  → User selects CSV file
  → System parses and validates data
  → System shows preview:
    "Found 45 expenses, 3 groups, 8 members"
  → User confirms import
  → System imports data
  → System shows success summary
```

---

## 10. Search & Filter

### Flow 10.1: Search Expenses

```
[Search Screen]
  → User enters search query (e.g., "dinner")
  → System searches:
    - Expense descriptions
    - Category names
    - Member names
    - Notes
  → System returns matching results
  → Results show: date, amount, description, group
  → User taps result → [Expense Detail Screen]
```

### Flow 10.2: Filter Transactions

```
[Transaction List Screen]
  → User taps filter icon
  → System shows filter chips:
    - Type: All / Expenses / Income / Settlements
    - Date range: Today / This Week / This Month / Custom
    - Category: All / [Category chips]
    - Amount: Min - Max
  → User applies filters
  → System reloads transaction list with filters
```

---

## 11. Profile & Settings

### Flow 11.1: Edit Profile

```
[More Screen]
  → User taps "Profile"
  → System shows [Profile Screen]
  → User taps "Edit"
  → User modifies name, email, avatar color
  → User taps "Save"
  → System updates profile (API: update_profile)
  → System shows success confirmation
```

### Flow 11.2: Notification Settings

```
[Settings Screen]
  → User taps "Notifications"
  → System shows toggle options:
    - Expense notifications
    - Settlement notifications
    - Bill reminders
    - Group invitations
  → User toggles preferences
  → System saves settings
```

---

## 12. Error Recovery Flows

### Flow 12.1: Network Error During Expense Creation

```
[Add Expense Screen]
  → User taps "Save Expense"
  → System attempts API call
  → Decision: Network available?
    → NO: System shows error:
      "Network unavailable. Your expense has been saved locally
       and will sync when you're back online."
    → System saves to local queue
    → System shows offline indicator
    → When network returns: System syncs automatically
    → YES: Continue normal flow
```

### Flow 12.2: Duplicate Expense Prevention

```
[Add Expense Screen]
  → User taps "Save Expense"
  → System generates client_request_id
  → System sends request to API
  → API checks for existing client_request_id
  → Decision: Duplicate?
    → YES: API returns existing expense (no new record)
    → NO: API creates new expense
  → System shows success (same result either way)
```

---

## Flow Priority Matrix

| Flow | Priority | Frequency | Complexity |
|------|----------|-----------|------------|
| 1.1 New Registration | P0 | Once per user | Low |
| 2.1 App Launch | P0 | Every session | Low |
| 3.1 Create Group | P0 | Weekly | Low |
| 4.1 Add Shared Expense | P0 | Daily | High |
| 5.2 Record Settlement | P0 | Weekly | Medium |
| 6.1 Add Personal Expense | P0 | Daily | Medium |
| 8.2 WhatsApp Expense Flow | P1 | Daily | High |
| 4.5 Receipt OCR | P2 | Weekly | High |
| 7.1 Add Recurring Bill | P2 | Monthly | Medium |
| 9.1 Export Report | P2 | Monthly | Low |

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should the expense creation flow be a single screen or multi-step wizard? | UX complexity, screen count |
| OQ-2 | Should WhatsApp guided flow support interrupting and resuming? | Conversation state complexity |
| OQ-3 | Should search support voice input on mobile? | AI scope, accessibility |
| OQ-4 | Should the app support expense templates for recurring group expenses? | Feature scope |
| OQ-5 | Should users be able to undo expense creation within a time window? | Data integrity, UX |

---

## Dependencies

- `00-PROJECT-OVERVIEW.md` — Product vision
- `01-FEATURES.md` — Feature inventory
- `04-DESIGN-SYSTEM.md` — Component specifications

## Related Documents

- `03-SCREEN-SPECIFICATION.md` — Screen details for each step in these flows
- `07-EXPENSES.md` — Expense creation rules and validation
- `08-SPLIT-METHODS.md` — Split calculation rules
- `09-SETTLEMENTS.md` — Settlement recording rules
- `16-WHATSAPP-CONVERSATION-FLOWS.md` — WhatsApp flow details
