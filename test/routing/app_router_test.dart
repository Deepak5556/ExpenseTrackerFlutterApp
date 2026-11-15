import 'package:expense_journal_budget/routing/app_router.dart';
import 'package:expense_journal_budget/features/analytics/presentation/analytics_screen.dart';
import 'package:expense_journal_budget/features/settings/presentation/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en_IN');
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });
  testWidgets('five destinations open their own pages and keep tab state', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    final router = createAppRouter();
    addTearDown(router.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    expect(find.text('MONTHLY BALANCE'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('bottom-nav-1')));
    await tester.pumpAndSettle();
    expect(find.text('Expense Journal'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).first, 'groceries');
    await tester.tap(find.byKey(const ValueKey<String>('bottom-nav-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('bottom-nav-1')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .controller
          .text,
      'groceries',
    );

    await tester.tap(find.byKey(const ValueKey<String>('bottom-nav-add')));
    await tester.pumpAndSettle();
    expect(find.text('Add transaction'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('bottom-nav-3')));
    await tester.pumpAndSettle();
    expect(find.byType(AnalyticsScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('bottom-nav-4')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('transaction detail and edit routes keep the transaction ID', (
    WidgetTester tester,
  ) async {
    final router = createAppRouter(initialLocation: '/transaction/tx-123/edit');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit transaction'), findsOneWidget);
    expect(find.textContaining('tx-123'), findsOneWidget);
  });
}
