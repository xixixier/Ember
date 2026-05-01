import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';

import 'package:ember/core/constants/emotions.dart';
import 'package:ember/core/constants/targets.dart';
import 'package:ember/core/providers/database_provider.dart';
import 'package:ember/data/database/app_database.dart';
import 'package:ember/core/theme/color_tokens.dart';
import 'package:ember/features/throw_in/throw_in_controller.dart';
import 'package:ember/features/throw_in/widgets/guide_text.dart';
import 'package:ember/features/throw_in/widgets/text_input_area.dart';
import 'package:ember/features/throw_in/widgets/emotion_picker.dart';
import 'package:ember/features/throw_in/widgets/target_picker.dart';
import 'package:ember/features/throw_in/widgets/intensity_slider.dart';
import 'package:ember/features/throw_in/widgets/destroy_time_picker.dart';
import 'package:ember/features/throw_in/widgets/submit_button.dart';
import 'package:ember/features/transform/engines/transform_engine.dart';
import 'package:ember/features/transform/engines/transform_engine_registry.dart';
import 'package:ember/features/transform/widgets/transform_selector.dart';
import 'package:ember/features/transform/widgets/transform_result_card.dart';
import 'package:ember/features/transform/widgets/collect_snackbar.dart';
import 'package:ember/features/destroy/animations/destroy_animation_factory.dart';
import 'package:ember/core/widgets/ember_breath_background.dart';
import 'package:ember/core/widgets/ember_particle_field.dart';

class ThrowInScreen extends ConsumerStatefulWidget {
  const ThrowInScreen({super.key});

  @override
  ConsumerState<ThrowInScreen> createState() => _ThrowInScreenState();
}

