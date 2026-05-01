import 'package:flutter/material.dart';
import 'package:ember/core/theme/ember_theme_extension.dart';

/// 空状态占位组件 (DESIGN.md §2.6)
///
/// 中央余烬橙微弱发光点呼吸 + 克制文案
/// 用于收藏馆/回望等空列表状态
///
/// 使用方式：
/// ```dart
/// if (items.isEmpty) const EmberEmptyState(message: '还没有收藏'),
/// ```
class EmberEmptyState extends StatefulWidget {
  final String message;
  final String? subMessage;
  final IconData? icon;

  const EmberEmptyState({
    super.key,
    required this.message,
    this.subMessage,
    this.icon,
  });

  @override
  State<EmberEmptyState> createState() => _EmberEmptyStateState();
}

class _EmberEmptyStateState extends State<EmberEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _breathAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _breathAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // 图标微缩放：1.0 ~ 1.06
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<EmberThemeExtension>();
    final primary = colorScheme.primary;
    final textWeak = ext?.textWeak ?? colorScheme.onSurfaceVariant;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 呼吸光点 + 图标
          AnimatedBuilder(
            animation: _breathAnim,
            builder: (context, child) {
              final glowOpacity = 0.04 + 0.10 * _breathAnim.value;
              final scale = _scaleAnim.value;

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: 0.06),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: glowOpacity),
                        blurRadius: 32,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      widget.icon ?? Icons.local_fire_department_outlined,
                      color: primary.withValues(alpha: 0.35 + 0.20 * _breathAnim.value),
                      size: 32,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // 主文案
          Text(
            widget.message,
            style: TextStyle(
              color: textWeak.withValues(alpha: 0.75),
              fontSize: 15,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),

          // 副文案（可选）
          if (widget.subMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              widget.subMessage!,
              style: TextStyle(
                color: textWeak.withValues(alpha: 0.45),
                fontSize: 12,
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
