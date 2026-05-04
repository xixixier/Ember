import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:ember/features/transform/engines/transform_engine.dart';
import 'package:ember/features/transform/engines/abstract_art_painter.dart';
import 'package:ember/features/transform/widgets/ash_text_reveal.dart';

/// 转化结果卡片
/// 展示转化结果 + 收藏按钮
class TransformResultCard extends StatefulWidget {
  final TransformResult result;
  final VoidCallback onCollect;
  final VoidCallback? onSkip;

  const TransformResultCard({
    super.key,
    required this.result,
    required this.onCollect,
    this.onSkip,
  });

  @override
  State<TransformResultCard> createState() => _TransformResultCardState();
}

class _TransformResultCardState extends State<TransformResultCard> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final result = widget.result;

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽条
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 类型标签
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Text(
                  '${result.type.emoji} ${result.type.label}',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '转化完成',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 内容区域
          if (result.type == TransformType.art)
            _buildArtContent(context)
          else
            _buildTextContent(context),

          const SizedBox(height: 16),

          // 操作按钮
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onSkip ?? () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                      side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('跳过'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: widget.onCollect,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('收藏这份转化'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 文字类结果展示 — 带灰烬聚合动画
  Widget _buildTextContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          child: AshTextReveal(
            text: widget.result.content,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              height: 1.8,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  /// 抽象画结果展示
  Widget _buildArtContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    try {
      final data = json.decode(widget.result.content) as Map<String, dynamic>;
      final paletteRaw = (data['palette'] as List).cast<int>();
      final elementsRaw =
          (data['elements'] as List).cast<Map<String, dynamic>>();
      final strokeWidth = (data['strokeWidth'] as num).toDouble();
      final bgAlpha = (data['bgAlpha'] as num).toDouble();

      final painter = AbstractArtPainter(
        palette: paletteRaw.map((v) => Color(v)).toList(),
        elements: elementsRaw,
        strokeWidth: strokeWidth,
        bgAlpha: bgAlpha,
      );

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: double.infinity,
            height: 200,
            child: CustomPaint(painter: painter),
          ),
        ),
      );
    } catch (_) {
      // 解析失败时显示文字回退
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '${widget.result.type.emoji} 抽象画生成中...',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }
  }
}
