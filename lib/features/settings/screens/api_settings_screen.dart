import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ember/core/services/ai_api_service.dart';
import 'package:ember/core/theme/ember_theme_extension.dart';

/// AI API 配置页面（参照 rikkahub Provider 架构）
/// 支持选择内置提供商、自定义 API 地址、自定义请求头
class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  ApiProvider _selectedProvider = ApiProvider.openai;

  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();
  final _maxTokensController = TextEditingController(text: '600');

  // 自定义请求头
  final List<_HeaderRow> _customHeaders = [];

  bool _obscureKey = true;
  bool _loading = true;
  bool _saving = false;
  String? _testResult;
  bool _testOk = false;

  // 模型列表
  List<String>? _fetchedModels;
  bool _loadingModels = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    await AiApiService.instance.loadSettings();
    final svc = AiApiService.instance;
    if (mounted) {
      setState(() {
        _selectedProvider = svc.provider;
        _apiKeyController.text = svc.apiKey;
        _baseUrlController.text = svc.baseUrl;
        _modelController.text = svc.model;
        _maxTokensController.text = svc.maxTokens.toString();

        // 自定义请求头
        _customHeaders
          ..clear()
          ..addAll(svc.customHeaders.map(
            (h) => _HeaderRow(key: h.key, value: h.value),
          ));
        if (_customHeaders.isEmpty) {
          _customHeaders.add(_HeaderRow());
        }

        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    _maxTokensController.dispose();
    for (final h in _customHeaders) {
      h.dispose();
    }
    super.dispose();
  }

  void _applyProvider(ApiProvider provider) {
    setState(() {
      _selectedProvider = provider;
      if (_baseUrlController.text.isEmpty ||
          ApiProvider.values.any((p) =>
              p.defaultBaseUrl.isNotEmpty &&
              _baseUrlController.text.contains(
                  p.defaultBaseUrl.replaceAll(RegExp(r'https?://'), '')))) {
        _baseUrlController.text = provider.defaultBaseUrl;
      }
      if (_modelController.text.isEmpty ||
          provider.defaultModels.contains(_modelController.text)) {
        // 保持当前模型（如果它在新提供商的默认列表中）
      } else if (provider.defaultModel.isNotEmpty) {
        _modelController.text = provider.defaultModel;
      }
      _testResult = null;
    });
  }

  Future<void> _fetchModels() async {
    setState(() => _loadingModels = true);
    final models = await AiApiService.instance.fetchModels();
    if (mounted) {
      setState(() {
        _fetchedModels = models;
        _loadingModels = false;
      });
    }
  }

  List<CustomHeader> _buildCustomHeaders() {
    return _customHeaders
        .where((h) => h.keyController.text.trim().isNotEmpty)
        .map((h) => CustomHeader(
              key: h.keyController.text.trim(),
              value: h.valueController.text.trim(),
            ))
        .toList();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await AiApiService.instance.saveSettings(
      provider: _selectedProvider,
      apiKey: _apiKeyController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      model: _modelController.text.trim(),
      customHeaders: _buildCustomHeaders(),
      maxTokens: int.tryParse(_maxTokensController.text) ?? 600,
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
    // 先保存再测试
    await AiApiService.instance.saveSettings(
      provider: _selectedProvider,
      apiKey: _apiKeyController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      model: _modelController.text.trim(),
      customHeaders: _buildCustomHeaders(),
      maxTokens: int.tryParse(_maxTokensController.text) ?? 600,
    );
    try {
      final result = await AiApiService.instance.testConnection();
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<EmberThemeExtension>()!;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
          _InfoCard(ext: ext, colorScheme: colorScheme),
          const SizedBox(height: 20),

          // 提供商选择
          Text(
            '选择 API 提供商',
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
              itemCount: ApiProvider.values.length,
              separatorBuilder: (context, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final provider = ApiProvider.values[i];
                final selected = _selectedProvider == provider;
                return _ProviderChip(
                  provider: provider,
                  selected: selected,
                  onTap: () => _applyProvider(provider),
                  colorScheme: colorScheme,
                  ext: ext,
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
            decoration: _inputDec(
              colorScheme,
              hint: _selectedProvider == ApiProvider.ollama
                  ? '本地 Ollama 通常不需要 Key'
                  : 'sk-...',
              suffix: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _obscureKey
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () =>
                        setState(() => _obscureKey = !_obscureKey),
                  ),
                  if (_apiKeyController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.copy_outlined,
                          size: 18, color: colorScheme.onSurfaceVariant),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: _apiKeyController.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('已复制'),
                              duration: Duration(seconds: 1)),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Base URL
          _buildLabel('API 地址（Base URL）', colorScheme),
          const SizedBox(height: 8),
          TextField(
            controller: _baseUrlController,
            keyboardType: TextInputType.url,
            decoration: _inputDec(
              colorScheme,
              hint: _selectedProvider.defaultBaseUrl.isNotEmpty
                  ? _selectedProvider.defaultBaseUrl
                  : 'https://your-api.com',
            ),
          ),
          const SizedBox(height: 14),

          // 模型名称
          Row(
            children: [
              Expanded(child: _buildLabel('模型名称', colorScheme)),
              if (_fetchedModels != null)
                Text(
                  '${_fetchedModels!.length} 个可用',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _modelController,
                  decoration: _inputDec(
                    colorScheme,
                    hint: _selectedProvider.defaultModel.isNotEmpty
                        ? _selectedProvider.defaultModel
                        : '模型名称',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _loadingModels ? null : _fetchModels,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                ),
                child: _loadingModels
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : const Text('获取模型', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),

          // 模型列表（获取成功后显示）
          if (_fetchedModels != null && _fetchedModels!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('可用模型（点击选择）',
                      style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _fetchedModels!.map((m) {
                      final selected = _modelController.text == m;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _modelController.text = m),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? colorScheme.primary.withValues(alpha: 0.15)
                                : colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? colorScheme.primary
                                  : Colors.transparent,
                              width: selected ? 1 : 0,
                            ),
                          ),
                          child: Text(
                            m,
                            style: TextStyle(
                              fontSize: 12,
                              color: selected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Max Tokens
          _buildLabel('最大 Token 数', colorScheme),
          const SizedBox(height: 8),
          TextField(
            controller: _maxTokensController,
            keyboardType: TextInputType.number,
            decoration: _inputDec(colorScheme, hint: '600'),
          ),
          const SizedBox(height: 20),

          // 自定义请求头
          _buildLabel('自定义请求头（可选）', colorScheme),
          const SizedBox(height: 6),
          Text(
            '部分 API 中转服务需要额外的请求头（如 X-Request-ID）',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          ..._buildCustomHeaderRows(colorScheme),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () =>
                setState(() => _customHeaders.add(_HeaderRow())),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('添加请求头', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10),
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

          const SizedBox(height: 24),

          // 清除配置
          Center(
            child: TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('清除配置'),
                    content: const Text('确定要清除所有 API 配置吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                        ),
                        child: const Text('清除'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await AiApiService.instance.clearSettings();
                  _loadExisting();
                }
              },
              child: Text(
                '清除配置',
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // 隐私说明
          _PrivacyCard(colorScheme: colorScheme),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<Widget> _buildCustomHeaderRows(ColorScheme cs) {
    return List.generate(_customHeaders.length, (i) {
      final row = _customHeaders[i];
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: row.keyController,
                decoration: _inputDec(cs,
                    hint: 'Header 名称（如 X-Custom）'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextField(
                controller: row.valueController,
                decoration: _inputDec(cs, hint: '值'),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.remove_circle_outline,
                  size: 18, color: cs.error),
              onPressed: () => setState(() => _customHeaders.removeAt(i)),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLabel(String text, ColorScheme cs) => Text(text,
      style: TextStyle(
          color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w600));

  InputDecoration _inputDec(ColorScheme cs,
      {String? hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
      filled: true,
      fillColor: cs.surfaceContainerHigh,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffix,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  组件
// ─────────────────────────────────────────────────────────────────────────────

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

class _ProviderChip extends StatelessWidget {
  final ApiProvider provider;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final EmberThemeExtension ext;

  const _ProviderChip({
    required this.provider,
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
            Text(provider.icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              provider.name,
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

class _PrivacyCard extends StatelessWidget {
  final ColorScheme colorScheme;
  const _PrivacyCard({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Icon(Icons.shield_outlined,
                  size: 14, color: colorScheme.onSurfaceVariant),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  辅助类
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderRow {
  final TextEditingController keyController;
  final TextEditingController valueController;
  _HeaderRow({String key = '', String value = ''})
      : keyController = TextEditingController(text: key),
        valueController = TextEditingController(text: value);

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}
