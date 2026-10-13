import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';

import 'package:ember/core/constants/emotions.dart';
import 'package:ember/core/constants/targets.dart';
import 'package:ember/core/providers/database_provider.dart';
import 'package:ember/data/database/app_database.dart';
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
import 'package:ember/features/destroy/screens/destroy_countdown_screen.dart';
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
  String _lastSubmittedText = ''; // 保存提交的文字，用于销毁动画

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ember',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '说吧，没人看见',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        toolbarHeight: 56,
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

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 2),
              child: Wrap(
                spacing: 0,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _QuietChoice(
                    label: state.emotion.label,
                    active: state.emotion != Emotion.anger,
                    onTap: () async {
                      final result = await EmotionPicker.show(
                        context,
                        current: state.emotion,
                      );
                      if (result != null) controller.setEmotion(result);
                    },
                  ),
                  const _QuietDot(),
                  _QuietChoice(
                    label: state.target == Target.none ? '对象' : state.target.label,
                    active: state.target != Target.none,
                    onTap: () async {
                      final result = await TargetPicker.show(
                        context,
                        current: state.target,
                      );
                      if (result != null) controller.setTarget(result);
                    },
                  ),
                  const _QuietDot(),
                  _QuietChoice(
                    label: '烈度 ${state.intensity}',
                    active: state.intensity != 3,
                    onTap: () async {
                      final result = await IntensitySlider.show(
                        context,
                        current: state.intensity,
                      );
                      if (result != null) controller.setIntensity(result);
                    },
                  ),
                  const _QuietDot(),
                  _QuietChoice(
                    label: '${state.destroyTime.label} · ${state.destroyStyle.label}',
                    active: state.destroyTime != DestroyTime.hours24,
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

    _lastSubmittedText = text;
    _textController.clear();
    _focusNode.unfocus();

    // 弹出转化选择
    if (!mounted) return;
    final transformType = await TransformSelector.show(this.context);
    if (!mounted) return;

    if (transformType == null) {
      // 跳过转化，直接显示销毁反馈/动画
      if (state.destroyTime == DestroyTime.now) {
        await _showDestroyAnimation();
      } else {
        _showDestroyFeedback(messenger, state);
      }
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
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: TransformResultCard(
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
            _showDestroyAnimation();
          },
          onSkip: () {
            Navigator.of(ctx).pop();
            _showDestroyAnimation();
          },
        ),
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
  Future<void> _showDestroyAnimation() async {
    if (!mounted) return;
    final state = ref.read(throwInControllerProvider);

    if (state.destroyTime == DestroyTime.now) {
      // 立刻销毁：显示全屏倒计时页面（3秒）
      final result = await DestroyCountdownScreen.show(
        context,
        remainingSeconds: 3,
        content: _lastSubmittedText,
        emotion: state.emotion,
        intensity: state.intensity,
        destroyStyle: state.destroyStyle,
      );

      // 根据返回值决定是否执行销毁
      if (result == true) {
        // 用户确认销毁
        await ref.read(throwInControllerProvider.notifier).destroyPendingEntry();
      }
      // 如果 result == false（用户取消），则不销毁，条目保留
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
}

/// 投放页的次要选择：一行细字，点开才展开。
class _QuietChoice extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _QuietChoice({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            color: active ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            fontSize: 13,
            height: 1.2,
            letterSpacing: 0.4,
            fontWeight: active ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _QuietDot extends StatelessWidget {
  const _QuietDot();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '·',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontSize: 13,
        ),
      ),
    );
  }
}
