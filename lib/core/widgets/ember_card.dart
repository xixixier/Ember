import 'dart:ui';
import 'package:flutter/material.dart';

/// Ember 统一卡片组件
///
/// 两种模式：
/// - glass=false (默认): surfaceVariant 填充 + 细线边框 + 轻微下方阴影 + 顶部微高光
/// - glass=true: BackdropFilter 毛玻璃 + 半透明背景 + 边框 + 光晕阴影
///
/// 用法:
/// ```dart
/// EmberCard(child: content)
/// EmberCard(glass: true, child: content)
/// EmberCard.glass(child: content)         // 语法糖
/// ```
class EmberCard extends StatelessWidget {
  final Widget child;
  final bool glass;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const EmberCard({
    super.key,
    required this.child,
    this.glass = false,
    this.borderRadius = 14,
    this.padding,
    this.backgroundColor,
    this.onTap,
  });

  const EmberCard.glass({
    super.key,
    required this.child,
    this.borderRadius = 14,
    this.padding,
    this.backgroundColor,
    this.onTap,
  }) : glass = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(borderRadius);

    final bgColor = backgroundColor ??
        (glass
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.48)
            : colorScheme.surfaceContainerHighest);

    final borderColor = colorScheme.outline.withValues(alpha: glass ? 0.30 : 0.45);

    final shadows = glass
        ? [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.06),
              blurRadius: 18,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ];

    Widget card = Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
        border: Border.all(color: borderColor, width: 0.5),
        boxShadow: shadows,
        gradient: _topHighlightGradient(colorScheme),
      ),
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : child,
    );

    if (glass) {
      card = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: card,
        ),
      );
    }

    if (onTap != null) {
      card = GestureDetector(onTap: onTap, child: card);
    }

    return card;
  }

  /// 顶部 + 左侧微弱线性高光，模拟光线来自左上角
  LinearGradient _topHighlightGradient(ColorScheme colorScheme) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.0, 0.06, 1.0],
      colors: [
        Colors.white.withValues(alpha: glass ? 0.07 : 0.05),
        Colors.white.withValues(alpha: glass ? 0.03 : 0.02),
        Colors.transparent,
      ],
    );
  }
}
