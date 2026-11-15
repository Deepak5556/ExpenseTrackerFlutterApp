import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/design_system_widgets.dart';
import '../../data/expense_data_provider.dart';
import '../../../models/expense_transaction.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({required this.transactionId, super.key});
  final String transactionId;

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    final ExpenseDataController controller = ref.read(
      expenseDataProvider.notifier,
    );
    await controller.initialize();
    if (ref.read(expenseDataProvider).isConnected &&
        ref.read(expenseDataProvider).transactions.isEmpty) {
      try {
        await controller.refresh();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final ExpenseDataState data = ref.watch(expenseDataProvider);
    final ExpenseTransaction? item = _find(data);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('Transaction details'),
        actions: <Widget>[
          if (item != null)
            IconButton(
              tooltip: 'Edit transaction',
              onPressed: () => context.push('/transaction/${item.id}/edit'),
              icon: const Icon(Icons.edit_outlined),
            ),
          if (item != null)
            IconButton(
              tooltip: 'Delete transaction',
              onPressed: () => _delete(context, item),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: item == null
          ? Center(
              child: data.loading
                  ? const CircularProgressIndicator()
                  : SurfaceCard(
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Transaction not available',
                        message: data.isConnected
                            ? data.error ??
                                  'Transaction ${widget.transactionId} was not found in the connected sheet.'
                            : 'Transaction ${widget.transactionId} is not loaded. Connect the spreadsheet that contains it.',
                        actionLabel: data.isConnected
                            ? null
                            : 'Connect spreadsheet',
                        onAction: data.isConnected
                            ? null
                            : () => context.push('/connect-spreadsheet'),
                      ),
                    ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.pageCompact),
              children: <Widget>[
                SurfaceCard(
                  child: Column(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: item.type == TransactionType.income
                            ? AppColors.incomeSurface
                            : AppColors.orangePillSurface,
                        child: Icon(
                          item.type == TransactionType.income
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
                          color: item.type == TransactionType.income
                              ? AppColors.income
                              : AppColors.brandStart,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x3),
                      Text(
                        item.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      Text(
                        item.type == TransactionType.income
                            ? 'Income'
                            : 'Expense',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      AmountText(
                        minorUnits: item.type == TransactionType.income
                            ? item.amountMinor
                            : -item.amountMinor,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: item.type == TransactionType.income
                                  ? AppColors.income
                                  : AppColors.brandStart,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                SurfaceCard(
                  child: Column(
                    children: <Widget>[
                      _DetailRow(
                        label: 'Category',
                        value: item.categoryName,
                        icon: Icons.category_outlined,
                      ),
                      const Divider(),
                      _DetailRow(
                        label: 'Date',
                        value: formatDate(item.occurredAt),
                        icon: Icons.calendar_month_outlined,
                      ),
                      const Divider(),
                      _DetailRow(
                        label: 'Time',
                        value: formatTime24h(item.occurredAt),
                        icon: Icons.schedule_rounded,
                      ),
                      if (item.paymentMethod.isNotEmpty) ...<Widget>[
                        const Divider(),
                        _DetailRow(
                          label: 'Payment method',
                          value: item.paymentMethod,
                          icon: Icons.credit_card_rounded,
                        ),
                      ],
                      if (item.notes.isNotEmpty) ...<Widget>[
                        const Divider(),
                        _DetailRow(
                          label: 'Notes',
                          value: item.notes,
                          icon: Icons.notes_rounded,
                        ),
                      ],
                      const Divider(),
                      _DetailRow(
                        label: 'Transaction ID',
                        value: item.id,
                        icon: Icons.fingerprint_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                FilledButton.icon(
                  onPressed: () => context.push('/transaction/${item.id}/edit'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit transaction'),
                ),
              ],
            ),
    );
  }

  ExpenseTransaction? _find(ExpenseDataState data) {
    for (final ExpenseTransaction item in data.transactions) {
      if (item.id == widget.transactionId) return item;
    }
    return null;
  }

  Future<void> _delete(BuildContext context, ExpenseTransaction item) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Delete transaction?'),
            content: Text(
              '“${item.title}” will be marked as deleted in your Google Sheet and hidden from this app.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await ref.read(expenseDataProvider.notifier).deleteTransaction(item.id);
      if (context.mounted) context.go('/journal');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(expenseDataProvider).error ??
                  'Could not delete transaction.',
            ),
          ),
        );
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: AppColors.labels, size: 20),
        const SizedBox(width: AppSpacing.x3),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    ),
  );
}
