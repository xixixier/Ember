import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart' as stt;

/// 语音识别服务
/// 封装 SpeechToText，提供流式识别 + 状态通知
class SpeechService {
  static SpeechService? _instance;
  static SpeechService get instance => _instance ??= SpeechService._();

  SpeechService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _isListening = false;

  /// 识别中的文本流
  final _resultController = StreamController<String>.broadcast();
  Stream<String> get onResult => _resultController.stream;

  /// 状态变化
  final _stateController = StreamController<SpeechState>.broadcast();
  Stream<SpeechState> get onStateChanged => _stateController.stream;

  bool get isListening => _isListening;
  bool get isAvailable => _initialized;

  /// 初始化语音识别
  Future<bool> initialize() async {
    if (_initialized) return true;

    _initialized = await _speech.initialize(
      onError: (error) {
        _isListening = false;
        _stateController.add(SpeechState.error);
      },
      onStatus: (status) {
        if (status == 'notListening') {
          _isListening = false;
          _stateController.add(SpeechState.stopped);
        }
      },
    );

    return _initialized;
  }

  /// 开始录音识别
  Future<void> startListening({String localeId = 'zh_CN'}) async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) {
        _stateController.add(SpeechState.error);
        return;
      }
    }

    if (_isListening) return;

    _isListening = true;
    _stateController.add(SpeechState.listening);

    await _speech.listen(
      onResult: (result) {
        _resultController.add(result.recognizedWords);
        if (result.finalResult) {
          _isListening = false;
          _stateController.add(SpeechState.stopped);
        }
      },
      localeId: localeId,
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 30),
    );
  }

  /// 停止录音
  Future<void> stopListening() async {
    if (!_isListening) return;
    await _speech.stop();
    _isListening = false;
    _stateController.add(SpeechState.stopped);
  }

  /// 取消录音
  Future<void> cancelListening() async {
    if (!_isListening) return;
    await _speech.cancel();
    _isListening = false;
    _stateController.add(SpeechState.stopped);
  }

  void dispose() {
    _resultController.close();
    _stateController.close();
  }
}

enum SpeechState {
  listening,
  stopped,
  error,
}
