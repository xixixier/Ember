import 'package:flutter/material.dart';

enum Emotion {
  anger('愤怒', '😤', '#E24B4A'),
  depression('沮丧', '😞', '#5F5E5A'),
  anxiety('焦虑', '😰', '#7F77DD'),
  breakdown('崩溃', '🤯', '#D85A30'),
  irritation('烦躁', '😒', '#BA7517'),
  custom('自定义', '🎭', '#534AB7');

  final String label;
  final String emoji;
  final String colorHex;
  const Emotion(this.label, this.emoji, this.colorHex);

  /// 从 name 字符串反查枚举
  static Emotion fromName(String name) {
    return Emotion.values.firstWhere(
      (e) => e.name == name,
      orElse: () => Emotion.custom,
    );
  }

  /// 获取 Color 对象
  Color get color => Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
}
