import 'dart:math';

import 'package:flutter/material.dart';

import 'package:ember/core/constants/destroy_styles.dart';
import 'destroy_animation.dart';

/// 烬 ✨ — 余烬飘散，温暖消逝
class AshAnimation extends DestroyAnimationWidget {
  const AshAnimation({
    super.key,
    super.style = DestroyStyle.ash,
    super.intensity = 3,
    required super.onComplete,
    super.textHint,
  });

  @override
  State<AshAnimation> createState() => _AshAnimationState();
}

class _AshAnimationState extends State<AshAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_AshParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2500 + (6 - widget.intensity) * 200),
    );

    _particles = _generateParticles();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    _controller.forward();
  }

  List<_AshParticle> _generateParticles() {
    final rng = Random(2024);
    final count = 15 + widget.intensity * 6;
    return List.generate(count, (i) {
      return _AshParticle(
        startX: rng.nextDouble(),
        startY: 0.6 + rng.nextDouble() * 0.4,
        driftX: (rng.nextDouble() - 0.5) * 0.3,
        speed: 0.3 + rng.nextDouble() * 0.7,
        size: 1.5 + rng.nextDouble() * 3.5,
        delay: rng.nextDouble() * 0.4,
        brightness: 0.4 + rng.nextDouble() * 0.6,
        flickerSpeed: 2.0 + rng.nextDouble() * 3.0,
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
            // 文字渐隐
            if (_controller.value < 0.6)
              Opacity(
                opacity: 1.0 - (_controller.value / 0.6),
                child: Text(
                  widget.textHint ?? '化为余烬',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // 余烬粒子
            CustomPaint(
              size: const Size(300, 400),
              painter: _AshPainter(
                progress: _controller.value,
                particles: _particles,
                intensity: widget.intensity,
              ),
            ),

            // 完成提示
            if (_controller.value > 0.85)
              Opacity(
                opacity: (_controller.value - 0.85) / 0.15,
                child: Text(
                  '余烬已冷',
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

class _AshParticle {
  final double startX;
  final double startY;
  final double driftX;
  final double speed;
  final double size;
  final double delay;
  final double brightness;
  final double flickerSpeed;

  _AshParticle({
    required this.startX,
    required this.startY,
    required this.driftX,
    required this.speed,
    required this.size,
    required this.delay,
    required this.brightness,
    required this.flickerSpeed,
  });
}

class _AshPainter extends CustomPainter {
  final double progress;
  final List<_AshParticle> particles;
  final int intensity;

  _AshPainter({
    required this.progress,
    required this.particles,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final effectiveProgress =
          ((progress - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
      if (effectiveProgress <= 0) continue;

      // 粒子向上飘动
      final x = (p.startX + p.driftX * sin(effectiveProgress * pi * 2)) * size.width;
      final y = (p.startY - effectiveProgress * 0.7 * p.speed) * size.height;

      // 闪烁效果
      final flicker = 0.5 + 0.5 * sin(effectiveProgress * pi * p.flickerSpeed);
      final alpha = flicker * (1.0 - effectiveProgress * 0.6) * p.brightness;

      if (alpha <= 0) continue;

      // 余烬颜色：暖橙 → 暗红 → 灰
      final Color color;
      if (effectiveProgress < 0.4) {
        color = Color.lerp(
          const Color(0xFFFFAB40),
          const Color(0xFFFF6D00),
          effectiveProgress / 0.4,
        )!;
      } else if (effectiveProgress < 0.7) {
        color = Color.lerp(
          const Color(0xFFFF6D00),
          const Color(0xFF8D3B00),
          (effectiveProgress - 0.4) / 0.3,
        )!;
      } else {
        color = Color.lerp(
          const Color(0xFF8D3B00),
          const Color(0xFF4A4A4A),
          (effectiveProgress - 0.7) / 0.3,
        )!;
      }

      final particleSize = p.size * (1.0 + sin(effectiveProgress * pi) * 0.3);

      // 光晕
      if (effectiveProgress < 0.5) {
        canvas.drawCircle(
          Offset(x, y),
          particleSize * 3,
          Paint()
            ..color = color.withValues(alpha: alpha * 0.15)
            ..style = PaintingStyle.fill,
        );
      }

      // 核心粒子
      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.fill,
      );

      // 亮芯
      if (effectiveProgress < 0.4) {
        canvas.drawCircle(
          Offset(x, y),
          particleSize * 0.4,
          Paint()
            ..color = const Color(0xFFFFF8E1)
                .withValues(alpha: alpha * 0.6)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AshPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
