import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';
import 'certificate_pinning.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static String? _token;

  /// Shared HTTP client — uses certificate pinning in release mode when
  /// fingerprints are configured in CertificatePinning.
  static http.Client _client = CertificatePinning.createClient();

  /// Recreate the HTTP client (e.g. after changing server URL).
  static void resetClient() {
    _client = CertificatePinning.createClient();
  }

  /// Fires whenever a server returns HTTP 401 (token expired/invalid).
  /// AuthProvider listens to this and triggers auto-logout + redirect to login.
  static final _unauthorizedController =
      StreamController<void>.broadcast();
  static Stream<void> get onUnauthorized => _unauthorizedController.stream;

  static Future<void> setToken(String token) async {
    _token = token;
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getToken() async {
    _token ??= await _storage.read(key: 'auth_token');
    return _token;
  }

  static Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: 'auth_token');
  }

  static Future<void> setServerUrl(String url) async {
    ApiConfig.serverUrl = url;
    await _storage.write(key: 'server_url', value: url);
  }

  static Future<String?> getServerUrl() async {
    final url = await _storage.read(key: 'server_url');
    if (url != null) ApiConfig.serverUrl = url;
    return url;
  }

  static Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  /// Returns true when the device has any network connectivity.
  static Future<bool> _isConnected() async {
    final results = await Connectivity().checkConnectivity();
    return results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);
  }

  static const _msgNoInternet = 'Tidak ada koneksi internet. Periksa jaringan Anda dan coba lagi.';

  static Future<Map<String, dynamic>> get(String url,
      {Map<String, String>? queryParams}) async {
    if (!await _isConnected()) {
      return {'success': false, 'pesan': _msgNoInternet};
    }
    try {
      var uri = Uri.parse(url);
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'pesan': 'Kesalahan koneksi: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> post(String url,
      {Map<String, dynamic>? body}) async {
    if (!await _isConnected()) {
      return {'success': false, 'pesan': _msgNoInternet};
    }
    try {
      final response = await _client
          .post(Uri.parse(url), headers: _headers, body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'pesan': 'Kesalahan koneksi: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> put(String url,
      {Map<String, dynamic>? body}) async {
    if (!await _isConnected()) {
      return {'success': false, 'pesan': _msgNoInternet};
    }
    try {
      final response = await _client
          .put(Uri.parse(url), headers: _headers, body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'pesan': 'Kesalahan koneksi: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> delete(String url,
      {Map<String, dynamic>? body}) async {
    if (!await _isConnected()) {
      return {'success': false, 'pesan': _msgNoInternet};
    }
    try {
      final request = http.Request('DELETE', Uri.parse(url));
      request.headers.addAll(_headers);
      if (body != null) request.body = jsonEncode(body);
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'pesan': 'Kesalahan koneksi: ${e.toString()}'};
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    // 401 → token expired or invalid → notify listeners to force re-login
    if (response.statusCode == 401) {
      _unauthorizedController.add(null);
      return {
        'success': false,
        'statusCode': 401,
        'pesan': 'Sesi habis, silakan login ulang',
      };
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // Always include statusCode so callers (e.g. background queue) can
      // distinguish permanent (4xx) from transient (5xx / network) failures.
      return {'statusCode': response.statusCode, ...data};
    } catch (_) {
      return {
        'success': false,
        'statusCode': response.statusCode,
        'pesan': 'Respon server tidak valid (${response.statusCode})',
      };
    }
  }
}
