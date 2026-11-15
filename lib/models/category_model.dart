import 'package:flutter/foundation.dart';

@immutable
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.isActive = true,
    this.monthlyBudgetMinor = 0,
  });
  final String id, name, type;
  final bool isActive;
  final int monthlyBudgetMinor;
  CategoryModel copyWith({
    String? name,
    String? type,
    bool? isActive,
    int? monthlyBudgetMinor,
  }) => CategoryModel(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    isActive: isActive ?? this.isActive,
    monthlyBudgetMinor: monthlyBudgetMinor ?? this.monthlyBudgetMinor,
  );
  List<Object?> toSheetRow() => <Object?>[
    id,
    name.trim().substring(0, name.trim().length.clamp(0, 120)),
    type,
    isActive,
    monthlyBudgetMinor,
  ];
  factory CategoryModel.fromSheetRow(List<Object?> row) => CategoryModel(
    id: '${row[0]}'.trim(),
    name: '${row[1]}'.trim(),
    type: '${row[2]}'.trim(),
    isActive: '${row.length > 3 ? row[3] : true}'.toLowerCase() != 'false',
    monthlyBudgetMinor: _int(row.length > 4 ? row[4] : 0),
  );
  static int _int(Object? v) => v is num ? v.round() : int.tryParse('$v') ?? 0;
  @override
  bool operator ==(Object other) =>
      other is CategoryModel &&
      id == other.id &&
      name == other.name &&
      type == other.type &&
      isActive == other.isActive &&
      monthlyBudgetMinor == other.monthlyBudgetMinor;
  @override
  int get hashCode => Object.hash(id, name, type, isActive, monthlyBudgetMinor);
}
