import 'package:intl/intl.dart';

enum TransactionType { expense, income }

class ExpenseTransaction {
  const ExpenseTransaction({
    required this.id,
    required this.type,
    required this.title,
    required this.amountMinor,
    required this.categoryId,
    required this.categoryName,
    required this.occurredAt,
    this.paymentMethod = '',
    this.notes = '',
    this.updatedAt = '',
  });

  final String id;
  final TransactionType type;
  final String title;
  final int amountMinor;
  final String categoryId;
  final String categoryName;
  final DateTime occurredAt;
  final String paymentMethod;
  final String notes;
  final String updatedAt;

  List<Object?> toSheetRow() => <Object?>[
    id,
    type.name,
    sanitizeSheetText(title),
    amountMinor,
    sanitizeSheetText(categoryId),
    sanitizeSheetText(categoryName),
    occurredAt.toIso8601String(),
    sanitizeSheetText(paymentMethod),
    sanitizeSheetText(notes),
  ];

  factory ExpenseTransaction.fromSheetRow(List<Object?> row) {
    String text(int index) => index < row.length ? '${row[index] ?? ''}' : '';
    return ExpenseTransaction(
      id: text(0),
      type: text(1) == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      title: restoreSheetText(text(2)),
      amountMinor: int.tryParse(text(3)) ?? 0,
      categoryId: restoreSheetText(text(4)),
      categoryName: restoreSheetText(text(5)),
      occurredAt:
          DateTime.tryParse(text(6)) ?? DateTime.fromMillisecondsSinceEpoch(0),
      paymentMethod: restoreSheetText(text(7)),
      notes: restoreSheetText(text(8)),
      updatedAt: sheetRowVersion(row),
    );
  }

  ExpenseTransaction copyWith({
    TransactionType? type,
    String? title,
    int? amountMinor,
    String? categoryId,
    String? categoryName,
    DateTime? occurredAt,
    String? paymentMethod,
    String? notes,
    String? updatedAt,
  }) => ExpenseTransaction(
    id: id,
    type: type ?? this.type,
    title: title ?? this.title,
    amountMinor: amountMinor ?? this.amountMinor,
    categoryId: categoryId ?? this.categoryId,
    categoryName: categoryName ?? this.categoryName,
    occurredAt: occurredAt ?? this.occurredAt,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    notes: notes ?? this.notes,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  String get monthKey => DateFormat('yyyy-MM').format(occurredAt);
}

/// RAW prevents Sheets from evaluating formulas; this prefix also protects
/// spreadsheet exports (CSV/Excel). Only our added prefix is removed on read.
String sanitizeSheetText(String value) {
  final clean = value.trim();
  final limited = clean.substring(0, clean.length.clamp(0, 500).toInt());
  return RegExp(r'^[=+\-@]').hasMatch(limited) ? "'$limited" : limited;
}

String restoreSheetText(String value) =>
    value.startsWith("'") &&
        value.length > 1 &&
        RegExp(r'^[=+\-@]').hasMatch(value.substring(1))
    ? value.substring(1)
    : value;

/// A stable row fingerprint catches manual edits in Sheets even when its
/// updatedAt cell is unchanged.
String sheetRowVersion(List<Object?> row) {
  final stored = row.length > 10 ? '${row[10] ?? ''}' : '';
  var hash = 0x811c9dc5;
  final bytes = row
      .take(10)
      .map((cell) => '${cell ?? ''}')
      .join('\u0000')
      .codeUnits;
  for (final byte in bytes) {
    hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
  }
  return '$stored#${hash.toRadixString(16).padLeft(8, '0')}';
}
