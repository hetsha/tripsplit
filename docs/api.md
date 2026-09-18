# TripBook REST API Documentation (LEGACY)

> **⚠️ DEPRECATED**: This document is a legacy API reference from the original implementation. It is preserved for reference during migration only. The canonical API specification is in `21-API-SPECIFICATION.md`. Do not follow this document for new development — it contains obsolete product concepts (CashBook, starting money, shared cash pool) that are no longer part of the product.

---

This document specifies the REST API contract for communicating with the TripBook PHP backend.

---

## Base Configuration

- **API Base URL**: `http://<host>/api/` (e.g. `http://10.0.2.2/api/` inside Android Emulator).
- **Protocol**: HTTP/HTTPS.
- **Content Type**: `application/json` for requests and responses.
- **Session Authentication**: Handled via PHP session cookies (`PHPSESSID`).
- **CSRF Protection**: All `POST` requests require the header `X-CSRF-Token` (or a `csrf_token` field in the request payload). The token can be retrieved from `GET api/auth.php?action=me` upon successful authentication.

---

## Authentication Endpoints

### 1. Send OTP (Phone)
Generates and sends a 6-digit OTP to the phone number.
- **Method**: `POST`
- **URL**: `api/otp.php?action=send_otp`
- **Payload**:
  ```json
  {
    "phone": "+919999999999"
  }
  ```
- **Response (Success)**:
  ```json
  {
    "success": true,
    "message": "OTP sent successfully"
  }
  ```

---

### 2. Verify OTP (Phone)
Verifies the OTP code and creates the session.
- **Method**: `POST`
- **URL**: `api/otp.php?action=verify_otp`
- **Payload**:
  ```json
  {
    "phone": "+919999999999",
    "otp_code": "123456"
  }
  ```
- **Response (Success)**:
  ```json
  {
    "success": true,
    "message": "Verification successful",
    "data": {
      "user": {
        "id": 1,
        "name": "Het Shah",
        "email": "het@example.com",
        "phone": "+919999999999",
        "avatar_color": "#2563eb"
      },
      "trips": [
        {
          "id": 12,
          "trip_code": "TRIP-DXQAT",
          "name": "Udaipur Trip",
          "currency_symbol": "₹",
          "role": "owner"
        }
      ],
      "is_new_user": false,
      "needs_phone": false
    }
  }
  ```

---

### 3. Get Session / Current User Info
Retrieves details of the currently logged-in user, their trips, and current active trip ID.
- **Method**: `GET`
- **URL**: `api/auth.php?action=me`
- **Response (Success)**:
  ```json
  {
    "success": true,
    "message": "User profile",
    "data": {
      "user": {
        "id": 1,
        "name": "Het Shah",
        "email": "het@example.com",
        "phone": "+919999999999",
        "avatar_color": "#2563eb"
      },
      "csrf_token": "a1b2c3d4...",
      "trips": [ ... ],
      "active_trip": 12
    }
  }
  ```

---

## Trip Endpoints

### 1. Switch Active Trip
Switches the active trip context for the user session.
- **Method**: `POST`
- **URL**: `api/auth.php?action=switch_trip`
- **Payload**:
  ```json
  {
    "trip_id": 12
  }
  ```
- **Response (Success)**:
  ```json
  {
    "success": true,
    "message": "Switched trip",
    "data": {
      "active_trip_id": 12
    }
  }
  ```

---

## Sync Endpoint

### 1. Check Real-Time Sync Status
Fast hashing check to determine if the client's cached state is out of sync with the database.
- **Method**: `GET`
- **URL**: `api/sync.php`
- **Query Parameters**:
  - `trip_id`: (integer) ID of the active trip.
  - `version`: (string) Client's currently cached MD5 version hash.
- **Response (Success)**:
  ```json
  {
    "success": true,
    "message": "Sync status",
    "data": {
      "trip_id": 12,
      "has_changes": true,
      "version": "60a4f553a...",
      "last_update": "2026-08-24 16:30:00"
    }
  }
  ```

---

## Dashboard Endpoint

### 1. Fetch Dashboard Stats
Fetches active shared pool money, payment method cash breakdowns, balances, settlements, category totals, and recent transaction timeline entries.
- **Method**: `GET`
- **URL**: `api/dashboard.php`
- **Response (Success)**:
  ```json
  {
    "success": true,
    "message": "Dashboard data",
    "data": {
      "expense_summary": {
        "total_all_expenses": 900.00,
        "expense_count": 1
      },
      "member_balances": [
        {
          "user_id": 1,
          "name": "Het Shah",
          "net_balance": -300.00
        }
      ],
      "who_owes_whom": [
        {
          "from_user_id": 2,
          "from_name": "Akshat",
          "to_user_id": 1,
          "to_name": "Het Shah",
          "amount": 300.00
        }
      ],
      "recent_transactions": [
        {
          "id": 45,
          "type": "expense",
          "amount": 900.00,
          "description": "Dinner",
          "payment_method": "cash",
          "formatted_amount": "₹900",
          "formatted_date": "Aug 24, 12:40 PM"
        }
      ]
    }
  }
  ```

---

## Expense Endpoints

### 1. Create shared/personal expense
Creates a new expense and records splits.
- **Method**: `POST`
- **URL**: `api/expenses.php`
- **Headers**:
  - `X-CSRF-Token`: (required)
- **Payload**:
  ```json
  {
    "action": "create",
    "amount": 900.00,
    "description": "Dinner",
    "category_id": 4,
    "paid_by": 2,
    "payment_method": "upi",
    "notes": "Had dinner at Lake view",
    "is_personal": false,
    "client_request_id": "uuid-1234-5678",
    "splits": [
      { "user_id": 1, "amount": 300.00 },
      { "user_id": 2, "amount": 300.00 },
      { "user_id": 3, "amount": 300.00 }
    ]
  }
  ```
- **Response (Success)**:
  ```json
  {
    "success": true,
    "message": "Expense saved successfully!"
  }
  ```

---

### 2. Update existing expense
- **Method**: `POST`
- **URL**: `api/expenses.php`
- **Payload**:
  Same as create, but with `"action": "update"` and an `"id": 45` parameter representing the transaction ID.

---

### 3. Delete transaction
- **Method**: `POST`
- **URL**: `api/transactions.php`
- **Payload**:
  ```json
  {
    "action": "delete",
    "id": 45
  }
  ```
- **Response (Success)**:
  ```json
  {
    "success": true,
    "message": "Transaction deleted"
  }
  ```
