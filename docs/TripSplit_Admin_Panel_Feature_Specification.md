# TripSplit Admin Panel — Detailed Feature Specification

**Project:** TripSplit  
**Repository:** `hetsha/tripsplit`  
**Document Type:** Admin Panel Functional & Technical Specification  
**Version:** 1.0  
**Status:** Development Specification

---

## 1. Purpose

The TripSplit Admin Panel is a secure web-based management console for administrators and support staff to manage the TripSplit platform.

The panel will provide centralized visibility and control over:

- Users
- Trips / groups
- Members
- Expenses and transactions
- Settlements
- Categories
- Personal finance activity
- Reports and analytics
- Notifications
- Receipt/OCR processing
- WhatsApp integrations
- AI/parser activity
- System configuration
- Authentication
- Admin accounts
- Audit logs
- Security and sessions
- Application health

The admin panel must be designed as a **separate administrative system**, not as an extension of the normal TripSplit user session.

---

# 2. Design Goals

## 2.1 Primary Goals

1. Give administrators complete visibility into platform activity.
2. Provide safe administrative controls without exposing user passwords or sensitive authentication data.
3. Allow support staff to investigate user/trip/transaction issues quickly.
4. Provide analytics for platform growth and usage.
5. Maintain a complete audit trail for administrative actions.
6. Support future WhatsApp and AI modules without requiring a major redesign.
7. Keep the panel responsive and usable on desktop, tablet, and mobile.
8. Use role-based permissions so administrators only see functions they are authorized to use.
9. Prevent administrative actions from bypassing application security.
10. Make the system production-ready and scalable.

---

# 3. Recommended Admin URL Structure

```text
/admin/
├── login.php
├── logout.php
├── index.php
│
├── dashboard/
├── users/
├── trips/
├── transactions/
├── settlements/
├── categories/
├── reports/
├── notifications/
├── receipts/
├── whatsapp/
├── ai/
├── system/
├── security/
└── profile/
```

A cleaner production implementation may use route-based URLs:

```text
/admin/login
/admin/dashboard
/admin/users
/admin/users/{id}
/admin/trips
/admin/trips/{id}
/admin/transactions
/admin/settlements
/admin/reports
/admin/settings
/admin/security/audit-logs
```

---

# 4. Admin Authentication

## 4.1 Separate Admin Authentication

Admin authentication must be completely separate from normal TripSplit user authentication.

Do not rely on:

```text
X-User-Id
```

or normal application user sessions for administrative authorization.

Recommended tables:

```text
admin_users
admin_sessions
admin_login_logs
admin_audit_logs
admin_password_resets
```

## 4.2 Login Features

Admin login should support:

- Email / username
- Password
- Remember me
- CAPTCHA/rate limiting where appropriate
- Account lockout after repeated failures
- Session regeneration after login
- Secure logout
- Optional 2FA
- Login activity tracking
- Last login information
- Failed login tracking

## 4.3 Login Security

Implement:

- `password_hash()`
- `password_verify()`
- Secure session cookies
- `HttpOnly`
- `Secure` when HTTPS is enabled
- `SameSite=Lax` or stricter where appropriate
- CSRF protection
- Session regeneration
- Login throttling
- Brute-force protection
- Idle session expiration

---

# 5. Admin Roles

## 5.1 SUPER_ADMIN

Full access.

Permissions:

```text
users.*
trips.*
transactions.*
settlements.*
reports.*
categories.*
notifications.*
receipts.*
whatsapp.*
ai.*
system.*
security.*
admins.*
audit_logs.*
```

Can:

- Create administrators
- Delete/deactivate administrators
- Change roles
- Change system settings
- View security logs
- Perform sensitive administrative actions

---

## 5.2 ADMIN

General platform administrator.

Permissions:

```text
users.view
users.edit
trips.view
trips.edit
transactions.view
transactions.edit
settlements.view
reports.view
categories.manage
notifications.manage
receipts.view
```

Cannot:

- Manage SUPER_ADMIN
- Change critical authentication settings
- Manage security policies unless explicitly granted

---

## 5.3 SUPPORT

Support-oriented access.

Permissions:

```text
users.view
users.edit
trips.view
trips.edit
transactions.view
settlements.view
receipts.view
```

Primarily used for customer support.

---

## 5.4 VIEWER

Read-only access.

Permissions:

```text
dashboard.view
users.view
trips.view
transactions.view
settlements.view
reports.view
```

No destructive actions.

---

# 6. Admin Dashboard

The dashboard is the main landing page after login.

## 6.1 KPI Cards

Display:

### Users

