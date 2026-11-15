import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/design_system_widgets.dart';
import '../core/widgets/responsive_builder.dart';
import '../core/utils/window_size_class.dart';
import '../features/data/expense_data_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(expenseDataProvider.notifier).initialize(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StatefulNavigationShell navigationShell = widget.navigationShell;
    ref.watch(expenseDataProvider);
    return ResponsiveBuilder(
      builder:
          (
            BuildContext context,
            BoxConstraints constraints,
            WindowSizeClass sizeClass,
          ) {
            if (sizeClass.isExpanded) {
              final int? railIndex = switch (navigationShell.currentIndex) {
                0 => 0,
                1 => 1,
                2 => null,
                3 => 2,
                4 => 3,
                _ => 0,
              };
              return Scaffold(
                backgroundColor: AppColors.pageBackground,
                body: Row(
                  children: <Widget>[
                    SafeArea(
                      child: NavigationRail(
                        selectedIndex: railIndex,
                        labelType: NavigationRailLabelType.all,
                        onDestinationSelected: (int index) => navigationShell
                            .goBranch(index < 2 ? index : index + 1),
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
                          padding: const EdgeInsets.only(top: 12),
                          child: FloatingActionButton.small(
                            key: const ValueKey<String>('rail-add'),
                            onPressed: () => navigationShell.goBranch(2),
                            tooltip: 'Add transaction',
                            child: const Icon(Icons.add_rounded),
                          ),
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: navigationShell),
                  ],
                ),
              );
            }

            return Scaffold(
              backgroundColor: AppColors.pageBackground,
              body: navigationShell,
              bottomNavigationBar: AppBottomNav(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: navigationShell.goBranch,
                onAdd: () => navigationShell.goBranch(2),
              ),
            );
          },
    );
  }
}
