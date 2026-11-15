// Google API operation implementations keep request bodies compact here.
// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/googleapis_auth.dart' as google_auth;

import '../core/utils/google_retry.dart';
import '../core/errors/app_failure.dart';
import '../models/expense_category.dart';
import '../models/expense_transaction.dart';
import '../models/transaction_model.dart' as model;
import '../models/category_model.dart';
import '../models/user_settings_model.dart';
import '../core/errors/conflict_failure.dart';

const List<String> transactionHeaders = <String>[
  'id',
  'type',
  'title',
  'amountMinor',
  'categoryId',
  'categoryName',
  'occurredAt',
  'paymentMethod',
  'notes',
  'deletedAt',
  'updatedAt',
];
const List<String> phase4TransactionHeaders = <String>[
  'id',
  'type',
  'title',
  'amountMinor',
  'categoryId',
  'categoryName',
  'occurredAt',
  'paymentMethod',
  'notes',
  'deletedAt',
  'updatedAt',
];
const List<String> categoryHeaders = <String>[
  'id',
  'name',
  'type',
  'isActive',
  'monthlyBudgetMinor',
];
const List<String> settingsHeaders = <String>['key', 'value'];
const List<String> budgetHeaders = <String>[
  'month',
  'categoryId',
  'amountMinor',
];

/// All spreadsheet reads and writes pass through this service. Each operation
/// opens an authorized client and closes it afterwards; cell values use RAW.
class GoogleSheetsService {
  const GoogleSheetsService();

  /// Creates the Phase 3 workbook structure in one Sheets batchUpdate, then
  /// writes all initial values with RAW input so no cell is interpreted as a formula.
  Future<void> initialiseWorkbook(
    String spreadsheetId, {
    required google_auth.AuthClient client,
    required String displayName,
    DateTime? now,
  }) async {
    final DateTime date = now ?? DateTime.now();
    final String month =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
    try {
      final sheets.SheetsApi api = sheets.SheetsApi(client);
      final sheets.Spreadsheet current = await api.spreadsheets
          .get(spreadsheetId, $fields: 'sheets(properties(sheetId,title))')
          .timeout(const Duration(seconds: 20));
      final sheets.Sheet? first = current.sheets?.firstOrNull;
      final int? firstId = first?.properties?.sheetId;
      if (firstId == null) {
        throw StateError('The new spreadsheet has no first worksheet.');
      }
      const int settingsId = 873421;
      const int categoriesId = 873422;
      await api.spreadsheets
          .batchUpdate(
            sheets.BatchUpdateSpreadsheetRequest(
              requests: <sheets.Request>[
                sheets.Request(
                  updateSheetProperties: sheets.UpdateSheetPropertiesRequest(
                    properties: sheets.SheetProperties(
                      sheetId: firstId,
                      title: 'Transactions',
                      gridProperties: sheets.GridProperties(frozenRowCount: 1),
                    ),
                    fields: 'title,gridProperties.frozenRowCount',
                  ),
                ),
                sheets.Request(
                  addSheet: sheets.AddSheetRequest(
                    properties: sheets.SheetProperties(
                      sheetId: settingsId,
                      title: 'Settings',
                      gridProperties: sheets.GridProperties(frozenRowCount: 1),
                    ),
                  ),
                ),
                sheets.Request(
                  addSheet: sheets.AddSheetRequest(
                    properties: sheets.SheetProperties(
                      sheetId: categoriesId,
                      title: 'Categories',
                      gridProperties: sheets.GridProperties(frozenRowCount: 1),
                    ),
                  ),
                ),
                _headerCells(firstId, transactionHeaders),
                _headerCells(settingsId, settingsHeaders),
                _headerCells(categoriesId, categoryHeaders),
                _formatColumn(firstId, 3, 'NUMBER'),
                _formatColumn(firstId, 6, 'TEXT'),
                _formatColumn(firstId, 9, 'TEXT'),
                _formatColumn(categoriesId, 4, 'NUMBER'),
              ],
            ),
            spreadsheetId,
          )
          .timeout(const Duration(seconds: 20));
      final List<List<Object?>> settings = <List<Object?>>[
        <Object?>['key', 'value'],
        <Object?>['schemaVersion', 1],
        <Object?>['setupCompleted', false],
        <Object?>['setupMonth', month],
        <Object?>['monthlySalary', 0],
        <Object?>['monthlyBudget', 0],
        <Object?>['currency', 'INR'],
        <Object?>['displayName', displayName],
        <Object?>['defaultMonth', month],
      ];
      final List<List<Object?>> categories = <List<Object?>>[
        categoryHeaders,
        for (final ExpenseCategory category in defaultExpenseCategories)
          category.toSheetRow(),
      ];
      await api.spreadsheets.values
          .batchUpdate(
            sheets.BatchUpdateValuesRequest(
              valueInputOption: 'RAW',
              data: <sheets.ValueRange>[
                sheets.ValueRange(
                  range: 'Settings!A1:B${settings.length}',
                  values: settings,
                ),
                sheets.ValueRange(
                  range: 'Categories!A1:E${categories.length}',
                  values: categories,
                ),
              ],
            ),
            spreadsheetId,
          )
          .timeout(const Duration(seconds: 20));
    } finally {
      client.close();
    }
  }

