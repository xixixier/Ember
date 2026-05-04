import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/pin_service.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/services/export_service.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/ai_api_service.dart';
import 'screens/api_settings_screen.dart';

/// 设置页面（Tab4: 我的）
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _lockEnabled = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _loading = true;
  bool _apiConfigured = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final lockEnabled = await PinService.instance.isLockEnabled();
    final bioEnabled = await PinService.instance.isBiometricEnabled();
    final bioAvailable = await AuthService.instance.canAuthenticate();
    await AiApiService.instance.loadSettings();
    if (!mounted) return;
    setState(() {
      _lockEnabled = lockEnabled;
      _biometricEnabled = bioEnabled;
      _biometricAvailable = bioAvailable;
      _apiConfigured = AiApiService.instance.isConfigured;
      _loading = false;
    });
  }

  // ─── 应用锁 ──────────────────────────────────────────────────────────────

  Future<void> _toggleLock(bool value) async {
    if (value) {
      // 启用锁：先设置密码
      final pin = await _showSetPinDialog();
      if (pin == null) return; // 取消
      await PinService.instance.setPin(pin);
      await PinService.instance.setLockEnabled(true);
      setState(() => _lockEnabled = true);
    } else {
      // 禁用锁：验证当前密码
      final verified = await _showVerifyPinDialog();
      if (!verified) return;
      await PinService.instance.setLockEnabled(false);
      setState(() => _lockEnabled = false);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final canAuth = await AuthService.instance.canAuthenticate();
      if (!canAuth) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('设备不支持生物识别或未录入')),
          );
        }
        return;
      }
      final success = await AuthService.instance.authenticate(
        reason: '请验证身份以启用生物识别解锁',
      );
      if (success) {
        await PinService.instance.setBiometricEnabled(true);
        setState(() => _biometricEnabled = true);
      }
    } else {
      await PinService.instance.setBiometricEnabled(false);
      setState(() => _biometricEnabled = false);
    }
  }

  // ─── 修改密码 ────────────────────────────────────────────────────────────

  Future<void> _changePin() async {
    final verified = await _showVerifyPinDialog();
    if (!verified) return;
    final newPin = await _showSetPinDialog(isChange: true);
    if (newPin == null) return;
    await PinService.instance.setPin(newPin);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码已更新')),
      );
    }
  }

  // ─── 数据导出 ────────────────────────────────────────────────────────────

  Future<void> _exportData() async {
    try {
      final db = ref.read(databaseProvider);
      final file = await ExportService.instance.exportAllStats(db);
      if (mounted) {
        await ExportService.instance.shareFile(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：$e')),
        );
      }
    }
  }

  // ─── Dialog ──────────────────────────────────────────────────────────────

  Future<String?> _showSetPinDialog({bool isChange = false}) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(isChange ? '设置新密码' : '设置应用锁密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请输入6位数字密码', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                counterText: '',
                border: OutlineInputBorder(),
                hintText: '6位数字',
              ),
              onSubmitted: (v) {
                if (v.length == 6) Navigator.of(ctx).pop(v);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.length == 6) {
                Navigator.of(ctx).pop(controller.text);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<bool> _showVerifyPinDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('验证密码'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            counterText: '',
            border: OutlineInputBorder(),
            hintText: '输入当前密码',
          ),
          onSubmitted: (_) => _doVerify(ctx, controller),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => _doVerify(ctx, controller),
            child: const Text('验证'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result ?? false;
  }

  Future<void> _doVerify(BuildContext ctx, TextEditingController c) async {
    if (c.text.length != 6) return;
    final ok = await PinService.instance.verifyPin(c.text);
    if (ctx.mounted) Navigator.of(ctx).pop(ok);
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '我的',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ─── AI 转化 ───────────────────────────────────────────────────
          _SectionHeader(title: 'AI 转化引擎', icon: Icons.auto_awesome_outlined),
          ListTile(
            leading: const Icon(Icons.api_outlined),
            title: const Text('API 配置'),
            subtitle: Text(_apiConfigured ? '已配置，AI 转化已启用' : '未配置，使用本地模板'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_apiConfigured)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ON',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ApiSettingsScreen(),
              ),
            ).then((_) {
              // 返回后刷新配置状态
              AiApiService.instance.loadSettings().then((_) {
                if (mounted) {
                  setState(() => _apiConfigured = AiApiService.instance.isConfigured);
                }
              });
            }),
          ),

          const Divider(indent: 16, endIndent: 16, height: 24),

          // ─── 安全 ──────────────────────────────────────────────────────
          _SectionHeader(title: '安全', icon: Icons.shield_outlined),
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline),
            title: const Text('应用锁'),
            subtitle: Text(_lockEnabled ? '已启用' : '未启用'),
            value: _lockEnabled,
            onChanged: _toggleLock,
          ),
          if (_lockEnabled && _biometricAvailable)
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('生物识别解锁'),
              subtitle: const Text('指纹或面部识别'),
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
            ),
          if (_lockEnabled)
            ListTile(
              leading: const Icon(Icons.password_outlined),
              title: const Text('修改密码'),
              onTap: _changePin,
            ),

          const Divider(indent: 16, endIndent: 16, height: 24),

          // ─── 外观 ──────────────────────────────────────────────────────
          _SectionHeader(title: '外观', icon: Icons.palette_outlined),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: const Text('主题'),
            subtitle: Text(_currentThemeLabel),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/theme'),
          ),

          const Divider(indent: 16, endIndent: 16, height: 24),

          // ─── 提醒 ──────────────────────────────────────────────────────
          _SectionHeader(title: '提醒', icon: Icons.notifications_outlined),
          ListTile(
            leading: const Icon(Icons.alarm_outlined),
            title: const Text('提醒设置'),
            subtitle: const Text('每日情绪提醒 + 免打扰'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/reminder'),
          ),

          const Divider(indent: 16, endIndent: 16, height: 24),

          // ─── 数据 ──────────────────────────────────────────────────────
          _SectionHeader(title: '数据', icon: Icons.storage_outlined),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('导出统计数据'),
            subtitle: const Text('仅导出脱敏统计 CSV'),
            onTap: _exportData,
          ),

          const Divider(indent: 16, endIndent: 16, height: 24),

          // ─── 关于 ──────────────────────────────────────────────────────
          _SectionHeader(title: '关于', icon: Icons.info_outlined),
          ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: const Text('隐私政策'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('版本'),
            trailing: Text('1.2.3',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(height: 24),
          // 底部签名
          Center(
            child: Text(
              '余烬 · 让情绪化为灰烬',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String get _currentThemeLabel {
    final name = ref.watch(themeNameProvider);
    return switch (name) {
      'dark' => '暗焰',
      'warmGray' => '暖灰',
      'deepBlue' => '深蓝',
      'pureBlack' => '纯黑',
      _ => '暗焰',
    };
  }
}

/// 分区标题
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              )),
        ],
      ),
    );
  }
}
