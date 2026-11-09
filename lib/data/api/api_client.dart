import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import '../models/api_error.dart';
import '../models/auth_response.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient({
    required this.storage,
    http.Client? httpClient,
    String? baseUrl,
    this.timeout = AppConfig.requestTimeout,
  }) : _http = httpClient ?? http.Client(),
       baseUrl = _stripTrailingSlash(baseUrl ?? AppConfig.apiBaseUrl);

  final TokenStorage storage;
  final String baseUrl;
  final Duration timeout;
  final http.Client _http;

  void Function(AuthResponse session)? onSessionUpdated;

  void Function()? onSessionExpired;

  Future<bool>? _refreshing;

  static String _stripTrailingSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  Future<dynamic> get(String path, {bool auth = false}) =>
      _send('GET', path, auth: auth);

  Future<dynamic> post(String path, {Object? body, bool auth = false}) =>
      _send('POST', path, body: body, auth: auth);

  Future<dynamic> put(String path, {Object? body, bool auth = false}) =>
      _send('PUT', path, body: body, auth: auth);

  Future<dynamic> delete(String path, {bool auth = false}) =>
      _send('DELETE', path, auth: auth);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    required bool auth,
  }) async {
    if (!auth) {
      return _decode(await _execute(method, path, body: body));
    }

    final token = storage.accessToken;
    if (token == null) {
      await _expireSession();
      throw ApiException.sessionExpired();
    }

    var response = await _execute(method, path, body: body, token: token);
    if (!_isTokenExpired(response)) return _decode(response);

    final current = storage.accessToken;
    final String? retryToken;
    if (current != null && current != token) {
      retryToken = current;
    } else {
      final refreshed = await _refreshOnce();
      retryToken = refreshed ? storage.accessToken : null;
    }
    if (retryToken == null) throw ApiException.sessionExpired();

    response = await _execute(method, path, body: body, token: retryToken);
    if (_isTokenExpired(response)) {
      await _expireSession();
      throw ApiException.sessionExpired();
    }
    return _decode(response);
  }

  static bool _isTokenExpired(http.Response r) =>
      r.statusCode == 401 || (r.statusCode == 403 && r.body.trim().isEmpty);

  Future<bool> _refreshOnce() {
    return _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _refresh() async {
    final refreshToken = storage.refreshToken;
    if (refreshToken == null) {
      await _expireSession();
      return false;
    }
    final response = await _execute(
      'POST',
      '/api/auth/refresh',
      body: RefreshTokenRequest(refreshToken: refreshToken).toJson(),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      final session = AuthResponse.fromJson(json as Map<String, dynamic>);
      await storage.save(session);
      onSessionUpdated?.call(session);
      return true;
    }
    if (response.statusCode >= 500) {
      throw ApiException.fromStatus(response.statusCode, _errorBody(response));
    }
    await _expireSession();
    return false;
  }

  Future<void> _expireSession() async {
    final hadSession = storage.accessToken != null || storage.user != null;
    await storage.clear();
    if (hadSession) onSessionExpired?.call();
  }

  Future<http.Response> _execute(
    String method,
    String path, {
    Object? body,
    String? token,
  }) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    request.headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    try {
      final streamed = await _http.send(request).timeout(timeout);
      return await http.Response.fromStream(streamed).timeout(timeout);
    } on TimeoutException {
      throw ApiException.network(
        'The server did not respond in time. Check that the backend is running at $baseUrl.',
      );
    } on http.ClientException catch (e) {
      throw ApiException.network(
        'Could not reach the server at $baseUrl (${e.message}).',
      );
    } on ApiException {
      rethrow;
    } on Exception catch (e) {
      throw ApiException.network(
        'Could not reach the server at $baseUrl ($e).',
      );
    }
  }

  dynamic _decode(http.Response response) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      final text = utf8.decode(response.bodyBytes);
      if (text.trim().isEmpty) return null;
      try {
        return jsonDecode(text);
      } on FormatException {
        throw ApiException(
          kind: ApiErrorKind.unknown,
          message: 'The server returned an unexpected response.',
          statusCode: status,
        );
      }
    }
    throw ApiException.fromStatus(status, _errorBody(response));
  }

  static ApiErrorResponse? _errorBody(http.Response response) {
    final text = utf8.decode(response.bodyBytes, allowMalformed: true);
    if (text.trim().isEmpty) return null;
    try {
      final json = jsonDecode(text);
      return json is Map<String, dynamic>
          ? ApiErrorResponse.fromJson(json)
          : null;
    } on FormatException {
      return null;
    }
  }
}
