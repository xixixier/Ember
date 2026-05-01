import 'package:flutter/material.dart';

import 'package:ember/core/theme/ember_theme_extension.dart';
import 'package:ember/features/transform/engines/transform_engine.dart';

/// 转化类型选择面板
/// BottomSheet 展示4种转化方式，用户选择后返回 TransformType
class TransformSelector extends StatelessWidget {
  const TransformSelector({super.key});

  /// 弹出选择面板
  static Future<TransformType?> show(BuildContext context) {
    return showModalBottomSheet<TransformType>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const TransformSelector(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽条
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text(
            '选择转化方式',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '你的文字将被重新诠释',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          // 4种转化卡片
          Row(
            children: TransformType.values.map((type) {
              return Expanded(
                child: _TransformCard(
                  type: type,
                  onTap: () => Navigator.of(context).pop(type),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TransformCard extends StatelessWidget {
  final TransformType type;
  final VoidCallback onTap;

  const _TransformCard({required this.type, required this.onTap});

  Color _cardColor(BuildContext context) {
    final ext = Theme.of(context).extension<EmberThemeExtension>()!;
    return switch (type) {
      TransformType.shakespeare => ext.shakespeareAccent,
      TransformType.haiku => ext.haikuAccent,
      TransformType.darkSoup => ext.darkSoupAccent,
      TransformType.art => ext.artAccent,
    };
  }

  String _description() {
    switch (type) {
      case TransformType.shakespeare:
        return '戏剧独白';
      case TransformType.haiku:
        return '诗意凝练';
      case TransformType.darkSoup:
        return '反向治愈';
      case TransformType.art:
        return '视觉表达';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = _cardColor(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: cardColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              type.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 8),
            Text(
              type.label,
              style: TextStyle(
                color: cardColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _description(),
              style: TextStyle(
                color: cardColor.withValues(alpha: 0.7),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
