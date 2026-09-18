# 28 — Admin Panel

This document specifies the admin panel: dashboard, user management, monitoring, and system health.

---

## 1. Admin Authentication

### Login

- Separate from user authentication
- Uses `admin_users` table
- Session-based (PHP session)
- Different session namespace from regular users

### Admin Roles

| Role | Permissions |
|------|-------------|
| `super_admin` | Full access, manage other admins |
| `admin` | User management, system settings |
| `viewer` | Read-only access to dashboards |

---

## 2. Dashboard

### Stats Overview

| Metric | Source |
|--------|--------|
| Total users | `COUNT(users)` |
| Active users (30 days) | Users with login in last 30 days |
| Total groups | `COUNT(trips)` |
| Active groups | Groups with expenses in last 30 days |
| Total expenses | `COUNT(transactions WHERE type='expense')` |
| Total expense amount | `SUM(transactions.amount)` |
| WhatsApp messages processed | `COUNT(whatsapp_messages)` |
| OCR jobs processed | `COUNT(receipts)` |

### Charts

- User registration trend (line chart)
- Expense volume trend (bar chart)
- Active users (daily/weekly/monthly)
- Top groups by expense

---

## 3. User Management

### User List

| Column | Description |
|--------|-------------|
| ID | User ID |
| Name | Display name |
| Email | Email address |
| Phone | Phone number |
| Auth provider | phone/google/email |
| Groups count | Number of groups |
| Last login | Last login timestamp |
| Status | Active/Disabled |

### Actions

| Action | Description |
|--------|-------------|
| View details | Full user profile |
| Disable account | Prevent login |
| Enable account | Restore access |
| Delete account | Trigger deletion flow |
| View groups | Groups user belongs to |
| View audit log | User's activity history |

---

## 4. Group Management

### Group List

| Column | Description |
|--------|-------------|
| ID | Group ID |
| Name | Group name |
| Members | Member count |
| Expenses | Total expenses |
| Created by | Owner name |
| Created at | Creation date |
| Status | Active/Archived |

### Actions

| Action | Description |
|--------|-------------|
| View details | Full group info |
| Archive group | Archive |
| Delete group | Force delete |
| View expenses | Expense list |
| View members | Member list |

---

## 5. Expense Oversight

### View All Expenses

- Filterable by group, user, date, amount
- Export capability
- Flag suspicious patterns

### Suspicious Patterns

| Pattern | Alert |
|---------|-------|
| Very large expense | > ₹1,00,000 |
| High frequency | > 20 expenses/day |
| Round amounts | All amounts round to 1000s |

---

## 6. WhatsApp Monitoring

### Connection Status

| Metric | Description |
|--------|-------------|
| Gateway status | Connected/Disconnected |
| Messages today | Count |
| Messages processed | Count |
| Failed messages | Count |
| Average response time | Milliseconds |

### Message Log

- Last 100 messages
- Sender, direction, status
- Processing time
- Errors

---

## 7. AI Processing Logs

| Metric | Description |
|--------|-------------|
| Messages processed | Total count |
| Average confidence | Mean AI confidence |
| Low confidence messages | < 0.5 confidence |
| Model usage | Which model used |
| Processing time | Average latency |

---

## 8. OCR Job Monitoring

| Metric | Description |
|--------|-------------|
| Jobs processed | Total count |
| Success rate | % successful |
| Average confidence | Mean OCR confidence |
| Failed jobs | With error details |

---

## 9. System Health

### Server Metrics

| Metric | Description |
|--------|-------------|
| CPU usage | Server CPU |
| Memory usage | RAM consumption |
| Disk usage | Storage remaining |
| Database size | MySQL database size |
| PHP error rate | Errors per hour |

### Uptime

| Service | Status |
|---------|--------|
| Web server | Running/Down |
| MySQL | Running/Down |
| WhatsApp gateway | Connected/Disconnected |
| OCR service | Available/Unavailable |

---

## 10. Audit Logs

### Log Viewer

- Filterable by user, action, date
- Export to CSV
- Retention: 7 years

### Tracked Actions

- User login/logout
- Expense CRUD
- Settlement CRUD
- Group management
- Admin actions
- System errors

---

## 11. App Settings Management

### Editable Settings

| Setting | Description |
|---------|-------------|
| App name | Display name |
| Default currency | Currency code |
| OTP configuration | API key, expiry, max attempts |
| Auth toggles | Enable/disable auth methods |
| SMTP settings | Email server config |
| Google OAuth | Client ID/secret |

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should admin panel have role-based access control? | Security scope |
| OQ-2 | Should we support multiple admin accounts? | Feature scope |
| OQ-3 | Should admin actions require 2FA? | Security vs. convenience |

---

## Dependencies

- `20-DATABASE-SCHEMA.md` — All tables
- `26-SECURITY-PRIVACY.md` — Admin security

## Related Documents

- `20-DATABASE-SCHEMA.md` — Database tables
- `26-SECURITY-PRIVACY.md` — Security rules
- `22-BACKEND-ARCHITECTURE.md` — Backend implementation
