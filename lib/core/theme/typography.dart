import 'package:flutter/material.dart';

/// 安全的 Inter 字体样式
/// 不依赖 Google Fonts 网络加载，避免国内网络问题导致黑屏
TextStyle _inter({
  double? fontSize,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  double? height,
  double? letterSpacing,
  Color? color,
}) {
  return TextStyle(
    fontFamily: 'Inter',
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
  );
}

class AppTypography {
  /// 引导语字体 — Cinematic
  static TextStyle get guideText => _inter(
        fontSize: 16,
        fontStyle: FontStyle.italic,
        height: 1.6,
        letterSpacing: 0.2,
      );

  /// 正文大字输入 — Inter, borderless cursor focus
  static TextStyle get inputText => _inter(
        fontSize: 18,
        height: 1.55,
        fontWeight: FontWeight.w300,
      );

  /// 正文提示文字 (Ash Grey whisper)
  static TextStyle get inputHint => _inter(
        fontSize: 18,
        height: 1.55,
        fontWeight: FontWeight.w300,
      );

  /// 按钮
  static TextStyle get button => _inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  /// 卡片标题
  static TextStyle get cardTitle => _inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      );

  /// 卡片正文
  static TextStyle get cardBody => _inter(
        fontSize: 13,
        height: 1.5,
        fontWeight: FontWeight.w400,
      );

  /// 次要标签
  static TextStyle get caption => _inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
      );

  /// 转化结果 — 莎翁风格
  static TextStyle get shakespeare => _inter(
        fontSize: 16,
        height: 1.7,
        fontStyle: FontStyle.italic,
        letterSpacing: 0.3,
      );

  /// 转化结果 — 俳句风格
  static TextStyle get haiku => _inter(
        fontSize: 18,
        height: 2.0,
        fontWeight: FontWeight.w300,
        letterSpacing: 1.0,
      );

  /// 构建 TextTheme（融入 ThemeData）
  static TextTheme buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: _inter(
        fontSize: 40,
        fontWeight: FontWeight.w300,
        height: 1.2,
        letterSpacing: -0.02,
        color: colorScheme.onSurface,
      ),
      displayMedium: _inter(
        fontSize: 32,
        fontWeight: FontWeight.w300,
        height: 1.25,
        letterSpacing: -0.02,
        color: colorScheme.onSurface,
      ),
      headlineMedium: _inter(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        height: 1.33,
        letterSpacing: 0.01,
        color: colorScheme.onSurface,
      ),
      titleLarge: _inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      bodyLarge: _inter(
        fontSize: 18,
        fontWeight: FontWeight.w300,
        height: 1.55,
        letterSpacing: 0.01,
        color: colorScheme.onSurface,
      ),
      bodyMedium: _inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.01,
        color: colorScheme.onSurface,
      ),
      labelLarge: _inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.33,
        color: colorScheme.onSurface,
      ),
      labelSmall: _inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
        color: colorScheme.onSurfaceVariant,
      ),
      bodySmall: _inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.38,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
