import 'package:flutter/material.dart';
import '../services/lock_service.dart';
import '../services/theme_service.dart';

class LockScreen extends StatefulWidget {
  final Widget child;
  const LockScreen({super.key, required this.child});
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  final _lock = LockService();
  bool _locked = true;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLock();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-lock when app goes to background
    if (state == AppLifecycleState.paused && _lock.isEnabled) {
      setState(() => _locked = true);
    }
    if (state == AppLifecycleState.resumed && _locked && _lock.isEnabled) {
      _checkLock();
    }
  }

  Future<void> _checkLock() async {
    if (!_lock.isEnabled) {
      setState(() => _locked = false);
      return;
    }
    _tryAuthenticate();
  }

  Future<void> _tryAuthenticate() async {
    if (_authenticating) return;
    _authenticating = true;
    final ok = await _lock.authenticate();
    _authenticating = false;
    if (ok && mounted) setState(() => _locked = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked) return widget.child;

    final isDark = ThemeService().isDark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF2F3F7),
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.lock_rounded, size: 56, color: AppColors.accent.withOpacity(0.3)),
        const SizedBox(height: 20),
        Text('Money Tracker', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Tap to unlock', style: TextStyle(color: AppColors.dimmed, fontSize: 14)),
        const SizedBox(height: 32),
        SizedBox(
          height: 48, width: 160,
          child: ElevatedButton.icon(
            onPressed: _tryAuthenticate,
            icon: const Icon(Icons.fingerprint_rounded, size: 20),
            label: const Text('Unlock', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ])),
    );
  }
}