  Future<void> updateSetupSettings(
    String spreadsheetId, {
    required google_auth.AuthClient client,
    required int salaryRupees,
    required String displayName,
  }) async {
    try {
      final DateTime now = DateTime.now();
      final String month =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
      await retryGoogleRequest(
        () => sheets.SheetsApi(client).spreadsheets.values.batchUpdate(
          sheets.BatchUpdateValuesRequest(
            valueInputOption: 'RAW',
            data: <sheets.ValueRange>[
              sheets.ValueRange(
                range: 'Settings!A2:B9',
                values: <List<Object?>>[
                  <Object?>['schemaVersion', 1],
                  <Object?>['setupCompleted', true],
                  <Object?>['setupMonth', month],
                  <Object?>['monthlySalary', salaryRupees],
                  <Object?>['monthlyBudget', 0],
                  <Object?>['currency', 'INR'],
                  <Object?>['displayName', displayName],
                  <Object?>['defaultMonth', month],
                ],
              ),
            ],
          ),
          spreadsheetId,
        ),
      );
    } finally {
      client.close();
    }
  }

  Future<bool> validatePhase3Workbook(
    String spreadsheetId, {
    required google_auth.AuthClient client,
  }) async {
    final spreadsheet = await sheets.SheetsApi(client).spreadsheets
        .get(spreadsheetId, $fields: 'sheets(properties(title))')
        .timeout(const Duration(seconds: 20));
    final titles = (spreadsheet.sheets ?? <sheets.Sheet>[])
        .map((e) => e.properties?.title)
        .whereType<String>()
        .toSet();
    if (!titles.containsAll(<String>{
      'Transactions',
      'Settings',
      'Categories',
    })) {
      throw const FormatException(
        'The spreadsheet is missing one or more required worksheets.',
      );
    }
    final rows = await readRows(
      client,
      spreadsheetId,
      'Settings',
      'A:B',
    ).timeout(const Duration(seconds: 20));
    final complete =
        rows
            .skip(1)
            .where((r) => r.length > 1 && '${r[0]}' == 'setupCompleted')
            .map((r) => '${r[1]}'.toLowerCase() == 'true')
            .firstOrNull ??
        false;
    return complete;
  }

  static sheets.Request _headerCells(int sheetId, List<String> headers) =>
      sheets.Request(
        updateCells: sheets.UpdateCellsRequest(
          range: sheets.GridRange(
            sheetId: sheetId,
            startRowIndex: 0,
            endRowIndex: 1,
            startColumnIndex: 0,
            endColumnIndex: headers.length,
          ),
          rows: <sheets.RowData>[
            sheets.RowData(
              values: <sheets.CellData>[
                for (final String header in headers)
                  sheets.CellData(
                    userEnteredValue: sheets.ExtendedValue(stringValue: header),
                    userEnteredFormat: sheets.CellFormat(
                      textFormat: sheets.TextFormat(bold: true),
                    ),
                  ),
              ],
            ),
          ],
          fields: 'userEnteredValue,userEnteredFormat.textFormat.bold',
        ),
      );

