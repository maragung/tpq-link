import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../providers/auth_provider.dart';

class DashboardProvider extends ChangeNotifier {
  AuthProvider? _auth;
  Map<String, dynamic>? _danaData;
  bool _loading = false;
  String? _error;

  Map<String, dynamic> _normalizeDanaData(Map<String, dynamic> raw) {
    return {
      ...raw,
      // Backward-compatible aliases used by existing Flutter screens.
      'saldo_kas': raw['saldo_kas'] ?? raw['saldo_akhir'] ?? 0,
      'total_pemasukan': raw['total_pemasukan'] ?? raw['total_pemasukan_tahun'] ?? 0,
      'total_pengeluaran': raw['total_pengeluaran'] ?? raw['total_pengeluaran_tahun'] ?? 0,
      'total_infak': raw['total_infak'] ?? raw['total_infak_tahun'] ?? 0,
    };
  }

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
      final data = (result['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      _danaData = _normalizeDanaData(data);
    } else {
      _error = result['pesan'];
    }

    _loading = false;
    notifyListeners();
  }
}
