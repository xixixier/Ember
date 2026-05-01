import 'package:flutter/material.dart';
import 'package:ember/core/theme/color_tokens.dart';

/// 烈度滑动条 — 5 档离散，暖黄→深红渐变
class IntensitySlider extends StatelessWidget {
  final int value; // 1-5
  final ValueChanged<int> onChanged;

  const IntensitySlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// 弹出选择器
  static Future<int?> show(
    BuildContext context, {
    int current = 3,
  }) async {
    return showModalBottomSheet<int>(
      context: context,
      builder: (_) => _IntensitySliderSheet(current: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = ColorTokens.intensityColors[value - 1];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          ColorTokens.intensityLabels[value - 1],
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _IntensitySliderSheet extends StatefulWidget {
  final int current;

  const _IntensitySliderSheet({required this.current});

  @override
  State<_IntensitySliderSheet> createState() => _IntensitySliderSheetState();
}

class _IntensitySliderSheetState extends State<_IntensitySliderSheet> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.current;
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
              '有多炸？',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            // 当前烈度显示
            Text(
              '$_value / 5  ${ColorTokens.intensityLabels[_value - 1]}',
              style: TextStyle(
                color: ColorTokens.intensityColors[_value - 1],
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            // 渐变滑块
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: ColorTokens.intensityColors[_value - 1],
                inactiveTrackColor: colorScheme.outline.withValues(alpha: 0.3),
                thumbColor: ColorTokens.intensityColors[_value - 1],
                overlayColor: ColorTokens.intensityColors[_value - 1].withValues(alpha: 0.12),
                trackHeight: 6,
                // thumb 大小随烈度值缩放：1档最小(8)，5档最大(12)
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: 8.0 + (_value - 1) * 1.0,
                ),
                // overlay (按压波纹) 随烈度增大
                overlayShape: RoundSliderOverlayShape(
                  overlayRadius: 16.0 + (_value - 1) * 2.0,
                ),
              ),
              child: Slider(
                value: _value.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: (v) => setState(() => _value = v.round()),
              ),
            ),
            // 标签行
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  5,
                  (i) => Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: i + 1 == _value
                          ? ColorTokens.intensityColors[i]
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      fontSize: 12,
                      fontWeight: i + 1 == _value ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 确认按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_value),
                style: FilledButton.styleFrom(
                  backgroundColor: ColorTokens.intensityColors[_value - 1],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
