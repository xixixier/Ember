import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  /// 引导语字体 — Cinematic
  static TextStyle get guideText => GoogleFonts.inter(
        textStyle: const TextStyle(
          fontSize: 16,
          fontStyle: FontStyle.italic,
          height: 1.6,
          letterSpacing: 0.2,
        ),
      );

  /// 正文大字输入 — Inter, borderless cursor focus
  static TextStyle get inputText => GoogleFonts.inter(
        textStyle: const TextStyle(
          fontSize: 18,
          height: 1.55,
          fontWeight: FontWeight.w300,
        ),
      );

  /// 正文提示文字 (Ash Grey whisper)
  static TextStyle get inputHint => GoogleFonts.inter(
        textStyle: const TextStyle(
          fontSize: 18,
          height: 1.55,
          fontWeight: FontWeight.w300,
        ),
      );

  /// 按钮
  static TextStyle get button => GoogleFonts.inter(
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );

  /// 卡片标题
  static TextStyle get cardTitle => GoogleFonts.inter(
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      );

  /// 卡片正文
  static TextStyle get cardBody => GoogleFonts.inter(
        textStyle: const TextStyle(
          fontSize: 13,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
      );

  /// 次要标签
  static TextStyle get caption => GoogleFonts.inter(
        textStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.3,
        ),
      );

  /// 转化结果 — 莎翁风格
  static TextStyle get shakespeare => GoogleFonts.inter(
        textStyle: const TextStyle(
          fontSize: 16,
          height: 1.7,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.3,
        ),
      );

  /// 转化结果 — 俳句风格
  static TextStyle get haiku => GoogleFonts.inter(
        textStyle: const TextStyle(
          fontSize: 18,
          height: 2.0,
          fontWeight: FontWeight.w300,
          letterSpacing: 1.0,
        ),
      );

  /// 构建 TextTheme（融入 ThemeData）
  static TextTheme buildTextTheme(ColorScheme colorScheme) {
    final base = GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        textStyle: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w300,
          height: 1.2,
          letterSpacing: -0.02,
          color: colorScheme.onSurface,
        ),
      ),
      displayMedium: GoogleFonts.inter(
        textStyle: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w300,
          height: 1.25,
          letterSpacing: -0.02,
          color: colorScheme.onSurface,
        ),
      ),
      headlineMedium: GoogleFonts.inter(
        textStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          height: 1.33,
          letterSpacing: 0.01,
          color: colorScheme.onSurface,
        ),
      ),
      titleLarge: GoogleFonts.inter(
        textStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      bodyLarge: GoogleFonts.inter(
        textStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w300,
          height: 1.55,
          letterSpacing: 0.01,
          color: colorScheme.onSurface,
        ),
      ),
      bodyMedium: GoogleFonts.inter(
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
          letterSpacing: 0.01,
          color: colorScheme.onSurface,
        ),
      ),
      labelLarge: GoogleFonts.inter(
        textStyle: TextStyle(
          fontSize: 12, // label-caps
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.33,
          color: colorScheme.onSurface,
        ),
      ),
      labelSmall: GoogleFonts.inter(
        textStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.3,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      bodySmall: GoogleFonts.inter(
        textStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.38,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
    return base;
  }
}
