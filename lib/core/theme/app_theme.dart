import 'package:flutter/material.dart';
import 'color_tokens.dart';
import 'ember_theme_extension.dart';
import 'typography.dart';

class AppTheme {
  static ThemeData get dark => _buildTheme(
    themeName: 'dark',
    surface: ColorTokens.darkSurface,
    surfaceVariant: ColorTokens.darkSurfaceVariant,
    primary: ColorTokens.darkPrimary,
    accent: ColorTokens.darkAccent,
    textPrimary: ColorTokens.darkTextPrimary,
    textSecondary: ColorTokens.darkTextSecondary,
    border: ColorTokens.darkBorder,
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
      scaffoldBackgroundColor: surface,
      colorScheme: colorScheme,
      extensions: [EmberThemeExtension.forTheme(themeName)],
      textTheme: AppTypography.buildTextTheme(colorScheme),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surfaceVariant,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 0.5),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: border,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: primary.withValues(alpha: 0.2),
        labelStyle: TextStyle(color: textPrimary),
        side: BorderSide(color: border, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(color: textSecondary, fontSize: 11),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
