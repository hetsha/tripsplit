# 25 Aug Next Plan — TripBook/SplitBook

## Full Implementation Plan

---

## TASK 1: Editable Profile (More Screen)

**What currently exists:** A read-only bottom sheet in `more_screen.dart` (lines 340-401) showing name, phone, email. No edit fields, no save button.

**What exists in PHP:** `settings.php` supports POST `update_profile` with params `name` (required) and `email`. Phone and password cannot be updated.

**Changes needed:**

1. **`lib/core/api/api_endpoints.dart`** — Add:
   ```dart
   static const String updateProfile = 'settings.php?action=update_profile';
   static const String updateTrip = 'trips.php?action=update';
   static const String deleteTrip = 'trips.php?action=delete';
   static const String deleteAccount = 'auth.php?action=delete_account';
   static const String searchUser = 'members.php?action=search';
   static const String exportData = 'export.php';
   ```

2. **`lib/features/settings/more_screen.dart`** — Modify `_showProfileSheet` (line 340):
   - Replace read-only `Text` widgets with `TextEditingController`-backed `TextField` widgets for `name` and `email` (phone stays read-only)
   - Add a "Save" button that calls `settings.php?action=update_profile` with `name` and `email`
   - On success, update `auth.currentUser` and show success SnackBar
   - Wire up "My Profile" tile `onTap` to open this edit sheet
   - Fix the avatar tap: change from `auth.logout()` to open the profile sheet (line 77-78)
   - Wire up "Create Group" and "Join Group" tiles to call the API (currently just close dialog)
   - Wire up "Delete Group" to call `trips.php?action=delete`
   - Wire up "Delete Account" to call `auth.php?action=delete_account`

---

## TASK 2: Group Settings Screen

**What exists in PHP:** `trips.php` supports POST `update` with params: `name`, `description`, `starting_money`, `starting_payment_method`. POST `delete` with `trip_id` (owner only).

**New file:** `lib/features/settings/group_settings_screen.dart`

**Contents:**
- `StatefulWidget` that loads current trip data from `auth.activeTrip`
- Form fields: Group Name (TextField), Description (TextField, multiline), Starting Money (number), Payment Method (Cash/Bank selector)
- Save button calls `trips.php?action=update` with the form data
- Delete button with confirmation dialog calls `trips.php?action=delete`
- On success, refresh trip data via `auth.checkAuth()`
- Uses the same glass/liquid card styling as other screens

**Modify:** `more_screen.dart` — Change `onTap: () => {}` on "Group Settings" tile (line 74) to navigate to the new `GroupSettingsScreen`. Change "Delete This Group" to call the API (line 82).

---

## TASK 3: CSV & PDF Export

**What exists in PHP:** `export.php` handles:
- `?format=csv` — Returns proper CSV with headers and data, sets `Content-Disposition` for download
- `?format=pdf` — Returns HTML with `window.print()` for browser-based PDF (not a real PDF file)

**What needs to happen in Flutter:**

1. **`pubspec.yaml`** — Add:
   ```yaml
   share_plus: ^10.1.0
   path_provider: ^2.1.0
   url_launcher: ^6.3.0
   ```

2. **`lib/core/api/api_endpoints.dart`** — Add export endpoint constant

3. **`lib/features/settings/more_screen.dart`** — Wire up CSV and PDF buttons:
   - **CSV**: Build URL as `http://192.168.1.9/tripsplit/api/export.php?format=csv&trip_id=TRIP_ID`, download file using Dio, then share with `Share.shareXFiles()`
   - **PDF**: Build URL as `http://192.168.1.9/tripsplit/api/export.php?format=pdf&trip_id=TRIP_ID`, open with `launchUrl(url, mode: LaunchMode.externalApplication)` to trigger browser print dialog

4. **Add required permissions** in `AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" tools:ignore="ScopedStorage"/>
   ```

5. **Add imports** to `more_screen.dart`: `dart:io`, `package:path_provider/path_provider.dart`, `package:share_plus/share_plus.dart`, `package:url_launcher/url_launcher.dart`

---

## TASK 4: More Screen Back Button → Dashboard

**What exists:** The More screen (inside HomeCoordinator tabs) has a back arrow that calls `Navigator.pop(context)`, which navigates back to the Groups List (the parent route).

