# TripBook Android Application (Flutter)

A premium shared-expense and personal-finance Android application for TripBook built with Flutter, Material 3, and Provider.

---

## Technical Specifications

- **Flutter version**: `3.35.6`
- **Dart version**: `3.9.2`
- **Theme**: Glassmorphism (Supports Light, Dark, and System modes)
- **State Management**: `Provider` (MVVM abstraction)
- **Networking**: `Dio` (Supports session cookies and CSRF protection)

---

## Folder Structure

```text
tripbook_flutter/
├── lib/
│   ├── core/
│   │   ├── api/
│   │   │   ├── api_client.dart
│   │   │   ├── api_endpoints.dart
│   │   │   └── api_exception.dart
│   │
│   ├── models/
│   │   ├── user.dart
│   │   ├── trip.dart
│   │   └── transaction.dart
│   │
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── expense_service.dart
│   │   └── sync_service.dart
│   │
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── theme_notifier.dart
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── trip_selector_screen.dart
│   │   ├── dashboard/
│   │   ├── transactions/
│   │   ├── people/
│   │   ├── settlements/
│   │   └── settings/
│   │
│   └── main.dart
```

---

## Getting Started

### Prerequisites

1. Install Flutter SDK: [Flutter Installation Guide](https://docs.flutter.dev/get-started/install)
2. Setup Android Studio and Android SDK Platform tools.
3. Ensure XAMPP or local web server is running.

---

### Configuration & Network Setup

#### 1. Android Emulator (Connecting to local XAMPP)
The Android Emulator loops back to your local development machine using:
`http://10.0.2.2/tripsplit/api/`

This is defined as the default base URL in [`lib/core/api/api_endpoints.dart`](file:///c:/xampp/htdocs/tripsplit/tripbook_flutter/lib/core/api/api_endpoints.dart).

#### 2. Physical Android Phone (Same local network)
To test on a physical device, both your development PC and your phone must be connected to the same Wi-Fi network.
- Determine your computer's local IP address (e.g. `192.168.1.15` using `ipconfig` on Windows command line).
- Update the API client base URL inside `main.dart` or call `ApiClient().setBaseUrl('http://192.168.1.15/tripsplit/api/')` during initialization.
- Configure XAMPP's Apache web server (`httpd.conf`) to listen on all interfaces:
  `Listen 80` (ensure it is not bound to `127.0.0.1:80`).

#### 3. Production HTTPS API
For production, update the API Base URL to use your production domain:
`https://your-domain.com/tripsplit/api/`

Ensure your production API operates over secure `HTTPS`.

---

## Build & Run

### 1. Resolve Dependencies
Download the required packages by running:
```bash
flutter pub get
```

### 2. Run Debug Mode
Ensure your simulator is running or device is connected, then run:
```bash
flutter run
```

### 3. Generate Android Release Build (APK)
To package the app into a signed production APK:
```bash
flutter build apk --release
```
The outputs will be generated under:
`build/app/outputs/flutter-apk/app-release.apk`

---

## Real-Time Synchronization & Offline Awareness

- **Interval Sync**: Polling `/api/sync.php` every 6 seconds checks the version hash.
- **Auto-Pause**: If the app transitions to the background or if network connectivity drops, aggressive polling is paused automatically.
- **Offline Banner**: An alert banner will overlay at the top of the interface notifying the user when they are viewing offline cached ledgers.

---

## Troubleshooting

1. **Connection Timeout Errors**:
   - Double check XAMPP server status.
   - Verify that your emulator/device has active internet connectivity.
   - Confirm firewall permissions don't intercept incoming local ports (`80` or default Apache port).
2. **Session Reset / 401 Unauthorized**:
   - If user credentials expire, `ApiClient` interceptors trigger the `clearSession()` method, automatically routing the user back to the login screen without crashing.
