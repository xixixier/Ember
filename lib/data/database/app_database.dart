import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

// ─── DAOs ─────────────────────────────────────────────────────────────────────

/// 情绪条目 DAO
@DriftAccessor(tables: [Entries])
class EntryDao extends DatabaseAccessor<AppDatabase> with _$EntryDaoMixin {
  EntryDao(super.db);

  Future<void> insertEntry(EntriesCompanion entry) =>
      into(entries).insert(entry);

  Future<List<Entry>> getActiveEntries() =>
      (select(entries)
            ..where((t) => t.isDestroyed.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Stream<List<Entry>> watchActiveEntries() =>
      (select(entries)
            ..where((t) => t.isDestroyed.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<List<Entry>> getPendingDestroy(int nowSeconds) =>
      (select(entries)
            ..where((t) =>
                t.isDestroyed.equals(false) &
                t.destroyAt.isSmallerOrEqualValue(nowSeconds)))
          .get();

  Future<void> destroyEntryWithTimestamp(String id, int destroyedAt) =>
      (update(entries)..where((t) => t.id.equals(id))).write(EntriesCompanion(
        rawText: const Value(''),
        voicePath: const Value.absent(),
        isDestroyed: const Value(true),
        destroyedAt: Value(destroyedAt),
      ));

  Future<void> destroyNow(String id) => destroyEntryWithTimestamp(
      id, DateTime.now().millisecondsSinceEpoch ~/ 1000);

  Future<List<Entry>> getByDateRange(int startSeconds, int endSeconds) =>
      (select(entries)
            ..where((t) =>
                t.createdAt.isBiggerOrEqualValue(startSeconds) &
                t.createdAt.isSmallerOrEqualValue(endSeconds)))
          .get();

  Future<Entry?> getById(String id) =>
      (select(entries)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// 监听待毁条目（未销毁）
  /// 用于「待毁」Tab 实时显示
  /// 注意：不在 SQL 中过滤 destroyAt，让前端根据当前时间过滤，
  /// 避免 Timer 每秒触发 setState 导致 stream 重建和 loading 闪烁
  Stream<List<Entry>> watchPendingDestroyEntries() =>
      (select(entries)
            ..where((t) => t.isDestroyed.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.destroyAt)]))
          .watch();

  /// 取消销毁（将销毁时间设为7天后，相当于暂缓）
  Future<void> cancelDestroy(String id) {
    final sevenDaysLater = DateTime.now().millisecondsSinceEpoch ~/ 1000 +
        7 * 24 * 3600;
    return (update(entries)..where((t) => t.id.equals(id)))
        .write(EntriesCompanion(destroyAt: Value(sevenDaysLater)));
  }

  /// 获取已销毁条目
  Stream<List<Entry>> watchDestroyedEntries() =>
      (select(entries)
            ..where((t) => t.isDestroyed.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.destroyedAt)]))
          .watch();

  Future<void> clearVoicePath(String id) => (update(entries)
        ..where((t) => t.id.equals(id)))
      .write(const EntriesCompanion(voicePath: Value.absent()));
}

/// 转化收藏 DAO
@DriftAccessor(tables: [Collections])
class CollectionDao extends DatabaseAccessor<AppDatabase>
    with _$CollectionDaoMixin {
  CollectionDao(super.db);

  Future<void> insertCollection(CollectionsCompanion item) =>
      into(collections).insert(item);

  Future<List<Collection>> getAll() => (select(collections)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();

  Stream<List<Collection>> watchAll() => (select(collections)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  Stream<List<Collection>> watchByType(String type) =>
      (select(collections)
            ..where((t) => t.type.equals(type))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<void> deleteCollection(String id) =>
      (delete(collections)..where((t) => t.id.equals(id))).go();

  Future<int> getCount() async {
    final countExpr = collections.id.count();
    final query = selectOnly(collections)..addColumns([countExpr]);
    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }
}

/// 词频统计 DAO
@DriftAccessor(tables: [Keywords])
class KeywordDao extends DatabaseAccessor<AppDatabase> with _$KeywordDaoMixin {
  KeywordDao(super.db);

  Future<void> incrementWord(
      String word, String emotionTag, String month) async {
    final existing = await (select(keywords)
          ..where((t) => t.word.equals(word) & t.month.equals(month)))
        .getSingleOrNull();

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (existing != null) {
      await (update(keywords)
            ..where((t) => t.word.equals(word) & t.month.equals(month)))
          .write(KeywordsCompanion(
        count: Value(existing.count + 1),
        updatedAt: Value(now),
      ));
    } else {
      await into(keywords).insert(KeywordsCompanion(
        word: Value(word),
        emotionTag: Value(emotionTag),
        month: Value(month),
        count: const Value(1),
        updatedAt: Value(now),
      ));
    }
  }

  Future<List<Keyword>> getTopByMonth(String month, {int limit = 20}) =>
      (select(keywords)
            ..where((t) => t.month.equals(month))
            ..orderBy([(t) => OrderingTerm.desc(t.count)])
            ..limit(limit))
          .get();

  Future<List<Keyword>> getTopByMonths(List<String> months,
          {int limit = 50}) =>
      (select(keywords)
            ..where((t) => t.month.isIn(months))
            ..orderBy([(t) => OrderingTerm.desc(t.count)])
            ..limit(limit))
          .get();

  Future<void> batchIncrement(
      List<String> words, String emotionTag, String month) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await batch((b) {
      for (final word in words) {
        b.customStatement(
          'INSERT INTO keywords (word, count, emotion_tag, month, updated_at) '
          'VALUES (?, 1, ?, ?, ?) '
          'ON CONFLICT (word, month) DO UPDATE SET '
          'count = count + 1, updated_at = excluded.updated_at, emotion_tag = excluded.emotion_tag',
          [word, emotionTag, month, now],
        );
      }
    });
  }
}

/// 日统计缓存 DAO
@DriftAccessor(tables: [DailyStats])
class DailyStatsDao extends DatabaseAccessor<AppDatabase>
    with _$DailyStatsDaoMixin {
  DailyStatsDao(super.db);

  Future<void> incrementDay(
      String date, String emotionTag, String targetTag, int intensity) async {
    final existing = await (select(dailyStats)
          ..where((t) => t.date.equals(date)))
        .getSingleOrNull();

    if (existing != null) {
      await (update(dailyStats)..where((t) => t.date.equals(date)))
          .write(DailyStatsCompanion(
        totalCount: Value(existing.totalCount + 1),
        intensitySum: Value(existing.intensitySum + intensity),
        topEmotion: Value(emotionTag),
        topTarget: Value(targetTag),
      ));
    } else {
      await into(dailyStats).insert(DailyStatsCompanion(
        date: Value(date),
        totalCount: const Value(1),
        intensitySum: Value(intensity),
        topEmotion: Value(emotionTag),
        topTarget: Value(targetTag),
      ));
    }
  }

  Future<DailyStat?> getByDate(String date) =>
      (select(dailyStats)..where((t) => t.date.equals(date))).getSingleOrNull();

  Future<List<DailyStat>> getMonthStats(String monthPrefix) =>
      (select(dailyStats)..where((t) => t.date.like('$monthPrefix%'))).get();

  Stream<List<DailyStat>> watchMonthStats(String monthPrefix) =>
      (select(dailyStats)..where((t) => t.date.like('$monthPrefix%'))).watch();

  Future<List<DailyStat>> getRangeStats(String startDate, String endDate) =>
      (select(dailyStats)
            ..where((t) =>
                t.date.isBiggerOrEqualValue(startDate) &
                t.date.isSmallerOrEqualValue(endDate)))
          .get();
}

// ─── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [Entries, Collections, Keywords, DailyStats],
  daos: [EntryDao, CollectionDao, KeywordDao, DailyStatsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  /// 清库（仅用于调试）
  Future<void> deleteAllData() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'ember.db');
}
