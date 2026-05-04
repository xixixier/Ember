import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ember/core/providers/database_provider.dart';
import 'package:ember/data/database/app_database.dart';
import 'package:ember/core/constants/emotions.dart';

/// 词云数据项
class WordCloudItem {
  final String word;
  final int count;
  final Emotion emotion;

  WordCloudItem({
    required this.word,
    required this.count,
    required this.emotion,
  });
}

/// 指定月份的词云数据
final wordCloudProvider =
    FutureProvider.family<List<WordCloudItem>, String>((ref, month) {
  final dao = ref.watch(keywordDaoProvider);
  return _buildWordCloud(dao, month);
});

/// 全年词云数据
final yearWordCloudProvider =
    FutureProvider.family<List<WordCloudItem>, int>((ref, year) async {
  final dao = ref.watch(keywordDaoProvider);
  final months = List.generate(
    12,
    (i) => '$year-${(i + 1).toString().padLeft(2, '0')}',
  );
  final allKeywords = await dao.getTopByMonths(months, limit: 80);

  // 合并同词
  final merged = <String, WordCloudItem>{};
  for (final kw in allKeywords) {
    final existing = merged[kw.word];
    final emotion = Emotion.fromName(kw.emotionTag);
    if (existing != null) {
      merged[kw.word] = WordCloudItem(
        word: kw.word,
        count: existing.count + kw.count,
        emotion: emotion,
      );
    } else {
      merged[kw.word] = WordCloudItem(
        word: kw.word,
        count: kw.count,
        emotion: emotion,
      );
    }
  }

  final items = merged.values.toList()
    ..sort((a, b) => b.count.compareTo(a.count));
  return items.take(50).toList();
});

Future<List<WordCloudItem>> _buildWordCloud(
  KeywordDao dao,
  String month,
) async {
  try {
    final keywords = await dao.getTopByMonth(month, limit: 50);
    return keywords.map((kw) {
      return WordCloudItem(
        word: kw.word,
        count: kw.count,
        emotion: Emotion.fromName(kw.emotionTag),
      );
    }).toList();
  } catch (e) {
    return <WordCloudItem>[];
  }
}
