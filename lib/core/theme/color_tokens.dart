import 'package:flutter/material.dart';

class ColorTokens {
  // Deep Dark Foundation (Ember Sanctuary)
  static const surface = Color(0xFF1B110D);
  static const surfaceVariant = Color(0xFF3F322D);
  static const surfaceBright = Color(0xFF433631);
  static const surfaceContainerLowest = Color(0xFF150C08);
  static const surfaceContainerLow = Color(0xFF241915);
  static const surfaceContainer = Color(0xFF281D19);
  static const surfaceContainerHigh = Color(0xFF332723);
  static const surfaceContainerHighest = Color(0xFF3F322D);

  static const onSurface = Color(0xFFF3DED7); // Soft Parchment
  static const onSurfaceVariant = Color(0xFFDEC0B5);
  
  static const outline = Color(0xFFA58B81);
  static const outlineVariant = Color(0xFF57423A);
  
  // Ember Glow
  static const primary = Color(0xFFFFB598);
  static const onPrimary = Color(0xFF591D00);
  static const primaryContainer = Color(0xFFE46F3A);
  static const onPrimaryContainer = Color(0xFF4E1800);
  
  static const secondary = Color(0xFFFFB781);
  static const onSecondary = Color(0xFF4E2500);
  static const secondaryContainer = Color(0xFF713B06);
  static const onSecondaryContainer = Color(0xFFF5A76B);
  
  static const tertiary = Color(0xFFFFB693);
  static const onTertiary = Color(0xFF562000);
  static const tertiaryContainer = Color(0xFFE07236);
  static const onTertiaryContainer = Color(0xFF4B1B00);
  
  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
  static const errorContainer = Color(0xFF93000A);
  static const onErrorContainer = Color(0xFFFFDAD6);

  static const background = Color(0xFF1B110D);
  static const onBackground = Color(0xFFF3DED7);

  // For backward compatibility with existing tokens (remapping to Ember design)
  static const darkSurface = surface;
  static const darkSurfaceVariant = surfaceVariant;
  static const darkPrimary = primaryContainer;
  static const darkAccent = secondary;
  static const darkTextPrimary = onSurface;
  static const darkTextSecondary = onSurfaceVariant;
  static const darkBorder = outlineVariant;
  
  static const warmGraySurface = surface;
  static const warmGraySurfaceVariant = surfaceVariant;
  static const warmGrayPrimary = primaryContainer;
  static const warmGrayAccent = secondary;
  static const warmGrayTextPrimary = onSurface;
  static const warmGrayTextSecondary = onSurfaceVariant;
  static const warmGrayBorder = outlineVariant;
  
  static const deepBlueSurface = surface;
  static const deepBlueSurfaceVariant = surfaceVariant;
  static const deepBluePrimary = primaryContainer;
  static const deepBlueAccent = secondary;
  static const deepBlueTextPrimary = onSurface;
  static const deepBlueTextSecondary = onSurfaceVariant;
  static const deepBlueBorder = outlineVariant;
  
  static const pureBlackSurface = surface;
  static const pureBlackSurfaceVariant = surfaceVariant;
  static const pureBlackPrimary = primaryContainer;
  static const pureBlackAccent = secondary;
  static const pureBlackTextPrimary = onSurface;
  static const pureBlackTextSecondary = onSurfaceVariant;
  static const pureBlackBorder = outlineVariant;

  // 烈度渐变色
  static const intensityColors = [
    Color(0xFFFFC107), // 1 - 微微不爽
    Color(0xFFFF9800), // 2
    Color(0xFFFF5722), // 3
    Color(0xFFE24B4A), // 4
    Color(0xFFB71C1C), // 5 - 爆炸
  ];

  static const intensityLabels = [
    '微微不爽',
    '有点烦',
    '挺生气的',
    '非常炸',
    '爆炸',
  ];
}
