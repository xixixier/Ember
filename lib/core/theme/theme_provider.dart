import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

const _kThemeKey = 'ember_theme_name';

/// 当前主题名称 Provider（持久化）
final themeNameProvider = StateNotifierProvider<ThemeNameNotifier, String>((ref) {
  return ThemeNameNotifier();
});

/// 主题名称 Notifier — 从 SharedPreferences 初始化，切换时写入
class ThemeNameNotifier extends StateNotifier<String> {
  ThemeNameNotifier() : super('dark') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeKey);
    if (saved != null && _validNames.contains(saved)) {
      state = saved;
    }
  }

  Future<void> set(String name) async {
    if (!_validNames.contains(name)) return;
    state = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, name);
  }

  static const _validNames = {'dark', 'warmGray', 'deepBlue', 'pureBlack'};
}

/// 根据主题名称获取对应 ThemeData
ThemeData _themeForName(String name) => switch (name) {
      'dark' => AppTheme.dark,
      'warmGray' => AppTheme.warmGray,
      'deepBlue' => AppTheme.deepBlue,
      'pureBlack' => AppTheme.pureBlack,
      _ => AppTheme.dark,
    };

/// 当前 ThemeData Provider（直接暴露 ThemeData，而非 ThemeMode）
final themeDataProvider = Provider<ThemeData>((ref) {
  final name = ref.watch(themeNameProvider);
  return _themeForName(name);
});

/// 切换主题
void setThemeByName(WidgetRef ref, String name) {
  ref.read(themeNameProvider.notifier).set(name);
}
