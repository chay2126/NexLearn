import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

String _normalizeBaseUrl(String value) =>
    value.endsWith('/') ? value.substring(0, value.length - 1) : value;

bool _isLocalRequest(Uri uri) {
  final host = uri.host;
  return uri.scheme == 'file' ||
      host.isEmpty ||
      host == 'localhost' ||
      host == '127.0.0.1' ||
      host == '0.0.0.0' ||
      host == '::1' ||
      host == '[::1]';
}

String _defaultBaseUrl({Uri? currentUri}) {
  const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  if (configuredBaseUrl.isNotEmpty) {
    return _normalizeBaseUrl(configuredBaseUrl);
  }

  final resolvedUri = currentUri ?? Uri.base;
  if (_isLocalRequest(resolvedUri)) {
    return 'http://127.0.0.1:8000';
  }

  if (API_URL.isNotEmpty) {
    return _normalizeBaseUrl(API_URL);
  }

  final scheme = resolvedUri.scheme == 'https' ? 'https' : 'http';
  return _normalizeBaseUrl(
    Uri(scheme: scheme, host: resolvedUri.host, port: 8000).toString(),
  );
}

class ApiService {
  ApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = resolveBaseUrl(baseUrl: baseUrl);

  final http.Client _client;
  final String _baseUrl;

  static String resolveBaseUrl({String? baseUrl, Uri? currentUri}) {
    if (baseUrl != null && baseUrl.isNotEmpty) {
      return _normalizeBaseUrl(baseUrl);
    }

    return _defaultBaseUrl(currentUri: currentUri);
  }

  Future<List<TopicSummary>> fetchTopics() async {
    final payload = await _request(
      () => _client.get(Uri.parse('$_baseUrl/topics')),
    );
    return (payload as List<dynamic>)
        .map((item) => TopicSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TopicSimulation> fetchSimulation(int topicId) async {
    final payload = await _request(
      () => _client.get(Uri.parse('$_baseUrl/simulation/$topicId')),
    );
    return TopicSimulation.fromJson(payload as Map<String, dynamic>);
  }

  Future<ChemistryResult> calculateReactionRate({
    required int topicId,
    required double concentration,
    required double temperature,
  }) async {
    final payload = await _request(
      () => _client.post(
        Uri.parse('$_baseUrl/chemistry/reaction-rate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'topic_id': topicId,
          'concentration': concentration,
          'temperature': temperature,
        }),
      ),
    );
    return ChemistryResult.fromJson(payload as Map<String, dynamic>);
  }

  Future<EnglishAnalysis> analyzeSentence({
    required int topicId,
    required String sentence,
  }) async {
    final payload = await _request(
      () => _client.post(
        Uri.parse('$_baseUrl/english/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'topic_id': topicId, 'sentence': sentence}),
      ),
    );
    return EnglishAnalysis.fromJson(payload as Map<String, dynamic>);
  }

  void dispose() {
    _client.close();
  }

  Future<Object> _request(Future<http.Response> Function() callback) async {
    try {
      final response = await callback();
      final payload = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return payload;
      }

      if (payload is Map<String, dynamic> && payload['detail'] != null) {
        throw ApiException(payload['detail'].toString());
      }
      throw ApiException('Unexpected API error (${response.statusCode}).');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'Could not reach the NexLearn API. Start FastAPI on http://127.0.0.1:8000, or set --dart-define=API_BASE_URL=<your-backend-url> if the backend runs elsewhere.',
      );
    }
  }
  Future<ChatResponse> sendChatMessage({
  required int topicId,
  required String message,
  required List<ChatMessage> history,
}) async {
  final payload = await _request(
    () => _client.post(
      Uri.parse('$_baseUrl/chat/message'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'topic_id': topicId,
        'message': message,
        'history': history.map((m) => m.toJson()).toList(),
      }),
    ),
  );
  return ChatResponse.fromJson(payload as Map<String, dynamic>);
}
}

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TopicSummary {
  const TopicSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.formula,
  });

  final int id;
  final String title;
  final String description;
  final String type;
  final String formula;

  factory TopicSummary.fromJson(Map<String, dynamic> json) {
    return TopicSummary(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      formula: json['formula'] as String,
    );
  }
}