- Total Users
- Active Users
- New Users Today
- New Users This Month
- Suspended Users

### Trips

- Total Trips
- Active Trips
- Completed Trips
- Trips Created Today
- Trips Created This Month

### Transactions

- Total Transactions
- Total Expense Amount
- Total Income Amount
- Transactions Today
- Transactions This Month

### Settlements

- Total Settlements
- Pending Settlements
- Completed Settlements
- Total Settled Amount

---

# 7. Dashboard Analytics

## 7.1 User Growth Chart

Chart:

```text
Daily / Weekly / Monthly
```

Metrics:

- New users
- Active users
- Returning users
- Deleted users

Filters:

```text
7 Days
30 Days
90 Days
6 Months
1 Year
Custom
```

---

## 7.2 Trip Growth Chart

Display:

- Trips created
- Trips completed
- Active trips
- Average members per trip

---

## 7.3 Transaction Chart

Display:

- Expense volume
- Income volume
- Number of transactions
- Average transaction amount

---

## 7.4 Settlement Chart

Display:

- Pending settlements
- Completed settlements
- Settlement amount
- Average settlement time

---

# 8. Recent Activity

Dashboard should show:

### Recent Users

Columns:

```text
Name
Email
Phone
Created At
Status
Last Active
```

### Recent Trips

Columns:

```text
Trip Name
Owner
Members
Expense Count
Total Expense
Created At
Status
```

### Recent Transactions

Columns:

```text
Description
Amount
Trip
Paid By
Created By
Date
```

### Recent Admin Activity

Columns:

```text
Admin
Action
Target
IP Address
Time
Status
```

---

# 9. System Health

Dashboard should display:

- Database connection
- API availability
- Storage availability
- PHP version
- Server memory
- Disk usage
- Queue status
- Scheduled jobs
- Email service status
- WhatsApp service status
- AI service status
- OCR service status

Example:

```text
Database       ● Healthy
API            ● Healthy
Storage        ● Healthy
Email          ● Healthy
WhatsApp       ● Offline
AI             ● Not Configured
```

---

# 10. User Management

## 10.1 User List

Admin can view all registered users.

Columns:

```text
ID
Name
Email
Phone
Profile
Status
Created At
Last Login
Last Active
Trips
Transactions
Actions
```

## 10.2 Filters

Filter by:

- Active
- Suspended
- Deleted
- Verified
- Unverified
- Google account
- Email account
- Phone account
- Date created
- Last active

## 10.3 Search

Search by:

```text
Name
Email
Phone
User ID
```

---

# 11. User Details

User profile page should contain:

## Profile

- Name
- Email
- Phone
- Profile image
- User ID
- Account status
- Registration date
- Last login
- Last active

## Activity

- Trips
- Transactions
- Settlements
- Notifications
- Login history

## Statistics

```text
Trips created
Trips joined
Expenses added
Total expense amount
Settlements completed
Total settled
```

---

# 12. User Actions

Depending on permissions:

- View user
- Edit user
- Suspend user
- Activate user
- Delete account
- Restore account where supported
- Force logout
- Reset authentication
- View sessions
- View activity
- View trips
- View transactions

Sensitive actions must require confirmation.

Example:

```text
Suspend User

Reason:
[________________________]

[Cancel] [Suspend User]
```

Every administrative action must be recorded in the audit log.

---

# 13. Trip Management

## 13.1 Trip List

Columns:

```text
Trip ID
Trip Name
Owner
Members
Transactions
Total Expense
Created Date
Status
Actions
```

## 13.2 Filters

- Active
- Completed
- Archived
- Recently created
- Large trips
- High transaction volume

## 13.3 Search

Search by:

```text
Trip Name
Trip ID
Owner
Member
```

---

# 14. Trip Details

Trip page should provide:

## Overview

```text
Trip Name
Owner
Created Date
Status
Member Count
Transaction Count
Total Expense
Total Settled
Outstanding
```

## Members

Display:

```text
Name
Role
Joined Date
Expense
Paid
Owed
Balance
```

## Expenses

Display all transactions associated with the trip.

## Settlements

Display all settlement records.

---

# 15. Trip Administrative Actions

Depending on role:

- Rename trip
- Change status
- View members
- Remove member
- View transactions
- View settlement information
- Archive trip
- Restore trip
- Delete trip where explicitly authorized

Destructive actions should require:

1. Confirmation
2. Reason
3. Audit log entry

---

# 16. Transaction Management

The transaction module provides a centralized view of financial activity.

## 16.1 Transaction Types

Support:

```text
Expense
Income
Personal Expense
Personal Income
Settlement
```

## 16.2 Transaction List

Columns:

