import 'package:flutter/material.dart';
import 'package:ember/features/review/widgets/heat_map_calendar.dart';

/// 动画版热力图 — 光点浮现错峰 + 高烈度日期闪烁
///
/// 包裹 [HeatMapCalendarPainter]，添加：
/// - 月份切换时整体淡入
/// - 各日期格子错峰浮现（staggered reveal）
/// - 高烈度日期（count >= 4）微弱闪烁
class AnimatedHeatMapCalendar extends StatefulWidget {
  final DateTime month;
  final Map<String, DayData> dayDataMap;
  final String? selectedDate;
  final Color headerColor;
  final Color dayTextColor;
  final Color emptyColor;
  final Color selectedBorderColor;
  final Size size;

  const AnimatedHeatMapCalendar({
    super.key,
    required this.month,
    required this.dayDataMap,
    this.selectedDate,
    required this.headerColor,
    required this.dayTextColor,
    required this.emptyColor,
    required this.selectedBorderColor,
    required this.size,
  });

  @override
  State<AnimatedHeatMapCalendar> createState() =>
      _AnimatedHeatMapCalendarState();
}

class _AnimatedHeatMapCalendarState extends State<AnimatedHeatMapCalendar>
    with SingleTickerProviderStateMixin {
  late AnimationController _revealController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant AnimatedHeatMapCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month != widget.month) {
      _revealController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_revealController, _pulseController]),
      builder: (context, _) {
        return CustomPaint(
          size: widget.size,
          painter: HeatMapCalendarPainter(
            month: widget.month,
            dayDataMap: widget.dayDataMap,
            selectedDate: widget.selectedDate,
            headerColor: widget.headerColor,
            dayTextColor: widget.dayTextColor,
            emptyColor: widget.emptyColor,
            selectedBorderColor: widget.selectedBorderColor,
            revealProgress: _revealController.value,
            pulseValue: _pulseController.value,
          ),
        );
      },
    );
  }
}
