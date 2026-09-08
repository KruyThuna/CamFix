import 'package:flutter/material.dart';

/// Central place for all colors, gradients and text styles used across
/// the CAM FIX app so every screen stays visually consistent.
///
/// [AppColors] holds the fixed brand palette (blues, cyan, accent colors)
/// that is identical in light and dark mode. Surface / text / border colors
/// that must flip between light and dark live in [AppPalette] and are read
/// from the theme via `context.pal`.
class AppColors {
  AppColors._();

  static const Color primaryBlue = Color(0xFF1B34FF);
  static const Color deepBlue = Color(0xFF1229E0);
  static const Color cyan = Color(0xFF17D2F0);
  static const Color darkButton = Color(0xFF0B0C1F);
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF5F6FA);
  static const Color hintGrey = Color(0xFF8C90A6);
  static const Color textDark = Color(0xFF16182B);
  static const Color success = Color(0xFF2ECC71);
  static const Color chipBg = Color(0xFFEFF1FA);

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [deepBlue, primaryBlue],
  );
}

/// Theme-dependent surface / text / border colors. Read with `context.pal`.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.shadow,
  });

  /// Scaffold / full-bleed panel background.
  final Color background;

  /// Card / sheet background.
  final Color surface;

  /// Subtle fills: chips, icon bubbles, input backgrounds.
  final Color surfaceAlt;

  /// Primary body text.
  final Color textPrimary;

  /// Secondary / hint text.
  final Color textSecondary;

  /// Hairline borders and dividers.
  final Color border;

  /// Elevation shadow color.
  final Color shadow;

  static const AppPalette light = AppPalette(
    background: Color(0xFFF5F6FA),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEFF1FA),
    textPrimary: Color(0xFF16182B),
    textSecondary: Color(0xFF8C90A6),
    border: Color(0x14000000),
    shadow: Color(0x14000000),
  );

  static const AppPalette dark = AppPalette(
    background: Color(0xFF0F1017),
    surface: Color(0xFF1A1C29),
    surfaceAlt: Color(0xFF262A3D),
    textPrimary: Color(0xFFEDEEF5),
    textSecondary: Color(0xFF9195AD),
    border: Color(0x1FFFFFFF),
    shadow: Color(0x40000000),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? shadow,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension AppPaletteX on BuildContext {
  /// Theme-dependent surface / text / border colors for the current brightness.
  AppPalette get pal =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

class AppText {
  AppText._();

  static const String fontFamily = 'Roboto';

  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.white,
    height: 1.15,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.white,
    height: 1.4,
  );

  static const TextStyle bodyDark = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _base(Brightness.light, AppPalette.light);
  static ThemeData get dark => _base(Brightness.dark, AppPalette.dark);

  static ThemeData _base(Brightness brightness, AppPalette pal) {
    final base = ThemeData(brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: pal.background,
      canvasColor: pal.background,
      primaryColor: AppColors.primaryBlue,
      cardColor: pal.surface,
      dividerColor: pal.border,
      fontFamily: AppText.fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        primary: AppColors.primaryBlue,
        brightness: brightness,
        surface: pal.surface,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: AppText.fontFamily,
        bodyColor: pal.textPrimary,
        displayColor: pal.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(backgroundColor: pal.surface),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: pal.surface),
      extensions: [pal],
    );
  }
}
