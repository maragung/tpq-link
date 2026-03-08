import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/biometric_service.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _loading = false;
  String? _error;
  bool _initialized = false;
  StreamSubscription<void>? _unauthorizedSub;

  User? get user => _user;
  String? get token => _token;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _user != null;
  bool get initialized => _initialized;

  static const _storage = FlutterSecureStorage();

  AuthProvider() {
    _init();
    // Auto-logout and notify when server returns 401
    _unauthorizedSub = ApiService.onUnauthorized.listen((_) async {
      if (_token != null) {
        await _clearAuth();
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _unauthorizedSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    _loading = true;
    notifyListeners();

    try {
      // Restore server URL
      final savedUrl = await ApiService.getServerUrl();
      if (savedUrl != null && savedUrl.isNotEmpty) {
        ApiConfig.serverUrl = savedUrl;
      }

      // Restore token
      final savedToken = await ApiService.getToken();
      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;

        // Restore user data
        final userData = await _storage.read(key: 'user_data');
        if (userData != null) {
          _user = User.fromJson(jsonDecode(userData));
        }

        // Verify token is still valid by refreshing
        await refreshToken();
      }
    } catch (_) {
      _token = null;
      _user = null;
    }

    _loading = false;
    _initialized = true;
    notifyListeners();
  }

  Future<bool> login(String serverUrl, String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      ApiConfig.serverUrl = serverUrl;
      await ApiService.setServerUrl(serverUrl);

      final result = await ApiService.post(
        ApiConfig.loginUrl,
        body: {'username': username, 'password': password},
      );

      if (result['success'] == true) {
        final data = result['data'];
        _token = data['token'];
        _user = User.fromJson(data['user']);

        await ApiService.setToken(_token!);
        await _storage.write(key: 'user_data', value: jsonEncode(_user!.toJson()));

        _loading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['pesan'] ?? 'Login gagal';
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Kesalahan koneksi: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithToken(String token, String serverUrl) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (serverUrl.isNotEmpty) {
        ApiConfig.serverUrl = serverUrl;
        await ApiService.setServerUrl(serverUrl);
      }

      _token = token;
      await ApiService.setToken(token);

      // Fetch user data
      final result = await ApiService.get(ApiConfig.meUrl);
      if (result['success'] == true) {
        final data = result['data'] ?? result['user'];
        _user = User.fromJson(data);
        await _storage.write(key: 'user_data', value: jsonEncode(_user!.toJson()));
        _loading = false;
        notifyListeners();
        return true;
      } else {
        _token = null;
        await ApiService.clearToken();
        _error = result['pesan'] ?? 'Token tidak valid';
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _token = null;
      await ApiService.clearToken();
      _error = 'Kesalahan koneksi';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshToken() async {
    try {
      final result = await ApiService.post(ApiConfig.refreshUrl);
      if (result['success'] == true) {
        final data = result['data'];
        _token = data['token'];
        await ApiService.setToken(_token!);
        if (data['user'] != null) {
          _user = User.fromJson(data['user']);
          await _storage.write(key: 'user_data', value: jsonEncode(_user!.toJson()));
        }
      } else {
        // Token invalid, logout
        await _clearAuth();
      }
    } catch (_) {
      // Keep existing auth on network errors
    }
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await ApiService.post(ApiConfig.logoutUrl);
    } catch (_) {}
    await BiometricService.disable();
    await _clearAuth();
    notifyListeners();
  }

  /// Login using device biometrics. The stored login token is used to silently
  /// re-authenticate; if the session has expired the user will be prompted to
  /// log in normally.
  Future<bool> loginWithBiometric() async {
    _loading = true;
    _error = null;
    notifyListeners();

    final authenticated = await BiometricService.authenticate(
      reason: 'Masuk ke aplikasi TPQ',
    );
    if (!authenticated) {
      _error = 'Autentikasi biometrik dibatalkan';
      _loading = false;
      notifyListeners();
      return false;
    }

    // Try reusing the existing saved token via refresh
    try {
      final saved = await ApiService.getToken();
      if (saved != null && saved.isNotEmpty) {
        _token = saved;
        await ApiService.setToken(saved);
        await refreshToken();
        if (isAuthenticated) {
          _loading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (_) {}

    _error = 'Sesi habis, silakan login ulang dengan username & password';
    _loading = false;
    notifyListeners();
    return false;
  }

  /// After a successful PIN action, offer to save that PIN for biometric use.
  Future<void> savePin(String pin) => BiometricService.savePin(pin);

  Future<void> _clearAuth() async {
    _token = null;
    _user = null;
    await ApiService.clearToken();
    await _storage.delete(key: 'user_data');
  }
}
