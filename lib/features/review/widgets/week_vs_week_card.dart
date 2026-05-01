import 'package:flutter/material.dart';

import 'package:ember/features/review/services/weekly_report_service.dart';

/// 本周 vs 上周 对比卡片
class WeekVsWeekCard extends StatelessWidget {
  final WeeklyData thisWeek;
  final WeeklyData lastWeek;

  const WeekVsWeekCard({
    super.key,
    required this.thisWeek,
    required this.lastWeek,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final countDiff = thisWeek.totalCount - lastWeek.totalCount;
    final intensityDiff = thisWeek.avgIntensity - lastWeek.avgIntensity;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '本周 vs 上周',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // 投放次数对比
          _ComparisonRow(
            label: '投放次数',
            thisValue: '${thisWeek.totalCount}',
            lastValue: '${lastWeek.totalCount}',
            diff: countDiff,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 8),

          // 平均烈度对比
          _ComparisonRow(
            label: '平均烈度',
            thisValue: thisWeek.avgIntensity.toStringAsFixed(1),
            lastValue: lastWeek.avgIntensity.toStringAsFixed(1),
            diff: intensityDiff,
            color: colorScheme.tertiary,
            isDecimal: true,
          ),
          const SizedBox(height: 8),

          // 主情绪
          _ComparisonRow(
            label: '主情绪',
            thisValue: '${thisWeek.topEmotion.emoji} ${thisWeek.topEmotion.label}',
            lastValue: '${lastWeek.topEmotion.emoji} ${lastWeek.topEmotion.label}',
            diff: null,
            color: thisWeek.topEmotion.color,
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final String thisValue;
  final String lastValue;
  final num? diff;
  final Color color;
  final bool isDecimal;

  const _ComparisonRow({
    required this.label,
    required this.thisValue,
    required this.lastValue,
    required this.diff,
    required this.color,
    this.isDecimal = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    String diffText;
    Color diffColor;
    if (diff == null) {
      diffText = '—';
      diffColor = colorScheme.onSurfaceVariant;
    } else if (diff! > 0) {
      diffText = isDecimal
          ? '+${diff!.toStringAsFixed(1)}'
          : '+$diff';
      diffColor = const Color(0xFFE24B4A); // 上升→红
    } else if (diff! < 0) {
      diffText = isDecimal
          ? diff!.toStringAsFixed(1)
          : '$diff';
      diffColor = const Color(0xFF4CAF50); // 下降→绿（好事）
    } else {
      diffText = '持平';
      diffColor = colorScheme.onSurfaceVariant;
    }

    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            thisValue,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: diffColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            diffText,
            style: TextStyle(
              color: diffColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            lastValue,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
