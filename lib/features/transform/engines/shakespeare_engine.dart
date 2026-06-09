import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import 'package:ember/core/constants/emotions.dart';
import 'package:ember/core/services/ai_api_service.dart';
import 'transform_engine.dart';

/// 莎翁剧场引擎
/// 优先使用 AI API；未配置时回退到本地词典模板
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
    // 尝试 AI 生成
    final api = AiApiService.instance;
    await api.loadSettings();
    if (api.isConfigured) {
      try {
        final content = await api.chat(
          systemPrompt: _buildSystemPrompt(emotion, intensity),
          userMessage: text,
        );
        return TransformResult(type: type, content: content);
      } catch (e, st) {
        // API 失败时打印错误到控制台，方便调试；然后回退本地
        // ignore: avoid_print
        print('[ShakespeareEngine] API 调用失败: $e');
        if (st != null) print(st);
        // 失败则回退本地
      }
    }

    // 本地模板回退
    await _loadTemplates();
    final emotionWord = _emotionMap![emotion.name] ?? '哀怨';
    final targetWord = _inferTarget(text) ?? _targetMap!['none']!;
    final rng = Random();
    final pool = _templates!;
    final offset = intensity > 3 ? pool.length ~/ 2 : 0;
    final template = pool[offset + rng.nextInt(pool.length - offset)];
    final result = template
        .replaceAll('{emotion}', emotionWord)
        .replaceAll('{target}', targetWord);
    return TransformResult(type: type, content: result);
  }

  String _buildSystemPrompt(Emotion emotion, int intensity) {
    final intensityDesc = intensity <= 2
        ? '低烈度（平静克制）'
        : intensity <= 3
            ? '中等烈度（情绪充沛）'
            : '高烈度（激烈沸腾）';

    return '''你是一位精通莎士比亚风格的创作者，擅长将现代情绪用戏剧性的古典语言重新演绎。

用户正在经历「${emotion.label}」情绪，烈度为 $intensity/5（$intensityDesc）。

请将用户的情绪文字转化为莎翁剧场风格的独白，要求：
1. 使用"汝"、"吾"等古典人称，融入诗意的隐喻和比喻
2. 2-4句话，语言华丽但不晦涩
3. 契合情绪的烈度，烈度高时更激昂，低时更忧郁克制
4. 只输出转化后的文字，不加解释

示例：「汝之愤怒如烈火焚城，然此城终将在灰烬中重生」''';
  }

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
