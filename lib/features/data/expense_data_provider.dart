import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/expense_category.dart';
import '../../models/expense_transaction.dart';
import '../../repositories/expense_repository.dart';
import '../../services/google_auth_service.dart';
import '../../repositories/sheets_repositories.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/expense_repository_v4.dart';
import '../../services/google_sheets_service.dart';

final Provider<GoogleAuthService> googleAuthServiceProvider =
    Provider<GoogleAuthService>((Ref ref) => GoogleAuthService());

final Provider<ExpenseRepository> expenseRepositoryProvider =
    Provider<ExpenseRepository>(
      (Ref ref) =>
          ExpenseRepository(auth: ref.watch(googleAuthServiceProvider)),
    );

final Provider<ExpenseRepositoryV4> sheetsExpenseRepositoryProvider =
    Provider<ExpenseRepositoryV4>(
      (Ref ref) => SheetsExpenseRepository(
        ref.watch(googleAuthServiceProvider),
        const GoogleSheetsService(),
        () =>
            ref.read(expenseRepositoryProvider).spreadsheetId ??
            (throw StateError('Connect a Google Sheet first.')),
      ),
    );
final Provider<CategoryRepository> categoryRepositoryProvider =
    Provider<CategoryRepository>(
      (Ref ref) => SheetsCategoryRepository(
        ref.watch(googleAuthServiceProvider),
        const GoogleSheetsService(),
        () =>
            ref.read(expenseRepositoryProvider).spreadsheetId ??
            (throw StateError('Connect a Google Sheet first.')),
      ),
    );
final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>(
      (Ref ref) => SheetsSettingsRepository(
        ref.watch(googleAuthServiceProvider),
        const GoogleSheetsService(),
        () =>
            ref.read(expenseRepositoryProvider).spreadsheetId ??
            (throw StateError('Connect a Google Sheet first.')),
      ),
    );

final NotifierProvider<ExpenseDataController, ExpenseDataState>
expenseDataProvider = NotifierProvider<ExpenseDataController, ExpenseDataState>(
  ExpenseDataController.new,
);

class ExpenseDataState {
  const ExpenseDataState({
    this.initialized = false,
    this.loading = false,
    this.saving = false,
    this.spreadsheetId,
    this.accountName,
    this.accountEmail,
    this.transactions = const <ExpenseTransaction>[],
    this.categories = const <ExpenseCategory>[],
    this.settings = const <String, String>{},
    this.budgets = const <String, int>{},
    this.error,
  });

  final bool initialized;
  final bool loading;
  final bool saving;
  final String? spreadsheetId;
  final String? accountName;
  final String? accountEmail;
  final List<ExpenseTransaction> transactions;
  final List<ExpenseCategory> categories;
  final Map<String, String> settings;
  final Map<String, int> budgets;
  final String? error;

  bool get isConnected => spreadsheetId != null;
  int get salaryMinor => int.tryParse(settings['salaryMinor'] ?? '') ?? 0;
  String get currency => settings['currency'] ?? 'INR';

  ExpenseDataState copyWith({
    bool? initialized,
    bool? loading,
    bool? saving,
    String? spreadsheetId,
    bool clearSpreadsheetId = false,
    String? accountName,
    String? accountEmail,
    List<ExpenseTransaction>? transactions,
    List<ExpenseCategory>? categories,
    Map<String, String>? settings,
    Map<String, int>? budgets,
    String? error,
    bool clearError = false,
    bool clearAccount = false,
  }) => ExpenseDataState(
    initialized: initialized ?? this.initialized,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    spreadsheetId: clearSpreadsheetId
        ? null
        : spreadsheetId ?? this.spreadsheetId,
    accountName: clearAccount ? null : accountName ?? this.accountName,
    accountEmail: clearAccount ? null : accountEmail ?? this.accountEmail,
    transactions: transactions ?? this.transactions,
    categories: categories ?? this.categories,
    settings: settings ?? this.settings,
    budgets: budgets ?? this.budgets,
    error: clearError ? null : error ?? this.error,
  );
}

class ExpenseDataController extends Notifier<ExpenseDataState> {
  late final ExpenseRepository _repository;
  bool _initializationStarted = false;

  @override
  ExpenseDataState build() {
    _repository = ref.watch(expenseRepositoryProvider);
    return const ExpenseDataState();
  }

