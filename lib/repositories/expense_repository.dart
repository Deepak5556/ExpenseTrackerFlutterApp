import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as google_sheets;
import 'package:googleapis_auth/googleapis_auth.dart' as google_auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/expense_category.dart';
import '../models/expense_transaction.dart';
import '../services/google_auth_service.dart';
import '../services/google_drive_service.dart';
import '../services/google_sheets_service.dart';
import '../core/errors/conflict_failure.dart';
import '../models/transaction_model.dart' as phase4;

const String _spreadsheetPreferenceKey = 'connected_spreadsheet_id';

class ExpenseSnapshot {
  const ExpenseSnapshot({
    required this.transactions,
    required this.categories,
    required this.settings,
    required this.budgets,
  });

  final List<ExpenseTransaction> transactions;
  final List<ExpenseCategory> categories;
  final Map<String, String> settings;
  final Map<String, int> budgets;
}

/// Google Sheets is the system of record. SharedPreferences holds only the
/// connected workbook ID; transaction values are never cached on-device.
class ExpenseRepository {
  ExpenseRepository({
    required this._auth,
    this._sheets = const GoogleSheetsService(),
    this._drive = const GoogleDriveService(),
  });

  final GoogleAuthService _auth;
  final GoogleSheetsService _sheets;
  final GoogleDriveService _drive;
  final Uuid _uuid = const Uuid();
  String? _spreadsheetId;

  String? get spreadsheetId => _spreadsheetId;
  GoogleSignInAccount? get account => _auth.account;

