import 'package:ember/core/constants/emotions.dart';
import 'package:ember/core/constants/targets.dart';
import 'package:ember/data/database/app_database.dart';
import 'package:ember/features/review/providers/wordcloud_provider.dart';

/// 年度统计数据
class AnnualData {
  final int year;
  final int totalCount;
  final double avgIntensity;
  final Emotion topEmotion;
  final Target topTarget;
  final Map<Emotion, int> emotionDistribution;
  final Map<int, int> monthlyCounts; // 月份→次数
  final Map<int, double> monthlyAvgIntensity;
  final List<WordCloudItem> topKeywords;

  AnnualData({
    required this.year,
    required this.totalCount,
    required this.avgIntensity,
    required this.topEmotion,
    required this.topTarget,
    required this.emotionDistribution,
    required this.monthlyCounts,
    required this.monthlyAvgIntensity,
    required this.topKeywords,
  });
}

/// 年度情绪年鉴服务
class AnnualReportService {
  final DailyStatsDao _statsDao;
  final KeywordDao _keywordDao;

  AnnualReportService(this._statsDao, this._keywordDao);

  Future<AnnualData> getAnnualData(int year) async {
    final startDate = '$year-01-01';
    final endDate = '$year-12-31';

    final stats = await _statsDao.getRangeStats(startDate, endDate);

    final totalCount = stats.fold<int>(0, (sum, s) => sum + s.totalCount);
    final intensitySum = stats.fold<int>(0, (sum, s) => sum + s.intensitySum);
    final avgIntensity = totalCount > 0 ? intensitySum / totalCount : 0.0;

    // 情绪分布
    final emotionCounts = <Emotion, int>{};
    String? topEmotionName;
    int topEmotionCount = 0;
    final targetCounts = <String, int>{};
    String? topTargetName;
    int topTargetCount = 0;

    for (final s in stats) {
      final e = Emotion.fromName(s.topEmotion ?? 'custom');
      emotionCounts[e] = (emotionCounts[e] ?? 0) + s.totalCount;
      if (emotionCounts[e]! > topEmotionCount) {
        topEmotionCount = emotionCounts[e]!;
        topEmotionName = e.name;
      }
      if (s.topTarget != null) {
        targetCounts[s.topTarget!] =
            (targetCounts[s.topTarget!] ?? 0) + s.totalCount;
        if (targetCounts[s.topTarget!]! > topTargetCount) {
          topTargetCount = targetCounts[s.topTarget!]!;
          topTargetName = s.topTarget!;
        }
      }
    }

    // 月度数据
    final monthlyCounts = <int, int>{};
    final monthlyIntensitySums = <int, int>{};
    final monthlyCountsForAvg = <int, int>{};
    for (var m = 1; m <= 12; m++) {
      monthlyCounts[m] = 0;
      monthlyIntensitySums[m] = 0;
      monthlyCountsForAvg[m] = 0;
    }

    for (final s in stats) {
      final month = int.parse(s.date.split('-')[1]);
      monthlyCounts[month] = (monthlyCounts[month] ?? 0) + s.totalCount;
      monthlyIntensitySums[month] =
          (monthlyIntensitySums[month] ?? 0) + s.intensitySum;
      monthlyCountsForAvg[month] =
          (monthlyCountsForAvg[month] ?? 0) + s.totalCount;
    }

    final monthlyAvgIntensity = <int, double>{};
    for (var m = 1; m <= 12; m++) {
      final count = monthlyCountsForAvg[m] ?? 0;
      final sum = monthlyIntensitySums[m] ?? 0;
      monthlyAvgIntensity[m] = count > 0 ? sum / count : 0.0;
    }

    // 年度关键词
    final months = List.generate(
      12,
      (i) => '$year-${(i + 1).toString().padLeft(2, '0')}',
    );
    final allKeywords = await _keywordDao.getTopByMonths(months, limit: 30);
    final topKeywords = allKeywords.map((kw) {
      return WordCloudItem(
        word: kw.word,
        count: kw.count,
        emotion: Emotion.fromName(kw.emotionTag),
      );
    }).toList();

    return AnnualData(
      year: year,
      totalCount: totalCount,
      avgIntensity: avgIntensity,
      topEmotion: Emotion.fromName(topEmotionName ?? 'custom'),
      topTarget: Target.fromName(topTargetName ?? 'none'),
      emotionDistribution: emotionCounts,
      monthlyCounts: monthlyCounts,
      monthlyAvgIntensity: monthlyAvgIntensity,
      topKeywords: topKeywords,
    );
  }
}
