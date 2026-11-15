import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/authentication/auth_controller.dart';
import 'features/authentication/auth_state.dart';
import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  final ValueNotifier<AuthState> authRefresh = ValueNotifier<AuthState>(
    ref.read(authControllerProvider),
  );
  ref.listen<AuthState>(authControllerProvider, (_, AuthState next) {
    authRefresh.value = next;
  });
  final GoRouter router = createAppRouter(
    initialLocation: '/splash',
    refreshListenable: authRefresh,
    authState: () => authRefresh.value,
  );
  ref.onDispose(() {
    router.dispose();
    authRefresh.dispose();
  });
  return router;
});

class ExpenseJournalApp extends ConsumerWidget {
  const ExpenseJournalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Expense Journal & Budget',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      themeMode: ThemeMode.light,
      routerConfig: ref.watch(appRouterProvider),
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
