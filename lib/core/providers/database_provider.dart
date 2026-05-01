import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ember/data/database/app_database.dart';

/// 全局数据库实例 Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// DAO 便捷访问 Providers
final entryDaoProvider = Provider<EntryDao>((ref) {
  return ref.watch(databaseProvider).entryDao;
});

final collectionDaoProvider = Provider<CollectionDao>((ref) {
  return ref.watch(databaseProvider).collectionDao;
});

final keywordDaoProvider = Provider<KeywordDao>((ref) {
  return ref.watch(databaseProvider).keywordDao;
});

final dailyStatsDaoProvider = Provider<DailyStatsDao>((ref) {
  return ref.watch(databaseProvider).dailyStatsDao;
});
