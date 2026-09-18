# 05 — Authentication

This document specifies the complete authentication system for TripBook. It covers all login methods, session management, security rules, and edge cases.

---

## Authentication Methods

| Method | Priority | Status | Provider |
|--------|----------|--------|----------|
| Phone OTP | P0 | Implemented | SMS gateway (upparac.com) |
| Google OAuth | P1 | Partially implemented | Google Identity Services |
| Email OTP | P2 | Partially implemented | Self-hosted SMTP |
| Password-based | P3 | Not started | Local (bcrypt) |

---

## 1. Phone OTP Authentication

### Flow

```
User enters phone number (+91XXXXXXXXXX)
  → Backend validates format
  → Backend generates 6-digit OTP
  → Backend stores OTP in otp_sessions table (expires in 5 minutes)
  → Backend sends OTP via SMS API
  → User receives OTP
  → User enters OTP
  → Backend verifies: code matches, not expired, attempts < 3
  → Decision: Phone number exists in users table?
    → YES: Create session, return user data + trips
    → NO: Return is_new_user=true, prompt for name
```

### Validation Rules

| Rule | Value |
|------|-------|
| Phone format | `+91` prefix + 10 digits |
| OTP length | 6 digits |
| OTP expiry | 5 minutes (configurable via `otp_expiry_minutes` setting) |
| Max attempts | 3 (configurable via `otp_max_attempts` setting) |
| Rate limit | 1 OTP per phone per 60 seconds |
| Cooldown between sends | 60 seconds |

### API Endpoints

| Endpoint | Method | Action |
|----------|--------|--------|
| `api/otp.php?action=send_otp` | POST | Send OTP to phone |
| `api/otp.php?action=verify_otp` | POST | Verify OTP code |

### Error States

| Error | HTTP Code | Message |
|-------|-----------|---------|
| Invalid phone format | 400 | "Invalid phone number format" |
| OTP not sent | 500 | "Failed to send OTP. Please try again." |
| Invalid OTP | 400 | "Invalid OTP code" |
| OTP expired | 400 | "OTP has expired. Please request a new one." |
| Too many attempts | 429 | "Too many attempts. Please request a new OTP." |
| Rate limited | 429 | "Please wait before requesting another OTP" |

### Database: `otp_sessions`

| Field | Type | Purpose |
|-------|------|---------|
| id | INT UNSIGNED PK | Auto-increment |
| phone | VARCHAR(30) | Phone number |
| otp_code | VARCHAR(6) | The OTP code (stored hashed) |
| expires_at | DATETIME | Expiry timestamp |
| verified | TINYINT(1) | Whether OTP was verified |
| attempts | INT | Number of verification attempts |

---

## 2. Google OAuth Authentication

### Flow

```
User taps "Continue with Google"
  → Frontend loads Google Identity Services
  → User selects Google account
  → Google returns ID token
  → Frontend sends ID token to backend
  → Backend verifies token with Google
  → Backend extracts: email, name, google_id
  → Decision: google_id exists in users table?
    → YES: Create session, return user data
    → NO: Decision: email exists in users table?
      → YES: Link google_id to existing account, create session
      → NO: Create new user with google data, create session
```

### Validation Rules

| Rule | Value |
|------|-------|
| Token verification | Via Google's tokeninfo endpoint |
| Email verification | Email must be verified by Google |
| Account linking | If email matches, link google_id to existing account |

### API Endpoints

| Endpoint | Method | Action |
|----------|--------|--------|
| `api/google-auth.php` | POST | Verify Google token, login/register |

### Database Changes

- `users.google_id`: VARCHAR(50), nullable — Google's unique user ID
- `users.auth_provider`: ENUM('phone','google','email') — How user authenticated
- `users.email_verified`: TINYINT(1) — Whether email is verified via Google

---

## 3. Email OTP Authentication

### Flow

```
User enters email address
  → Backend validates format
  → Backend generates 6-digit OTP
  → Backend stores OTP in email_otp_sessions table
  → Backend sends OTP via SMTP
  → User receives OTP
  → User enters OTP
  → Backend verifies: code matches, not expired, attempts < 3
  → Create session, return user data
```

### Validation Rules

| Rule | Value |
|------|-------|
| Email format | Standard email validation |
| OTP length | 6 digits |
| OTP expiry | 5 minutes |
| Max attempts | 3 |
| SMTP | Self-hosted, configurable via app_settings |

### API Endpoints

| Endpoint | Method | Action |
|----------|--------|--------|
| `api/email-otp.php?action=send_email_otp` | POST | Send OTP to email |
| `api/email-otp.php?action=verify_email_otp` | POST | Verify OTP code |

---

## 4. Session Management

### Session Creation

After successful authentication:
1. Backend creates PHP session
2. Session stores: `user_id`, `active_trip_id`, `csrf_token`
3. Session cookie (`PHPSESSID`) sent to client
4. Client stores cookie for subsequent requests

### Session Structure

```
$_SESSION = [
    'user_id'      => 123,
    'active_trip_id' => 456,
    'csrf_token'   => 'random_csrf_token_string'
]
```

### CSRF Protection

- Every POST request requires `X-CSRF-Token` header or `csrf_token` field
- CSRF token generated on session creation
- Token returned in `GET api/auth.php?action=me` response
- Token validated on every write operation

### Session Expiry

| Rule | Value |
|------|-------|
| Session lifetime | 30 days (configurable) |
| Idle timeout | 7 days of inactivity |
| Absolute timeout | 30 days |

