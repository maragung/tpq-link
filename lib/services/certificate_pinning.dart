import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Certificate pinning for the TPQ app.
///
/// How to find your server's SHA-256 fingerprint:
///   openssl s_client -connect your-domain.com:443 </dev/null 2>/dev/null \
///     | openssl x509 -fingerprint -sha256 -noout \
///     | sed 's/://g' | awk -F= '{print tolower($2)}'
///
/// Add the result to [_trustedFingerprints] below, WITHOUT colons, lowercase.
///
/// Note: if you use a load balancer or CDN (Cloudflare, Nginx with auto-renew
/// certs), pin the CA fingerprint instead of the leaf cert, or disable pinning
/// and rely solely on TLS hostname verification (HTTPS enforcement).

class CertificatePinning {
  /// SHA-256 fingerprints of trusted server certificates (lowercase, no colons).
  /// Add your server's fingerprint here.
  /// Leave empty to disable pinning and rely on system CA store only.
  static const List<String> _trustedFingerprints = [
    // TODO: Add your server certificate SHA-256 fingerprint here.
    // Example: 'a1b2c3d4e5f6...64hexchars'
  ];

  /// Returns true if certificate pinning is actively enforced.
  static bool get isPinningEnabled => _trustedFingerprints.isNotEmpty;

  /// Creates an [http.Client] that enforces certificate pinning when
  /// [_trustedFingerprints] is non-empty.
  ///
  /// In debug mode, pinning is skipped to allow local development with
  /// self-signed certificates.  In release mode the pin is always checked
  /// when fingerprints are configured.
  static http.Client createClient() {
    // Skip pinning in debug mode to ease local development
    if (kDebugMode || !isPinningEnabled) {
      return http.Client();
    }

    final httpClient = HttpClient();

    httpClient.badCertificateCallback = (cert, host, port) {
      // Reject immediately for non-443 ports unless explicitly testing
      if (port != 443) return false;

      // SHA-256 fingerprint of the presented certificate (hex, lowercase)
      final fingerprint = cert.sha256
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .toLowerCase();

      if (_trustedFingerprints.contains(fingerprint)) {
        return true; // cert matches — allow connection
      }

      debugPrint(
        '[CertificatePinning] REJECTED cert for $host:$port — '
        'fingerprint=$fingerprint not in trusted list',
      );
      return false; // cert does not match — reject
    };

    return IOClient(httpClient);
  }
}
