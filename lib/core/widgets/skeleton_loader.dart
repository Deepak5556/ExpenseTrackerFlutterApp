import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_design_tokens.dart';

/// Shimmering placeholder box for smooth skeleton loading states.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.card,
    super.key,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.disableAnimationsOf(context)) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget? child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.divider.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Dashboard skeleton displayed on first-load while Google Sheets is contacted.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: AppSpacing.x3),
          SkeletonBox(
            width: double.infinity,
            height: 110,
            borderRadius: AppRadius.card,
          ),
          SizedBox(height: AppSpacing.x4),
          Row(
            children: <Widget>[
              Expanded(
                child: SkeletonBox(
                  width: double.infinity,
                  height: 95,
                  borderRadius: AppRadius.card,
                ),
              ),
              SizedBox(width: AppSpacing.x3),
              Expanded(
                child: SkeletonBox(
                  width: double.infinity,
                  height: 95,
                  borderRadius: AppRadius.card,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.x4),
          SkeletonBox(
            width: double.infinity,
            height: 120,
            borderRadius: AppRadius.card,
          ),
          SizedBox(height: AppSpacing.x4),
          SkeletonBox(width: 140, height: 24, borderRadius: AppRadius.pill),
          SizedBox(height: AppSpacing.x3),
          SkeletonBox(
            width: double.infinity,
            height: 64,
            borderRadius: AppRadius.card,
          ),
          SizedBox(height: AppSpacing.x2),
          SkeletonBox(
            width: double.infinity,
            height: 64,
            borderRadius: AppRadius.card,
          ),
        ],
      ),
    );
  }
}

/// Transaction list skeleton displayed during loading in Journal screen.
class TransactionListSkeleton extends StatelessWidget {
  const TransactionListSkeleton({this.itemCount = 6, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x4,
        vertical: AppSpacing.x2,
      ),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.x2),
      itemBuilder: (_, _) => const SkeletonBox(
        width: double.infinity,
        height: 68,
        borderRadius: AppRadius.card,
      ),
    );
  }
}
