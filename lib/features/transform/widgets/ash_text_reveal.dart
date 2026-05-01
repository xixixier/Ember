import 'dart:math';
import 'package:flutter/material.dart';

/// 灰烬聚合文字 — 转化结果文字渐现动画
/// 粒子从随机位置聚合 → 文字渐现 → 粒子消融散开
class AshTextReveal extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;

  const AshTextReveal({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 2200),
  });

  @override
  State<AshTextReveal> createState() => _AshTextRevealState();
}

class _AshTextRevealState extends State<AshTextReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _rng = Random(42);

  List<_AshParticle>? _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 在布局后计算文字区域并生成粒子
  void _initParticles(double width, double height, Color primaryColor) {
    if (_particles != null) return;

    final style = widget.style ?? const TextStyle(fontSize: 16, height: 1.8);
    final padding = 16.0;
    final contentWidth = width - padding * 2;

    // 用 TextPainter 布局文字，获取文本区域
    final tp = TextPainter(
      text: TextSpan(text: widget.text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: contentWidth);

    final textHeight = tp.height;
    final textWidth = tp.width;

    // 在文字区域内随机采样目标点
    final count = 35;
    final particles = <_AshParticle>[];

    for (var i = 0; i < count; i++) {
      final tx = padding + _rng.nextDouble() * textWidth;
      final ty = padding + _rng.nextDouble() * textHeight;

      particles.add(_AshParticle(
        startX: _rng.nextDouble() * width,
        startY: _rng.nextDouble() * height,
        targetX: tx,
        targetY: ty,
        endX: tx + (_rng.nextDouble() - 0.5) * 60,
        endY: ty - 20 - _rng.nextDouble() * 40,
        size: 1.0 + _rng.nextDouble() * 1.5,
        delay: _rng.nextDouble() * 0.15,
      ));
    }

    _particles = particles;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final style = widget.style ?? TextStyle(
      color: colorScheme.onSurface,
      fontSize: 16,
      height: 1.8,
      fontWeight: FontWeight.w400,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        _initParticles(constraints.maxWidth, 200, primary);

        return SizedBox(
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;

              return Stack(
                children: [
                  // 文字层 — 渐现（30%~60%）
                  Opacity(
                    opacity: ((t - 0.3) / 0.3).clamp(0.0, 1.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        widget.text,
                        style: style,
                      ),
                    ),
                  ),

                  // 粒子层
                  if (_particles != null)
                    SizedBox.expand(
                      child: CustomPaint(
                        painter: _AshParticlePainter(
                          particles: _particles!,
                          t: t,
                          color: primary,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// 粒子数据
class _AshParticle {
  final double startX;
  final double startY;
  final double targetX;
  final double targetY;
  final double endX;
  final double endY;
  final double size;
  final double delay;

  const _AshParticle({
    required this.startX,
    required this.startY,
    required this.targetX,
    required this.targetY,
    required this.endX,
    required this.endY,
    required this.size,
    required this.delay,
  });
}

/// 粒子绘制器
class _AshParticlePainter extends CustomPainter {
  final List<_AshParticle> particles;
  final double t;
  final Color color;

  _AshParticlePainter({
    required this.particles,
    required this.t,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final localT = ((t - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);

      double x, y, alpha;

      if (localT < 0.4) {
        // 聚合（0~40%）
        final at = _easeOutCubic(localT / 0.4);
        x = p.startX + (p.targetX - p.startX) * at;
        y = p.startY + (p.targetY - p.startY) * at;
        alpha = 0.5 * at;
      } else if (localT < 0.7) {
        // 驻留（40%~70%）— 与文字共存
        x = p.targetX;
        y = p.targetY;
        alpha = 0.5 - (localT - 0.4) / 0.3 * 0.4;
      } else {
        // 消融（70%~100%）
        final at = _easeInCubic((localT - 0.7) / 0.3);
        x = p.targetX + (p.endX - p.targetX) * at;
        y = p.targetY + (p.endY - p.targetY) * at;
        alpha = 0.1 * (1.0 - at);
      }

      if (alpha < 0.01) continue;

      canvas.drawCircle(
        Offset(x, y),
        p.size,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
  }

  double _easeOutCubic(double t) => 1 - pow(1 - t, 3).toDouble();
  double _easeInCubic(double t) => t * t * t;

  @override
  bool shouldRepaint(covariant _AshParticlePainter old) => old.t != t;
}
