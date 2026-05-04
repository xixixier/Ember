import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import 'package:ember/core/constants/emotions.dart';
import 'package:ember/core/services/ai_api_service.dart';
import 'transform_engine.dart';

/// 俳句生成引擎
/// 优先使用 AI API；未配置时回退到本地模板
class HaikuEngine extends TransformEngine {
  @override
  TransformType get type => TransformType.haiku;

  Map<String, dynamic>? _data;

  Future<void> _loadData() async {
    if (_data != null) return;
    final jsonStr = await rootBundle.loadString(
      'assets/templates/haiku_templates.json',
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
      } catch (_) {
        // 失败则回退本地
      }
    }

    // 本地模板回退
    await _loadData();
    final emotionWords =
        (_data!['emotionWords'] as Map<String, dynamic>)[emotion.name]
                as List? ??
            [];
    final natureWords = _data!['natureWords'] as List? ?? [];
    final intensityWords =
        (_data!['intensityWords'] as Map<String, dynamic>)[intensity.toString()]
                as List? ??
            [];
    final templates = _data!['templates'] as List? ?? [];
    final rng = Random();
    final extractedKeywords = _extractKeywords(text);
    final coreWords = _pickCore(extractedKeywords, emotionWords, rng);
    final templateStr = templates.isNotEmpty
        ? templates[rng.nextInt(templates.length)] as String
        : '{intensity}{emotionWord}——\n{nature}过{emotionWord}处\n{intensity}{nature}亦{emotionWord}';
    final emotionWord = emotionWords.isNotEmpty
        ? emotionWords[rng.nextInt(emotionWords.length)] as String
        : '余烬';
    final nature = natureWords.isNotEmpty
        ? natureWords[rng.nextInt(natureWords.length)] as String
        : '风';
    final intensityWord = intensityWords.isNotEmpty
        ? intensityWords[rng.nextInt(intensityWords.length)] as String
        : '半';
    String result = templateStr
        .replaceAll('{emotionWord}', emotionWord)
        .replaceAll('{nature}', nature)
        .replaceAll('{intensity}', intensityWord);
    if (coreWords.isNotEmpty) {
      result = result.replaceAll('{core1}', coreWords[0]);
      if (coreWords.length > 1) result = result.replaceAll('{core2}', coreWords[1]);
    }
    return TransformResult(type: type, content: result);
  }

  String _buildSystemPrompt(Emotion emotion, int intensity) {
    return '''你是一位俳句诗人，擅长用极简的汉字捕捉情绪的瞬间。

用户正在经历「${emotion.label}」情绪，烈度 $intensity/5。

请将用户的情绪文字转化为三行俳句，要求：
1. 共3行，每行短促有力（4-8字）
2. 融入意象（自然/天气/季节/身体感受）
3. 不用解释，只输出三行诗本身
4. 换行用\\n分隔

示例：
枯叶在风中旋
无人知晓它的重
落地无声碎''';
  }

  List<String> _extractKeywords(String text) {
    const stopWords = {
      '的', '了', '在', '是', '我', '有', '和', '就', '不', '人', '都',
      '一', '上', '也', '很', '到', '说', '要', '去', '你', '会', '着',
      '没有', '看', '好', '自己', '这', '那', '什么', '怎么', '还', '把',
    };
    return text
        .replaceAll(RegExp(r'[，。！？、；：\u201c\u201d\u2018\u2019\uff08\uff09\[\]{}.,!?;:\s]+'), ' ')
        .split(' ')
        .where((s) => s.length >= 2 && s.length <= 4 && !stopWords.contains(s))
        .take(6)
        .toList();
  }

  List<String> _pickCore(List<String> extracted, List emotionWords, Random rng) {
    final result = <String>[];
    result.addAll(extracted.take(3));
    while (result.length < 3 && emotionWords.isNotEmpty) {
      final w = emotionWords[rng.nextInt(emotionWords.length)] as String;
      if (!result.contains(w)) result.add(w);
    }
    return result;
  }
}
