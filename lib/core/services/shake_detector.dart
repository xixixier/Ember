import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// 摇一摇检测器
/// 监听加速度计，检测手机摇动事件
class ShakeDetector {
  ShakeDetector._();

  static StreamSubscription<AccelerometerEvent>? _subscription;
  static bool _isMonitoring = false;

  /// 摇动阈值（m/s²）— 超过此值视为一次摇动
  static const double _shakeThreshold = 15.0;

  /// 两次摇动之间的最小间隔（毫秒）— 防抖
  static const int _shakeIntervalMs = 1000;

  static int _lastShakeTime = 0;

  /// 开始监听摇动
  /// [onShake] 摇动回调
  static void start(VoidCallback onShake) {
    if (_isMonitoring) return;
    _isMonitoring = true;

    _subscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((event) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastShakeTime < _shakeIntervalMs) return;

      // 计算合加速度（减去重力 ≈ 9.8）
      final acceleration = _calculateAcceleration(event);
      if (acceleration > _shakeThreshold) {
        _lastShakeTime = now;
        onShake();
      }
    });
  }

  /// 停止监听
  static void stop() {
    _subscription?.cancel();
    _subscription = null;
    _isMonitoring = false;
  }

  /// 是否正在监听
  static bool get isMonitoring => _isMonitoring;

  /// 计算加速度合值（减去重力偏移）
  static double _calculateAcceleration(AccelerometerEvent event) {
    // 减去地球重力 (≈9.8) 后的平方和开根号
    final x = event.x;
    final y = event.y;
    final z = event.z - 9.8;
    return sqrt(x * x + y * y + z * z);
  }

  static double sqrt(num x) => x < 0 ? 0 : _nativeSqrt(x);

  /// 牛顿迭代法求平方根
  static double _nativeSqrt(num x) {
    double guess = x.toDouble() / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x.toDouble() / guess) / 2;
    }
    return guess;
  }
}