  static sheets.Request _formatColumn(int sheetId, int column, String type) =>
      sheets.Request(
        repeatCell: sheets.RepeatCellRequest(
          range: sheets.GridRange(
            sheetId: sheetId,
            startRowIndex: 1,
            startColumnIndex: column,
            endColumnIndex: column + 1,
          ),
          cell: sheets.CellData(
            userEnteredFormat: sheets.CellFormat(
              numberFormat: sheets.NumberFormat(type: type),
            ),
          ),
          fields: 'userEnteredFormat.numberFormat',
        ),
      );

  Future<String> createWorkbook(
    google_auth.AuthClient client, {
    required String title,
  }) async {
    final sheets.SheetsApi sheetsApi = sheets.SheetsApi(client);
    final sheets.Spreadsheet created = await sheetsApi.spreadsheets.create(
      sheets.Spreadsheet(
        properties: sheets.SpreadsheetProperties(title: title),
        sheets: <sheets.Sheet>[
          for (final String title in <String>[
            'Transactions',
            'Categories',
            'Settings',
            'Budgets',
          ])
            sheets.Sheet(properties: sheets.SheetProperties(title: title)),
        ],
      ),
      $fields: 'spreadsheetId,spreadsheetUrl,sheets(properties(title,sheetId))',
    );
    final String? id = created.spreadsheetId;
    if (id == null || id.isEmpty) {
      throw StateError('Google Sheets created a workbook without an ID.');
    }

    final List<sheets.ValueRange> initialRanges = <sheets.ValueRange>[
      sheets.ValueRange(
        range: 'Transactions!A1:K1',
        values: <List<Object?>>[
          <Object?>[...transactionHeaders],
        ],
      ),
      sheets.ValueRange(
        range: 'Categories!A1:E1',
        values: <List<Object?>>[
          <Object?>[...categoryHeaders],
        ],
      ),
      sheets.ValueRange(
        range: 'Categories!A2:E${defaultExpenseCategories.length + 1}',
        values: <List<Object?>>[
          for (final ExpenseCategory category in defaultExpenseCategories)
            category.toSheetRow(),
        ],
      ),
      sheets.ValueRange(
        range: 'Settings!A1:B1',
        values: <List<Object?>>[
          <Object?>[...settingsHeaders],
        ],
      ),
      sheets.ValueRange(
        range: 'Settings!A2:B3',
        values: <List<Object?>>[
          <Object?>['currency', 'INR'],
          <Object?>['salaryMinor', 0],
        ],
      ),
      sheets.ValueRange(
        range: 'Budgets!A1:C1',
        values: <List<Object?>>[
          <Object?>[...budgetHeaders],
        ],
      ),
    ];
    await sheetsApi.spreadsheets.values.batchUpdate(
      sheets.BatchUpdateValuesRequest(
        valueInputOption: 'RAW',
        data: initialRanges,
      ),
      id,
    );
    await drive.DriveApi(client).files.update(
      drive.File(
        appProperties: <String, String>{
          'ejbSchema': '1',
          'ejbProduct': 'expense-journal-budget',
        },
      ),
      id,
      $fields: 'id,name,appProperties',
    );
    return id;
  }

