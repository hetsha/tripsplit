# 13 — People and Friends

This document specifies the social graph: people list, friend connections, and person details.

---

## 1. People List

### Purpose

View all users the current user has interacted with across all groups.

### Data Source

People are derived from:
- Members of groups the user belongs to
- Users the user has settled with
- Users who have shared expenses with the user

### Response Format

```json
{
  "people": [
    {
      "id": 2,
      "name": "Akshat",
      "avatar_color": "#10b981",
      "phone": "+919999999999",
      "mutual_groups": 3,
      "net_balance": 800.00,
      "last_interaction": "2026-09-15"
    }
  ]
}
```

### Sorting

Default: Sort by most recent interaction, then alphabetically.

### API Endpoints

| Endpoint | Method | Action |
|----------|--------|--------|
| `api/members.php` | GET | List people across groups |

---

## 2. Person Details

### Sections

1. **Profile**: Name, avatar, phone, email
2. **Mutual Groups**: Groups shared with this person
3. **Balance Summary**: Net balance across all mutual groups
4. **Recent Shared Expenses**: Last 10 expenses involving both users
5. **Settlement History**: Past settlements between users

### Balance Calculation Per Person

```
For each mutual group:
  net_balance = (user_paid - user_share) - settlements_received + settlements_sent
  (F3 formula applied per group)
```

### API Endpoints

| Endpoint | Method | Action |
|----------|--------|--------|
| `api/members.php` | GET (person_id) | Get person details |

---

## 3. Add Friend

### Flow

```
User enters phone number or email
  → System searches users table
  → Decision: User found?
    → YES: Show profile, confirm add
    → NO: "User not found. Invite them to join TripBook!"
  → If found: Add to friend list (if friend system is implemented)
```

### Friend Request/Accept (Future)

| State | Description |
|-------|-------------|
| `pending` | Request sent, awaiting acceptance |
| `accepted` | Mutual friends |
| `blocked` | One user blocked the other |

> **Current**: No formal friend request system. People are connected through shared groups.

---

## 4. Send Payment Reminder

### Via App

```
User selects person → Person Details → "Remind"
  → System calculates outstanding balance
  → System shows: "Remind Akshat to pay ₹800?"
  → User confirms
  → System sends in-app notification to Akshat
```

### Via WhatsApp

```
User: "Remind Rahul to pay"
  → System checks Rahul's phone number
  → System calculates: Rahul owes ₹500
  → System sends WhatsApp message to Rahul:
    "Hi Rahul! Reminder from TripBook:
     You owe ₹500 in the 'Goa Trip' group.
     Please settle up when convenient. 🙏"
```

### Notification Content

```
In-app: "You sent a payment reminder to {name} for ₹{amount}"
WhatsApp to debtor: "Reminder: You owe ₹{amount} to {sender} in {group}"
```

---

## 5. Mutual Groups View

### Purpose

See which groups both users belong to.

### Response

```json
{
  "mutual_groups": [
    {
      "id": 1,
      "name": "Goa Trip",
      "your_balance": 800.00,
      "their_balance": -800.00
    },
    {
      "id": 3,
      "name": "College Friends",
      "your_balance": -200.00,
      "their_balance": 200.00
    }
  ]
}
```

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should there be a formal friend request system? | Feature scope |
| OQ-2 | Should people list show users from deleted groups? | Data retention |
| OQ-3 | Should we support blocking people? | Privacy feature |

---

## Dependencies

- `05-AUTHENTICATION.md` — User identity
- `06-GROUPS.md` — Group membership
- `09-SETTLEMENTS.md` — Balance calculations

## Related Documents

- `06-GROUPS.md` — Group membership
- `09-SETTLEMENTS.md` — Settlements
- `20-DATABASE-SCHEMA.md` — Users, group_members tables
- `21-API-SPECIFICATION.md` — People API endpoints
- `16-WHATSAPP-CONVERSATION-FLOWS.md` — WhatsApp reminder flow
