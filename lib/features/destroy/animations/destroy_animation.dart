import 'package:flutter/material.dart';

import 'package:ember/core/constants/destroy_styles.dart';

/// 销毁动画抽象 Widget
/// 所有销毁动画继承此类，动画完成后调用 onComplete
abstract class DestroyAnimationWidget extends StatefulWidget {
  final DestroyStyle style;
  final int intensity;
  final VoidCallback onComplete;
  final String? textHint;

  const DestroyAnimationWidget({
    super.key,
    required this.style,
    this.intensity = 3,
    required this.onComplete,
    this.textHint,
  });
}
