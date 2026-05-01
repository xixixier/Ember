import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

/// 生物识别认证服务
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// 设备是否支持生物识别
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// 设备是否已注册生物识别
  Future<bool> canAuthenticate() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  /// 获取可用生物识别类型列表
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// 执行生物识别认证
  /// 返回 true 表示认证成功
  Future<bool> authenticate({String reason = '请验证身份以打开余烬'}) async {
    try {
      return await _localAuth.authenticate(
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: '验证身份',
            cancelButton: '使用密码',
            biometricHint: '触摸传感器',
            biometricNotRecognized: '未识别，请重试',
            biometricSuccess: '识别成功',
          ),
          IOSAuthMessages(
            cancelButton: '使用密码',
            goToSettingsButton: '设置',
            goToSettingsDescription: '请在设置中开启生物识别',
          ),
        ],
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // 允许回退到设备密码
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
