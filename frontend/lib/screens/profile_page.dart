import 'dart:convert';

import 'package:flutter/material.dart';

import '../auth_service.dart';
import '../services/plan_api_service.dart';
import '../widgets/bottom_nav_bar.dart';

//Färgkonstanter som används på sidan
const Color kBackground = Color(0xFF120A1E);
const Color kCardBg = Color(0xFF1E1030);
const Color kHeaderBg = Color(0xFF120A1E);
const Color kAccent = Color.fromARGB(255, 158, 88, 183);
const Color kSubtext = Color(0xFF8B6AAA);
const Color kBorder = Color(0xFF3A1F5C);
const Color kDivider = Color(0xFF2E1A50);
const Color kIconBg = Color(0xFF2A1545);
const Color kLogoutBg = Color(0xFF1E1030);
const Color kLogoutBorder = Color(0xFF3A1F5C);
const Color kLogoutText = Color.fromARGB(255, 158, 88, 183);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final PlanApiService _api =
      PlanApiService(baseUrl: 'http://10.0.2.2:8084');

  Map<String, dynamic>? _preferences;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final config = await AuthConfig.load();

    if (AuthService.instance.session == null) {
      await AuthService.instance.loadPersistedSession(config);
    }

    final token = await AuthService.instance.validAccessToken();
    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final data = await _api.fetchAll(token);
      setState(() {
        _preferences = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardBg,
        title: const Text(
          'Radera all din data?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Detta tar bort alla dina sparade preferenser. '
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
              style: TextStyle(color: kAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final token = await AuthService.instance.validAccessToken();
    if (token == null) return;

    try {
      final count = await _api.deleteAll(token);
      if (!mounted) return;
      setState(() => _preferences = {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Raderade $count poster.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunde inte radera: $e')),
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
        break; // byt till '/plan' när den routen finns
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
    final savedCount = _preferences?.length ?? 0;

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: SingleChildScrollView( //Så att man kan scrolla om innehållet blir för långt
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(email),
              _buildSectionLabel('SPARADE & PLANERADE'),
              _buildSavedCard(savedCount),
            //  _buildSectionLabel('INTRESSEN'),
           //   _buildInterestsCard(),
              _buildSectionLabel('KONTO'),
              _buildAccountCard(email),
              _buildLogoutButton(),
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

//Sidans header med namn, avatar, mejl, redigera profil knapp
  Widget _buildHeader(String? email) {
    return Container(
      color: kHeaderBg,
      padding: const EdgeInsets.fromLTRB(14, 28, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container( //cirkel till avatar med initialer i
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
              const Icon(Icons.settings_outlined, color: Colors.white, size: 26), //kugghjul för inställningar symbol
            ],
          ),
          const SizedBox(height: 14),
          Text( //användarens namn
            email ?? 'Inloggad användare',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text( //användarens email
            email ?? '',
            style: const TextStyle(color: kSubtext, fontSize: 16),
          ),
          const SizedBox(height: 14), //redigera profil knapp
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined, size: 17, color: kAccent), //penna ikon
            label: const Text(
              'Redigera profil',
              style: TextStyle(color: kAccent, fontSize: 15),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: kBorder, width: 1.5),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 11),
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

  Widget _buildSavedCard(int savedCount) { //sparade evenemang och min plan kort
    return _buildCard(
      children: [
        _buildRow(
          icon: Icons.favorite_border,
          title: 'Sparade evenemang',
          subtitle: _loading ? 'Laddar…' : '$savedCount sparade',
          isLast: false,
        ),
        _buildRow(
          icon: Icons.calendar_today_outlined,
          title: 'Min plan',
          subtitle: 'Inga evenemang',
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildAccountCard(String? email) { //kontoinställningar kort
    return _buildCard(
      children: [
        _buildRow(
          icon: Icons.person_outline,
          title: 'Kontouppgifter',
          subtitle: email ?? 'Inte inloggad',
          isLast: false,
        ),
        _buildRow(
          icon: Icons.notifications_none,
          title: 'Aviseringar',
          subtitle: 'Påminnelser, nyheter',
          isLast: false,
        ),
        _buildRow(
          icon: Icons.lock_outline,
          title: 'Sekretess',
          subtitle: 'Radera min data',
          isLast: true,
          onTap: _deleteAll,
        ),
      ],
    );
  }

//kort som har rundadehörn och fin lila kant, återanvändningsbar
  Widget _buildCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 1.5),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isLast,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: kIconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: kAccent, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(color: kSubtext, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF4A3070),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(color: kDivider, height: 0.5, thickness: 0.5),
      ],
    );
  }

//logga ut knapp längst ned
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
}
