import 'package:flutter/material.dart';

import 'package:ember/features/transform/engines/transform_engine.dart';

/// 类型筛选栏
class TypeFilterBar extends StatelessWidget {
  final TransformType? selectedType;
  final ValueChanged<TransformType?> onSelected;

  const TypeFilterBar({
    super.key,
    this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "全部"选项
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('全部'),
              selected: selectedType == null,
              onSelected: (_) => onSelected(null),
              backgroundColor: colorScheme.surfaceContainerLow,
              selectedColor: colorScheme.primary.withValues(alpha: 0.2),
              side: BorderSide(
                color: selectedType == null
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
          ),
          // 各类型选项
          ...TransformType.values.map((type) {
            final isSelected = selectedType == type;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${type.emoji} ${type.label}'),
                selected: isSelected,
                onSelected: (_) => onSelected(isSelected ? null : type),
                backgroundColor: colorScheme.surfaceContainerLow,
                selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                side: BorderSide(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
