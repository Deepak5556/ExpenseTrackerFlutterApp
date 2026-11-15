import 'package:material_ui/material_ui.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_design_tokens.dart';
import '../core/utils/money_formatter.dart';
import '../core/utils/window_size_class.dart';
import '../core/widgets/design_system_widgets.dart';
import '../core/widgets/responsive_builder.dart';

/// Temporary visual QA screen for the design foundation. Delete in Phase 6.
class DesignPreviewScreen extends StatefulWidget {
  const DesignPreviewScreen({super.key});

  @override
  State<DesignPreviewScreen> createState() => _DesignPreviewScreenState();
}

class _DesignPreviewScreenState extends State<DesignPreviewScreen> {
  int _selectedDestination = 0;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder:
          (
            BuildContext context,
            BoxConstraints constraints,
            WindowSizeClass sizeClass,
          ) {
            final Widget content = _buildContent(context, sizeClass);
            return Scaffold(
              backgroundColor: AppColors.pageBackground,
              bottomNavigationBar: sizeClass.isExpanded
                  ? null
                  : AppBottomNav(
                      selectedIndex: _selectedDestination,
                      onDestinationSelected: (int index) =>
                          setState(() => _selectedDestination = index),
                      onAdd: _showAddMessage,
                    ),
              body: sizeClass.isExpanded
                  ? Row(
                      children: <Widget>[
                        SafeArea(
                          child: NavigationRail(
                            selectedIndex: _selectedDestination,
                            labelType: NavigationRailLabelType.all,
                            onDestinationSelected: (int index) =>
                                setState(() => _selectedDestination = index),
                            destinations: const <NavigationRailDestination>[
                              NavigationRailDestination(
                                icon: Icon(Icons.home_outlined),
                                selectedIcon: Icon(Icons.home_rounded),
                                label: Text('Home'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.receipt_long_outlined),
                                selectedIcon: Icon(Icons.receipt_long_rounded),
                                label: Text('Journal'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.insights_outlined),
                                selectedIcon: Icon(Icons.insights_rounded),
                                label: Text('Analytics'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.settings_outlined),
                                selectedIcon: Icon(Icons.settings_rounded),
                                label: Text('Settings'),
                              ),
                            ],
                            trailing: Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.x3,
                              ),
                              child: FloatingActionButton.small(
                                onPressed: _showAddMessage,
                                tooltip: 'Add expense',
                                child: const Icon(Icons.add_rounded),
                              ),
                            ),
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: content),
                      ],
                    )
                  : content,
            );
          },
    );
  }

  Widget _buildContent(BuildContext context, WindowSizeClass sizeClass) {
    final double pagePadding = sizeClass.pagePadding;
    return SafeArea(
      top: false,
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.contentMaxWidth,
          ),
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: GradientHeader(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const CircleAvatar(
                            backgroundColor: Color(0x33FFFFFF),
                            foregroundColor: Colors.white,
                            child: Icon(Icons.person_outline_rounded),
                          ),
                          const SizedBox(width: AppSpacing.x2),
                          Expanded(
                            child: Text(
                              'Expense Journal & Budget',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                          const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x4),
                      Text(
                        'NOVEMBER 2026  •  INR',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.onGradientSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      AmountText(
                        minorUnits: 1655400,
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              color: Colors.white,
                              fontSize: AppTypography.heroAmount,
                              letterSpacing: -1.5,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      Text(
                        'Remaining balance',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.onGradientSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    pagePadding,
                    AppSpacing.x3,
                    pagePadding,
                    0,
                  ),
                  child: Transform.translate(
                    offset: const Offset(0, -38),
                    child: FloatingActionCard(
                      actions: <QuickAction>[
                        QuickAction(
                          label: 'Expense',
                          icon: Icons.add_rounded,
                          onPressed: _showAddMessage,
                        ),
                        QuickAction(
                          label: 'Income',
                          icon: Icons.south_west_rounded,
                          color: AppColors.income,
                          onPressed: _showAddMessage,
                        ),
                        QuickAction(
                          label: 'Journal',
                          icon: Icons.receipt_long_outlined,
                          color: AppColors.amber,
                          onPressed: () {},
                        ),
                        QuickAction(
                          label: 'More',
                          icon: Icons.more_horiz_rounded,
                          color: AppColors.labels,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  pagePadding,
                  AppSpacing.x2,
                  pagePadding,
                  AppSpacing.x6,
                ),
                sliver: SliverGrid(
                  delegate: SliverChildListDelegate(<Widget>[
                    KpiCard(
                      label: 'Monthly salary',
                      value: formatMoney(1700000),
                      detail: 'Monthly base income',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    KpiCard(
                      label: 'Now expenses',
                      value: formatMoney(44600),
                      detail: '2.6% of monthly salary',
                      icon: Icons.trending_down_rounded,
                    ),
                    KpiCard(
                      label: 'Remaining balance',
                      value: formatMoney(1655400),
                      detail: 'Surplus for November',
                      icon: Icons.savings_outlined,
                      emphasized: true,
                    ),
                    const KpiCard(
                      label: 'Savings rate',
                      value: '97.38%',
                      detail: 'All-time savings',
                      icon: Icons.show_chart_rounded,
                      valueColor: AppColors.income,
                    ),
                  ]),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: sizeClass.dashboardColumns,
                    crossAxisSpacing: AppSpacing.x3,
                    mainAxisSpacing: AppSpacing.x3,
                    childAspectRatio: switch (sizeClass) {
                      WindowSizeClass.compact => 1.0,
                      WindowSizeClass.medium => 1.3,
                      WindowSizeClass.expanded => 1.4,
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  pagePadding,
                  0,
                  pagePadding,
                  AppSpacing.x3,
                ),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: SectionHeader(
                          title: 'November overview',
                          subtitle: 'Sample figures for the design preview',
                          leading: const Icon(
                            Icons.calendar_month_rounded,
                            color: AppColors.brandStart,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x2),
                      const PillBadge(label: 'Active month'),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  pagePadding,
                  0,
                  pagePadding,
                  AppSpacing.x4,
                ),
                sliver: SliverToBoxAdapter(
                  child: SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SectionHeader(
                          title: 'Monthly expense trajectory',
                          subtitle: 'Skeleton state while the sheet is loading',
                          leading: Icon(
                            Icons.bar_chart_rounded,
                            color: AppColors.accentOrange,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x4),
                        Row(
                          children: <Widget>[
                            const ShimmerBox(
                              width: 42,
                              height: 42,
                              borderRadius: 14,
                            ),
                            const SizedBox(width: AppSpacing.x3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const <Widget>[
                                  ShimmerBox(width: 148, height: 14),
                                  SizedBox(height: AppSpacing.x2),
                                  ShimmerBox(width: 96, height: 12),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.x3),
                            const ShimmerBox(
                              width: 64,
                              height: 28,
                              borderRadius: 999,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  pagePadding,
                  0,
                  pagePadding,
                  AppSpacing.x8,
                ),
                sliver: SliverToBoxAdapter(
                  child: SurfaceCard(
                    child: const EmptyState(
                      icon: Icons.cloud_done_outlined,
                      title: 'Design preview only',
                      message: 'Google Sheets sync and journal entries arrive in later phases.',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sample screen: expense entry comes in a later phase.'),
      ),
    );
  }
}
