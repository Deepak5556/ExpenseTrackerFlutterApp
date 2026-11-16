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

class ExpenseJournalApp extends ConsumerStatefulWidget {
  const ExpenseJournalApp({super.key});

  @override
  ConsumerState<ExpenseJournalApp> createState() => _ExpenseJournalAppState();
}

class _ExpenseJournalAppState extends ConsumerState<ExpenseJournalApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(authControllerProvider.notifier).handleAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
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
