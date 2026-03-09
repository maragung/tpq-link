import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../models/absensi.dart';

class AbsensiProvider with ChangeNotifier {
  List<Absensi> _absensiList = [];
  Map<String, dynamic>? _ringkasan;
  bool _loading = false;
  String? _error;

  List<Absensi> get absensiList => _absensiList;
  Map<String, dynamic>? get ringkasan => _ringkasan;
  bool get loading => _loading;
  String? get error => _error;

  /// Ambil data absensi per tanggal
  Future<void> fetchAbsensi({required String tanggal}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.get('${ApiConfig.absensiUrl}?tanggal=$tanggal');
      if (res['success'] == true) {
        final list = (res['data'] as List?) ?? [];
        _absensiList = list.map((e) => Absensi.fromJson(e)).toList();
        _ringkasan = res['ringkasan'] as Map<String, dynamic>?;
      } else {
        _error = res['pesan'] ?? 'Gagal memuat absensi';
      }
    } catch (e) {
      _error = 'Gagal terhubung ke server';
    }

    _loading = false;
    notifyListeners();
  }

  /// Simpan / batch update absensi
  Future<bool> simpanAbsensi({
    required String tanggal,
    required List<Map<String, dynamic>> data,
    required String pin,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.post(ApiConfig.absensiUrl, body: {
        'tanggal': tanggal,
        'data': data,
        'pin': pin,
      });

      _loading = false;
      if (res['success'] == true) {
        await fetchAbsensi(tanggal: tanggal);
        return true;
      } else {
        _error = res['pesan'] ?? 'Gagal menyimpan absensi';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _loading = false;
      _error = 'Gagal terhubung ke server';
      notifyListeners();
      return false;
    }
  }
}
