import 'package:flutter/material.dart';
import 'package:ember/core/widgets/ember_empty_state.dart';

/// 空收藏状态 — 使用 EmberEmptyState 呼吸光效果
class EmptyCollection extends StatelessWidget {
  const EmptyCollection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: EmberEmptyState(
        message: '还没有收藏',
        subMessage: '投放情绪后选择转化\n值得留住的文字会被收藏在这里',
        icon: Icons.auto_awesome_outlined,
      ),
    );
  }
}
