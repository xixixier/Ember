import 'package:flutter/material.dart';
import 'package:ember/core/theme/ember_theme_extension.dart';
import 'package:ember/core/theme/typography.dart';

/// 情绪容器式输入区
///
/// 特性 (DESIGN.md §7.1)：
/// - 深色半透明容器背景
/// - 聚焦时：余烬橙细线边框 (0.8px) + 外侧柔光光晕
/// - 聚焦时：容器微放大 (scale 1.008)
/// - 余烬橙光标
/// - AnimatedContainer 所有过渡 (250ms easeOutCubic)
class TextInputArea extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;

  const TextInputArea({
    super.key,
    required this.controller,
    this.focusNode,
  });

  @override
  State<TextInputArea> createState() => _TextInputAreaState();
}

class _TextInputAreaState extends State<TextInputArea> {
  late FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    // 只在内部创建的 focusNode 才 dispose
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<EmberThemeExtension>();
    final primaryColor = colorScheme.primary;
    final borderColor = colorScheme.outline;
    final surfaceVariant = colorScheme.surfaceContainerHighest;

    // 边框颜色
    final activeBorderColor = primaryColor.withValues(alpha: 0.50);
    final idleBorderColor = borderColor.withValues(alpha: 0.35);

    // 光晕颜色
    final glowColor = primaryColor.withValues(alpha: _focused ? 0.08 : 0.0);

    // textWeak 用于 hint
    final hintColor = ext?.textWeak ?? colorScheme.onSurfaceVariant;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: AnimatedScale(
          scale: _focused ? 1.008 : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: surfaceVariant.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _focused ? activeBorderColor : idleBorderColor,
                width: 0.8,
              ),
              boxShadow: [
                // 主光晕
                BoxShadow(
                  color: glowColor,
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                // 轻微环境阴影
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15.2),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  expands: true,
                  cursorColor: primaryColor,
                  cursorWidth: 1.5,
                  style: AppTypography.inputText.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.55,
                  ),
                  decoration: InputDecoration(
                    hintText: '说吧...',
                    hintStyle: AppTypography.inputHint.copyWith(
                      color: hintColor.withValues(alpha: 0.45),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
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