```text
Transaction ID
Description
Amount
Type
Trip
Paid By
Category
Payment Method
Created By
Date
Status
```

## 16.3 Filters

- Transaction type
- Trip
- User
- Category
- Payment method
- Date range
- Amount range
- Status

---

# 17. Transaction Details

Show:

```text
Transaction ID
Description
Amount
Category
Trip
Created By
Created At
Updated At
```

For expenses:

```text
Payer(s)
Participants
Split Method
Individual Share
```

For multiple payers:

```text
Payer A     ₹500
Payer B     ₹300
Payer C     ₹200
-----------------
Total       ₹1000
```

---

# 18. Split Information

Admin should be able to inspect:

### Equal Split

```text
Total: ₹1,000
Members: 4

Each: ₹250
```

### Exact Split

```text
User A: ₹400
User B: ₹300
User C: ₹200
User D: ₹100
```

### Percentage Split

```text
User A: 40%
User B: 30%
User C: 20%
User D: 10%
```

### Share Split

```text
User A: 2 shares
User B: 1 share
User C: 1 share
```

---

# 19. Settlement Management

## 19.1 Settlement Dashboard

Display:

```text
Total Settlements
Pending
Completed
Cancelled
Total Amount
```

## 19.2 Settlement List

Columns:

```text
Settlement ID
From
To
Amount
Trip
Status
Created At
Completed At
```

## 19.3 Settlement Details

Show:

```text
Payer
Receiver
Amount
Trip
Status
Created Date
Completed Date
Payment Method
Notes
```

---

# 20. Settlement Actions

Authorized administrators may:

- View settlement
- Mark as completed where business rules permit
- Cancel settlement
- Investigate disputed settlement
- View related transactions

Any manual settlement modification must be logged.

---

# 21. Categories

Admin can manage global categories.

Example:

```text
Food
Travel
Hotel
Transport
Shopping
Entertainment
Medical
Bills
Other
```

Features:

- Add category
- Edit category
- Disable category
- Reorder category
- Set icon
- Set category type
- View usage statistics

Do not physically delete a category that is already referenced by transactions unless the database/business rules support safe deletion.

Prefer:

```text
active = 0
```

for old categories.

---

# 22. Reports

The reporting system should provide exportable platform data.

## 22.1 User Report

Fields:

```text
User
Registration Date
Trips
Transactions
Activity
Status
```

## 22.2 Trip Report

Fields:

```text
Trip
Owner
Members
Transactions
Total Expense
Settled Amount
Outstanding
```

## 22.3 Transaction Report

Fields:

```text
Date
Trip
User
Type
Category
Amount
Payment Method
```

## 22.4 Settlement Report

Fields:

```text
Date
Trip
From
To
Amount
Status
```

---

# 23. Export Formats

Support:

```text
CSV
Excel
PDF
```

Large exports should use background processing if required.

All exports should respect the admin's permissions.

---

# 24. Notifications

Admin notification management.

Features:

- View notifications
- Create notification
- Send notification
- Schedule notification
- Target users
- Target trip members
- Broadcast notification
- Notification history

Types:

```text
System
Maintenance
Feature Update
Security
Promotion
General
```

---

# 25. Notification Targeting

Admin can target:

```text
All users
Active users
Specific users
Trip members
Users created after date
Users with specific activity
```

Example:

```text
Target:
Active users

Title:
New Split Feature

Message:
You can now split expenses using shares.
```

---

# 26. Receipt Management

TripSplit already has receipt/OCR-related functionality. The admin panel should expose its operational status.

## Receipt List

Display:

```text
Receipt ID
Transaction
Uploaded By
File
OCR Status
Created At
```

Statuses:

```text
Uploaded
Processing
Processed
Failed
```

## Receipt Details

Show:

- Receipt image/file
- OCR output
- Extracted merchant
- Extracted amount
- Extracted date
- Confidence
- Related transaction

---

# 27. OCR Monitoring

Dashboard:

```text
Receipts Processed
Receipts Failed
Average Processing Time
OCR Success Rate
```

Failed OCR records should include an error message for troubleshooting.

---

# 28. WhatsApp Module

The admin panel must be prepared for the future WhatsApp expense parser/integration.

## 28.1 Connections

Display:

```text
Connection ID
User
Phone
Status
Last Connected
Last Message
```

Statuses:

```text
Connected
Disconnected
QR Required
Error
```

## 28.2 WhatsApp Messages

Display:

```text
Message ID
Sender
Group
Message
Timestamp
Processing Status
Parsed Result
```

## 28.3 Processing Status