**Fix needed:**
1. Add a `VoidCallback? onBack` parameter to `MoreScreen`. In `HomeCoordinator`, pass `onBack: () => setState(() => _currentIndex = 0)` to MoreScreen. In More's back button `onTap`, call `widget.onBack!()` instead of `Navigator.pop(context)`.

**Files to modify:**
- `lib/features/settings/more_screen.dart` — Add `onBack` parameter, update back button `onTap`
- `lib/features/home_coordinator.dart` — Pass `onBack` callback to `MoreScreen`

---

## TASK 5: Enhanced Groups List Screen with Bottom Nav, Quick Split, and Friends

This is the largest task. Here is the full breakdown:

### 5.1 Database Changes

**New migration file:** `sql/migration_direct_expenses.sql`

```sql
-- Add trip_type column to existing trips table
ALTER TABLE trips ADD COLUMN trip_type ENUM('group', 'direct') NOT NULL DEFAULT 'group' AFTER url_token;
```

**Changes to `trips.php`:**
- In `create` action: accept optional `trip_type` parameter (default 'group')
- In `create` action: accept optional `friend_id` parameter (for direct trips, auto-add the friend as member)
- Add validation: direct trips can only have 2 members
- The `is_hidden` concept is handled by `trip_type = 'direct'` — these trips won't show a share code and won't appear in the "Join Group" feature

**New PHP endpoint: `api/members.php`** — Add `search` action:
```
GET members.php?action=search&q={phone_or_email}&trip_id={optional}
```
- Searches `users` table by phone (LIKE match) or email (exact match)
- Excludes users already in the trip
- Returns: list of {id, name, email, phone, avatar_color}

**Changes to `api/dashboard.php`:**
- Add `trip_type` to the `trip_info` response
- Add a new section `direct_balances` that queries across all trips where `trip_type = 'direct'` for the current user, computing net balances with each other person

### 5.2 Flutter Model Changes

**Modify `lib/models/trip.dart`:**
- Add `final String tripType;` field (default 'group')
- Update `fromJson` and `toJson` methods

### 5.3 Flutter API Endpoint Additions

**Modify `lib/core/api/api_endpoints.dart`:**
```dart
static const String updateTrip = 'trips.php?action=update';
static const String deleteTrip = 'trips.php?action=delete';
static const String updateProfile = 'settings.php?action=update_profile';
static const String deleteAccount = 'auth.php?action=delete_account';
static const String searchUser = 'members.php?action=search';
static const String exportData = 'export.php';
```

### 5.4 Groups List Screen Redesign

**Modify `lib/features/groups/groups_list_screen.dart`:**

The screen becomes a **tabbed screen** with 3 tabs:

**Tab 0: My Groups** (current groups list, enhanced)
- Header: "My Groups" title + user avatar (tap → navigates to Tab 2 "My Profile")
- Enhanced group cards:
  - Colored gradient icon (existing, now differentiate group vs direct trips — e.g., suitcase for group, person icon for direct)
  - Group name
  - Group code (small, muted, only for `group` type, not for `direct` trips)
  - Balance: show user's balance in green/red (fetched from dashboard)
  - "Open" button or tap to enter
- FAB: "+" button → bottom sheet with "Create Group", "Join Group" options

**Tab 2: My Profile** (new, replaces logout-on-avatar-click)
- User avatar (large, gradient circle)
- Edit profile fields (name, email) with Save button
- Delete Account button

### 5.5 Quick Split Tab (Tab 1)

**New file:** `lib/features/direct/quick_split_screen.dart`

**What it does:**
- A standalone expense splitting screen for 2 people (no group required)
- When user wants to split with a friend, this screen handles the entire flow

**UI Flow:**
1. **Select Friend** - Search by phone or email. Shows matching users. Tap to select.
2. **Enter Expense Details:**
   - Amount (large input, currency symbol)
   - Description (text field)
   - Payment method: Cash or Bank pills
   - Split type: Equal (default, splits 50/50 between the 2 people)
3. **Split Preview** - Shows how much each person pays/owes
4. **Save** - Calls API to:
   a. Auto-create a hidden trip (`trip_type='direct'`, name="User A & User B") if one doesn't already exist for this pair
   b. Add both users as members of the trip (if new trip)
   c. Create the expense with splits

