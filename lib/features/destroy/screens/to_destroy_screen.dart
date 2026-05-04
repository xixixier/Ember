import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ember/core/constants/emotions.dart';
import 'package:ember/core/constants/destroy_styles.dart';
import 'package:ember/core/theme/ember_theme_extension.dart';
import 'package:ember/core/providers/database_provider.dart';
import 'package:ember/core/widgets/ember_card.dart';
import 'package:ember/core/widgets/ember_empty_state.dart';
import 'package:ember/data/database/app_database.dart';

/// 「待毁」Tab 页面
/// 显示所有等待销毁的条目，支持取消销毁和立即销毁
class ToDestroyScreen extends ConsumerStatefulWidget {
  const ToDestroyScreen({super.key});

  @override
  ConsumerState<ToDestroyScreen> createState() => _ToDestroyScreenState();
}

class _ToDestroyScreenState extends ConsumerState<ToDestroyScreen> {
  Timer? _timer;
  int _nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  @override
  void initState() {
    super.initState();
    // 每秒更新一次倒计时
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<EmberThemeExtension>();
    final entryDao = ref.watch(entryDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '待毁',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // 销毁方式图例
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 20),
            tooltip: '销毁方式图例',
            onPressed: () => _showStyleLegend(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Entry>>(
        stream: entryDao.watchPendingDestroyEntries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 前端过滤：只显示还没到期的条目
          final allItems = snapshot.data ?? [];
          final items = allItems.where((e) => e.destroyAt > _nowSeconds).toList();

          if (items.isEmpty) {
            return const EmberEmptyState(
              message: '没有待销毁的情绪',
              subMessage: '投放的情绪会在倒计时结束后自动化为灰烬',
              icon: Icons.hourglass_empty_outlined,
            );
          }

          // 统计信息
          final fireOrange = ext?.fireOrange ?? colorScheme.primary;
          final nearest = items.first;
          final nearestRemaining = nearest.destroyAt - _nowSeconds;

          return CustomScrollView(
            slivers: [
              // 统计卡片
              SliverToBoxAdapter(
                child: _buildStatsCard(
                  context,
                  count: items.length,
                  nearestRemaining: nearestRemaining,
                  fireOrange: fireOrange,
                ),
              ),

              // 待毁列表
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PendingDestroyCard(
                          entry: entry,
                          nowSeconds: _nowSeconds,
                          onDestroyNow: () => _destroyNow(entryDao, entry),
                          onCancel: () => _cancelDestroy(entryDao, entry),
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 统计卡片
  Widget _buildStatsCard(
    BuildContext context, {
    required int count,
    required int nearestRemaining,
    required Color fireOrange,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            // 待毁数量
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      color: fireOrange,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '条待销毁',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // 最近一条倒计时
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: fireOrange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: fireOrange.withValues(alpha: 0.20),
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '最近销毁',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatCountdown(nearestRemaining),
                    style: TextStyle(
                      color: fireOrange,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化倒计时
  String _formatCountdown(int seconds) {
    if (seconds <= 0) return '即将销毁';
    if (seconds < 60) return '$seconds 秒';
    if (seconds < 3600) return '${seconds ~/ 60} 分钟';
    if (seconds < 86400) {
      final h = seconds ~/ 3600;
      final m = (seconds % 3600) ~/ 60;
      return m > 0 ? '$h 小时 $m 分' : '$h 小时';
    }
    final d = seconds ~/ 86400;
    final h = (seconds % 86400) ~/ 3600;
    return h > 0 ? '$d 天 $h 小时' : '$d 天';
  }

  /// 立即销毁
  Future<void> _destroyNow(EntryDao dao, Entry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '立即销毁？',
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '这条情绪将被永久化为灰烬，不可恢复。',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('确认销毁'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await dao.destroyNow(entry.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已销毁 ${DestroyStyle.fromName(entry.destroyStyle).emoji}'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('销毁失败：$e'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  /// 取消销毁（暂缓7天）
  Future<void> _cancelDestroy(EntryDao dao, Entry entry) async {
    try {
      await dao.cancelDestroy(entry.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已暂缓销毁，7天后再次到期'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败：$e'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 显示销毁方式图例
  void _showStyleLegend(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '销毁方式',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: DestroyStyle.values.map((style) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(style.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${style.label} — ${_styleDescription(style)}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  String _styleDescription(DestroyStyle style) {
    return switch (style) {
      DestroyStyle.burn => '火焰焚烧，化为灰烬',
      DestroyStyle.sink => '沉入深海，永不见天日',
      DestroyStyle.scatter => '随风飘散，不留痕迹',
      DestroyStyle.ash => '凝结为余烬，缓缓消散',
    };
  }
}

/// 待毁条目卡片
class _PendingDestroyCard extends StatelessWidget {
  final Entry entry;
  final int nowSeconds;
  final VoidCallback onDestroyNow;
  final VoidCallback onCancel;

  const _PendingDestroyCard({
    required this.entry,
    required this.nowSeconds,
    required this.onDestroyNow,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<EmberThemeExtension>();
    final emotion = Emotion.fromName(entry.emotionTag);
    final style = DestroyStyle.fromName(entry.destroyStyle);
    final remaining = entry.destroyAt - nowSeconds;
    final isUrgent = remaining < 3600; // 小于1小时为紧急

    final accentColor = ext?.fireOrange ?? colorScheme.primary;
    final urgentColor = ext?.darkRedOrange ?? colorScheme.error;

    // 计算销毁进度
    final totalDuration = entry.destroyAt - entry.createdAt;
    final elapsed = nowSeconds - entry.createdAt;
    final progress = (totalDuration > 0 ? elapsed / totalDuration : 0.0).clamp(0.0, 1.0);

    return EmberCard(
      borderRadius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：情绪标签 + 倒计时
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                // 情绪标签
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: emotion.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: emotion.color.withValues(alpha: 0.30),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emotion.emoji, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        emotion.label,
                        style: TextStyle(
                          color: emotion.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 销毁方式
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(style.emoji, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 3),
                      Text(
                        '以${style.label}销毁',
                        style: TextStyle(
                          color: accentColor.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // 倒计时
                Text(
                  _formatRemaining(remaining),
                  style: TextStyle(
                    color: isUrgent ? urgentColor : colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: isUrgent ? FontWeight.w700 : FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),

          // 进度条
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isUrgent ? urgentColor : accentColor,
                ),
              ),
            ),
          ),

          // 内容预览
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Text(
              entry.rawText.isEmpty ? '(已匿名)' : entry.rawText,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 底部操作栏
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 暂缓按钮
                TextButton.icon(
                  onPressed: onCancel,
                  icon: Icon(
                    Icons.schedule_outlined,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  label: Text(
                    '暂缓',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                // 立即销毁按钮
                TextButton.icon(
                  onPressed: onDestroyNow,
                  icon: Icon(
                    Icons.local_fire_department_outlined,
                    size: 14,
                    color: urgentColor,
                  ),
                  label: Text(
                    '立即销毁',
                    style: TextStyle(
                      color: urgentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRemaining(int seconds) {
    if (seconds <= 0) return '销毁中...';
    if (seconds < 60) return '$seconds 秒后';
    if (seconds < 3600) return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')} 后';
    if (seconds < 86400) {
      final h = seconds ~/ 3600;
      final m = (seconds % 3600) ~/ 60;
      return '$h:${m.toString().padLeft(2, '0')}:00 后';
    }
    final d = seconds ~/ 86400;
    final h = (seconds % 86400) ~/ 3600;
    return '$d 天 $h 小时后';
  }
}
