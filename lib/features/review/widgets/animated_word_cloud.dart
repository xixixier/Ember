import 'package:flutter/material.dart';
import 'package:ember/features/review/providers/wordcloud_provider.dart';
import 'package:ember/features/review/widgets/word_cloud_painter.dart';

/// 动画版词云 — 词语烟雾浮现 + 高频词微光
class AnimatedWordCloud extends StatefulWidget {
  final List<WordCloudItem> items;
  final double height;

  const AnimatedWordCloud({
    super.key,
    required this.items,
    this.height = 220,
  });

  @override
  State<AnimatedWordCloud> createState() => _AnimatedWordCloudState();
}

class _AnimatedWordCloudState extends State<AnimatedWordCloud>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: WordCloudPainter(
            items: widget.items,
            revealProgress: _controller.value,
            glowPulse: _controller.value,
          ),
        );
      },
    );
  }
}
