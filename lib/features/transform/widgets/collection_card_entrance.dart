import 'package:flutter/material.dart';

/// 收藏馆卡片进入动画包装器
/// 淡入 + 缩放 0.95→1.0，延迟错峰
class CollectionCardEntrance extends StatefulWidget {
  final int index;
  final Widget child;

  const CollectionCardEntrance({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<CollectionCardEntrance> createState() => _CollectionCardEntranceState();
}

class _CollectionCardEntranceState extends State<CollectionCardEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // 每张卡片延迟 index * 50ms，最长延迟 400ms
    final delay = (widget.index * 50).clamp(0, 400);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // 启动时延迟后开始动画
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