class TopicSimulation {
  const TopicSimulation({required this.topic, required this.config});

  final TopicSummary topic;
  final SimulationConfig config;

  factory TopicSimulation.fromJson(Map<String, dynamic> json) {
    return TopicSimulation(
      topic: TopicSummary.fromJson(json['topic'] as Map<String, dynamic>),
      config: SimulationConfig.fromJson(json['config'] as Map<String, dynamic>),
    );
  }
}

class SimulationConfig {
  const SimulationConfig({
    required this.visualization,
    required this.inputs,
    this.inputType,
  });

  final String visualization;
  final List<InputDefinition> inputs;
  final String? inputType;

  factory SimulationConfig.fromJson(Map<String, dynamic> json) {
    return SimulationConfig(
      visualization: json['visualization'] as String,
      inputs: (json['inputs'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => InputDefinition.fromJson(item as Map<String, dynamic>))
          .toList(),
      inputType: json['input_type'] as String?,
    );
  }
}

class InputDefinition {
  const InputDefinition({
    required this.name,
    required this.min,
    required this.max,
    required this.defaultValue,
  });

  final String name;
  final double min;
  final double max;
  final double defaultValue;

  factory InputDefinition.fromJson(Map<String, dynamic> json) {
    return InputDefinition(
      name: json['name'] as String,
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
      defaultValue: (json['default'] as num).toDouble(),
    );
  }
}

class ChemistryResult {
  const ChemistryResult({
    required this.topicId,
    required this.rate,
    required this.rateConstant,
    required this.graphPoints,
    required this.formula,
    required this.cacheHit,
  });

  final int topicId;
  final double rate;
  final double rateConstant;
  final List<GraphPoint> graphPoints;
  final String formula;
  final bool cacheHit;

  factory ChemistryResult.fromJson(Map<String, dynamic> json) {
    return ChemistryResult(
      topicId: json['topic_id'] as int,
      rate: (json['rate'] as num).toDouble(),
      rateConstant: (json['rate_constant'] as num).toDouble(),
      graphPoints: (json['graph_points'] as List<dynamic>)
          .map((item) => GraphPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
      formula: json['formula'] as String,
      cacheHit: json['cache_hit'] as bool,
    );
  }
}

class GraphPoint {
  const GraphPoint({required this.time, required this.concentration});

  final double time;
  final double concentration;

  factory GraphPoint.fromJson(Map<String, dynamic> json) {
    return GraphPoint(
      time: (json['time'] as num).toDouble(),
      concentration: (json['concentration'] as num).toDouble(),
    );
  }
}

class EnglishAnalysis {
  const EnglishAnalysis({
    required this.topicId,
    required this.sentence,
    required this.subject,
    required this.verb,
    required this.object,
    required this.segments,
    required this.visualization,
    required this.cacheHit,
  });

  final int topicId;
  final String sentence;
  final String subject;
  final String verb;
  final String object;
  final List<TextSegment> segments;
  final String visualization;
  final bool cacheHit;

  factory EnglishAnalysis.fromJson(Map<String, dynamic> json) {
    return EnglishAnalysis(
      topicId: json['topic_id'] as int,
      sentence: json['sentence'] as String,
      subject: json['subject'] as String,
      verb: json['verb'] as String,
      object: json['object'] as String,
      segments: (json['segments'] as List<dynamic>)
          .map((item) => TextSegment.fromJson(item as Map<String, dynamic>))
          .toList(),
      visualization: json['visualization'] as String,
      cacheHit: json['cache_hit'] as bool,
    );
  }
}

class TextSegment {
  const TextSegment({required this.text, required this.role});

  final String text;
  final String role;

  factory TextSegment.fromJson(Map<String, dynamic> json) {
    return TextSegment(
      text: json['text'] as String,
      role: json['role'] as String,
    );
  }
}
class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
  };
}

class ChatResponse {
  const ChatResponse({required this.reply, required this.cacheHit});

  final String reply;
  final bool cacheHit;

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      reply: json['reply'] as String,
      cacheHit: json['cache_hit'] as bool,
    );
  }
}