import 'dart:math';

import 'package:flutter/material.dart';

import 'package:ember/core/constants/destroy_styles.dart';
import 'destroy_animation.dart';

/// 焚 🔥 — 火焰粒子上升燃烧
class BurnAnimation extends DestroyAnimationWidget {
  const BurnAnimation({
    super.key,
    super.style = DestroyStyle.burn,
    super.intensity = 3,
    required super.onComplete,
    super.textHint,
  });

  @override
  State<BurnAnimation> createState() => _BurnAnimationState();
}

class _BurnAnimationState extends State<BurnAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000 + (6 - widget.intensity) * 200),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // 文字渐隐
            if (_controller.value < 0.7)
              Opacity(
                opacity: 1.0 - (_controller.value / 0.7),
                child: Text(
                  widget.textHint ?? '烧掉它',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // 火焰粒子
            CustomPaint(
              size: const Size(300, 400),
              painter: _FlamePainter(
                progress: _controller.value,
                intensity: widget.intensity,
              ),
            ),

            // 灰烬消散
            if (_controller.value > 0.8)
              Opacity(
                opacity: (_controller.value - 0.8) / 0.2,
                child: Text(
                  '已化为灰烬',
                  style: TextStyle(
                    color: colorScheme.primary.withValues(alpha: 0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FlamePainter extends CustomPainter {
  final double progress;
  final int intensity;

  _FlamePainter({required this.progress, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    final particleCount = 15 + intensity * 8;

    for (var i = 0; i < particleCount; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseSpeed = 0.5 + rng.nextDouble() * 0.8;
      final particleProgress = (progress * baseSpeed * 1.5).clamp(0.0, 1.0);

      if (particleProgress >= 1.0) continue;

      final y = size.height * (1.0 - particleProgress);
      final xOffset = (rng.nextDouble() - 0.5) * 40 * sin(particleProgress * pi);
      final x = baseX + xOffset;

      // 粒子大小随上升减小
      final baseSize = 4.0 + rng.nextDouble() * 6.0;
      final particleSize = baseSize * (1.0 - particleProgress * 0.7);

      // 颜色：底部橙红，顶部暗红/灰
      final t = particleProgress;
      final color = Color.lerp(
        const Color(0xFFFF6B35),
        const Color(0xFF4A1508),
        t,
      )!.withValues(alpha: 1.0 - t * 0.5);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      // 火焰形状（椭圆+微变形）
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: particleSize * 1.5,
          height: particleSize * 2.5,
        ),
        paint,
      );

      // 内核亮色
      if (t < 0.5) {
        final coreColor = Color.lerp(
          const Color(0xFFFFF176),
          const Color(0xFFFF9800),
          t * 2,
        )!.withValues(alpha: 0.6 * (1.0 - t * 2));
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, y + particleSize * 0.3),
            width: particleSize * 0.6,
            height: particleSize,
          ),
          Paint()..color = coreColor,
        );
      }
    }

    // 底部光晕
    if (progress < 0.8) {
      final glowAlpha = 0.3 * (1.0 - progress / 0.8);
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF6B35).withValues(alpha: glowAlpha),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4));
      canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4),
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FlamePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
