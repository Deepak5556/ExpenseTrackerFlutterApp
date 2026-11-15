import 'package:flutter/widgets.dart';

enum WindowSizeClass { compact, medium, expanded }

extension WindowSizeClassLayout on WindowSizeClass {
  bool get isCompact => this == WindowSizeClass.compact;
  bool get isMedium => this == WindowSizeClass.medium;
  bool get isExpanded => this == WindowSizeClass.expanded;

  int get dashboardColumns => switch (this) {
    WindowSizeClass.compact => 2,
    WindowSizeClass.medium => 2,
    WindowSizeClass.expanded => 4,
  };

  double get pagePadding => isCompact ? 20 : 24;

  double get contentMaxWidth => switch (this) {
    WindowSizeClass.compact => double.infinity,
    WindowSizeClass.medium => 760,
    WindowSizeClass.expanded => 1200,
  };

  double get compactScale => switch (this) {
    WindowSizeClass.compact => 0.94,
    WindowSizeClass.medium => 1,
    WindowSizeClass.expanded => 1.06,
  };
}

WindowSizeClass windowSizeClassForWidth(double width) {
  if (width < 600) return WindowSizeClass.compact;
  if (width < 840) return WindowSizeClass.medium;
  return WindowSizeClass.expanded;
}

WindowSizeClass windowSizeClassOf(BuildContext context) =>
    windowSizeClassForWidth(MediaQuery.sizeOf(context).width);

extension ResponsiveContext on BuildContext {
  WindowSizeClass get windowSizeClass => windowSizeClassOf(this);

  double responsiveValue({
    required double compact,
    double? medium,
    double? expanded,
  }) => switch (windowSizeClass) {
    WindowSizeClass.compact => compact,
    WindowSizeClass.medium => medium ?? compact,
    WindowSizeClass.expanded => expanded ?? medium ?? compact,
  };
}
