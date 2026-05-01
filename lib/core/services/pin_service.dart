import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 6 位数字密码锁服务
class PinService {
  PinService._();
  static final PinService instance = PinService._();

  static const _pinKey = 'app_lock_pin';
  static const _lockEnabledKey = 'app_lock_enabled';
  static const _useBiometricKey = 'app_lock_use_biometric';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ─── 密码管理 ──────────────────────────────────────────────────────────────

  /// 设置 6 位数字密码
  Future<void> setPin(String pin) async {
    if (pin.length != 6 || int.tryParse(pin) == null) {
      throw ArgumentError('密码必须为6位数字');
    }
    await _storage.write(key: _pinKey, value: pin);
  }

  /// 验证密码
  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    return stored != null && stored == pin;
  }

  /// 获取已存储的密码（用于修改密码时验证旧密码）
  Future<String?> getStoredPin() => _storage.read(key: _pinKey);

  /// 删除密码
  Future<void> removePin() => _storage.delete(key: _pinKey);

  /// 是否已设置密码
  Future<bool> hasPin() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null;
  }

  // ─── 锁开关 ────────────────────────────────────────────────────────────────

  /// 应用锁是否启用
  Future<bool> isLockEnabled() async {
    final val = await _storage.read(key: _lockEnabledKey);
    return val == 'true';
  }

  /// 设置应用锁启用/禁用
  Future<void> setLockEnabled(bool enabled) async {
    await _storage.write(key: _lockEnabledKey, value: enabled.toString());
  }

  // ─── 生物识别选项 ──────────────────────────────────────────────────────────

  /// 是否启用生物识别
  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _useBiometricKey);
    return val == 'true';
  }

  /// 设置是否启用生物识别
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _useBiometricKey, value: enabled.toString());
  }

  // ─── 工具 ──────────────────────────────────────────────────────────────────

  /// 生成随机 6 位数字密码（初始化用，实际应由用户设置）
  static String generateRandomPin() {
    final rng = Random.secure();
    return List.generate(6, (_) => rng.nextInt(10)).join();
  }
}
