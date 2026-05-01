import 'package:flutter/material.dart';

/// 隐私政策页面
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('隐私政策')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('余烬（Ember）隐私政策',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 8),
          Text('最后更新：2026年4月',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 24),
          _Section(title: '1. 我们的承诺', content: '''
余烬是一款本地优先的情绪释放工具。你的情绪数据默认存储在设备本地，我们不会收集、上传或分享你的任何个人数据。

我们坚信：你的情绪只属于你自己。'''),
          _Section(title: '2. 数据存储', content: '''
• 所有情绪条目、收藏内容和统计数据均存储在设备本地 SQLite 数据库中
• 密码使用 Android Keystore 加密存储
• 生物识别数据由系统安全芯片管理，应用无法读取
• 不存在任何云端服务器或第三方数据存储'''),
          _Section(title: '3. 数据销毁', content: '''
• 情绪原文按照你选择的时间自动销毁
• 销毁后仅保留脱敏统计信息（情绪标签、烈度、时间）
• 语音文件随原文一同删除，不可恢复
• 收藏内容仅保存转化后的艺术作品，不保存原文'''),
          _Section(title: '4. 权限说明', content: '''
• 麦克风：仅用于语音输入功能，录音数据不会被保存或上传
• 生物识别：仅用于应用锁功能，指纹/面部数据由系统管理
• 通知：仅用于定时提醒功能
• 传感器：仅用于摇一摇紧急伪装功能'''),
          _Section(title: '5. 数据导出', content: '''
• 导出功能仅输出脱敏统计数据（CSV 格式）
• 导出内容不包含任何情绪原文或语音
• 导出文件由你完全控制，我们无法访问'''),
          _Section(title: '6. 第三方服务', content: '''
余烬不集成任何第三方分析、广告或追踪服务。

应用使用的开源库列表可在应用内查看。'''),
          _Section(title: '7. 儿童隐私', content: '''
余烬不面向 14 岁以下儿童。我们不会故意收集儿童的个人信息。'''),
          _Section(title: '8. 政策变更', content: ''
          '如果本政策发生变更，我们会在应用内通知你。继续使用应用即表示你同意修订后的政策。'),
          const SizedBox(height: 32),
          Text('如有疑问，请联系：novcloud@ember.app',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;

  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 8),
          Text(content.trim(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.7,
              )),
        ],
      ),
    );
  }
}
