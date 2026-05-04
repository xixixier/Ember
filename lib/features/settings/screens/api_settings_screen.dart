import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ember/core/services/ai_api_service.dart';
import 'package:ember/core/theme/ember_theme_extension.dart';

/// AI API 配置页面
/// 支持 OpenAI / DeepSeek / 通义千问 / 本地 Ollama 等兼容格式
class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();
  bool _obscureKey = true;
  bool _loading = true;
  bool _saving = false;
  String? _testResult;
  bool _testOk = false;

  // 快捷预设
  static const _presets = [
    _ApiPreset(
      name: 'OpenAI',
      url: 'https://api.openai.com',
      model: 'gpt-3.5-turbo',
      icon: '🤖',
    ),
    _ApiPreset(
      name: 'DeepSeek',
      url: 'https://api.deepseek.com',
      model: 'deepseek-chat',
      icon: '🌊',
    ),
    _ApiPreset(
      name: '通义千问',
      url: 'https://dashscope.aliyuncs.com/compatible-mode',
      model: 'qwen-turbo',
      icon: '🌐',
    ),
    _ApiPreset(
      name: 'Ollama',
      url: 'http://localhost:11434',
      model: 'llama3',
      icon: '🦙',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
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
        const SnackBar(
          content: Text('✅ 已保存'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _test() async {
    setState(() {
      _testResult = null;
      _saving = true;
    });
    // 先保存
    await AiApiService.instance.saveSettings(
      apiKey: _apiKeyController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      model: _modelController.text.trim(),
    );
    try {
      final result = await AiApiService.instance.chat(
        systemPrompt: '你是一个测试机器人，只需回复"连接成功"四个字。',
        userMessage: '测试',
        temperature: 0.1,
      );
      if (mounted) {
        setState(() {
          _testResult = '✅ $result';
          _testOk = true;
          _saving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testResult = '❌ ${e.toString()}';
          _testOk = false;
          _saving = false;
        });
      }
    }
  }

  void _applyPreset(_ApiPreset preset) {
    setState(() {
      _baseUrlController.text = preset.url;
      _modelController.text = preset.model;
      _testResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<EmberThemeExtension>()!;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI 转化引擎',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // 说明卡片
          _InfoCard(
            ext: ext,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 20),

          // 快捷预设
          Text(
            '快捷预设',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _presets.length,
              separatorBuilder: (context, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final preset = _presets[i];
                final selected = _baseUrlController.text.startsWith(
                  preset.url.split('//').last.split('/').first,
                );
                return _PresetChip(
                  preset: preset,
                  selected: selected,
                  onTap: () => _applyPreset(preset),
                  colorScheme: colorScheme,
                  ext: ext,
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // API Key
          Text(
            'API Key',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureKey,
            decoration: InputDecoration(
              hintText: 'sk-...',
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              filled: true,
              fillColor: colorScheme.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _obscureKey ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy_outlined, size: 18, color: colorScheme.onSurfaceVariant),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _apiKeyController.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已复制'), duration: Duration(seconds: 1)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Base URL
          Text(
            'API 地址（Base URL）',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _baseUrlController,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: 'https://api.openai.com',
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              filled: true,
              fillColor: colorScheme.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),

          // 模型名
          Text(
            '模型名称',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _modelController,
            decoration: InputDecoration(
              hintText: 'gpt-3.5-turbo',
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              filled: true,
              fillColor: colorScheme.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 24),

          // 测试结果
          if (_testResult != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: (_testOk ? Colors.green : colorScheme.error)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_testOk ? Colors.green : colorScheme.error)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _testResult!,
                style: TextStyle(
                  color: _testOk ? Colors.green : colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ),

          // 按钮行
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _test,
                  icon: _saving
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        )
                      : const Icon(Icons.wifi_outlined, size: 16),
                  label: const Text('测试连接'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // 隐私说明
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      '隐私说明',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• API Key 仅存储在本设备，不上传到任何服务器\n'
                  '• 转化时会向你配置的 API 地址发送情绪文本\n'
                  '• 建议使用专用的低权限 API Key\n'
                  '• 不配置 API 时，将使用本地内置模板',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final EmberThemeExtension ext;
  final ColorScheme colorScheme;

  const _InfoCard({required this.ext, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ext.fireOrange.withValues(alpha: 0.12),
            ext.emberGold.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ext.emberGold.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ext.fireOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('✨', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '接入真实 AI，让转化更懂你',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '配置后，莎翁剧场、俳句、反向鸡汤\n将使用 AI 根据你的文字生成',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApiPreset {
  final String name;
  final String url;
  final String model;
  final String icon;

  const _ApiPreset({
    required this.name,
    required this.url,
    required this.model,
    required this.icon,
  });
}

class _PresetChip extends StatelessWidget {
  final _ApiPreset preset;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final EmberThemeExtension ext;

  const _PresetChip({
    required this.preset,
    required this.selected,
    required this.onTap,
    required this.colorScheme,
    required this.ext,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.2),
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(preset.icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              preset.name,
              style: TextStyle(
                color: selected ? colorScheme.primary : colorScheme.onSurface,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
