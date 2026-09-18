# 26 — Security and Privacy

This document specifies the complete security posture: authentication security, encryption, privacy, data protection, and compliance.

---

## 1. Authentication Security

| Rule | Implementation |
|------|---------------|
| Password hashing | bcrypt, cost factor 10 |
| OTP storage | Hashed (not plaintext) |
| OTP expiry | 5 minutes |
| Max OTP attempts | 3 |
| Session cookie | HttpOnly, Secure, SameSite=Strict |
| Session fixation | Regenerate ID on login |
| CSRF protection | Token per session, validated on POST |

---

## 2. API Security

| Rule | Implementation |
|------|---------------|
| Rate limiting | 30 requests/minute per user |
| Input validation | Server-side on all inputs |
| SQL injection | PDO prepared statements |
| XSS prevention | `htmlspecialchars()` on output |
| Authorization | Checked per endpoint |
| Idempotency | client_request_id dedup |

---

## 3. Data Encryption

| Type | Method |
|------|--------|
| In transit | HTTPS (TLS 1.2+) |
| At rest | Database encryption (MySQL TDE) |
| Passwords | bcrypt hash |
| OTP codes | SHA-256 hash |
| Session tokens | Secure random generation |

---

## 4. File Security

| Rule | Value |
|------|-------|
| Receipt storage | Outside web root |
| Access control | User can only access own files |
| File type validation | Server-side, not just extension |
| Max file size | 5 MB |
| Antivirus | Scan uploaded files |

---

## 5. WhatsApp Session Security

| Rule | Value |
|------|-------|
| Session file | Outside web root, chmod 600 |
| Phone number | Not exposed in logs |
| Message content | Not logged permanently |
| Media files | Temporary, deleted after processing |

---

## 6. Privacy

### Data Collected

| Data | Purpose | Retention |
|------|---------|-----------|
| Phone number | Authentication | Account lifetime |
| Email | Authentication (optional) | Account lifetime |
| Name | Display | Account lifetime |
| Expenses | Core functionality | Account lifetime + 30 days |
| Receipts | Expense attachment | 90 days after expense deletion |
| WhatsApp messages | Expense processing | 30 days |
| AI processing logs | Debugging | 7 days |

### Data Not Collected

- Location data
- Contact list
- Browsing history
- Device identifiers (beyond push tokens)

---

## 7. Account Deletion

### Process

1. User requests deletion
2. System soft-deletes (30-day recovery window)
3. After 30 days: hard-delete all data
4. Data removed: user record, expenses, splits, settlements, notifications, receipts, WhatsApp messages

### Exceptions

- Audit logs retained for 1 year (anonymized)
- Financial records retained for 7 years (legal compliance, if applicable)

---

## 8. Audit Logs

### Tracked Events

| Event | Details |
|-------|---------|
| User login | IP, device, timestamp |
| Expense created | User, amount, group |
| Settlement recorded | Users, amount |
| Account deleted | User, timestamp |
| Admin actions | Admin, action, target |

### Log Retention

| Log Type | Retention |
|----------|-----------|
| Login logs | 90 days |
| Expense logs | 1 year |
| Admin logs | 2 years |
| Audit logs | 7 years |

---

## 9. Backup and Recovery

| Rule | Value |
|------|-------|
| Database backup | Daily automated |
| Backup retention | 30 days |
| Recovery tested | Monthly |
| Backup encryption | AES-256 |

---

## 10. Security Headers

```php
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('X-XSS-Protection: 1; mode=block');
header('Strict-Transport-Security: max-age=31536000; includeSubDomains');
header('Content-Security-Policy: default-src \'self\'');
```

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should we implement 2FA for admin accounts? | Security vs. convenience |
| OQ-2 | Should we encrypt sensitive data (amounts) in database? | Performance vs. security |
| OQ-3 | What legal compliance requirements apply? (GDPR, etc.) | Compliance scope |

---

## Dependencies

- `05-AUTHENTICATION.md` — Auth security details
- `20-DATABASE-SCHEMA.md` — Data storage
- `22-BACKEND-ARCHITECTURE.md` — Security implementation

## Related Documents

- `05-AUTHENTICATION.md` — Authentication
- `15-WHATSAPP-INTEGRATION.md` — WhatsApp security
- `28-ADMIN-PANEL.md` — Admin security
