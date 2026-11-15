import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_design_tokens.dart';

ThemeData buildLightTheme() {
  final ColorScheme scheme = AppColors.lightColorScheme;
  final RoundedSuperellipseBorder cardShape = RoundedSuperellipseBorder(
    borderRadius: BorderRadius.circular(AppRadius.card),
    side: const BorderSide(color: AppColors.border),
  );
  final RoundedSuperellipseBorder controlShape = RoundedSuperellipseBorder(
    borderRadius: BorderRadius.circular(AppRadius.tile),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.pageBackground,
    fontFamily: AppTypography.family,
    textTheme: AppTypography.textTheme(AppColors.textPrimary),
    visualDensity: VisualDensity.standard,
    iconTheme: const IconThemeData(size: 22, color: AppColors.textSecondary),
    extensions: const <ThemeExtension<dynamic>>[AppThemeExtension.light],
    appBarTheme: AppBarThemeData(
      backgroundColor: AppColors.pageBackground,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: AppTypography.textTheme(AppColors.textPrimary).titleLarge,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: cardShape,
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: AppColors.mutedSurface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x4,
        vertical: AppSpacing.x3,
      ),
      hintStyle: AppTypography.textTheme(AppColors.labels).bodyMedium,
      labelStyle: AppTypography.textTheme(AppColors.textSecondary).bodyMedium,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        borderSide: const BorderSide(color: AppColors.brandStart, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        borderSide: const BorderSide(color: AppColors.brandStart),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.mutedSurface,
      selectedColor: AppColors.orangePillSurface,
      disabledColor: AppColors.divider,
      secondarySelectedColor: AppColors.orangePillSurface,
      labelStyle: AppTypography.textTheme(AppColors.textSecondary).labelMedium!,
      secondaryLabelStyle: AppTypography.textTheme(AppColors.orangePillText)
          .labelMedium!,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
      side: const BorderSide(color: AppColors.border),
      shape: const StadiumBorder(),
      showCheckmark: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandStart,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.labels,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
        shape: controlShape,
        textStyle: AppTypography.textTheme(Colors.white).labelLarge,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandStart,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        shape: controlShape,
        textStyle: AppTypography.textTheme(Colors.white).labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brandStart,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: AppColors.border),
        shape: controlShape,
        textStyle: AppTypography.textTheme(AppColors.brandStart).labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brandStart,
        minimumSize: const Size(48, 48),
        shape: controlShape,
        textStyle: AppTypography.textTheme(AppColors.brandStart).labelLarge,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.orangePillSurface,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
        (Set<WidgetState> states) => AppTypography.textTheme(
          states.contains(WidgetState.selected)
              ? AppColors.brandStart
              : AppColors.textSecondary,
        ).labelSmall,
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.card,
      selectedIconTheme: const IconThemeData(color: AppColors.brandStart),
      unselectedIconTheme: const IconThemeData(color: AppColors.labels),
      selectedLabelTextStyle: AppTypography.textTheme(AppColors.brandStart)
          .labelMedium,
      unselectedLabelTextStyle: AppTypography.textTheme(AppColors.labels)
          .labelMedium,
      indicatorColor: AppColors.orangePillSurface,
      useIndicator: true,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
      minVerticalPadding: AppSpacing.x2,
      iconColor: AppColors.brandStart,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      titleTextStyle: AppTypography.textTheme(AppColors.textPrimary).bodyMedium,
      subtitleTextStyle: AppTypography.textTheme(AppColors.textSecondary)
          .bodySmall,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: AppColors.card,
      showDragHandle: true,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      titleTextStyle: AppTypography.textTheme(AppColors.textPrimary).titleLarge,
      contentTextStyle: AppTypography.textTheme(AppColors.textSecondary)
          .bodyMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: AppTypography.textTheme(Colors.white).bodyMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      insetPadding: const EdgeInsets.all(AppSpacing.x4),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) => states.contains(WidgetState.selected)
            ? AppColors.brandStart
            : AppColors.labels,
      ),
      trackColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) => states.contains(WidgetState.selected)
            ? AppColors.orangePillSurface
            : AppColors.mutedSurface,
      ),
      trackOutlineColor: WidgetStatePropertyAll<Color>(AppColors.border),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),
  );
}
