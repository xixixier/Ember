import 'package:flutter/material.dart';

import 'package:ember/core/theme/ember_theme_extension.dart';
import 'package:ember/features/transform/engines/transform_engine.dart';

/// 转化类型选择面板
/// BottomSheet 展示4种转化方式，用户选择后返回 TransformType
/// 设计稿：大标题"已接住。"+ 垂直列表卡片
class TransformSelector extends StatelessWidget {
  const TransformSelector({super.key});

  /// 弹出选择面板
  static Future<TransformType?> show(BuildContext context) {
    return showModalBottomSheet<TransformType>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const TransformSelector(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 拖拽条
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // 设计稿标题：大号"已接住。"
            Text(
              '已接住。',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '选一种方式，让它变个样子',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // 垂直列表卡片（设计稿样式）
            ...TransformType.values.map((type) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TransformCard(
                type: type,
                onTap: () => Navigator.of(context).pop(type),
              ),
            )),

            // 跳过选项
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: Text(
                  '不了，直接销毁',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
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
        return '用莎翁剧场的方式把情绪演绎出来';
      case TransformType.haiku:
        return '凝练成三行俳句，简洁而诗意';
      case TransformType.darkSoup:
        return '反向治愈，换个角度看世界';
      case TransformType.art:
        return '转化为一幅抽象画的视觉描述';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = _cardColor(context);
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: cardColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            // Emoji 大图标
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  type.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // 文字信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.label,
                    style: TextStyle(
                      color: cardColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _description(),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: cardColor.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
