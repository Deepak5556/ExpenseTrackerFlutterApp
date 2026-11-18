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
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/data/expense_data_provider.dart';
import '../../../models/expense_category.dart';
import '../../../models/expense_transaction.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _months = 6;

  @override
  Widget build(BuildContext context) {
    final ExpenseDataState data = ref.watch(expenseDataProvider);
    final DateTime now = DateTime.now();
    final DateTime firstMonth = DateTime(now.year, now.month - _months + 1);
    final List<ExpenseTransaction> periodItems = data.transactions
        .where(
          (ExpenseTransaction item) =>
              !item.occurredAt.isBefore(firstMonth) &&
              !item.occurredAt.isAfter(now.add(const Duration(days: 1))),
        )
        .toList(growable: false);
    final int expenses = periodItems
        .where(
          (ExpenseTransaction item) => item.type == TransactionType.expense,
        )
        .fold<int>(
          0,
          (int sum, ExpenseTransaction item) => sum + item.amountMinor,
        );
    final int income = periodItems
        .where((ExpenseTransaction item) => item.type == TransactionType.income)
        .fold<int>(
          0,
          (int sum, ExpenseTransaction item) => sum + item.amountMinor,
        );
    final Map<String, int> categoryTotals = <String, int>{};
    for (final ExpenseTransaction item in periodItems.where(
      (ExpenseTransaction item) => item.type == TransactionType.expense,
    )) {
      categoryTotals.update(
        item.categoryId,
        (int value) => value + item.amountMinor,
        ifAbsent: () => item.amountMinor,
      );
    }
    final List<ExpenseCategory> usedCategories =
        data.categories
            .where(
              (ExpenseCategory item) =>
                  item.type == 'expense' && (categoryTotals[item.id] ?? 0) > 0,
            )
            .toList()
          ..sort(
            (ExpenseCategory a, ExpenseCategory b) =>
                (categoryTotals[b.id] ?? 0).compareTo(
                  categoryTotals[a.id] ?? 0,
                ),
          );
    final int count = periodItems
        .where(
          (ExpenseTransaction item) => item.type == TransactionType.expense,
        )
        .length;

    final bool isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Sync with Google Sheets',
            onPressed: data.loading
                ? null
                : () => ref.read(expenseDataProvider.notifier).refresh(),
            icon: const Icon(Icons.sync_rounded),
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
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
          if (data.error != null)
            OfflineBanner(
              message: data.error!,
              onRetry: () => ref.read(expenseDataProvider.notifier).refresh(),
            ),
          if (!data.isConnected)
            SurfaceCard(
              child: EmptyState(
                icon: Icons.insights_rounded,
                title: 'Connect your spreadsheet to see analytics',
                message:
                    'Income, expenses, savings, category insights and trend charts are calculated from your Google Sheet.',
                actionLabel: 'Connect spreadsheet',
                onAction: () => context.push('/connect-spreadsheet'),
              ),
            )
          else if (data.loading && data.transactions.isEmpty)
            const DashboardSkeleton()
          else ...<Widget>[
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SectionHeader(
                    title: 'Your money, clearly',
                    subtitle: 'Income, expenses, savings and category insights from your sheet.',
                    leading: Icon(
                      Icons.insights_rounded,
                      color: AppColors.accentOrange,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  SegmentedButton<int>(
                    segments: const <ButtonSegment<int>>[
                      ButtonSegment<int>(value: 6, label: Text('6 months')),
                      ButtonSegment<int>(value: 12, label: Text('12 months')),
                    ],
                    selected: <int>{_months},
                    onSelectionChanged: (Set<int> value) =>
                        setState(() => _months = value.single),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x3),
            ResponsiveGrid(
              children: <Widget>[
                KpiCard(
                  label: 'Total expenses',
                  value: formatMoney(expenses),
                  detail: '$_months month period',
                  icon: Icons.trending_down_rounded,
                  valueColor: AppColors.brandStart,
                ),
                KpiCard(
                  label: 'Total income',
                  value: formatMoney(income),
                  detail: '$_months month period',
                  icon: Icons.trending_up_rounded,
                  valueColor: AppColors.income,
                ),
                KpiCard(
                  label: 'Savings',
                  value: formatMoney(income - expenses),
                  detail: 'Income minus recorded expenses',
                  icon: Icons.savings_outlined,
                ),
                KpiCard(
                  label: 'Average expense',
                  value: formatMoney(count == 0 ? 0 : expenses ~/ count),
                  detail: '$count expense entries',
                  icon: Icons.calculate_outlined,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x3),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SectionHeader(
                    title: 'Income and expenses',
                    subtitle: 'Monthly totals over the selected period',
                    leading: Icon(
                      Icons.bar_chart_rounded,
                      color: AppColors.brandStart,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  SizedBox(
                    height: isLandscape
                        ? 160
                        : context.responsiveValue(
                            compact: 205,
                            medium: 230,
                            expanded: 260,
                          ),
                    child: _IncomeExpenseChart(
                      items: data.transactions,
                      months: _months,
                      now: now,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _Legend(color: AppColors.brandStart, label: 'Expenses'),
                      SizedBox(width: AppSpacing.x4),
                      _Legend(color: AppColors.income, label: 'Income'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x3),
            SurfaceCard(
              child: Column(
                children: <Widget>[
                  SectionHeader(
                    title: 'Category breakdown',
                    subtitle:
                        '${usedCategories.length} categories · ${formatMonthLabel(now)}',
                    leading: const Icon(
                      Icons.donut_large_rounded,
                      color: AppColors.accentOrange,
                    ),
                    actionLabel: 'Manage',
                    onAction: () => context.push('/categories'),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  if (usedCategories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.x4),
                      child: Text(
                        'No expense categories have activity in this period.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else ...<Widget>[
                    SizedBox(
                      height: isLandscape
                          ? 150
                          : context.responsiveValue(
                              compact: 175,
                              medium: 195,
                              expanded: 220,
                            ),
                      child: PieChart(
                        PieChartData(
                          centerSpaceRadius: 42,
                          sectionsSpace: 3,
                          sections: <PieChartSectionData>[
                            for (int i = 0; i < usedCategories.length; i++)
                              PieChartSectionData(
                                value:
                                    (categoryTotals[usedCategories[i].id] ?? 0)
                                        .toDouble(),
                                color:
                                    AppColors.chartPalette[i %
                                        AppColors.chartPalette.length],
                                radius: 48,
                                title: '',
                              ),
                          ],
                        ),
                      ),
                    ),
                    for (int i = 0; i < usedCategories.length; i++)
                      _CategoryAnalyticsRow(
                        category: usedCategories[i],
                        amount: categoryTotals[usedCategories[i].id] ?? 0,
                        total: expenses,
                        color: AppColors
                            .chartPalette[i % AppColors.chartPalette.length],
                        budget:
                            data.budgets['${formatMonthKey(now)}|${usedCategories[i].id}'] ??
                            usedCategories[i].monthlyBudgetMinor,
                      ),
                  ],
                ],
              ),
            ),
          ],
          if (data.error != null) ...<Widget>[
            const SizedBox(height: AppSpacing.x3),
            Text(
              data.error!,
              style: const TextStyle(color: AppColors.brandStart),
            ),
          ],
        ],
      ),
    ),
  );
}
}

class _IncomeExpenseChart extends StatelessWidget {
  const _IncomeExpenseChart({
    required this.items,
    required this.months,
    required this.now,
  });
  final List<ExpenseTransaction> items;
  final int months;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final List<DateTime> timeline = List<DateTime>.generate(
      months,
      (int index) => DateTime(now.year, now.month - months + 1 + index),
    );
    final List<int> expenseValues = <int>[];
    final List<int> incomeValues = <int>[];
    for (final DateTime month in timeline) {
      int sum(TransactionType type) => items
          .where(
            (ExpenseTransaction item) =>
                item.type == type &&
                item.occurredAt.year == month.year &&
                item.occurredAt.month == month.month,
          )
          .fold<int>(
            0,
            (int value, ExpenseTransaction item) => value + item.amountMinor,
          );
      expenseValues.add(sum(TransactionType.expense));
      incomeValues.add(sum(TransactionType.income));
    }
    final int maxValue = <int>[
      ...expenseValues,
      ...incomeValues,
    ].fold<int>(0, (int max, int value) => value > max ? value : max);
    return BarChart(
      BarChartData(
        maxY: maxValue == 0 ? 100 : maxValue / 100 * 1.2,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: true),
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
                if (index < 0 || index >= timeline.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    DateFormat('MMM').format(timeline[index]),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: <BarChartGroupData>[
          for (int i = 0; i < timeline.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: <BarChartRodData>[
                BarChartRodData(
                  toY: expenseValues[i] / 100,
                  color: AppColors.brandStart,
                  width: months > 6 ? 7 : 12,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                BarChartRodData(
                  toY: incomeValues[i] / 100,
                  color: AppColors.income,
                  width: months > 6 ? 7 : 12,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CategoryAnalyticsRow extends StatelessWidget {
  const _CategoryAnalyticsRow({
    required this.category,
    required this.amount,
    required this.total,
    required this.color,
    required this.budget,
  });
  final ExpenseCategory category;
  final int amount;
  final int total;
  final Color color;
  final int budget;

  @override
  Widget build(BuildContext context) {
    final int percent = total == 0 ? 0 : (amount * 100 / total).round();
    final bool overBudget = budget > 0 && amount > budget;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
      child: Row(
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  category.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : amount / total,
                    minHeight: 5,
                    color: color,
                    backgroundColor: AppColors.border,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                formatMoney(amount),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                budget > 0
                    ? '$percent% · ${formatMoney(budget)} budget'
                    : '$percent%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: overBudget
                      ? AppColors.brandStart
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: AppSpacing.x1),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}
