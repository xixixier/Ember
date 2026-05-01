import 'dart:math';
import 'package:flutter/material.dart';

import 'package:ember/core/constants/emotions.dart';

/// 日数据（公共类型，供热力图和日详情使用）
class DayData {
  final int count;
  final Color emotionColor;
  final String emotionName;
  final String emotionEmoji;
  final String? topTarget;
  final int intensitySum;

  DayData({
    required this.count,
    required this.emotionColor,
    required this.emotionName,
    required this.emotionEmoji,
    this.topTarget,
    required this.intensitySum,
  });
}

/// 情绪日历热力图 Painter
/// 每日格子根据 topEmotion 着色，根据 totalCount 调节透明度
///
/// 可选动画参数：
/// - [revealProgress]: 0~1，错峰浮现进度（由 AnimatedHeatMapCalendar 驱动）
/// - [pulseValue]: 0~1，高烈度日期闪烁（由 AnimatedHeatMapCalendar 驱动）
class HeatMapCalendarPainter extends CustomPainter {
  final DateTime month;
  final Map<String, DayData> dayDataMap;
  final String? selectedDate;
  final Color headerColor;
  final Color dayTextColor;
  final Color emptyColor;
  final Color selectedBorderColor;
  final double revealProgress;
  final double pulseValue;

  HeatMapCalendarPainter({
    required this.month,
    required this.dayDataMap,
    this.selectedDate,
    this.headerColor = const Color(0x89FFFFFF),
    this.dayTextColor = const Color(0xB3FFFFFF),
    this.emptyColor = const Color(0x0AFFFFFF),
    this.selectedBorderColor = const Color(0xFFFFFFFF),
    this.revealProgress = 1.0,
    this.pulseValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = (size.width - 6 * _gap) / 7; // 7列
    final headerHeight = cellSize * 0.6;
    final rowHeight = cellSize + _gap;

    // 绘制星期头
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    for (var i = 0; i < 7; i++) {
      final x = i * (cellSize + _gap) + cellSize / 2;
      _drawText(
        canvas,
        weekdays[i],
        Offset(x, headerHeight / 2),
        11,
        headerColor,
      );
    }

    // 计算月份第一天是星期几（周一=0）
    final firstDay = DateTime(month.year, month.month, 1);
    final weekdayOffset = firstDay.weekday - 1; // 0=Mon, 6=Sun
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    // 绘制日期格子
    final totalDays = daysInMonth;
    for (var day = 1; day <= totalDays; day++) {
      final cellIndex = weekdayOffset + day - 1;
      final col = cellIndex % 7;
      final row = cellIndex ~/ 7;

      final x = col * (cellSize + _gap);
      final y = headerHeight + row * rowHeight;

      final dateStr =
          '${month.year}-${month.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final data = dayDataMap[dateStr];
      final isSelected = dateStr == selectedDate;

      final rect = Rect.fromLTWH(x, y, cellSize, cellSize);
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cellSize * 0.2));

      // 错峰浮现：每个日期延迟 (day / totalDays * 0.4)
      final stagger = day / totalDays * 0.4;
      final cellReveal = ((revealProgress - stagger) / (1.0 - stagger)).clamp(0.0, 1.0);

      if (cellReveal < 0.01) continue; // 还没到浮现时间，跳过

      canvas.save();
      canvas.translate(x + cellSize / 2, y + cellSize / 2);
      canvas.scale(cellReveal, cellReveal);
      canvas.translate(-(x + cellSize / 2), -(y + cellSize / 2));

      // 浮现透明度
      final cellAlpha = _easeOutCubic(cellReveal);

      if (data != null) {
        // 有数据：根据情绪着色
        final baseColor = data.emotionColor;
        var alpha = (0.3 + (data.count / 10).clamp(0.0, 1.0) * 0.7) * cellAlpha;

        // 高烈度日期（count >= 4）闪烁
        if (data.count >= 4 && pulseValue > 0) {
          final pulse = (sin(pulseValue * 2 * pi) + 1) / 2 * 0.12;
          alpha = (alpha + pulse).clamp(0.0, 1.0);
        }

        final paint = Paint()
          ..color = baseColor.withValues(alpha: alpha)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(rrect, paint);

        // 数字
        _drawText(
          canvas,
          '$day',
          Offset(x + cellSize / 2, y + cellSize / 2),
          12,
          (isSelected ? selectedBorderColor : dayTextColor).withValues(alpha: cellAlpha),
        );

        // 情绪小点
        canvas.drawCircle(
          Offset(x + cellSize / 2, y + cellSize - 6),
          2.5,
          Paint()..color = baseColor.withValues(alpha: cellAlpha),
        );
      } else {
        // 无数据：暗色空格
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = emptyColor.withValues(alpha: cellAlpha)
            ..style = PaintingStyle.fill,
        );
        _drawText(
          canvas,
          '$day',
          Offset(x + cellSize / 2, y + cellSize / 2),
          12,
          emptyColor.withValues(alpha: cellAlpha),
        );
      }

      // 选中框
      if (isSelected) {
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = selectedBorderColor.withValues(alpha: cellAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      canvas.restore();
    }
  }

  void _drawText(Canvas canvas, String text, Offset center, double fontSize, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  static const double _gap = 4;

  double _easeOutCubic(double t) => 1 - pow(1 - t, 3).toDouble();

  @override
  bool shouldRepaint(covariant HeatMapCalendarPainter oldDelegate) {
    return oldDelegate.month != month ||
        oldDelegate.dayDataMap != dayDataMap ||
        oldDelegate.selectedDate != selectedDate ||
        oldDelegate.headerColor != headerColor ||
        oldDelegate.dayTextColor != dayTextColor ||
        oldDelegate.emptyColor != emptyColor ||
        oldDelegate.selectedBorderColor != selectedBorderColor ||
        oldDelegate.revealProgress != revealProgress ||
        oldDelegate.pulseValue != pulseValue;
  }
}

/// 从 DailyStat 列表构建 dayDataMap
Map<String, DayData> buildDayDataMap(List<dynamic> stats) {
  final map = <String, DayData>{};
  for (final stat in stats) {
    final emotion = Emotion.fromName(stat.topEmotion ?? 'custom');
    map[stat.date] = DayData(
      count: stat.totalCount,
      emotionColor: emotion.color,
      emotionName: emotion.label,
      emotionEmoji: emotion.emoji,
      topTarget: stat.topTarget,
      intensitySum: stat.intensitySum,
    );
  }
  return map;
}
