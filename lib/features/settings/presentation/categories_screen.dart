import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/design_system_widgets.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../features/data/expense_data_provider.dart';
import '../../../models/expense_category.dart';
import '../../../models/expense_transaction.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});
  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String _type = 'expense';
  bool _showInactive = false;

  @override
  Widget build(BuildContext context) {
    final ExpenseDataState data = ref.watch(expenseDataProvider);
    final List<ExpenseCategory> categories = data.categories
        .where(
          (ExpenseCategory item) =>
              item.type == _type && (_showInactive || item.isActive),
        )
        .toList(growable: false);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('Categories'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Add category',
            onPressed: data.isConnected ? _editCategory : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: ResponsiveListView(
        children: <Widget>[
          if (!data.isConnected)
            SurfaceCard(
              child: EmptyState(
                icon: Icons.category_outlined,
                title: 'Connect your spreadsheet',
                message: 'Your expense and income categories are stored in the Categories tab of your workbook.',
              ),
            )
          else ...<Widget>[
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: 'expense',
                  label: Text('Expenses'),
                ),
                ButtonSegment<String>(value: 'income', label: Text('Income')),
              ],
              selected: <String>{_type},
              onSelectionChanged: (Set<String> value) =>
                  setState(() => _type = value.single),
            ),
            const SizedBox(height: AppSpacing.x3),
            SurfaceCard(
              child: Column(
                children: <Widget>[
                  for (
                    int index = 0;
                    index < categories.length;
                    index++
                  ) ...<Widget>[
                    if (index > 0) const Divider(height: 1),
                    _CategoryTile(
                      category: categories[index],
                      usage: data.transactions
                          .where(
                            (ExpenseTransaction item) =>
                                item.categoryId == categories[index].id,
                          )
                          .length,
                      onEdit: () => _editCategory(categories[index]),
                      onArchive: () => _archiveCategory(categories[index]),
                    ),
                  ],
                  if (categories.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.x4),
                      child: EmptyState(
                        icon: Icons.category_outlined,
                        title: 'No categories here yet',
                        message: 'Add a category to classify your ${_type}s.',
                        actionLabel: 'Add category',
                        onAction: _editCategory,
                      ),
                    ),
                ],
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _showInactive,
              title: const Text('Show archived categories'),
              onChanged: (bool? value) =>
                  setState(() => _showInactive = value ?? false),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _editCategory,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add category'),
              ),
            ),
          ],
          if (data.error != null) ...<Widget>[
            const SizedBox(height: AppSpacing.x2),
            Text(
              data.error!,
              style: const TextStyle(color: AppColors.brandStart),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _editCategory([ExpenseCategory? category]) async {
    final TextEditingController name = TextEditingController(
      text: category?.name ?? '',
    );
    String type = category?.type ?? _type;
    final ExpenseCategory? result = await showDialog<ExpenseCategory>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) =>
            AlertDialog(
              title: Text(category == null ? 'New category' : 'Edit category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: name,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Category name',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  SegmentedButton<String>(
                    segments: const <ButtonSegment<String>>[
                      ButtonSegment<String>(
                        value: 'expense',
                        label: Text('Expense'),
                      ),
                      ButtonSegment<String>(
                        value: 'income',
                        label: Text('Income'),
                      ),
                    ],
                    selected: <String>{type},
                    onSelectionChanged: (Set<String> value) =>
                        setDialogState(() => type = value.single),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final String value = name.text.trim();
                    if (value.isEmpty) return;
                    Navigator.pop(
                      dialogContext,
                      ExpenseCategory(
                        id: category?.id ?? const Uuid().v4(),
                        name: value,
                        type: type,
                        isActive: category?.isActive ?? true,
                        monthlyBudgetMinor: category?.monthlyBudgetMinor ?? 0,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
      ),
    );
    name.dispose();
    if (result == null || !mounted) return;
    try {
      if (category == null) {
        await ref.read(expenseDataProvider.notifier).addCategory(result);
      } else {
        await ref.read(expenseDataProvider.notifier).updateCategory(result);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(expenseDataProvider).error ?? 'Could not save category.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _archiveCategory(ExpenseCategory category) async {
    try {
      await ref
          .read(expenseDataProvider.notifier)
          .updateCategory(
            ExpenseCategory(
              id: category.id,
              name: category.name,
              type: category.type,
              isActive: !category.isActive,
              monthlyBudgetMinor: category.monthlyBudgetMinor,
            ),
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(expenseDataProvider).error ??
                  'Could not update category.',
            ),
          ),
        );
      }
    }
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.usage,
    required this.onEdit,
    required this.onArchive,
  });
  final ExpenseCategory category;
  final int usage;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(
      backgroundColor: AppColors.orangePillSurface,
      child: Icon(
        category.type == 'income'
            ? Icons.south_west_rounded
            : Icons.category_outlined,
        color: AppColors.brandStart,
      ),
    ),
    title: Text(category.name, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: Text(
      '$usage transactions${category.monthlyBudgetMinor > 0 ? ' · ${formatMoney(category.monthlyBudgetMinor)} budget' : ''}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: Wrap(
      spacing: 0,
      children: <Widget>[
        IconButton(
          tooltip: 'Edit category',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: category.isActive ? 'Archive category' : 'Restore category',
          onPressed: onArchive,
          icon: Icon(
            category.isActive
                ? Icons.archive_outlined
                : Icons.unarchive_outlined,
          ),
        ),
      ],
    ),
  );
}
