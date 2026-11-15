import 'package:flutter/widgets.dart';

import '../utils/window_size_class.dart';

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({required this.builder, super.key});

  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
    WindowSizeClass sizeClass,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) => builder(
        context,
        constraints,
        windowSizeClassForWidth(constraints.maxWidth),
      ),
    );
  }
}
