import 'package:flutter/material.dart';

import 'package:ember/core/constants/emotions.dart';

/// 转化类型
enum TransformType {
  shakespeare('莎翁剧场', '🎭'),
  haiku('俳句', '🎋'),
  darkSoup('反向鸡汤', '🍲'),
  art('抽象画', '🎨');

  final String label;
  final String emoji;
  const TransformType(this.label, this.emoji);
}

/// 转化结果
class TransformResult {
  final TransformType type;
  final String content;
  final Color? dominantColor;

  const TransformResult({
    required this.type,
    required this.content,
    this.dominantColor,
  });
}

/// 转化引擎抽象接口
abstract class TransformEngine {
  TransformType get type;

  /// 执行转化
  /// [text] 原始文本
  /// [emotion] 情绪标签
  /// [intensity] 烈度 1-5
  Future<TransformResult> transform(
    String text,
    Emotion emotion,
    int intensity,
  );
}
