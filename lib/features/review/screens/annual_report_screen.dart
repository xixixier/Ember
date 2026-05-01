import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ember/core/constants/targets.dart';
import 'package:ember/core/providers/database_provider.dart';
import 'package:ember/features/review/services/annual_report_service.dart';
import 'package:ember/features/review/widgets/word_cloud_painter.dart';

/// 年度情绪年鉴页面
/// 长滚动：封面 → 情绪地图 → 月度曲线 → 关键词 → 总结
class AnnualReportScreen extends ConsumerStatefulWidget {
  final int year;

  const AnnualReportScreen({super.key, required this.year});

  @override
  ConsumerState<AnnualReportScreen> createState() => _AnnualReportScreenState();
}

class _AnnualReportScreenState extends ConsumerState<AnnualReportScreen> {
  AnnualData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final statsDao = ref.read(dailyStatsDaoProvider);
    final keywordDao = ref.read(keywordDaoProvider);
    final service = AnnualReportService(statsDao, keywordDao);
    final data = await service.getAnnualData(widget.year);
    if (mounted) {
      setState(() {
        _data = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? Center(child: Text('加载失败', style: TextStyle(color: colorScheme.error)))
              : CustomScrollView(
                  slivers: [
                    // 封面
                    SliverToBoxAdapter(child: _buildCover(colorScheme)),
                    // 情绪地图
                    SliverToBoxAdapter(child: _buildEmotionMap(colorScheme)),
                    // 月度投放次数
                    SliverToBoxAdapter(child: _buildMonthlyChart(colorScheme)),
                    // 月度烈度
                    SliverToBoxAdapter(
                        child: _buildMonthlyIntensityChart(colorScheme)),
                    // 关键词
                    SliverToBoxAdapter(child: _buildKeywords(colorScheme)),
                    // 年度总结
                    SliverToBoxAdapter(child: _buildSummary(colorScheme)),
                    // 底部留白
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 80),
                    ),
                  ],
                ),
    );
  }

  /// 封面
  Widget _buildCover(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary.withValues(alpha: 0.2),
            colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            '${widget.year}',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 64,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '年度情绪年鉴',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w300,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '你一共投放了 ${_data!.totalCount} 次',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 情绪地图 — 环形图
  Widget _buildEmotionMap(ColorScheme colorScheme) {
    final dist = _data!.emotionDistribution;
    final total = dist.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final sorted = dist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: '情绪地图', color: colorScheme.primary),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: CustomPaint(
              size: const Size(180, 180),
              painter: _DonutChartPainter(
                segments: sorted
                    .map((e) => _ChartSegment(
                          value: e.value,
                          color: e.key.color,
                          label: '${e.key.emoji} ${e.key.label}',
                        ))
                    .toList(),
                total: total,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: sorted.map((e) {
              final pct = (e.value / total * 100).toStringAsFixed(0);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: e.key.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${e.key.emoji} ${e.key.label} $pct%',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 月度投放次数柱状图
  Widget _buildMonthlyChart(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: '月度投放', color: colorScheme.tertiary),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: CustomPaint(
              size: Size.infinite,
              painter: _BarChartPainter(
                values: List.generate(12, (i) => _data!.monthlyCounts[i + 1]?.toDouble() ?? 0),
                color: colorScheme.primary,
                labels: List.generate(12, (i) => '${i + 1}月'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 月度烈度折线图
  Widget _buildMonthlyIntensityChart(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: '月度烈度', color: colorScheme.tertiary),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: Size.infinite,
              painter: _LineChartPainter(
                values: List.generate(12, (i) => _data!.monthlyAvgIntensity[i + 1] ?? 0),
                color: colorScheme.tertiary,
                maxValue: 5.0,
                labels: List.generate(12, (i) => '${i + 1}'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 关键词
  Widget _buildKeywords(ColorScheme colorScheme) {
    if (_data!.topKeywords.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: '年度关键词', color: colorScheme.secondary),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: Size.infinite,
              painter: WordCloudPainter(items: _data!.topKeywords),
            ),
          ),
        ],
      ),
    );
  }

  /// 年度总结
  Widget _buildSummary(ColorScheme colorScheme) {
    final d = _data!;
    final summary = _generateSummary(d);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withValues(alpha: 0.12),
              colorScheme.primary.withValues(alpha: 0.04),
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
                  '年度洞察',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              summary,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 15,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _generateSummary(AnnualData d) {
    final buffers = <String>[];
    buffers.add('${d.year}年，你向余烬投放了${d.totalCount}次情绪。');

    if (d.totalCount == 0) {
      buffers.add('这一年，平静如水。');
    } else {
      buffers.add('主情绪是${d.topEmotion.emoji}${d.topEmotion.label}，');
      if (d.topTarget != Target.none) {
        buffers.add('主要指向「${d.topTarget.label}」。');
      } else {
        buffers.add('没有特定的指向。');
      }

      if (d.avgIntensity >= 4) {
        buffers.add('你的情绪烈度很高，这一年一定不容易。');
      } else if (d.avgIntensity >= 2.5) {
        buffers.add('情绪起伏有度，你在学习与自己相处。');
      } else {
        buffers.add('总体情绪温和，你处理得不错。');
      }

      buffers.add('每一次投放，都是你面对自己的勇敢。');
    }

    return buffers.join();
  }
}

/// 小节标题
class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// 环形图数据
class _ChartSegment {
  final int value;
  final Color color;
  final String label;
  _ChartSegment({required this.value, required this.color, required this.label});
}

/// 环形图 Painter
class _DonutChartPainter extends CustomPainter {
  final List<_ChartSegment> segments;
  final int total;

  _DonutChartPainter({required this.segments, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final strokeWidth = 24.0;

    var startAngle = -pi / 2;

    for (final seg in segments) {
      final sweepAngle = (seg.value / total) * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = seg.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      startAngle += sweepAngle;
    }

    // 中心文字
    final tp = TextPainter(
      text: TextSpan(
        text: '$total',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(center.dx - tp.width / 2, center.dy - tp.height / 2);
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.segments != segments;
}

/// 柱状图 Painter
class _BarChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final List<String> labels;

  _BarChartPainter({required this.values, required this.color, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = values.reduce(max);
    if (maxVal == 0) return;

    final barWidth = (size.width - 24) / 12 * 0.6;
    final gap = (size.width - 24) / 12;
    final chartHeight = size.height - 20;

    for (var i = 0; i < 12; i++) {
      final x = 12 + i * gap + (gap - barWidth) / 2;
      final barHeight = (values[i] / maxVal) * chartHeight;
      final y = chartHeight - barHeight;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          Radius.circular(barWidth / 3),
        ),
        Paint()..color = color.withValues(alpha: 0.6),
      );

      // 标签
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(color: Colors.white38, fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(x + barWidth / 2 - tp.width / 2, chartHeight + 4);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.values != values;
}

/// 折线图 Painter
class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double maxValue;
  final List<String> labels;

  _LineChartPainter({
    required this.values,
    required this.color,
    required this.maxValue,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.every((v) => v == 0)) return;

    final chartHeight = size.height - 20;
    final gap = (size.width - 24) / 11;

    final points = <Offset>[];
    for (var i = 0; i < 12; i++) {
      final x = 12 + i * gap;
      final y = chartHeight - (values[i] / maxValue) * chartHeight;
      points.add(Offset(x, y));

      // 标签
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(color: Colors.white38, fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(x - tp.width / 2, chartHeight + 4);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }

    // 填充区域
    final areaPath = Path()
      ..moveTo(points.first.dx, chartHeight)
      ..addPolygon(points, false)
      ..lineTo(points.last.dx, chartHeight)
      ..close();
    canvas.drawPath(
      areaPath,
      Paint()
        ..color = color.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill,
    );

    // 折线
    final linePath = Path()..addPolygon(points, false);
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // 数据点
    for (final p in points) {
      canvas.drawCircle(p, 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.values != values;
}
