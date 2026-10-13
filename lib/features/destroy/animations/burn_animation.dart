import 'dart:math';

import 'package:flutter/material.dart';

import 'package:ember/core/constants/destroy_styles.dart';
import 'package:ember/core/theme/typography.dart';
import 'destroy_animation.dart';

/// 焚 — 文字像纸，从下沿被一条余烬线慢慢吞掉。
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
      duration: Duration(milliseconds: 2200 + (6 - widget.intensity) * 180),
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
    final t = _controller.value;
    final fade = t < 0.88 ? 1.0 : (1 - (t - 0.88) / 0.12).clamp(0.0, 1.0);

    final readable = AppTypography.literary.copyWith(
      color: colorScheme.onSurface,
      fontSize: 22,
    );
    final charred = AppTypography.literary.copyWith(
      color: const Color(0xFF3A2218),
      fontSize: 22,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Center(
          child: Opacity(
            opacity: fade,
            child: SizedBox(
              width: 280,
              child: CustomPaint(
                foregroundPainter: _EdgeBurnPainter(
                  progress: t,
                  intensity: widget.intensity,
                ),
                child: Stack(
                  children: [
                    Text(
                      widget.textHint ?? '烧掉它',
                      textAlign: TextAlign.center,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: charred,
                    ),
                    ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (bounds) {
                        final edge = (1 - t).clamp(0.0, 1.0);
                        final feather = (edge - 0.045).clamp(0.0, 1.0);
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: const [
                            Colors.white,
                            Colors.white,
                            Colors.transparent,
                          ],
                          stops: [0, feather, edge],
                        ).createShader(bounds);
                      },
                      child: Text(
                        widget.textHint ?? '烧掉它',
                        textAlign: TextAlign.center,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: readable,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EdgeBurnPainter extends CustomPainter {
  final double progress;
  final int intensity;

  _EdgeBurnPainter({required this.progress, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1 || size.height < 2) return;

    final y = size.height * (1 - progress);
    final rng = Random(7);
    final sparks = 5 + intensity;

    final glow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFFB598).withValues(alpha: 0.0),
          const Color(0xFFE46F3A).withValues(alpha: 0.85),
          const Color(0xFF591D00).withValues(alpha: 0.0),
        ],
        stops: const [0, 0.45, 1],
      ).createShader(Rect.fromLTWH(0, y - 10, size.width, 22));
    canvas.drawRect(Rect.fromLTWH(0, y - 10, size.width, 22), glow);

    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = const Color(0xFFF3DED7).withValues(alpha: 0.9)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < sparks; i++) {
      final life = (progress * 1.4 + rng.nextDouble()) % 1.0;
      if (life > 0.65) continue;
      final x = rng.nextDouble() * size.width;
      final rise = life * (18 + intensity * 4);
      final alpha = (1 - life / 0.65) * 0.8;
      canvas.drawCircle(
        Offset(x, y - rise),
        1.1 + rng.nextDouble() * 0.8,
        Paint()..color = const Color(0xFFE46F3A).withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EdgeBurnPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
