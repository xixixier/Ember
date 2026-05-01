import 'package:flutter/material.dart';

/// Ember 自定义主题扩展
///
/// 包含 DESIGN.md 中定义但 ColorScheme 未覆盖的语义色：
/// - 情绪色 (8 种低饱和)
/// - 转化类型色 (4 种)
/// - 余烬系统色
/// - 文本层级
/// - 热力图/词云专用色
class EmberThemeExtension extends ThemeExtension<EmberThemeExtension> {
  // ─── 情绪色 (DESIGN.md §4.3) ─────────────────────────────────────────
  final Color angerColor;
  final Color depressionColor;
  final Color anxietyColor;
  final Color grievanceColor;
  final Color irritationColor;
  final Color breakdownColor;
  final Color numbColor;
  final Color calmColor;

  // ─── 转化类型色 ───────────────────────────────────────────────────────
  final Color shakespeareBg;
  final Color shakespeareBorder;
  final Color shakespeareTitle;
  final Color shakespeareText;

  final Color haikuBg;
  final Color haikuBorder;
  final Color haikuTitle;
  final Color haikuText;

  final Color darkSoupBg;
  final Color darkSoupBorder;
  final Color darkSoupTitle;
  final Color darkSoupText;

  final Color artBg;
  final Color artBorder;
  final Color artTitle;

  // ─── 转化类型色 — 简化版 (用于 TransformCard) ───────────────────────
  final Color shakespeareAccent;
  final Color haikuAccent;
  final Color darkSoupAccent;
  final Color artAccent;

  // ─── 余烬系统色 (DESIGN.md §4.2) ────────────────────────────────────
  final Color emberGold;
  final Color copperColor;
  final Color fireOrange;
  final Color darkRedOrange;

  // ─── 文本层级 (DESIGN.md §4.4) ───────────────────────────────────────
  final Color textWeak;
  final Color textDisabled;

  // ─── 热力图专用 ─────────────────────────────────────────────────────
  final Color heatMapHeader;
  final Color heatMapDayText;
  final Color heatMapEmpty;
  final Color heatMapSelectedBorder;

  // ─── 引导页色 ────────────────────────────────────────────────────────
  final Color onboardingWelcome;
  final Color onboardingThrow;
  final Color onboardingTransform;
  final Color onboardingDestroy;

  const EmberThemeExtension({
    // 情绪色
    required this.angerColor,
    required this.depressionColor,
    required this.anxietyColor,
    required this.grievanceColor,
    required this.irritationColor,
    required this.breakdownColor,
    required this.numbColor,
    required this.calmColor,
    // 莎翁
    required this.shakespeareBg,
    required this.shakespeareBorder,
    required this.shakespeareTitle,
    required this.shakespeareText,
    // 俳句
    required this.haikuBg,
    required this.haikuBorder,
    required this.haikuTitle,
    required this.haikuText,
    // 反向鸡汤
    required this.darkSoupBg,
    required this.darkSoupBorder,
    required this.darkSoupTitle,
    required this.darkSoupText,
    // 抽象画
    required this.artBg,
    required this.artBorder,
    required this.artTitle,
    // 简化版
    required this.shakespeareAccent,
    required this.haikuAccent,
    required this.darkSoupAccent,
    required this.artAccent,
    // 余烬系统色
    required this.emberGold,
    required this.copperColor,
    required this.fireOrange,
    required this.darkRedOrange,
    // 文本层级
    required this.textWeak,
    required this.textDisabled,
    // 热力图
    required this.heatMapHeader,
    required this.heatMapDayText,
    required this.heatMapEmpty,
    required this.heatMapSelectedBorder,
    // 引导页
    required this.onboardingWelcome,
    required this.onboardingThrow,
    required this.onboardingTransform,
    required this.onboardingDestroy,
  });

  /// 从主题名构建对应的扩展色
  static EmberThemeExtension forTheme(String themeName) {
    return switch (themeName) {
      'warmGray' => _warmGray,
      'deepBlue' => _deepBlue,
      'pureBlack' => _pureBlack,
      _ => _dark,
    };
  }

