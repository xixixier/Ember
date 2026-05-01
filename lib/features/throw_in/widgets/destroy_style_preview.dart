import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ember/core/constants/destroy_styles.dart';

/// 销毁方式微预览动画 — 嵌入 DestroyTimePicker 的方式选择卡片
/// 每种方式用 CustomPainter 绘制微型动画效果
class DestroyStylePreview extends StatefulWidget {
  final DestroyStyle style;
  final bool isSelected;

  const DestroyStylePreview({
    super.key,
    required this.style,
    required this.isSelected,
  });

  @override
  State<DestroyStylePreview> createState() => _DestroyStylePreviewState();
}

class _DestroyStylePreviewState extends State<DestroyStylePreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _buildPainter(primary),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  CustomPainter _buildPainter(Color primary) {
    switch (widget.style) {
      case DestroyStyle.burn:
        return _BurnPreviewPainter(_controller.value, primary);
      case DestroyStyle.sink:
        return _SinkPreviewPainter(_controller.value, primary);
      case DestroyStyle.scatter:
        return _ScatterPreviewPainter(_controller.value, primary);
      case DestroyStyle.ash:
        return _AshPreviewPainter(_controller.value, primary);
    }
  }
}

/// --- 焚：火光闪烁粒子 ---
class _BurnPreviewPainter extends CustomPainter {
  final double t;
  final Color primary;
  _BurnPreviewPainter(this.t, this.primary);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.65;

    // 底部火焰光晕
    final glowAlpha = 0.08 + 0.06 * sin(t * 2 * pi);
    final glow = Paint()
      ..color = primary.withValues(alpha: glowAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(cx, cy), 18, glow);

    // 火焰粒子（5颗）
    final rng = Random(42);
    for (var i = 0; i < 5; i++) {
      final phase = rng.nextDouble() * 2 * pi;
      final speed = 0.6 + rng.nextDouble() * 0.8;
      final xOff = sin(t * speed * 2 * pi + phase) * 8;
      final lifeT = ((t * speed + rng.nextDouble()) % 1.0);
      final y = cy - lifeT * 28;
      final alpha = (1.0 - lifeT) * 0.6;
      final r = (1.0 - lifeT) * 2.5 + 0.5;

      canvas.drawCircle(
        Offset(cx + xOff, y),
        r,
        Paint()..color = primary.withValues(alpha: alpha),
      );
    }

    // 火焰核心亮点
    final coreAlpha = 0.5 + 0.3 * sin(t * 3 * pi);
    canvas.drawCircle(
      Offset(cx, cy - 2),
      3,
      Paint()..color = primary.withValues(alpha: coreAlpha),
    );
  }

  @override
  bool shouldRepaint(covariant _BurnPreviewPainter old) =>
      old.t != t;
}

/// --- 沉：水波涟漪扩散 ---
class _SinkPreviewPainter extends CustomPainter {
  final double t;
  final Color primary;
  _SinkPreviewPainter(this.t, this.primary);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.55;

    // 3 圈涟漪，错峰扩散
    for (var i = 0; i < 3; i++) {
      final phase = i / 3.0;
      final rippleT = (t + phase) % 1.0;
      final radius = rippleT * 20;
      final alpha = (1.0 - rippleT) * 0.35;

      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..color = primary.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // 中心下沉点
    final dotAlpha = 0.6 + 0.2 * sin(t * 2 * pi);
    canvas.drawCircle(
      Offset(cx, cy),
      3,
      Paint()..color = primary.withValues(alpha: dotAlpha),
    );
  }

  @override
  bool shouldRepaint(covariant _SinkPreviewPainter old) =>
      old.t != t;
}

/// --- 散：烟雾飘散 ---
class _ScatterPreviewPainter extends CustomPainter {
  final double t;
  final Color primary;
  _ScatterPreviewPainter(this.t, this.primary);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.6;
    final rng = Random(77);

    // 6 团烟雾，缓慢上飘 + 横向漂移
    for (var i = 0; i < 6; i++) {
      final phase = rng.nextDouble() * 2 * pi;
      final speed = 0.3 + rng.nextDouble() * 0.5;
      final lifeT = ((t * speed + rng.nextDouble() * 0.3) % 1.0);

      final x = cx + sin(phase + t * 0.5) * (12 + rng.nextDouble() * 8);
      final y = cy - lifeT * 30;
      final alpha = sin(lifeT * pi) * 0.2; // 淡入淡出
      final r = 4 + lifeT * 6;

      final smoke = Paint()
        ..color = primary.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), r, smoke);
    }

    // 底部小光源
    final baseGlow = Paint()
      ..color = primary.withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(cx, cy + 4), 12, baseGlow);
  }

  @override
  bool shouldRepaint(covariant _ScatterPreviewPainter old) =>
      old.t != t;
}

/// --- 烬：星尘闪烁 ---
class _AshPreviewPainter extends CustomPainter {
  final double t;
  final Color primary;
  _AshPreviewPainter(this.t, this.primary);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(99);
    final cx = size.width / 2;
    final cy = size.height / 2;

    // 8 颗星尘，随机位置闪烁
    for (var i = 0; i < 8; i++) {
      final x = size.width * 0.2 + rng.nextDouble() * size.width * 0.6;
      final y = size.height * 0.2 + rng.nextDouble() * size.height * 0.6;
      final phase = rng.nextDouble() * 2 * pi;
      final speed = 1.5 + rng.nextDouble() * 2.0;

      // 闪烁 alpha
      final flicker = (sin(t * speed * pi + phase) + 1) / 2; // 0~1
      final alpha = flicker * 0.5 + 0.05;
      final r = flicker * 1.8 + 0.5;

      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = primary.withValues(alpha: alpha),
      );

      // 十字星芒（仅最亮的几颗）
      if (flicker > 0.7) {
        final lineAlpha = (flicker - 0.7) * 1.5;
        final lineLen = 4 * flicker;
        final linePaint = Paint()
          ..color = primary.withValues(alpha: lineAlpha * 0.4)
          ..strokeWidth = 0.5;
        canvas.drawLine(
          Offset(x - lineLen, y),
          Offset(x + lineLen, y),
          linePaint,
        );
        canvas.drawLine(
          Offset(x, y - lineLen),
          Offset(x, y + lineLen),
          linePaint,
        );
      }
    }

    // 中心微光
    final centerGlow = Paint()
      ..color = primary.withValues(alpha: 0.04 + 0.02 * sin(t * pi))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(cx, cy), 16, centerGlow);
  }

  @override
  bool shouldRepaint(covariant _AshPreviewPainter old) =>
      old.t != t;
}
