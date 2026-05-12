import 'package:flutter/material.dart';

import '../auth_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final config = await AuthConfig.load();
    if (config.isConfigured) {
      await AuthService.instance.loadPersistedSession(config);
    }
    if (!mounted) return;
    final target =
        AuthService.instance.session != null ? '/home' : '/login';
    Navigator.pushReplacementNamed(context, target);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFEC34F8)),
      ),
    );
  }
}
