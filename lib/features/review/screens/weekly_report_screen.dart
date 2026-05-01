import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ember/core/providers/database_provider.dart';
import 'package:ember/features/review/services/weekly_report_service.dart';
import 'package:ember/features/review/widgets/week_vs_week_card.dart';

/// 每周情绪报告页面
class WeeklyReportScreen extends ConsumerStatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  ConsumerState<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends ConsumerState<WeeklyReportScreen> {
  WeeklyData? _thisWeek;
  WeeklyData? _lastWeek;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dao = ref.read(dailyStatsDaoProvider);
    final service = WeeklyReportService(dao);

    final now = DateTime.now();
    // 本周一
    final thisMonday = now.subtract(Duration(days: now.weekday - 1));
    final thisMondayStr =
        '${thisMonday.year}-${thisMonday.month.toString().padLeft(2, '0')}-${thisMonday.day.toString().padLeft(2, '0')}';
    // 上周一
    final lastMonday = thisMonday.subtract(const Duration(days: 7));
    final lastMondayStr =
        '${lastMonday.year}-${lastMonday.month.toString().padLeft(2, '0')}-${lastMonday.day.toString().padLeft(2, '0')}';

    final results = await Future.wait([
      service.getWeeklyData(thisMondayStr),
      service.getWeeklyData(lastMondayStr),
    ]);

    if (mounted) {
      setState(() {
        _thisWeek = results[0];
        _lastWeek = results[1];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '周报',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _thisWeek == null
              ? const Center(child: Text('加载失败'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 一句话总结
                      _buildSummaryCard(colorScheme),
                      const SizedBox(height: 20),

                      // 5 项指标
                      _buildMetricsGrid(colorScheme),
                      const SizedBox(height: 20),

                      // 情绪分布
                      _buildEmotionDistribution(colorScheme),
                      const SizedBox(height: 20),

                      // 本周 vs 上周
                      if (_lastWeek != null)
                        WeekVsWeekCard(
                          thisWeek: _thisWeek!,
                          lastWeek: _lastWeek!,
                        ),
                    ],
                  ),
                ),
    );
  }

  /// 一句话总结
  Widget _buildSummaryCard(ColorScheme colorScheme) {
    final service = WeeklyReportService(ref.read(dailyStatsDaoProvider));
    final summary = service.generateSummary(_thisWeek!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.15),
            colorScheme.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                '本周洞察',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// 5 项指标网格
  Widget _buildMetricsGrid(ColorScheme colorScheme) {
    final w = _thisWeek!;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _MetricCard(
          title: '投放次数',
          value: '${w.totalCount}',
          unit: '次',
          icon: Icons.local_fire_department,
          color: colorScheme.primary,
        ),
        _MetricCard(
          title: '平均烈度',
          value: w.avgIntensity.toStringAsFixed(1),
          unit: '/5',
          icon: Icons.bolt,
          color: colorScheme.tertiary,
        ),
        _MetricCard(
          title: '主情绪',
          value: w.topEmotion.emoji,
          unit: w.topEmotion.label,
          icon: Icons.emoji_emotions,
          color: w.topEmotion.color,
        ),
        _MetricCard(
          title: '主对象',
          value: w.topTarget.label,
          unit: '',
          icon: Icons.my_location,
          color: colorScheme.secondary,
        ),
      ],
    );
  }

  /// 情绪分布
  Widget _buildEmotionDistribution(ColorScheme colorScheme) {
    final dist = _thisWeek!.emotionDistribution;
    final total = dist.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final sorted = dist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
            '情绪分布',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...sorted.map((entry) {
            final percent = (entry.value / total * 100).toStringAsFixed(0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      '${entry.key.emoji} ${entry.key.label}',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: entry.value / total,
                        backgroundColor: colorScheme.surfaceContainerLow,
                        valueColor: AlwaysStoppedAnimation(entry.key.color),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '$percent%',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (unit.isNotEmpty)
                Text(
                  unit,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
