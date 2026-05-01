import 'package:flutter/material.dart';
import 'package:ember/core/constants/destroy_styles.dart';
import 'package:ember/features/throw_in/widgets/destroy_style_preview.dart';

/// 销毁时间选项
enum DestroyTime {
  now('立刻', 0),
  hours6('6 小时', 6 * 3600),
  hours24('24 小时', 24 * 3600),
  days3('3 天', 3 * 24 * 3600),
  days7('7 天', 7 * 24 * 3600);

  final String label;
  final int seconds; // 距今的秒数
  const DestroyTime(this.label, this.seconds);
}

/// 销毁时间+方式选择器 — BottomSheet
class DestroyTimePicker extends StatelessWidget {
  final DestroyTime? selectedTime;
  final DestroyStyle? selectedStyle;
  final ValueChanged<DestroyTime> onTimeSelected;
  final ValueChanged<DestroyStyle> onStyleSelected;

  const DestroyTimePicker({
    super.key,
    this.selectedTime,
    this.selectedStyle,
    required this.onTimeSelected,
    required this.onStyleSelected,
  });

  /// 弹出选择器
  static Future<DestroyPickerResult?> show(
    BuildContext context, {
    DestroyTime? currentTime,
    DestroyStyle? currentStyle,
  }) async {
    return showModalBottomSheet<DestroyPickerResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DestroyPickerSheet(
        currentTime: currentTime,
        currentStyle: currentStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This widget is only used via .show()
    return const SizedBox.shrink();
  }
}

class DestroyPickerResult {
  final DestroyTime time;
  final DestroyStyle style;
  const DestroyPickerResult({required this.time, required this.style});
}

class _DestroyPickerSheet extends StatefulWidget {
  final DestroyTime? currentTime;
  final DestroyStyle? currentStyle;

  const _DestroyPickerSheet({
    this.currentTime,
    this.currentStyle,
  });

  @override
  State<_DestroyPickerSheet> createState() => _DestroyPickerSheetState();
}

class _DestroyPickerSheetState extends State<_DestroyPickerSheet> {
  late DestroyTime _time;
  late DestroyStyle _style;

  @override
  void initState() {
    super.initState();
    _time = widget.currentTime ?? DestroyTime.hours24;
    _style = widget.currentStyle ?? DestroyStyle.burn;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            // 销毁时间
            Text(
              '何时销毁？',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DestroyTime.values.map((dt) {
                final isSelected = dt == _time;
                return ChoiceChip(
                  label: Text(dt.label),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _time = dt),
                  selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                  side: BorderSide(
                    color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.3),
                    width: isSelected ? 1.5 : 0.5,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // 销毁方式
            Text(
              '怎么消散？',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: DestroyStyle.values.map((ds) {
                final isSelected = ds == _style;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _style = ds),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.15)
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.3),
                          width: isSelected ? 1.5 : 0.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(ds.label, style: TextStyle(
                            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          )),
                          const SizedBox(height: 4),
                          DestroyStylePreview(style: ds, isSelected: isSelected),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // 确认
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  DestroyPickerResult(time: _time, style: _style),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('确定'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
