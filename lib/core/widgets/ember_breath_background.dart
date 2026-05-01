import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 首页余烬呼吸光背景 (DESIGN.md §2.1)
///
/// 中心径向渐变在 opacity 0.03 ~ 0.08 之间周期性脉动，
/// 营造"余烬还在燃烧"的微弱呼吸感。
///
/// 使用方式：
/// ```dart
/// Stack(
///   children: [
///     const EmberBreathBackground(),
///     // 其他内容...
///   ],
/// )
/// ```
class EmberBreathBackground extends StatefulWidget {
  /// 呼吸周期，默认 6 秒
  final Duration period;

  /// 中心光晕最小不透明度
  final double minOpacity;

  /// 中心光晕最大不透明度
  final double maxOpacity;

  /// 光晕中心位置 (0~1)，默认 (0.5, 0.35) 偏上
  final Alignment alignment;

  const EmberBreathBackground({
    super.key,
    this.period = const Duration(seconds: 6),
    this.minOpacity = 0.03,
    this.maxOpacity = 0.085,
    this.alignment = const Alignment(0.0, -0.3),
  });

  @override
  State<EmberBreathBackground> createState() => _EmberBreathBackgroundState();
}

class _EmberBreathBackgroundState extends State<EmberBreathBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _breathAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.period,
    )..repeat(reverse: true);

    // easeInOut 让呼吸感更自然（不是线性脉冲）
    _breathAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _breathAnim,
          builder: (context, _) {
            final opacity = widget.minOpacity +
                (widget.maxOpacity - widget.minOpacity) * _breathAnim.value;

            return CustomPaint(
              painter: _BreathPainter(
                color: primary,
                opacity: opacity,
                alignment: widget.alignment,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BreathPainter extends CustomPainter {
  final Color color;
  final double opacity;
  final Alignment alignment;

  const _BreathPainter({
    required this.color,
    required this.opacity,
    required this.alignment,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * ((alignment.x + 1) / 2);
    final cy = size.height * ((alignment.y + 1) / 2);

    // 主光晕：大半径柔和扩散
    final radius = math.max(size.width, size.height) * 0.75;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: opacity),
          color.withValues(alpha: opacity * 0.4),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(cx, cy),
        radius: radius,
      ));

    canvas.drawCircle(Offset(cx, cy), radius, paint);

    // 内核：更小、更亮的光点（增加层次）
    final innerRadius = size.width * 0.22;
    final innerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: opacity * 0.6),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(cx, cy),
        radius: innerRadius,
      ));

    canvas.drawCircle(Offset(cx, cy), innerRadius, innerPaint);
  }

  @override
  bool shouldRepaint(_BreathPainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.color != color;
}
