# 31 — Implementation Roadmap

This document specifies the phased development plan with objectives, dependencies, deliverables, and completion criteria.

---

## Phase 0: Documentation (Current)

| Item | Status |
|------|--------|
| Documentation system | Complete |
| All 32 spec files | Complete |
| Review & lock | Pending |

### Completion Criteria

- [ ] All documentation reviewed and approved
- [ ] Contradictions resolved
- [ ] Database model locked
- [ ] API contracts locked
- [ ] Screen flows locked
- [ ] Design system locked

---

## Phase 1: Foundation + Authentication

### Objectives

- Clean up existing codebase
- Implement complete auth system
- Establish API patterns

### Dependencies

- Phase 0 complete

### Deliverables

| Deliverable | Files |
|-------------|-------|
| Phone OTP login | `api/otp.php`, `05-AUTHENTICATION.md` |
| Google OAuth login | `api/google-auth.php` |
| Email OTP login | `api/email-otp.php` |
| Session management | `includes/auth.php` |
| CSRF protection | `includes/auth.php` |
| Profile setup | `api/auth.php` |
| Login/signup screens | Web + Flutter |

### Database Changes

- `users` table (existing, add google_id, email_verified)
- `otp_sessions` table (existing)
- `email_otp_sessions` table (existing)
- `user_sessions` table (new)

### Tests

- OTP send/verify
- Session creation/expiry
- CSRF validation
- Rate limiting

---

## Phase 2: Groups + Members

### Objectives

- Complete group CRUD
- Member management
- Invite system

### Dependencies

- Phase 1 complete

### Deliverables

| Deliverable | Files |
|-------------|-------|
| Create group | `api/trips.php`, `06-GROUPS.md` |
| Edit group | `api/trips.php` |
| Delete group | `api/trips.php` |
| Join by code | `api/trips.php` |
| Join by URL token | `api/trips.php` |
| Add/remove member | `api/members.php` |
| Member roles | `api/members.php` |
| Groups list screen | Web + Flutter |
| Group details screen | Web + Flutter |

### Database Changes

- `trips` table (existing, add group_type, is_archived)
- `trip_members` table (existing)

### Tests

- Group CRUD
- Member management
- Role permissions
- Invite code generation

---

## Phase 3: Expense Splitting

### Objectives

- Complete expense lifecycle
- All 5 split methods
- Balance calculation

### Dependencies

- Phase 2 complete

### Deliverables

| Deliverable | Files |
|-------------|-------|
| Add expense | `api/expenses.php`, `07-EXPENSES.md` |
| Edit expense | `api/expenses.php` |
| Delete expense | `api/transactions.php` |
| Equal split | `08-SPLIT-METHODS.md` |
| Exact split | `08-SPLIT-METHODS.md` |
| Percentage split | `08-SPLIT-METHODS.md` |
| Shares split | `08-SPLIT-METHODS.md` |
| Item-wise split | `08-SPLIT-METHODS.md` |
| Category selection | `api/categories.php` |
| Balance calculation | `includes/calculations.php` |
| Add expense screen | Web + Flutter |
| Expense detail screen | Web + Flutter |

### Database Changes

- `transactions` table (existing, add client_request_id, whatsapp_message_id)
- `expense_splits` table (existing)
- `expense_items` table (new)
- `expense_item_splits` table (new)
- `categories` table (existing, add user_id, type)

### Tests

- F1 invariant: all split methods
- Rounding edge cases
- Idempotency (F4)
- Category CRUD

---

## Phase 4: Settlements

### Objectives

- Balance display
- Debt simplification
- Settlement recording

### Dependencies

- Phase 3 complete

### Deliverables

| Deliverable | Files |
|-------------|-------|
| View balances | `api/settlements.php`, `09-SETTLEMENTS.md` |
| Debt simplification | `includes/calculations.php` |
| Record settlement | `api/settlements.php` |
| Partial settlement | `api/settlements.php` |
| Undo settlement | `api/settlements.php` |
| Settlement history | `api/settlements.php` |
| Settlement screen | Web + Flutter |

### Database Changes

