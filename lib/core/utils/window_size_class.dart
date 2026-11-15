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
}

WindowSizeClass windowSizeClassForWidth(double width) {
  if (width < 600) return WindowSizeClass.compact;
  if (width < 840) return WindowSizeClass.medium;
  return WindowSizeClass.expanded;
}

WindowSizeClass windowSizeClassOf(BuildContext context) =>
    windowSizeClassForWidth(MediaQuery.sizeOf(context).width);
