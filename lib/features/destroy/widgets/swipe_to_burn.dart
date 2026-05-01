import 'package:flutter/material.dart';

/// 滑动即焚
/// Dismissible 组件，右滑触发销毁
class SwipeToBurn extends StatelessWidget {
  final Widget child;
  final VoidCallback onBurn;
  final String? confirmText;

  const SwipeToBurn({
    super.key,
    required this.child,
    required this.onBurn,
    this.confirmText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        if (confirmText != null) {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: colorScheme.surfaceContainerHigh,
              title: Text(confirmText!, style: const TextStyle(fontSize: 16)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                  ),
                  child: const Text('确认销毁'),
                ),
              ],
            ),
          );
        }
        return true;
      },
      onDismissed: (_) => onBurn(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colorScheme.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.local_fire_department,
          color: colorScheme.error,
          size: 28,
        ),
      ),
      child: child,
    );
  }
}
