import 'package:material_ui/material_ui.dart';

/// The complete light palette for Expense Journal & Budget.
/// Keep color values here so future themes can share the same semantic tokens.
abstract final class AppColors {
  static const Color brandStart = Color(0xFFB3260F);
  static const Color brandMiddle = Color(0xFFD5401A);
  static const Color brandEnd = Color(0xFFE85A1C);
  static const Color pressed = Color(0xFF8F1A07);
  static const Color accentOrange = Color(0xFFF26A1B);
  static const Color amber = Color(0xFFE08A0B);
  static const Color activeMonth = Color(0xFFB3260F);

  static const Color pageBackground = Color(0xFFF5F1EF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color mutedSurface = Color(0xFFFAF7F6);
  static const Color border = Color(0xFFEDE6E3);
  static const Color divider = Color(0xFFF1EBE8);

  static const Color textPrimary = Color(0xFF1C1917);
  static const Color textSecondary = Color(0xFF57534E);
  static const Color labels = Color(0xFF8A817C);
  static const Color onGradient = Color(0xFFFFFFFF);
  static const Color onGradientSecondary = Color(0xC7FFFFFF);

  static const Color income = Color(0xFF12A150);
  static const Color incomeSurface = Color(0xFFE7F6EE);
  static const Color timeChipText = Color(0xFF2D5BD0);
  static const Color timeChipSurface = Color(0xFFE8F0FE);
  static const Color orangePillText = Color(0xFFC2410C);
  static const Color orangePillSurface = Color(0xFFFFEADD);
  static const Color amberPillText = Color(0xFFB45309);
  static const Color amberPillSurface = Color(0xFFFFF1D6);

  static const List<Color> chartPalette = <Color>[
    Color(0xFFF26A1B),
    Color(0xFFE08A0B),
    Color(0xFFC42A0E),
    Color(0xFFF5B84A),
    Color(0xFF8C3B1F),
    Color(0xFFFF9A6B),
    Color(0xFFA8A29E),
  ];

  static const LinearGradient brandGradient = LinearGradient(
    colors: <Color>[brandStart, brandMiddle, brandEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: brandStart,
    onPrimary: Colors.white,
    primaryContainer: orangePillSurface,
    onPrimaryContainer: orangePillText,
    secondary: accentOrange,
    onSecondary: Colors.white,
    secondaryContainer: amberPillSurface,
    onSecondaryContainer: amberPillText,
    tertiary: amber,
    onTertiary: Colors.white,
    tertiaryContainer: incomeSurface,
    onTertiaryContainer: income,
    error: Color(0xFFB3261E),
    onError: Colors.white,
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: card,
    onSurface: textPrimary,
    onSurfaceVariant: textSecondary,
    outline: border,
    outlineVariant: divider,
    shadow: Color(0xFF1C1917),
    scrim: Color(0x66000000),
    inverseSurface: Color(0xFF322F2D),
    onInverseSurface: Colors.white,
    inversePrimary: Color(0xFFFFB4A2),
    surfaceTint: brandStart,
  );
}

/// Semantic colors used by components that need more than Material's scheme.
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.gradientStart,
    required this.gradientMiddle,
    required this.gradientEnd,
    required this.pressed,
    required this.accentOrange,
    required this.amber,
    required this.activeMonth,
    required this.mutedSurface,
    required this.border,
    required this.divider,
    required this.labels,
    required this.onGradientSecondary,
    required this.income,
    required this.incomeSurface,
    required this.timeChipText,
    required this.timeChipSurface,
    required this.orangePillText,
    required this.orangePillSurface,
    required this.amberPillText,
    required this.amberPillSurface,
    required this.chartPalette,
  });

  final Color gradientStart;
  final Color gradientMiddle;
  final Color gradientEnd;
  final Color pressed;
  final Color accentOrange;
  final Color amber;
  final Color activeMonth;
  final Color mutedSurface;
  final Color border;
  final Color divider;
  final Color labels;
  final Color onGradientSecondary;
  final Color income;
  final Color incomeSurface;
  final Color timeChipText;
  final Color timeChipSurface;
  final Color orangePillText;
  final Color orangePillSurface;
  final Color amberPillText;
  final Color amberPillSurface;
  final List<Color> chartPalette;

  static const AppThemeExtension light = AppThemeExtension(
    gradientStart: AppColors.brandStart,
    gradientMiddle: AppColors.brandMiddle,
    gradientEnd: AppColors.brandEnd,
    pressed: AppColors.pressed,
    accentOrange: AppColors.accentOrange,
    amber: AppColors.amber,
    activeMonth: AppColors.activeMonth,
    mutedSurface: AppColors.mutedSurface,
    border: AppColors.border,
    divider: AppColors.divider,
    labels: AppColors.labels,
    onGradientSecondary: AppColors.onGradientSecondary,
    income: AppColors.income,
    incomeSurface: AppColors.incomeSurface,
    timeChipText: AppColors.timeChipText,
    timeChipSurface: AppColors.timeChipSurface,
    orangePillText: AppColors.orangePillText,
    orangePillSurface: AppColors.orangePillSurface,
    amberPillText: AppColors.amberPillText,
    amberPillSurface: AppColors.amberPillSurface,
    chartPalette: AppColors.chartPalette,
  );

  @override
  AppThemeExtension copyWith({
    Color? gradientStart,
    Color? gradientMiddle,
    Color? gradientEnd,
    Color? pressed,
    Color? accentOrange,
    Color? amber,
    Color? activeMonth,
    Color? mutedSurface,
    Color? border,
    Color? divider,
    Color? labels,
    Color? onGradientSecondary,
    Color? income,
    Color? incomeSurface,
    Color? timeChipText,
    Color? timeChipSurface,
    Color? orangePillText,
    Color? orangePillSurface,
    Color? amberPillText,
    Color? amberPillSurface,
    List<Color>? chartPalette,
  }) {
    return AppThemeExtension(
      gradientStart: gradientStart ?? this.gradientStart,
      gradientMiddle: gradientMiddle ?? this.gradientMiddle,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      pressed: pressed ?? this.pressed,
      accentOrange: accentOrange ?? this.accentOrange,
      amber: amber ?? this.amber,
      activeMonth: activeMonth ?? this.activeMonth,
      mutedSurface: mutedSurface ?? this.mutedSurface,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      labels: labels ?? this.labels,
      onGradientSecondary: onGradientSecondary ?? this.onGradientSecondary,
      income: income ?? this.income,
      incomeSurface: incomeSurface ?? this.incomeSurface,
      timeChipText: timeChipText ?? this.timeChipText,
      timeChipSurface: timeChipSurface ?? this.timeChipSurface,
      orangePillText: orangePillText ?? this.orangePillText,
      orangePillSurface: orangePillSurface ?? this.orangePillSurface,
      amberPillText: amberPillText ?? this.amberPillText,
      amberPillSurface: amberPillSurface ?? this.amberPillSurface,
      chartPalette: chartPalette ?? this.chartPalette,
    );
  }

  @override
  AppThemeExtension lerp(
    covariant ThemeExtension<AppThemeExtension>? other,
    double t,
  ) {
    if (other is! AppThemeExtension) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    final int paletteLength = chartPalette.length < other.chartPalette.length
        ? chartPalette.length
        : other.chartPalette.length;

    return AppThemeExtension(
      gradientStart: mix(gradientStart, other.gradientStart),
      gradientMiddle: mix(gradientMiddle, other.gradientMiddle),
      gradientEnd: mix(gradientEnd, other.gradientEnd),
      pressed: mix(pressed, other.pressed),
      accentOrange: mix(accentOrange, other.accentOrange),
      amber: mix(amber, other.amber),
      activeMonth: mix(activeMonth, other.activeMonth),
      mutedSurface: mix(mutedSurface, other.mutedSurface),
      border: mix(border, other.border),
      divider: mix(divider, other.divider),
      labels: mix(labels, other.labels),
      onGradientSecondary: mix(onGradientSecondary, other.onGradientSecondary),
      income: mix(income, other.income),
      incomeSurface: mix(incomeSurface, other.incomeSurface),
      timeChipText: mix(timeChipText, other.timeChipText),
      timeChipSurface: mix(timeChipSurface, other.timeChipSurface),
      orangePillText: mix(orangePillText, other.orangePillText),
      orangePillSurface: mix(orangePillSurface, other.orangePillSurface),
      amberPillText: mix(amberPillText, other.amberPillText),
      amberPillSurface: mix(amberPillSurface, other.amberPillSurface),
      chartPalette: List<Color>.generate(
        paletteLength,
        (int index) => mix(chartPalette[index], other.chartPalette[index]),
        growable: false,
      ),
    );
  }
}
