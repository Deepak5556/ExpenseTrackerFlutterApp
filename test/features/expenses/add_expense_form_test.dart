import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expense_journal_budget/core/storage/cache_manager.dart';
import 'package:expense_journal_budget/features/data/expense_data_provider.dart';
import 'package:expense_journal_budget/features/expenses/presentation/add_transaction_screen.dart';
import 'package:expense_journal_budget/features/transactions/application/transactions_controller.dart';
import 'package:expense_journal_budget/models/category_model.dart';
import 'package:expense_journal_budget/models/transaction_model.dart';
import 'package:expense_journal_budget/repositories/category_repository.dart';
import 'package:expense_journal_budget/repositories/expense_repository_v4.dart';
import 'package:expense_journal_budget/services/google_sheets_service.dart';

class FakeExpenseRepositoryV4 implements ExpenseRepositoryV4 {
  bool shouldFail = false;
  bool shouldDelay = false;
  final List<TransactionModel> saved = <TransactionModel>[];

  @override
  Future<void> append(TransactionModel item) async {
    if (shouldDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    if (shouldFail) {
      throw Exception('Simulated network error');
    }
    saved.add(item);
  }

  @override
  Future<void> update(TransactionModel item) async {
    if (shouldFail) throw Exception('Simulated update error');
  }

  @override
  Future<void> delete(TransactionModel item) async {}

  @override
  Future<SheetReadResult> readAll() async {
    return SheetReadResult(
      transactions: saved,
      settingsRows: const <List<Object?>>[],
      categoryRows: const <List<Object?>>[],
      invalidRows: 0,
    );
  }
}

class FakeCategoryRepository implements CategoryRepository {
  List<CategoryModel> categories = CategoriesController.defaultCategories;
  @override
  Future<List<CategoryModel>> readCategories() async => categories;
  @override
  Future<void> saveCategories(List<CategoryModel> cats) async {
    categories = cats;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en_IN');
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Widget buildTestScreen({
    required FakeExpenseRepositoryV4 fakeRepo,
    String initialType = 'expense',
    String? transactionId,
  }) {
    return ProviderScope(
      overrides: [
        cacheManagerProvider.overrideWithValue(InMemoryCacheManager()),
        sheetsExpenseRepositoryProvider.overrideWithValue(fakeRepo),
        categoryRepositoryProvider.overrideWithValue(FakeCategoryRepository()),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: AddTransactionScreen(
            initialType: initialType,
            transactionId: transactionId,
          ),
        ),
      ),
    );
  }

  group('Add Transaction Form Widget Tests', () {
    testWidgets('Empty submit displays inline validation errors', (
      WidgetTester tester,
    ) async {
      final fakeRepo = FakeExpenseRepositoryV4();
      await tester.pumpWidget(buildTestScreen(fakeRepo: fakeRepo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap the save button without typing
      final saveButton = find.byType(FilledButton);
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pump();

      // Check inline validation error messages
      expect(find.text('Amount is required'), findsOneWidget);
      expect(find.text('Title is required'), findsOneWidget);
      expect(find.text('Please choose a category'), findsOneWidget);
      expect(fakeRepo.saved, isEmpty);
    });

    testWidgets('Disables save button and displays progress while saving', (
      WidgetTester tester,
    ) async {
      final fakeRepo = FakeExpenseRepositoryV4()..shouldDelay = true;
      await tester.pumpWidget(buildTestScreen(fakeRepo: fakeRepo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Fill in amount
      await tester.enterText(
        find.widgetWithText(TextFormField, '').first,
        '250.50',
      );

      // Select a category chip
      final foodChip = find.widgetWithText(ChoiceChip, 'Food & Dining');
      expect(foodChip, findsOneWidget);
      await tester.tap(foodChip);
      await tester.pump();

      // Fill in title
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Lunch with team',
      );
      await tester.pump();

      // Tap Save
      await tester.tap(find.byType(FilledButton));
      await tester.pump(); // Enter saving state

      // Save button text updates to progress state
      expect(find.text('Saving to Google Sheets…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Let the delayed future finish
      await tester.pump(const Duration(milliseconds: 600));
      expect(fakeRepo.saved.length, 1);
      expect(fakeRepo.saved.first.title, 'Lunch with team');
      expect(fakeRepo.saved.first.amountMinor, 25050);
    });

    testWidgets('Displays inline error banner on failure and preserves form values', (
      WidgetTester tester,
    ) async {
      final fakeRepo = FakeExpenseRepositoryV4()..shouldFail = true;
      await tester.pumpWidget(buildTestScreen(fakeRepo: fakeRepo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter form details
      await tester.enterText(
        find.widgetWithText(TextFormField, '').first,
        '500',
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Food & Dining'));
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Weekly milk',
      );
      await tester.pump();

      // Submit
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Inline error banner appears with Retry button
      expect(find.text('Retry'), findsOneWidget);
      expect(find.textContaining('Simulated network error'), findsOneWidget);

      // Verify form values remain preserved
      expect(find.text('500'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pump();
      expect(find.text('Weekly milk'), findsOneWidget);
    });
  });
}
