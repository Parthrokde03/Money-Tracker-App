import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LockService {
  static final LockService _instance = LockService._();
  factory LockService() => _instance;
  LockService._();

  static const _enabledKey = 'app_lock_enabled';
  final LocalAuthentication _auth = LocalAuthentication();

  bool _enabled = false;
  bool get isEnabled => _enabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  /// Check if device has any biometric or device credential set up.
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Authenticate using device PIN/pattern/password/biometric.
  /// Returns true if authenticated, false otherwise.
  Future<bool> authenticate() async {
    if (!_enabled) return true;
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock Money Tracker',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // allows PIN/pattern/password fallback
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
