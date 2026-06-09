import 'dart:math';

import 'package:flutter/material.dart';

import 'package:ember/core/constants/destroy_styles.dart';
import 'destroy_animation.dart';

/// 散 🌬️ — 粒子从中心向外扩散消失
class ScatterAnimation extends DestroyAnimationWidget {
  const ScatterAnimation({
    super.key,
    super.style = DestroyStyle.scatter,
    super.intensity = 3,
    required super.onComplete,
    super.textHint,
  });

  @override
  State<ScatterAnimation> createState() => _ScatterAnimationState();
}

class _ScatterAnimationState extends State<ScatterAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000 + (6 - widget.intensity) * 200),
    );

    _particles = _generateParticles();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    _controller.forward();
  }

  List<_Particle> _generateParticles() {
    final rng = Random(777);
    final count = 20 + widget.intensity * 10;
    return List.generate(count, (i) {
      final angle = rng.nextDouble() * 2 * pi;
      final speed = 0.5 + rng.nextDouble() * 1.5;
      final size = 2.0 + rng.nextDouble() * 5.0;
      final delay = rng.nextDouble() * 0.3;
      // 文字碎片颜色
      final hue = rng.nextDouble() * 60 + 20; // 暖色调
      final color = HSLColor.fromAHSL(1.0, hue, 0.5, 0.5 + rng.nextDouble() * 0.3).toColor();
      return _Particle(
        angle: angle,
        speed: speed,
        size: size,
        delay: delay,
        color: color,
      );
    });
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
            // 文字碎裂+消失
            if (_controller.value < 0.5)
              Opacity(
                opacity: (1.0 - (_controller.value * 2)).clamp(0.0, 1.0),
                child: SizedBox(
                  width: 280,
                  child: Text(
                    widget.textHint ?? '随风散去',
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            // 粒子扩散
            CustomPaint(
              size: const Size(300, 400),
              painter: _ScatterPainter(
                progress: _controller.value,
                particles: _particles,
              ),
            ),

            // 完成提示
            if (_controller.value > 0.85)
              Opacity(
                opacity: (_controller.value - 0.85) / 0.15,
                child: Text(
                  '已随风散去',
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

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final double delay;
  final Color color;

  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.delay,
    required this.color,
  });
}

class _ScatterPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;

  _ScatterPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.6;

    for (final p in particles) {
      // 每个粒子有自己的延迟
      final effectiveProgress = ((progress - p.delay) / (1.0 - p.delay))
          .clamp(0.0, 1.0);
      if (effectiveProgress <= 0) continue;

      final radius = maxRadius * effectiveProgress * p.speed;
      final x = center.dx + cos(p.angle) * radius;
      final y = center.dy + sin(p.angle) * radius;

      // 透明度先增后减
      final alpha = effectiveProgress < 0.3
          ? effectiveProgress / 0.3
          : 1.0 - ((effectiveProgress - 0.3) / 0.7);

      final particleSize = p.size * (1.0 + effectiveProgress * 0.5);

      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        Paint()
          ..color = p.color.withValues(alpha: alpha.clamp(0.0, 1.0))
          ..style = PaintingStyle.fill,
      );

      // 拖尾
      if (effectiveProgress > 0.1 && effectiveProgress < 0.8) {
        final tailLength = radius * 0.2;
        final tx = x - cos(p.angle) * tailLength;
        final ty = y - sin(p.angle) * tailLength;
        canvas.drawLine(
          Offset(tx, ty),
          Offset(x, y),
          Paint()
            ..color = p.color.withValues(alpha: alpha * 0.4)
            ..strokeWidth = p.size * 0.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ScatterPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
