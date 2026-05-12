import 'package:flutter/material.dart';

import '../auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _username.text.trim();
    final password = _password.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Fyll i användarnamn och lösenord.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final config = await AuthConfig.load();
      if (!config.isConfigured) {
        setState(() {
          _loading = false;
          _error = config.configurationError;
        });
        return;
      }
      await AuthService.instance.signInWithPassword(
        config,
        username: username,
        password: password,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Fel användarnamn eller lösenord.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Logga in'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const SizedBox(height: 24),
              const Center(
                child: Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Color(0xFFEC34F8),
                ),
              ),
              const SizedBox(height: 32),
              _field(_username, 'Användarnamn', false),
              const SizedBox(height: 12),
              _field(_password, 'Lösenord', true),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFEC34F8)),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: _loading ? null : _login,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEC34F8),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Logga in'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, bool obscure) {
    return TextField(
      controller: c,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      cursorColor: const Color(0xFFAE8ACF),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFAE8ACF)),
        filled: true,
        fillColor: const Color(0xFF1D0930),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF461458), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF861C91), width: 2),
        ),
      ),
    );
  }
}