  // ─── Dark Flame 主题 ─────────────────────────────────────────────────
  static const _dark = EmberThemeExtension(
    // 情绪色
    angerColor: Color(0xFFC84040),
    depressionColor: Color(0xFF506878),
    anxietyColor: Color(0xFF7F77DD),
    grievanceColor: Color(0xFFB0909A),
    irritationColor: Color(0xFFC8956C),
    breakdownColor: Color(0xFF6B3A6B),
    numbColor: Color(0xFF5F5A55),
    calmColor: Color(0xFF5A7A6A),
    // 莎翁
    shakespeareBg: Color(0xFF2A2520),
    shakespeareBorder: Color(0xFF8B6914),
    shakespeareTitle: Color(0xFFD4A574),
    shakespeareText: Color(0xFFF0EBE3),
    // 俳句
    haikuBg: Color(0xFF1A2A20),
    haikuBorder: Color(0xFF2E7D4F),
    haikuTitle: Color(0xFF6DB889),
    haikuText: Color(0xFFE0EDE3),
    // 反向鸡汤
    darkSoupBg: Color(0xFF251A2A),
    darkSoupBorder: Color(0xFF7B4F8A),
    darkSoupTitle: Color(0xFFB88ADB),
    darkSoupText: Color(0xFFE8DCF0),
    // 抽象画
    artBg: Color(0xFF2A1A15),
    artBorder: Color(0xFFC75B39),
    artTitle: Color(0xFFE8915A),
    // 简化版
    shakespeareAccent: Color(0xFF8B6914),
    haikuAccent: Color(0xFF2E7D4F),
    darkSoupAccent: Color(0xFF7B4F8A),
    artAccent: Color(0xFFC75B39),
    // 余烬系统色
    emberGold: Color(0xFFF2B56B),
    copperColor: Color(0xFFC9824A),
    fireOrange: Color(0xFFFF8A4C),
    darkRedOrange: Color(0xFFA9472B),
    // 文本层级
    textWeak: Color(0xFF5F5A55),
    textDisabled: Color(0xFF3A3530),
    // 热力图
    heatMapHeader: Color(0x89FFFFFF), // white54
    heatMapDayText: Color(0xB3FFFFFF), // white70
    heatMapEmpty: Color(0x0AFFFFFF), // white04
    heatMapSelectedBorder: Color(0xFFFFFFFF), // white
    // 引导页
    onboardingWelcome: Color(0xFFE8915A),
    onboardingThrow: Color(0xFFFF9800),
    onboardingTransform: Color(0xFF6EA4BF),
    onboardingDestroy: Color(0xFFE24B4A),
  );

  // ─── Warm Gray 主题 ─────────────────────────────────────────────────
  static const _warmGray = EmberThemeExtension(
    angerColor: Color(0xFFB06050),
    depressionColor: Color(0xFF607068),
    anxietyColor: Color(0xFF8A80C0),
    grievanceColor: Color(0xFFB09898),
    irritationColor: Color(0xFFC89870),
    breakdownColor: Color(0xFF7A5A6A),
    numbColor: Color(0xFF706A62),
    calmColor: Color(0xFF6A8070),
    // 莎翁
    shakespeareBg: Color(0xFF302A22),
    shakespeareBorder: Color(0xFF9A7A3A),
    shakespeareTitle: Color(0xFFD8B080),
    shakespeareText: Color(0xFFF0EBE0),
    // 俳句
    haikuBg: Color(0xFF222A22),
    haikuBorder: Color(0xFF4A8A60),
    haikuTitle: Color(0xFF78B090),
    haikuText: Color(0xFFD8E8D8),
    // 反向鸡汤
    darkSoupBg: Color(0xFF2A2028),
    darkSoupBorder: Color(0xFF886A98),
    darkSoupTitle: Color(0xFFC09AD0),
    darkSoupText: Color(0xFFE8DCF0),
    // 抽象画
    artBg: Color(0xFF2E2020),
    artBorder: Color(0xFFC07050),
    artTitle: Color(0xFFD4A080),
    // 简化版
    shakespeareAccent: Color(0xFF9A7A3A),
    haikuAccent: Color(0xFF4A8A60),
    darkSoupAccent: Color(0xFF886A98),
    artAccent: Color(0xFFC07050),
    // 余烬系统色
    emberGold: Color(0xFFD4A060),
    copperColor: Color(0xFFB88A50),
    fireOrange: Color(0xFFE0A060),
    darkRedOrange: Color(0xFFA06040),
    // 文本层级
    textWeak: Color(0xFF6A645C),
    textDisabled: Color(0xFF4A453E),
    // 热力图
    heatMapHeader: Color(0x89F0EBE3),
    heatMapDayText: Color(0xB3F0EBE3),
    heatMapEmpty: Color(0x0AF0EBE3),
    heatMapSelectedBorder: Color(0xFFF0EBE3),
    // 引导页
    onboardingWelcome: Color(0xFFD4A574),
    onboardingThrow: Color(0xFFC8956C),
    onboardingTransform: Color(0xFF8A98A0),
    onboardingDestroy: Color(0xFFB8705A),
  );

