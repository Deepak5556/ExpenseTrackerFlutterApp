import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/design_system_widgets.dart';
import '../../../models/expense_category.dart';
import '../../../models/expense_transaction.dart';
import '../../data/expense_data_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({this.initialType = 'expense', super.key});

  final String initialType;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  late TransactionType _type;
  DateTime _occurredAt = DateTime.now();
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType == 'income'
        ? TransactionType.income
        : TransactionType.expense;
  }

  @override
  void didUpdateWidget(covariant AddTransactionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialType != widget.initialType) {
      _type = widget.initialType == 'income'
          ? TransactionType.income
          : TransactionType.expense;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _paymentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ExpenseDataState data = ref.watch(expenseDataProvider);
    final List<ExpenseCategory> categories = data.categories
        .where(
          (ExpenseCategory item) => item.type == _type.name && item.isActive,
        )
        .toList(growable: false);
    if (_categoryId != null &&
        !categories.any((ExpenseCategory c) => c.id == _categoryId)) {
      _categoryId = null;
    }
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Add transaction')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pageCompact),
          children: <Widget>[
            SegmentedButton<TransactionType>(
              segments: const <ButtonSegment<TransactionType>>[
                ButtonSegment<TransactionType>(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_upward_rounded),
                ),
                ButtonSegment<TransactionType>(
                  value: TransactionType.income,
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_downward_rounded),
                ),
              ],
              selected: <TransactionType>{_type},
              onSelectionChanged: (Set<TransactionType> selection) =>
                  setState(() {
                    _type = selection.single;
                    _categoryId = null;
                  }),
            ),
            const SizedBox(height: AppSpacing.x4),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _type == TransactionType.expense
                        ? 'Expense details'
                        : 'Income details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'For example, Groceries',
                    ),
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
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: data.currency == 'INR'
                          ? '₹ '
                          : '${data.currency} ',
                    ),
                    validator: (String? value) {
                      final int? amount = _parseMinorUnits(value ?? '');
                      if (amount == null || amount <= 0) {
                        return 'Enter an amount greater than zero.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  DropdownButtonFormField<String>(
                    key: ValueKey<String>(
                      'category-${_type.name}-${categories.length}',
                    ),
                    initialValue: _categoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: <DropdownMenuItem<String>>[
                      for (final ExpenseCategory category in categories)
                        DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                    ],
                    onChanged: categories.isEmpty
                        ? null
                        : (String? value) =>
                              setState(() => _categoryId = value),
                    validator: (String? value) =>
                        value == null ? 'Choose a category.' : null,
                    hint: Text(
                      data.isConnected ? 'Choose category' : 'Connect sheet',
                    ),
                  ),
                  if (data.isConnected && categories.isEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.x1),
                    TextButton.icon(
                      onPressed: () => context.push('/categories'),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add a category'),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.x3),
                  OutlinedButton.icon(
                    onPressed: _pickDateTime,
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: Text(
                      '${formatDate(_occurredAt)} · ${formatTime24h(_occurredAt)}',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  TextFormField(
                    controller: _paymentController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Payment method',
                      hintText: 'Optional',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  TextFormField(
                    controller: _notesController,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Optional',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  if (!data.isConnected) ...<Widget>[
                    const Text(
                      'Connect your Google Sheet before saving. The form stays on this screen until a write is confirmed.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/connect-spreadsheet'),
                        icon: const Icon(Icons.link_rounded),
                        label: const Text('Connect spreadsheet'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          data.isConnected &&
                              !data.saving &&
                              categories.isNotEmpty
                          ? _save
                          : null,
                      icon: data.saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        data.saving
                            ? 'Saving to Google Sheets…'
                            : 'Save ${_type.name}',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Cancel'),
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
          ],
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
      final TimeOfDay chosenTime = time ?? TimeOfDay.fromDateTime(_occurredAt);
      _occurredAt = DateTime(
        date.year,
        date.month,
        date.day,
        chosenTime.hour,
        chosenTime.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ExpenseDataState data = ref.read(expenseDataProvider);
    final ExpenseCategory category = data.categories.firstWhere(
      (ExpenseCategory item) => item.id == _categoryId,
    );
    final int amount = _parseMinorUnits(_amountController.text)!;
    try {
      await ref
          .read(expenseDataProvider.notifier)
          .addTransaction(
            type: _type,
            title: _titleController.text,
            amountMinor: amount,
            category: category,
            occurredAt: _occurredAt,
            paymentMethod: _paymentController.text,
            notes: _notesController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_type.name == 'expense' ? 'Expense' : 'Income'} saved to Google Sheets',
          ),
        ),
      );
      context.go('/journal');
    } catch (_) {
      // The controller exposes the sync error; keep all fields for retry.
    }
  }

  int? _parseMinorUnits(String raw) {
    final String normalized = raw.replaceAll(',', '').trim();
    if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(normalized)) return null;
    final List<String> pieces = normalized.split('.');
    final int? rupees = int.tryParse(pieces.first);
    if (rupees == null) return null;
    final int paise = pieces.length == 1
        ? 0
        : int.parse(pieces[1].padRight(2, '0'));
    return rupees * 100 + paise;
  }
}
