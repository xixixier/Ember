import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:ember/core/constants/emotions.dart';
import 'package:ember/core/constants/targets.dart';
import 'package:ember/core/constants/destroy_styles.dart';
import 'package:ember/core/providers/database_provider.dart';
import 'package:ember/data/database/app_database.dart';
import 'package:ember/features/throw_in/widgets/destroy_time_picker.dart';

/// 投放页状态
class ThrowInState {
  final Emotion emotion;
  final Target target;
  final int intensity;
  final DestroyTime destroyTime;
  final DestroyStyle destroyStyle;
  final bool isSubmitting;

  const ThrowInState({
    this.emotion = Emotion.anger,
    this.target = Target.none,
    this.intensity = 3,
    this.destroyTime = DestroyTime.hours24,
    this.destroyStyle = DestroyStyle.burn,
    this.isSubmitting = false,
  });

  ThrowInState copyWith({
    Emotion? emotion,
    Target? target,
    int? intensity,
    DestroyTime? destroyTime,
    DestroyStyle? destroyStyle,
    bool? isSubmitting,
  }) {
    return ThrowInState(
      emotion: emotion ?? this.emotion,
      target: target ?? this.target,
      intensity: intensity ?? this.intensity,
      destroyTime: destroyTime ?? this.destroyTime,
      destroyStyle: destroyStyle ?? this.destroyStyle,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

/// 投放页 Controller
class ThrowInController extends StateNotifier<ThrowInState> {
  final EntryDao _entryDao;
  final DailyStatsDao _dailyStatsDao;
  final KeywordDao _keywordDao;

  /// 最后提交的条目ID（用于后续销毁操作）
  String? _lastSubmittedId;

  ThrowInController(this._entryDao, this._dailyStatsDao, this._keywordDao)
      : super(const ThrowInState());

  void setEmotion(Emotion e) => state = state.copyWith(emotion: e);
  void setTarget(Target t) => state = state.copyWith(target: t);
  void setIntensity(int i) => state = state.copyWith(intensity: i);
  void setDestroyTime(DestroyTime dt) => state = state.copyWith(destroyTime: dt);
  void setDestroyStyle(DestroyStyle ds) => state = state.copyWith(destroyStyle: ds);

  /// 提交一条情绪条目
  /// 返回 true 表示成功
  Future<bool> submit(String rawText) async {
    if (rawText.trim().isEmpty) return false;

    state = state.copyWith(isSubmitting: true);

    try {
      final now = DateTime.now();
      final nowSeconds = now.millisecondsSinceEpoch ~/ 1000;
      final destroyAt = nowSeconds + state.destroyTime.seconds;
      final id = const Uuid().v4();

      // 1. 写入 entries
      await _entryDao.insertEntry(EntriesCompanion(
        id: Value(id),
        rawText: Value(rawText),
        emotionTag: Value(state.emotion.name),
        targetTag: Value(state.target.name),
        intensity: Value(state.intensity),
        destroyAt: Value(destroyAt),
        destroyStyle: Value(state.destroyStyle.name),
        isDestroyed: const Value(false),
        createdAt: Value(nowSeconds),
      ));

      // 保存条目ID，用于后续可能的销毁操作
      _lastSubmittedId = id;

      // 2. 更新日统计
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await _dailyStatsDao.incrementDay(
        dateStr,
        state.emotion.name,
        state.target.name,
        state.intensity,
      );

      // 3. 提取关键词并更新词频
      final monthStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final keywords = _extractKeywords(rawText);
      if (keywords.isNotEmpty) {
        await _keywordDao.batchIncrement(keywords, state.emotion.name, monthStr);
      }

      // 注意：不在这里执行销毁！
      // "立刻销毁"应该在显示销毁动画后，由 ThrowInScreen 处理
      // 这样用户有机会取消销毁

      return true;
    } catch (e) {
      return false;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  /// 销毁最后提交的条目（在销毁动画完成后调用）
  Future<void> destroyPendingEntry() async {
    if (_lastSubmittedId != null) {
      await _entryDao.destroyNow(_lastSubmittedId!);
      _lastSubmittedId = null;
    }
  }

  /// 简易中文关键词提取
  /// Phase 1: 基于规则（去除停用词 + 2-4 字长词组）
  /// Phase 2: 可接入 jieba 分词
  List<String> _extractKeywords(String text) {
    // 停用词表
    const stopWords = {
      '的', '了', '在', '是', '我', '有', '和', '就', '不', '人', '都',
      '一', '一个', '上', '也', '很', '到', '说', '要', '去', '你', '会',
      '着', '没有', '看', '好', '自己', '这', '他', '她', '它', '那',
      '什么', '怎么', '还', '把', '让', '被', '从', '对', '吧', '啊',
      '吗', '呢', '哦', '嗯', '呀', '哈', '嘿', '啦', '嘛',
    };

    // 简单分词：按标点和空格切分，过滤停用词和短词
    final segments = text
        .replaceAll(RegExp(r'[，。！？、；：\u201c\u201d\u2018\u2019\uff08\uff09\[\]{}.,!?;:\s]+'), ' ')
        .split(' ')
        .where((s) => s.isNotEmpty && s.length >= 2 && !stopWords.contains(s))
        .toList();

    // 最多取 10 个关键词
    return segments.take(10).toList();
  }
}

/// 投放页 Controller Provider
final throwInControllerProvider =
    StateNotifierProvider<ThrowInController, ThrowInState>((ref) {
  return ThrowInController(
    ref.watch(entryDaoProvider),
    ref.watch(dailyStatsDaoProvider),
    ref.watch(keywordDaoProvider),
  );
});
