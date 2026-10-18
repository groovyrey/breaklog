import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// BreakLog's palette is "blackout crimson": pure black canvas, near-black
/// surfaces, hairline dividers, and one red signal accent. Display type is
/// condensed (broadcast/crew flyer register); body runs on Inter.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0D0D0D);
  static const Color surfaceVariant = Color(0xFF161616);
  static const Color onSurface = Color(0xFFFAFAFA);
  static const Color onSurfaceVariant = Color(0xFFA3A3A3);
  static const Color outline = Color(0xFF262626);
  static const Color error = Color(0xFFF87171);

  static const Color accent = Color(0xFFE53935);
  static const Color onAccent = Color(0xFFFFFFFF);
  static const Color accentSoft = Color(0xFF2A0E0C);
}

class AppRadius {
  AppRadius._();

  static const double card = 14;
  static const double control = 12;
  static const double field = 10;
  static const double chip = 999;
}

ThemeData buildDarkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      primaryContainer: AppColors.accentSoft,
      onPrimaryContainer: AppColors.onSurface,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      secondaryContainer: AppColors.accentSoft,
      onSecondaryContainer: AppColors.onSurface,
      surface: AppColors.surface,
      surfaceContainerHighest: AppColors.surfaceVariant,
      error: AppColors.error,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      onError: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
    dividerColor: AppColors.outline,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
  return _applyComponentThemes(
    base.copyWith(textTheme: buildAppTextTheme(base.textTheme)),
  );
}

ThemeData _applyComponentThemes(ThemeData theme) {
  return theme.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.onSurface,
      iconTheme: IconThemeData(color: AppColors.onSurfaceVariant),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.accentSoft,
      height: 68,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.accent : AppColors.onSurfaceVariant,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.accent : AppColors.onSurfaceVariant,
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceVariant,
      contentTextStyle: const TextStyle(color: AppColors.onSurface),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.outline, thickness: 1),
  );
}

TextTheme buildAppTextTheme(TextTheme base) {
  final display = GoogleFonts.barlowCondensedTextTheme(base);
  final body = GoogleFonts.interTextTheme(base);
  return display.copyWith(
    displayLarge: display.displayLarge?.copyWith(
      fontSize: 56,
      fontWeight: FontWeight.w800,
      height: 0.95,
      letterSpacing: -0.01,
    ),
    headlineMedium: display.headlineMedium?.copyWith(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      height: 1.0,
      letterSpacing: -0.01,
    ),
    headlineSmall: display.headlineSmall?.copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.05,
    ),
    titleLarge: display.titleLarge?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.1,
    ),
    titleMedium: display.titleMedium?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.25,
    ),
    bodyLarge: body.bodyLarge?.copyWith(fontSize: 15, height: 1.6),
    bodyMedium: body.bodyMedium?.copyWith(
      fontSize: 13,
      height: 1.55,
      color: AppColors.onSurfaceVariant,
    ),
    bodySmall: body.bodySmall?.copyWith(fontSize: 12, height: 1.4),
    titleSmall: body.titleSmall?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
    labelSmall: body.labelSmall?.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 2.0,
      color: AppColors.onSurfaceVariant,
    ),
    labelMedium: body.labelMedium?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    ),
  );
}

extension AppThemeX on BuildContext {
  Color get appSurface => AppColors.surface;
  Color get appBackground => AppColors.background;
  Color get appOnSurface => AppColors.onSurface;
  Color get appOnSurfaceVariant => AppColors.onSurfaceVariant;
  Color get appSurfaceVariant => AppColors.surfaceVariant;
  Color get appAccent => AppColors.accent;
  Color get appAccentSoft => AppColors.accentSoft;
  Color get appOnAccent => AppColors.onAccent;
  Color get appOutline => AppColors.outline;
  TextTheme get appTextTheme => Theme.of(this).textTheme;
}
