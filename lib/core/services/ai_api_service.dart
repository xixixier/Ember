import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// AI API 服务
/// 支持 OpenAI 兼容格式（OpenAI / DeepSeek / 通义千问 / 本地 Ollama 等）
class AiApiService {
  AiApiService._();
  static final AiApiService instance = AiApiService._();

  static const _keyApiKey = 'ai_api_key';
  static const _keyBaseUrl = 'ai_base_url';
  static const _keyModel = 'ai_model';
  static const _defaultModel = 'gpt-3.5-turbo';

  String? _cachedApiKey;
  String? _cachedBaseUrl;
  String? _cachedModel;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedApiKey = prefs.getString(_keyApiKey);
    _cachedBaseUrl = prefs.getString(_keyBaseUrl);
    _cachedModel = prefs.getString(_keyModel);
  }

  Future<void> saveSettings({
    required String apiKey,
    required String baseUrl,
    required String model,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey, apiKey);
    await prefs.setString(_keyBaseUrl, baseUrl);
    await prefs.setString(_keyModel, model.isEmpty ? _defaultModel : model);
    _cachedApiKey = apiKey;
    _cachedBaseUrl = baseUrl;
    _cachedModel = model.isEmpty ? _defaultModel : model;
  }

  bool get isConfigured =>
      _cachedApiKey != null && _cachedApiKey!.isNotEmpty &&
      _cachedBaseUrl != null && _cachedBaseUrl!.isNotEmpty;

  String get apiKey => _cachedApiKey ?? '';
  String get baseUrl => _cachedBaseUrl ?? '';
  String get model => _cachedModel ?? _defaultModel;

  /// 发送聊天请求，返回模型回复文本
  /// [systemPrompt] 系统提示词
  /// [userMessage] 用户输入
  /// 若未配置则抛出 [ApiNotConfiguredException]
  Future<String> chat({
    required String systemPrompt,
    required String userMessage,
    double temperature = 0.9,
  }) async {
    await loadSettings();

    if (!isConfigured) {
      throw ApiNotConfiguredException();
    }

    final url = '${baseUrl.trimRight().replaceAll(RegExp(r'/$'), '')}/v1/chat/completions';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
        'temperature': temperature,
        'max_tokens': 600,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      final message = (body['error']?['message'] as String?) ?? '请求失败 ${response.statusCode}';
      throw ApiException(message);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['choices']?[0]?['message']?['content'] as String?;
    if (content == null || content.isEmpty) {
      throw ApiException('模型返回了空内容');
    }

    return content.trim();
  }
}

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
