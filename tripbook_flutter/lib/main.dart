import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/expense_service.dart';
import 'theme/theme_notifier.dart';
import 'theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/groups/groups_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ExpenseService()),
      ],
      child: const TripBookApp(),
    ),
  );
}

class TripBookApp extends StatefulWidget {
  const TripBookApp({Key? key}) : super(key: key);

  @override
  State<TripBookApp> createState() => _TripBookAppState();
}

class _TripBookAppState extends State<TripBookApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthService>(context, listen: false).checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final auth = Provider.of<AuthService>(context);

    return MaterialApp(
      title: 'SplitBook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.themeMode,
      home: _resolveAppHome(auth.state),
    );
  }

  Widget _resolveAppHome(AuthState state) {
    switch (state) {
      case AuthState.uninitialized:
      case AuthState.loading:
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.explore_rounded, size: 64, color: AppColors.primary),
                SizedBox(height: 16),
                CircularProgressIndicator(strokeWidth: 2),
              ],
            ),
          ),
        );
      case AuthState.unauthenticated:
        return const LoginScreen();
      case AuthState.authenticated:
        return const GroupsListScreen();
    }
  }
}
