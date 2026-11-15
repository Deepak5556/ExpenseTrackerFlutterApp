import 'package:googleapis_auth/googleapis_auth.dart' as auth;

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/user_settings_model.dart';
import '../services/google_auth_service.dart';
import '../services/google_sheets_service.dart';
import 'category_repository.dart';
import 'expense_repository_v4.dart';
import 'settings_repository.dart';

/// Shared implementation obtains a fresh short-lived client per operation.
abstract class _SheetsRepositoryBase {
  _SheetsRepositoryBase(this.authService, this.sheets, this.spreadsheetId);
  final GoogleAuthService authService;
  final GoogleSheetsService sheets;
  final String Function() spreadsheetId;
  Future<T> withClient<T>(
    Future<T> Function(auth.AuthClient client, String id) action,
  ) async {
    final client = await authService.authorizedClient();
    try {
      return await action(client, spreadsheetId());
    } finally {
      client.close();
    }
  }
}

class SheetsExpenseRepository extends _SheetsRepositoryBase
    implements ExpenseRepositoryV4 {
  SheetsExpenseRepository(super.authService, super.sheets, super.spreadsheetId);
  @override
  Future<SheetReadResult> readAll() =>
      withClient((c, id) => sheets.readAll(id, client: c));
  @override
  Future<void> append(TransactionModel item) =>
      withClient((c, id) => sheets.appendTransaction(id, item, client: c));
  @override
  Future<void> update(TransactionModel item) =>
      withClient((c, id) => sheets.updateTransaction(id, item, client: c));
  @override
  Future<void> delete(TransactionModel item) =>
      withClient((c, id) => sheets.deleteTransaction(id, item, client: c));
}

class SheetsCategoryRepository extends _SheetsRepositoryBase
    implements CategoryRepository {
  SheetsCategoryRepository(
    super.authService,
    super.sheets,
    super.spreadsheetId,
  );
  @override
  Future<List<CategoryModel>> readCategories() => withClient((c, id) async {
    final rows = await sheets.readCategories(id, client: c);
    return [
      for (final r in rows.skip(1))
        if (r.length >= 3 && '${r[0]}'.trim().isNotEmpty)
          CategoryModel.fromSheetRow(r),
    ];
  });
  @override
  Future<void> saveCategories(List<CategoryModel> categories) =>
      withClient((c, id) => sheets.updateCategories(id, categories, client: c));
}

class SheetsSettingsRepository extends _SheetsRepositoryBase
    implements SettingsRepository {
  SheetsSettingsRepository(
    super.authService,
    super.sheets,
    super.spreadsheetId,
  );
  @override
  Future<UserSettingsModel> readSettings() => withClient(
    (c, id) async =>
        UserSettingsModel.fromRows(await sheets.readSettings(id, client: c)),
  );
  @override
  Future<void> saveSettings(UserSettingsModel settings) => withClient(
    (c, id) => sheets.updateSettings(id, settings.toSheetRows(), client: c),
  );
}
