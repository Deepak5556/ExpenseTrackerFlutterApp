import 'package:expense_journal_budget/core/theme/app_theme.dart';
import 'package:expense_journal_budget/core/widgets/design_system_widgets.dart';
import 'package:expense_journal_budget/dev/design_preview_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'design preview fits the requested window sizes at max text scale',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      const List<Size> viewports = <Size>[
        Size(360, 800),
        Size(412, 915),
        Size(600, 960),
        Size(1024, 768),
      ];

      for (final Size viewport in viewports) {
        tester.view.physicalSize = viewport;
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: viewport,
              textScaler: TextScaler.linear(1.3),
              disableAnimations: true,
            ),
            child: MaterialApp(
              theme: buildLightTheme(),
              home: const DesignPreviewScreen(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));

        expect(tester.takeException(), isNull, reason: 'Viewport: $viewport');
        expect(find.byType(KpiCard), findsNWidgets(4));
        if (viewport.width >= 840) {
          expect(find.byType(NavigationRail), findsOneWidget);
        } else {
          expect(find.byType(AppBottomNav), findsOneWidget);
        }
      }

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    },
  );
}
