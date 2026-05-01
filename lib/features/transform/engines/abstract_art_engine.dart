import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ember/core/constants/emotions.dart';
import 'transform_engine.dart';

/// 抽象画引擎
/// emotion → 色相, intensity → 饱和度/元素数, 生成 CustomPainter 所需参数
class AbstractArtEngine extends TransformEngine {
  @override
  TransformType get type => TransformType.art;

  Map<String, dynamic>? _data;

  Future<void> _loadData() async {
    if (_data != null) return;
    final jsonStr = await rootBundle.loadString(
      'assets/templates/art_mapping.json',
    );
    _data = json.decode(jsonStr) as Map<String, dynamic>;
  }

  @override
  Future<TransformResult> transform(
    String text,
    Emotion emotion,
    int intensity,
  ) async {
    await _loadData();

    final emotionColors =
        _data!['emotionColors'] as Map<String, dynamic>;
    final intensityScale =
        _data!['intensityScale'] as Map<String, dynamic>;
    final styles = _data!['styles'] as Map<String, dynamic>;

    final colorConfig =
        (emotionColors[emotion.name] ?? emotionColors['custom']!)
            as Map<String, dynamic>;
    final intensityConfig =
        (intensityScale[intensity.toString()] ?? intensityScale['3']!)
            as Map<String, dynamic>;
    final styleConfig =
        (styles[emotion.name] ?? styles['custom']!);

    final hue = colorConfig['hue'] as int;
    final satBase = (colorConfig['saturationBase'] as num).toDouble();
    final lightBase = (colorConfig['lightnessBase'] as num).toDouble();
    final strokeWidth = (intensityConfig['strokeWidth'] as num).toDouble();
    final elementCount = intensityConfig['elementCount'] as int;
    final speed = (intensityConfig['speed'] as num).toDouble();
    final bgAlpha = (styleConfig['bgAlpha'] as num).toDouble();
    final shapes = (styleConfig['shapes'] as List).cast<String>();

    // 生成调色板（基于色相偏移）
    final rng = Random(text.hashCode);
    final palette = List.generate(5, (i) {
      final h = (hue + i * 30 + rng.nextInt(20) - 10) % 360;
      final s = (satBase + rng.nextDouble() * 0.2).clamp(0.0, 1.0);
      final l = (lightBase + rng.nextDouble() * 0.15).clamp(0.0, 1.0);
      return HSLColor.fromAHSL(1.0, h.toDouble(), s, l).toColor();
    });

    final dominantColor = palette.isNotEmpty ? palette.first : const Color(0xFFE8915A);

    // 生成元素种子数据（给 CustomPainter 用）
    final elements = List.generate(elementCount, (i) {
      return {
        'x': rng.nextDouble(),
        'y': rng.nextDouble(),
        'size': rng.nextDouble() * 0.3 + 0.05,
        'rotation': rng.nextDouble() * 6.28,
        'shape': shapes[rng.nextInt(shapes.length)],
        'colorIndex': rng.nextInt(palette.length),
        'alpha': rng.nextDouble() * 0.6 + 0.2,
      };
    });

    // 将参数序列化为 JSON 供 CustomPainter 使用
    final artParams = {
      'palette': palette.map((c) => c.toARGB32()).toList(),
      'elements': elements,
      'strokeWidth': strokeWidth,
      'speed': speed,
      'bgAlpha': bgAlpha,
      'dominantColorValue': dominantColor.toARGB32(),
    };

    return TransformResult(
      type: type,
      content: json.encode(artParams),
      dominantColor: dominantColor,
    );
  }
}