```text
Received
Parsed
Created
Needs Review
Duplicate
Failed
Ignored
```

---

# 29. WhatsApp Expense Parser Monitoring

Admin should be able to inspect:

```text
Original Message
Detected Amount
Description
Detected Payer
Detected Participants
Parser Confidence
Result
Error
```

Example:

```text
Message:
"Raj paid 1200 dinner"

Detected:
Amount: ₹1,200
Payer: Raj
Description: Dinner

Status:
Created
```

---

# 30. AI Module

The architecture should be ready for AI-assisted functionality.

## AI Request Logs

Display:

```text
Request ID
User
Feature
Prompt/Request Type
Provider
Model
Tokens
Response Time
Status
Created At
```

Sensitive prompt/response data should be access-controlled and redacted where necessary.

---

# 31. AI Parser Logs

Track:

```text
Input
Expected Fields
Detected Fields
Confidence
Final Result
Correction
Failure Reason
```

Example:

```text
Input:
"hum 5 log dinner 2500"

Detected:
Amount = 2500
Participants = 5
Category = Food

Status:
Needs Review
```

---

# 32. Failed Processing Center

Create a central troubleshooting screen for:

- Failed OCR
- Failed WhatsApp parsing
- Failed AI parsing
- Failed notification delivery
- Failed email
- Failed synchronization
- API errors

Each failure should contain:

```text
Error ID
Module
User
Request ID
Error Message
Timestamp
Status
```

---

# 33. System Settings

Admin system settings should be divided into sections.

## General

```text
Application Name
Application URL
Support Email
Timezone
Currency
```

## Authentication

```text
OTP Enabled
Email OTP Enabled
Google Login Enabled
Session Timeout
Maximum Login Attempts
```

## Email

```text
SMTP Host
SMTP Port
SMTP Username
SMTP Password
Encryption
From Email
From Name
```

Secrets must never be displayed in plain text after saving.

---

# 34. API Settings

Settings for:

```text
API Base URL
Request Timeout
Rate Limits
External Service Status
```

Sensitive API keys should be encrypted at rest.

---

# 35. Feature Flags

Create centralized feature toggles:

```text
WhatsApp Integration
AI Parser
OCR
Notifications
Google Login
Email OTP
Receipt Scanner
Experimental Features
```

Example:

```text
Feature             Status
--------------------------------
WhatsApp Parser     ON
AI Parser           OFF
OCR                 ON
Google Login        ON
```

---

# 36. Security Center

The security module is critical.

## 36.1 Admin Users

Display:

```text
Name
Email
Role
Status
Last Login
Created At
```

Actions:

- Create admin
- Edit admin
- Change role
- Disable admin
- Force logout
- Reset password

---

# 37. Admin Audit Logs

Every sensitive administrative action must be recorded.

Fields:

```text
ID
Admin ID
Admin Email
Action
Module
Target Type
Target ID
Old Value
New Value
IP Address
User Agent
Timestamp
Status
```

Example:

```text
Admin:
admin@example.com

Action:
SUSPEND_USER

Target:
USER #128

Reason:
Spam activity

IP:
xxx.xxx.xxx.xxx

Time:
2026-10-07 10:30
```

---

# 38. Audit Events

Track actions such as:

```text
LOGIN
LOGOUT
LOGIN_FAILED
CREATE_ADMIN
UPDATE_ADMIN
DELETE_ADMIN
SUSPEND_USER
ACTIVATE_USER
DELETE_USER
EDIT_USER
EDIT_TRIP
DELETE_TRIP
EDIT_TRANSACTION
DELETE_TRANSACTION
CHANGE_SETTINGS
EXPORT_DATA
SEND_NOTIFICATION
```

---

# 39. Admin Sessions

Admin should be able to see active sessions.

Display:

```text
Admin
Device
Browser
IP
Login Time
Last Activity
```

Actions:

```text
Terminate Session
Terminate All Other Sessions
```

---

# 40. Login Logs

Track:

```text
Successful Login
Failed Login
IP
Device
Browser
Timestamp
Failure Reason
```

Provide filters by:

- Admin
- Date
- IP
- Success/failure

---

# 41. Data Privacy

Admin panel must not expose:

- Passwords
- OTP values
- Authentication tokens
- Session secrets
- API secrets
- Private keys

Phone numbers/emails may be partially masked for roles that do not require full visibility.

Example:

```text
+91 ******1234
h***@example.com
```

---

# 42. Dangerous Actions

For high-risk actions, require confirmation.

Examples:

```text
Delete User
Delete Trip
Delete Transaction
Change Admin Role
Disable Admin
Change Authentication Settings
```

Use confirmation:

```text
Type DELETE to confirm
```

for especially destructive operations.

---

# 43. CSRF Protection

All state-changing admin requests must require CSRF protection.

Protected operations include:

```text
POST
PUT
PATCH
DELETE
```

Do not implement administrative write actions through GET requests.

---

# 44. Authorization

Every backend admin endpoint must verify:

```text
1. Valid admin session
2. Active admin account
3. Required permission
4. CSRF token for state-changing requests
```

Never rely only on hiding buttons in the frontend.

---

# 45. API Architecture

Recommended:

```text
admin/api/
├── auth.php
├── dashboard.php
├── users.php
├── trips.php
├── transactions.php
├── settlements.php
├── categories.php
├── reports.php
├── notifications.php
├── receipts.php
├── whatsapp.php
├── ai.php
├── settings.php
├── admins.php
├── audit-logs.php
└── system-health.php
```

---

# 46. Admin Middleware

Create:

```text
includes/admin_auth.php
includes/admin_permissions.php
includes/admin_csrf.php
includes/admin_audit.php
```

Example flow:

```text
Request
   ↓
Admin Session Check
   ↓
Account Status Check
   ↓
Permission Check
   ↓
CSRF Check
   ↓
Controller
   ↓
Database
   ↓
Audit Log
   ↓
Response
```

---

# 47. Database Tables

Recommended administrative tables:

```sql
admin_users
admin_roles
admin_permissions
admin_role_permissions
admin_sessions
admin_login_logs
admin_audit_logs
admin_password_resets
admin_notifications
system_settings
feature_flags
```

Optional:

```sql
ai_request_logs
whatsapp_connections
whatsapp_messages
processing_failures
```

Only create optional tables when the corresponding feature is implemented.

---

# 48. Admin Users Schema Concept

```text
id
name
email
password_hash
role_id
status
last_login_at
last_login_ip
created_at
updated_at
```

Never store plaintext passwords.

---

# 49. Audit Log Schema Concept

```text
id
admin_id
action
module
target_type
target_id
old_data
new_data
reason
ip_address
user_agent
created_at
```

For JSON fields use JSON-capable database columns where supported.

---

# 50. Search & Filtering

Every major list should support:

- Search
- Pagination
- Sorting
- Filters
- Date range
- Status
- Export

Pagination should happen at the database query level.

Do not load thousands of records into PHP and paginate afterward.

---

# 51. Bulk Actions

Where appropriate:

```text
Select Users
Suspend Selected
Activate Selected
Export Selected
```

For transactions:

```text
Export Selected
```

For notifications:

```text
Delete Drafts
```

Bulk destructive actions must require confirmation.

---

# 52. UI Design

Recommended visual direction:

- Premium SaaS dashboard
- Clean modern interface
- Responsive layout
- Sidebar navigation
- Top navigation
- Cards
- Data tables
- Charts
- Status badges
- Modal confirmations
- Toast notifications
- Skeleton loading
- Empty states
- Error states

Suggested structure:

```text
┌─────────────────────────────────────────────┐
│ Logo      Search       Notifications  Admin │
├───────────┬─────────────────────────────────┤
│ Dashboard │                                 │
│ Users     │          Main Content           │
│ Trips     │                                 │
│ Expenses  │                                 │
│ Reports   │                                 │
│ Settings  │                                 │
└───────────┴─────────────────────────────────┘
```

---

# 53. Responsive Design

Desktop:

```text
Sidebar + Content
```

Tablet:

```text
Collapsible Sidebar
```

Mobile:

```text
Drawer Navigation
Full-width Content
Scrollable Tables
```

Tables should support horizontal scrolling on smaller screens.

---

# 54. Dark Mode

Optional but recommended.

Store preference:

```text
admin_theme
```

Values:

```text
light
dark
system
```

---

# 55. Global Search

Add global admin search.

Search across:

```text
Users
Trips
Transactions
Settlements
Receipts
Audit Logs
```

Example:

```text
Search "Het"

Users
 └─ Het Shah

Trips
 └─ Kerala Trip

Transactions
 └─ Hotel Expense
```

---

# 56. Quick Actions

Dashboard quick actions:

```text
Add User
Create Notification
View Failed Processing
View Recent Transactions
Export Report
Manage Admins
```

Actions shown depend on permissions.

---

# 57. Activity Timeline

User and trip details should include a timeline.

Example:

```text
10:35 AM
Expense added — ₹1,200

10:40 AM
Settlement created — ₹500

11:05 AM
Member joined trip

11:10 AM
Trip updated
```

---

# 58. Error Handling

Admin UI should never expose raw PHP/database errors to users.

