import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles biometric authentication and encrypted PIN storage.
///
/// Flow:
/// 1. After user successfully logs in with PIN, call [savePin] to encrypt and
///    store the PIN in Android Keystore-backed secure storage.
/// 2. Next time user wants to act, call [authenticateAndGetPin]: triggers the
///    biometric prompt; on success returns the stored PIN, otherwise null.
/// 3. The returned PIN is passed to the API exactly as the manual PIN would be.
class BiometricService {
  static const _storage = FlutterSecureStorage();
  static final _auth = LocalAuthentication();

  static const _pinKey = 'biometric_pin';
  static const _enabledKey = 'biometric_enabled';

  // ── availability ──────────────────────────────────────────────────────────

  /// Returns true when the device hardware supports and has enrolled biometrics.
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isSupported) return false;
      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Returns true when the user has previously enabled biometric login.
  static Future<bool> isEnabled() async {
    final flag = await _storage.read(key: _enabledKey);
    return flag == 'true';
  }

  // ── setup ─────────────────────────────────────────────────────────────────

  /// Saves [pin] in Keystore-backed secure storage and marks biometric enabled.
  /// Call this right after a successful manual PIN verification so the PIN is
  /// confirmed valid before being stored.
  static Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
    await _storage.write(key: _enabledKey, value: 'true');
  }

  /// Removes stored PIN and disables biometric login.
  static Future<void> disable() async {
    await _storage.delete(key: _pinKey);
    await _storage.write(key: _enabledKey, value: 'false');
  }

  // ── authenticate ──────────────────────────────────────────────────────────

  /// Shows the biometric prompt. On success, decrypts and returns the stored
  /// PIN. Returns null if authentication fails or is cancelled.
  static Future<String?> authenticateAndGetPin({
    String reason = 'Verifikasi identitas untuk melanjutkan',
  }) async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!authenticated) return null;
      return await _storage.read(key: _pinKey);
    } catch (_) {
      return null;
    }
  }

  /// Authenticate without retrieving a PIN (e.g., for app login screen).
  static Future<bool> authenticate({
    String reason = 'Masuk ke aplikasi TPQ',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // allow PIN fallback on login screen
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
