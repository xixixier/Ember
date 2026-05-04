import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  API 提供商定义（参照 rikkahub Provider 架构）
// ─────────────────────────────────────────────────────────────────────────────

/// 内置 API 提供商
enum ApiProvider {
  openai(
    name: 'OpenAI',
    defaultBaseUrl: 'https://api.openai.com',
    defaultModel: 'gpt-4o-mini',
    defaultModels: ['gpt-4o', 'gpt-4o-mini', 'gpt-4-turbo', 'gpt-3.5-turbo'],
    icon: '🤖',
    needsPath: true,
  ),
  deepseek(
    name: 'DeepSeek',
    defaultBaseUrl: 'https://api.deepseek.com',
    defaultModel: 'deepseek-chat',
    defaultModels: ['deepseek-chat', 'deepseek-reasoner'],
    icon: '🌊',
    needsPath: true,
  ),
  qwen(
    name: '通义千问',
    defaultBaseUrl: 'https://dashscope.aliyuncs.com/compatible-mode',
    defaultModel: 'qwen-turbo',
    defaultModels: ['qwen-turbo', 'qwen-plus', 'qwen-max'],
    icon: '🌐',
    needsPath: true,
  ),
  zhipu(
    name: '智谱 AI',
    defaultBaseUrl: 'https://open.bigmodel.cn/api/paas',
    defaultModel: 'glm-4-flash',
    defaultModels: ['glm-4-flash', 'glm-4-air', 'glm-4-plus'],
    icon: '🧠',
    needsPath: true,
  ),
  moonshot(
    name: 'Moonshot',
    defaultBaseUrl: 'https://api.moonshot.cn',
    defaultModel: 'moonshot-v1-8k',
    defaultModels: ['moonshot-v1-8k', 'moonshot-v1-32k', 'moonshot-v1-128k'],
    icon: '🌙',
    needsPath: true,
  ),
  ollama(
    name: 'Ollama (本地)',
    defaultBaseUrl: 'http://localhost:11434',
    defaultModel: 'llama3',
    defaultModels: ['llama3', 'qwen2', 'gemma2'],
    icon: '🦙',
    needsPath: false, // Ollama 自身就是 /v1/chat/completions
  ),
  custom(
    name: '自定义',
    defaultBaseUrl: '',
    defaultModel: '',
    defaultModels: [],
    icon: '⚙️',
    needsPath: true,
  );

  const ApiProvider({
    required this.name,
    required this.defaultBaseUrl,
    required this.defaultModel,
    required this.defaultModels,
    required this.icon,
    required this.needsPath,
  });

  final String name;
  final String defaultBaseUrl;
  final String defaultModel;
  final List<String> defaultModels;
  final String icon;
  /// 是否需要在 base URL 末尾拼接 /v1
  final bool needsPath;
}

// ─────────────────────────────────────────────────────────────────────────────
//  自定义请求头
// ─────────────────────────────────────────────────────────────────────────────

class CustomHeader {
  final String key;
  final String value;
  const CustomHeader({required this.key, required this.value});

  Map<String, String> toMap() => {key: value};
}

// ─────────────────────────────────────────────────────────────────────────────
//  API 服务（参考 rikkahub OpenAIProvider 实现）
// ─────────────────────────────────────────────────────────────────────────────

/// AI API 服务
/// 参考 rikkahub 的 Provider 架构，支持多种 OpenAI 兼容 API 提供商
class AiApiService {
  AiApiService._();
  static final AiApiService instance = AiApiService._();

  // ── SharedPreferences 键 ──
  static const _keyProvider = 'ai_provider';
  static const _keyApiKey = 'ai_api_key';
  static const _keyBaseUrl = 'ai_base_url';
  static const _keyModel = 'ai_model';
  static const _keyCustomHeaders = 'ai_custom_headers';
  static const _keyMaxTokens = 'ai_max_tokens';

  // ── 缓存 ──
  ApiProvider _cachedProvider = ApiProvider.openai;
  String? _cachedApiKey;
  String? _cachedBaseUrl;
  String? _cachedModel;
  List<CustomHeader> _cachedCustomHeaders = [];
  int _cachedMaxTokens = 600;

  // ── Getters ──
  ApiProvider get provider => _cachedProvider;
  String get apiKey => _cachedApiKey ?? '';
  String get baseUrl => _cachedBaseUrl ?? '';
  String get model => _cachedModel ?? '';
  List<CustomHeader> get customHeaders => _cachedCustomHeaders;
  int get maxTokens => _cachedMaxTokens;

  bool get isConfigured =>
      _cachedApiKey != null &&
      _cachedApiKey!.isNotEmpty &&
      _cachedBaseUrl != null &&
      _cachedBaseUrl!.isNotEmpty;