  // ─── Deep Blue 主题 ─────────────────────────────────────────────────
  static const _deepBlue = EmberThemeExtension(
    angerColor: Color(0xFFB85050),
    depressionColor: Color(0xFF5A7888),
    anxietyColor: Color(0xFF8890C8),
    grievanceColor: Color(0xFF9890A8),
    irritationColor: Color(0xFFA89870),
    breakdownColor: Color(0xFF6058A8),
    numbColor: Color(0xFF586878),
    calmColor: Color(0xFF587888),
    // 莎翁
    shakespeareBg: Color(0xFF18222A),
    shakespeareBorder: Color(0xFF708898),
    shakespeareTitle: Color(0xFFA0B8C8),
    shakespeareText: Color(0xFFE0E8F0),
    // 俳句
    haikuBg: Color(0xFF122028),
    haikuBorder: Color(0xFF3A8878),
    haikuTitle: Color(0xFF68B0A0),
    haikuText: Color(0xFFD0E8E0),
    // 反向鸡汤
    darkSoupBg: Color(0xFF201828),
    darkSoupBorder: Color(0xFF7868A0),
    darkSoupTitle: Color(0xFFA890C8),
    darkSoupText: Color(0xFFE0D8F0),
    // 抽象画
    artBg: Color(0xFF281820),
    artBorder: Color(0xFFA06858),
    artTitle: Color(0xFFC89888),
    // 简化版
    shakespeareAccent: Color(0xFF708898),
    haikuAccent: Color(0xFF3A8878),
    darkSoupAccent: Color(0xFF7868A0),
    artAccent: Color(0xFFA06858),
    // 余烬系统色
    emberGold: Color(0xFFB8A878),
    copperColor: Color(0xFF8898A8),
    fireOrange: Color(0xFF88A0B8),
    darkRedOrange: Color(0xFF785848),
    // 文本层级
    textWeak: Color(0xFF5A6878),
    textDisabled: Color(0xFF2A3A4A),
    // 热力图
    heatMapHeader: Color(0x89E0E8F0),
    heatMapDayText: Color(0xB3E0E8F0),
    heatMapEmpty: Color(0x0AE0E8F0),
    heatMapSelectedBorder: Color(0xFFE0E8F0),
    // 引导页
    onboardingWelcome: Color(0xFF6EA4BF),
    onboardingThrow: Color(0xFF8AB0C8),
    onboardingTransform: Color(0xFF7898B0),
    onboardingDestroy: Color(0xFFB8706A),
  );

  // ─── Pure Black 主题 ────────────────────────────────────────────────
  static const _pureBlack = EmberThemeExtension(
    angerColor: Color(0xFFE24B4A),
    depressionColor: Color(0xFF5A7080),
    anxietyColor: Color(0xFF8888DD),
    grievanceColor: Color(0xFFB898A8),
    irritationColor: Color(0xFFD4A050),
    breakdownColor: Color(0xFF7040A0),
    numbColor: Color(0xFF606060),
    calmColor: Color(0xFF40A080),
    // 莎翁
    shakespeareBg: Color(0xFF1A1610),
    shakespeareBorder: Color(0xFFA07820),
    shakespeareTitle: Color(0xFFE8C080),
    shakespeareText: Color(0xFFF8F0E8),
    // 俳句
    haikuBg: Color(0xFF10201A),
    haikuBorder: Color(0xFF30A060),
    haikuTitle: Color(0xFF80D0A0),
    haikuText: Color(0xFFE0F8E8),
    // 反向鸡汤
    darkSoupBg: Color(0xFF1A1020),
    darkSoupBorder: Color(0xFFA060C0),
    darkSoupTitle: Color(0xFFD0A0E8),
    darkSoupText: Color(0xFFF0E0F8),
    // 抽象画
    artBg: Color(0xFF201410),
    artBorder: Color(0xFFE86840),
    artTitle: Color(0xFFFF8A65),
    // 简化版
    shakespeareAccent: Color(0xFFA07820),
    haikuAccent: Color(0xFF30A060),
    darkSoupAccent: Color(0xFFA060C0),
    artAccent: Color(0xFFE86840),
    // 余烬系统色
    emberGold: Color(0xFFFFB040),
    copperColor: Color(0xFFD88840),
    fireOrange: Color(0xFFFF6B22),
    darkRedOrange: Color(0xFFC04020),
    // 文本层级
    textWeak: Color(0xFF606060),
    textDisabled: Color(0xFF333333),
    // 热力图
    heatMapHeader: Color(0x89ECECEC),
    heatMapDayText: Color(0xB3ECECEC),
    heatMapEmpty: Color(0x0AECECEC),
    heatMapSelectedBorder: Color(0xFFECECEC),
    // 引导页
    onboardingWelcome: Color(0xFFFF6B22),
    onboardingThrow: Color(0xFFFF8A40),
    onboardingTransform: Color(0xFF60A8D0),
    onboardingDestroy: Color(0xFFE24B4A),
  );

