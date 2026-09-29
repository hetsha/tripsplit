import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/expense_service.dart';
import 'theme/theme_notifier.dart';
import 'theme/app_theme.dart';

// TripSplit Screens
import 'features/home/all_groups_home_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/trips/create_trip_screen.dart';
import 'features/dashboard/trip_dashboard_screen.dart';
import 'features/expenses/add_expense_screen.dart';
import 'features/expenses/all_expenses_screen.dart';
import 'features/settlements/settle_up_screen.dart';
import 'features/settlements/trip_settled_screen.dart';
import 'features/gallery/trip_gallery_screen.dart';
import 'features/members/trip_members_screen.dart';
import 'features/settings/trip_settings_screen.dart';
import 'features/profile/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ExpenseService()),
      ],
      child: const TripSplitApp(),
    ),
  );
}

class TripSplitApp extends StatelessWidget {
  const TripSplitApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: 'TripSplit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.themeMode,
      initialRoute: '/home',
      routes: {
        '/home': (context) => const AllGroupsHomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/create_trip': (context) => const CreateTripScreen(),
        '/dashboard': (context) => const TripDashboardScreen(),
        '/add_expense': (context) => const AddExpenseScreen(),
        '/all_expenses': (context) => const AllExpensesScreen(),
        '/settle_up': (context) => const SettleUpScreen(),
        '/trip_settled': (context) => const TripSettledScreen(),
        '/gallery': (context) => const TripGalleryScreen(),
        '/members': (context) => const TripMembersScreen(),
        '/trip_settings': (context) => const TripSettingsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
