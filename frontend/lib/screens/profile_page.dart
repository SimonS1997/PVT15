import 'dart:convert';

import 'package:flutter/material.dart';

import '../auth_service.dart';
import '../managers/saved_events_manager.dart';
import '../services/plan_api_service.dart';
import '../widgets/bottom_nav_bar.dart';

const Color kBackground = Color(0xFF120A1E);
const Color kCardBg = Color(0xFF1E1030);
const Color kHeaderBg = Color(0xFF120A1E);
const Color kAccent = Color.fromARGB(255, 158, 88, 183);
const Color kSubtext = Color(0xFF8B6AAA);
const Color kBorder = Color(0xFF3A1F5C);
const Color kIconBg = Color(0xFF2A1545);
const Color kLogoutBg = Color(0xFF1E1030);
const Color kLogoutBorder = Color(0xFF3A1F5C);
const Color kLogoutText = Color.fromARGB(255, 158, 88, 183);
const Color kDanger = Color(0xFFE45A5A);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final PlanApiService _api =
      PlanApiService(baseUrl: 'http://10.0.2.2:8084');

  @override
  void initState() {
    super.initState();
    _ensureSession();
  }

  Future<void> _ensureSession() async {
    if (AuthService.instance.session != null) return;
    final config = await AuthConfig.load();
    await AuthService.instance.loadPersistedSession(config);
    if (mounted) setState(() {});
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    SavedEventsManager.instance.clear();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardBg,
        title: const Text(
          'Radera kontot?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Detta tar bort ditt konto och all data permanent. '
          'Åtgärden kan inte ångras.',
          style: TextStyle(color: kSubtext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Ja, radera',
              style: TextStyle(color: kDanger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final token = await AuthService.instance.validAccessToken();
    if (token == null) return;

    try {
      await _api.deleteAccount(token);
      SavedEventsManager.instance.clear();
      await AuthService.instance.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunde inte radera kontot: $e')),
      );
    }
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/map');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/plan');
        break;
      case 3:
        break;
    }
  }

  String? _email() {
    final idToken = AuthService.instance.session?.idToken;
    if (idToken == null) return null;

    final parts = idToken.split('.');
    if (parts.length != 3) return null;

    try {
      final decoded = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = jsonDecode(decoded) as Map<String, dynamic>;
      return (claims['email'] ?? claims['preferred_username']) as String?;
    } catch (_) {
      return null;
    }
  }

  String _initials(String? email) {
    if (email == null || email.isEmpty) return '?';
    final name = email.split('@').first;
    final parts = name.split(RegExp(r'[._-]'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final email = _email();

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(email),
              _buildSectionLabel('KONTO'),
              _buildAccountCard(email),
              _buildLogoutButton(),
              _buildDeleteAccountButton(),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildHeader(String? email) {
    return Container(
      color: kHeaderBg,
      padding: const EdgeInsets.fromLTRB(14, 28, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2D1A4A),
              border: Border.all(color: kBorder, width: 2),
            ),
            child: Center(
              child: Text(
                _initials(email),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            email ?? 'Inloggad användare',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF7C6A9A),
          fontSize: 11,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _buildAccountCard(String? email) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: kIconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_outline, color: kAccent, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'E-post',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email ?? 'Inte inloggad',
                  style: const TextStyle(color: kSubtext, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 20, 14, 0),
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _signOut,
        icon: const Icon(Icons.logout, size: 20, color: kLogoutText),
        label: const Text(
          'Logga ut',
          style: TextStyle(
            color: kLogoutText,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: kLogoutBg,
          side: const BorderSide(color: kLogoutBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _deleteAccount,
        icon: const Icon(Icons.delete_outline, size: 20, color: kDanger),
        label: const Text(
          'Radera konto',
          style: TextStyle(
            color: kDanger,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: kLogoutBg,
          side: const BorderSide(color: kDanger, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
