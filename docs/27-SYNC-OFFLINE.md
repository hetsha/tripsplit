# 27 — Sync and Offline

This document specifies data synchronization between web and Flutter, offline transaction support, and conflict resolution.

---

## 1. Architecture

> Web and Flutter use the **same backend and database**. There is no separate sync server — both clients read/write directly to MySQL.

---

## 2. Incremental Sync

### Hash-Based Polling

```
Client polls GET /api/sync.php every 6 seconds:
  - Sends: trip_id, current version hash
  - Server computes: MD5 hash of latest data
  - If hashes match: no changes
  - If hashes differ: client refreshes data
```

### Version Hash Computation

```sql
-- Server computes hash from latest data
SELECT MD5(CONCAT(
    MAX(updated_at),
    (SELECT COUNT(*) FROM transactions WHERE trip_id = ?),
    (SELECT COUNT(*) FROM settlements WHERE trip_id = ?)
)) as version FROM trips WHERE id = ?
```

---

## 3. Optimistic Updates

### Pattern

```
1. User performs action (e.g., add expense)
2. Client immediately updates UI (optimistic)
3. Client sends request to backend
4. Backend validates and saves
5. If success: confirm UI update
6. If failure: revert UI, show error
```

### Benefits

- Feels instant to user
- No loading spinners for common actions
- Falls back gracefully on failure

---

## 4. Offline Transactions

### Flutter Offline Support

| Rule | Value |
|------|-------|
| Queue storage | SQLite or SharedPreferences |
| Max queue size | 50 transactions |
| Sync trigger | Network reconnect + every 30 seconds |
| Conflict resolution | Last-write-wins (server timestamp) |

### Offline Queue Entry

```json
{
  "client_request_id": "uuid-offline-1234",
  "action": "create_expense",
  "data": { "amount": 1500, "description": "Dinner", ... },
  "created_at": "2026-09-15T19:30:00Z",
  "status": "pending",
  "attempts": 0
}
```

### Sync Process

```
Network available:
  1. Load pending transactions from queue
  2. For each transaction:
     - Send to backend with client_request_id
     - Backend checks for duplicates (F4)
     - If new: create and return success
     - If duplicate: return existing record
  3. Mark as synced in queue
  4. Refresh local data from server
```

---

## 5. Conflict Resolution

### Strategy: Last-Write-Wins

| Scenario | Resolution |
|----------|-----------|
| Same expense edited offline on two devices | Server keeps latest `updated_at` |
| Same expense created twice | `client_request_id` prevents duplicate (F4) |
| Settlement recorded offline + online | `client_request_id` prevents duplicate |

### Conflict Detection

```sql
-- Server checks if record was modified since client last fetched
SELECT updated_at FROM transactions WHERE id = ? AND updated_at > ?
```

---

## 6. Idempotency (F4)

### Client Request ID

- Every create/update sends `client_request_id` (UUID)
- Server checks: `SELECT id FROM transactions WHERE client_request_id = ?`
- If exists: return existing record (no new creation)
- If not: create new record

### WhatsApp Dedup

- `whatsapp_message_id` checked before processing
- Prevents duplicate actions from message replays

---

## 7. Retry Queue

### Pattern

```
Request fails:
  → Add to retry queue with exponential backoff:
    - Attempt 1: immediate
    - Attempt 2: 1 second
    - Attempt 3: 5 seconds
    - Attempt 4: 30 seconds
    - Attempt 5: 5 minutes
    → After 5 failures: show error, require manual retry
```

---

## 8. Real-Time Updates (Future)

### WebSocket Architecture

```
Client connects via WebSocket
  → Server pushes updates when data changes
  → Client receives update, refreshes affected sections
```

### Status

Not yet implemented. Currently using 6-second polling.

---

## 9. Sync Status Indicators

### Web

- Green dot: synced
- Yellow dot: syncing
- Red dot: offline/error
- "Offline" banner: when network unavailable

### Flutter

- Same indicators in app bar
- "Offline mode" banner
- Pending transactions count badge

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should we implement WebSocket for real-time updates? | Complexity vs. UX |
| OQ-2 | Should offline queue persist across app restarts? | Storage strategy |
| OQ-3 | What is the max offline queue size before blocking user? | UX policy |

---

## Dependencies

- `23-FRONTEND-ARCHITECTURE.md` — Web sync implementation
- `24-FLUTTER-ARCHITECTURE.md` — Flutter sync implementation
- `21-API-SPECIFICATION.md` — Sync API endpoint
- `07-EXPENSES.md` — Idempotency rules

## Related Documents

- `23-FRONTEND-ARCHITECTURE.md` — Web architecture
- `24-FLUTTER-ARCHITECTURE.md` — Flutter architecture
- `21-API-SPECIFICATION.md` — API contracts
