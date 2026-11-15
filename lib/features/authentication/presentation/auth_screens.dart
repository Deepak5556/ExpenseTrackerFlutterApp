import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/auth_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/design_system_widgets.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/utils/window_size_class.dart';
import '../auth_controller.dart';
import '../auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _animation,
    curve: Curves.easeOutCubic,
  );

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.88, end: 1).animate(_fade),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  WalletMark(
                    size: context.responsiveValue(compact: 66, medium: 76),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Expense Journal & Budget',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.responsiveValue(
                        compact: 20,
                        medium: 22,
                      ),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your money, clearly in view',
                    style: TextStyle(
                      color: AppColors.onGradientSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pages = PageController();
  int _page = 0;
  static const List<(String, String)> _slides = <(String, String)>[
    ('Track every rupee', 'Add expenses and income in a few simple taps.'),
    (
      'Your data stays in your Google Sheet',
      'Your journal lives in your own Google Drive.',
    ),
    ('See where it goes', 'Clear monthly and category insights help you plan.'),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(authControllerProvider.notifier).completeOnboarding();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _slides.length,
                  onPageChanged: (int value) => setState(() => _page = value),
                  itemBuilder: (BuildContext context, int index) => Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.windowSizeClass.pagePadding,
                      12,
                      context.windowSizeClass.pagePadding,
                      20,
                    ),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxWidth: 390),
                              height: context.responsiveValue(
                                compact: 220,
                                medium: 260,
                                expanded: 300,
                              ),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: AppShadows.card,
                              ),
                              child: _OnboardingIllustration(index: index),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _slides[index].$1,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _slides[index].$2,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: AppColors.onGradientSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  _slides.length,
                  (int index) => AnimatedContainer(
                    duration: AppMotion.stateChange,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == index ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.brandStart,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _page == _slides.length - 1
                        ? _finish
                        : () => _pages.nextPage(
                            duration: AppMotion.page,
                            curve: Curves.easeOutCubic,
                          ),
                    child: Text(
                      _page == _slides.length - 1 ? 'Get started' : 'Continue',
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
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({required this.index});
  final int index;
  @override
  Widget build(BuildContext context) {
    if (index == 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _MiniBar(height: 72),
              SizedBox(width: 14),
              _MiniBar(height: 116),
              SizedBox(width: 14),
              _MiniBar(height: 88),
              SizedBox(width: 14),
              _MiniBar(height: 142),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '₹ 12,480.52',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      );
    }
    if (index == 1) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.incomeSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const <Widget>[
              Icon(
                Icons.table_chart_rounded,
                color: AppColors.income,
                size: 48,
              ),
              SizedBox(height: 12),
              Text(
                'Your Google Sheet',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 16),
              _SheetLine(),
              _SheetLine(),
              _SheetLine(),
            ],
          ),
        ),
      );
    }
    return Center(
      child: SizedBox(
        width: 190,
        height: 190,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            SizedBox(
              width: 180,
              height: 180,
              child: CircularProgressIndicator(
                value: 0.76,
                strokeWidth: 25,
                backgroundColor: AppColors.border,
                color: AppColors.accentOrange,
              ),
            ),
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'THIS MONTH',
                  style: TextStyle(color: AppColors.labels, fontSize: 11),
                ),
                SizedBox(height: 5),
                Text(
                  '₹ 8,420',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 21),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({required this.height});
  final double height;
  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: height,
    decoration: BoxDecoration(
      gradient: AppColors.brandGradient,
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

class _SheetLine extends StatelessWidget {
  const _SheetLine();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 7),
    width: 180,
    height: 9,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState state = ref.watch(authControllerProvider);
    final AuthController controller = ref.read(authControllerProvider.notifier);
    final AuthFailure? failure = switch (state) {
      AuthSignedOut(:final failure) => failure,
      AuthNeedsAuthorization(:final failure) => failure,
      _ => null,
    };
    final bool isAuthorization = state is AuthNeedsAuthorization;

    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isLandscape = constraints.maxWidth > constraints.maxHeight;
          if (isLandscape) {
            return Row(
              children: <Widget>[
                Expanded(
                  flex: 5,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: AppColors.brandGradient,
                    ),
                    child: SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const WalletMark(size: 60),
                              const SizedBox(height: 16),
                              Text(
                                'Expense Journal & Budget',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'A clearer view of every rupee.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppColors.onGradientSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Container(
                    color: AppColors.card,
                    child: SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: _LoginForm(
                              isAuthorization: isAuthorization,
                              failure: failure,
                              state: state,
                              controller: controller,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: <Widget>[
                    Expanded(
                      flex: 5,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: AppColors.brandGradient,
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const WalletMark(size: 70),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Expense Journal & Budget',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'A clearer view of every rupee.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: AppColors.onGradientSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                        decoration: const BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: _LoginForm(
                              isAuthorization: isAuthorization,
                              failure: failure,
                              state: state,
                              controller: controller,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.isAuthorization,
    required this.failure,
    required this.state,
    required this.controller,
  });

  final bool isAuthorization;
  final AuthFailure? failure;
  final AuthState state;
  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          isAuthorization ? 'Connect your Google Drive' : 'Welcome',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isAuthorization
              ? 'Allow access to files you choose to create or open in this app.'
              : 'Sign in to keep your journal in your Google Sheet.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        if (failure != null) ...<Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              failure!.message,
              style: const TextStyle(color: AppColors.brandStart),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: state.isBusy
                ? null
                : () => isAuthorization
                      ? controller.authorizeAndContinue()
                      : controller.signIn(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: state.isBusy
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        state is AuthBusy
                            ? (state as AuthBusy).step
                            : 'Please wait…',
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      GoogleMark(),
                      SizedBox(width: 12),
                      Text(
                        'Continue with Google',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Your spreadsheet stays in your Google Drive. We only request access when needed.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.labels, fontSize: 12),
        ),
      ],
    );
  }
}

class ConnectedScreen extends ConsumerWidget {
  const ConnectedScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState state = ref.watch(authControllerProvider);
    if (state is! AuthSignedIn) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final GoogleSignInAccount user = state.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Google connected')),
      body: ResponsiveListView(
        children: <Widget>[
          SurfaceCard(
            child: Column(
              children: <Widget>[
                CircleAvatar(
                  radius: 38,
                  backgroundImage: user.photoUrl == null
                      ? null
                      : NetworkImage(user.photoUrl!),
                  child: user.photoUrl == null
                      ? const Icon(Icons.person_rounded, size: 36)
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  user.displayName ?? 'Google account',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Access granted'),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final String scope in state.grantedScopes)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.income,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SelectableText(
                            scope,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 24),
                const Text(
                  'Drive token check',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'Connected · ${state.tokenTestResult}',
                  style: const TextStyle(color: AppColors.income),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).disconnect();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.link_off_rounded),
            label: const Text('Disconnect Google account'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Sign out ends this app session. Disconnect also revokes this app’s Google authorization.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.labels, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class ReconnectScreen extends ConsumerWidget {
  const ReconnectScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState state = ref.watch(authControllerProvider);
    final String message = state is AuthReconnectRequired
        ? state.failure.message
        : 'Reconnect Google Drive to continue.';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.sync_problem_rounded,
                    size: 54,
                    color: AppColors.brandStart,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Reconnect Google Drive',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: state.isBusy
                        ? null
                        : () => ref
                              .read(authControllerProvider.notifier)
                              .reconnect(),
                    child: state.isBusy
                        ? const CircularProgressIndicator()
                        : const Text('Reconnect'),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WalletMark extends StatelessWidget {
  const WalletMark({super.key, this.size = 64});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(size * 0.28),
      border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
    ),
    child: Icon(
      Icons.account_balance_wallet_rounded,
      color: Colors.white,
      size: size * 0.54,
    ),
  );
}

class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 22,
    height: 22,
    child: CustomPaint(painter: _GoogleMarkPainter()),
  );
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    const List<Color> colors = <Color>[
      Color(0xFF4285F4),
      Color(0xFF34A853),
      Color(0xFFFBBC05),
      Color(0xFFEA4335),
    ];
    for (int index = 0; index < colors.length; index++) {
      final Paint paint = Paint()
        ..color = colors[index]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect.deflate(2), -0.55 + index * 1.57, 1.40, false, paint);
    }
    final Paint blue = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = 3.5;
    canvas.drawLine(
      Offset(size.width * .55, size.height * .5),
      Offset(size.width - 1, size.height * .5),
      blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
