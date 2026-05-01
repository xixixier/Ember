import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ember/data/database/app_database.dart';

/// 数据导出服务（仅导出脱敏统计，不含原文）
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  /// 导出日统计 CSV
  Future<File> exportDailyStatsCsv(AppDatabase db) async {
    final allStats = await _getAllDailyStats(db);

    final buffer = StringBuffer();
    buffer.writeln('日期,吐槽次数,烈度总和,主要情绪,高杀伤对象');

    for (final s in allStats) {
      buffer.writeln(
          '${s.date},${s.totalCount},${s.intensitySum},${s.topEmotion ?? ""},${s.topTarget ?? ""}');
    }

    return _writeAndReturn(buffer, 'ember_daily_stats');
  }

  /// 导出词频统计 CSV
  Future<File> exportKeywordsCsv(AppDatabase db) async {
    // 获取所有月份的关键词（需要一些 trick，先取最近 12 个月）
    final months = _getRecentMonths(12);
    final keywords = await db.keywordDao.getTopByMonths(months, limit: 500);

    final buffer = StringBuffer();
    buffer.writeln('关键词,出现次数,关联情绪,月份');

    for (final k in keywords) {
      buffer.writeln('${k.word},${k.count},${k.emotionTag},${k.month}');
    }

    return _writeAndReturn(buffer, 'ember_keywords');
  }

  /// 导出收藏统计 CSV
  Future<File> exportCollectionsCsv(AppDatabase db) async {
    final collections = await db.collectionDao.getAll();

    final buffer = StringBuffer();
    buffer.writeln('类型,情绪,烈度,收藏时间');

    for (final c in collections) {
      final date = DateTime.fromMillisecondsSinceEpoch(c.createdAt * 1000);
      buffer.writeln(
          '${c.type},${c.emotionTag},${c.intensity},${date.toIso8601String().substring(0, 10)}');
    }

    return _writeAndReturn(buffer, 'ember_collections');
  }

  /// 一键导出全部统计（合并 CSV）
  Future<File> exportAllStats(AppDatabase db) async {
    final buffer = StringBuffer();

    // ─── 日统计 ───
    buffer.writeln('=== 日情绪统计 ===');
    buffer.writeln('日期,吐槽次数,烈度总和,主要情绪,高杀伤对象');
    final allStats = await _getAllDailyStats(db);
    for (final s in allStats) {
      buffer.writeln(
          '${s.date},${s.totalCount},${s.intensitySum},${s.topEmotion ?? ""},${s.topTarget ?? ""}');
    }
    buffer.writeln();

    // ─── 词频 ───
    buffer.writeln('=== 关键词统计 ===');
    buffer.writeln('关键词,出现次数,关联情绪,月份');
    final months = _getRecentMonths(12);
    final keywords = await db.keywordDao.getTopByMonths(months, limit: 500);
    for (final k in keywords) {
      buffer.writeln('${k.word},${k.count},${k.emotionTag},${k.month}');
    }
    buffer.writeln();

    // ─── 收藏 ───
    buffer.writeln('=== 收藏统计 ===');
    buffer.writeln('类型,情绪,烈度,收藏时间');
    final collections = await db.collectionDao.getAll();
    for (final c in collections) {
      final date = DateTime.fromMillisecondsSinceEpoch(c.createdAt * 1000);
      buffer.writeln(
          '${c.type},${c.emotionTag},${c.intensity},${date.toIso8601String().substring(0, 10)}');
    }

    return _writeAndReturn(buffer, 'ember_all_stats');
  }

  /// 分享导出的文件
  Future<void> shareFile(File file) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: '余烬 — 数据统计导出',
        text: '你的情绪脱敏统计数据，来自余烬 App',
      ),
    );
  }

  // ─── 内部工具 ──────────────────────────────────────────────────────────────

  Future<List<DailyStat>> _getAllDailyStats(AppDatabase db) async {
    // 获取最近 2 年的日统计
    final results = <DailyStat>[];
    for (int y = 0; y < 2; y++) {
      final year = DateTime.now().year - y;
      for (int m = 1; m <= 12; m++) {
        final prefix = '$year-${m.toString().padLeft(2, '0')}';
        final monthStats = await db.dailyStatsDao.getMonthStats(prefix);
        results.addAll(monthStats);
      }
    }
    results.sort((a, b) => a.date.compareTo(b.date));
    return results;
  }

  List<String> _getRecentMonths(int count) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}';
    });
  }

  Future<File> _writeAndReturn(StringBuffer buffer, String namePrefix) async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().substring(0, 10);
    final file = File('${dir.path}/${namePrefix}_$timestamp.csv');
    await file.writeAsString(buffer.toString());
    return file;
  }
}
