import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ember/features/review/providers/wordcloud_provider.dart';

/// 情绪词云 CustomPainter
/// 螺旋布局：词频→字号，emotion→颜色
///
/// 可选动画参数：
/// - [revealProgress]: 0~1，词语烟雾浮现进度
/// - [glowPulse]: 0~1，高频词微光脉动
class WordCloudPainter extends CustomPainter {
  final List<WordCloudItem> items;
  final String? hoveredWord;
  final double revealProgress;
  final double glowPulse;

  WordCloudPainter({
    required this.items,
    this.hoveredWord,
    this.revealProgress = 1.0,
    this.glowPulse = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxCount = items.first.count;
    final minCount = items.last.count;
    final countRange = maxCount - minCount > 0 ? maxCount - minCount : 1;
    final totalItems = items.length;

    // 已放置的矩形区域（用于碰撞检测）
    final placedRects = <Rect>[];

    // 螺旋放置
    for (var i = 0; i < totalItems; i++) {
      final item = items[i];

      // 错峰浮现延迟
      final stagger = i / totalItems * 0.5;
      final itemReveal = ((revealProgress - stagger) / (1.0 - stagger)).clamp(0.0, 1.0);
      if (itemReveal < 0.01) continue;

      // 烟雾浮现 easeOut
      final revealEase = _easeOutCubic(itemReveal);

      // 字号映射：最大→28，最小→11
      final ratio = (item.count - minCount) / countRange;
      final fontSize = 11.0 + ratio * 17.0;

      final isHovered = item.word == hoveredWord;
      var alpha = isHovered ? 1.0 : (0.7 + ratio * 0.3) * revealEase;

      // 高频词微光（ratio > 0.7）
      if (ratio > 0.7 && glowPulse > 0) {
        final pulse = sin(glowPulse * 2 * pi) * 0.08;
        alpha = (alpha + pulse).clamp(0.0, 1.0);
      }

      final style = TextStyle(
        color: item.emotion.color.withValues(alpha: alpha),
        fontSize: fontSize,
        fontWeight: ratio > 0.5 ? FontWeight.w700 : FontWeight.w500,
      );

      final textPainter = TextPainter(
        text: TextSpan(text: item.word, style: style),
        textDirection: TextDirection.ltr,
      )..layout();

      // 阿基米德螺旋线寻找位置
      for (var t = 0.0; t < 50; t += 0.15) {
        final x = center.dx + t * 6 * cos(t);
        final y = center.dy + t * 4 * sin(t);

        final rect = Rect.fromCenter(
          center: Offset(x, y),
          width: textPainter.width + 4,
          height: textPainter.height + 2,
        );

        // 边界检查
        if (rect.left < 0 ||
            rect.right > size.width ||
            rect.top < 0 ||
            rect.bottom > size.height) {
          continue;
        }

        // 碰撞检测
        if (!_collides(rect, placedRects)) {
          placedRects.add(rect);

          // 高频词微光光晕
          if (ratio > 0.7 && glowPulse > 0) {
            final glowAlpha = sin(glowPulse * 2 * pi) * 0.05 + 0.02;
            canvas.save();
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect, Radius.circular(4)),
              Paint()
                ..color = item.emotion.color.withValues(alpha: glowAlpha)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
            );
            canvas.restore();
          }

          canvas.save();
          canvas.translate(
            x - textPainter.width / 2,
            y - textPainter.height / 2,
          );
          textPainter.paint(canvas, Offset.zero);
          canvas.restore();
          break;
        }
      }
    }
  }

  bool _collides(Rect rect, List<Rect> placed) {
    for (final other in placed) {
      if (rect.overlaps(other)) return true;
    }
    return false;
  }

  double _easeOutCubic(double t) => 1 - pow(1 - t, 3).toDouble();

  @override
  bool shouldRepaint(covariant WordCloudPainter oldDelegate) {
    return oldDelegate.items != items ||
        oldDelegate.hoveredWord != hoveredWord ||
        oldDelegate.revealProgress != revealProgress ||
        oldDelegate.glowPulse != glowPulse;
  }
}