  Future<void> initialize() async {
    if (_initializationStarted) return;
    _initializationStarted = true;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final String? id = await _repository.loadConnectionId();
      state = state.copyWith(spreadsheetId: id, initialized: true);
      if (id != null) await _repositoryAuthRefresh();
    } catch (error) {
      state = state.copyWith(initialized: true, error: _message(error));
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> _repositoryAuthRefresh() async {
    try {
      await ref.read(googleAuthServiceProvider).initialize();
      final account = _repository.account;
      if (account != null) {
        state = state.copyWith(
          accountName: account.displayName,
          accountEmail: account.email,
        );
        await refresh();
      }
    } catch (_) {
      // Google identity plug-in initialization can be unavailable in widget
      // tests or before OAuth is configured. The saved workbook ID is retained.
    }
  }

  Future<void> connectNewWorkbook() async {
    await _runSaving(() async {
      final String id = await _repository.createWorkbook();
      final account = _repository.account;
      state = state.copyWith(
        spreadsheetId: id,
        accountName: account?.displayName,
        accountEmail: account?.email,
        clearError: true,
      );
      await refresh();
    });
  }

  Future<void> connectExistingWorkbook(String value) async {
    await _runSaving(() async {
      await _repository.connectExisting(value);
      final account = _repository.account;
      state = state.copyWith(
        spreadsheetId: _repository.spreadsheetId,
        accountName: account?.displayName,
        accountEmail: account?.email,
        clearError: true,
      );
      await refresh();
    });
  }

  Future<void> refresh() async {
    if (_repository.spreadsheetId == null && state.spreadsheetId != null) {
      await _repository.loadConnectionId();
    }
    if (_repository.spreadsheetId == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final ExpenseSnapshot snapshot = await _repository.loadSnapshot();
      state = state.copyWith(
        transactions: snapshot.transactions,
        categories: snapshot.categories,
        settings: snapshot.settings,
        budgets: snapshot.budgets,
        loading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(loading: false, error: _message(error));
      rethrow;
    }
  }

  Future<void> addTransaction({
    required TransactionType type,
    required String title,
    required int amountMinor,
    required ExpenseCategory category,
    required DateTime occurredAt,
    String paymentMethod = '',
    String notes = '',
  }) async {
    await _runSaving(() async {
      final item = await _repository.addTransaction(
        type: type,
        title: title,
        amountMinor: amountMinor,
        category: category,
        occurredAt: occurredAt,
        paymentMethod: paymentMethod,
        notes: notes,
      );
      state = state.copyWith(
        transactions: <ExpenseTransaction>[item, ...state.transactions],
      );
    });
  }

  Future<void> updateTransaction(ExpenseTransaction item) async {
    await _runSaving(() async {
      final updated = await _repository.updateTransaction(item);
      state = state.copyWith(
        transactions: <ExpenseTransaction>[
          for (final current in state.transactions)
            current.id == updated.id ? updated : current,
        ],
      );
    });
  }

  Future<void> deleteTransaction(String id) async {
    final item = state.transactions
        .where((transaction) => transaction.id == id)
        .firstOrNull;
    if (item == null) {
      throw StateError('Transaction is not loaded. Refresh and try again.');
    }
    await _runSaving(() async {
      await _repository.deleteTransaction(
        id,
        expectedUpdatedAt: item.updatedAt,
      );
      state = state.copyWith(
        transactions: state.transactions
            .where((transaction) => transaction.id != id)
            .toList(growable: false),
      );
    });
  }

  Future<void> addCategory(ExpenseCategory category) async {
    await _runSaving(() async {
      await _repository.addCategory(category);
      state = state.copyWith(
        categories: <ExpenseCategory>[...state.categories, category],
      );
    });
  }

  Future<void> updateCategory(ExpenseCategory category) async {
    await _runSaving(() async {
      await _repository.updateCategory(category);
      state = state.copyWith(
        categories: <ExpenseCategory>[
          for (final current in state.categories)
            current.id == category.id ? category : current,
        ],
      );
    });
  }

  Future<void> setSalary(int amountMinor) async {
    await _runSaving(() async {
      await _repository.setSalary(amountMinor);
      state = state.copyWith(
        settings: <String, String>{
          ...state.settings,
          'salaryMinor': '$amountMinor',
        },
      );
    });
  }

  Future<void> setBudget(
    String month,
    String categoryId,
    int amountMinor,
  ) async {
    await _runSaving(() async {
      await _repository.setBudget(month, categoryId, amountMinor);
      state = state.copyWith(
        budgets: <String, int>{
          ...state.budgets,
          '$month|$categoryId': amountMinor,
        },
      );
    });
  }

  Future<void> disconnect() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _repository.disconnect();
      await ref.read(googleAuthServiceProvider).signOut();
      state = const ExpenseDataState(initialized: true);
    } catch (error) {
      state = state.copyWith(loading: false, error: _message(error));
      rethrow;
    }
  }

  Future<void> _runSaving(Future<void> Function() action) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await action();
      state = state.copyWith(saving: false, clearError: true);
    } catch (error) {
      state = state.copyWith(saving: false, error: _message(error));
      rethrow;
    }
  }

  String _message(Object error) {
    final String value = error.toString();
    if (value.contains('GOOGLE_SERVER_CLIENT_ID')) {
      return 'Google sign-in is not configured. Add your OAuth web client ID and Android signing SHA-1, then try again.';
    }
    if (value.contains('PlatformException') ||
        value.contains('MissingPluginException')) {
      return 'Google sign-in is unavailable. Check the Android OAuth setup and retry.';
    }
    return value
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '');
  }
}
