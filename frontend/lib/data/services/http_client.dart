import 'dart:convert';

import 'package:http/http.dart' as http;

class HttpClientService {
  HttpClientService({
    required this.baseUrl,
    required String? Function() tokenProvider,
  }) : _tokenProvider = tokenProvider;

  final String baseUrl;
  final String? Function() _tokenProvider;
  final http.Client _client = http.Client();

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _client.get(
      _uri(path, queryParameters: queryParameters),
      headers: _headers(),
    );
    return _decode(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await _client.post(
      _uri(path),
      headers: _headers(),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
    return _decode(response);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final response = await _client.patch(
      _uri(path),
      headers: _headers(),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
    return _decode(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await _client.delete(
      _uri(path),
      headers: _headers(),
    );
    return _decode(response);
  }

  Uri _uri(String path, {Map<String, dynamic>? queryParameters}) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$normalizedBase$path');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    final normalizedQuery = <String, String>{};
    for (final entry in queryParameters.entries) {
      final value = entry.value?.toString().trim();
      if (value == null || value.isEmpty) {
        continue;
      }
      normalizedQuery[entry.key] = value;
    }
    if (normalizedQuery.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: normalizedQuery);
  }

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final token = _tokenProvider();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Ошибка запроса (${response.statusCode}): ${response.body}',
      );
    }

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body);
  }

  void dispose() {
    _client.close();
  }
}
