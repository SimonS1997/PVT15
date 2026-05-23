import 'dart:async';

import 'package:flutter/material.dart';

import '../auth_service.dart';
import '../managers/saved_events_manager.dart';
import '../services/plan_api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final PlanApiService _api =
      PlanApiService(baseUrl: 'http://10.0.2.2:8084');

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Fyll i e-post och lösenord.');
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

      await _api.register(email: email, password: password);

      await AuthService.instance.signInWithPassword(
        config,
        username: email,
        password: password,
      );

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      unawaited(SavedEventsManager.instance.init());
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
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
        title: const Text('Skapa konto'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const SizedBox(height: 24),
              const Center(
                child: Icon(
                  Icons.person_add_alt_1_outlined,
                  size: 64,
                  color: Color(0xFFEC34F8),
                ),
              ),
              const SizedBox(height: 32),
              _field(_email, 'E-post', false),
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
                onPressed: _loading ? null : _register,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEC34F8),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _loading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Konto skapas…'),
                        ],
                      )
                    : const Text('Skapa konto'),
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
