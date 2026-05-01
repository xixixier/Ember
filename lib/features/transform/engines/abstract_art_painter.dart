import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

/// 抽象画 CustomPainter
/// 接收 AbstractArtEngine 生成的 JSON 参数进行绘制
class AbstractArtPainter extends CustomPainter {
  final List<Color> palette;
  final List<Map<String, dynamic>> elements;
  final double strokeWidth;
  final double bgAlpha;

  AbstractArtPainter({
    required this.palette,
    required this.elements,
    required this.strokeWidth,
    required this.bgAlpha,
  });

  /// 从 JSON 字符串构造
  factory AbstractArtPainter.fromJson(String jsonStr) {
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final paletteRaw = (data['palette'] as List).cast<int>();
    final elementsRaw = (data['elements'] as List).cast<Map<String, dynamic>>();
    return AbstractArtPainter(
      palette: paletteRaw.map((v) => Color(v)).toList(),
      elements: elementsRaw,
      strokeWidth: (data['strokeWidth'] as num).toDouble(),
      bgAlpha: (data['bgAlpha'] as num).toDouble(),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 背景
    final bgColor = palette.first.withValues(alpha: bgAlpha);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = bgColor);

    final rng = Random(42);

    for (final el in elements) {
      final x = (el['x'] as num).toDouble() * size.width;
      final y = (el['y'] as num).toDouble() * size.height;
      final s = (el['size'] as num).toDouble() * min(size.width, size.height);
      final rotation = (el['rotation'] as num).toDouble();
      final shape = el['shape'] as String;
      final colorIndex = el['colorIndex'] as int;
      final alpha = (el['alpha'] as num).toDouble();

      final color = palette[colorIndex % palette.length].withValues(alpha: alpha);
      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      switch (shape) {
        case 'jagged':
        case 'scratch':
          _drawJagged(canvas, s, paint, rng);
          break;
        case 'spiral':
        case 'tangle':
          _drawSpiral(canvas, s, paint, rng);
          break;
        case 'burst':
        case 'shatter':
          _drawBurst(canvas, s, paint, rng);
          break;
        case 'droop':
        case 'layer':
          _drawDroop(canvas, s, paint);
          break;
        case 'mist':
        case 'flow':
        case 'wave':
          _drawMist(canvas, s, paint);
          break;
        case 'grid':
          _drawGrid(canvas, s, paint, rng);
          break;
        case 'void':
        case 'crack':
          _drawCrack(canvas, s, paint, rng);
          break;
        case 'dot':
        case 'bubble':
          _drawDots(canvas, s, paint, rng);
          break;
        case 'zigzag':
          _drawZigzag(canvas, s, paint, rng);
          break;
        default:
          _drawAbstractCircle(canvas, s, paint);
      }

      canvas.restore();
    }

    // 叠加一层柔和的渐变蒙版，提升整体美感
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.black.withValues(alpha: 0.15),
        Colors.transparent,
        Colors.black.withValues(alpha: 0.25),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = gradient,
    );
  }

  void _drawJagged(Canvas canvas, double s, Paint paint, Random rng) {
    final path = Path();
    path.moveTo(-s / 2, 0);
    for (var i = 1; i <= 6; i++) {
      final dx = rng.nextDouble() * s / 3 - s / 6;
      final dy = -s / 2 + (s / 6) * i;
      path.lineTo(dx, dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawSpiral(Canvas canvas, double s, Paint paint, Random rng) {
    final center = Offset.zero;
    for (var i = 0; i < 30; i++) {
      final angle = i * 0.4;
      final r = s * 0.02 * i;
      final p = Offset(
        center.dx + r * cos(angle),
        center.dy + r * sin(angle),
      );
      if (i > 0) {
        final prev = Offset(
          center.dx + s * 0.02 * (i - 1) * cos((i - 1) * 0.4),
          center.dy + s * 0.02 * (i - 1) * sin((i - 1) * 0.4),
        );
        canvas.drawLine(prev, p, paint);
      }
    }
  }

  void _drawBurst(Canvas canvas, double s, Paint paint, Random rng) {
    for (var i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      canvas.drawLine(
        Offset.zero,
        Offset(cos(angle) * s / 2, sin(angle) * s / 2),
        paint,
      );
    }
  }

  void _drawDroop(Canvas canvas, double s, Paint paint) {
    final path = Path();
    path.moveTo(-s / 2, -s / 4);
    path.quadraticBezierTo(0, s / 4, s / 2, -s / 4);
    canvas.drawPath(path, paint);
  }

  void _drawMist(Canvas canvas, double s, Paint paint) {
    final fillPaint = Paint()
      ..color = paint.color.withValues(alpha: paint.color.a * 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: s, height: s * 0.6),
      fillPaint,
    );
  }

  void _drawGrid(Canvas canvas, double s, Paint paint, Random rng) {
    final step = s / 5;
    for (var i = 0; i <= 5; i++) {
      canvas.drawLine(
        Offset(-s / 2 + i * step, -s / 2),
        Offset(-s / 2 + i * step, s / 2),
        paint,
      );
      canvas.drawLine(
        Offset(-s / 2, -s / 2 + i * step),
        Offset(s / 2, -s / 2 + i * step),
        paint,
      );
    }
  }

  void _drawCrack(Canvas canvas, double s, Paint paint, Random rng) {
    final path = Path();
    path.moveTo(0, -s / 2);
    var cx = 0.0;
    for (var i = 1; i <= 5; i++) {
      cx += rng.nextDouble() * s / 4 - s / 8;
      path.lineTo(cx, -s / 2 + (s / 5) * i);
    }
    canvas.drawPath(path, paint);
  }

  void _drawDots(Canvas canvas, double s, Paint paint, Random rng) {
    final fillPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 6; i++) {
      final dx = rng.nextDouble() * s - s / 2;
      final dy = rng.nextDouble() * s - s / 2;
      canvas.drawCircle(Offset(dx, dy), s * 0.05, fillPaint);
    }
  }

  void _drawZigzag(Canvas canvas, double s, Paint paint, Random rng) {
    final path = Path();
    path.moveTo(-s / 2, 0);
    for (var i = 0; i < 6; i++) {
      path.lineTo(
        -s / 2 + (s / 6) * (i + 1),
        i.isEven ? -s / 6 : s / 6,
      );
    }
    canvas.drawPath(path, paint);
  }

  void _drawAbstractCircle(Canvas canvas, double s, Paint paint) {
    canvas.drawCircle(Offset.zero, s / 3, paint);
  }

  @override
  bool shouldRepaint(covariant AbstractArtPainter oldDelegate) {
    return oldDelegate.elements != elements || oldDelegate.palette != palette;
  }
}