  @override
  EmberThemeExtension copyWith({
    Color? angerColor,
    Color? depressionColor,
    Color? anxietyColor,
    Color? grievanceColor,
    Color? irritationColor,
    Color? breakdownColor,
    Color? numbColor,
    Color? calmColor,
    Color? shakespeareBg,
    Color? shakespeareBorder,
    Color? shakespeareTitle,
    Color? shakespeareText,
    Color? haikuBg,
    Color? haikuBorder,
    Color? haikuTitle,
    Color? haikuText,
    Color? darkSoupBg,
    Color? darkSoupBorder,
    Color? darkSoupTitle,
    Color? darkSoupText,
    Color? artBg,
    Color? artBorder,
    Color? artTitle,
    Color? shakespeareAccent,
    Color? haikuAccent,
    Color? darkSoupAccent,
    Color? artAccent,
    Color? emberGold,
    Color? copperColor,
    Color? fireOrange,
    Color? darkRedOrange,
    Color? textWeak,
    Color? textDisabled,
    Color? heatMapHeader,
    Color? heatMapDayText,
    Color? heatMapEmpty,
    Color? heatMapSelectedBorder,
    Color? onboardingWelcome,
    Color? onboardingThrow,
    Color? onboardingTransform,
    Color? onboardingDestroy,
  }) {
    return EmberThemeExtension(
      angerColor: angerColor ?? this.angerColor,
      depressionColor: depressionColor ?? this.depressionColor,
      anxietyColor: anxietyColor ?? this.anxietyColor,
      grievanceColor: grievanceColor ?? this.grievanceColor,
      irritationColor: irritationColor ?? this.irritationColor,
      breakdownColor: breakdownColor ?? this.breakdownColor,
      numbColor: numbColor ?? this.numbColor,
      calmColor: calmColor ?? this.calmColor,
      shakespeareBg: shakespeareBg ?? this.shakespeareBg,
      shakespeareBorder: shakespeareBorder ?? this.shakespeareBorder,
      shakespeareTitle: shakespeareTitle ?? this.shakespeareTitle,
      shakespeareText: shakespeareText ?? this.shakespeareText,
      haikuBg: haikuBg ?? this.haikuBg,
      haikuBorder: haikuBorder ?? this.haikuBorder,
      haikuTitle: haikuTitle ?? this.haikuTitle,
      haikuText: haikuText ?? this.haikuText,
      darkSoupBg: darkSoupBg ?? this.darkSoupBg,
      darkSoupBorder: darkSoupBorder ?? this.darkSoupBorder,
      darkSoupTitle: darkSoupTitle ?? this.darkSoupTitle,
      darkSoupText: darkSoupText ?? this.darkSoupText,
      artBg: artBg ?? this.artBg,
      artBorder: artBorder ?? this.artBorder,
      artTitle: artTitle ?? this.artTitle,
      shakespeareAccent: shakespeareAccent ?? this.shakespeareAccent,
      haikuAccent: haikuAccent ?? this.haikuAccent,
      darkSoupAccent: darkSoupAccent ?? this.darkSoupAccent,
      artAccent: artAccent ?? this.artAccent,
      emberGold: emberGold ?? this.emberGold,
      copperColor: copperColor ?? this.copperColor,
      fireOrange: fireOrange ?? this.fireOrange,
      darkRedOrange: darkRedOrange ?? this.darkRedOrange,
      textWeak: textWeak ?? this.textWeak,
      textDisabled: textDisabled ?? this.textDisabled,
      heatMapHeader: heatMapHeader ?? this.heatMapHeader,
      heatMapDayText: heatMapDayText ?? this.heatMapDayText,
      heatMapEmpty: heatMapEmpty ?? this.heatMapEmpty,
      heatMapSelectedBorder: heatMapSelectedBorder ?? this.heatMapSelectedBorder,
      onboardingWelcome: onboardingWelcome ?? this.onboardingWelcome,
      onboardingThrow: onboardingThrow ?? this.onboardingThrow,
      onboardingTransform: onboardingTransform ?? this.onboardingTransform,
      onboardingDestroy: onboardingDestroy ?? this.onboardingDestroy,
    );
  }