Instead:

```text
Something went wrong.

Error ID:
ERR-20261007-00128
```

Detailed technical error goes into server logs.

---

# 59. Logging

Use structured application logs for:

- API errors
- Database errors
- Authentication errors
- External API failures
- OCR errors
- WhatsApp errors
- AI errors

Never log:

```text
Passwords
OTP codes
Access tokens
API secrets
```

---

# 60. Performance

Admin dashboard should avoid expensive queries on every page load.

Recommended:

- Indexed database fields
- Pagination
- Cached dashboard statistics where useful
- Aggregated queries
- Lazy loading
- Background reports
- Query limits

Important indexes:

```text
users.email
users.phone
transactions.trip_id
transactions.created_by
transactions.created_at
settlements.trip_id
settlements.created_at
admin_audit_logs.admin_id
admin_audit_logs.created_at
```

---

# 61. Data Consistency

Admin actions must respect TripSplit's existing calculation engine.

The admin panel should not independently calculate balances differently from the application.

For:

```text
Expense
Split
Payer
Participant
Settlement
Balance
```

use the existing backend calculation/source-of-truth logic.

---

# 62. Transaction Safety

Financial changes should use database transactions where multiple records must change together.

Example:

```text
Update transaction
+
Update payer records
+
Update participant records
+
Recalculate balances
+
Create audit log
```

If one step fails:

```text
ROLLBACK
```

---

# 63. Soft Delete

Prefer soft deletion for important records where appropriate.

Example:

```text
deleted_at
```

or:

```text
status = deleted
```

This is especially useful for:

- Users
- Trips
- Transactions
- Categories

Permanent deletion should be restricted to SUPER_ADMIN and only where legally/business appropriate.

---

# 64. Backup & Recovery

Admin system should expose backup status if server-side backups exist.

Display:

```text
Last Backup
Backup Size
Backup Status
Next Backup
```

Do not allow arbitrary database downloads to normal administrators.

---

# 65. Maintenance Mode

Optional system setting:

```text
Maintenance Mode
```

When enabled:

```text
Normal Users → Maintenance Page
Admins → Continue Access
```

Display:

```text
Maintenance message
Expected duration
Support contact
```

---

# 66. API Rate Monitoring

Where possible show:

```text
Requests/minute
Errors/minute
Top endpoints
Slow endpoints
429 responses
```

Useful for identifying abuse or performance issues.

---

# 67. User Support Workflow

Support staff should be able to:

```text
Search user
   ↓
Open user profile
   ↓
See trips
   ↓
Open affected trip
   ↓
Inspect transaction
   ↓
Inspect settlement
   ↓
Review activity
   ↓
Take authorized action
```

This should be optimized for quick troubleshooting.

---

# 68. User Impersonation

Optional future feature.

If implemented:

- Must be SUPER_ADMIN only
- Must require explicit confirmation
- Must create an audit log
- Must display a prominent impersonation banner
- Must never expose passwords
- Must have a time limit
- Must provide "Stop Impersonation"

Example:

```text
⚠ You are viewing the application as USER #128
[Stop Impersonation]
```

---

# 69. GDPR / Privacy / Data Export Readiness

Where applicable, prepare for:

```text
User Data Export
Account Deletion
Data Retention
Privacy Requests
```

Admin should be able to track privacy requests without exposing unnecessary personal data.

---

# 70. Future Subscription Module

If TripSplit later introduces paid plans, prepare the admin architecture for:

```text
Plans
Subscriptions
Payments
Invoices
Refunds
Coupons
Usage Limits
```

Possible dashboard:

```text
Free Users
Premium Users
MRR
Active Subscriptions
Cancelled Subscriptions
```

This module should be added only when monetization is implemented.

---

# 71. Future Feature Management

Prepare for feature-level control:

```text
Feature
Enabled
Minimum App Version
Rollout Percentage
Allowed Platforms
```

Example:

```text
WhatsApp Parser
Enabled: ON
Rollout: 25%
Platform: Android
```

---

# 72. Mobile App Version Management

Recommended future module:

```text
Current Android Version
Minimum Android Version
Current iOS Version
Minimum iOS Version
Force Update
Maintenance
```

Admin can configure:

```text
Minimum supported version
Latest version
Update URL
Force update message
```

---

# 73. Notifications & Announcements

Create an announcement system:

```text
Title
Description
Image
Action URL
Target Audience
Start Date
End Date
Status
```

Target audiences:

```text
All
New Users
Active Users
Inactive Users
Specific Users
```

---

# 74. Admin Dashboard Navigation

Recommended final sidebar:

