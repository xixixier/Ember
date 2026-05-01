/// 时间戳工具
class Timestamp {
  /// 当前 Unix 秒
  static int now() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  /// 当前日期字符串 "2026-04-29"
  static String todayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 当前月份字符串 "2026-04"
  static String currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// Unix 秒转日期字符串
  static String secondsToDate(int seconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// 日期字符串转 Unix 秒（当天 00:00:00）
  static int dateToSeconds(String date) {
    final parts = date.split('-');
    final dt = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    return dt.millisecondsSinceEpoch ~/ 1000;
  }
}