  Future<void> validateSpreadsheet(
    google_auth.AuthClient client,
    String spreadsheetId,
  ) async {
    final sheets.SheetsApi api = sheets.SheetsApi(client);
    final sheets.Spreadsheet spreadsheet = await api.spreadsheets.get(
      spreadsheetId,
      $fields: 'spreadsheetId,sheets(properties(title))',
    );
    final Set<String> titles = (spreadsheet.sheets ?? <sheets.Sheet>[])
        .map((sheets.Sheet sheet) => sheet.properties?.title ?? '')
        .toSet();
    if (!titles.contains('Transactions')) {
      throw const FormatException(
        'This workbook has no Transactions tab. Create a new app workbook or choose a compatible sheet.',
      );
    }

    final List<List<Object?>> transactionRows = await readRows(
      client,
      spreadsheetId,
      'Transactions',
      'A:K',
    );
    if (transactionRows.isEmpty) {
      await updateRow(
        client,
        spreadsheetId,
        'Transactions!A1:K1',
        transactionHeaders,
      );
    } else {
      final List<String> header = transactionRows.first
          .map((Object? cell) => '${cell ?? ''}')
          .toList(growable: false);
      if (header.length < transactionHeaders.length ||
          !List<String>.generate(
            transactionHeaders.length,
            (int index) => header[index],
          ).asMap().entries.every(
            (MapEntry<int, String> entry) =>
                entry.value == transactionHeaders[entry.key],
          )) {
        throw const FormatException(
          'This workbook uses a different Transactions column layout. Use a workbook with the Expense Journal & Budget headers.',
        );
      }
    }

    final List<String> missingTabs = <String>[
      for (final String title in <String>['Categories', 'Settings', 'Budgets'])
        if (!titles.contains(title)) title,
    ];
    if (missingTabs.isNotEmpty) {
      await api.spreadsheets.batchUpdate(
        sheets.BatchUpdateSpreadsheetRequest(
          requests: <sheets.Request>[
            for (final String title in missingTabs)
              sheets.Request(
                addSheet: sheets.AddSheetRequest(
                  properties: sheets.SheetProperties(title: title),
                ),
              ),
          ],
        ),
        spreadsheetId,
      );
    }

    final List<sheets.ValueRange> initialRanges = <sheets.ValueRange>[];
    final List<List<Object?>> categoryRows = await readRows(
      client,
      spreadsheetId,
      'Categories',
      'A:E',
    );
    if (categoryRows.isEmpty) {
      initialRanges.addAll(<sheets.ValueRange>[
        sheets.ValueRange(
          range: 'Categories!A1:E1',
          values: <List<Object?>>[
            <Object?>[...categoryHeaders],
          ],
        ),
        sheets.ValueRange(
          range: 'Categories!A2:E${defaultExpenseCategories.length + 1}',
          values: <List<Object?>>[
            for (final ExpenseCategory category in defaultExpenseCategories)
              category.toSheetRow(),
          ],
        ),
      ]);
    }
    final List<List<Object?>> settingsRows = await readRows(
      client,
      spreadsheetId,
      'Settings',
      'A:B',
    );
    if (settingsRows.isEmpty) {
      initialRanges.addAll(<sheets.ValueRange>[
        sheets.ValueRange(
          range: 'Settings!A1:B1',
          values: <List<Object?>>[
            <Object?>[...settingsHeaders],
          ],
        ),
        sheets.ValueRange(
          range: 'Settings!A2:B3',
          values: <List<Object?>>[
            <Object?>['currency', 'INR'],
            <Object?>['salaryMinor', 0],
          ],
        ),
      ]);
    }
    final List<List<Object?>> budgetRows = await readRows(
      client,
      spreadsheetId,
      'Budgets',
      'A:C',
    );
    if (budgetRows.isEmpty) {
      initialRanges.add(
        sheets.ValueRange(
          range: 'Budgets!A1:C1',
          values: <List<Object?>>[
            <Object?>[...budgetHeaders],
          ],
        ),
      );
    }
    if (initialRanges.isNotEmpty) {
      await api.spreadsheets.values.batchUpdate(
        sheets.BatchUpdateValuesRequest(
          valueInputOption: 'RAW',
          data: initialRanges,
        ),
        spreadsheetId,
      );
    }
  }

  Future<List<drive.File>> listAccessibleWorkbooks(
    google_auth.AuthClient client,
  ) async {
    final drive.FileList result = await drive.DriveApi(client).files.list(
      q: "mimeType = 'application/vnd.google-apps.spreadsheet' and trashed = false",
      spaces: 'drive',
      pageSize: 100,
      orderBy: 'modifiedTime desc',
      $fields: 'files(id,name,mimeType,webViewLink,modifiedTime)',
    );
    return result.files ?? <drive.File>[];
  }

  Future<List<List<Object?>>> readRows(
    google_auth.AuthClient client,
    String spreadsheetId,
    String tab,
    String columns,
  ) async {
    final sheets.ValueRange result = await retryGoogleRequest(
      () => sheets.SheetsApi(client).spreadsheets.values.get(
        spreadsheetId,
        '$tab!$columns',
        valueRenderOption: 'UNFORMATTED_VALUE',
      ),
    );
    return (result.values ?? <List<Object?>>[])
        .map((List<Object?> row) => List<Object?>.of(row))
        .toList(growable: false);
  }

