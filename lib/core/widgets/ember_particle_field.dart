import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 首页余烬漂浮粒子效果 (DESIGN.md §2.2)
///
/// 12 个细小粒子，缓慢上浮 + 正弦横向漂移，
/// 颜色跟随主题 primary，透明度 0.05~0.15。
///
/// 使用方式：
/// ```dart
/// Stack(
///   children: [
///     const EmberBreathBackground(),
///     const EmberParticleField(),
///     // 其他内容...
///   ],
/// )
/// ```
class EmberParticleField extends StatefulWidget {
  final int particleCount;

  const EmberParticleField({
    super.key,
    this.particleCount = 12,
  });

  @override
  State<EmberParticleField> createState() => _EmberParticleFieldState();
}

class _EmberParticleFieldState extends State<EmberParticleField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final _random = math.Random(42); // 固定 seed，避免布局跳变

  @override
  void initState() {
    super.initState();
    _particles = List.generate(
      widget.particleCount,
      (i) => _Particle.random(_random, i),
    );

    // 一次 ticker，粒子通过 progress 自行推算当前位置
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
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
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _controller.value,
                  color: primary,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── 粒子数据 ─────────────────────────────────────────────────────────

class _Particle {
  /// x 初始位置 (0~1)
  final double x;

  /// y 初始位置 (0~1)，从底部 80%~100% 范围起始
  final double yStart;

  /// 上浮周期 (秒)，8~15s
  final double period;

  /// 相位偏移 (0~1)，让粒子不同步
  final double phase;

  /// 横向摆幅 (0~1 相对屏宽)
  final double swingAmp;

  /// 横向摆动频率倍数 (1 or 2)
  final double swingFreq;

  /// 粒子半径 px (1~3)
  final double radius;

  /// 最大透明度
  final double maxAlpha;

  const _Particle({
    required this.x,
    required this.yStart,
    required this.period,
    required this.phase,
    required this.swingAmp,
    required this.swingFreq,
    required this.radius,
    required this.maxAlpha,
  });

  factory _Particle.random(math.Random rng, int seed) {
    return _Particle(
      x: rng.nextDouble(),
      yStart: 0.7 + rng.nextDouble() * 0.3,
      period: 8.0 + rng.nextDouble() * 7.0,
      phase: rng.nextDouble(),
      swingAmp: 0.02 + rng.nextDouble() * 0.04,
      swingFreq: rng.nextBool() ? 1.0 : 2.0,
      radius: 1.0 + rng.nextDouble() * 2.0,
      maxAlpha: 0.05 + rng.nextDouble() * 0.10,
    );
  }
}

// ─── 画笔 ────────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress; // 0.0 ~ 1.0 (15s 循环)
  final Color color;

  const _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      // 当前粒子在自己周期内的进度（0~1）
      final t = ((progress * 15.0 / p.period) + p.phase) % 1.0;

      // 纵向：从 yStart 上浮到 yStart - 1.1（离开屏幕）
      final y = (p.yStart - t * 1.1) * size.height;

      // 超出屏幕边界则跳过
      if (y < -p.radius * 2 || y > size.height + p.radius) continue;

      // 横向：正弦摆动
      final swing = math.sin(t * math.pi * 2.0 * p.swingFreq) * p.swingAmp;
      final x = (p.x + swing) * size.width;

      // 透明度：起始时淡入(0→maxAlpha)，快离开时淡出(maxAlpha→0)
      double alpha;
      if (t < 0.1) {
        alpha = p.maxAlpha * (t / 0.1);
      } else if (t > 0.85) {
        alpha = p.maxAlpha * ((1.0 - t) / 0.15);
      } else {
        alpha = p.maxAlpha;
      }

      paint.color = color.withValues(alpha: alpha.clamp(0.0, 1.0));

      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
