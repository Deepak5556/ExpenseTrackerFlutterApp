import 'expense_transaction.dart';

class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.type,
    this.isActive = true,
    this.monthlyBudgetMinor = 0,
  });

  final String id;
  final String name;
  final String type;
  final bool isActive;
  final int monthlyBudgetMinor;

  List<Object?> toSheetRow() => <Object?>[
    id,
    sanitizeSheetText(name),
    type,
    isActive,
    monthlyBudgetMinor,
  ];

  factory ExpenseCategory.fromSheetRow(List<Object?> row) {
    String text(int index) => index < row.length ? '${row[index] ?? ''}' : '';
    return ExpenseCategory(
      id: text(0),
      name: restoreSheetText(text(1)),
      type: text(2).isEmpty ? 'expense' : text(2),
      isActive: text(3).toLowerCase() != 'false',
      monthlyBudgetMinor: int.tryParse(text(4)) ?? 0,
    );
  }
}

const List<ExpenseCategory> defaultExpenseCategories = <ExpenseCategory>[
  ExpenseCategory(id: 'food', name: 'Food', type: 'expense'),
  ExpenseCategory(id: 'tea-coffee', name: 'Tea / Coffee', type: 'expense'),
  ExpenseCategory(id: 'fruits', name: 'Fruits', type: 'expense'),
  ExpenseCategory(id: 'transport', name: 'Transport', type: 'expense'),
  ExpenseCategory(id: 'shopping', name: 'Shopping', type: 'expense'),
  ExpenseCategory(id: 'home', name: 'Home', type: 'expense'),
  ExpenseCategory(id: 'salary', name: 'Salary', type: 'income'),
  ExpenseCategory(id: 'other-income', name: 'Other income', type: 'income'),
];
