import 'dart:convert';
import 'dart:io';

import 'api_exception.dart';

class ApiClient {
  ApiClient({required this.baseUrl});

  final String baseUrl;
  final HttpClient _httpClient = HttpClient();

  Future<List<dynamic>> getJsonList(
    String path, {
    Map<String, String>? query,
    String? token,
  }) async {
    final request = await _httpClient.getUrl(_uri(path, query));
    _applyHeaders(request, token);
    final response = await request.close();
    return _decodeListResponse(response);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    String? token,
  }) async {
    final request = await _httpClient.getUrl(_uri(path, query));
    _applyHeaders(request, token);
    final response = await request.close();
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final request = await _httpClient.postUrl(_uri(path));
    _applyHeaders(request, token);
    request.write(jsonEncode(body));
    final response = await request.close();
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final request = await _httpClient.patchUrl(_uri(path));
    _applyHeaders(request, token);
    request.write(jsonEncode(body));
    final response = await request.close();
    return _decodeResponse(response);
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    final cleanedQuery = query?.withoutBlankValues();
    if (cleanedQuery == null || cleanedQuery.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: cleanedQuery);
  }

  void _applyHeaders(HttpClientRequest request, String? token) {
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
  }

  Future<Map<String, dynamic>> _decodeResponse(
    HttpClientResponse response,
  ) async {
    final decoded = await _decodeBody(response);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw ApiException(response.statusCode, 'Réponse serveur invalide.');
  }

  Future<List<dynamic>> _decodeListResponse(HttpClientResponse response) async {
    final decoded = await _decodeBody(response);
    if (decoded is List<dynamic>) {
      return decoded;
    }
    throw ApiException(response.statusCode, 'Réponse serveur invalide.');
  }

  Future<Object?> _decodeBody(HttpClientResponse response) async {
    final body = await response.transform(utf8.decoder).join();
    final decoded = body.isBlank ? <String, dynamic>{} : jsonDecode(body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, _errorMessage(decoded));
    }
    return decoded;
  }

  String _errorMessage(Object? decoded) {
    if (decoded is Map<String, dynamic>) {
      return decoded['message'] as String? ?? 'Erreur serveur.';
    }
    return 'Erreur serveur.';
  }
}

extension on String {
  bool get isBlank => trim().isEmpty;
}

extension on Map<String, String> {
  Map<String, String> withoutBlankValues() {
    return Map.fromEntries(
      entries.where((entry) => entry.value.trim().isNotEmpty),
    );
  }
}