```text
Dashboard

Users
  All Users
  Active Users
  Suspended Users

Trips
  All Trips
  Active Trips
  Completed Trips

Finance
  Transactions
  Settlements
  Categories

Reports
  Users
  Trips
  Transactions
  Settlements

Engagement
  Notifications
  Announcements

Processing
  Receipts / OCR
  WhatsApp
  AI
  Failed Jobs

System
  Settings
  Feature Flags
  System Health

Security
  Admin Users
  Sessions
  Login Logs
  Audit Logs

Profile
  My Profile
  Change Password
```

---

# 75. Permission Naming Convention

Use granular permission names:

```text
dashboard.view

users.view
users.create
users.edit
users.suspend
users.delete

trips.view
trips.edit
trips.archive
trips.delete

transactions.view
transactions.edit
transactions.delete

settlements.view
settlements.manage

categories.view
categories.create
categories.edit
categories.delete

reports.view
reports.export

notifications.view
notifications.create
notifications.send

receipts.view
receipts.manage

whatsapp.view
whatsapp.manage

ai.view
ai.manage

settings.view
settings.edit

admins.view
admins.create
admins.edit
admins.delete

audit_logs.view
```

---

# 76. Security Rules

The admin panel must follow these rules:

### Rule 1

Never trust frontend permissions.

### Rule 2

Never trust:

```text
X-User-Id
```

for administrative authentication.

### Rule 3

Never expose passwords.

### Rule 4

Never expose OTP values.

### Rule 5

Never store plaintext API secrets.

### Rule 6

Every sensitive action must be audited.

### Rule 7

Every state-changing request requires CSRF protection.

### Rule 8

Every admin endpoint verifies permission server-side.

### Rule 9

Use prepared SQL statements.

### Rule 10

Do not expose raw database errors.

---

# 77. Existing TripSplit Integration

The admin panel should reuse existing TripSplit backend logic wherever possible.

Existing modules that should remain the source of truth include:

```text
Authentication
Trips
Members
Transactions
Expenses
Settlements
Categories
CashBook
PassBook
Receipts
Notifications
Sync
```

The admin panel should not duplicate business logic unnecessarily.

---

# 78. Existing Security Issues to Resolve During Admin Development

The admin implementation should also address existing backend security risks identified during the repository audit.

## 78.1 User Header Authentication

Do not allow an HTTP header such as:

```text
X-User-Id
```

to bypass normal authentication.

## 78.2 Development Authentication Fallback

Remove production fallback behavior that automatically chooses a trip member when no valid session exists.

## 78.3 Settlement Authorization

Verify that settlement operations are authorized server-side.

## 78.4 Account Deletion

Review old table/column references in account deletion logic and align them with the current transaction architecture.

## 78.5 Payment Method Consistency

Ensure validation and database schema support the same payment methods.

## 78.6 Runtime Migrations

Move runtime schema creation such as:

```text
ensureTransactionPayersTable()
ensureReceiptColumns()
```

into explicit database migrations in a future cleanup phase.

---

# 79. Development Phases

## Phase 1 — Admin Foundation

Implement:

```text
Admin Login
Admin Logout
Admin Sessions
RBAC
Permissions
Admin Layout
Sidebar
Dashboard
Audit Logs
```

Priority: **Critical**

---

## Phase 2 — Core Management

Implement:

```text
Users
User Details
Trips
Trip Details
Members
Transactions
Settlements
Categories
```

Priority: **Critical**

---

## Phase 3 — Reporting

Implement:

```text
User Reports
Trip Reports
Transaction Reports
Settlement Reports
CSV Export
Excel Export
PDF Export
```

Priority: **High**

---

## Phase 4 — Operations

Implement:

```text
Notifications
Receipts
OCR Monitoring
Failed Processing
System Health
```

Priority: **High**

---

## Phase 5 — Advanced Integrations

Implement:

```text
WhatsApp
AI Parser
AI Logs
WhatsApp Messages
Parser Review
```

Priority: **Medium**

These should only become functional once the corresponding backend services exist.

---

## Phase 6 — Security Hardening

Implement:

```text
2FA
Login Rate Limiting
Session Management
Security Logs
CSRF
Permission Tests
Audit Tests
Data Privacy Controls
```

Priority: **Critical**

---

# 80. Testing Requirements

## Authentication Tests

Test:

```text
Valid login
Invalid password
Locked account
Expired session
Logout
Session regeneration
CSRF
```

## Permission Tests

Test every role against every protected endpoint.

Example:

```text
VIEWER → cannot delete user
SUPPORT → cannot manage admins
ADMIN → cannot change SUPER_ADMIN
SUPER_ADMIN → full access
```

