import 'package:flutter/material.dart';
import 'package:ember/core/constants/targets.dart';

/// 攻击对象选择器 — BottomSheet, FlowRow Chip
class TargetPicker extends StatelessWidget {
  final Target? selected;
  final ValueChanged<Target> onSelected;

  const TargetPicker({
    super.key,
    this.selected,
    required this.onSelected,
  });

  /// 弹出选择器
  static Future<Target?> show(
    BuildContext context, {
    Target? current,
  }) async {
    return showModalBottomSheet<Target>(
      context: context,
      builder: (_) => TargetPicker(
        selected: current,
        onSelected: (t) => Navigator.of(context).pop(t),
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
              '朝谁发火？',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: Target.values.map((target) {
                final isSelected = target == selected;
                return ChoiceChip(
                  label: Text(target.label),
                  selected: isSelected,
                  onSelected: (_) => onSelected(target),
                  selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                  side: BorderSide(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.3),
                    width: isSelected ? 1.5 : 0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
