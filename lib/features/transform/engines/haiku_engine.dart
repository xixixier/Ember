import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import 'package:ember/core/constants/emotions.dart';
import 'transform_engine.dart';

/// 俳句生成引擎
/// 从原文提取关键词 → 选3个核心词 → 填入5-7-5模板
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

    // 从原文提取关键词（2-4字）
    final extractedKeywords = _extractKeywords(text);
    // 取3个核心词
    final coreWords = _pickCore(extractedKeywords, emotionWords, rng);

    // 选择模板
    final templateStr =
        templates.isNotEmpty ? templates[rng.nextInt(templates.length)] as String : '{intensity}{emotionWord}——\n{nature}过{emotionWord}处\n{intensity}{nature}亦{emotionWord}';

    // 构建替换词
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

    // 如果有核心词，替换部分位置
    if (coreWords.isNotEmpty) {
      result = result.replaceAll('{core1}', coreWords[0]);
      if (coreWords.length > 1) {
        result = result.replaceAll('{core2}', coreWords[1]);
      }
    }

    return TransformResult(
      type: type,
      content: result,
    );
  }

  /// 从文本中提取关键词
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

  /// 选取核心词，优先用原文提取的，不够则用情绪词补
  List<String> _pickCore(
    List<String> extracted,
    List emotionWords,
    Random rng,
  ) {
    final result = <String>[];
    result.addAll(extracted.take(3));
    while (result.length < 3 && emotionWords.isNotEmpty) {
      final w = emotionWords[rng.nextInt(emotionWords.length)] as String;
      if (!result.contains(w)) result.add(w);
    }
    return result;
  }
}
