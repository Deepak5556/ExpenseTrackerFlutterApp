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

/// Adaptive layout builder switching between compact, medium, and expanded views,
/// or handling portrait vs. landscape orientations seamlessly.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.compact,
    this.medium,
    this.expanded,
    this.landscape,
    super.key,
  });

  final WidgetBuilder compact;
  final WidgetBuilder? medium;
  final WidgetBuilder? expanded;
  final WidgetBuilder? landscape;

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.orientationOf(context);
    if (landscape != null && orientation == Orientation.landscape) {
      return landscape!(context);
    }
    return switch (context.windowSizeClass) {
      WindowSizeClass.compact => compact(context),
      WindowSizeClass.medium => (medium ?? compact)(context),
      WindowSizeClass.expanded => (expanded ?? medium ?? compact)(context),
    };
  }
}

/// Calculates equal-width tiles without fixed card widths, with floating-point
/// rounding protection so tiles never wrap prematurely.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    required this.children,
    this.compactColumns = 2,
    this.mediumColumns = 2,
    this.expandedColumns = 4,
    this.spacing = AppSpacing.x2,
    this.runSpacing,
    super.key,
  });

  final List<Widget> children;
  final int compactColumns;
  final int mediumColumns;
  final int expandedColumns;
  final double spacing;
  final double? runSpacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = switch (context.windowSizeClass) {
        WindowSizeClass.compact => compactColumns,
        WindowSizeClass.medium => mediumColumns,
        WindowSizeClass.expanded => expandedColumns,
      };
      final maxWidth = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width;
      final rawWidth = (maxWidth - (spacing * (columns - 1))) / columns;
      // Guard against double precision overflow in Wrap
      final width = (rawWidth - 0.05).clamp(1.0, double.infinity);
      final verticalSpacing = runSpacing ?? spacing;

      return Wrap(
        spacing: spacing,
        runSpacing: verticalSpacing,
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
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.onDrag,
    super.key,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  @override
  Widget build(BuildContext context) {
    final sizeClass = context.windowSizeClass;
    return ListView(
      controller: controller,
      physics: physics,
      keyboardDismissBehavior: keyboardDismissBehavior,
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

/// Responsive text that scales down gracefully instead of overflowing or clipping.
class ResponsiveText extends StatelessWidget {
  const ResponsiveText(
    this.text, {
    this.style,
    this.maxLines = 1,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    this.scaleDown = true,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextAlign? textAlign;
  final TextOverflow overflow;
  final bool scaleDown;

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      text,
      style: style,
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: overflow,
    );

    if (scaleDown) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: textAlign == TextAlign.center
            ? Alignment.center
            : textAlign == TextAlign.right
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: textWidget,
      );
    }
    return textWidget;
  }
}
