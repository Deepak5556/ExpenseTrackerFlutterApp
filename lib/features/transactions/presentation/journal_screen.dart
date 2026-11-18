import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/utils/window_size_class.dart';
import '../../../core/widgets/design_system_widgets.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/data/expense_data_provider.dart';
import '../../../models/expense_category.dart';
import '../../../models/expense_transaction.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _type = 'all';
  String? _categoryId;
  DateTime? _month = DateTime(DateTime.now().year, DateTime.now().month);
  String _sort = 'newest';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ExpenseDataState data = ref.watch(expenseDataProvider);
    final List<ExpenseTransaction> items =
        data.transactions.where((ExpenseTransaction item) {
          final String query = _query.toLowerCase().trim();
          final bool matchesSearch =
              query.isEmpty ||
              <String>[
                item.title,
                item.categoryName,
                item.notes,
                item.paymentMethod,
                formatMoney(item.amountMinor),
              ].any((String value) => value.toLowerCase().contains(query));
          final bool matchesType = _type == 'all' || item.type.name == _type;
          final bool matchesCategory =
              _categoryId == null || item.categoryId == _categoryId;
          final bool matchesMonth =
              _month == null ||
              (item.occurredAt.year == _month!.year &&
                  item.occurredAt.month == _month!.month);
          return matchesSearch &&
              matchesType &&
              matchesCategory &&
              matchesMonth;
        }).toList()..sort((ExpenseTransaction a, ExpenseTransaction b) {
          switch (_sort) {
            case 'oldest':
              return a.occurredAt.compareTo(b.occurredAt);
            case 'amount_high':
              return b.amountMinor.compareTo(a.amountMinor);
            case 'amount_low':
              return a.amountMinor.compareTo(b.amountMinor);
            default:
              return b.occurredAt.compareTo(a.occurredAt);
          }
        });
    final int total = items.fold<int>(
      0,
      (int sum, ExpenseTransaction item) => sum + item.amountMinor,
    );

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('Expense Journal'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Sync with Google Sheets',
            onPressed: data.loading
                ? null
                : () => ref.read(expenseDataProvider.notifier).refresh(),
            icon: const Icon(Icons.sync_rounded),
          ),
          IconButton(
            tooltip: 'Add transaction',
            onPressed: () => context.go('/add'),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.brandStart,
        backgroundColor: AppColors.card,
        onRefresh: () async {
          if (data.isConnected) {
            await ref.read(expenseDataProvider.notifier).refresh();
          }
        },
        child: ResponsiveListView(
          key: const PageStorageKey<String>('journal-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            SearchBar(
              key: const ValueKey<String>('journal-search'),
              controller: _searchController,
              onChanged: (String value) => setState(() => _query = value),
              hintText: 'Search title, category, notes or amount',
              leading: const Icon(Icons.search_rounded),
              trailing: <Widget>[
                if (_query.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                PopupMenuButton<String>(
                  tooltip: 'Sort transactions',
                  initialValue: _sort,
                  onSelected: (String value) => setState(() => _sort = value),
                  itemBuilder: (BuildContext context) =>
                      const <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'newest',
                          child: Text('Newest first'),
                        ),
                        PopupMenuItem<String>(
                          value: 'oldest',
                          child: Text('Oldest first'),
                        ),
                        PopupMenuItem<String>(
                          value: 'amount_high',
                          child: Text('Amount: high to low'),
                        ),
                        PopupMenuItem<String>(
                          value: 'amount_low',
                          child: Text('Amount: low to high'),
                        ),
                      ],
                  icon: const Icon(Icons.sort_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x3),
            Wrap(
              spacing: AppSpacing.x2,
              runSpacing: AppSpacing.x2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                ActionChip(
                  avatar: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: Text(
                    _month == null ? 'All dates' : formatMonthLabel(_month!),
                  ),
                  onPressed: _chooseMonth,
                ),
                FilterChip(
                  label: const Text('All'),
                  selected: _type == 'all',
                  onSelected: (_) => setState(() => _type = 'all'),
                ),
                FilterChip(
                  label: const Text('Expenses'),
                  selected: _type == 'expense',
                  onSelected: (_) => setState(
                    () => _type = _type == 'expense' ? 'all' : 'expense',
                  ),
                ),
                FilterChip(
                  label: const Text('Income'),
                  selected: _type == 'income',
                  onSelected: (_) => setState(
                    () => _type = _type == 'income' ? 'all' : 'income',
                  ),
                ),
                if (data.categories.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x3,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mutedSurface,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _categoryId,
                        hint: const Text('Category'),
                        isDense: true,
                        icon: const Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 20,
                        ),
                        items: <DropdownMenuItem<String?>>[
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All categories'),
                          ),
                          for (final ExpenseCategory category in data.categories)
                            DropdownMenuItem<String?>(
                              value: category.id,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 160,
                                ),
                                child: Text(
                                  category.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                        ],
                        onChanged: (String? value) =>
                            setState(() => _categoryId = value),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.x3),
            if (data.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                child: OfflineBanner(
                  message: data.error!,
                  onRetry: () =>
                      ref.read(expenseDataProvider.notifier).refresh(),
                ),
              ),
            if (data.isConnected)
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${items.length} transactions',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Showing ${formatMoney(total)}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.x2),
            if (!data.isConnected)
              SurfaceCard(
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Connect your Google Sheet',
                  message:
                      'Your transactions will load from the spreadsheet. Search, filters and sorting work on the live sheet data.',
                  actionLabel: 'Connect spreadsheet',
                  onAction: () => context.push('/connect-spreadsheet'),
                ),
              )
            else if (data.loading && data.transactions.isEmpty)
              const TransactionListSkeleton()
            else if (items.isEmpty)
              SurfaceCard(
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  title: data.transactions.isEmpty
                      ? 'Your journal is ready'
                      : 'No matching transactions',
                  message: data.transactions.isEmpty
                      ? 'Add your first expense or income.'
                      : 'Try changing the date, category or search filters.',
                  actionLabel: data.transactions.isEmpty
                      ? 'Add transaction'
                      : 'Clear filters',
                  onAction: data.transactions.isEmpty
                      ? () => context.go('/add')
                      : () => setState(() {
                          _searchController.clear();
                          _query = '';
                          _type = 'all';
                          _categoryId = null;
                          _month = null;
                        }),
                ),
              )
            else
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    for (
                      int index = 0;
                      index < items.length;
                      index++
                    ) ...<Widget>[
                      if (index > 0)
                        const Divider(
                          height: 1,
                          indent: AppSpacing.x4,
                          endIndent: AppSpacing.x4,
                        ),
                      _JournalRow(item: items[index]),
                    ],
                  ],
                ),
              ),
            if (data.error != null) ...<Widget>[
              const SizedBox(height: AppSpacing.x3),
              Text(
                data.error!,
                style: const TextStyle(color: AppColors.brandStart),
              ),
            ],
            const SizedBox(height: AppSpacing.x8),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseMonth() async {
    final DateTime now = DateTime.now();
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _month ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 2),
      helpText: 'Choose a month',
    );
    if (selected != null && mounted) {
      setState(() => _month = DateTime(selected.year, selected.month));
    }
  }
}

class _JournalRow extends ConsumerWidget {
  const _JournalRow({required this.item});
  final ExpenseTransaction item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool income = item.type == TransactionType.income;
    return InkWell(
      onTap: () => context.push('/transaction/${item.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x3,
        ),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 20,
              backgroundColor: income
                  ? AppColors.incomeSurface
                  : AppColors.orangePillSurface,
              child: Icon(
                income ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: income ? AppColors.income : AppColors.brandStart,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.categoryName} · ${formatDate(item.occurredAt)}${item.paymentMethod.isEmpty ? '' : ' · ${item.paymentMethod}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: context.responsiveValue(compact: 110, medium: 150),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '${income ? '+' : '−'}${formatMoney(item.amountMinor)}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: income ? AppColors.income : AppColors.brandStart,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
