import 'package:flutter/material.dart';

enum Emotion {
  anger('愤怒', '😤', '#8C3A32'),
  depression('沮丧', '😞', '#5C6570'),
  anxiety('焦虑', '😰', '#6A6488'),
  breakdown('崩溃', '🤯', '#6E3038'),
  irritation('烦躁', '😒', '#8A6840'),
  custom('自定义', '🎭', '#6A6258');

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
