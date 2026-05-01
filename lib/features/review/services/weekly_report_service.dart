import 'package:ember/core/constants/emotions.dart';
import 'package:ember/core/constants/targets.dart';
import 'package:ember/data/database/app_database.dart';

/// 每周统计数据
class WeeklyData {
  final int totalCount;
  final double avgIntensity;
  final Emotion topEmotion;
  final Target topTarget;
  final Map<Emotion, int> emotionDistribution;
  final List<DailyStat> dailyStats;

  WeeklyData({
    required this.totalCount,
    required this.avgIntensity,
    required this.topEmotion,
    required this.topTarget,
    required this.emotionDistribution,
    required this.dailyStats,
  });
}

/// 每周情绪报告服务
class WeeklyReportService {
  final DailyStatsDao _dao;

  WeeklyReportService(this._dao);

  /// 获取指定周的统计数据
  /// [weekStart] 格式 "2026-04-28" (周一)
  Future<WeeklyData> getWeeklyData(String weekStart) async {
    final startDate = DateTime.parse(weekStart);
    final endDate = startDate.add(const Duration(days: 6));
    final endStr =
        '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

    final stats = await _dao.getRangeStats(weekStart, endStr);

    final totalCount = stats.fold<int>(0, (sum, s) => sum + s.totalCount);
    final intensitySum = stats.fold<int>(0, (sum, s) => sum + s.intensitySum);
    final avgIntensity = totalCount > 0 ? intensitySum / totalCount : 0.0;

    // 情绪分布
    final emotionCounts = <Emotion, int>{};
    String? topEmotionName;
    int topEmotionCount = 0;
    String? topTargetName;
    int topTargetCount = 0;

    final targetCounts = <String, int>{};
    for (final s in stats) {
      // 情绪统计
      final e = Emotion.fromName(s.topEmotion ?? 'custom');
      emotionCounts[e] = (emotionCounts[e] ?? 0) + s.totalCount;
      if (emotionCounts[e]! > topEmotionCount) {
        topEmotionCount = emotionCounts[e]!;
        topEmotionName = e.name;
      }

      // 对象统计
      if (s.topTarget != null) {
        targetCounts[s.topTarget!] =
            (targetCounts[s.topTarget!] ?? 0) + s.totalCount;
        if (targetCounts[s.topTarget!]! > topTargetCount) {
          topTargetCount = targetCounts[s.topTarget!]!;
          topTargetName = s.topTarget!;
        }
      }
    }

    return WeeklyData(
      totalCount: totalCount,
      avgIntensity: avgIntensity,
      topEmotion: Emotion.fromName(topEmotionName ?? 'custom'),
      topTarget: Target.fromName(topTargetName ?? 'none'),
      emotionDistribution: emotionCounts,
      dailyStats: stats,
    );
  }

  /// 生成一句话总结
  String generateSummary(WeeklyData data) {
    if (data.totalCount == 0) {
      return '这周没有投放记录，有时候平静也是好事。';
    }

    final buffers = <String>[];

    if (data.avgIntensity >= 4) {
      buffers.add('这周情绪风暴很猛');
    } else if (data.avgIntensity >= 2.5) {
      buffers.add('这周情绪起伏不小');
    } else {
      buffers.add('这周情绪还算温和');
    }

    buffers.add('，主情绪是${data.topEmotion.emoji}${data.topEmotion.label}');

    if (data.topTarget != Target.none) {
      buffers.add('，主要指向「${data.topTarget.label}」');
    }

    if (data.totalCount >= 7) {
      buffers.add('。投放了${data.totalCount}次，你很勇敢地面对了自己。');
    } else if (data.totalCount >= 3) {
      buffers.add('。${data.totalCount}次投放，每次都是一次释放。');
    } else {
      buffers.add('。偶尔释放也是一种选择。');
    }

    return buffers.join();
  }
}
