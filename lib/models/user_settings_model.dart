import 'package:flutter/foundation.dart';

@immutable
class UserSettingsModel {
  const UserSettingsModel({
    this.schemaVersion = 1,
    this.setupCompleted = false,
    this.setupMonth = '',
    this.monthlySalary = 0,
    this.monthlyBudget = 0,
    this.currency = 'INR',
    this.displayName = '',
    this.defaultMonth = '',
  });
  final int schemaVersion;
  final bool setupCompleted;
  final String setupMonth;
  final int monthlySalary;
  final int monthlyBudget;
  final String currency, displayName, defaultMonth;
  UserSettingsModel copyWith({
    bool? setupCompleted,
    String? setupMonth,
    int? monthlySalary,
    int? monthlyBudget,
    String? currency,
    String? displayName,
    String? defaultMonth,
  }) => UserSettingsModel(
    schemaVersion: schemaVersion,
    setupCompleted: setupCompleted ?? this.setupCompleted,
    setupMonth: setupMonth ?? this.setupMonth,
    monthlySalary: monthlySalary ?? this.monthlySalary,
    monthlyBudget: monthlyBudget ?? this.monthlyBudget,
    currency: currency ?? this.currency,
    displayName: displayName ?? this.displayName,
    defaultMonth: defaultMonth ?? this.defaultMonth,
  );
  Map<String, Object?> toSheetRows() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'setupCompleted': setupCompleted,
    'setupMonth': setupMonth,
    'monthlySalary': monthlySalary,
    'monthlyBudget': monthlyBudget,
    'currency': currency,
    'displayName': displayName,
    'defaultMonth': defaultMonth,
  };
  factory UserSettingsModel.fromRows(List<List<Object?>> rows) {
    final values = <String, String>{
      for (final row in rows.skip(1))
        if (row.length > 1) '${row[0]}': '${row[1] ?? ''}',
    };
    int num(String k) => int.tryParse(values[k] ?? '') ?? 0;
    return UserSettingsModel(
      schemaVersion: num('schemaVersion'),
      setupCompleted: values['setupCompleted']?.toLowerCase() == 'true',
      setupMonth: values['setupMonth'] ?? '',
      monthlySalary: num('monthlySalary'),
      monthlyBudget: num('monthlyBudget'),
      currency: values['currency'] ?? 'INR',
      displayName: values['displayName'] ?? '',
      defaultMonth: values['defaultMonth'] ?? '',
    );
  }
  @override
  bool operator ==(Object other) =>
      other is UserSettingsModel &&
      schemaVersion == other.schemaVersion &&
      setupCompleted == other.setupCompleted &&
      setupMonth == other.setupMonth &&
      monthlySalary == other.monthlySalary &&
      monthlyBudget == other.monthlyBudget &&
      currency == other.currency &&
      displayName == other.displayName &&
      defaultMonth == other.defaultMonth;
  @override
  int get hashCode => Object.hash(
    schemaVersion,
    setupCompleted,
    setupMonth,
    monthlySalary,
    monthlyBudget,
    currency,
    displayName,
    defaultMonth,
  );
}
