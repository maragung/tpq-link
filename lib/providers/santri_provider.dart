import 'package:flutter/material.dart';
// santri model used via dynamic from API response
import '../models/pembayaran.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../providers/auth_provider.dart';

class SantriProvider extends ChangeNotifier {
  AuthProvider? _auth;
  List<StatusPembayaran> _santriList = [];
  bool _loading = false;
  String? _error;
  int _selectedYear = DateTime.now().year;

  List<StatusPembayaran> get santriList => _santriList;
  bool get loading => _loading;
  String? get error => _error;
  int get selectedYear => _selectedYear;

  void updateAuth(AuthProvider auth) {
    _auth = auth;
    if (auth.isAuthenticated && _santriList.isEmpty) {
      fetchSantriStatus();
    }
  }

  set selectedYear(int year) {
    _selectedYear = year;
    fetchSantriStatus();
  }

  Future<void> fetchSantriStatus() async {
    if (_auth?.token == null) return;
    _loading = true;
    _error = null;
    notifyListeners();

    final result = await ApiService.get(
      ApiConfig.pembayaranStatusUrl,
      queryParams: {'tahun': _selectedYear.toString()},
    );

    if (result['success'] == true) {
      final data = result['data'] as List? ?? [];
      _santriList = data.map((e) => StatusPembayaran.fromJson(e)).toList();
    } else {
      _error = result['pesan'];
    }

    _loading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> addSantri(Map<String, dynamic> data) async {
    final result = await ApiService.post(ApiConfig.santriUrl, body: data);
    if (result['success'] == true) fetchSantriStatus();
    return result;
  }

  Future<Map<String, dynamic>> updateSantri(int id, Map<String, dynamic> data) async {
    final result = await ApiService.put(ApiConfig.santriDetailUrl(id), body: data);
    if (result['success'] == true) fetchSantriStatus();
    return result;
  }

  Future<Map<String, dynamic>> deleteSantri(int id, String pin) async {
    final result = await ApiService.delete(
      ApiConfig.santriDetailUrl(id),
      body: {'pin': pin},
    );
    if (result['success'] == true) fetchSantriStatus();
    return result;
  }

  Future<Map<String, dynamic>> getSantriDetail(int id) async {
    return await ApiService.get(ApiConfig.santriDetailUrl(id));
  }
}
