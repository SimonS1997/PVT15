import 'dart:convert';

import 'package:flutter/material.dart';

import '../auth_service.dart';
import '../services/plan_api_service.dart';
import '../widgets/bottom_nav_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final PlanApiService _api =
  PlanApiService(baseUrl: 'http://10.0.2.2:8084');

  AuthConfig? _config;
  Map<String, dynamic>? _preferences;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final config = await AuthConfig.load();

    if (!config.isConfigured) {
      setState(() {
        _loading = false;
        _error = config.configurationError;
      });
      return;
    }

    _config = config;

    if (AuthService.instance.session == null) {
      await AuthService.instance.loadPersistedSession(config);
    }

    if (AuthService.instance.session == null) {
      setState(() => _loading = false);
      return;
    }

    await _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final token = AuthService.instance.session?.accessToken;

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
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Kunde inte hämta data: $e';
      });
    }
  }

  Future<void> _signIn() async {
    final result = await Navigator.pushNamed(context, '/login');

    if (result == true) {
      setState(() {
        _loading = true;
        _error = null;
      });

      await _loadPreferences();
    }
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D0930),
        title: const Text(
          'Radera all din data?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Detta tar bort alla dina sparade preferenser. '
              'Åtgärden kan inte ångras.',
          style: TextStyle(color: Color(0xFFAE8ACF)),
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
              style: TextStyle(color: Color(0xFFEC34F8)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final token = AuthService.instance.session?.accessToken;

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

  Future<void> _signOut() async {
    await AuthService.instance.signOut();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
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
        base64Url.decode(
          base64Url.normalize(parts[1]),
        ),
      );

      final claims = jsonDecode(decoded) as Map<String, dynamic>;

      return (claims['email'] ?? claims['preferred_username']) as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool loggedIn = AuthService.instance.session != null;

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Min profil'),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: ListView(
            children: [
              const Center(
                child: Icon(
                  Icons.account_circle,
                  size: 80,
                  color: Color(0xFFEC34F8),
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  loggedIn
                      ? (_email() ?? 'Inloggad användare')
                      : 'Inte inloggad',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Min data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Vi lagrar dina preferenser '
                    'så att de finns kvar nästa gång du loggar in. '
                    'Datan kan tas bort när du vill.',
                style: TextStyle(color: Color(0xFFAE8ACF)),
              ),

              const SizedBox(height: 12),

              _PreferencesCard(
                loading: _loading,
                error: _error,
                loggedIn: loggedIn,
                preferences: _preferences,
              ),

              const SizedBox(height: 24),

              if (!loggedIn)
                FilledButton.icon(
                  onPressed: _loading ? null : _signIn,
                  icon: const Icon(Icons.login),
                  label: const Text('Logga in'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEC34F8),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                )
              else ...[
                if (_preferences != null && _preferences!.isNotEmpty) ...[
                  OutlinedButton.icon(
                    onPressed: _deleteAll,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Radera all min data'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEC34F8),
                      side: const BorderSide(color: Color(0xFFEC34F8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],

                OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logga ut'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF461458)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],

              const SizedBox(height: 24),
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
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({
    required this.loading,
    required this.error,
    required this.loggedIn,
    required this.preferences,
  });

  final bool loading;
  final String? error;
  final bool loggedIn;
  final Map<String, dynamic>? preferences;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: const Color(0xFF1D0930),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF461458),
          width: 2,
        ),
      ),

      child: _content(),
    );
  }

  Widget _content() {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(
            color: Color(0xFFEC34F8),
          ),
        ),
      );
    }

    if (error != null) {
      return Text(
        error!,
        style: const TextStyle(
          color: Color(0xFFAE8ACF),
        ),
      );
    }

    if (!loggedIn) {
      return const Text(
        'Logga in för att se vilken data vi lagrar om dig.',
        style: TextStyle(
          color: Color(0xFFAE8ACF),
        ),
      );
    }

    if (preferences == null || preferences!.isEmpty) {
      return const Text(
        'Inga sparade preferenser ännu.',
        style: TextStyle(
          color: Color(0xFFAE8ACF),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: preferences!.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '${e.key}: ${e.value}',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        );
      }).toList(),
    );
  }
}