**Backend flow for Quick Split:**
1. Flutter calls `trips.php?action=create&trip_type=direct&name=Het & Rahul&friend_id=123`
2. PHP creates trip, adds both users, returns trip details
3. Flutter then calls `expenses.php?action=trip_id=NEW_TRIP&amount=X&description=Y&paid_by=ME&splits=[{user_id: friend_id, amount: X/2}]`

Or alternatively, create a combined `POST transactions.php?action=quick_split` endpoint that handles all of this in one call.

### 5.6 Friends Tab

**New file:** `lib/features/friends/friends_list_screen.dart`

**What it shows:**
- Search bar at top to find friends by phone/email
- "Friends" section listing all people the user has direct expenses with
  - Each entry shows: avatar, name, net balance (green if they owe you, red if you owe them)
  - Tap to see transaction history with that person
  - "Settle" button for each friend (calls `settlements.php?action=settle`)
- "Add Friend" button (opens search)

**Backend:** The `getSplitwiseBalances()` function in `calculations.php` already computes per-user balances across trips. We need to filter for trips where `trip_type = 'direct'` to get friend-specific balances.

### 5.7 Bottom Navigation in Groups List

**Modify `lib/features/groups/groups_list_screen.dart`:**

Replace the simple Scaffold with a tabbed version:

```dart
// In build method:
return Scaffold(
  body: _screens[_currentNavIndex],
  floatingActionButton: ..., // Only show on groups tab
  bottomNavigationBar: FloatingBottomNav(
    currentIndex: _currentNavIndex,
    onTap: (index) {
      setState(() => _currentNavIndex = index);
    },
    labels: ['Groups', 'Split', 'Friends'],
    icons: [Icons.group, Icons.receipt_long, Icons.people_outline],
  ),
);
```

Screens:
- Index 0: `GroupsTab` — the existing groups list (extract from current build)
- Index 1: `QuickSplitScreen` — new expense splitting between two people
- Index 2: `FriendsScreen` — friend list with balances and settle-up

---

## Execution Order

1. **Task 4** — Fix More screen back button (smallest, ~15 min)
2. **Task 1** — Editable profile + wire up stub handlers in More (30 min)
3. **Task 2** — Group Settings screen + wire up + delete trip (45 min)
4. **Task 3** — CSV/PDF export (add packages, wire buttons) (30 min)
5. **Task 5.1-5.3** — Database migration + API endpoints + Flutter model updates (30 min)
6. **Task 5.4** — Enhanced groups list with bottom nav (1 hr)
7. **Task 5.5** — Quick Split screen and flow (1 hr)
8. **Task 5.6-5.7** — Friends list + final bottom nav integration (1 hr)

**Estimated total: ~5 hours of implementation**

---

## New Files to Create
1. `lib/features/settings/group_settings_screen.dart`
2. `sql/migration_direct_expenses.sql`
3. `lib/features/direct/quick_split_screen.dart`
4. `lib/features/friends/friends_list_screen.dart`

## Files to Modify
1. `lib/core/api/api_endpoints.dart` — Add 7+ new endpoint constants
2. `lib/features/settings/more_screen.dart` — Profile edit, wire handlers, CSV/PDF, back button
3. `lib/features/home_coordinator.dart` — Pass callback to MoreScreen
4. `lib/features/groups/groups_list_screen.dart` — Bottom nav, enhanced cards, quick split & friends tabs
5. `lib/models/trip.dart` — Add trip_type field
6. `api/trips.php` — Add trip_type, friend_id support, delete support
7. `api/members.php` — Add search action
8. `api/dashboard.php` — Add trip_type to response
9. `pubspec.yaml` — Add share_plus, path_provider, url_launcher
10. `android/app/src/main/AndroidManifest.xml` — Add internet/storage permissions

## Bug Fixes Included
1. Avatar tap → navigates to Profile tab (not logout)
2. "Create Group" / "Join Group" in More screen actually call the API
3. "Delete Group" and "Delete Account" call their respective APIs
4. CSV/PDF buttons functional
5. Settlement action endpoint mismatch (Flutter sends `action=create`, PHP expects `action=settle`) — fix in `api_endpoints.dart`
