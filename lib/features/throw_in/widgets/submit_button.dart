import 'package:flutter/material.dart';

/// 「扔进去」按钮 — 大圆角全宽，按下缩放 + 释放点燃光晕扩散动画
class SubmitButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool enabled;

  const SubmitButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  State<SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<SubmitButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  // 光晕扩散动效
  late AnimationController _glowController;
  late Animation<double> _glowRadius;
  late Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // 光晕半径：从 0 → 40（向外扩散）
    _glowRadius = Tween<double>(begin: 0.0, end: 40.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeOut),
    );

    // 光晕透明度：快速出现 → 缓慢消失
    _glowOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.55), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.55, end: 0.0), weight: 85),
    ]).animate(_glowController);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _onPressedChanged(bool pressed) {
    if (!mounted) return;
    setState(() => _pressed = pressed);
    if (!pressed) {
      // 手指抬起时触发光晕扩散
      _glowController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: GestureDetector(
        onTapDown: (_) => _onPressedChanged(true),
        onTapUp: (_) => _onPressedChanged(false),
        onTapCancel: () => _onPressedChanged(false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    // 点燃光晕：扩散后消散
                    if (_glowController.isAnimating || _glowController.value > 0)
                      BoxShadow(
                        color: primary.withValues(alpha: _glowOpacity.value),
                        blurRadius: _glowRadius.value,
                        spreadRadius: _glowRadius.value * 0.15,
                      ),
                    // 常驻低亮光晕
                    BoxShadow(
                      color: primary.withValues(alpha: _pressed ? 0.0 : 0.12),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: child!,
              );
            },
            child: AbsorbPointer(
              absorbing: !widget.enabled,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: widget.enabled ? widget.onPressed : null,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '扔进去',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