- `settlements` table (existing)

### Tests

- F3 invariant: balance formula
- Debt simplification algorithm
- Partial settlement
- Settlement undo

---

## Phase 5: Personal Expenses

### Objectives

- First-class personal finance module
- Income/expense tracking
- Personal finance ledger

### Dependencies

- Phase 1 complete (independent of groups)

### Deliverables

| Deliverable | Files |
|-------------|-------|
| Add personal expense | `api/cashbook.php`, `10-PERSONAL-EXPENSES.md` |
| Add personal income | `api/cashbook.php` |
| Transaction history | `api/cashbook.php` |
| Running balance | `api/passbook.php` |
| Personal categories | `api/categories.php` |
| Personal dashboard | Web + Flutter |

### Database Changes

- None (uses existing `transactions` with `trip_id=NULL`)

### Tests

- Personal expense/income CRUD
- Balance calculation
- Category management

---

## Phase 6: Analytics

### Objectives

- Personal analytics
- Group analytics
- Visualizations

### Dependencies

- Phase 3, 5 complete

### Deliverables

| Deliverable | Files |
|-------------|-------|
| Personal income/expense totals | `12-ANALYTICS.md` |
| Category breakdown | `12-ANALYTICS.md` |
| Spending trends | `12-ANALYTICS.md` |
| Group analytics | `12-ANALYTICS.md` |
| Charts (donut, bar, line) | Web + Flutter |
| Analytics dashboard | Web + Flutter |

### Tests

- Analytics accuracy
- Chart rendering
- Date range filtering

---

## Phase 7: Bills/Reminders

### Objectives

- Recurring bills
- Due date tracking
- Reminders

### Dependencies

- Phase 5 complete

### Deliverables

| Deliverable | Files |
|-------------|-------|
| Recurring bills CRUD | `api/bills.php`, `11-BILLS-AND-REMINDERS.md` |
| Due date tracking | Background worker |
| Bill reminders | `25-NOTIFICATIONS.md` |
| Priority bills | `11-BILLS-AND-REMINDERS.md` |
| Bills screen | Web + Flutter |

### Database Changes

- `recurring_bills` table (new)

### Tests

- Bill CRUD
- Recurrence calculation
- Reminder scheduling

---

## Phase 8: Receipt/OCR

### Objectives

- Camera capture
- OCR processing
- Data extraction

### Dependencies

- Phase 3 complete

### Deliverables

| Deliverable | Files |
|-------------|-------|
| Camera capture | `18-RECEIPT-OCR.md` |
| Image upload | `18-RECEIPT-OCR.md` |
| Tesseract OCR | `services/ocr/` |
| Data extraction | `18-RECEIPT-OCR.md` |
| User review | Web + Flutter |
| Receipt storage | `storage/receipts/` |

### Database Changes

- `receipts` table (new)

### Tests

- Image upload
- OCR accuracy
- Data extraction

---

## Phase 9: WhatsApp

### Objectives

- OpenWA integration
- Message handling
- Guided expense flow

### Dependencies

- Phase 3, 17 complete

### Deliverables

| Deliverable | Files |
|-------------|-------|
| OpenWA adapter | `services/whatsapp/`, `15-WHATSAPP-INTEGRATION.md` |
| Message router | `15-WHATSAPP-INTEGRATION.md` |
| Registration check | `15-WHATSAPP-INTEGRATION.md` |
| Guided expense flow | `16-WHATSAPP-CONVERSATION-FLOWS.md` |
| Natural language parsing | `16-WHATSAPP-CONVERSATION-FLOWS.md` |
| Balance inquiry | `16-WHATSAPP-CONVERSATION-FLOWS.md` |
| Settlement recording | `16-WHATSAPP-CONVERSATION-FLOWS.md` |

### Database Changes

- `whatsapp_messages` table (new)
- `whatsapp_conversations` table (new)
- `whatsapp_conversation_state` table (new)
- `whatsapp_message_queue` table (new)

### Tests

- Message deduplication
- Intent parsing
- Conversation state machine
- Guided flow end-to-end

---

## Phase 10: AI/LLM

