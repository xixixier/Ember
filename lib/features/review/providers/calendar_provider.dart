import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ember/core/providers/database_provider.dart';
import 'package:ember/data/database/app_database.dart';

/// 指定月份的 daily_stats 流
final calendarMonthProvider =
    StreamProvider.family<List<DailyStat>, String>((ref, monthPrefix) {
  final dao = ref.watch(dailyStatsDaoProvider);
  return dao.watchMonthStats(monthPrefix);
});

/// 当前选中月份（格式 "2026-04"）
final selectedMonthProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
});

/// 指定日期的 daily_stats（单次查询）
final dayStatsProvider =
    FutureProvider.family<DailyStat?, String>((ref, date) {
  final dao = ref.watch(dailyStatsDaoProvider);
  return dao.getByDate(date);
});
