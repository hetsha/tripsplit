# 24 — Flutter Architecture

This document specifies the Flutter Android application architecture: folder structure, state management, API layer, models, and services.

---

## 1. Technology Stack

| Component | Technology |
|-----------|-----------|
| Framework | Flutter 3.9+ |
| Language | Dart |
| State Management | Provider |
| Networking | Dio |
| Secure Storage | flutter_secure_storage |
| Charts | fl_chart |
| Icons | lucide_icons |
| Local Storage | shared_preferences |

---

## 2. Directory Structure

```
tripbook_flutter/
├── lib/
│   ├── main.dart                    # Entry point, Provider setup
│   ├── core/
│   │   └── api/
│   │       ├── api_client.dart      # Dio singleton, interceptors
│   │       ├── api_endpoints.dart   # Endpoint constants
│   │       └── api_exception.dart   # Error handling
│   ├── features/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── trip_selector_screen.dart
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart
│   │   ├── expenses/
│   │   │   └── add_expense_screen.dart
│   │   ├── groups/
│   │   │   └── groups_list_screen.dart
│   │   ├── cashbook/
│   │   │   └── cashbook_screen.dart
│   │   ├── passbook/
│   │   │   └── passbook_screen.dart
│   │   ├── people/
│   │   │   └── people_screen.dart
│   │   ├── settlements/
│   │   │   └── settlements_screen.dart
│   │   ├── transactions/
│   │   │   └── transactions_screen.dart
│   │   ├── settings/
│   │   │   └── more_screen.dart
│   │   └── home_coordinator.dart    # Tab navigation, FAB
│   ├── models/
│   │   ├── user.dart
│   │   ├── trip.dart
│   │   └── transaction.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── expense_service.dart
│   │   └── sync_service.dart
│   ├── theme/
│   │   ├── app_theme.dart           # Design tokens
│   │   └── theme_notifier.dart      # Light/dark toggle
│   └── widgets/
│       └── floating_bottom_nav.dart
├── android/
├── test/
└── pubspec.yaml
```

---

## 3. State Management

### Provider Setup

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeNotifier()),
    ChangeNotifierProvider(create: (_) => AuthService()),
    ChangeNotifierProvider(create: (_) => ExpenseService()),
  ],
  child: MaterialApp(...),
)
```

### Theme Notifier

```dart
class ThemeNotifier extends ChangeNotifier {
    ThemeMode _themeMode = ThemeMode.system;
    ThemeMode get themeMode => _themeMode;
    
    void toggleTheme() {
        _themeMode = _themeMode == ThemeMode.dark 
            ? ThemeMode.light 
            : ThemeMode.dark;
        notifyListeners();
    }
}
```

---

## 4. API Client

### Dio Singleton

```dart
class ApiClient {
    static final ApiClient _instance = ApiClient._internal();
    factory ApiClient() => _instance;
    
    late Dio _dio;
    
    ApiClient._internal() {
        _dio = Dio(BaseOptions(
            baseUrl: 'http://192.168.1.11/tripsplit/api/',
            contentType: 'application/json',
        ));
        
        _dio.interceptors.add(SessionInterceptor());
        _dio.interceptors.add(CsrfInterceptor());
    }
}
```

### Interceptors

```dart
class SessionInterceptor extends Interceptor {
    @override
    void onRequest(options, handler) {
        final session = FlutterSecureStorage().read(key: 'session');
        options.headers['Cookie'] = 'PHPSESSID=$session';
        handler.next(options);
    }
    
    @override
    void onError(dioException, handler) {
        if (dioException.response?.statusCode == 401) {
            // Auto-logout
            AuthService().logout();
        }
        handler.next(dioException);
    }
}
```

---

## 5. Models

### User Model

```dart
class User {
    final int id;
    final String name;
    final String? email;
    final String? phone;
    final String avatarColor;
    
    factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        phone: json['phone'],
        avatarColor: json['avatar_color'],
    );
}
```

### Trip Model

```dart
class Trip {
    final int id;
    final String tripCode;
    final String name;
    final String currencySymbol;
    final String role;
    
    factory Trip.fromJson(Map<String, dynamic> json) => Trip(...);
}
```

### Transaction Model

```dart
class Transaction {
    final int id;
    final String type;
    final double amount;
    final String description;
    final String? categoryName;
    final String? paidByName;
    final DateTime transactionDate;
    
    List<TransactionSplit> splits;
    
    factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(...);
}

class TransactionSplit {
    final int userId;
    final String name;
    final double amount;
}
```

---

## 6. Services

### Auth Service

```dart
class AuthService extends ChangeNotifier {
    User? _user;
    List<Trip> _trips = [];
    Trip? _activeTrip;
    
    Future<void> login(String phone, String otp) async { ... }
    Future<void> logout() async { ... }
    Future<void> switchTrip(int tripId) async { ... }
}
```

### Sync Service

```dart
class SyncService {
    Timer? _timer;
    
    void startSyncing() {
        _timer = Timer.periodic(Duration(seconds: 6), (_) => checkForUpdates());
    }
    
    Future<void> checkForUpdates() async {
        final res = await ApiClient().get('sync.php', params: {
            'trip_id': activeTripId,
            'version': lastVersion,
        });
        if (res.data['has_changes']) {
            refreshData();
        }
    }
}
```

---

## 7. Navigation

### Home Coordinator

```dart
class HomeCoordinator extends StatefulWidget {
    int _currentTab = 0;
    final List<Widget> _pages = [
        DashboardScreen(),
        TransactionsScreen(),
        PeopleScreen(),
        SettlementsScreen(),
        MoreScreen(),
    ];
    
    @override
    Widget build(BuildContext context) {
        return Scaffold(
            body: _pages[_currentTab],
            bottomNav: FloatingBottomNav(
                currentIndex: _currentTab,
                onTap: (i) => setState(() => _currentTab = i),
            ),
            floatingActionButton: FloatingActionButton(
                onPressed: () => _showExpenseMenu(context),
                child: Icon(Icons.add),
            ),
        );
    }
}
```

---

## 8. Theme

### Design Tokens (from `04-DESIGN-SYSTEM.md`)

```dart
class AppColors {
    static const Color primary = Color(0xFF6C63FF);
    static const Color positive = Color(0xFF10B981);
    static const Color negative = Color(0xFFF43F5E);
    // ... all tokens from design system
}
```

### Glassmorphism Card

```dart
class GlassCard extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                    decoration: BoxDecoration(
                        color: isDark ? Color(0xFF0B1020) : Color(0xFFFFFFFF),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: child,
                ),
            ),
        );
    }
}
```

---

## 9. Offline Support

### Local Storage

```dart
// Store last-known data for offline display
class LocalCache {
    Future<void> saveDashboard(DashboardData data) async {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('dashboard_cache', jsonEncode(data.toJson()));
    }
    
    Future<DashboardData?> getDashboard() async {
        final prefs = await SharedPreferences.getInstance();
        final json = prefs.getString('dashboard_cache');
        return json != null ? DashboardData.fromJson(jsonDecode(json)) : null;
    }
}
```

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should we migrate to Riverpod for state management? | Architecture |
| OQ-2 | Should we implement local SQLite for offline? | Storage complexity |
| OQ-3 | Should we support iOS in the future? | Cross-platform scope |

---

## Dependencies

- `04-DESIGN-SYSTEM.md` — Design tokens
- `21-API-SPECIFICATION.md` — API endpoints
- `22-BACKEND-ARCHITECTURE.md` — Backend integration

## Related Documents

- `04-DESIGN-SYSTEM.md` — Design tokens (Flutter mapping)
- `22-BACKEND-ARCHITECTURE.md` — Backend
- `23-FRONTEND-ARCHITECTURE.md` — Web counterpart
- `27-SYNC-OFFLINE.md` — Sync implementation
