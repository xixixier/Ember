import 'package:flutter/material.dart';

import 'package:ember/core/constants/destroy_styles.dart';
import 'burn_animation.dart';
import 'sink_animation.dart';
import 'scatter_animation.dart';
import 'ash_animation.dart';

/// 销毁动画工厂
/// 根据 DestroyStyle 返回对应的动画 Widget
class DestroyAnimationFactory {
  static Widget create({
    required DestroyStyle style,
    int intensity = 3,
    required VoidCallback onComplete,
    String? textHint,
  }) {
    switch (style) {
      case DestroyStyle.burn:
        return BurnAnimation(
          intensity: intensity,
          onComplete: onComplete,
          textHint: textHint,
        );
      case DestroyStyle.sink:
        return SinkAnimation(
          intensity: intensity,
          onComplete: onComplete,
          textHint: textHint,
        );
      case DestroyStyle.scatter:
        return ScatterAnimation(
          intensity: intensity,
          onComplete: onComplete,
          textHint: textHint,
        );
      case DestroyStyle.ash:
        return AshAnimation(
          intensity: intensity,
          onComplete: onComplete,
          textHint: textHint,
        );
    }
  }
}
