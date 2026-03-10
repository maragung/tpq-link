import 'package:flutter/material.dart';
// santri model used via dynamic from API response
import '../models/pembayaran.dart';
import '../services/api_service.dart';
import '../services/background_service.dart';
import '../utils/constants.dart';
import '../providers/auth_provider.dart';

class SantriProvider extends ChangeNotifier {
  AuthProvider? _auth;
  List<StatusPembayaran> _santriList = [];
  List<Map<String, dynamic>> _alumniList = [];
  bool _loading = false;
  bool _alumniLoading = false;
  String? _error;
  int _selectedYear = DateTime.now().year;

  List<StatusPembayaran> get santriList => _santriList;
  List<Map<String, dynamic>> get alumniList => _alumniList;
  bool get loading => _loading;
  bool get alumniLoading => _alumniLoading;
  String? get error => _error;
  int get selectedYear => _selectedYear;

  void updateAuth(AuthProvider auth) {
    _auth = auth;
    if (auth.isAuthenticated && _santriList.isEmpty) {
      fetchSantriStatus();
      fetchAlumni();
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
      queryParams: {
        'tahun': _selectedYear.toString(),
        'include_nonaktif': 'true',
      },
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
    final result = await BackgroundService.enqueueOrExecute(
      'POST', ApiConfig.santriUrl, body: data,
    );
    if (result['success'] == true) fetchSantriStatus();
    return result;
  }

  Future<Map<String, dynamic>> updateSantri(int id, Map<String, dynamic> data) async {
    final result = await BackgroundService.enqueueOrExecute(
      'PUT', ApiConfig.santriDetailUrl(id), body: data,
    );
    if (result['success'] == true) fetchSantriStatus();
    return result;
  }

  Future<Map<String, dynamic>> nonaktifkanSantri(int id, String pin) async {
    final result = await BackgroundService.enqueueOrExecute(
      'PUT', ApiConfig.santriDetailUrl(id),
      body: {'status_aktif': false, 'pin': pin},
    );
    if (result['success'] == true) fetchSantriStatus();
    return result;
  }

  Future<Map<String, dynamic>> deleteSantri(int id, String pin) async {
    final result = await BackgroundService.enqueueOrExecute(
      'DELETE', ApiConfig.santriDetailUrl(id), body: {'pin': pin},
    );
    if (result['success'] == true) {
      fetchSantriStatus();
      fetchAlumni();
    }
    return result;
  }

  Future<Map<String, dynamic>> luluskanSantri(int id, String pin) async {
    final result = await BackgroundService.enqueueOrExecute(
      'PUT', ApiConfig.santriDetailUrl(id),
      body: {'status_lulus': true, 'pin': pin},
    );
    if (result['success'] == true) {
      fetchSantriStatus();
      fetchAlumni();
    }
    return result;
  }

  Future<Map<String, dynamic>> aktifkanSantri(int id, String pin) async {
    final result = await BackgroundService.enqueueOrExecute(
      'PUT', ApiConfig.santriDetailUrl(id),
      body: {'status_aktif': true, 'pin': pin},
    );
    if (result['success'] == true) fetchSantriStatus();
    return result;
  }

  Future<void> fetchAlumni() async {
    if (_auth?.token == null) return;
    _alumniLoading = true;
    notifyListeners();

    final result = await ApiService.get(
      ApiConfig.santriUrl,
      queryParams: {'status': 'lulus', 'limit': '500'},
    );
    if (result['success'] == true) {
      final data = result['data'] as List? ?? [];
      _alumniList = data.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    _alumniLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> batalLulusSantri(int id, String pin) async {
    final result = await BackgroundService.enqueueOrExecute(
      'PUT', ApiConfig.santriDetailUrl(id),
      body: {'status_lulus': false, 'status_aktif': true, 'pin': pin},
    );
    if (result['success'] == true) {
      fetchSantriStatus();
      fetchAlumni();
    }
    return result;
  }

  Future<Map<String, dynamic>> getSantriDetail(int id) async {
    return await ApiService.get(ApiConfig.santriDetailUrl(id));
  }
}
