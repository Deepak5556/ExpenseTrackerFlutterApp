import 'package:flutter/foundation.dart';

import 'expense_transaction.dart' show sheetRowVersion;

enum TransactionType { expense, income }

@immutable
class TransactionModel {
  const TransactionModel({
    required this.transactionId,
    required this.type,
    required this.title,
    required this.amountMinor,
    required this.categoryId,
    required this.categoryName,
    required this.date,
    required this.time,
    required this.updatedAt,
    this.paymentMethod = '',
    this.notes = '',
  });

  final String transactionId;
  final TransactionType type;
  final String title;
  final int amountMinor;
  final String categoryId;
  final String categoryName;

  /// User-selected date and time are stored as text to avoid timezone changes.
  final String date;
  final String time;
  final String paymentMethod;
  final String notes;
  final String updatedAt;

  TransactionModel copyWith({
    String? title,
    int? amountMinor,
    String? categoryId,
    String? categoryName,
    String? date,
    String? time,
    String? paymentMethod,
    String? notes,
    String? updatedAt,
  }) => TransactionModel(
    transactionId: transactionId,
    type: type,
    title: title ?? this.title,
    amountMinor: amountMinor ?? this.amountMinor,
    categoryId: categoryId ?? this.categoryId,
    categoryName: categoryName ?? this.categoryName,
    date: date ?? this.date,
    time: time ?? this.time,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    notes: notes ?? this.notes,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  List<Object?> toSheetRow() => <Object?>[
    transactionId,
    type.name,
    _safe(title),
    amountMinor,
    _safe(categoryId),
    _safe(categoryName),
    _safe('${date}T$time:00'),
    _safe(paymentMethod),
    _safe(notes),
    '',
    updatedAt,
  ];

  factory TransactionModel.fromSheetRow(List<Object?> row) {
    String cell(int i) => i < row.length ? '${row[i] ?? ''}'.trim() : '';
    final rawAmount = row.length > 3 ? row[3] : null;
    final amount = rawAmount is num ? rawAmount.round() : int.tryParse(cell(3));
    if (cell(0).isEmpty ||
        amount == null ||
        !<String>{'expense', 'income'}.contains(cell(1))) {
      throw FormatException('Invalid transaction row');
    }
    final dateTime = _unescape(cell(6));
    final split = dateTime.contains('|')
        ? dateTime.split('|')
        : dateTime.contains('T')
        ? <String>[dateTime.substring(0, 10), dateTime.substring(11, 16)]
        : <String>[dateTime, ''];
    return TransactionModel(
      transactionId: cell(0),
      type: TransactionType.values.byName(cell(1)),
      title: _unescape(cell(2)),
      amountMinor: amount,
      categoryId: _unescape(cell(4)),
      categoryName: _unescape(cell(5)),
      date: split.first,
      time: split.length > 1 ? split[1] : '',
      paymentMethod: _unescape(cell(7)),
      notes: _unescape(cell(8)),
      updatedAt: sheetRowVersion(row),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TransactionModel &&
      transactionId == other.transactionId &&
      type == other.type &&
      title == other.title &&
      amountMinor == other.amountMinor &&
      categoryId == other.categoryId &&
      categoryName == other.categoryName &&
      date == other.date &&
      time == other.time &&
      paymentMethod == other.paymentMethod &&
      notes == other.notes &&
      updatedAt == other.updatedAt;
  @override
  int get hashCode => Object.hash(
    transactionId,
    type,
    title,
    amountMinor,
    categoryId,
    categoryName,
    date,
    time,
    paymentMethod,
    notes,
    updatedAt,
  );
}

String _safe(String value) {
  final clean = value.trim();
  final trimmed = clean.substring(0, clean.length.clamp(0, 500).toInt());
  return RegExp(r'^[=+\-@]').hasMatch(trimmed) ? "'$trimmed" : trimmed;
}

String _unescape(String value) =>
    value.startsWith("'") &&
        value.length > 1 &&
        RegExp(r'^[=+\-@]').hasMatch(value.substring(1))
    ? value.substring(1)
    : value;
