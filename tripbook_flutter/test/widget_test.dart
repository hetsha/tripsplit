// Basic Flutter widget test for TripSplit app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tripbook_flutter/main.dart';
import 'package:tripbook_flutter/services/auth_service.dart';
import 'package:tripbook_flutter/services/expense_service.dart';
import 'package:tripbook_flutter/theme/theme_notifier.dart';

void main() {
  testWidgets('TripSplit app smoke test', (WidgetTester tester) async {
    // Build our app with required providers and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => ExpenseService()),
        ],
        child: const TripSplitApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify app builds - MaterialApp should be present.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
