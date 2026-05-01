import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ember/core/constants/emotions.dart';
import 'package:ember/core/theme/ember_theme_extension.dart';
import 'package:ember/features/review/providers/calendar_provider.dart';
import 'package:ember/features/review/providers/wordcloud_provider.dart';
import 'package:ember/features/review/widgets/heat_map_calendar.dart';
import 'package:ember/features/review/widgets/animated_heat_map_calendar.dart';
import 'package:ember/features/review/widgets/day_detail_sheet.dart';
import 'package:ember/features/review/widgets/animated_word_cloud.dart';
import 'package:ember/features/review/screens/weekly_report_screen.dart';
import 'package:ember/features/review/screens/annual_report_screen.dart';
import 'package:ember/core/widgets/ember_empty_state.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  String? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedMonth = ref.watch(selectedMonthProvider);
    final monthAsync = ref.watch(calendarMonthProvider(selectedMonth));

    // 解析当前月份
    final parts = selectedMonth.split('-');
    final monthDateTime = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '回望',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment_outlined),
            tooltip: '周报',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WeeklyReportScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: '年鉴',
            onPressed: () {
              final year = DateTime.now().year;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AnnualReportScreen(year: year),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // 月份切换
            _buildMonthSelector(context, monthDateTime, colorScheme),
            const SizedBox(height: 12),

            // 热力图日历
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: monthAsync.when(
                data: (stats) {
                final dayDataMap = buildDayDataMap(stats);
                final ext = Theme.of(context).extension<EmberThemeExtension>()!;
                final calendarSize = Size(
                  MediaQuery.of(context).size.width - 32,
                  320,
                );
                return GestureDetector(
                  key: ValueKey(selectedMonth),
                  onTapUp: (details) {
                    _onCalendarTap(
                      details,
                      monthDateTime,
                      dayDataMap,
                      context,
                    );
                  },
                  child: SizedBox(
                    height: 320,
                    child: AnimatedHeatMapCalendar(
                      month: monthDateTime,
                      dayDataMap: dayDataMap,
                      selectedDate: _selectedDate,
                      headerColor: ext.heatMapHeader,
                      dayTextColor: ext.heatMapDayText,
                      emptyColor: ext.heatMapEmpty,
                      selectedBorderColor: ext.heatMapSelectedBorder,
                      size: calendarSize,
                    ),
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 320,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SizedBox(
                height: 320,
                child: Center(child: Text('加载失败', style: TextStyle(color: colorScheme.error))),
              ),
              ),
            ),
            const SizedBox(height: 20),

            // 情绪图例
            _buildLegend(colorScheme),
            const SizedBox(height: 24),

            // 本月概览
            _buildMonthSummary(monthAsync, colorScheme),
            const SizedBox(height: 24),

            // 本月词云
            _buildWordCloud(selectedMonth, colorScheme),
          ],
        ),
      ),
    );
  }

  /// 月份选择器
  Widget _buildMonthSelector(
    BuildContext context,
    DateTime month,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _changeMonth(-1),
          color: colorScheme.onSurfaceVariant,
        ),
        Text(
          '${month.year}年${month.month}月',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => _changeMonth(1),
          color: colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  void _changeMonth(int delta) {
    final current = ref.read(selectedMonthProvider);
    final parts = current.split('-');
    var year = int.parse(parts[0]);
    var month = int.parse(parts[1]) + delta;

    if (month > 12) {
      month = 1;
      year++;
    } else if (month < 1) {
      month = 12;
      year--;
    }

    ref.read(selectedMonthProvider.notifier).state =
        '$year-${month.toString().padLeft(2, '0')}';
    _selectedDate = null;
  }

  /// 日历点击处理
  void _onCalendarTap(
    TapUpDetails details,
    DateTime month,
    Map<String, DayData> dayDataMap,
    BuildContext context,
  ) {
    final cellSize = (MediaQuery.of(context).size.width - 32 - 6 * 4) / 7;
    final headerHeight = cellSize * 0.6;
    final rowHeight = cellSize + 4;

    final dx = details.localPosition.dx;
    final dy = details.localPosition.dy - headerHeight;

    if (dy < 0) return;

    final col = (dx / (cellSize + 4)).floor();
    final row = (dy / rowHeight).floor();

    final firstDay = DateTime(month.year, month.month, 1);
    final weekdayOffset = firstDay.weekday - 1;
    final dayIndex = row * 7 + col - weekdayOffset + 1;

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    if (dayIndex < 1 || dayIndex > daysInMonth) return;

    final dateStr =
        '${month.year}-${month.month.toString().padLeft(2, '0')}-${dayIndex.toString().padLeft(2, '0')}';
    final data = dayDataMap[dateStr];

    setState(() => _selectedDate = dateStr);

    if (data != null) {
      DayDetailSheet.show(
        context,
        date: dateStr,
        totalCount: data.count,
        emotionName: data.emotionName,
        emotionEmoji: data.emotionEmoji,
        intensitySum: data.intensitySum,
        topTarget: data.topTarget,
      );
    }
  }

  /// 情绪图例
  Widget _buildLegend(ColorScheme colorScheme) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: Emotion.values.map((e) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: e.color.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${e.emoji} ${e.label}',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  /// 本月概览卡片
  Widget _buildMonthSummary(
    AsyncValue monthAsync,
    ColorScheme colorScheme,
  ) {
    return monthAsync.when(
      data: (stats) {
        if (stats.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: EmberEmptyState(
              message: '这个月还没有记录',
              subMessage: '去投放一些情绪吧',
              icon: Icons.calendar_today_outlined,
            ),
          );
        }

        final totalCount = stats.fold<int>(0, (sum, s) => sum + (s.totalCount as int));
        final intensitySum = stats.fold<int>(0, (sum, s) => sum + (s.intensitySum as int));
        final avgIntensity = totalCount > 0
            ? (intensitySum / totalCount).toStringAsFixed(1)
            : '0';

        // 统计情绪分布
        final emotionCounts = <String, int>{};
        for (final s in stats) {
          final e = s.topEmotion ?? 'custom';
          emotionCounts[e] = (emotionCounts[e] ?? 0) + (s.totalCount as int);
        }
        final topEmotion = emotionCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b);
        final topE = Emotion.fromName(topEmotion.key);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '本月概览',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem(label: '投放', value: '$totalCount 次', color: colorScheme.primary),
                  _SummaryItem(label: '均烈度', value: avgIntensity, color: colorScheme.tertiary),
                  _SummaryItem(
                    label: '主情绪',
                    value: '${topE.emoji} ${topE.label}',
                    color: topE.color,
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  /// 本月词云
  Widget _buildWordCloud(String month, ColorScheme colorScheme) {
    final cloudAsync = ref.watch(wordCloudProvider(month));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '关键词云',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        cloudAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const SizedBox(
                width: double.infinity,
                height: 160,
                child: EmberEmptyState(
                  message: '暂无关键词数据',
                  subMessage: '多记录几次就能看到词云',
                  icon: Icons.bubble_chart_outlined,
                ),
              );
            }
            return Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AnimatedWordCloud(items: items),
              ),
            );
          },
          loading: () => const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
