import 'dart:math';

import 'package:flutter/material.dart';

import 'package:ember/core/constants/destroy_styles.dart';
import 'destroy_animation.dart';

/// 沉 🌊 — 文字缓缓下沉，水面合拢覆盖
class SinkAnimation extends DestroyAnimationWidget {
  const SinkAnimation({
    super.key,
    super.style = DestroyStyle.sink,
    super.intensity = 3,
    required super.onComplete,
    super.textHint,
  });

  @override
  State<SinkAnimation> createState() => _SinkAnimationState();
}

class _SinkAnimationState extends State<SinkAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2500 + (6 - widget.intensity) * 200),
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
            // 文字下沉
            Transform.translate(
              offset: Offset(0, _controller.value * 120),
              child: Opacity(
                opacity: 1.0 - (_controller.value * 1.2).clamp(0.0, 1.0),
                child: SizedBox(
                  width: 280,
                  child: Text(
                    widget.textHint ?? '沉入深渊',
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
            ),

            // 水面动画
            CustomPaint(
              size: const Size(300, 400),
              painter: _WaterPainter(
                progress: _controller.value,
                intensity: widget.intensity,
              ),
            ),

            // 完成提示
            if (_controller.value > 0.85)
              Opacity(
                opacity: ((_controller.value - 0.85) / 0.15).clamp(0.0, 1.0),
                child: Text(
                  '已沉入深渊',
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

class _WaterPainter extends CustomPainter {
  final double progress;
  final int intensity;

  _WaterPainter({required this.progress, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    // 水面从底部上升
    final waterLevel = size.height * (1.0 - progress * 0.85);

    // 水面波浪
    final wavePaint = Paint()
      ..style = PaintingStyle.fill;

    // Dark gradient background (Deep Dark Foundation)
    final deepColor = const Color(0xFF1B110D).withValues(alpha: 0.6 + progress * 0.3);
    wavePaint.color = deepColor;
    canvas.drawRect(
      Rect.fromLTWH(0, waterLevel + 10, size.width, size.height - waterLevel),
      wavePaint,
    );

    // 波浪线
    final wavePath = Path();
    wavePath.moveTo(0, waterLevel);

    for (var x = 0.0; x <= size.width; x++) {
      final wave1 = sin((x / size.width * 4 * pi) + progress * 6) * 8;
      final wave2 = sin((x / size.width * 6 * pi) + progress * 4) * 4;
      wavePath.lineTo(x, waterLevel + wave1 + wave2);
    }

    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();

    final surfaceColor =
        const Color(0xFF3F322D).withValues(alpha: 0.5 + progress * 0.4);
    canvas.drawPath(wavePath, Paint()..color = surfaceColor);

    // 水面光泽
    if (progress > 0.1 && progress < 0.9) {
      final highlightPaint = Paint()
        ..color = const Color(0xFFA58B81).withValues(alpha: 0.15);
      canvas.drawPath(wavePath, highlightPaint);
    }

    // 气泡
    final rng = Random(123);
    final bubbleCount = 5 + intensity * 3;
    for (var i = 0; i < bubbleCount; i++) {
      final bx = rng.nextDouble() * size.width;
      final baseY = size.height * 0.7 + rng.nextDouble() * size.height * 0.3;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final by = baseY - progress * size.height * 0.5 * speed;

      if (by < waterLevel) continue;

      final bubbleR = 2.0 + rng.nextDouble() * 4.0;
      final bubbleAlpha = 0.3 + rng.nextDouble() * 0.3;

      canvas.drawCircle(
        Offset(bx, by),
        bubbleR,
        Paint()
          ..color = const Color(0xFFA58B81).withValues(alpha: bubbleAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaterPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
