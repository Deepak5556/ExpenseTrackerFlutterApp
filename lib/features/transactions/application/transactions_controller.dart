import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/conflict_failure.dart';
import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import '../../../models/user_settings_model.dart';
import '../../../repositories/category_repository.dart';
import '../../../repositories/expense_repository_v4.dart';
import '../../../repositories/settings_repository.dart';
import '../../data/expense_data_provider.dart';

sealed class TransactionMutationResult {
  const TransactionMutationResult();
}

final class MutationSuccess extends TransactionMutationResult {
  const MutationSuccess(this.item);
  final TransactionModel item;
}

final class MutationConflict extends TransactionMutationResult {
  const MutationConflict({
    required this.attempted,
    required this.current,
  });
  final TransactionModel attempted;
  final TransactionModel current;
}

final class MutationFailure extends TransactionMutationResult {
  const MutationFailure(this.error, {this.message});
  final Object error;
  final String? message;
}

final Provider<ExpenseRepositoryV4> v4ExpenseRepositoryProvider =
    sheetsExpenseRepositoryProvider;

final AsyncNotifierProvider<TransactionsController, List<TransactionModel>>
transactionsControllerProvider =
    AsyncNotifierProvider<TransactionsController, List<TransactionModel>>(
  TransactionsController.new,
);

class TransactionsController extends AsyncNotifier<List<TransactionModel>> {
  late ExpenseRepositoryV4 _repository;

  @override
  Future<List<TransactionModel>> build() async {
    _repository = ref.watch(sheetsExpenseRepositoryProvider);
    try {
      final sheetResult = await _repository.readAll();
      return sheetResult.transactions;
    } catch (_) {
      // In preview or disconnected states, provide empty transaction list
      return const <TransactionModel>[];
    }
  }

  Future<TransactionMutationResult> add(TransactionModel item) async {
    try {
      await _repository.append(item);
      final List<TransactionModel> currentList =
          state.value ?? const <TransactionModel>[];
      state = AsyncData<List<TransactionModel>>(<TransactionModel>[
        item,
        ...currentList,
      ]);
      return MutationSuccess(item);
    } catch (error) {
      return MutationFailure(error, message: error.toString());
    }
  }

  Future<TransactionMutationResult> edit(
    TransactionModel item, {
    bool force = false,
  }) async {
    try {
      TransactionModel toUpdate = item;
      if (force) {
        toUpdate = item.copyWith(
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );
      }
      await _repository.update(toUpdate);
      final List<TransactionModel> currentList =
          state.value ?? const <TransactionModel>[];
      final List<TransactionModel> updatedList = currentList.map((
        TransactionModel tx,
      ) {
        return tx.transactionId == toUpdate.transactionId ? toUpdate : tx;
      }).toList();
      state = AsyncData<List<TransactionModel>>(updatedList);
      return MutationSuccess(toUpdate);
    } on ConflictFailure catch (conflict) {
      return MutationConflict(
        attempted: item,
        current: conflict.current,
      );
    } catch (error) {
      return MutationFailure(error, message: error.toString());
    }
  }

  Future<TransactionMutationResult> delete(TransactionModel item) async {
    try {
      await _repository.delete(item);
      final List<TransactionModel> currentList =
          state.value ?? const <TransactionModel>[];
      final List<TransactionModel> updatedList = currentList
          .where((TransactionModel tx) => tx.transactionId != item.transactionId)
          .toList();
      state = AsyncData<List<TransactionModel>>(updatedList);
      return MutationSuccess(item);
    } on ConflictFailure catch (conflict) {
      return MutationConflict(
        attempted: item,
        current: conflict.current,
      );
    } catch (error) {
      return MutationFailure(error, message: error.toString());
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<TransactionModel>>();
    state = await AsyncValue.guard(() async {
      final sheetResult = await _repository.readAll();
      return sheetResult.transactions;
    });
  }
}

final FutureProvider<UserSettingsModel> userSettingsProvider =
    FutureProvider<UserSettingsModel>((Ref ref) async {
  final SettingsRepository repo = ref.watch(settingsRepositoryProvider);
  try {
    return await repo.readSettings();
  } catch (_) {
    return const UserSettingsModel();
  }
});

final NotifierProvider<SelectedMonthNotifier, String> selectedMonthProvider =
    NotifierProvider<SelectedMonthNotifier, String>(SelectedMonthNotifier.new);

class SelectedMonthNotifier extends Notifier<String> {
  @override
  String build() {
    final UserSettingsModel? settings =
        ref.watch(userSettingsProvider).value;
    if (settings != null && settings.defaultMonth.trim().isNotEmpty) {
      return settings.defaultMonth.trim();
    }
    final DateTime now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  void setMonth(String month) => state = month;
}

final AsyncNotifierProvider<CategoriesController, List<CategoryModel>>
categoriesListProvider =
    AsyncNotifierProvider<CategoriesController, List<CategoryModel>>(
  CategoriesController.new,
);

class CategoriesController extends AsyncNotifier<List<CategoryModel>> {
  late CategoryRepository _repo;

  @override
  Future<List<CategoryModel>> build() async {
    try {
      _repo = ref.watch(categoryRepositoryProvider);
      final List<CategoryModel> list = await _repo.readCategories();
      if (list.isNotEmpty) {
        return list;
      }
    } catch (_) {}
    return defaultCategories;
  }

  Future<void> addCategory(CategoryModel category) async {
    final List<CategoryModel> current =
        state.value ?? defaultCategories;
    final List<CategoryModel> updated = <CategoryModel>[...current, category];
    try {
      await _repo.saveCategories(updated);
    } catch (_) {}
    state = AsyncData<List<CategoryModel>>(updated);
  }

  static const List<CategoryModel> defaultCategories = <CategoryModel>[
    CategoryModel(id: 'cat-food', name: 'Food & Dining', type: 'expense'),
    CategoryModel(id: 'cat-groceries', name: 'Groceries', type: 'expense'),
    CategoryModel(id: 'cat-transport', name: 'Transport', type: 'expense'),
    CategoryModel(id: 'cat-shopping', name: 'Shopping', type: 'expense'),
    CategoryModel(id: 'cat-bills', name: 'Bills & Utilities', type: 'expense'),
    CategoryModel(
      id: 'cat-entertainment',
      name: 'Entertainment',
      type: 'expense',
    ),
    CategoryModel(id: 'cat-health', name: 'Health & Medical', type: 'expense'),
    CategoryModel(id: 'cat-salary', name: 'Salary', type: 'income'),
    CategoryModel(id: 'cat-freelance', name: 'Freelance', type: 'income'),
    CategoryModel(id: 'cat-investments', name: 'Investments', type: 'income'),
    CategoryModel(id: 'cat-other', name: 'Other', type: 'expense'),
  ];
}
