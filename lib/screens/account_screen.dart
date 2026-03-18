import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;

    final user = _usernameCtrl.text.trim();
    final pass = _passwordCtrl.text.trim();

    if (user == 'developer' && pass == 'developer') {
      AuthService().login();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Login successful'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid credentials'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
      prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF0F0F1A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text('Account', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.person_rounded, color: Color(0xFF6C63FF), size: 32),
                  ),
                  const SizedBox(height: 20),
                  const Text('Developer Login',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _usernameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Username', Icons.person_outline_rounded),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter username' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      'Password',
                      Icons.lock_outline_rounded,
                      suffix: GestureDetector(
                        onTap: () => setState(() => _obscure = !_obscure),
                        child: Icon(
                          _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: Colors.white.withOpacity(0.4),
                          size: 20,
                        ),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter password' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Confirm',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