class _ThrowInScreenState extends ConsumerState<ThrowInScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  String? _lastCollectedId;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(throwInControllerProvider);
    final controller = ref.read(throwInControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ember',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // 余烬呼吸光背景（最底层，不拦截点击）
            const EmberBreathBackground(),
            // 漂浮粒子（次底层，不拦截点击）
            const EmberParticleField(),
            // 主内容列
            Column(
              children: [
            // 引导语
            const GuideText(),

            // 大字输入区
            TextInputArea(
              controller: _textController,
              focusNode: _focusNode,
            ),

            // 已选标签展示行
            if (state.emotion != Emotion.anger ||
                state.target != Target.none ||
                state.intensity != 3)
              _buildSelectedTags(context, state, controller),

            // 元数据按钮行
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MetaChip(
                    icon: Icons.emoji_emotions,
                    label: '情绪',
                    value: state.emotion.emoji,
                    highlight: state.emotion != Emotion.anger,
                    onTap: () async {
                      final result = await EmotionPicker.show(
                        context,
                        current: state.emotion,
                      );
                      if (result != null) controller.setEmotion(result);
                    },
                  ),
                  _MetaChip(
                    icon: Icons.my_location,
                    label: '对象',
                    value: state.target == Target.none ? null : state.target.label,
                    highlight: state.target != Target.none,
                    onTap: () async {
                      final result = await TargetPicker.show(
                        context,
                        current: state.target,
                      );
                      if (result != null) controller.setTarget(result);
                    },
                  ),
                  _MetaChip(
                    icon: Icons.local_fire_department,
                    label: '烈度',
                    value: '${state.intensity}',
                    highlight: state.intensity != 3,
                    valueColor: ColorTokens.intensityColors[state.intensity - 1],
                    onTap: () async {
                      final result = await IntensitySlider.show(
                        context,
                        current: state.intensity,
                      );
                      if (result != null) controller.setIntensity(result);
                    },
                  ),
                  _MetaChip(
                    icon: Icons.timer,
                    label: '销毁',
                    value: state.destroyTime.label,
                    highlight: state.destroyTime != DestroyTime.hours24,
                    onTap: () async {
                      final result = await DestroyTimePicker.show(
                        context,
                        currentTime: state.destroyTime,
                        currentStyle: state.destroyStyle,
                      );
                      if (result != null) {
                        controller.setDestroyTime(result.time);
                        controller.setDestroyStyle(result.style);
                      }
                    },
                  ),
                ],
              ),
            ),

            // 扔进去按钮
            SubmitButton(
              enabled: !state.isSubmitting,
              onPressed: () => _handleSubmit(context, state, controller),
            ),
          ],
            ),  // Column
          ],
        ),  // Stack
      ),
    );
  }

  /// 提交流程：写DB → 弹转化选择 → 结果/收藏 → 销毁动画
  Future<void> _handleSubmit(
    BuildContext context,
    ThrowInState state,
    ThrowInController controller,
  ) async {
    final text = _textController.text;
    final messenger = ScaffoldMessenger.of(context);

    final success = await controller.submit(text);
    if (!mounted) return;

    if (!success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('写点什么再扔吧'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _textController.clear();
    _focusNode.unfocus();

    // 弹出转化选择
    if (!mounted) return;
    final transformType = await TransformSelector.show(this.context);
    if (!mounted) return;

    if (transformType == null) {
      // 跳过转化，直接显示销毁反馈
      _showDestroyFeedback(messenger, state);
      return;
    }

    // 执行转化
    try {
      final result = await TransformEngineRegistry.transform(
        transformType,
        text,
        state.emotion,
        state.intensity,
      );

      if (!mounted) return;

      // 展示转化结果 + 收藏选项
      _showTransformResult(this.context, result, state, messenger);
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('转化失败，请重试'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 展示转化结果 + 收藏
  void _showTransformResult(
    BuildContext context,
    TransformResult result,
    ThrowInState state,
    ScaffoldMessengerState messenger,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransformResultCard(
        result: result,
        onCollect: () async {
          Navigator.of(ctx).pop();
          await _collectResult(result, state);
          if (!mounted) return;
          CollectSnackbar.show(
            this.context,
            onUndo: () async {
              if (_lastCollectedId != null) {
                final collectionDao = ref.read(collectionDaoProvider);
                await collectionDao.deleteCollection(_lastCollectedId!);
                _lastCollectedId = null;
                if (mounted) {
                  CollectSnackbar.showUndo(this.context);
                }
              }
            },
          );
          // 收藏后播放销毁动画
          _showDestroyAnimation(state);
        },
        onSkip: () {
          Navigator.of(ctx).pop();
          _showDestroyAnimation(state);
        },
      ),
    );
  }

  /// 收藏转化结果到 DB
  Future<void> _collectResult(
    TransformResult result,
    ThrowInState state,
  ) async {
    final collectionDao = ref.read(collectionDaoProvider);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final id = const Uuid().v4();

    await collectionDao.insertCollection(CollectionsCompanion(
      id: Value(id),
      sourceEntryId: const Value.absent(),
      type: Value(result.type.name),
      content: Value(result.content),
      imagePath: const Value.absent(),
      emotionTag: Value(state.emotion.name),
      intensity: Value(state.intensity),
      createdAt: Value(now),
    ));

    _lastCollectedId = id;
  }

  /// 播放销毁动画
  void _showDestroyAnimation(ThrowInState state) {
    if (!mounted) return;

    if (state.destroyTime == DestroyTime.now) {
      // 立刻销毁：播放动画
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => DestroyAnimationFactory.create(
          style: state.destroyStyle,
          intensity: state.intensity,
          textHint: '已化为灰烬',
          onComplete: () {
            Navigator.of(ctx).pop();
          },
        ),
      );
    }
  }

  /// 显示销毁反馈（无动画路径）
  void _showDestroyFeedback(
    ScaffoldMessengerState messenger,
    ThrowInState state,
  ) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          state.destroyTime == DestroyTime.now
              ? '已销毁 ${state.destroyStyle.emoji}'
              : '已扔进去，${state.destroyTime.label}后${state.destroyStyle.label}',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 已选标签展示
  Widget _buildSelectedTags(
    BuildContext context,
    ThrowInState state,
    ThrowInController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Wrap(
        spacing: 6,
        children: [
          if (state.emotion != Emotion.anger)
            _TagChip(
              label: '${state.emotion.emoji} ${state.emotion.label}',
              color: state.emotion.color,
              onDismiss: () => controller.setEmotion(Emotion.anger),
            ),
          if (state.target != Target.none)
            _TagChip(
              label: state.target.label,
              color: colorScheme.primary,
              onDismiss: () => controller.setTarget(Target.none),
            ),
          if (state.intensity != 3)
            _TagChip(
              label: '${ColorTokens.intensityLabels[state.intensity - 1]} ${state.intensity}/5',
              color: ColorTokens.intensityColors[state.intensity - 1],
              onDismiss: () => controller.setIntensity(3),
            ),
        ],
      ),
    );
  }
}

/// 元数据按钮
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool highlight;
  final Color? valueColor;
  final VoidCallback onTap;

  const _MetaChip({
    required this.icon,
    required this.label,
    this.value,
    this.highlight = false,
    this.valueColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: highlight ? (valueColor ?? colorScheme.primary) : colorScheme.onSurfaceVariant,
            size: 22,
          ),
          const SizedBox(height: 2),
          Text(
            value ?? label,
            style: TextStyle(
              color: highlight ? (valueColor ?? colorScheme.primary) : colorScheme.onSurfaceVariant,
              fontSize: 10,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// 已选标签
class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onDismiss;

  const _TagChip({
    required this.label,
    required this.color,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 11)),
      deleteIcon: Icon(Icons.close, size: 14, color: color),
      onDeleted: onDismiss,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      backgroundColor: color.withValues(alpha: 0.1),
      deleteButtonTooltipMessage: '移除',
    );
  }
}
