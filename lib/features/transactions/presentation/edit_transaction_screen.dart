import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/design_system_widgets.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../features/data/expense_data_provider.dart';
import '../../../models/expense_category.dart';
import '../../../models/expense_transaction.dart';

class EditTransactionScreen extends ConsumerStatefulWidget {
  const EditTransactionScreen({required this.transactionId, super.key});
  final String transactionId;
  @override
  ConsumerState<EditTransactionScreen> createState() =>
      _EditTransactionScreenState();
}

class _EditTransactionScreenState extends ConsumerState<EditTransactionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String? _loadedId;
  String? _categoryId;
  DateTime _occurredAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _paymentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final ExpenseDataController controller = ref.read(
      expenseDataProvider.notifier,
    );
    await controller.initialize();
    if (ref.read(expenseDataProvider).transactions.isEmpty &&
        ref.read(expenseDataProvider).isConnected) {
      try {
        await controller.refresh();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final ExpenseDataState data = ref.watch(expenseDataProvider);
    ExpenseTransaction? item;
    for (final ExpenseTransaction candidate in data.transactions) {
      if (candidate.id == widget.transactionId) item = candidate;
    }
    if (item != null && _loadedId != item.id) {
      _loadedId = item.id;
      _titleController.text = item.title;
      _amountController.text = (item.amountMinor / 100).toStringAsFixed(
        item.amountMinor % 100 == 0 ? 0 : 2,
      );
      _paymentController.text = item.paymentMethod;
      _notesController.text = item.notes;
      _categoryId = item.categoryId;
      _occurredAt = item.occurredAt;
    }
    if (item == null) {
      return Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: AppBar(title: const Text('Edit transaction')),
        body: Center(
          child: data.loading
              ? const CircularProgressIndicator()
              : Text(
                  'Transaction ${widget.transactionId} could not be loaded. ${data.error ?? ''}',
                ),
        ),
      );
    }
    final ExpenseTransaction transaction = item;
    final List<ExpenseCategory> categories = data.categories
        .where(
          (ExpenseCategory category) =>
              category.isActive &&
              (category.type == transaction.type.name ||
                  category.id == transaction.categoryId),
        )
        .toList(growable: false);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Edit transaction')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Form(
          key: _formKey,
          child: ResponsiveListView(
          children: <Widget>[
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  PillBadge(
                    label: transaction.type == TransactionType.income
                        ? 'Income'
                        : 'Expense',
                    icon: transaction.type == TransactionType.income
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (String? value) =>
                        value == null || value.trim().isEmpty
                        ? 'Enter a title.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₹ ',
                    ),
                    validator: (String? value) =>
                        _parseMinor(value ?? '') == null
                        ? 'Enter a valid amount.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  DropdownButtonFormField<String>(
                    initialValue:
                        categories.any(
                          (ExpenseCategory category) =>
                              category.id == _categoryId,
                        )
                        ? _categoryId
                        : null,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: <DropdownMenuItem<String>>[
                      for (final ExpenseCategory category in categories)
                        DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                    ],
                    onChanged: (String? value) =>
                        setState(() => _categoryId = value),
                    validator: (String? value) =>
                        value == null ? 'Choose a category.' : null,
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickDateTime,
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(
                        '${formatDate(_occurredAt)} · ${formatTime24h(_occurredAt)}',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  TextFormField(
                    controller: _paymentController,
                    decoration: const InputDecoration(
                      labelText: 'Payment method',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  TextFormField(
                    controller: _notesController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: data.saving ? null : () => _save(transaction),
                      icon: data.saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(data.saving ? 'Saving…' : 'Save changes'),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  if (data.error != null)
                    Text(
                      data.error!,
                      style: const TextStyle(color: AppColors.brandStart),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (!mounted) return;
    setState(() {
      final TimeOfDay selected = time ?? TimeOfDay.fromDateTime(_occurredAt);
      _occurredAt = DateTime(
        date.year,
        date.month,
        date.day,
        selected.hour,
        selected.minute,
      );
    });
  }

  Future<void> _save(ExpenseTransaction old) async {
    if (!_formKey.currentState!.validate()) return;
    final ExpenseDataState data = ref.read(expenseDataProvider);
    final ExpenseCategory category = data.categories.firstWhere(
      (ExpenseCategory item) => item.id == _categoryId,
    );
    try {
      await ref
          .read(expenseDataProvider.notifier)
          .updateTransaction(
            old.copyWith(
              title: _titleController.text.trim(),
              amountMinor: _parseMinor(_amountController.text)!,
              categoryId: category.id,
              categoryName: category.name,
              occurredAt: _occurredAt,
              paymentMethod: _paymentController.text.trim(),
              notes: _notesController.text.trim(),
            ),
          );
      if (mounted) {
        AppFeedback.showSuccess(context, 'Transaction updated in Google Sheets');
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(
          context,
          'Could not update transaction. Check connection and retry.',
        );
      }
    }
  }

  int? _parseMinor(String value) {
    final String normalized = value.replaceAll(',', '').trim();
    if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(normalized)) return null;
    final List<String> parts = normalized.split('.');
    return (int.tryParse(parts.first) ?? 0) * 100 +
        (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
  }
}
