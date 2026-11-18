import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expense_journal_budget/core/storage/cache_manager.dart';
import 'package:expense_journal_budget/features/analytics/presentation/analytics_screen.dart';
import 'package:expense_journal_budget/features/authentication/presentation/auth_screens.dart';
import 'package:expense_journal_budget/features/dashboard/presentation/home_screen.dart';
import 'package:expense_journal_budget/features/expenses/presentation/add_transaction_screen.dart';
import 'package:expense_journal_budget/features/settings/presentation/budgets_screen.dart';
import 'package:expense_journal_budget/features/settings/presentation/categories_screen.dart';
import 'package:expense_journal_budget/features/settings/presentation/google_sheets_connection_screen.dart';
import 'package:expense_journal_budget/features/settings/presentation/notifications_screen.dart';
import 'package:expense_journal_budget/features/settings/presentation/privacy_screen.dart';
import 'package:expense_journal_budget/features/settings/presentation/profile_screen.dart';
import 'package:expense_journal_budget/features/settings/presentation/salary_screen.dart';
import 'package:expense_journal_budget/features/settings/presentation/settings_screen.dart';
import 'package:expense_journal_budget/features/transactions/presentation/edit_transaction_screen.dart';
import 'package:expense_journal_budget/features/transactions/presentation/journal_screen.dart';
import 'package:expense_journal_budget/features/transactions/presentation/transaction_detail_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en_IN');
    SharedPreferences.setMockInitialValues(<String, Object>{
      'connected_spreadsheet_id': 'test-sheet-123',
      'cached_selected_currency': 'INR',
    });
  });

  Widget createTestApp(Widget child) {
    return ProviderScope(
      overrides: [
        cacheManagerProvider.overrideWithValue(InMemoryCacheManager()),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: child,
        ),
      ),
    );
  }

  group('All App Screens Render & Layout Verification', () {
    testWidgets('SplashScreen renders without error', (tester) async {
      await tester.pumpWidget(createTestApp(const SplashScreen()));
      expect(find.text('Expense Journal & Budget'), findsOneWidget);
    });

    testWidgets('OnboardingScreen renders with page indicator and button', (tester) async {
      await tester.pumpWidget(createTestApp(const OnboardingScreen()));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('LoginScreen renders Google sign in action', (tester) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('HomeScreen renders balance and dashboard elements', (tester) async {
      await tester.pumpWidget(createTestApp(const Scaffold(body: HomeScreen())));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('MONTHLY BALANCE'), findsOneWidget);
    });

    testWidgets('JournalScreen renders filters and empty state', (tester) async {
      await tester.pumpWidget(createTestApp(const Scaffold(body: JournalScreen())));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Expense Journal'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('AnalyticsScreen renders insights header and segments', (tester) async {
      await tester.pumpWidget(createTestApp(const Scaffold(body: AnalyticsScreen())));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Analytics'), findsOneWidget);
    });

    testWidgets('BudgetsScreen renders', (tester) async {
      await tester.pumpWidget(createTestApp(const BudgetsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Budgets'), findsOneWidget);
    });

    testWidgets('CategoriesScreen renders with tabs', (tester) async {
      await tester.pumpWidget(createTestApp(const CategoriesScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Categories'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders all navigation groups', (tester) async {
      await tester.pumpWidget(createTestApp(const SettingsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Monthly salary'), findsOneWidget);
      expect(find.text('Google Sheets'), findsOneWidget);
    });

    testWidgets('SalaryScreen renders form inputs', (tester) async {
      await tester.pumpWidget(createTestApp(const SalaryScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Monthly salary'), findsWidgets);
    });

    testWidgets('ProfileScreen renders account section', (tester) async {
      await tester.pumpWidget(createTestApp(const ProfileScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Data ownership'), findsOneWidget);
    });

    testWidgets('NotificationsScreen renders toggles', (tester) async {
      await tester.pumpWidget(createTestApp(const NotificationsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Budget progress reminders'), findsOneWidget);
    });

    testWidgets('PrivacyScreen renders privacy details', (tester) async {
      await tester.pumpWidget(createTestApp(const PrivacyScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Privacy and data'), findsOneWidget);
      expect(find.text('Spreadsheet access'), findsOneWidget);
    });

    testWidgets('AddTransactionScreen renders transaction forms', (tester) async {
      await tester.pumpWidget(createTestApp(const AddTransactionScreen(initialType: 'expense')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Add transaction'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
    });

    testWidgets('EditTransactionScreen renders edit form with transaction ID', (tester) async {
      await tester.pumpWidget(createTestApp(const EditTransactionScreen(transactionId: 'test-123')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Edit transaction'), findsOneWidget);
    });

    testWidgets('TransactionDetailScreen renders transaction detail view', (tester) async {
      await tester.pumpWidget(createTestApp(const TransactionDetailScreen(transactionId: 'test-123')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Transaction details'), findsOneWidget);
    });

    testWidgets('GoogleSheetsConnectionScreen renders connection actions', (tester) async {
      await tester.pumpWidget(createTestApp(const GoogleSheetsConnectionScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Google Sheets connection'), findsOneWidget);
      expect(find.text('Create a new workbook'), findsOneWidget);
      expect(find.text('Use an existing workbook'), findsOneWidget);
    });
  });
}
