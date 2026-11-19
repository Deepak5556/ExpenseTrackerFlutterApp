import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/utils/window_size_class.dart';
import '../../../core/widgets/design_system_widgets.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/responsive_builder.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/data/expense_data_provider.dart';
import '../../../models/expense_category.dart';
import '../../../models/expense_transaction.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ExpenseDataState data = ref.watch(expenseDataProvider);
    return ResponsiveBuilder(
      builder:
          (
            BuildContext context,
            BoxConstraints constraints,
            WindowSizeClass sizeClass,
          ) {
            final double padding = sizeClass.pagePadding;
            final DateTime now = DateTime.now();
            final List<ExpenseTransaction> monthItems = data.transactions
                .where(
                  (ExpenseTransaction item) =>
                      item.occurredAt.year == now.year &&
                      item.occurredAt.month == now.month,
                )
                .toList(growable: false);
            final int expenses = monthItems
                .where(
                  (ExpenseTransaction item) =>
                      item.type == TransactionType.expense,
                )
                .fold<int>(
                  0,
                  (int total, ExpenseTransaction item) =>
                      total + item.amountMinor,
                );
            final int income = monthItems
                .where(
                  (ExpenseTransaction item) =>
                      item.type == TransactionType.income,
                )
                .fold<int>(
                  0,
                  (int total, ExpenseTransaction item) =>
                      total + item.amountMinor,
                );
            final int salary = data.salaryMinor > 0 ? data.salaryMinor : income;
            final int remaining =
                salary +
                (income -
                    (data.salaryMinor > 0
                        ? _salaryIncome(monthItems)
                        : income)) -
                expenses;
            final List<ExpenseTransaction> recent = data.transactions.toList()
              ..sort(
                (ExpenseTransaction a, ExpenseTransaction b) =>
                    b.occurredAt.compareTo(a.occurredAt),
              );
            final Map<String, int> categoryTotals = _categoryTotals(monthItems);
            final int expenseCount = monthItems
                .where(
                  (ExpenseTransaction t) => t.type == TransactionType.expense,
                )
                .length;

            return RefreshIndicator(
              color: AppColors.brandStart,
              backgroundColor: AppColors.card,
              onRefresh: () async {
                if (data.isConnected) {
                  await ref.read(expenseDataProvider.notifier).refresh();
                }
              },
              child: SafeArea(
                top: false,
                bottom: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.contentMaxWidth,
                    ),
                    child: CustomScrollView(
                      key: const PageStorageKey<String>('home-scroll'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: <Widget>[
                        SliverToBoxAdapter(
                          child: GradientHeader(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0x28FFFFFF),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.tile,
                                        ),
                                        border: Border.all(
                                          color: const Color(0x38FFFFFF),
                                          width: 1.5,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: data.accountName != null &&
                                              data.accountName!.trim().isNotEmpty
                                          ? Text(
                                              data.accountName!
                                                  .trim()
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 18,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.account_balance_wallet_rounded,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                    ),
                                    const SizedBox(width: AppSpacing.x3),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            data.accountName ??
                                                'Expense Journal & Budget',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 3),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.x2,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0x24FFFFFF),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadius.pill,
                                                  ),
                                            ),
                                            child: Text(
                                              formatMonthLabel(now),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                    letterSpacing: 0,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.x2),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0x1FFFFFFF),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.tile,
                                        ),
                                      ),
                                      child: IconButton(
                                        tooltip: 'Notifications',
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () =>
                                            context.push('/notifications'),
                                        icon: const Icon(
                                          Icons.notifications_none_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.x5),
                                Text(
                                  'MONTHLY BALANCE',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppColors.onGradientSecondary,
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.x1),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: AmountText(
                                    minorUnits: remaining,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                    animate: data.isConnected,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.x1),
                                Text(
                                  data.isConnected
                                      ? 'After this month’s expenses'
                                      : 'Connect your sheet to load your balance',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.onGradientSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              padding,
                              AppSpacing.x2,
                              padding,
                              0,
                            ),
                            child: Transform.translate(
                              offset: const Offset(0, -26),
                              child: FloatingActionCard(
                                actions: <QuickAction>[
                                  QuickAction(
                                    label: 'Expense',
                                    icon: Icons.add_rounded,
                                    onPressed: () =>
                                        context.go('/add?type=expense'),
                                  ),
                                  QuickAction(
                                    label: 'Income',
                                    icon: Icons.south_west_rounded,
                                    color: AppColors.income,
                                    onPressed: () =>
                                        context.go('/add?type=income'),
                                  ),
                                  QuickAction(
                                    label: 'Journal',
                                    icon: Icons.receipt_long_outlined,
                                    color: AppColors.amber,
                                    onPressed: () => context.go('/journal'),
                                  ),
                                  QuickAction(
                                    label: 'More',
                                    icon: Icons.more_horiz_rounded,
                                    color: AppColors.labels,
                                    onPressed: () => _showMore(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (data.error != null)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                padding,
                                0,
                                padding,
                                AppSpacing.x3,
                              ),
                              child: OfflineBanner(
                                message: data.error!,
                                onRetry: () => ref
                                    .read(expenseDataProvider.notifier)
                                    .refresh(),
                              ),
                            ),
                          ),
                        if (data.loading &&
                            data.transactions.isEmpty &&
                            data.isConnected)
                          const SliverToBoxAdapter(child: DashboardSkeleton())
                        else ...<Widget>[
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              padding,
                              0,
                              padding,
                              AppSpacing.x4,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: ResponsiveGrid(
                                compactColumns: 2,
                                mediumColumns: 2,
                                expandedColumns: 4,
                                spacing: AppSpacing.x2,
                                children: <Widget>[
                                  KpiCard(
                                    label: 'Monthly salary',
                                    value: formatMoney(salary),
                                    detail: data.isConnected
                                        ? 'Configured in Settings'
                                        : 'Connect sheet to configure',
                                    icon: Icons.account_balance_outlined,
                                  ),
                                  KpiCard(
                                    label: 'Expenses',
                                    value: formatMoney(expenses),
                                    detail: '$expenseCount transactions',
                                    icon: Icons.trending_down_rounded,
                                    valueColor: AppColors.brandStart,
                                  ),
                                  KpiCard(
                                    label: 'Income',
                                    value: formatMoney(income),
                                    detail: 'This month',
                                    icon: Icons.trending_up_rounded,
                                    valueColor: AppColors.income,
                                  ),
                                  KpiCard(
                                    label: 'Savings rate',
                                    value:
                                        '${salary <= 0 ? 0 : ((remaining / salary) * 100).clamp(0, 100).round()}%',
                                    detail: 'Based on monthly balance',
                                    icon: Icons.savings_outlined,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (!data.isConnected)
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              padding,
                              0,
                              padding,
                              AppSpacing.x4,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: SurfaceCard(
                                child: Column(
                                  children: <Widget>[
                                    const EmptyState(
                                      icon: Icons.cloud_off_outlined,
                                      title: 'Connect your Google Sheet',
                                      message:
                                          'Your balance, summaries, charts and recent transactions will appear here after your spreadsheet is connected.',
                                    ),
                                    const SizedBox(height: AppSpacing.x3),
                                    FilledButton.icon(
                                      onPressed: () =>
                                          context.push('/connect-spreadsheet'),
                                      icon: const Icon(Icons.link_rounded),
                                      label: const Text('Connect spreadsheet'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (data.isConnected) ...<Widget>[
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              padding,
                              0,
                              padding,
                              AppSpacing.x4,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: _MonthlyTrajectory(
                                items: data.transactions,
                                now: now,
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              padding,
                              0,
                              padding,
                              AppSpacing.x4,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: _CategorySummary(
                                categories: data.categories,
                                totals: categoryTotals,
                                total: expenses,
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              padding,
                              0,
                              padding,
                              AppSpacing.x4,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: SurfaceCard(
                                child: Column(
                                  children: <Widget>[
                                    SectionHeader(
                                      title: 'Recent transactions',
                                      subtitle: 'Latest entries in your sheet',
                                      actionLabel: 'View all',
                                      onAction: () => context.go('/journal'),
                                    ),
                                    const SizedBox(height: AppSpacing.x2),
                                    if (recent.isEmpty)
                                      const EmptyState(
                                        icon: Icons.receipt_long_outlined,
                                        title: 'No transactions yet',
                                        message:
                                            'Add your first expense or income to get started.',
                                      )
                                    else
                                      for (final ExpenseTransaction item
                                          in recent.take(5))
                                        _TransactionTile(
                                          item: item,
                                          onTap: () => context.push(
                                            '/transaction/${item.id}',
                                          ),
                                        ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
    );
  }

  static int _salaryIncome(List<ExpenseTransaction> items) => items
      .where(
        (ExpenseTransaction item) =>
            item.type == TransactionType.income && item.categoryId == 'salary',
      )
      .fold<int>(
        0,
        (int total, ExpenseTransaction item) => total + item.amountMinor,
      );

  static Map<String, int> _categoryTotals(List<ExpenseTransaction> items) {
    final Map<String, int> totals = <String, int>{};
    for (final ExpenseTransaction item in items.where(
      (ExpenseTransaction t) => t.type == TransactionType.expense,
    )) {
      totals.update(
        item.categoryId,
        (int old) => old + item.amountMinor,
        ifAbsent: () => item.amountMinor,
      );
    }
    return totals;
  }

  void _showMore(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Categories'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/categories');
              },
            ),
            ListTile(
              leading: const Icon(Icons.savings_outlined),
              title: const Text('Budgets'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/budgets');
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: const Text('Spreadsheet connection'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/connect-spreadsheet');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyTrajectory extends StatelessWidget {
  const _MonthlyTrajectory({required this.items, required this.now});

  final List<ExpenseTransaction> items;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final List<DateTime> months = List<DateTime>.generate(
      6,
      (int index) => DateTime(now.year, now.month - 5 + index),
    );
    final List<int> values = months
        .map(
          (DateTime month) => items
              .where(
                (ExpenseTransaction item) =>
                    item.type == TransactionType.expense &&
                    item.occurredAt.year == month.year &&
                    item.occurredAt.month == month.month,
              )
              .fold<int>(
                0,
                (int total, ExpenseTransaction item) =>
                    total + item.amountMinor,
              ),
        )
        .toList();
    final int maxValue = values.fold<int>(
      0,
      (int max, int value) => value > max ? value : max,
    );
    final compact = context.windowSizeClass.isCompact;
    return RepaintBoundary(
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionHeader(
              title: 'Monthly expense trajectory',
              subtitle: 'Compare your spending over the last six months',
              leading: Icon(Icons.bar_chart_rounded, color: AppColors.brandStart),
            ),
            const SizedBox(height: AppSpacing.x4),
            SizedBox(
              height: context.responsiveValue(
                compact: 190,
                medium: 218,
                expanded: 238,
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue == 0 ? 100 : (maxValue / 100) * 1.25,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final int index = value.toInt();
                          if (index < 0 || index >= months.length) {
                            return const SizedBox.shrink();
                          }
                          final bool isCurrent = index == months.length - 1;
                          return SideTitleWidget(
                            meta: meta,
                            space: 6,
                            child: Text(
                              DateFormat('MMM').format(months[index]),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: isCurrent ? AppColors.brandStart : AppColors.textSecondary,
                                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: <BarChartGroupData>[
                    for (int i = 0; i < values.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: <BarChartRodData>[
                          BarChartRodData(
                            toY: values[i] <= 0 ? 1.0 : values[i] / 100,
                            width: compact ? 22 : 26,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: i == values.length - 1
                                  ? <Color>[
                                      AppColors.brandStart,
                                      AppColors.accentOrange,
                                    ]
                                  : <Color>[
                                      AppColors.border,
                                      AppColors.border,
                                    ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x3),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x3,
                vertical: AppSpacing.x2,
              ),
              decoration: BoxDecoration(
                color: AppColors.pageBackground,
                borderRadius: BorderRadius.circular(AppRadius.tile),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.brandStart,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  Text(
                    'This month',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatMoney(values.isEmpty ? 0 : values.last),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySummary extends StatelessWidget {
  const _CategorySummary({
    required this.categories,
    required this.totals,
    required this.total,
  });

  final List<ExpenseCategory> categories;
  final Map<String, int> totals;
  final int total;

  @override
  Widget build(BuildContext context) {
    final List<ExpenseCategory> used =
        categories
            .where(
              (ExpenseCategory category) =>
                  category.type == 'expense' && (totals[category.id] ?? 0) > 0,
            )
            .toList()
          ..sort(
            (ExpenseCategory a, ExpenseCategory b) =>
                (totals[b.id] ?? 0).compareTo(totals[a.id] ?? 0),
          );
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: 'Category spend',
            subtitle: 'Total ${formatMoney(total)} this month',
            leading: const Icon(
              Icons.donut_large_rounded,
              color: AppColors.accentOrange,
            ),
            actionLabel: 'View',
            onAction: () => context.push('/categories'),
          ),
          const SizedBox(height: AppSpacing.x3),
          if (used.isEmpty)
            const Text(
              'No expense categories have spending this month.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            for (final ExpenseCategory category in used.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.x3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: AppColors.accentOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.x2),
                        Expanded(
                          child: Text(
                            category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          formatMoney(totals[category.id] ?? 0),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.x2),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 42),
                          child: Text(
                            '${total == 0 ? 0 : ((totals[category.id] ?? 0) * 100 / total).round()}%',
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total == 0
                            ? 0.0
                            : ((totals[category.id] ?? 0) / total).clamp(
                                0.0,
                                1.0,
                              ),
                        minHeight: 4,
                        backgroundColor: AppColors.divider,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accentOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.item, required this.onTap});
  final ExpenseTransaction item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isIncome = item.type == TransactionType.income;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.tile),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.x2,
          horizontal: AppSpacing.x1,
        ),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 20,
              backgroundColor: isIncome
                  ? AppColors.incomeSurface
                  : AppColors.orangePillSurface,
              child: Icon(
                isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: isIncome ? AppColors.income : AppColors.brandStart,
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
                    '${item.categoryName} · ${formatDate(item.occurredAt)}',
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
                maxWidth: context.responsiveValue(compact: 110, medium: 144),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '${isIncome ? '+' : '−'}${formatMoney(item.amountMinor)}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isIncome ? AppColors.income : AppColors.brandStart,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
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
