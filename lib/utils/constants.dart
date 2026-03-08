import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF059669);
  static const Color secondary = Color(0xFF3B82F6);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF22C55E);
  static const Color info = Color(0xFF06B6D4);
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
}

class ApiConfig {
  // Default server URL - changeable at login
  static String _serverUrl = '';

  static String get serverUrl => _serverUrl;

  static set serverUrl(String url) {
    _serverUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  // API endpoints
  static String get baseUrl => '$_serverUrl/api';

  // Auth
  static String get loginUrl => '$baseUrl/auth/app-login';
  static String get refreshUrl => '$baseUrl/auth/app-refresh';
  static String get meUrl => '$baseUrl/auth/me';
  static String get qrLoginUrl    => '$baseUrl/auth/qr-login';
  static String get qrExchangeUrl => '$baseUrl/auth/qr-exchange';
  static String get logoutUrl     => '$baseUrl/auth/logout';

  // Santri
  static String get santriUrl => '$baseUrl/santri';
  static String santriDetailUrl(dynamic id) => '$baseUrl/santri/$id';

  // Pembayaran
  static String get pembayaranUrl => '$baseUrl/pembayaran';
  static String pembayaranDetailUrl(dynamic id) => '$baseUrl/pembayaran/$id';
  static String get pembayaranStatusUrl => '$baseUrl/pembayaran/status';

  // Infak
  static String get infakUrl => '$baseUrl/infak';
  static String infakDetailUrl(dynamic id) => '$baseUrl/infak/$id';

  // Pengeluaran
  static String get pengeluaranUrl => '$baseUrl/pengeluaran';
  static String pengeluaranDetailUrl(dynamic id) => '$baseUrl/pengeluaran/$id';

  // Dana
  static String get danaUrl => '$baseUrl/dana';

  // Jurnal
  static String get jurnalUrl => '$baseUrl/jurnal';

  // Pengaturan
  static String get pengaturanUrl => '$baseUrl/pengaturan';

  // Notifikasi
  static String get notifikasiUrl => '$baseUrl/notifikasi';

  // Saran
  static String get saranUrl => '$baseUrl/saran';
  static String saranDetailUrl(dynamic id) => '$baseUrl/saran/$id';

  // Admin
  static String get adminUrl => '$baseUrl/admin';
  static String get pinUrl => '$baseUrl/admin/pin';

  // Absensi
  static String get absensiUrl => '$baseUrl/absensi';

  // Email Server (Developer only)
  static String get emailServerUrl => '$baseUrl/email-server';
  static String emailServerDetailUrl(dynamic id) => '$baseUrl/email-server/$id';
  static String get emailLogUrl => '$baseUrl/email-log';
}

// namaBulan function is in helpers.dart

const List<String> jilidOptions = [
  'Pra TK', 'Jilid 1', 'Jilid 2', 'Jilid 3', 'Jilid 4',
  'Jilid 5', 'Jilid 6', 'Gharib', 'Tajwid', 'Al-Quran'
];
