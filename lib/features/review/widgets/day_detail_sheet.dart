import 'package:flutter/material.dart';

import 'package:ember/core/constants/emotions.dart';
import 'package:ember/core/constants/targets.dart';

/// 日期详情 BottomSheet
/// 显示统计信息，不展示原文
class DayDetailSheet extends StatelessWidget {
  final String date;
  final int totalCount;
  final String emotionName;
  final String emotionEmoji;
  final int intensitySum;
  final String? topTarget;

  const DayDetailSheet({
    super.key,
    required this.date,
    required this.totalCount,
    required this.emotionName,
    required this.emotionEmoji,
    required this.intensitySum,
    this.topTarget,
  });

  static void show(
    BuildContext context, {
    required String date,
    required int totalCount,
    required String emotionName,
    required String emotionEmoji,
    required int intensitySum,
    String? topTarget,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DayDetailSheet(
        date: date,
        totalCount: totalCount,
        emotionName: emotionName,
        emotionEmoji: emotionEmoji,
        intensitySum: intensitySum,
        topTarget: topTarget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final avgIntensity = totalCount > 0 ? (intensitySum / totalCount).toStringAsFixed(1) : '0';
    final targetLabel = topTarget != null
        ? Target.fromName(topTarget!).label
        : '—';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拖拽条
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 日期标题
          Text(
            _formatDate(date),
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // 统计卡片行
          Row(
            children: [
              _StatCard(
                label: '投放次数',
                value: '$totalCount',
                icon: Icons.local_fire_department,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: '主要情绪',
                value: '$emotionEmoji $emotionName',
                icon: Icons.emoji_emotions,
                color: Emotion.fromName(emotionName).color,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                label: '平均烈度',
                value: avgIntensity,
                icon: Icons.bolt,
                color: colorScheme.tertiary,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: '主要对象',
                value: targetLabel,
                icon: Icons.my_location,
                color: colorScheme.secondary,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 隐私提示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '原始内容已销毁，仅保留脱敏统计',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      return '${parts[0]}年${int.parse(parts[1])}月${int.parse(parts[2])}日';
    } catch (_) {
      return dateStr;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
