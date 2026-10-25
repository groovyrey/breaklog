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

/// The worker refused a profile save because the weekly window is still shut.
class ProfileCooldownException implements Exception {
  ProfileCooldownException(this.nextAt);

  /// When edits open again, when the worker could say so.
  final DateTime? nextAt;

  @override
  String toString() => 'Profile can only be updated once a week';
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
  /// and returns it. Each profile field is only sent when this device has a
  /// value, so a first sign in on a new device does not clear what was set
  /// elsewhere.
  Future<Map<String, dynamic>> session(
    String idToken, {
    String? alias,
    String? startedAt,
    String? why,
  }) =>
      _post(
        '/auth/session',
        {
          if (alias != null && alias.isNotEmpty) 'alias': alias,
          if (startedAt != null && startedAt.isNotEmpty) 'startedAt': startedAt,
          if (why != null && why.isNotEmpty) 'why': why,
        },
        idToken: idToken,
      );

  /// Saves the profile the user battles under. Values are sent as given so
  /// clearing a field is a real change rather than a no-op.
  Future<Map<String, dynamic>> saveProfile(
    String idToken, {
    required String alias,
    String? startedAt,
    String? why,
  }) =>
      _post(
        '/profile',
        {
          'alias': alias,
          if (startedAt != null) 'startedAt': startedAt,
          if (why != null) 'why': why,
        },
        idToken: idToken,
      );

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

  Future<Map<String, dynamic>> getMyCrews(String idToken) =>
      _get('/crews/me', idToken: idToken);

  Future<Map<String, dynamic>> getCrews(String idToken) =>
      _get('/crews', idToken: idToken);

  Future<Map<String, dynamic>> getCrew(String idToken, String crewId) =>
      _get('/crews/$crewId', idToken: idToken);

  Future<Map<String, dynamic>> createCrew(
    String idToken, {
    required String name,
    String? bio,
    String? photoUrl,
    bool publicMembers = true,
  }) =>
      _post(
        '/crews',
        {
          'name': name,
          if (bio != null) 'bio': bio,
          if (photoUrl != null) 'photo_url': photoUrl,
          'public_members': publicMembers,
        },
        idToken: idToken,
      );

  Future<Map<String, dynamic>> joinCrew(String idToken, String crewId) =>
      _post('/crews/$crewId/join', {}, idToken: idToken);

  Future<Map<String, dynamic>> leaveCrew(String idToken, String crewId) =>
      _post('/crews/$crewId/leave', {}, idToken: idToken);

  Future<Map<String, dynamic>> updateCrew(
    String idToken,
    String crewId, {
    String? name,
    String? bio,
    String? photoUrl,
    bool? publicMembers,
  }) =>
      _put(
        '/crews/$crewId',
        {
          if (name != null) 'name': name,
          if (bio != null) 'bio': bio,
          if (photoUrl != null) 'photo_url': photoUrl,
          if (publicMembers != null) 'public_members': publicMembers,
        },
        idToken: idToken,
      );

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

  Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> body, {
    String? idToken,
  }) async {
    final headers = <String, String>{'content-type': 'application/json'};
    if (idToken != null) headers['authorization'] = 'Bearer $idToken';
    final response = await _client
        .put(Uri.parse('$_baseUrl$path'),
            headers: headers, body: jsonEncode(body))
        .timeout(_timeout);
    return _decode(response);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    String? idToken,
  }) async {
    final headers = <String, String>{'content-type': 'application/json'};
    if (idToken != null) headers['authorization'] = 'Bearer $idToken';
    final response = await _client
        .get(Uri.parse('$_baseUrl$path'), headers: headers)
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
    if (response.statusCode == 429) {
      final nextAt = body?['nextAt'];
      throw ProfileCooldownException(
        nextAt is int
            ? DateTime.fromMillisecondsSinceEpoch(nextAt)
            : null,
      );
    }
    if (response.statusCode >= 400) {
      throw ApiException(
        error is String ? error : 'Request failed (${response.statusCode})',
      );
    }
    if (body == null) throw ApiException('Server sent an unexpected reply');
    return body;
  }
}