### Objectives

- Rule-based parsing
- Local LLM integration
- Cloud fallback

### Dependencies

- Phase 9 complete

### Deliverables

| Deliverable | Files |
|-------------|-------|
| Rule engine | `services/ai/RuleEngine.php`, `17-AI-AND-LLM.md` |
| Local LLM | `services/ai/LLMService.php` |
| Cloud fallback | `services/ai/LLMService.php` |
| Confidence scoring | `17-AI-AND-LLM.md` |
| Fallback behavior | `17-AI-AND-LLM.md` |

### Tests

- Rule matching accuracy
- LLM extraction accuracy
- Confidence thresholds
- Fallback triggers

---

## Phase 11: Advanced Imports

### Objectives

- CSV import
- Splitwise import
- Vendor integrations

### Dependencies

- Phase 3 complete

### Deliverables

| Deliverable | Files |
|-------------|-------|
| CSV import | `19-ONLINE-BILL-IMPORT.md` |
| Splitwise import | `14-REPORTS-IMPORT-EXPORT.md` |
| Screenshot import | `19-ONLINE-BILL-IMPORT.md` |
| PDF export | `14-REPORTS-IMPORT-EXPORT.md` |
| CSV export | `14-REPORTS-IMPORT-EXPORT.md` |

### Database Changes

- `imports` table (new)
- `imported_bills` table (new)
- `exports` table (new)

### Tests

- Import validation
- Conflict detection
- Export accuracy

---

## Phase 12: Admin + Production

### Objectives

- Admin panel
- Security hardening
- Performance optimization
- Production deployment

### Dependencies

- All previous phases complete

### Deliverables

| Deliverable | Files |
|-------------|-------|
| Admin dashboard | `admin/`, `28-ADMIN-PANEL.md` |
| User management | `28-ADMIN-PANEL.md` |
| System health | `28-ADMIN-PANEL.md` |
| Security headers | `26-SECURITY-PRIVACY.md` |
| Rate limiting | `26-SECURITY-PRIVACY.md` |
| Audit logs | `26-SECURITY-PRIVACY.md` |
| Load testing | `30-TESTING.md` |

### Database Changes

- `audit_logs` table (new)
- `admin_users` table (existing)

### Tests

- Security tests
- Load tests
- Admin CRUD
- Audit logging

---

## Timeline Estimate

| Phase | Duration | Dependencies |
|-------|----------|-------------|
| Phase 0 | Complete | — |
| Phase 1 | 1-2 weeks | Phase 0 |
| Phase 2 | 1 week | Phase 1 |
| Phase 3 | 2-3 weeks | Phase 2 |
| Phase 4 | 1 week | Phase 3 |
| Phase 5 | 1-2 weeks | Phase 1 |
| Phase 6 | 1 week | Phase 3, 5 |
| Phase 7 | 1 week | Phase 5 |
| Phase 8 | 1-2 weeks | Phase 3 |
| Phase 9 | 2-3 weeks | Phase 3, 17 |
| Phase 10 | 1-2 weeks | Phase 9 |
| Phase 11 | 1-2 weeks | Phase 3 |
| Phase 12 | 2-3 weeks | All |

**Total estimated**: 16-24 weeks (4-6 months)

---

## Dependencies Graph

```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4
                              ↓         ↓
Phase 1 → Phase 5 → Phase 6 ←──────────┘
                   ↓
              Phase 7
Phase 3 → Phase 8
Phase 3 → Phase 9 → Phase 10
Phase 3 → Phase 11
All → Phase 12
```

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should we parallelize independent phases? | Timeline |
| OQ-2 | Should we implement Phase 5 (Personal) in parallel with Phase 2-4? | Resource allocation |
| OQ-3 | What is the team size for this project? | Timeline adjustment |

---

## Dependencies

- All previous documentation files

## Related Documents

- `01-FEATURES.md` — Feature inventory
- `20-DATABASE-SCHEMA.md` — Database changes per phase
- `21-API-SPECIFICATION.md` — API endpoints per phase
- `30-TESTING.md` — Test strategy per phase
