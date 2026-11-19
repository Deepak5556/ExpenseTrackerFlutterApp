import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import '../../transactions/application/transactions_controller.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({
    this.initialType = 'expense',
    this.transactionId,
    super.key,
  });

  final String initialType;
  final String? transactionId;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  late TransactionType _type;
  late String _transactionId;
  DateTime _occurredAt = DateTime.now();
  String? _categoryId;
  String? _categoryName;
  String _paymentMethod = 'UPI';
  String? _existingUpdatedAt;

  bool _isSaving = false;
  bool _isSuccess = false;
  String? _errorMessage;
  bool _isDirty = false;

  static const List<String> _paymentMethods = <String>[
    'Cash',
    'UPI',
    'Card',
    'Net banking',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType.toLowerCase() == 'income'
        ? TransactionType.income
        : TransactionType.expense;
    _transactionId = widget.transactionId ?? const Uuid().v4();

    _titleController.addListener(_markDirty);
    _amountController.addListener(_markDirty);
    _notesController.addListener(_markDirty);

    if (widget.transactionId != null) {
      Future<void>.microtask(_loadExistingTransaction);
    }
  }

  void _markDirty() {
    if (!_isDirty && mounted) {
      setState(() => _isDirty = true);
    }
  }

  void _loadExistingTransaction() {
    final List<TransactionModel> transactions =
        ref.read(transactionsControllerProvider).value ??
        const <TransactionModel>[];
    final TransactionModel? item = transactions
        .where((TransactionModel t) => t.transactionId == widget.transactionId)
        .firstOrNull;

    if (item != null) {
      _populateFromModel(item);
    }
  }

  void _populateFromModel(TransactionModel item) {
    setState(() {
      _type = item.type;
      _titleController.text = item.title;
      _amountController.text = (item.amountMinor / 100).toStringAsFixed(
        item.amountMinor % 100 == 0 ? 0 : 2,
      );
      _categoryId = item.categoryId;
      _categoryName = item.categoryName;
      _paymentMethod = item.paymentMethod.isNotEmpty
          ? item.paymentMethod
          : 'UPI';
      _notesController.text = item.notes;
      _existingUpdatedAt = item.updatedAt;

      final List<String> dateParts = item.date.split('-');
      final List<String> timeParts = item.time.split(':');
      if (dateParts.length == 3) {
        final int year = int.tryParse(dateParts[0]) ?? _occurredAt.year;
        final int month = int.tryParse(dateParts[1]) ?? _occurredAt.month;
        final int day = int.tryParse(dateParts[2]) ?? _occurredAt.day;
        final int hour = timeParts.isNotEmpty
            ? int.tryParse(timeParts[0]) ?? _occurredAt.hour
            : _occurredAt.hour;
        final int minute = timeParts.length > 1
            ? int.tryParse(timeParts[1]) ?? _occurredAt.minute
            : _occurredAt.minute;
        _occurredAt = DateTime(year, month, day, hour, minute);
      }
      _isDirty = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty || _isSuccess) return true;
    return await AppFeedback.showConfirmationDialog(
      context,
      title: 'Discard unsaved changes?',
      message:
          'You have unconfirmed edits. If you leave now, your changes will not be saved.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
      isDestructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompact = MediaQuery.sizeOf(context).width < 600;
    final bool isEditing = widget.transactionId != null;

    final Widget content = PopScope(
      canPop: !_isDirty || _isSuccess,
      onPopInvokedWithResult: (bool didPop, dynamic _) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Stack(
        children: <Widget>[
          Scaffold(
            backgroundColor: AppColors.pageBackground,
            body: Column(
              children: <Widget>[
                _buildHeader(isEditing),
                Expanded(
                  child: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    behavior: HitTestBehavior.opaque,
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.x4,
                          AppSpacing.x3,
                          AppSpacing.x4,
                          AppSpacing.x8,
                        ),
                        children: <Widget>[
                          if (_errorMessage != null) _buildErrorBanner(),
                          _buildAmountHero(),
                          const SizedBox(height: AppSpacing.x4),
                          _buildTypeSegmentedControl(),
                          const SizedBox(height: AppSpacing.x4),
                          _buildCategorySection(),
                          const SizedBox(height: AppSpacing.x4),
                          _buildTitleField(),
                          const SizedBox(height: AppSpacing.x3),
                          _buildDateTimeSection(),
                          const SizedBox(height: AppSpacing.x3),
                          _buildPaymentMethodSection(),
                          const SizedBox(height: AppSpacing.x3),
                          _buildNotesField(),
                          const SizedBox(height: AppSpacing.x6),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildStickyBottomBar(isEditing),
              ],
            ),
          ),
          if (_isSuccess) _buildSuccessOverlay(),
        ],
      ),
    );

    if (isCompact) {
      return content;
    }

    return Scaffold(
      backgroundColor: Colors.black45,
      body: Center(
        child: Container(
          width: 560,
          height: MediaQuery.sizeOf(context).height * 0.9,
          decoration: BoxDecoration(
            color: AppColors.pageBackground,
            borderRadius: BorderRadius.circular(AppRadius.sheet),
            boxShadow: AppShadows.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: content,
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEditing) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.x3,
        MediaQuery.paddingOf(context).top + AppSpacing.x2,
        AppSpacing.x4,
        AppSpacing.x3,
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Close',
            onPressed: () async {
              if (await _onWillPop() && mounted) {
                context.pop();
              }
            },
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  isEditing
                      ? 'Edit transaction'
                      : (_type == TransactionType.expense
                          ? 'Add expense'
                          : 'Add income'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isEditing)
                  Text(
                    _existingUpdatedAt != null
                        ? 'ID: ${widget.transactionId!} · Last updated ${_formatUpdatedAt(_existingUpdatedAt!)}'
                        : 'ID: ${widget.transactionId!}',
                    style: const TextStyle(
                      color: AppColors.onGradientSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.x3),
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: AppColors.orangePillSurface,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: AppColors.brandStart.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.brandStart,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppColors.brandStart,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _isSaving ? null : _submit,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
              minimumSize: const Size(48, 32),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                color: AppColors.brandStart,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountHero() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'AMOUNT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.labels,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.x1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                '₹',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: _type == TransactionType.income
                      ? AppColors.income
                      : AppColors.brandStart,
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  autofocus: widget.transactionId == null,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: _type == TransactionType.income
                        ? AppColors.income
                        : AppColors.textPrimary,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  validator: FormValidators.validateAmount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSegmentedControl() {
    return SegmentedButton<TransactionType>(
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
      onSelectionChanged: (Set<TransactionType> selection) {
        setState(() {
          _type = selection.single;
          _categoryId = null;
          _categoryName = null;
          _isDirty = true;
        });
      },
    );
  }

  Widget _buildCategorySection() {
    final categoriesAsync = ref.watch(categoriesListProvider);
    final allCategories = categoriesAsync.value ?? const <CategoryModel>[];
    final activeCategories = allCategories
        .where((c) => c.type == _type.name && c.isActive)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'CATEGORY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.labels,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.x2),
        Wrap(
          spacing: AppSpacing.x2,
          runSpacing: AppSpacing.x2,
          children: <Widget>[
            for (final CategoryModel cat in activeCategories)
              ChoiceChip(
                avatar: Icon(
                  _categoryIcon(cat.name),
                  size: 18,
                  color: _categoryId == cat.id ? Colors.white : AppColors.brandStart,
                ),
                label: Text(cat.name),
                selected: _categoryId == cat.id,
                selectedColor: AppColors.brandStart,
                labelStyle: TextStyle(
                  color: _categoryId == cat.id ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (bool selected) {
                  setState(() {
                    _categoryId = selected ? cat.id : null;
                    _categoryName = selected ? cat.name : null;
                    _isDirty = true;
                  });
                },
              ),
            ActionChip(
              avatar: const Icon(Icons.add_rounded, size: 18, color: AppColors.brandStart),
              label: const Text('+ New'),
              onPressed: _showAddCategorySheet,
            ),
          ],
        ),
        if (_categoryId == null)
          FormField<String>(
            validator: (_) => FormValidators.validateCategory(_categoryId),
            builder: (FormFieldState<String> state) {
              if (state.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.x1),
                  child: Text(
                    state.errorText!,
                    style: const TextStyle(
                      color: AppColors.brandStart,
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Title',
        hintText: 'e.g. Groceries, Dinner, Metro ticket',
        prefixIcon: Icon(Icons.title_rounded),
      ),
      validator: FormValidators.validateTitle,
    );
  }

  Widget _buildDateTimeSection() {
    return Row(
      children: <Widget>[
        Expanded(
          child: InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(AppRadius.tile),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.x3),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.tile),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.labels),
                  const SizedBox(width: AppSpacing.x2),
                  Expanded(
                    child: Text(
                      formatDate(_occurredAt),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.x2),
        Expanded(
          child: InkWell(
            onTap: _pickTime,
            borderRadius: BorderRadius.circular(AppRadius.tile),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.x3),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.tile),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.schedule_rounded, size: 18, color: AppColors.labels),
                  const SizedBox(width: AppSpacing.x2),
                  Expanded(
                    child: Text(
                      formatTime24h(_occurredAt),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'PAYMENT METHOD',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.labels,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.x2),
        Wrap(
          spacing: AppSpacing.x2,
          runSpacing: AppSpacing.x2,
          children: <Widget>[
            for (final String method in _paymentMethods)
              ChoiceChip(
                label: Text(method),
                selected: _paymentMethod == method,
                selectedColor: AppColors.brandStart,
                labelStyle: TextStyle(
                  color: _paymentMethod == method ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (bool selected) {
                  if (selected) {
                    setState(() {
                      _paymentMethod = method;
                      _isDirty = true;
                    });
                  }
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLength: FormValidators.maxNotesLength,
      maxLines: 3,
      minLines: 2,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Notes (optional)',
        hintText: 'Add any extra details or tags',
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildStickyBottomBar(bool isEditing) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.x4,
        AppSpacing.x2,
        AppSpacing.x4,
        MediaQuery.paddingOf(context).bottom + AppSpacing.x2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: _isSaving ? null : _submit,
          icon: _isSaving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.check_rounded),
          label: Text(
            _isSaving
                ? 'Saving to Google Sheets…'
                : (isEditing ? 'Update transaction' : 'Save ${_type.name}'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (BuildContext context, double value, Widget? child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  boxShadow: AppShadows.card,
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.income,
                      size: 54,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Saved!',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && mounted) {
      setState(() {
        _occurredAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _occurredAt.hour,
          _occurredAt.minute,
        );
        _isDirty = true;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (picked != null && mounted) {
      setState(() {
        _occurredAt = DateTime(
          _occurredAt.year,
          _occurredAt.month,
          _occurredAt.day,
          picked.hour,
          picked.minute,
        );
        _isDirty = true;
      });
    }
  }

  Future<void> _showAddCategorySheet() async {
    final TextEditingController nameController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pageBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.x4,
            AppSpacing.x4,
            AppSpacing.x4,
            MediaQuery.viewInsetsOf(ctx).bottom + AppSpacing.x4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Add ${_type.name} category',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.x3),
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Category name',
                  hintText: 'e.g. Subscriptions, Gifts',
                ),
              ),
              const SizedBox(height: AppSpacing.x4),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final String name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final String newId = 'cat-${name.toLowerCase().replaceAll(RegExp(r'\s+'), '-')}';
                    final CategoryModel newCat = CategoryModel(
                      id: newId,
                      name: name,
                      type: _type.name,
                    );
                    await ref.read(categoriesListProvider.notifier).addCategory(newCat);
                    if (mounted) {
                      setState(() {
                        _categoryId = newCat.id;
                        _categoryName = newCat.name;
                        _isDirty = true;
                      });
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Add category'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate() || _categoryId == null) {
      return;
    }

    final int? amountMinor = FormValidators.parseAmountMinor(_amountController.text);
    if (amountMinor == null || amountMinor <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount greater than 0.');
      return;
    }

    setState(() => _isSaving = true);

    final String dateString =
        '${_occurredAt.year.toString().padLeft(4, '0')}-${_occurredAt.month.toString().padLeft(2, '0')}-${_occurredAt.day.toString().padLeft(2, '0')}';
    final String timeString =
        '${_occurredAt.hour.toString().padLeft(2, '0')}:${_occurredAt.minute.toString().padLeft(2, '0')}';

    final TransactionModel model = TransactionModel(
      transactionId: _transactionId,
      type: _type,
      title: _titleController.text.trim(),
      amountMinor: amountMinor,
      categoryId: _categoryId!,
      categoryName: _categoryName ?? 'Other',
      date: dateString,
      time: timeString,
      paymentMethod: _paymentMethod,
      notes: _notesController.text.trim(),
      updatedAt: _existingUpdatedAt ?? DateTime.now().toUtc().toIso8601String(),
    );

    final TransactionsController controller =
        ref.read(transactionsControllerProvider.notifier);
    final TransactionMutationResult result = widget.transactionId != null
        ? await controller.edit(model)
        : await controller.add(model);

    if (!mounted) return;

    switch (result) {
      case MutationSuccess():
        await HapticFeedback.lightImpact();
        setState(() {
          _isSaving = false;
          _isSuccess = true;
        });
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (mounted) {
          context.pop();
        }
      case MutationConflict(:final TransactionModel current):
        setState(() => _isSaving = false);
        _handleConflict(model, current);
      case MutationFailure(:final String? message):
        setState(() {
          _isSaving = false;
          _errorMessage = message ?? 'Could not save to Google Sheets. Check connection and retry.';
        });
    }
  }

  Future<void> _handleConflict(TransactionModel attempted, TransactionModel remoteCurrent) async {
    final String? action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Changed elsewhere'),
          content: Text(
            'This transaction was modified in Google Sheets by another session.\n\n'
            'Remote title: ${remoteCurrent.title}\n'
            'Remote amount: ₹${(remoteCurrent.amountMinor / 100).toStringAsFixed(2)}\n\n'
            'Choose how you want to proceed:',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'review'),
              child: const Text('Review changes'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'keep_mine'),
              child: const Text('Keep mine'),
            ),
          ],
        );
      },
    );

    if (!mounted || action == null) return;

    if (action == 'review') {
      _populateFromModel(remoteCurrent);
      AppFeedback.showInfo(context, 'Loaded the latest values from Google Sheets.');
    } else if (action == 'keep_mine') {
      setState(() => _isSaving = true);
      final TransactionsController controller =
          ref.read(transactionsControllerProvider.notifier);
      final TransactionMutationResult result = await controller.edit(
        attempted,
        force: true,
      );
      if (!mounted) return;
      if (result is MutationSuccess) {
        await HapticFeedback.lightImpact();
        setState(() {
          _isSaving = false;
          _isSuccess = true;
        });
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (mounted) context.pop();
      } else {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to overwrite remote transaction.';
        });
      }
    }
  }

  String _formatUpdatedAt(String isoString) {
    try {
      final DateTime dt = DateTime.parse(isoString).toLocal();
      return '${formatDate(dt)} at ${formatTime24h(dt)}';
    } catch (_) {
      return isoString;
    }
  }

  IconData _categoryIcon(String name) {
    final String lower = name.toLowerCase();
    if (lower.contains('food') || lower.contains('dining') || lower.contains('restaurant')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('grocer')) return Icons.shopping_cart_rounded;
    if (lower.contains('transport') || lower.contains('cab') || lower.contains('fuel')) {
      return Icons.directions_car_rounded;
    }
    if (lower.contains('shop') || lower.contains('cloth')) return Icons.shopping_bag_rounded;
    if (lower.contains('bill') || lower.contains('utilit') || lower.contains('electric')) {
      return Icons.receipt_long_rounded;
    }
    if (lower.contains('entertain') || lower.contains('movie')) return Icons.movie_rounded;
    if (lower.contains('health') || lower.contains('medic')) return Icons.local_hospital_rounded;
    if (lower.contains('salary')) return Icons.account_balance_wallet_rounded;
    if (lower.contains('freelance')) return Icons.laptop_chromebook_rounded;
    if (lower.contains('invest')) return Icons.trending_up_rounded;
    return Icons.category_rounded;
  }
}
