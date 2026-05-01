import 'dart:io';

import 'package:workmanager/workmanager.dart';
import 'package:ember/data/database/app_database.dart';
import 'package:ember/core/utils/timestamp.dart';

/// 销毁调度服务
/// 使用 WorkManager 每 15 分钟检查并软删除到期条目
class DestroyScheduler {
  static const _taskName = 'ember_destroy_expired';

  /// 初始化 WorkManager 并注册周期任务
  static Future<void> init() async {
    await Workmanager().initialize(_callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  /// 取消调度
  static Future<void> cancel() async {
    await Workmanager().cancelByUniqueName(_taskName);
  }

  /// 立即执行一次销毁检查（可用于 app 启动时）
  static Future<void> checkNow() async {
    final db = AppDatabase();
    try {
      await _destroyExpired(db);
    } finally {
      await db.close();
    }
  }
}

/// WorkManager 回调 — 后台执行入口
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != 'ember_destroy_expired') return true;

    final db = AppDatabase();
    try {
      await _destroyExpired(db);
      return true;
    } catch (e) {
      return false;
    } finally {
      await db.close();
    }
  });
}

/// 查找并软删除所有到期条目
Future<void> _destroyExpired(AppDatabase db) async {
  final nowSeconds = Timestamp.now();
  final pending = await db.entryDao.getPendingDestroy(nowSeconds);

  for (final entry in pending) {
    // 删除语音文件
    if (entry.voicePath != null && entry.voicePath!.isNotEmpty) {
      final file = File(entry.voicePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    // 软删除
    await db.entryDao.destroyEntryWithTimestamp(entry.id, nowSeconds);
  }
}
