import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_design_tokens.dart';
import '../utils/money_formatter.dart';
import '../utils/window_size_class.dart';

class GradientHeader extends StatelessWidget {
  const GradientHeader({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final double safeTop = MediaQuery.paddingOf(context).top;
    final double pagePadding = context.windowSizeClass.pagePadding;
    return ClipPath(
      clipper: const _CurvedBottomClipper(),
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        width: double.infinity,
        padding:
            padding ??
            EdgeInsets.fromLTRB(
              pagePadding,
              safeTop + AppSpacing.x4,
              pagePadding,
              AppSpacing.x10 + AppSpacing.x3,
            ),
        child: child,
      ),
    );
  }
}

class _CurvedBottomClipper extends CustomClipper<Path> {
  const _CurvedBottomClipper();

  @override
  Path getClip(Size size) {
    final Path path = Path()
      ..lineTo(0, size.height - 28)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height + 8,
        size.width * 0.52,
        size.height - 12,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height - 31,
        size.width,
        size.height - 18,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.margin = EdgeInsets.zero,
    this.color = AppColors.card,
    this.onTap,
    this.shadow = true,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color color;
  final VoidCallback? onTap;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.card);
    return Padding(
      padding: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              color: color,
              borderRadius: radius,
              border: Border.all(color: AppColors.border),
              boxShadow: shadow ? AppShadows.card : const <BoxShadow>[],
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

@immutable
class QuickAction {
  const QuickAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.accentOrange,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
}

class FloatingActionCard extends StatelessWidget {
  const FloatingActionCard({required this.actions, super.key});

  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.floating,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2,
        vertical: AppSpacing.x3,
      ),
      child: Row(
        children: actions
            .map(
              (QuickAction action) => Expanded(
                child: _QuickActionButton(action: action),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action});

  final QuickAction action;

  @override
  Widget build(BuildContext context) {
    final double iconBox = context.responsiveValue(
      compact: 40,
      medium: 44,
      expanded: 48,
    );
    return Semantics(
      button: true,
      label: action.label,
      child: InkWell(
        onTap: action.onPressed,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.x1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.tile),
                ),
                alignment: Alignment.center,
                child: Icon(
                  action.icon,
                  color: action.color,
                  size: iconBox * 0.52,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  action.label,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
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

class KpiCard extends StatelessWidget {
  const KpiCard({
    required this.label,
    required this.value,
    this.detail,
    this.icon,
    this.emphasized = false,
    this.valueColor,
    super.key,
  });

  final String label;
  final String value;
  final String? detail;
  final IconData? icon;
  final bool emphasized;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final compact = context.windowSizeClass.isCompact;
    final TextStyle? labelStyle = Theme.of(context).textTheme.labelSmall;
    final Widget contents = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: compact ? 88.0 : 96.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle?.copyWith(
                    color: emphasized
                        ? AppColors.onGradientSecondary
                        : AppColors.labels,
                    fontSize: AppTypography.micro,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (icon != null) ...<Widget>[
                const SizedBox(width: AppSpacing.x1),
                Icon(
                  icon,
                  size: 16,
                  color: emphasized ? Colors.white : AppColors.accentOrange,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.x1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color:
                    valueColor ??
                    (emphasized ? Colors.white : AppColors.textPrimary),
                fontSize: compact ? 22 : AppTypography.kpiValue,
                letterSpacing: -0.5,
                fontWeight: FontWeight.w700,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x1),
          Text(
            detail ?? ' ',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: detail != null
                  ? (emphasized
                      ? AppColors.onGradientSecondary
                      : AppColors.textSecondary)
                  : Colors.transparent,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );

    if (emphasized) {
      return Container(
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.hero,
        ),
        child: Padding(
          padding: EdgeInsets.all(
            compact ? AppSpacing.x3 : AppSpacing.cardPadding,
          ),
          child: contents,
        ),
      );
    }

    return SurfaceCard(
      padding: EdgeInsets.all(compact ? AppSpacing.x3 : AppSpacing.cardPadding),
      child: contents,
    );
  }
}

class PillBadge extends StatelessWidget {
  const PillBadge({
    required this.label,
    this.backgroundColor = AppColors.orangePillSurface,
    this.foregroundColor = AppColors.orangePillText,
    this.icon,
    super.key,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: foregroundColor),
            const SizedBox(width: AppSpacing.x1),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foregroundColor,
              letterSpacing: 0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class AmountText extends StatelessWidget {
  const AmountText({
    required this.minorUnits,
    this.style,
    this.compact = false,
    this.animate = true,
    this.duration = AppMotion.chart,
    this.textAlign = TextAlign.start,
    super.key,
  });

  final int minorUnits;
  final TextStyle? style;
  final bool compact;
  final bool animate;
  final Duration duration;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final bool reducedMotion = MediaQuery.disableAnimationsOf(context);
    final TextStyle amountStyle =
        (style ?? Theme.of(context).textTheme.displayLarge!).copyWith(
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        );

    Widget textFor(int value) => Text(
      formatMoney(value, compact: compact),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: amountStyle,
    );

    if (!animate || reducedMotion) return textFor(minorUnits);
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: minorUnits),
      duration: duration,
      curve: AppMotion.curve,
      builder: (BuildContext context, int value, Widget? child) =>
          textFor(value),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.subtitle,
    this.leading,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (leading != null) ...<Widget>[
          leading!,
          const SizedBox(width: AppSpacing.x2),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: AppSpacing.x1),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    this.width,
    this.height = 14,
    this.borderRadius = AppRadius.tile,
    super.key,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(widget.borderRadius);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final double travel = _reducedMotion ? 0 : _controller.value * 2;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                colors: _reducedMotion
                    ? const <Color>[
                        AppColors.mutedSurface,
                        AppColors.mutedSurface,
                      ]
                    : const <Color>[
                        AppColors.mutedSurface,
                        Color(0xFFFFFFFF),
                        AppColors.mutedSurface,
                      ],
                stops: _reducedMotion ? null : const <double>[0.25, 0.5, 0.75],
                begin: Alignment(-1 + travel, 0),
                end: Alignment(1 + travel, 0),
              ),
            ),
          );
        },
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: context.responsiveValue(compact: 56, medium: 64),
              height: context.responsiveValue(compact: 56, medium: 64),
              decoration: BoxDecoration(
                color: AppColors.orangePillSurface,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Icon(
                icon,
                color: AppColors.accentOrange,
                size: context.responsiveValue(compact: 27, medium: 30),
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            if (actionLabel != null) ...<Widget>[
              const SizedBox(height: AppSpacing.x4),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

@immutable
class AppNavItem {
  const AppNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onAdd,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onAdd;

  static const List<AppNavItem> _items = <AppNavItem>[
    AppNavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    AppNavItem(
      label: 'Journal',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
    ),
    AppNavItem(
      label: 'Analytics',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
    ),
    AppNavItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final compact = context.windowSizeClass.isCompact;
    final double textScale = mediaQuery.textScaler.scale(1.0).clamp(0.9, 1.25);
    final double bottomInset = mediaQuery.padding.bottom;
    final double baseHeight = (compact ? 66.0 : 72.0) * textScale;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.x2,
        0,
        AppSpacing.x2,
        bottomInset > 0 ? bottomInset : AppSpacing.x1,
      ),
      child: SizedBox(
        height: baseHeight,
        child: Row(
          children: <Widget>[
            _navButton(context, itemIndex: 0, branchIndex: 0),
            _navButton(context, itemIndex: 1, branchIndex: 1),
            Expanded(
              child: Semantics(
                button: true,
                label: 'Add expense',
                child: InkWell(
                  onTap: onAdd,
                  key: const ValueKey<String>('bottom-nav-add'),
                  borderRadius: BorderRadius.circular(AppRadius.tile),
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, -3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            width: compact ? 42 : 46,
                            height: compact ? 42 : 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.brandGradient,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppColors.brandStart.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: compact ? 24 : 26,
                            ),
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Add',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppColors.brandStart,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _navButton(context, itemIndex: 2, branchIndex: 3),
            _navButton(context, itemIndex: 3, branchIndex: 4),
          ],
        ),
      ),
    );
  }

  Widget _navButton(
    BuildContext context, {
    required int itemIndex,
    required int branchIndex,
  }) {
    final AppNavItem item = _items[itemIndex];
    final bool selected = selectedIndex == branchIndex;
    final Color color = selected ? AppColors.brandStart : AppColors.labels;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: InkWell(
          key: ValueKey<String>('bottom-nav-$branchIndex'),
          onTap: () => onDestinationSelected(branchIndex),
          borderRadius: BorderRadius.circular(AppRadius.tile),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.x1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  color: color,
                  size: context.responsiveValue(compact: 22, medium: 24),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Professional elevated financial dashboard card matching the design reference.
class DashboardCard extends StatelessWidget {
  const DashboardCard({
    required this.child,
    this.title,
    this.subtitle,
    this.leading,
    this.action,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.margin = EdgeInsets.zero,
    this.onTap,
    super.key,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? action;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      margin: margin,
      padding: padding,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Row(
              children: <Widget>[
                if (leading != null) ...<Widget>[
                  leading!,
                  const SizedBox(width: AppSpacing.x2),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ?action,
              ],
            ),
            const SizedBox(height: AppSpacing.x3),
          ],
          child,
        ],
      ),
    );
  }
}

/// Standardized loading indicator for components and whole screens.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    this.message,
    this.size = 36.0,
    this.color = AppColors.brandStart,
    super.key,
  });

  final String? message;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: 3.0,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: AppSpacing.x3),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Alias for EmptyState to provide consistent naming across architecture.
typedef AppEmptyState = EmptyState;

/// Standardized error state widget with recovery action.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    required this.message,
    this.title = 'Something went wrong',
    this.onRetry,
    this.retryLabel = 'Try again',
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.orangePillSurface,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.brandStart,
                size: 30,
              ),
            ),
            const SizedBox(height: AppSpacing.x3),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: AppSpacing.x4),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
