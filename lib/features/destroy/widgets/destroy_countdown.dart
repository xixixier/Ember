import 'package:flutter/material.dart';

/// 3秒倒计时确认
/// 环形倒计时 + 撤销按钮
class DestroyCountdown extends StatefulWidget {
  final int seconds;
  final String message;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const DestroyCountdown({
    super.key,
    this.seconds = 3,
    this.message = '即将销毁...',
    required this.onConfirm,
    this.onCancel,
  });

  /// 弹出倒计时确认
  static Future<void> show(
    BuildContext context, {
    int seconds = 3,
    String message = '即将销毁...',
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => DestroyCountdown(
        seconds: seconds,
        message: message,
        onConfirm: onConfirm,
        onCancel: onCancel ??
            () {
              Navigator.of(context).pop();
            },
      ),
    );
  }

  @override
  State<DestroyCountdown> createState() => _DestroyCountdownState();
}

class _DestroyCountdownState extends State<DestroyCountdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.seconds),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_cancelled) {
        widget.onConfirm();
        if (mounted) Navigator.of(context).pop();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _cancel() {
    _cancelled = true;
    _controller.stop();
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 环形倒计时
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: 1.0 - _controller.value,
                          strokeWidth: 4,
                          backgroundColor:
                              colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                        Text(
                          '${(widget.seconds - (_controller.value * widget.seconds)).ceil()}',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              Text(
                widget.message,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 12),

              // 撤销按钮
              TextButton(
                onPressed: () {
                  _cancel();
                  Navigator.of(context).pop();
                },
                child: Text(
                  '撤销',
                  style: TextStyle(
                    color: colorScheme.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
