import 'dart:async';
import 'dart:convert';
import 'dart:math';
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
    final now = DateTime.now();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'x-client-tz-offset': now.timeZoneOffset.inMinutes.toString(),
      'x-client-timezone': now.timeZoneName,
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  /// Generates a unique idempotency key for POST requests.
  static String _generateIdempotencyKey() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'flutter-${DateTime.now().millisecondsSinceEpoch}-$hex';
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
      final headers = {
        ..._headers,
        'x-idempotency-key': _generateIdempotencyKey(),
      };
      final response = await _client
          .post(Uri.parse(url), headers: headers, body: jsonEncode(body ?? {}))
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
    final int code = response.statusCode;

    // 401 → token expired or invalid → notify listeners to force re-login
    if (code == 401) {
      _unauthorizedController.add(null);
      return {
        'success': false,
        'statusCode': 401,
        'pesan': 'Sesi habis atau tidak valid, silakan login ulang',
      };
    }

    if (code == 403) {
      return {
        'success': false,
        'statusCode': 403,
        'pesan': 'Anda tidak memiliki akses untuk melakukan tindakan ini',
      };
    }

    if (code == 404) {
      return {
        'success': false,
        'statusCode': 404,
        'pesan': 'Data atau layanan tidak ditemukan (404)',
      };
    }

    if (code >= 500) {
      return {
        'success': false,
        'statusCode': code,
        'pesan': 'Terjadi kesalahan pada server ($code). Silakan coba lagi nanti.',
      };
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // If the API returns success: false but no message, provide a default
      if (data['success'] == false && data['pesan'] == null && data['message'] == null) {
        data['pesan'] = 'Terjadi kesalahan internal (Status: $code)';
      }
      return {'statusCode': code, ...data};
    } catch (_) {
      return {
        'success': false,
        'statusCode': code,
        'pesan': 'Respon server tidak dapat diproses ($code)',
      };
    }
  }
}
