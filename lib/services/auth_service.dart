import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  bool _isDeveloper = false;
  bool get isDeveloper => _isDeveloper;

  void login() {
    _isDeveloper = true;
    notifyListeners();
  }

  void logout() {
    _isDeveloper = false;
    notifyListeners();
  }
}
