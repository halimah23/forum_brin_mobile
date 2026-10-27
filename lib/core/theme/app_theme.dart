import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_typography.dart';

/// Ekstensi Tema Flutter untuk Design Tokens khusus:
/// Oceanic Blue, Teal, dan Amber/Orange
class AppCustomTheme extends ThemeExtension<AppCustomTheme> {
  final Color primary;
  final Color primarySoft;
  final Color secondary;
  final Color secondaryStrong;
  final Color secondarySoft;
  final Color accent;
  final Color accentWarm;
  final Color accentSoft;
  final Color surfaceCard;
  final Color borderSubtle;

  const AppCustomTheme({
    required this.primary,
    required this.primarySoft,
    required this.secondary,
    required this.secondaryStrong,
    required this.secondarySoft,
    required this.accent,
    required this.accentWarm,
    required this.accentSoft,
    required this.surfaceCard,
    required this.borderSubtle,
  });

  static const light = AppCustomTheme(
    primary: AppColors.colorPrimary,
    primarySoft: AppColors.colorPrimarySoft,
    secondary: AppColors.colorSecondary,
    secondaryStrong: AppColors.colorSecondaryStrong,
    secondarySoft: AppColors.colorSecondarySoft,
    accent: AppColors.colorAccent,
    accentWarm: AppColors.colorAccentWarm,
    accentSoft: AppColors.colorAccentSoft,
    surfaceCard: AppColors.colorSurface,
    borderSubtle: AppColors.colorBorder,
  );

  @override
  ThemeExtension<AppCustomTheme> copyWith({
    Color? primary,
    Color? primarySoft,
    Color? secondary,
    Color? secondaryStrong,
    Color? secondarySoft,
    Color? accent,
    Color? accentWarm,
    Color? accentSoft,
    Color? surfaceCard,
    Color? borderSubtle,
  }) {
    return AppCustomTheme(
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      secondary: secondary ?? this.secondary,
      secondaryStrong: secondaryStrong ?? this.secondaryStrong,
      secondarySoft: secondarySoft ?? this.secondarySoft,
      accent: accent ?? this.accent,
      accentWarm: accentWarm ?? this.accentWarm,
      accentSoft: accentSoft ?? this.accentSoft,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      borderSubtle: borderSubtle ?? this.borderSubtle,
    );
  }

  @override
  ThemeExtension<AppCustomTheme> lerp(
    covariant ThemeExtension<AppCustomTheme>? other,
    double t,
  ) {
    if (other is! AppCustomTheme) return this;
    return AppCustomTheme(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t) ?? primarySoft,
      secondary: Color.lerp(secondary, other.secondary, t) ?? secondary,
      secondaryStrong: Color.lerp(secondaryStrong, other.secondaryStrong, t) ?? secondaryStrong,
      secondarySoft: Color.lerp(secondarySoft, other.secondarySoft, t) ?? secondarySoft,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      accentWarm: Color.lerp(accentWarm, other.accentWarm, t) ?? accentWarm,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t) ?? accentSoft,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t) ?? surfaceCard,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t) ?? borderSubtle,
    );
  }
}

/// Helper konfigurasi ThemeData untuk BOSDM-Connect
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Arial',
      scaffoldBackgroundColor: AppColors.colorBg,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.colorPrimary,
        onPrimary: AppColors.colorTextInverse,
        primaryContainer: AppColors.colorPrimarySoft,
        onPrimaryContainer: AppColors.colorPrimaryHover,
        secondary: AppColors.colorSecondary,
        onSecondary: AppColors.colorTextInverse,
        secondaryContainer: AppColors.colorSecondarySoft,
        onSecondaryContainer: AppColors.colorSecondaryStrong,
        tertiary: AppColors.colorAccentWarm,
        onTertiary: AppColors.colorTextInverse,
        tertiaryContainer: AppColors.colorAccentSoft,
        onTertiaryContainer: AppColors.colorAccentWarm,
        error: AppColors.error,
        onError: AppColors.colorTextInverse,
        errorContainer: AppColors.errorBackground,
        onErrorContainer: AppColors.error,
        surface: AppColors.colorSurface,
        onSurface: AppColors.colorText,
        surfaceContainerHighest: AppColors.slate100,
        outline: AppColors.colorBorder,
        outlineVariant: AppColors.slate200,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.colorSurface,
        foregroundColor: AppColors.colorText,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.colorText,
          fontSize: 17,
          fontWeight: FontWeight.bold,
          fontFamily: 'Arial',
        ),
        iconTheme: IconThemeData(color: AppColors.colorText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.colorSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.colorBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.colorBorder,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.colorSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.colorTextMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.colorBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.colorBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.colorPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.colorPrimary,
          foregroundColor: AppColors.colorTextInverse,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Arial',
          ),
        ),
      ),
      extensions: const [
        AppCustomTheme.light,
      ],
    );
  }
}