  Future<String?> loadConnectionId() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    _spreadsheetId = preferences.getString(_spreadsheetPreferenceKey);
    return _spreadsheetId;
  }

  Future<String> createWorkbook() async {
    await _auth.signIn();
    final google_auth.AuthClient client = await _auth.authorizedClient();
    try {
      final drive.File file = await _drive.createSpreadsheet(client);
      final String id = file.id!;
      await _sheets.initialiseWorkbook(
        id,
        client: client,
        displayName: _auth.account?.displayName ?? '',
      );
      await _saveId(id);
      return id;
    } finally {
      client.close();
    }
  }

  Future<List<drive.File>> listAccessibleWorkbooks() async {
    await _auth.signIn();
    final google_auth.AuthClient client = await _auth.authorizedClient();
    try {
      return await _sheets.listAccessibleWorkbooks(client);
    } finally {
      client.close();
    }
  }

  Future<void> connectExisting(String spreadsheetId) async {
    final String id = _extractSpreadsheetId(spreadsheetId.trim());
    if (id.isEmpty) {
      throw const FormatException('Enter a Google Sheets URL or ID.');
    }
    await _auth.signIn();
    final google_auth.AuthClient client = await _auth.authorizedClient();
    try {
      await _sheets.validateSpreadsheet(client, id);
      await _saveId(id);
    } finally {
      client.close();
    }
  }

  Future<ExpenseSnapshot> loadSnapshot() async {
    final String id = _requireSpreadsheet();
    final google_auth.AuthClient client = await _auth.authorizedClient();
    try {
      final List<List<Object?>> transactionRows = await _sheets.readRows(
        client,
        id,
        'Transactions',
        'A:K',
      );
      final List<List<Object?>> categoryRows = await _sheets.readRows(
        client,
        id,
        'Categories',
        'A:E',
      );
      final List<List<Object?>> settingRows = await _sheets.readRows(
        client,
        id,
        'Settings',
        'A:B',
      );
      final List<List<Object?>> budgetRows = await _sheets.readRows(
        client,
        id,
        'Budgets',
        'A:C',
      );
      final Map<String, String> settings = <String, String>{};
      for (final List<Object?> row in settingRows.skip(1)) {
        if (row.length >= 2 && row[0] != null) {
          settings['${row[0]}'] = '${row[1] ?? ''}';
        }
      }
      final Map<String, int> budgets = <String, int>{};
      for (final List<Object?> row in budgetRows.skip(1)) {
        if (row.length >= 3) {
          budgets['${row[0]}|${row[1]}'] = int.tryParse('${row[2]}') ?? 0;
        }
      }
      return ExpenseSnapshot(
        transactions: parseTransactions(transactionRows),
        categories: parseCategories(categoryRows),
        settings: settings,
        budgets: budgets,
      );
    } finally {
      client.close();
    }
  }

  Future<ExpenseTransaction> addTransaction({
    required TransactionType type,
    required String title,
    required int amountMinor,
    required ExpenseCategory category,
    required DateTime occurredAt,
    String paymentMethod = '',
    String notes = '',
  }) async {
    final String id = _requireSpreadsheet();
    final ExpenseTransaction item = ExpenseTransaction(
      id: _uuid.v4(),
      type: type,
      title: title.trim(),
      amountMinor: amountMinor,
      categoryId: category.id,
      categoryName: category.name,
      occurredAt: occurredAt,
      paymentMethod: paymentMethod.trim(),
      notes: notes.trim(),
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    final google_auth.AuthClient client = await _auth.authorizedClient();
    try {
      await _sheets.appendRow(client, id, 'Transactions!A:K', <Object?>[
        ...item.toSheetRow(),
        '',
        item.updatedAt,
      ]);
      return ExpenseTransaction.fromSheetRow(<Object?>[
        ...item.toSheetRow(),
        '',
        item.updatedAt,
      ]);
    } finally {
      client.close();
    }
  }

  Future<ExpenseTransaction> updateTransaction(ExpenseTransaction item) async {
    final String id = _requireSpreadsheet();
    final google_auth.AuthClient client = await _auth.authorizedClient();
    try {
      final List<List<Object?>> rows = await _sheets.readRows(
        client,
        id,
        'Transactions',
        'A:K',
      );
      final int index = rows.indexWhere(
        (List<Object?> row) => row.isNotEmpty && '${row[0]}' == item.id,
      );
      if (index < 1) {
        throw StateError(
          'This transaction no longer exists in the connected sheet.',
        );
      }
      final List<Object?> oldRow = rows[index];
      final String actualVersion = sheetRowVersion(oldRow);
      if (actualVersion != item.updatedAt) {
        throw ConflictFailure(
          _toPhase4(ExpenseTransaction.fromSheetRow(oldRow)),
        );
      }
      final String deletedAt = oldRow.length > 9 ? '${oldRow[9] ?? ''}' : '';
      final String updatedAt = DateTime.now().toUtc().toIso8601String();
      await _sheets.updateRow(
        client,
        id,
        'Transactions!A${index + 1}:K${index + 1}',
        <Object?>[...item.toSheetRow(), deletedAt, updatedAt],
      );
      return ExpenseTransaction.fromSheetRow(<Object?>[
        ...item.toSheetRow(),
        deletedAt,
        updatedAt,
      ]);
    } finally {
      client.close();
    }
  }

  Future<void> deleteTransaction(
    String transactionId, {
    String? expectedUpdatedAt,
  }) async {
    final String id = _requireSpreadsheet();
    final google_auth.AuthClient client = await _auth.authorizedClient();
    try {
      final List<List<Object?>> rows = await _sheets.readRows(
        client,
        id,
        'Transactions',
        'A:K',
      );
      final int index = rows.indexWhere(
        (List<Object?> row) => row.isNotEmpty && '${row[0]}' == transactionId,
      );
      if (index < 1) {
        throw StateError(
          'This transaction no longer exists in the connected sheet.',
        );
      }
      final List<Object?> row = rows[index];
      final String actualVersion = sheetRowVersion(row);
      if (expectedUpdatedAt != null && actualVersion != expectedUpdatedAt) {
        throw ConflictFailure(_toPhase4(ExpenseTransaction.fromSheetRow(row)));
      }
      final book = await google_sheets.SheetsApi(client).spreadsheets
          .get(id, $fields: 'sheets(properties(sheetId,title))');
      final int? sheetId = (book.sheets ?? <google_sheets.Sheet>[])
          .where((s) => s.properties?.title == 'Transactions')
          .firstOrNull
          ?.properties
          ?.sheetId;
      if (sheetId == null) {
        throw StateError('Transactions worksheet is missing.');
      }
      // Sheets lacks atomic compare-and-set; another editor can modify a row
      // between reading this version and issuing the row deletion.
      await google_sheets.SheetsApi(client).spreadsheets
          .batchUpdate(
            google_sheets.BatchUpdateSpreadsheetRequest(
              requests: <google_sheets.Request>[
                google_sheets.Request(
                  deleteDimension: google_sheets.DeleteDimensionRequest(
                    range: google_sheets.DimensionRange(
                      sheetId: sheetId,
                      dimension: 'ROWS',
                      startIndex: index,
                      endIndex: index + 1,
                    ),
                  ),
                ),
              ],
            ),
            id,
          )
          .timeout(const Duration(seconds: 20));
    } finally {
      client.close();
    }
  }

  Future<void> addCategory(ExpenseCategory category) async {
    final google_auth.AuthClient client = await _auth.authorizedClient();
    try {
      await _sheets.appendRow(
        client,
        _requireSpreadsheet(),
        'Categories!A:E',
        category.toSheetRow(),
      );
    } finally {
      client.close();
    }
  }

  Future<void> updateCategory(ExpenseCategory category) async {
    final String id = _requireSpreadsheet();
    final google_auth.AuthClient client = await _auth.authorizedClient();
    try {
      final List<List<Object?>> rows = await _sheets.readRows(
        client,
        id,
        'Categories',
        'A:E',
      );
      final int index = rows.indexWhere(
        (List<Object?> row) => row.isNotEmpty && '${row[0]}' == category.id,
      );
      if (index < 1) {
        throw StateError(
          'This category no longer exists in the connected sheet.',
        );
      }
      await _sheets.updateRow(
        client,
        id,
        'Categories!A${index + 1}:E${index + 1}',
        category.toSheetRow(),
      );
    } finally {
      client.close();
    }
  }

  Future<void> setSalary(int amountMinor) =>
      _setSetting('salaryMinor', amountMinor);

  Future<void> setCurrency(String currency) =>
      _setSetting('currency', currency);

  Future<void> setBudget(
    String month,
    String categoryId,
    int amountMinor,
  ) async {
    final String id = _requireSpreadsheet();
    final google_auth.AuthClient client = await _auth.authorizedClient();
    try {
      final List<List<Object?>> rows = await _sheets.readRows(
        client,
        id,
        'Budgets',
        'A:C',
      );
      final int index = rows.indexWhere(
        (List<Object?> row) =>
            row.length >= 2 &&
            '${row[0]}' == month &&
            '${row[1]}' == categoryId,
      );
      final List<Object?> updated = <Object?>[month, categoryId, amountMinor];
      if (index < 1) {
        await _sheets.appendRow(client, id, 'Budgets!A:C', updated);
      } else {
        await _sheets.updateRow(
          client,
          id,
          'Budgets!A${index + 1}:C${index + 1}',
          updated,
        );
      }
    } finally {
      client.close();
    }
  }

  Future<void> disconnect() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_spreadsheetPreferenceKey);
    _spreadsheetId = null;
  }

  Future<void> _setSetting(String key, Object value) async {
    final String id = _requireSpreadsheet();
    final google_auth.AuthClient client = await _auth.authorizedClient();
    try {
      final List<List<Object?>> rows = await _sheets.readRows(
        client,
        id,
        'Settings',
        'A:B',
      );
      final int index = rows.indexWhere(
        (List<Object?> row) => row.isNotEmpty && '${row[0]}' == key,
      );
      if (index < 1) {
        await _sheets.appendRow(client, id, 'Settings!A:B', <Object?>[
          key,
          value,
        ]);
      } else {
        await _sheets.updateCell(client, id, 'Settings!B${index + 1}', value);
      }
    } finally {
      client.close();
    }
  }

  Future<void> _saveId(String id) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_spreadsheetPreferenceKey, id);
    _spreadsheetId = id;
  }

  String _requireSpreadsheet() {
    final String? id = _spreadsheetId;
    if (id == null || id.isEmpty) {
      throw StateError('Connect a Google Sheet first.');
    }
    return id;
  }

  String _extractSpreadsheetId(String value) {
    final RegExpMatch? match =
        RegExp(r'/spreadsheets/d/([^/?#]+)').firstMatch(value) ??
        RegExp(r'^([A-Za-z0-9_-]{20,})$').firstMatch(value);
    return match?.group(1) ?? '';
  }
}

phase4.TransactionModel _toPhase4(ExpenseTransaction transaction) {
  final value = transaction.occurredAt;
  return phase4.TransactionModel(
    transactionId: transaction.id,
    type: transaction.type == TransactionType.income
        ? phase4.TransactionType.income
        : phase4.TransactionType.expense,
    title: transaction.title,
    amountMinor: transaction.amountMinor,
    categoryId: transaction.categoryId,
    categoryName: transaction.categoryName,
    date:
        '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
    time:
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
    paymentMethod: transaction.paymentMethod,
    notes: transaction.notes,
    updatedAt: transaction.updatedAt,
  );
}
