import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../providers/auth_provider.dart';

class DashboardProvider extends ChangeNotifier {
  AuthProvider? _auth;
  Map<String, dynamic>? _danaData;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? get danaData => _danaData;
  bool get loading => _loading;
  String? get error => _error;

  void updateAuth(AuthProvider auth) {
    _auth = auth;
    if (auth.isAuthenticated && _danaData == null) {
      fetchDana();
    }
  }

  Future<void> fetchDana() async {
    if (_auth?.token == null) return;
    _loading = true;
    _error = null;
    notifyListeners();

    final result = await ApiService.get(ApiConfig.danaUrl);
    if (result['success'] == true) {
      _danaData = result['data'];
    } else {
      _error = result['pesan'];
    }

    _loading = false;
    notifyListeners();
  }
}
