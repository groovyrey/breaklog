import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';

/// A Drive call that failed, phrased with the API message when there is one.
class DriveException implements Exception {
  DriveException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Keeps attachment files in a `BreakLog` folder in the user's own Drive.
///
/// Talks to the REST API directly with an access token from google_sign_in, so
/// media never passes through the worker and stays out of the database quota.
class DriveBackup {
  DriveBackup({http.Client? client, String? apiUrl, String? uploadUrl})
      : _client = client ?? http.Client(),
        _apiUrl = apiUrl ?? AppConfig.driveApiUrl,
        _uploadUrl = uploadUrl ?? AppConfig.driveUploadUrl;

  final http.Client _client;
  final String _apiUrl;
  final String _uploadUrl;

  String? _folderId;

  /// Id of the backup folder, creating it on first use.
  Future<String> ensureFolder(String accessToken) async {
    final cached = _folderId;
    if (cached != null) return cached;
    final id = await findFolder(accessToken) ?? await createFolder(accessToken);
    _folderId = id;
    return id;
  }

  Future<String?> findFolder(String accessToken) async {
    final uri = Uri.parse('$_apiUrl/files').replace(queryParameters: {
      'q': "name = '${AppConfig.driveFolderName}'"
          " and mimeType = 'application/vnd.google-apps.folder'"
          ' and trashed = false',
      'fields': 'files(id)',
      'spaces': 'drive',
      'pageSize': '1',
    });
    final body =
        await _decode(await _client.get(uri, headers: _bearer(accessToken)));
    final files = body['files'];
    if (files is! List || files.isEmpty) return null;
    final first = files.first;
    return first is Map<String, dynamic> ? first['id'] as String? : null;
  }

  Future<String> createFolder(String accessToken) async {
    final response = await _client.post(
      Uri.parse('$_apiUrl/files?fields=id'),
      headers: {..._bearer(accessToken), 'content-type': 'application/json'},
      body: jsonEncode({
        'name': AppConfig.driveFolderName,
        'mimeType': 'application/vnd.google-apps.folder',
      }),
    );
    final id = (await _decode(response))['id'];
    if (id is! String) throw DriveException('Drive did not return a folder id');
    return id;
  }

  /// Uploads [file] into [parentId] and returns the new Drive file id.
  ///
  /// A resumable session with a known length lets a single PUT stream the file
  /// from disk, which keeps clips of a few hundred megabytes off the heap.
  Future<String> upload({
    required String accessToken,
    required String parentId,
    required File file,
    required String name,
    required String mimeType,
  }) async {
    final uri = Uri.parse('$_uploadUrl/files')
        .replace(queryParameters: {'uploadType': 'resumable', 'fields': 'id'});
    final session = await _client.post(
      uri,
      headers: {
        ..._bearer(accessToken),
        'content-type': 'application/json; charset=utf-8',
        'x-upload-content-type': mimeType,
      },
      body: jsonEncode({'name': name, 'parents': [parentId]}),
    );
    if (session.statusCode >= 300) throw DriveException(_message(session));
    final location = session.headers['location'] ?? session.headers['Location'];
    if (location == null) throw DriveException('Drive returned no upload url');

    final request = http.StreamedRequest('PUT', Uri.parse(location));
    request.contentLength = await file.length();
    request.headers['content-type'] = mimeType;
    final sent = _client.send(request);
    await request.sink.addStream(file.openRead());
    await request.sink.close();

    final id = (await _decode(await sent))['id'];
    if (id is! String) throw DriveException('Drive did not return a file id');
    return id;
  }

  Map<String, String> _bearer(String accessToken) =>
      {'authorization': 'Bearer $accessToken'};

  Future<Map<String, dynamic>> _decode(http.Response response) async {
    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } on FormatException {
      body = null;
    }
    if (response.statusCode >= 300) {
      throw DriveException(_message(response, body));
    }
    if (body == null) throw DriveException('Drive sent an unexpected reply');
    return body;
  }

  String _message(http.Response response, [Map<String, dynamic>? body]) {
    final error = (body ?? const <String, dynamic>{})['error'];
    if (error is Map<String, dynamic>) {
      final message = error['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return 'Drive returned ${response.statusCode}';
  }
}