---

# 81. User Management Tests

Test:

```text
Search
Pagination
Filtering
Suspend
Activate
Edit
Delete
Audit logging
```

---

# 82. Financial Tests

Test:

```text
Transaction viewing
Multiple payer transactions
Equal split
Exact split
Percentage split
Share split
Settlement status
Balance calculations
```

The admin must never change financial calculations unexpectedly.

---

# 83. Security Testing

Test:

```text
SQL Injection
XSS
CSRF
Session fixation
Session hijacking
Privilege escalation
IDOR
Brute-force login
Unauthorized API access
```

Particularly test:

```text
/admin/users/123
```

against users who are not authorized to view user #123.

---

# 84. Performance Testing

Test:

```text
1,000 users
10,000 users
100,000 transactions
Large trips
Large reports
Large audit logs
```

The admin should remain responsive with pagination and indexed queries.

---

# 85. Acceptance Criteria

The admin panel is considered ready when:

- Admin login is secure.
- Normal user authentication cannot access admin functions.
- RBAC works.
- Dashboard statistics are accurate.
- Users can be searched and managed.
- Trips can be inspected.
- Transactions can be inspected.
- Settlements can be inspected.
- Reports can be exported.
- Categories can be managed.
- Notifications can be managed.
- Audit logs record sensitive actions.
- Admin sessions can be managed.
- CSRF protection works.
- Unauthorized API calls are rejected.
- SQL queries use prepared statements.
- No sensitive secrets are exposed.
- Existing TripSplit business logic remains consistent.
- Responsive UI works on desktop/tablet/mobile.
- Production error messages do not expose internals.

---

# 86. Recommended Priority Matrix

| Module | Priority | Phase |
|---|---|---|
| Admin Authentication | Critical | 1 |
| RBAC | Critical | 1 |
| Dashboard | Critical | 1 |
| Audit Logs | Critical | 1 |
| Users | Critical | 2 |
| Trips | Critical | 2 |
| Transactions | Critical | 2 |
| Settlements | Critical | 2 |
| Categories | High | 2 |
| Reports | High | 3 |
| Notifications | High | 4 |
| Receipt/OCR | High | 4 |
| System Health | High | 4 |
| Security Center | Critical | 1/6 |
| WhatsApp | Medium | 5 |
| AI | Medium | 5 |
| Subscriptions | Future | Future |
| App Version Management | Future | Future |
| Impersonation | Optional | Future |

---

# 87. Final Architecture

Recommended high-level architecture:

```text
                    ┌─────────────────────┐
                    │    Admin Browser    │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │  Admin UI / Router  │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │ Admin Middleware    │
                    │                     │
                    │ Session             │
                    │ RBAC                │
                    │ CSRF                │
                    │ Validation          │
                    └──────────┬──────────┘
                               │
             ┌─────────────────┼─────────────────┐
             ▼                 ▼                 ▼
       ┌───────────┐     ┌───────────┐    ┌────────────┐
       │ User API  │     │ Trip API  │    │ Finance API│
       └─────┬─────┘     └─────┬─────┘    └─────┬──────┘
             │                 │                 │
             └─────────────────┼─────────────────┘
                               ▼
                    ┌─────────────────────┐
                    │ TripSplit Database  │
                    └─────────────────────┘

Additional services:

       ┌─────────────┐
       │ WhatsApp    │
       └──────┬──────┘
              │
       ┌──────▼──────┐
       │ AI / Parser │
       └─────────────┘

       ┌─────────────┐
       │ OCR / Files │
       └─────────────┘
```

---

# 88. Implementation Principle

The admin panel should be treated as a **production administration platform**, not simply a collection of PHP pages.

The implementation must prioritize:

```text
Security
   ↓
Correctness
   ↓
Auditability
   ↓
Performance
   ↓
Usability
   ↓
Extensibility
```

The final system should allow the TripSplit team to operate the entire application from one secure control center while preserving the existing application's business rules and financial calculations.

---

# 89. Immediate Development Scope

The first implementation should contain:

```text
1. Secure Admin Login
2. Admin Session Management
3. Role & Permission System
4. Modern Admin Layout
5. Dashboard
6. User Management
7. Trip Management
8. Transaction Management
9. Settlement Management
10. Category Management
11. Reports
12. Admin Audit Logs
13. Security Center
14. System Settings
15. System Health
```

Then add:

```text
16. Receipt/OCR Monitoring
17. Notifications
18. WhatsApp Management
19. AI/Parser Management
20. Advanced Analytics
```

This creates a solid foundation while keeping future TripSplit integrations ready.
