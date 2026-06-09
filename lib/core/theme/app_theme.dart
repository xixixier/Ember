import 'package:flutter/material.dart';
import 'color_tokens.dart';
import 'ember_theme_extension.dart';
import 'typography.dart';

class AppTheme {
  static ThemeData get dark => _buildTheme(
    themeName: 'dark',
    surface: ColorTokens.surface,
    surfaceVariant: ColorTokens.surfaceVariant,
    primary: ColorTokens.primaryContainer,
    accent: ColorTokens.secondary,
    textPrimary: ColorTokens.onSurface,
    textSecondary: ColorTokens.onSurfaceVariant,
    border: ColorTokens.outlineVariant,
  );

  static ThemeData get warmGray => _buildTheme(
    themeName: 'warmGray',
    surface: ColorTokens.warmGraySurface,
    surfaceVariant: ColorTokens.warmGraySurfaceVariant,
    primary: ColorTokens.warmGrayPrimary,
    accent: ColorTokens.warmGrayAccent,
    textPrimary: ColorTokens.warmGrayTextPrimary,
    textSecondary: ColorTokens.warmGrayTextSecondary,
    border: ColorTokens.warmGrayBorder,
  );

  static ThemeData get deepBlue => _buildTheme(
    themeName: 'deepBlue',
    surface: ColorTokens.deepBlueSurface,
    surfaceVariant: ColorTokens.deepBlueSurfaceVariant,
    primary: ColorTokens.deepBluePrimary,
    accent: ColorTokens.deepBlueAccent,
    textPrimary: ColorTokens.deepBlueTextPrimary,
    textSecondary: ColorTokens.deepBlueTextSecondary,
    border: ColorTokens.deepBlueBorder,
  );

  static ThemeData get pureBlack => _buildTheme(
    themeName: 'pureBlack',
    surface: ColorTokens.pureBlackSurface,
    surfaceVariant: ColorTokens.pureBlackSurfaceVariant,
    primary: ColorTokens.pureBlackPrimary,
    accent: ColorTokens.pureBlackAccent,
    textPrimary: ColorTokens.pureBlackTextPrimary,
    textSecondary: ColorTokens.pureBlackTextSecondary,
    border: ColorTokens.pureBlackBorder,
  );

  static ThemeData _buildTheme({
    required String themeName,
    required Color surface,
    required Color surfaceVariant,
    required Color primary,
    required Color accent,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
  }) {
    final colorScheme = ColorScheme.dark(
      surface: surface,
      surfaceContainerHighest: surfaceVariant,
      primary: primary,
      secondary: accent,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: border,
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ColorTokens.background, // #1b110d Deep Dark
      colorScheme: colorScheme,
      extensions: [EmberThemeExtension.forTheme(themeName)],
      textTheme: AppTypography.buildTextTheme(colorScheme),
      appBarTheme: AppBarTheme(
        backgroundColor: ColorTokens.background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surfaceVariant.withValues(alpha: 0.8), // Semi-transparent for glassmorphism
        elevation: 0, // No shadows
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32), // 2rem / 32px rounded corners
          side: BorderSide(color: ColorTokens.onSurface.withValues(alpha: 0.1), width: 1.0), // 1px solid micro-border at 10% opacity
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceVariant.withValues(alpha: 0.9), // Glassmorphism base
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary, // Soft-pulsing Ember Orange
        selectionColor: primary.withValues(alpha: 0.3),
        selectionHandleColor: primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none, // Borderless input area
        hintStyle: TextStyle(
          color: ColorTokens.onSurfaceVariant.withValues(alpha: 0.5), // Ash Grey 
          fontWeight: FontWeight.w300, // 300 weight like a whisper
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: border,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant.withValues(alpha: 0.5),
        selectedColor: primary.withValues(alpha: 0.2),
        labelStyle: TextStyle(color: textPrimary),
        side: BorderSide(color: border, width: 0.5), // Match colored micro-border
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)), // Pill shaped tags
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ColorTokens.surfaceVariant.withValues(alpha: 0.8), // Floating translucent bar
        indicatorColor: Colors.transparent, // Ember dot instead of standard color shift
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(color: textSecondary, fontSize: 11),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: ColorTokens.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)), // Capsule
        elevation: 0, // No dark shadow, prefer soft bloom
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: ColorTokens.onPrimaryContainer,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50), // Perfect capsules
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTypography.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: ColorTokens.onSurface.withValues(alpha: 0.1), width: 1.0), // Ghost style with micro-border
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTypography.button,
        ),
      ),
    );
  }
}
