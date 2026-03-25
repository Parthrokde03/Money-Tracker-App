import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/sms_service.dart';
import '../services/gmail_service.dart';
import '../services/lock_service.dart';
import '../services/budget_service.dart';

Color get _bg => AppColors.bg;
Color get _surface => AppColors.surface;
const _accent = Color(0xFF6C63FF);
Color get _border => AppColors.border;
Color get _dimmed => AppColors.dimmed;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _smsService = SmsService();
  final _gmailService = GmailService();
  final _theme = ThemeService();
  final _lockService = LockService();
  final _budgetService = BudgetService();

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true, backgroundColor: _surface, elevation: 0, surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // ── Appearance ──
          _sectionLabel('Appearance'),
          _settingsTile(
            icon: _theme.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            title: _theme.isDark ? 'Dark Mode' : 'Light Mode',
            subtitle: 'Switch between dark and light theme',
            trailing: Switch(
              value: _theme.isDark,
              activeColor: _accent,
              onChanged: (v) async {
                await _theme.toggle();
                setState(() {});
              },
            ),
          ),

          const SizedBox(height: 8),

          // ── Privacy & Security ──
          _sectionLabel('Privacy & Security'),
          _settingsTile(
            icon: Icons.lock_rounded,
            title: 'App Lock',
            subtitle: 'Use PIN, pattern, or biometric to lock',
            trailing: Switch(
              value: _lockService.isEnabled,
              activeColor: _accent,
              onChanged: (v) async {
                if (v) {
                  // Verify device has a lock set up
                  final supported = await _lockService.isDeviceSupported();
                  if (!supported) {
                    _snack('Set up a screen lock on your device first');
                    return;
                  }
                  // Test authentication before enabling
                  await _lockService.setEnabled(true);
                  final ok = await _lockService.authenticate();
                  if (!ok) {
                    await _lockService.setEnabled(false);
                    _snack('Authentication failed');
                    setState(() {});
                    return;
                  }
                }
                await _lockService.setEnabled(v);
                setState(() {});
                _snack(v ? 'App lock enabled' : 'App lock disabled');
              },
            ),
          ),

          const SizedBox(height: 8),

          // ── Budget ──
          _sectionLabel('Budget'),
          _settingsTile(
            icon: Icons.pie_chart_rounded,
            title: 'Set Budget',
            subtitle: 'Track your monthly spending limits',
            trailing: Switch(
              value: _budgetService.isEnabled,
              activeColor: _accent,
              onChanged: (v) async {
                await _budgetService.setEnabled(v);
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 8),

          // ── SMS ──
          _sectionLabel('SMS'),
          _settingsTile(
            icon: Icons.sms_rounded,
            title: 'SMS Auto-Entry',
            subtitle: 'Auto-detect bank transactions from SMS',
            trailing: Switch(
              value: _smsService.isEnabled,
              activeColor: _accent,
              onChanged: (v) async {
                if (v) {
                  final granted = await _smsService.requestPermissions();
                  if (!granted) { _snack('SMS permission denied'); return; }
                }
                await _smsService.setEnabled(v);
                setState(() {});
              },
            ),
          ),

          const SizedBox(height: 8),

          // ── Gmail ──
          _sectionLabel('Gmail'),
          if (_gmailService.isSignedIn) ...[
            // Connected account card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accent.withOpacity(0.12)),
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 20, backgroundColor: _accent.withOpacity(0.12),
                  child: const Icon(Icons.email_rounded, color: _accent, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Connected', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  if (_gmailService.userEmail != null)
                    Text(_gmailService.userEmail!, style: TextStyle(color: _dimmed, fontSize: 12), overflow: TextOverflow.ellipsis),
                ])),
                SizedBox(
                  height: 34,
                  child: OutlinedButton(
                    onPressed: () async {
                      final email = _gmailService.userEmail;
                      final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                        backgroundColor: _surface,
                        title: Text('Sign out?', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                        content: Text('Disconnect Gmail auto-entry for $email', style: TextStyle(color: _dimmed, fontSize: 13)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: _dimmed))),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent))),
                        ],
                      ));
                      if (confirm == true) {
                        await _gmailService.signOut();
                        setState(() {});
                        _snack('Gmail disconnected');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 0.8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Sign Out', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 4),
            _settingsTile(
              icon: Icons.sync_rounded,
              title: 'Auto-Entry',
              subtitle: 'Auto-detect bank transactions from emails',
              trailing: Switch(
                value: _gmailService.isEnabled,
                activeColor: _accent,
                onChanged: (v) async {
                  await _gmailService.setEnabled(v);
                  setState(() {});
                },
              ),
            ),
          ] else ...[
            // Not signed in
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SizedBox(
                width: double.infinity, height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await _gmailService.signIn();
                    if (ok) {
                      await _gmailService.setEnabled(true);
                      setState(() {});
                      _snack('Gmail connected');
                    } else {
                      _snack('Google sign-in failed');
                    }
                  },
                  icon: const Icon(Icons.email_rounded, size: 18),
                  label: const Text('Connect Gmail', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accent,
                    side: BorderSide(color: _accent.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text('Connect your Gmail to auto-detect bank transactions from emails',
                style: TextStyle(color: _dimmed, fontSize: 12)),
            ),
          ],

          const SizedBox(height: 24),

          // ── About ──
          _sectionLabel('About'),
          _settingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Money Tracker',
            subtitle: 'Version 1.0.0',
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Text(label, style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    );
  }

  Widget _settingsTile({required IconData icon, required String title, String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: ListTile(
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: _accent.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _accent, size: 18),
        ),
        title: Text(title, style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: _dimmed, fontSize: 11)) : null,
        trailing: trailing,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
