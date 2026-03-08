import 'package:flutter/material.dart';
import '../models/pembayaran.dart';
import '../services/api_service.dart';
import '../services/background_service.dart';
import '../utils/constants.dart';
import '../providers/auth_provider.dart';

class PembayaranProvider extends ChangeNotifier {
  AuthProvider? _auth;
  List<Pembayaran> _pembayaranList = [];
  bool _loading = false;
  String? _error;
  int _selectedYear = DateTime.now().year;

  List<Pembayaran> get pembayaranList => _pembayaranList;
  bool get loading => _loading;
  String? get error => _error;
  int get selectedYear => _selectedYear;

  void updateAuth(AuthProvider auth) {
    _auth = auth;
    if (auth.isAuthenticated && _pembayaranList.isEmpty) {
      fetchPembayaran();
    }
  }

  set selectedYear(int year) {
    _selectedYear = year;
    fetchPembayaran();
  }

  Future<void> fetchPembayaran() async {
    if (_auth?.token == null) return;
    _loading = true;
    _error = null;
    notifyListeners();

    final result = await ApiService.get(
      ApiConfig.pembayaranUrl,
      queryParams: {'tahun': _selectedYear.toString(), 'limit': '100'},
    );

    if (result['success'] == true) {
      final data = result['data'] as List? ?? [];
      _pembayaranList = data.map((e) => Pembayaran.fromJson(e)).toList();
    } else {
      _error = result['pesan'];
    }

    _loading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> bayarSPP(Map<String, dynamic> data) async {
    final result = await BackgroundService.enqueueOrExecute(
      'POST', ApiConfig.pembayaranUrl, body: data,
    );
    if (result['success'] == true) fetchPembayaran();
    return result;
  }

  Future<Map<String, dynamic>> deletePembayaran(int id, String pin) async {
    final result = await BackgroundService.enqueueOrExecute(
      'DELETE', ApiConfig.pembayaranDetailUrl(id), body: {'pin': pin},
    );
    if (result['success'] == true) fetchPembayaran();
    return result;
  }
}