### Session Invalidation

- Logout: Destroys session, clears cookie
- Account deletion: Destroys all sessions for user
- Password change: Destroys all other sessions
- Security event: Force logout on suspicious activity

---

## 5. User Registration

### New User (Phone OTP)

```
OTP verified for new phone number
  → System prompts for name (required) and email (optional)
  → System creates user record:
    - name: provided
    - phone: verified phone
    - phone_verified: 1
    - auth_provider: 'phone'
    - avatar_color: random from predefined palette
    - password_hash: bcrypt hash of random secure string
  → System creates session
  → System returns user data + empty trips list
```

### New User (Google OAuth)

```
Google token verified, no existing account
  → System creates user record:
    - name: from Google profile
    - email: from Google profile
    - google_id: from Google
    - email_verified: 1
    - auth_provider: 'google'
    - avatar_color: random
  → System creates session
```

### Avatar Color Palette

When creating a new user, assign a random color from:

```
#2563eb (blue)
#10b981 (emerald)
#f59e0b (amber)
#ef4444 (red)
#8b5cf6 (violet)
#ec4899 (pink)
#06b6d4 (cyan)
#f97316 (orange)
```

---

## 6. User Profile Management

### Edit Profile

| Field | Editable | Validation |
|-------|----------|------------|
| name | Yes | Required, 1-100 chars |
| email | Yes | Valid email, unique if changed |
| avatar_color | Yes | Must be from predefined palette |
| phone | No | Requires new OTP verification flow |

### API Endpoints

| Endpoint | Method | Action |
|----------|--------|--------|
| `api/settings.php?action=update_profile` | POST | Update name, email, avatar_color |

---

## 7. Account Deletion

### Flow

```
User requests account deletion
  → System shows confirmation dialog:
    "This will permanently delete your account and all associated data.
     This action cannot be undone."
  → User confirms
  → System verifies session
  → System deletes:
    - User record
    - All expenses created by user
    - All splits for user
    - All settlements involving user
    - All notifications for user
    - All OTP sessions
    - All sessions
  → System destroys session
  → System returns success
```

### Deletion Rules

- Only the user can delete their own account
- If user is sole owner of a group, prompt to transfer ownership or delete group first
- Deletion is soft-delete for 30 days (recoverable), then hard-delete
- Admin accounts cannot be deleted via API

---

## 8. Security Rules

### Password Hashing

- Algorithm: bcrypt (PHP `password_hash()`)
- Cost factor: 10 (default)
- Used for: admin accounts, future password-based login

### OTP Security

- OTP codes are stored hashed in database (not plaintext)
- Max 3 verification attempts per OTP
- 60-second cooldown between OTP sends
- 5-minute expiry

### Rate Limiting

| Action | Limit | Window |
|--------|-------|--------|
| Send OTP (phone) | 3 requests | 5 minutes |
| Send OTP (email) | 3 requests | 5 minutes |
| Verify OTP | 5 requests | 5 minutes |
| Login (Google) | 10 requests | 5 minutes |
| Profile update | 10 requests | 1 minute |

### Session Security

- Session cookie: `HttpOnly`, `Secure` (HTTPS), `SameSite=Strict`
- Session ID regenerated on login (prevents session fixation)
- IP-based session validation (optional, configurable)

---

## 9. Authorization

### User Roles

| Role | Permissions |
|------|-------------|
| Regular User | Create groups, join groups, add expenses, settle |
| Group Owner | All regular permissions + manage members, delete group |
| Group Admin | All regular permissions + manage members |
| Group Member | View group, add expenses, settle |
| System Admin | Access admin panel, manage all data |

### Authorization Checks

| Action | Required Role |
|--------|---------------|
| Create group | Any authenticated user |
| Join group | Any authenticated user |
| Add expense to group | Group member |
| Edit expense | Expense creator or group admin |
| Delete expense | Expense creator or group owner |
| Add member | Group admin or owner |
| Remove member | Group owner |
| Delete group | Group owner only |
| Access admin panel | System admin only |

---

## 10. Multi-Platform Session Handling

### Web

- PHP session cookie (`PHPSESSID`)
- CSRF token in meta tag and request headers
- Service Worker handles offline session caching

### Flutter Android

- Session stored in `flutter_secure_storage`
- Dio interceptor attaches session cookie to all requests
- Auto-logout on 401 response
- Biometric lock (future) protects session access

### WhatsApp

- Session linked to phone number
- No web session — authentication is implicit via phone number
- WhatsApp session is separate from web/app sessions
- User identified by phone number match in database

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should we implement refresh tokens or rely on PHP session expiry? | Token management complexity |
| OQ-2 | Should biometric lock be required for accessing financial data? | Security vs. convenience |
| OQ-3 | Should we support multiple phone numbers per user? | Database schema, UX |
| OQ-4 | What is the session limit per user (max concurrent sessions)? | Security policy |
| OQ-5 | Should account recovery be supported (forgot phone/email)? | Recovery flow design |

---

## Dependencies

- `00-PROJECT-OVERVIEW.md` — Locked decisions
- `04-DESIGN-SYSTEM.md` — Login/OTP screen components

## Related Documents

- `06-GROUPS.md` — Group membership authorization
- `20-DATABASE-SCHEMA.md` — users, otp_sessions, email_otp_sessions tables
- `21-API-SPECIFICATION.md` — Auth API endpoint details
- `26-SECURITY-PRIVACY.md` — Full security posture
