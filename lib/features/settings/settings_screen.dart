import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/pin_service.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/services/export_service.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/ai_api_service.dart';

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
                builder: (_) => const _ApiSettingsPage(),
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
            trailing: Text('1.2.2',
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

/// API 设置页面入口（独立 import 避免循环）
class _ApiSettingsPage extends StatelessWidget {
  const _ApiSettingsPage();

  @override
  Widget build(BuildContext context) {
    // 延迟 import 避免循环引用，直接实例化
    return const _ApiSettingsRouteWrapper();
  }
}

class _ApiSettingsRouteWrapper extends StatelessWidget {
  const _ApiSettingsRouteWrapper();

  @override
  Widget build(BuildContext context) {
    // 直接引入独立页面
    return const _InlineApiSettings();
  }
}

// 内嵌一个精简的 API 设置页面（避免 import 独立文件时的可能问题）
class _InlineApiSettings extends StatefulWidget {
  const _InlineApiSettings();

  @override
  State<_InlineApiSettings> createState() => _InlineApiSettingsState();
}

class _InlineApiSettingsState extends State<_InlineApiSettings> {
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();
  bool _obscureKey = true;
  bool _loading = true;
  bool _saving = false;
  String? _testResult;
  bool _testOk = false;

  static const _presets = <_Preset>[
    _Preset(name: 'OpenAI', url: 'https://api.openai.com', model: 'gpt-3.5-turbo', icon: '🤖'),
    _Preset(name: 'DeepSeek', url: 'https://api.deepseek.com', model: 'deepseek-chat', icon: '🌊'),
    _Preset(name: '通义千问', url: 'https://dashscope.aliyuncs.com/compatible-mode', model: 'qwen-turbo', icon: '🌐'),
    _Preset(name: 'Ollama', url: 'http://localhost:11434', model: 'llama3', icon: '🦙'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await AiApiService.instance.loadSettings();
    if (mounted) {
      setState(() {
        _apiKeyController.text = AiApiService.instance.apiKey;
        _baseUrlController.text = AiApiService.instance.baseUrl;
        _modelController.text = AiApiService.instance.model;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await AiApiService.instance.saveSettings(
      apiKey: _apiKeyController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      model: _modelController.text.trim(),
    );
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 已保存'), duration: Duration(seconds: 2), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _test() async {
    setState(() { _testResult = null; _saving = true; });
    // 先保存配置再测试
    await AiApiService.instance.saveSettings(
      apiKey: _apiKeyController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      model: _modelController.text.trim(),
    );
    try {
      final result = await AiApiService.instance.testConnection();
      if (mounted) setState(() { _testResult = '✅ $result'; _testOk = true; _saving = false; });
    } catch (e) {
      if (mounted) setState(() { _testResult = '❌ ${e.toString()}'; _testOk = false; _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text('AI 转化引擎', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // 顶部说明
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('接入真实 AI，让转化更懂你',
                          style: TextStyle(color: colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('配置后，莎翁剧场、俳句、反向鸡汤将用 AI 生成\n未配置时使用本地内置模板',
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12, height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 快捷预设
          Text('快捷预设', style: TextStyle(color: colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _presets.length,
              separatorBuilder: (context, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final p = _presets[i];
                final selected = _baseUrlController.text.contains(p.url.replaceAll('https://', '').replaceAll('http://', '').split('/').first);
                return GestureDetector(
                  onTap: () => setState(() {
                    _baseUrlController.text = p.url;
                    _modelController.text = p.model;
                    _testResult = null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? colorScheme.primary.withValues(alpha: 0.12) : colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: selected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.2),
                        width: selected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(p.icon, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(p.name, style: TextStyle(
                          color: selected ? colorScheme.primary : colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // API Key
          _buildLabel('API Key', colorScheme),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureKey,
            decoration: _inputDec('sk-...', colorScheme, suffix: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(_obscureKey ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: colorScheme.onSurfaceVariant),
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                ),
              ],
            )),
          ),
          const SizedBox(height: 14),

          // Base URL
          _buildLabel('API 地址（Base URL）', colorScheme),
          const SizedBox(height: 8),
          TextField(
            controller: _baseUrlController,
            keyboardType: TextInputType.url,
            decoration: _inputDec('https://api.openai.com', colorScheme),
          ),
          const SizedBox(height: 14),

          // 模型
          _buildLabel('模型名称', colorScheme),
          const SizedBox(height: 8),
          TextField(
            controller: _modelController,
            decoration: _inputDec('gpt-3.5-turbo', colorScheme),
          ),
          const SizedBox(height: 24),

          // 测试结果
          if (_testResult != null) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: (_testOk ? Colors.green : colorScheme.error).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (_testOk ? Colors.green : colorScheme.error).withValues(alpha: 0.3)),
              ),
              child: Text(_testResult!, style: TextStyle(color: _testOk ? Colors.green : colorScheme.error, fontSize: 13)),
            ),
          ],

          // 按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _test,
                  icon: _saving
                      ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary))
                      : const Icon(Icons.wifi_outlined, size: 16),
                  label: const Text('测试连接'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('保存'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 隐私说明
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '🔒 隐私说明\n\n'
              '• API Key 仅存储在本设备\n'
              '• 转化时会向你配置的地址发送情绪文本\n'
              '• 建议使用低权限的专用 API Key\n'
              '• 未配置时使用本地模板，完全离线',
              style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 12, height: 1.65),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, ColorScheme cs) => Text(text,
      style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w600));

  InputDecoration _inputDec(String hint, ColorScheme cs, {Widget? suffix}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
    filled: true,
    fillColor: cs.surfaceContainerHigh,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    suffixIcon: suffix,
  );
}

class _Preset {
  final String name;
  final String url;
  final String model;
  final String icon;
  const _Preset({required this.name, required this.url, required this.model, required this.icon});
}
