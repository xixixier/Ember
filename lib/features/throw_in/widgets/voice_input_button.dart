import 'dart:async';

import 'package:flutter/material.dart';

import 'package:ember/data/services/speech_service.dart';

/// 语音输入按钮 — 长按录音 + 波形动画
class VoiceInputButton extends StatefulWidget {
  final ValueChanged<String>? onResult;

  const VoiceInputButton({super.key, this.onResult});

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  String _partialText = '';
  StreamSubscription? _resultSub;
  StreamSubscription? _stateSub;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _resultSub = SpeechService.instance.onResult.listen((text) {
      if (mounted) {
        setState(() => _partialText = text);
      }
    });

    _stateSub = SpeechService.instance.onStateChanged.listen((state) {
      if (state == SpeechState.stopped && _isRecording) {
        if (_partialText.isNotEmpty) {
          widget.onResult?.call(_partialText);
        }
        if (mounted) {
          setState(() {
            _isRecording = false;
            _partialText = '';
          });
          _waveController.stop();
        }
      } else if (state == SpeechState.error) {
        if (mounted) {
          setState(() {
            _isRecording = false;
            _partialText = '';
          });
          _waveController.stop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('语音识别不可用，请检查权限或设备支持'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _resultSub?.cancel();
    _stateSub?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final available = await SpeechService.instance.initialize();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('语音识别不可用，请检查权限或设备支持'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {
      _isRecording = true;
      _partialText = '';
    });
    _waveController.repeat();
    await SpeechService.instance.startListening();
  }

  Future<void> _stopRecording() async {
    await SpeechService.instance.stopListening();
    _waveController.stop();
    // 结果通过 _stateSub 回调处理
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 录音中显示识别文字
        if (_isRecording && _partialText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _partialText,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

        // 波形 + 按钮
        GestureDetector(
          onLongPressStart: (_) => _startRecording(),
          onLongPressEnd: (_) => _stopRecording(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isRecording
                  ? colorScheme.primary.withValues(alpha: 0.2)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: _isRecording
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _WaveformPainter(
                            progress: _waveController.value,
                            color: colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.mic_none,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
          ),
        ),
      ],
    );
  }
}

/// 录音波形动画
class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;

  _WaveformPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 3层波形
    for (var layer = 0; layer < 3; layer++) {
      final waveProgress = (progress + layer * 0.15) % 1.0;
      final radius = size.width * 0.25 + waveProgress * size.width * 0.25;
      final alpha = 1.0 - waveProgress;

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: alpha * 0.5)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }

    // 中心圆点
    canvas.drawCircle(
      center,
      3,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
