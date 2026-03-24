import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._();
  factory ThemeService() => _instance;
  ThemeService._();

  static const _key = 'is_dark_mode';
  bool _isDark = true;

  bool get isDark => _isDark;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_key) ?? true;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDark);
    notifyListeners();
  }
}

/// Centralized color tokens that adapt to light/dark mode.
class AppColors {
  static bool get _dark => ThemeService().isDark;

  static Color get bg => _dark ? const Color(0xFF0F0F1A) : const Color(0xFFF2F3F7);
  static Color get surface => _dark ? const Color(0xFF1A1A2E) : Colors.white;
  static Color get accent => const Color(0xFF6C63FF);
  static Color get green => const Color(0xFF2ECC71);
  static Color get red => const Color(0xFFFF6B6B);
  static Color get orange => const Color(0xFFE67E22);
  static Color get border => _dark ? const Color(0x0FFFFFFF) : const Color(0x18000000);
  static Color get muted => _dark ? const Color(0x99FFFFFF) : const Color(0xAA333333);
  static Color get dimmed => _dark ? const Color(0x59FFFFFF) : const Color(0x77555555);
  static Color get textPrimary => _dark ? Colors.white : const Color(0xFF1A1A2E);
  static Color get textSecondary => _dark ? Colors.white70 : const Color(0xFF555555);
  static Color get drawerHeader1 => const Color(0xFF5B54E0);
  static Color get drawerHeader2 => const Color(0xFF3D2FB5);
  static Color get divider => _dark ? const Color(0xFF2A2A3E) : const Color(0xFFE0E0E0);
  static Color get cardShadow => _dark ? accent.withOpacity(0.15) : Colors.black.withOpacity(0.06);
  /// For icons/text that sit on surface cards (not on gradient)
  static Color get iconMuted => _dark ? Colors.white38 : const Color(0xFF999999);
  /// For drawer list items
  static Color get drawerIcon => _dark ? Colors.white70 : const Color(0xFF555555);
  static Color get drawerText => _dark ? Colors.white : const Color(0xFF222222);
  static Color get drawerSubtext => dimmed;
  /// For chart labels
  static Color get chartLabel => _dark ? const Color(0x59FFFFFF) : const Color(0xFF888888);
  static Color get chartGrid => _dark ? const Color(0x0AFFFFFF) : const Color(0x15000000);
  /// Insight strip
  static Color get insightBg => _dark ? accent.withOpacity(0.08) : const Color(0xFFEDE9FF);
  static Color get insightBorder => _dark ? accent.withOpacity(0.12) : const Color(0xFFD5CEFF);
  static Color get insightText => _dark ? Colors.white70 : const Color(0xFF444444);
}
