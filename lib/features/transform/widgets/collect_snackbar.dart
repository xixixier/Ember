import 'package:flutter/material.dart';

/// 收藏成功 SnackBar
/// 带5秒撤销功能
class CollectSnackbar {
  /// 显示收藏成功提示
  static void show(
    BuildContext context, {
    required VoidCallback onUndo,
    String message = '已收藏到转化馆',
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '撤销',
          onPressed: onUndo,
        ),
      ),
    );
  }

  /// 显示取消收藏提示
  static void showUndo(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已取消收藏'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
