import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

/// A server-side failure, already phrased for the user.
class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Client for the breaklog-api worker. Requests carry the Firebase ID token;
/// the database token stays on the worker.
class BreaklogApi {
  BreaklogApi({http.Client? client, String baseUrl = AppConfig.apiUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;

  static const _timeout = Duration(seconds: 30);

  /// Sign in handshake. The worker verifies the token, stores the account row,
  /// and returns it. [alias] is only sent when this device has one, so a first
  /// sign in on a new device does not clear the name set elsewhere.
  Future<Map<String, dynamic>> session(String idToken, {String? alias}) => _post(
        '/auth/session',
        {if (alias != null && alias.isNotEmpty) 'alias': alias},
        idToken: idToken,
      );

  /// Saves the name the user battles under.
  Future<Map<String, dynamic>> saveProfile(String idToken, String alias) =>
      _post('/profile', {'alias': alias}, idToken: idToken);

  /// True when the accounts backend answers, used to flag offline mode.
  Future<bool> ping() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 6));
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    String? idToken,
  }) async {
    final headers = <String, String>{'content-type': 'application/json'};
    if (idToken != null) headers['authorization'] = 'Bearer $idToken';
    final response = await _client
        .post(Uri.parse('$_baseUrl$path'),
            headers: headers, body: jsonEncode(body))
        .timeout(_timeout);
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } on FormatException {
      body = null;
    }
    final error = body?['error'];
    if (response.statusCode >= 400) {
      throw ApiException(
        error is String ? error : 'Request failed (${response.statusCode})',
      );
    }
    if (body == null) throw ApiException('Server sent an unexpected reply');
    return body;
  }
}
