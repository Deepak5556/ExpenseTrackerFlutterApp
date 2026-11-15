import 'package:material_ui/material_ui.dart';

abstract final class AppTypography {
  /// Change this one value to replace the bundled font family.
  static const String family = 'Inter';

  static const double largeTitle = 34;
  static const double titleLarge = 28;
  static const double titleMedium = 22;
  static const double titleSmall = 20;
  static const double headline = 17;
  static const double body = 17;
  static const double callout = 16;
  static const double subhead = 15;
  static const double footnote = 13;
  static const double caption = 12;
  static const double micro = 11;
  static const double heroAmount = 44;
  static const double kpiValue = 26;

  static TextTheme textTheme(Color color) {
    TextStyle style(double size, FontWeight weight, {double tracking = 0}) =>
        TextStyle(
          color: color,
          fontFamily: family,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: tracking,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          fontVariations: <FontVariation>[
            FontVariation('wght', weight.value.toDouble()),
            FontVariation('opsz', size),
          ],
        );

    return TextTheme(
      displayLarge: style(largeTitle, FontWeight.w600, tracking: -0.8),
      headlineLarge: style(titleLarge, FontWeight.w600, tracking: -0.4),
      headlineMedium: style(titleMedium, FontWeight.w600, tracking: -0.2),
      headlineSmall: style(titleSmall, FontWeight.w600),
      titleLarge: style(headline, FontWeight.w600),
      titleMedium: style(subhead, FontWeight.w600),
      titleSmall: style(caption, FontWeight.w600),
      bodyLarge: style(body, FontWeight.w400),
      bodyMedium: style(callout, FontWeight.w400),
      bodySmall: style(footnote, FontWeight.w400),
      labelLarge: style(subhead, FontWeight.w600),
      labelMedium: style(caption, FontWeight.w500),
      labelSmall: style(micro, FontWeight.w500, tracking: 0.6),
    );
  }
}

abstract final class AppSpacing {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;

  static const double pageCompact = 20;
  static const double pageMedium = 24;
  static const double contentMaxWidth = 1200;
  static const double cardPadding = 16;
}

abstract final class AppRadius {
  static const double card = 24;
  static const double tile = 16;
  static const double sheet = 28;
  static const double pill = 999;
}

abstract final class AppShadows {
  static const List<BoxShadow> card = <BoxShadow>[
    BoxShadow(color: Color(0x0F1C1917), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> floating = <BoxShadow>[
    BoxShadow(color: Color(0x2E781E0A), blurRadius: 40, offset: Offset(0, 16)),
  ];

  static const List<BoxShadow> hero = <BoxShadow>[
    BoxShadow(color: Color(0x241C1917), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

abstract final class AppMotion {
  static const Duration press = Duration(milliseconds: 120);
  static const Duration stateChange = Duration(milliseconds: 240);
  static const Duration chart = Duration(milliseconds: 500);
  static const Duration page = Duration(milliseconds: 300);
  static const Curve curve = Curves.easeOutCubic;
  static const double pressScale = 0.97;
  static const double listSlideDistance = 12;
}
