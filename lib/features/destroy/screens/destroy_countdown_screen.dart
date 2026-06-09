import 'dart:math';
import 'package:flutter/material.dart';

import 'package:ember/core/constants/emotions.dart';
import 'package:ember/core/constants/destroy_styles.dart';
import 'package:ember/core/theme/ember_theme_extension.dart';
import '../animations/destroy_animation_factory.dart';

/// 全屏倒计时页面
/// 用于展示条目在销毁前的最后时刻
///
/// 特性：
/// - 全屏沉浸式暗色背景
/// - 大号数字倒计时（余烬风格）
/// - 火焰粒子动画效果
/// - 情绪 emoji + 标签 + 内容预览
/// - 取消和立即销毁按钮
class DestroyCountdownScreen extends StatefulWidget {
  final int remainingSeconds;
  final String content;
  final Emotion emotion;
  final int intensity;
  final DestroyStyle destroyStyle;

  const DestroyCountdownScreen({
    super.key,
    required this.remainingSeconds,
    required this.content,
    required this.emotion,
    required this.intensity,
    required this.destroyStyle,
  });

  /// 显示全屏倒计时
  static Future<bool?> show(
    BuildContext context, {
    required int remainingSeconds,
    required String content,
    required Emotion emotion,
    required int intensity,
    required DestroyStyle destroyStyle,
  }) {
    return Navigator.of(context).push<bool>(
      PageRouteBuilder(
        opaque: true,
        barrierDismissible: false,
        pageBuilder: (context, anim, _) => DestroyCountdownScreen(
          remainingSeconds: remainingSeconds,
          content: content,
          emotion: emotion,
          intensity: intensity,
          destroyStyle: destroyStyle,
        ),
        transitionsBuilder: (context, animation, secondary, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeIn,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  State<DestroyCountdownScreen> createState() => _DestroyCountdownScreenState();
}

class _DestroyCountdownScreenState extends State<DestroyCountdownScreen>
    with TickerProviderStateMixin {
  late AnimationController _countdownController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  int _remainingSeconds = 0;
  bool _isComplete = false;

  // 粒子数据
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.remainingSeconds;

    // 倒计时控制器
    _countdownController = AnimationController(
      vsync: this,
      duration: Duration(seconds: max(1, _remainingSeconds)),
    );

    _scaleAnim = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _countdownController, curve: Curves.easeIn),
    );
    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _countdownController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );

    _countdownController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isComplete) {
        setState(() => _isComplete = true);
        // 不再自动返回，等待全屏销毁动画执行完毕后自动 pop
      }
    });

    // 每秒更新倒计时
    _countdownController.addListener(() {
      final newRemaining = (widget.remainingSeconds * (1.0 - _countdownController.value)).ceil();
      if (newRemaining != _remainingSeconds && newRemaining >= 0) {
        setState(() => _remainingSeconds = newRemaining);
      }
    });

    _countdownController.forward();

    // 粒子控制器
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // 初始化粒子
    _initParticles();
  }

  void _initParticles() {
    final rng = Random();
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 1.5 + rng.nextDouble() * 3,
        speed: 0.002 + rng.nextDouble() * 0.005,
        drift: (rng.nextDouble() - 0.5) * 0.003,
        opacity: 0.2 + rng.nextDouble() * 0.5,
        phase: rng.nextDouble() * 2 * pi,
      ));
    }
  }

  @override
  void dispose() {
    _countdownController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<EmberThemeExtension>();
    final emberGold = ext?.emberGold ?? const Color(0xFFF2B56B);
    final fireOrange = ext?.fireOrange ?? const Color(0xFFFF8A4C);
    final darkRed = ext?.darkRedOrange ?? const Color(0xFFA9472B);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isComplete) {
          Navigator.of(context).pop(false);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: Stack(
          children: [
            // 背景渐变
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      emberGold.withValues(alpha: 0.04),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // 浮动粒子
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _particleController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ParticlePainter(
                      particles: _particles,
                      progress: _particleController.value,
                      emberGold: emberGold,
                      fireOrange: fireOrange,
                    ),
                  );
                },
              ),
            ),

            // 主内容和动画切换
            SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _isComplete
                    ? Center(
                        key: const ValueKey('destroy_anim'),
                        child: DestroyAnimationFactory.create(
                          style: widget.destroyStyle,
                          intensity: widget.intensity,
                          textHint: widget.content.isEmpty ? '化为余烬' : widget.content,
                          onComplete: () {
                            if (mounted) Navigator.of(context).pop(true);
                          },
                        ),
                      )
                    : _buildCountdownContent(context, emberGold, fireOrange, darkRed),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownContent(BuildContext context, Color emberGold, Color fireOrange, Color darkRed) {
    return Column(
      key: const ValueKey('countdown'),
      children: [
        // 顶部安全区域
        const SizedBox(height: 24),

        // 情绪标签
        _buildEmotionTag(emberGold),

        const SizedBox(height: 32),

        // 大号倒计时数字
        Expanded(
          child: Center(
            child: AnimatedBuilder(
              animation: _countdownController,
              builder: (context, _) {
                if (_isComplete) {
                  // 完成状态：显示销毁 emoji
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.5, end: 1.5),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(
                                scale: scale,
                                child: Opacity(
                                  opacity: _isComplete ? 1.0 : 0.0,
                                  child: Text(
                                    widget.destroyStyle.emoji,
                                    style: const TextStyle(fontSize: 80),
                                  ),
                                ),
                              );
                            },
                          );
                        }

                        return Transform.scale(
                          scale: _scaleAnim.value,
                          child: Opacity(
                            opacity: _fadeAnim.value,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 大号数字
                                ShaderMask(
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [fireOrange, darkRed],
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    _formatTime(_remainingSeconds),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 88,
                                      fontWeight: FontWeight.w200,
                                      letterSpacing: -4,
                                      height: 1.0,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // 秒数（小字）
                                Text(
                                  _remainingSeconds > 0
                                      ? '$_remainingSeconds 秒'
                                      : '完成',
                                  style: TextStyle(
                                    color: emberGold.withValues(alpha: 0.6),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // 内容预览
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: emberGold.withValues(alpha: 0.10),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.content.isEmpty
                              ? '(匿名情绪)'
                              : widget.content,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 15,
                            height: 1.6,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              '${widget.emotion.emoji} ${widget.emotion.label}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '烈度 ${"🔥" * widget.intensity}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '以${widget.destroyStyle.label}销毁',
                              style: TextStyle(
                                color: fireOrange.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 底部操作
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // 取消按钮
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.10),
                              ),
                            ),
                          ),
                          child: Text(
                            '取消',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 立即销毁按钮
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            // 立即完成：停止倒计时，触发全屏销毁动画
                            _countdownController.stop();
                            setState(() {
                              _remainingSeconds = 0;
                              _isComplete = true;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: fireOrange.withValues(alpha: 0.15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: fireOrange.withValues(alpha: 0.30),
                              ),
                            ),
                          ),
                          child: Text(
                            '立即销毁',
                            style: TextStyle(
                              color: fireOrange,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              ],
    );
  }

  /// 情绪标签
  Widget _buildEmotionTag(Color emberGold) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: widget.emotion.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.emotion.color.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.emotion.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              widget.emotion.label,
              style: TextStyle(
                color: widget.emotion.color.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化时间
  String _formatTime(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// 粒子数据
class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double drift;
  final double opacity;
  final double phase;

  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.drift,
    required this.opacity,
    required this.phase,
  });
}

/// 粒子绘制器
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color emberGold;
  final Color fireOrange;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.emberGold,
    required this.fireOrange,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final x = (p.x + sin(progress * 2 * pi + p.phase) * 0.05 + p.drift * progress * 100) % 1.0;
      final y = (p.y - p.speed * progress * 100) % 1.0;
      final actualY = y < 0 ? y + 1.0 : y;

      final px = x * size.width;
      final py = actualY * size.height;

      // 闪烁效果
      final flicker = 0.5 + 0.5 * sin(progress * 3 * pi + p.phase);
      final alpha = p.opacity * flicker;

      // 颜色插值（emberGold → fireOrange）
      final color = Color.lerp(emberGold, fireOrange, flicker)!;

      canvas.drawCircle(
        Offset(px, py),
        p.size * (0.8 + flicker * 0.4),
        Paint()..color = color.withValues(alpha: alpha * 0.6),
      );

      // 光晕
      canvas.drawCircle(
        Offset(px, py),
        p.size * 2.5,
        Paint()..color = color.withValues(alpha: alpha * 0.08),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