  @override
  EmberThemeExtension lerp(covariant EmberThemeExtension? other, double t) {
    if (other is! EmberThemeExtension) return this;
    // 简化 lerp：仅对主要颜色做插值
    return EmberThemeExtension(
      angerColor: Color.lerp(angerColor, other.angerColor, t)!,
      depressionColor: Color.lerp(depressionColor, other.depressionColor, t)!,
      anxietyColor: Color.lerp(anxietyColor, other.anxietyColor, t)!,
      grievanceColor: Color.lerp(grievanceColor, other.grievanceColor, t)!,
      irritationColor: Color.lerp(irritationColor, other.irritationColor, t)!,
      breakdownColor: Color.lerp(breakdownColor, other.breakdownColor, t)!,
      numbColor: Color.lerp(numbColor, other.numbColor, t)!,
      calmColor: Color.lerp(calmColor, other.calmColor, t)!,
      shakespeareBg: Color.lerp(shakespeareBg, other.shakespeareBg, t)!,
      shakespeareBorder: Color.lerp(shakespeareBorder, other.shakespeareBorder, t)!,
      shakespeareTitle: Color.lerp(shakespeareTitle, other.shakespeareTitle, t)!,
      shakespeareText: Color.lerp(shakespeareText, other.shakespeareText, t)!,
      haikuBg: Color.lerp(haikuBg, other.haikuBg, t)!,
      haikuBorder: Color.lerp(haikuBorder, other.haikuBorder, t)!,
      haikuTitle: Color.lerp(haikuTitle, other.haikuTitle, t)!,
      haikuText: Color.lerp(haikuText, other.haikuText, t)!,
      darkSoupBg: Color.lerp(darkSoupBg, other.darkSoupBg, t)!,
      darkSoupBorder: Color.lerp(darkSoupBorder, other.darkSoupBorder, t)!,
      darkSoupTitle: Color.lerp(darkSoupTitle, other.darkSoupTitle, t)!,
      darkSoupText: Color.lerp(darkSoupText, other.darkSoupText, t)!,
      artBg: Color.lerp(artBg, other.artBg, t)!,
      artBorder: Color.lerp(artBorder, other.artBorder, t)!,
      artTitle: Color.lerp(artTitle, other.artTitle, t)!,
      shakespeareAccent: Color.lerp(shakespeareAccent, other.shakespeareAccent, t)!,
      haikuAccent: Color.lerp(haikuAccent, other.haikuAccent, t)!,
      darkSoupAccent: Color.lerp(darkSoupAccent, other.darkSoupAccent, t)!,
      artAccent: Color.lerp(artAccent, other.artAccent, t)!,
      emberGold: Color.lerp(emberGold, other.emberGold, t)!,
      copperColor: Color.lerp(copperColor, other.copperColor, t)!,
      fireOrange: Color.lerp(fireOrange, other.fireOrange, t)!,
      darkRedOrange: Color.lerp(darkRedOrange, other.darkRedOrange, t)!,
      textWeak: Color.lerp(textWeak, other.textWeak, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      heatMapHeader: Color.lerp(heatMapHeader, other.heatMapHeader, t)!,
      heatMapDayText: Color.lerp(heatMapDayText, other.heatMapDayText, t)!,
      heatMapEmpty: Color.lerp(heatMapEmpty, other.heatMapEmpty, t)!,
      heatMapSelectedBorder: Color.lerp(heatMapSelectedBorder, other.heatMapSelectedBorder, t)!,
      onboardingWelcome: Color.lerp(onboardingWelcome, other.onboardingWelcome, t)!,
      onboardingThrow: Color.lerp(onboardingThrow, other.onboardingThrow, t)!,
      onboardingTransform: Color.lerp(onboardingTransform, other.onboardingTransform, t)!,
      onboardingDestroy: Color.lerp(onboardingDestroy, other.onboardingDestroy, t)!,
    );
  }
}
