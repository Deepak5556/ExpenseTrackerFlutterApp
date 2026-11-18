import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/design_system_widgets.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../features/data/expense_data_provider.dart';
import '../../../models/expense_category.dart';
import '../../../models/expense_transaction.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});
  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String? _categoryId;
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ExpenseDataState data = ref.watch(expenseDataProvider);
    final List<ExpenseCategory> categories = data.categories
        .where(
          (ExpenseCategory item) => item.type == 'expense' && item.isActive,
        )
        .toList(growable: false);
    if (_categoryId != null &&
        !categories.any((ExpenseCategory item) => item.id == _categoryId)) {
      _categoryId = null;
    }
    final String monthKey = formatMonthKey(_month);
    final Map<String, int> spent = <String, int>{};
    for (final ExpenseTransaction item in data.transactions.where(
      (ExpenseTransaction item) =>
          item.type == TransactionType.expense &&
          item.occurredAt.year == _month.year &&
          item.occurredAt.month == _month.month,
    )) {
      spent.update(
        item.categoryId,
        (int amount) => amount + item.amountMinor,
        ifAbsent: () => item.amountMinor,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Budgets')),
      body: ResponsiveListView(
        children: <Widget>[
          if (!data.isConnected)
            SurfaceCard(
              child: EmptyState(
                icon: Icons.savings_outlined,
                title: 'Connect your spreadsheet',
                message:
                    'Budgets are stored in the Budgets worksheet and compared with your live transactions.',
                actionLabel: 'Connect spreadsheet',
                onAction: () => context.push('/connect-spreadsheet'),
              ),
            )
          else ...<Widget>[
            SurfaceCard(
              child: Row(
                children: <Widget>[
                  IconButton(
                    tooltip: 'Previous month',
                    onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1),
                    ),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatMonthLabel(_month),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next month',
                    onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month + 1),
                    ),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x3),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SectionHeader(
                    title: 'Set a category budget',
                    subtitle: 'Choose a monthly spending limit.',
                    leading: Icon(
                      Icons.tune_rounded,
                      color: AppColors.brandStart,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Expense category',
                    ),
                    items: <DropdownMenuItem<String>>[
                      for (final ExpenseCategory category in categories)
                        DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                    ],
                    onChanged: (String? value) {
                      setState(() {
                        _categoryId = value;
                        final int existing = value == null
                            ? 0
                            : data.budgets['$monthKey|$value'] ?? 0;
                        _amountController.text = existing == 0
                            ? ''
                            : (existing / 100).toStringAsFixed(
                                existing % 100 == 0 ? 0 : 2,
                              );
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Budget limit',
                      prefixText: '₹ ',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: data.saving || _categoryId == null
                          ? null
                          : _saveBudget,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(data.saving ? 'Saving…' : 'Save budget'),
                    ),
                  ),
                  if (data.error != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      data.error!,
                      style: const TextStyle(color: AppColors.brandStart),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x3),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SectionHeader(
                    title: 'Budget progress',
                    subtitle: 'Actual spending compared with your limits',
                    leading: Icon(
                      Icons.stacked_bar_chart_rounded,
                      color: AppColors.accentOrange,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  for (final ExpenseCategory category in categories)
                    _BudgetProgressRow(
                      category: category,
                      amount:
                          data.budgets['$monthKey|${category.id}'] ??
                          category.monthlyBudgetMinor,
                      spent: spent[category.id] ?? 0,
                    ),
                  if (categories.isEmpty)
                    const Text(
                      'Add an expense category before setting budgets.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveBudget() async {
    final String value = _amountController.text.replaceAll(',', '').trim();
    if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(value)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid budget amount.')),
      );
      return;
    }
    final List<String> parts = value.split('.');
    final int amountMinor =
        (int.tryParse(parts[0]) ?? 0) * 100 +
        (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
    try {
      await ref
          .read(expenseDataProvider.notifier)
          .setBudget(formatMonthKey(_month), _categoryId!, amountMinor);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget saved to Google Sheets.')),
        );
      }
    } catch (_) {
      // The visible error from provider keeps the form ready for another try.
    }
  }
}

class _BudgetProgressRow extends StatelessWidget {
  const _BudgetProgressRow({
    required this.category,
    required this.amount,
    required this.spent,
  });
  final ExpenseCategory category;
  final int amount;
  final int spent;

  @override
  Widget build(BuildContext context) {
    final bool over = amount > 0 && spent > amount;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  category.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                amount == 0
                    ? 'No limit'
                    : '${formatMoney(spent)} / ${formatMoney(amount)}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: over ? AppColors.brandStart : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x1),
          LinearProgressIndicator(
            value: amount == 0 ? 0 : (spent / amount).clamp(0, 1).toDouble(),
            color: over ? AppColors.brandStart : AppColors.accentOrange,
            backgroundColor: AppColors.border,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
          if (over)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.x1),
              child: Text(
                '${formatMoney(spent - amount)} over budget',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: AppColors.brandStart),
              ),
            ),
        ],
      ),
    );
  }
}
