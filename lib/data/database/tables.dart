import 'package:drift/drift.dart';

/// 情绪条目表
/// raw_text 和 voice_path 在销毁时置空/删除，仅保留脱敏统计字段
class Entries extends Table {
  TextColumn get id => text()();
  TextColumn get rawText => text().withDefault(const Constant(''))();
  TextColumn get emotionTag => text()();
  TextColumn get targetTag => text().withDefault(const Constant('none'))();
  IntColumn get intensity => integer().withDefault(const Constant(3))();
  IntColumn get destroyAt => integer()();
  TextColumn get destroyStyle => text().withDefault(const Constant('burn'))();
  TextColumn get voicePath => text().nullable()();
  BoolColumn get isDestroyed => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get destroyedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 转化收藏表
/// 不存原文，只存转化后的艺术结果
class Collections extends Table {
  TextColumn get id => text()();
  TextColumn get sourceEntryId => text().nullable()();
  TextColumn get type => text()(); // shakespeare / haiku / soup / art
  TextColumn get content => text()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get emotionTag => text()();
  IntColumn get intensity => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 词频统计表
/// 脱敏统计，销毁时不删除
class Keywords extends Table {
  TextColumn get word => text()();
  IntColumn get count => integer()();
  TextColumn get emotionTag => text()();
  TextColumn get month => text()(); // "2026-04"
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {word, month};
}

/// 日统计缓存表
class DailyStats extends Table {
  TextColumn get date => text()(); // "2026-04-29"
  IntColumn get totalCount => integer().withDefault(const Constant(0))();
  IntColumn get intensitySum => integer().withDefault(const Constant(0))();
  TextColumn get topEmotion => text().nullable()();
  TextColumn get topTarget => text().nullable()();

  @override
  Set<Column> get primaryKey => {date};
}
