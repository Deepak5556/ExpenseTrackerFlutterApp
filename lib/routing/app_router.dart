import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_design_tokens.dart';
import '../dev/design_preview_screen.dart';
import '../dev/sheet_debug_screen.dart';
import '../features/authentication/auth_state.dart';
import '../features/authentication/presentation/auth_screens.dart';
import '../features/analytics/presentation/analytics_screen.dart';
import '../features/dashboard/presentation/home_screen.dart';
import '../features/expenses/presentation/add_transaction_screen.dart';
import '../features/settings/presentation/budgets_screen.dart';
import '../features/settings/presentation/categories_screen.dart';
import '../features/settings/presentation/google_sheets_connection_screen.dart';
import '../features/settings/presentation/notifications_screen.dart';
import '../features/settings/presentation/profile_screen.dart';
import '../features/settings/presentation/privacy_screen.dart';
import '../features/settings/presentation/spreadsheet_setup_screen.dart';
import '../features/settings/presentation/salary_screen.dart';
import '../features/transactions/presentation/transaction_detail_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/transactions/presentation/journal_screen.dart';
import 'app_shell.dart';

final GoRouter appRouter = createAppRouter();

GoRouter createAppRouter({
  String initialLocation = '/home',
  Listenable? refreshListenable,
  AuthState Function()? authState,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: refreshListenable,
    redirect: authState == null
        ? null
        : (BuildContext context, GoRouterState route) {
            final AuthState auth = authState();
            final String path = route.uri.path;
            const Set<String> entryPaths = <String>{
              '/splash',
              '/onboarding',
              '/login',
              '/reconnect',
              '/auth/connected',
            };
            if (auth is AuthRestoring) {
              return path == '/splash' ? null : '/splash';
            }
            if (auth.onboardingRequired) {
              return path == '/onboarding' ? null : '/onboarding';
            }
            if (path == '/onboarding') {
              return auth is AuthSignedIn ? '/auth/connected' : '/login';
            }
            if (auth is AuthSignedIn) {
              if (path == '/splash' ||
                  path == '/login' ||
                  path == '/reconnect' ||
                  path == '/auth/connected') {
                return '/setup-sheet';
              }
              return null;
            }
            if (auth is AuthReconnectRequired) {
              return path == '/reconnect' ? null : '/reconnect';
            }
            if (auth is AuthSignedOut || auth is AuthNeedsAuthorization) {
              if (auth is AuthBusy) {
                return null;
              }
              if (path == '/splash') {
                return '/login';
              }
              if (path == '/reconnect' || path == '/auth/connected') {
                return '/login';
              }
              if (!entryPaths.contains(path)) {
                return '/login';
              }
            }
            return null;
          },
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) => AppShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (BuildContext context, GoRouterState state) =>
                    const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/journal',
                name: 'journal',
                builder: (BuildContext context, GoRouterState state) =>
                    const JournalScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/add',
                name: 'add',
                builder: (BuildContext context, GoRouterState state) =>
                    AddTransactionScreen(
                      initialType:
                          state.uri.queryParameters['type'] ?? 'expense',
                    ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/analytics',
                name: 'analytics',
                builder: (BuildContext context, GoRouterState state) =>
                    const AnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (BuildContext context, GoRouterState state) =>
                    const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/splash',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadePage(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadePage(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadePage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/reconnect',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadePage(state, const ReconnectScreen()),
      ),
      GoRoute(
        path: '/setup-sheet',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadePage(state, const SpreadsheetSetupScreen()),
      ),
      GoRoute(
        path: '/auth/connected',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadePage(state, const ConnectedScreen()),
      ),
      GoRoute(
        path: '/categories',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadePage(state, const CategoriesScreen()),
      ),
      GoRoute(
        path: '/transaction/:id',
        pageBuilder: (BuildContext context, GoRouterState state) => _fadePage(
          state,
          TransactionDetailScreen(transactionId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/transaction/:id/edit',
        pageBuilder: (BuildContext context, GoRouterState state) => _fadePage(
          state,
          AddTransactionScreen(transactionId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/salary',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadePage(state, const SalaryScreen()),
      ),
      GoRoute(
        path: '/connect-spreadsheet',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadePage(state, const GoogleSheetsConnectionScreen()),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadePage(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: '/budgets',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadePage(state, const BudgetsScreen()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadePage(state, const ProfileScreen()),
      ),
      GoRoute(
        path: '/privacy',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadePage(state, const PrivacyScreen()),
      ),
      GoRoute(
        path: '/dev/preview',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadePage(state, const DesignPreviewScreen()),
      ),
      GoRoute(
        path: '/dev/sheets',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadePage(state, const SheetDebugScreen()),
      ),
    ],
  );
}

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      transitionDuration: AppMotion.page,
      reverseTransitionDuration: AppMotion.page,
      child: child,
      transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) => FadeTransition(opacity: animation, child: child),
    );
