import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import 'package:ember/core/constants/emotions.dart';
import 'transform_engine.dart';

/// 反向鸡汤引擎
/// (emotion, intensity) 检索模板库，高烈度偏向更深刻的句子
class DarkSoupEngine extends TransformEngine {
  @override
  TransformType get type => TransformType.darkSoup;

  Map<String, dynamic>? _data;

  Future<void> _loadData() async {
    if (_data != null) return;
    final jsonStr = await rootBundle.loadString(
      'assets/templates/dark_soup_templates.json',
    );
    _data = json.decode(jsonStr) as Map<String, dynamic>;
  }

  @override
  Future<TransformResult> transform(
    String text,
    Emotion emotion,
    int intensity,
  ) async {
    await _loadData();

    final templatesMap = _data!['templates'] as Map<String, dynamic>;
    final pool = (templatesMap[emotion.name] as List?)?.cast<String>() ??
        (templatesMap['custom'] as List?)?.cast<String>() ??
        ['你的感受是真实的。'];

    final rng = Random();

    // 高烈度（4-5）从后半段选更深刻的
    final offset = intensity >= 4 ? pool.length ~/ 3 : 0;
    final availableLen = pool.length - offset;
    final index = offset + rng.nextInt(availableLen > 0 ? availableLen : 1);

    final selected = pool[index.clamp(0, pool.length - 1)];

    return TransformResult(
      type: type,
      content: selected,
    );
  }
}
