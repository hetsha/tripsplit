# 30 — Testing

This document specifies the testing strategy: unit, integration, API, frontend, and financial calculation tests.

---

## 1. Testing Principles

| Principle | Description |
|-----------|-------------|
| Financial tests first | All calculation tests are P0 |
| Idempotency tests | Verify F4 invariant |
| Balance tests | Verify F3 invariant |
| Split tests | Verify F1 invariant |
| Cross-platform | Same backend, same results |

---

## 2. Test Types

### Unit Tests

| Module | Tests |
|--------|-------|
| `calculations.php` | Balance calculation, settlement algorithm |
| `validation.php` | Amount validation, split validation |
| `functions.php` | Utility functions |

### Financial Calculation Tests

| Test Case | Formula | Expected |
|-----------|---------|----------|
| Equal split 3 ways | 1500 / 3 | 500, 500, 500 |
| Uneven split | 1000 / 3 | 333.34, 333.33, 333.33 |
| Balance after settlement | F3 | Verified |
| Debt simplification | Greedy algorithm | Minimal transactions |
| F1 invariant | sum(splits) == total | Always true |

### Integration Tests

| Flow | Steps |
|------|-------|
| Create group → add expense → settle | Full lifecycle |
| Register → create group → add member → add expense | User onboarding |
| Expense creation with idempotency | Duplicate prevention |

### API Tests

| Endpoint | Method | Tests |
|----------|--------|-------|
| `otp.php` | POST | Send/verify OTP, rate limiting |
| `trips.php` | POST | CRUD, join, permissions |
| `expenses.php` | POST | Create, update, delete, F1 validation |
| `settlements.php` | POST | Record, undo, F3 verification |
| `cashbook.php` | POST | Personal expense/income |

### Frontend Tests

| Component | Tests |
|-----------|-------|
| Expense creation form | Validation, split calculation |
| Settlement flow | Confirmation, error handling |
| Navigation | Page loading, state management |

### Flutter Tests

| Component | Tests |
|-----------|-------|
| API client | Network requests, error handling |
| Models | JSON serialization |
| Services | Auth, expense, sync |

---

## 3. Test Data

### Seed Data

- 3 test users (Admin, User 2, User 3)
- 1 test group with 3 members
- 10 test expenses with splits
- 3 test settlements

### Edge Cases

| Case | Description |
|------|-------------|
| Zero amount | ₹0 expense |
| Maximum amount | ₹10,000,000 |
| Single participant | 1 person expense |
| 50 participants | Large group |
| Rounding edge | ₹10 / 3 |
| Circular debts | A→B, B→C, C→A |

---

## 4. Test Commands

```bash
# Unit tests
php vendor/bin/phpunit tests/unit/

# API tests
php vendor/bin/phpunit tests/api/

# Financial tests
php vendor/bin/phpunit tests/financial/

# Flutter tests
cd tripbook_flutter && flutter test
```

---

## 5. Security Tests

| Test | Description |
|------|-------------|
| SQL injection | Malicious input |
| XSS | Script injection |
| CSRF | Cross-site request forgery |
| Rate limiting | Abuse prevention |
| Authentication bypass | Session hijacking |

---

## 6. Load Tests

| Scenario | Target |
|----------|--------|
| Concurrent users | 100 |
| API response time | < 200ms |
| Database queries | < 50ms |
| Sync polling | 100 concurrent polls/minute |

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should we implement automated CI/CD testing? | DevOps scope |
| OQ-2 | What is the minimum test coverage target? | Quality bar |
| OQ-3 | Should we use a testing framework (PHPUnit)? | Tooling choice |

---

## Dependencies

- `07-EXPENSES.md` — Expense creation rules
- `08-SPLIT-METHODS.md` — Split calculations
- `09-SETTLEMENTS.md` — Settlement formulas
- `21-API-SPECIFICATION.md` — API contracts

## Related Documents

- `31-IMPLEMENTATION-ROADMAP.md` — Test phases
- `22-BACKEND-ARCHITECTURE.md` — Backend test structure
- `20-DATABASE-SCHEMA.md` — Test data models
