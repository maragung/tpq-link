import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static String? _token;

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

  static Future<Map<String, dynamic>> get(String url,
      {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse(url);
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'pesan': 'Kesalahan koneksi: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> post(String url,
      {Map<String, dynamic>? body}) async {
    try {
      final response = await http
          .post(Uri.parse(url), headers: _headers, body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'pesan': 'Kesalahan koneksi: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> put(String url,
      {Map<String, dynamic>? body}) async {
    try {
      final response = await http
          .put(Uri.parse(url), headers: _headers, body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'pesan': 'Kesalahan koneksi: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> delete(String url,
      {Map<String, dynamic>? body}) async {
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
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } catch (_) {
      return {
        'success': false,
        'pesan': 'Respon server tidak valid (${response.statusCode})',
      };
    }
  }
}
