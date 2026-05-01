import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  /// 引导语字体 — Playfair Display，衬线体，典雅感
  static TextStyle get guideText => GoogleFonts.playfairDisplay(
        textStyle: const TextStyle(
          fontSize: 16,
          fontStyle: FontStyle.italic,
          height: 1.6,
          letterSpacing: 0.2,
        ),
      );

  /// 正文大字输入 — Noto Sans SC，清晰大字号
  static TextStyle get inputText => GoogleFonts.notoSansSc(
        textStyle: const TextStyle(
          fontSize: 18,
          height: 1.8,
          fontWeight: FontWeight.w400,
        ),
      );

  /// 正文提示文字
  static TextStyle get inputHint => GoogleFonts.notoSansSc(
        textStyle: const TextStyle(
          fontSize: 18,
          height: 1.8,
          fontWeight: FontWeight.w300,
        ),
      );

  /// 按钮
  static TextStyle get button => GoogleFonts.notoSansSc(
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );

  /// 卡片标题
  static TextStyle get cardTitle => GoogleFonts.notoSansSc(
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      );

  /// 卡片正文
  static TextStyle get cardBody => GoogleFonts.notoSansSc(
        textStyle: const TextStyle(
          fontSize: 13,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
      );

  /// 次要标签
  static TextStyle get caption => GoogleFonts.notoSansSc(
        textStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.3,
        ),
      );

  /// 转化结果 — 莎翁风格
  static TextStyle get shakespeare => GoogleFonts.playfairDisplay(
        textStyle: const TextStyle(
          fontSize: 16,
          height: 1.7,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.3,
        ),
      );

  /// 转化结果 — 俳句风格
  static TextStyle get haiku => GoogleFonts.notoSerifSc(
        textStyle: const TextStyle(
          fontSize: 18,
          height: 2.0,
          fontWeight: FontWeight.w300,
          letterSpacing: 1.0,
        ),
      );

  /// 构建 TextTheme（融入 ThemeData）
  static TextTheme buildTextTheme(ColorScheme colorScheme) {
    final base = GoogleFonts.notoSansScTextTheme().copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
        textStyle: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        textStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.8,
        color: colorScheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: colorScheme.onSurface,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
        color: colorScheme.onSurfaceVariant,
      ),
    );
    return base;
  }
}