  Future<void> appendRow(
    google_auth.AuthClient client,
    String spreadsheetId,
    String range,
    List<Object?> row,
  ) async {
    await sheets.SheetsApi(client).spreadsheets.values
        .append(
          sheets.ValueRange(values: <List<Object?>>[row]),
          spreadsheetId,
          range,
          valueInputOption: 'RAW',
          insertDataOption: 'INSERT_ROWS',
        )
        .timeout(const Duration(seconds: 20));
  }

  Future<void> updateRow(
    google_auth.AuthClient client,
    String spreadsheetId,
    String range,
    List<Object?> row,
  ) async {
    await retryGoogleRequest(
      () => sheets.SheetsApi(client).spreadsheets.values.update(
        sheets.ValueRange(values: <List<Object?>>[row]),
        spreadsheetId,
        range,
        valueInputOption: 'RAW',
      ),
    );
  }

  Future<void> updateCell(
    google_auth.AuthClient client,
    String spreadsheetId,
    String range,
    Object value,
  ) async {
    await retryGoogleRequest(
      () => sheets.SheetsApi(client).spreadsheets.values.update(
        sheets.ValueRange(
          values: <List<Object?>>[
            <Object?>[value],
          ],
        ),
        spreadsheetId,
        range,
        valueInputOption: 'RAW',
      ),
    );
  }
}

List<ExpenseTransaction> parseTransactions(List<List<Object?>> rows) {
  if (rows.length < 2) return const <ExpenseTransaction>[];
  return rows
      .skip(1)
      .where(
        (List<Object?> row) =>
            row.isNotEmpty &&
            row[0] != null &&
            '${row[0]}' != '' &&
            (row.length < 10 || row[9] == null || '${row[9]}'.isEmpty),
      )
      .map(ExpenseTransaction.fromSheetRow)
      .toList(growable: false);
}

List<ExpenseCategory> parseCategories(List<List<Object?>> rows) {
  if (rows.length < 2) return const <ExpenseCategory>[];
  return rows
      .skip(1)
      .where((List<Object?> row) => row.isNotEmpty && row[0] != null)
      .map(ExpenseCategory.fromSheetRow)
      .toList(growable: false);
}

/// Typed Phase 4 API. The workbook is read in one batchGet to keep refreshes
/// quota friendly. Rows with malformed IDs, types, or amounts are skipped and
/// reported through [SheetReadResult.invalidRows].
class SheetReadResult {
  const SheetReadResult({
    required this.transactions,
    required this.settingsRows,
    required this.categoryRows,
    required this.invalidRows,
  });
  final List<model.TransactionModel> transactions;
  final List<List<Object?>> settingsRows, categoryRows;
  final int invalidRows;
}

class ValidationResult {
  const ValidationResult({
    required this.readable,
    required this.canEdit,
    required this.missingWorksheets,
    required this.headerMatches,
    required this.schemaVersion,
    this.headerRepairable = false,
    this.problems = const <String>[],
  });
  final bool readable, canEdit, headerMatches;
  final List<String> missingWorksheets, problems;
  final int? schemaVersion;
  final bool headerRepairable;
  bool get valid =>
      readable &&
      canEdit &&
      missingWorksheets.isEmpty &&
      headerMatches &&
      schemaVersion == 1;
  bool get canAutoRepair => missingWorksheets.isNotEmpty || headerRepairable;
}

extension Phase4GoogleSheetsService on GoogleSheetsService {
  /// Reads Transactions, Settings and Categories with a single values.batchGet.
  Future<SheetReadResult> readAll(
    String id, {
    required google_auth.AuthClient client,
  }) async {
    final result = await sheets.SheetsApi(client).spreadsheets.values
        .batchGet(
          id,
          ranges: <String>[
            'Transactions!A:K',
            'Settings!A:B',
            'Categories!A:E',
          ],
          valueRenderOption: 'UNFORMATTED_VALUE',
        )
        .timeout(const Duration(seconds: 20));
    final data = result.valueRanges ?? <sheets.ValueRange>[];
    final rows = data.isNotEmpty
        ? data[0].values ?? <List<Object?>>[]
        : <List<Object?>>[];
    final parsed = parsePhase4Transactions(rows);
    return SheetReadResult(
      transactions: parsed.transactions,
      settingsRows: data.length > 1
          ? data[1].values ?? <List<Object?>>[]
          : const <List<Object?>>[],
      categoryRows: data.length > 2
          ? data[2].values ?? <List<Object?>>[]
          : const <List<Object?>>[],
      invalidRows: parsed.invalidRows,
    );
  }

