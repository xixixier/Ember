import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import 'package:ember/core/constants/emotions.dart';
import 'package:ember/core/services/ai_api_service.dart';
import 'transform_engine.dart';

/// 反向鸡汤引擎
/// 优先使用 AI API；未配置时回退到本地模板
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
        print('[DarkSoupEngine] API 调用失败: $e');
        if (st != null) print(st);
        // 失败则回退本地
      }
    }

    // 本地模板回退
    await _loadData();
    final templatesMap = _data!['templates'] as Map<String, dynamic>;
    final pool = (templatesMap[emotion.name] as List?)?.cast<String>() ??
        (templatesMap['custom'] as List?)?.cast<String>() ??
        ['你的感受是真实的。'];
    final rng = Random();
    final offset = intensity >= 4 ? pool.length ~/ 3 : 0;
    final availableLen = pool.length - offset;
    final index = offset + rng.nextInt(availableLen > 0 ? availableLen : 1);
    final selected = pool[index.clamp(0, pool.length - 1)];
    return TransformResult(type: type, content: selected);
  }

  String _buildSystemPrompt(Emotion emotion, int intensity) {
    final intensityDesc = intensity <= 2 ? '低烈度' : intensity <= 3 ? '中等烈度' : '高烈度';

    return '''你是一位擅长反向治愈的智者，你的风格是「毒鸡汤」——看似消极，实则让人会心一笑，甚至从另一个角度获得解脱。

用户正在经历「${emotion.label}」情绪，烈度 $intensity/5（$intensityDesc）。

请将用户的情绪文字转化为一段反向鸡汤，要求：
1. 1-3句话，简洁有力
2. 用反讽、黑色幽默或意想不到的视角
3. 不要说教，不要强行正能量
4. 让人感觉"被理解"，而不是"被劝慰"
5. 只输出这段话本身，不加任何解释

示例：「人生本来就不公平，你现在愤怒，说明你还对它有期待——那挺好的。」''';
  }
}
