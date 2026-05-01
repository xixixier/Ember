import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';

/// 定时提醒服务
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  static const _channelId = 'ember_reminder';
  static const _channelName = '情绪提醒';
  static const _channelDesc = '定时提醒你释放情绪';

  static const _reminderEnabledKey = 'reminder_enabled';
  static const _reminderHourKey = 'reminder_hour';
  static const _reminderMinuteKey = 'reminder_minute';
  static const _dndStartKey = 'dnd_start_hour';
  static const _dndEndKey = 'dnd_end_hour';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// 初始化通知插件
  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    // 点击通知后的行为 — 可以跳转到投放页
    // 这里仅做日志，实际导航由 main 层处理
    debugPrint('Reminder notification tapped: ${response.payload}');
  }

  // ─── 提醒调度 ──────────────────────────────────────────────────────────────

  /// 调度每日提醒
  Future<void> scheduleDailyReminder({int hour = 22, int minute = 0}) async {
    await init();

    // 先取消已有的
    await _plugin.cancel(0);

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
        android: androidDetails, iOS: iosDetails);

    // 使用定时通知（每天重复）
    await _plugin.zonedSchedule(
      0,
      '今天过得怎么样？',
      '把不开心的都扔进来，让它化为灰烬 🔥',
      _nextInstanceOfTime(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 每天同一时间重复
      payload: 'daily_reminder',
    );

    // 保存设置
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderHourKey, hour);
    await prefs.setInt(_reminderMinuteKey, minute);
    await prefs.setBool(_reminderEnabledKey, true);
  }

  /// 取消每日提醒
  Future<void> cancelDailyReminder() async {
    await init();
    await _plugin.cancel(0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, false);
  }

  /// 提醒是否启用
  Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reminderEnabledKey) ?? false;
  }

  /// 获取提醒时间
  Future<TimeOfDay> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_reminderHourKey) ?? 22;
    final minute = prefs.getInt(_reminderMinuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  // ─── 免打扰 ────────────────────────────────────────────────────────────────

  /// 设置免打扰时段
  Future<void> setDndPeriod(int startHour, int endHour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dndStartKey, startHour);
    await prefs.setInt(_dndEndKey, endHour);
  }

  /// 获取免打扰时段
  Future<({int start, int end})> getDndPeriod() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      start: prefs.getInt(_dndStartKey) ?? 0,
      end: prefs.getInt(_dndEndKey) ?? 6,
    );
  }

  /// 当前是否在免打扰时段
  Future<bool> isInDndPeriod() async {
    final dnd = await getDndPeriod();
    final now = TimeOfDay.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = dnd.start * 60;
    final endMinutes = dnd.end * 60;

    if (dnd.start <= dnd.end) {
      // 同一天内：如 8:00-18:00
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      // 跨天：如 22:00-6:00
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }

  /// 清除免打扰设置
  Future<void> clearDndPeriod() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dndStartKey);
    await prefs.remove(_dndEndKey);
  }

  // ─── 工具 ──────────────────────────────────────────────────────────────────

  /// 计算下一个指定时间的 TZDateTime
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