  // ── 持久化 ──

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final providerName = prefs.getString(_keyProvider);
    if (providerName != null) {
      _cachedProvider = ApiProvider.values.firstWhere(
        (p) => p.name == providerName,
        orElse: () => ApiProvider.openai,
      );
    }
    _cachedApiKey = prefs.getString(_keyApiKey);
    _cachedBaseUrl = prefs.getString(_keyBaseUrl);
    _cachedModel = prefs.getString(_keyModel);
    _cachedMaxTokens = prefs.getInt(_keyMaxTokens) ?? 600;

    // 自定义请求头
    final headersJson = prefs.getString(_keyCustomHeaders);
    if (headersJson != null) {
      try {
        final list = jsonDecode(headersJson) as List;
        _cachedCustomHeaders = list
            .map((e) => CustomHeader(
                  key: e['key'] as String,
                  value: e['value'] as String,
                ))
            .toList();
      } catch (_) {
        _cachedCustomHeaders = [];
      }
    }
  }

  Future<void> saveSettings({
    required ApiProvider provider,
    required String apiKey,
    required String baseUrl,
    required String model,
    List<CustomHeader>? customHeaders,
    int? maxTokens,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProvider, provider.name);
    await prefs.setString(_keyApiKey, apiKey);
    await prefs.setString(_keyBaseUrl, baseUrl);
    await prefs.setString(_keyModel, model);
    if (customHeaders != null) {
      final json = jsonEncode(customHeaders
          .map((h) => {'key': h.key, 'value': h.value})
          .toList());
      await prefs.setString(_keyCustomHeaders, json);
    }
    if (maxTokens != null) {
      await prefs.setInt(_keyMaxTokens, maxTokens);
    }
    _cachedProvider = provider;
    _cachedApiKey = apiKey;
    _cachedBaseUrl = baseUrl;
    _cachedModel = model;
    _cachedCustomHeaders = customHeaders ?? _cachedCustomHeaders;
    _cachedMaxTokens = maxTokens ?? _cachedMaxTokens;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  URL 构建（参考 rikkahub 的 ChatCompletionsAPI.buildRequest）
  //
  //  核心逻辑：
  //  1. 如果 provider.needsPath 为 true，确保 URL 以 /v1 结尾
  //  2. 使用 replaceLast 移除末尾可能已有的 /v1 或 /v1/，再统一拼接
  //  3. 如果 provider.needsPath 为 false（如 Ollama），直接在 base 后拼 /v1
  // ─────────────────────────────────────────────────────────────────────────

  String _buildApiUrl() {
    var base = baseUrl.trim();

    if (provider.needsPath) {
      // 对于需要 /v1 的提供商，先确保去掉末尾已有的 /v1
      // 处理各种情况: /v1, /v1/, /v1/chat/completions 等
      if (base.contains('/v1')) {
        final idx = base.lastIndexOf('/v1');
        base = base.substring(0, idx);
      }
      // 去掉末尾斜杠
      base = base.replaceAll(RegExp(r'/+$'), '');
      // 统一拼接
      return '$base/v1/chat/completions';
    } else {
      // Ollama 等自身提供 /v1 端点的
      base = base.replaceAll(RegExp(r'/+$'), '');
      return '$base/v1/chat/completions';
    }
  }

  /// 构建 HTTP 请求头（参考 rikkahub OpenAIProvider）
  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    // 叠加用户自定义请求头
    for (final h in _cachedCustomHeaders) {
      headers[h.key] = h.value;
    }

    return headers;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  错误解析（参考 rikkahub ErrorParser）
  //  依次检查 error.message, error.detail, message, description 字段
  // ─────────────────────────────────────────────────────────────────────────

  String _parseErrorMessage(int statusCode, String? body) {
    if (body == null || body.isEmpty) {
      return 'HTTP $statusCode（无响应内容）';
    }

    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        // 尝试多层 error 对象
        final errorObj = json['error'];
        if (errorObj is Map<String, dynamic>) {
          // OpenAI 格式: {"error": {"message": "...", "type": "...", "code": "..."}}
          final msg = errorObj['message'] as String?;
          if (msg != null && msg.isNotEmpty) return msg;

          // 某些 API 返回 {"error": {"detail": "..."}}
          final detail = errorObj['detail'] as String?;
          if (detail != null && detail.isNotEmpty) return detail;

          // 某些 API 返回 {"error": {"description": "..."}}
          final desc = errorObj['description'] as String?;
          if (desc != null && desc.isNotEmpty) return desc;
        }

        // 顶层 message 字段
        final msg = json['message'] as String?;
        if (msg != null && msg.isNotEmpty) return 'HTTP $statusCode: $msg';

        // 顶层 detail 字段
        final detail = json['detail'] as String?;
        if (detail != null && detail.isNotEmpty) return 'HTTP $statusCode: $detail';

        // 顶层 error 是字符串
        final errStr = json['error'];
        if (errStr is String && errStr.isNotEmpty) return errStr;
      }

      // 非预期格式，截取前200字符
      if (body.length > 200) {
        return 'HTTP $statusCode: ${body.substring(0, 200)}...';
      }
      return 'HTTP $statusCode: $body';
    } catch (_) {
      // JSON 解析失败
      if (body.length > 200) {
        return 'HTTP $statusCode: ${body.substring(0, 200)}...';
      }
      return 'HTTP $statusCode: $body';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Chat 接口
  // ─────────────────────────────────────────────────────────────────────────

  /// 发送聊天请求，返回模型回复文本
  Future<String> chat({
    required String systemPrompt,
    required String userMessage,
    double temperature = 0.9,
  }) async {
    await loadSettings();
    if (!isConfigured) throw ApiNotConfiguredException();

    final url = _buildApiUrl();
    final headers = _buildHeaders();

    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userMessage},
      ],
      'temperature': temperature,
      'max_tokens': _cachedMaxTokens,
    });

    http.Response response;
    try {
      response = await http
          .post(Uri.parse(url), headers: headers, body: body)
          .timeout(const Duration(seconds: 30));
    } on SocketException {
      throw ApiException('网络连接失败，请检查地址是否正确或网络是否可用');
    } on HttpException {
      throw ApiException('HTTP 请求异常，请检查 API 地址格式');
    } on FormatException {
      throw ApiException('API 地址格式无效，请检查 URL');
    } on http.ClientException catch (e) {
      throw ApiException('连接失败: ${e.message}');
    } catch (e) {
      if (e is ApiException || e is ApiNotConfiguredException) rethrow;
      throw ApiException('请求失败: $e');
    }

    // 解析响应
    if (response.statusCode != 200) {
      throw ApiException(_parseErrorMessage(response.statusCode, response.body));
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content =
          data['choices']?[0]?['message']?['content'] as String?;
      if (content == null || content.isEmpty) {
        throw ApiException('模型返回了空内容');
      }
      return content.trim();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('解析响应失败，API 返回格式异常');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  连接测试（参考 rikkahub 的 listModels 测试方式）
  //  策略：先尝试 /models 端点（轻量），失败则 fallback 到 chat
  // ─────────────────────────────────────────────────────────────────────────

  Future<String> testConnection() async {
    await loadSettings();
    if (!isConfigured) throw ApiNotConfiguredException();

    final url = _buildApiUrl();
    final headers = _buildHeaders();

    // 策略1：尝试 /models 端点（轻量 HEAD 或 GET）
    try {
      final modelsUrl = url.replaceAll('/chat/completions', '/models');
      final response = await http
          .get(Uri.parse(modelsUrl), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // /models 成功，解析模型列表
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final models = data['data'] as List?;
          if (models != null && models.isNotEmpty) {
            return '连接成功，可用 ${models.length} 个模型';
          }
        } catch (_) {}
        return '连接成功';
      }

      // /models 不可用，尝试 chat 作为 fallback
      return _testViaChat(headers);
    } catch (e) {
      // /models 失败，尝试 chat fallback
      if (e is ApiException) rethrow;
      try {
        return await _testViaChat(headers);
      } catch (chatError) {
        // 两个都失败
        if (e.toString().contains('SocketException') ||
            e.toString().contains('ClientException')) {
          throw ApiException('网络连接失败，请检查地址是否可达');
        }
        throw ApiException('连接测试失败: $chatError');
      }
    }
  }

  /// 通过发送一条极短消息测试连接
  Future<String> _testViaChat(Map<String, String> headers) async {
    final url = _buildApiUrl();
    final response = await http
        .post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode({
            'model': model,
            'messages': [
              {'role': 'user', 'content': 'Hi'},
            ],
            'max_tokens': 5,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw ApiException(_parseErrorMessage(response.statusCode, response.body));
    }

    return '连接成功';
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  获取可用模型列表（参考 rikkahub listModels）
  // ─────────────────────────────────────────────────────────────────────────

  /// 获取 API 可用模型列表，失败返回 null
  Future<List<String>?> fetchModels() async {
    await loadSettings();
    if (!isConfigured) return null;

    final url = _buildApiUrl();
    final modelsUrl = url.replaceAll('/chat/completions', '/models');
    final headers = _buildHeaders();

    try {
      final response = await http
          .get(Uri.parse(modelsUrl), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final models = data['data'] as List?;
      if (models == null) return null;

      return models
          .map((m) => m['id'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toList()
        ..sort();
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  重置
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProvider);
    await prefs.remove(_keyApiKey);
    await prefs.remove(_keyBaseUrl);
    await prefs.remove(_keyModel);
    await prefs.remove(_keyCustomHeaders);
    await prefs.remove(_keyMaxTokens);
    _cachedProvider = ApiProvider.openai;
    _cachedApiKey = null;
    _cachedBaseUrl = null;
    _cachedModel = null;
    _cachedCustomHeaders = [];
    _cachedMaxTokens = 600;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  异常
// ─────────────────────────────────────────────────────────────────────────────

class ApiNotConfiguredException implements Exception {
  @override
  String toString() => '尚未配置 AI API，请在设置中填写 API Key 和地址';
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}
