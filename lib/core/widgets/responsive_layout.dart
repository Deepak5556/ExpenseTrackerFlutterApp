import 'package:material_ui/material_ui.dart';

import '../theme/app_design_tokens.dart';
import '../utils/window_size_class.dart';

/// Gives every screen safe insets, proportional page padding and a readable
/// maximum content width. It is deliberately presentation-only.
class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    required this.child,
    this.scrollable = false,
    this.padding,
    this.top = true,
    this.bottom = true,
    super.key,
  });

  final Widget child;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;
  final bool top;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    final sizeClass = context.windowSizeClass;
    final content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: sizeClass.contentMaxWidth),
        child: child,
      ),
    );
    final insets =
        padding ?? EdgeInsets.symmetric(horizontal: sizeClass.pagePadding);
    return SafeArea(
      top: top,
      bottom: bottom,
      child: scrollable
          ? SingleChildScrollView(
              padding: insets.add(const EdgeInsets.only(bottom: AppSpacing.x6)),
              child: content,
            )
          : Padding(padding: insets, child: content),
    );
  }
}

/// Calculates equal-width tiles without a fixed card width.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    required this.children,
    this.compactColumns = 2,
    this.mediumColumns = 2,
    this.expandedColumns = 4,
    this.spacing = AppSpacing.x2,
    super.key,
  });

  final List<Widget> children;
  final int compactColumns;
  final int mediumColumns;
  final int expandedColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = switch (context.windowSizeClass) {
        WindowSizeClass.compact => compactColumns,
        WindowSizeClass.medium => mediumColumns,
        WindowSizeClass.expanded => expandedColumns,
      };
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: <Widget>[
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

/// A drop-in list body that keeps existing screen scrolling while limiting
/// line length and card width on tablets and landscape devices.
class ResponsiveListView extends StatelessWidget {
  const ResponsiveListView({
    required this.children,
    this.padding,
    this.controller,
    this.physics,
    super.key,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final sizeClass = context.windowSizeClass;
    return ListView(
      controller: controller,
      physics: physics,
      padding: padding ?? EdgeInsets.all(sizeClass.pagePadding),
      children: <Widget>[
        for (final child in children)
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: sizeClass.contentMaxWidth),
              child: child,
            ),
          ),
      ],
    );
  }
}
