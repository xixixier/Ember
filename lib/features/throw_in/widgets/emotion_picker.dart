import 'package:flutter/material.dart';
import 'package:ember/core/constants/emotions.dart';

/// 情绪选择器 — BottomSheet, 4×2 Grid, 6 预设 + 自定义
class EmotionPicker extends StatelessWidget {
  final Emotion? selected;
  final ValueChanged<Emotion> onSelected;

  const EmotionPicker({
    super.key,
    this.selected,
    required this.onSelected,
  });

  /// 弹出选择器
  static Future<Emotion?> show(
    BuildContext context, {
    Emotion? current,
  }) async {
    return showModalBottomSheet<Emotion>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EmotionPicker(
        selected: current,
        onSelected: (e) => Navigator.of(context).pop(e),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽条
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              '你现在感觉？',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            // 情绪网格
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: Emotion.values.map((emotion) {
                final isSelected = emotion == selected;
                return _EmotionChip(
                  emotion: emotion,
                  isSelected: isSelected,
                  onTap: () => onSelected(emotion),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmotionChip extends StatelessWidget {
  final Emotion emotion;
  final bool isSelected;
  final VoidCallback onTap;

  const _EmotionChip({
    required this.emotion,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? emotion.color.withValues(alpha: 0.25)
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: emotion.color, width: 1.5)
                : Border.all(color: colorScheme.outline.withValues(alpha: 0.3), width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emotion.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                emotion.label,
                style: TextStyle(
                  color: isSelected ? emotion.color : colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
