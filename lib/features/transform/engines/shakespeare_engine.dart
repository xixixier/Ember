import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import 'package:ember/core/constants/emotions.dart';
import 'transform_engine.dart';

/// 莎翁剧场引擎
/// 本地词典映射 + 模板填充
class ShakespeareEngine extends TransformEngine {
  @override
  TransformType get type => TransformType.shakespeare;

  List<String>? _templates;
  Map<String, String>? _emotionMap;
  Map<String, String>? _targetMap;

  Future<void> _loadTemplates() async {
    if (_templates != null) return;
    final jsonStr = await rootBundle.loadString(
      'assets/templates/shakespeare_templates.json',
    );
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    _templates = (data['templates'] as List).cast<String>();
    _emotionMap = Map<String, String>.from(data['emotionMap'] as Map);
    _targetMap = Map<String, String>.from(data['targetMap'] as Map);
  }

  @override
  Future<TransformResult> transform(
    String text,
    Emotion emotion,
    int intensity,
  ) async {
    await _loadTemplates();

    final emotionWord = _emotionMap![emotion.name] ?? '哀怨';
    // 尝试从文本提取对象关键词
    final targetWord = _inferTarget(text) ?? _targetMap!['none']!;

    // 高烈度选更激烈的模板（后面的更激烈）
    final rng = Random();
    final pool = _templates!;
    final offset = intensity > 3 ? pool.length ~/ 2 : 0;
    final template = pool[offset + rng.nextInt(pool.length - offset)];

    final result = template
        .replaceAll('{emotion}', emotionWord)
        .replaceAll('{target}', targetWord);

    return TransformResult(
      type: type,
      content: result,
    );
  }

  /// 简单推断目标对象
  String? _inferTarget(String text) {
    final lower = text.toLowerCase();
    final mapping = <String, List<String>>{
      'work': ['工作', '老板', '同事', '加班', '公司', '上班', '领导', '任务', '会议', 'KPI'],
      'love': ['感情', '恋爱', '前任', '对象', '分手', '男朋友', '女朋友', '爱人', '他', '她'],
      'self': ['自己', '我', '没用', '废物', '不够好', '差劲', '自卑'],
      'social': ['社交', '朋友', '聚会', '圈子', '应酬', '人际关系'],
      'stranger': ['陌生人', '路人', '别人', '插队', '撞', '骂'],
      'world': ['世界', '社会', '体制', '命运', '时代', '人生', '活着'],
    };

    for (final entry in mapping.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) {
          return _targetMap![entry.key];
        }
      }
    }
    return null;
  }
}