  /// Creates required tabs only when missing; existing data is never cleared.
  Future<void> createWorksheets(
    String id, {
    required google_auth.AuthClient client,
  }) async {
    final api = sheets.SheetsApi(client);
    final book = await api.spreadsheets
        .get(id, $fields: 'sheets(properties(sheetId,title))')
        .timeout(const Duration(seconds: 20));
    final titles = (book.sheets ?? <sheets.Sheet>[])
        .map((s) => s.properties?.title)
        .whereType<String>()
        .toSet();
    final missing = <String>[
      'Transactions',
      'Settings',
      'Categories',
    ].where((t) => !titles.contains(t)).toList();
    if (missing.isNotEmpty)
      await api.spreadsheets
          .batchUpdate(
            sheets.BatchUpdateSpreadsheetRequest(
              requests: [
                for (final title in missing)
                  sheets.Request(
                    addSheet: sheets.AddSheetRequest(
                      properties: sheets.SheetProperties(title: title),
                    ),
                  ),
              ],
            ),
            id,
          )
          .timeout(const Duration(seconds: 20));
  }

  Future<void> initializeHeaders(
    String id, {
    required google_auth.AuthClient client,
  }) async {
    await createWorksheets(id, client: client);
    final api = sheets.SheetsApi(client);
    final headersByTab = <String, List<String>>{
      'Transactions': phase4TransactionHeaders,
      'Settings': settingsHeaders,
      'Categories': categoryHeaders,
    };
    for (final entry in headersByTab.entries) {
      final existing = await readRows(
        client,
        id,
        entry.key,
        'A:${entry.key == 'Transactions'
            ? 'K'
            : entry.key == 'Settings'
            ? 'B'
            : 'E'}',
      );
      if (existing.isEmpty)
        await updateRow(
          client,
          id,
          '${entry.key}!A1:${entry.key == 'Transactions'
              ? 'K'
              : entry.key == 'Settings'
              ? 'B'
              : 'E'}1',
          entry.value,
        );
      else if (existing.length == 1 &&
          (existing.first.every(
                (Object? c) => c == null || '$c'.trim().isEmpty,
              ) ||
              List.generate(
                entry.value.length,
                (int i) =>
                    i >= existing.first.length ||
                    '${existing.first[i]}' != entry.value[i],
              ).any((bool mismatch) => mismatch)))
        await updateRow(
          client,
          id,
          '${entry.key}!A1:${entry.key == 'Transactions'
              ? 'K'
              : entry.key == 'Settings'
              ? 'B'
              : 'E'}1',
          entry.value,
        );
    }
    final meta = await api.spreadsheets.get(
      id,
      $fields: 'sheets(properties(sheetId,title))',
    );
    final transactionSheet = (meta.sheets ?? [])
        .where((s) => s.properties?.title == 'Transactions')
        .firstOrNull;
    if (transactionSheet?.properties?.sheetId case final int sheetId) {
      await api.spreadsheets.batchUpdate(
        sheets.BatchUpdateSpreadsheetRequest(
          requests: [
            sheets.Request(
              updateSheetProperties: sheets.UpdateSheetPropertiesRequest(
                properties: sheets.SheetProperties(
                  sheetId: sheetId,
                  gridProperties: sheets.GridProperties(frozenRowCount: 1),
                ),
                fields: 'gridProperties.frozenRowCount',
              ),
            ),
          ],
        ),
        id,
      );
    }
  }

  Future<void> appendTransaction(
    String id,
    model.TransactionModel item, {
    required google_auth.AuthClient client,
  }) async {
    final rows = await readRows(client, id, 'Transactions', 'A:K');
    if (rows
        .skip(1)
        .any((r) => r.isNotEmpty && '${r[0]}' == item.transactionId))
      throw StateError('Duplicate transaction ID.');
    await appendWithIdempotencyCheck(
      append: () =>
          appendRow(client, id, 'Transactions!A:K', item.toSheetRow()),
      alreadyExists: () async {
        final check = await readRows(client, id, 'Transactions', 'A:K');
        return check
            .skip(1)
            .any((row) => row.isNotEmpty && '${row[0]}' == item.transactionId);
      },
    );
  }

  Future<int> _transactionRow(
    String id,
    String txId,
    google_auth.AuthClient client,
  ) async {
    final rows = await readRows(client, id, 'Transactions', 'A:K');
    final found = <int>[];
    for (var i = 1; i < rows.length; i++)
      if (rows[i].isNotEmpty && '${rows[i][0]}' == txId) found.add(i);
    if (found.length > 1)
      throw StateError('Duplicate transaction ID in worksheet: $txId');
    if (found.isEmpty) throw StateError('Transaction no longer exists.');
    return found.single;
  }

  Future<void> updateTransaction(
    String id,
    model.TransactionModel item, {
    required google_auth.AuthClient client,
  }) async {
    final index = await _transactionRow(id, item.transactionId, client);
    final rows = await readRows(client, id, 'Transactions', 'A:K');
    final current = model.TransactionModel.fromSheetRow(rows[index]);
    if (current.updatedAt != item.updatedAt) throw ConflictFailure(current);
    final updated = item.copyWith(
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    await updateRow(
      client,
      id,
      'Transactions!A${index + 1}:K${index + 1}',
      updated.toSheetRow(),
    );
  }

  Future<void> deleteTransaction(
    String id,
    model.TransactionModel item, {
    required google_auth.AuthClient client,
  }) async {
    final index = await _transactionRow(id, item.transactionId, client);
    final rows = await readRows(client, id, 'Transactions', 'A:K');
    final current = model.TransactionModel.fromSheetRow(rows[index]);
    if (current.updatedAt != item.updatedAt) throw ConflictFailure(current);
    final book = await sheets.SheetsApi(client).spreadsheets
        .get(id, $fields: 'sheets(properties(sheetId,title))');
    final sheet = (book.sheets ?? [])
        .where((s) => s.properties?.title == 'Transactions')
        .firstOrNull
        ?.properties
        ?.sheetId;
    if (sheet == null) throw StateError('Transactions worksheet is missing.');
    // Sheets has no atomic compare-and-set. Another editor can change the row
    // after the version check and before this deleteDimension request.
    await sheets.SheetsApi(client).spreadsheets
        .batchUpdate(
          sheets.BatchUpdateSpreadsheetRequest(
            requests: [
              sheets.Request(
                deleteDimension: sheets.DeleteDimensionRequest(
                  range: sheets.DimensionRange(
                    sheetId: sheet,
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
  }

  Future<List<List<Object?>>> readTransactions(
    String id, {
    required google_auth.AuthClient client,
  }) => readRows(client, id, 'Transactions', 'A:K');
  Future<List<List<Object?>>> readSettings(
    String id, {
    required google_auth.AuthClient client,
  }) => readRows(client, id, 'Settings', 'A:B');
  Future<List<List<Object?>>> readCategories(
    String id, {
    required google_auth.AuthClient client,
  }) => readRows(client, id, 'Categories', 'A:E');

  Future<void> updateSettings(
    String id,
    Map<String, Object?> values, {
    required google_auth.AuthClient client,
  }) async {
    final rows = await readSettings(id, client: client);
    for (final entry in values.entries) {
      final index = rows.indexWhere(
        (r) => r.isNotEmpty && '${r[0]}' == entry.key,
      );
      if (index < 1)
        await appendRow(client, id, 'Settings!A:B', [entry.key, entry.value]);
      else
        await updateRow(client, id, 'Settings!A${index + 1}:B${index + 1}', [
          entry.key,
          entry.value,
        ]);
    }
  }

  Future<void> updateCategories(
    String id,
    List<CategoryModel> categories, {
    required google_auth.AuthClient client,
  }) async {
    final existing = await readCategories(id, client: client);
    final ids = <String>{};
    for (final category in categories) {
      if (!ids.add(category.id))
        throw StateError('Duplicate category ID: ${category.id}');
      final index = existing.indexWhere(
        (r) => r.isNotEmpty && '${r[0]}' == category.id,
      );
      if (index < 1)
        await appendRow(client, id, 'Categories!A:E', category.toSheetRow());
      else
        await updateRow(
          client,
          id,
          'Categories!A${index + 1}:E${index + 1}',
          category.toSheetRow(),
        );
    }
  }

  Future<ValidationResult> validateSpreadsheetV4(
    String id, {
    required google_auth.AuthClient client,
  }) async {
    final api = sheets.SheetsApi(client);
    final book = await api.spreadsheets
        .get(id, $fields: 'sheets(properties(title))')
        .timeout(const Duration(seconds: 20));
    final titles = (book.sheets ?? [])
        .map((s) => s.properties?.title)
        .whereType<String>()
        .toSet();
    final missing = <String>[
      'Transactions',
      'Settings',
      'Categories',
    ].where((t) => !titles.contains(t)).toList();
    final rows = titles.contains('Transactions')
        ? await readTransactions(id, client: client)
        : <List<Object?>>[];
    final headerOk =
        rows.isNotEmpty &&
        rows.first.length >= phase4TransactionHeaders.length &&
        List.generate(
          phase4TransactionHeaders.length,
          (i) => '${rows.first[i]}' == phase4TransactionHeaders[i],
        ).every((v) => v);
    final headerRepairable = rows.isEmpty || rows.length == 1;
    final settings = titles.contains('Settings')
        ? await readSettings(id, client: client)
        : <List<Object?>>[];
    final schema = UserSettingsModel.fromRows(settings).schemaVersion;
    final drive.File metadata =
        await drive.DriveApi(client).files
                .get(id, $fields: 'capabilities(canEdit)')
                .timeout(const Duration(seconds: 20))
            as drive.File;
    return ValidationResult(
      readable: true,
      canEdit: metadata.capabilities?.canEdit ?? false,
      missingWorksheets: missing,
      headerMatches: headerOk,
      schemaVersion: schema,
      headerRepairable: headerRepairable,
      problems: [
        if (missing.isNotEmpty) 'Missing worksheets: ${missing.join(', ')}',
        if (!headerOk) 'Transactions header does not match supported schema',
        if (schema != 1) 'Unsupported schema version: $schema',
      ],
    );
  }

  /// Revalidates access with the fresh authorized client supplied by the
  /// repository, then confirms the workbook remains readable and editable.
  Future<ValidationResult> reconnect(
    String spreadsheetId, {
    required google_auth.AuthClient client,
  }) => validateSpreadsheetV4(spreadsheetId, client: client);
}

class ParsedTransactions {
  const ParsedTransactions(this.transactions, this.invalidRows);
  final List<model.TransactionModel> transactions;
  final int invalidRows;
}

ParsedTransactions parsePhase4Transactions(List<List<Object?>> rows) {
  final valid = <model.TransactionModel>[];
  final ids = <String>{};
  var invalid = 0;
  for (final row in rows.skip(1)) {
    if (row.every((Object? cell) => cell == null || '$cell'.trim().isEmpty))
      continue;
    try {
      final item = model.TransactionModel.fromSheetRow(row);
      if (!ids.add(item.transactionId)) {
        invalid++;
        continue;
      }
      valid.add(item);
    } on FormatException {
      invalid++;
    }
  }
  return ParsedTransactions(List.unmodifiable(valid), invalid);
}

/// Checks for a committed row before retrying an append with an unknown result.
/// The callbacks make this safe to exercise with a fake store in unit tests.
Future<void> appendWithIdempotencyCheck({
  required Future<void> Function() append,
  required Future<bool> Function() alreadyExists,
  int maxAttempts = 2,
  Future<void> Function(Duration)? wait,
}) async {
  for (var attempt = 0; ; attempt++) {
    try {
      await append();
      return;
    } catch (error) {
      if (!mapGoogleFailure(error).retryable || attempt + 1 >= maxAttempts) {
        rethrow;
      }
      if (await alreadyExists()) return;
      await (wait ?? Future<void>.delayed)(
        Duration(milliseconds: 250 * (1 << attempt)),
      );
    }
  }
}
