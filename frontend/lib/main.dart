import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'screens/map_screen.dart';
import 'screens/profile_page.dart';

void main() {
  runApp(const KulturnattenApp());
}

const String routeAuth = '/';
const String routeMap = '/map';
const String routeProfile = '/profile';

class KulturnattenApp extends StatelessWidget {
  const KulturnattenApp({super.key});

  @override


  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Kulturnatten',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006A6A)),
        scaffoldBackgroundColor: const Color(0xFFF5F7F8),
      ),
      initialRoute: routeProfile,
      routes: <String, WidgetBuilder>{
        //routeAuth: (_) => const AuthScreen(),
        //routeMap: (_) => const MapScreen(),
        routeProfile: (_) => const ProfilePage(),
      },
    );


    /*
    return MaterialApp(
      title: 'Kulturnatten',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006A6A)),
        scaffoldBackgroundColor: const Color(0xFFF5F7F8),
      ),
      initialRoute: routeAuth,
      routes: <String, WidgetBuilder>{
        routeAuth: (_) => const AuthScreen(),
        routeMap: (_) => const MapScreen(),
      },
    ); */
  }
}


/*
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService.instance;
  late final Future<AuthConfig> _configFuture;

  AuthSession? _session;
  bool _isBusy = true;
  String? _error;
  String? _backendResult;

  @override
  void initState() {
    super.initState();
    _configFuture = AuthConfig.load();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final AuthConfig config = await _configFuture;
    if (!mounted) return;

    if (!config.isConfigured) {
      setState(() => _isBusy = false);
      return;
    }

    final AuthSession? session =
        await _authService.loadPersistedSession(config);
    if (!mounted) return;

    if (session != null) {
      Navigator.pushReplacementNamed(context, routeMap);
    } else {
      setState(() => _isBusy = false);
    }
  }

  Future<void> _signIn(AuthConfig config) async {
    if (!config.isConfigured) {
      setState(() => _error = config.configurationError);
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      final AuthSession session = await _authService.signIn(config);
      if (!mounted) return;
      setState(() => _session = session);
      Navigator.pushReplacementNamed(context, routeMap);
    } on FlutterAppAuthUserCancelledException {
      setState(() => _error = 'Sign-in was cancelled.');
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      await _authService.signOut();
      setState(() {
        _session = null;
        _backendResult = null;
      });
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _callBackend(AuthConfig config) async {
    final String? token = _session?.accessToken;
    final String? baseUrl = config.backendBaseUrl;

    if (token == null || token.isEmpty) {
      setState(() => _error = 'Sign in first.');
      return;
    }

    if (baseUrl == null || baseUrl.isEmpty) {
      setState(() => _error = 'Set BACKEND_BASE_URL in env/auth.local.json.');
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
      _backendResult = null;
    });

    try {
      final http.Response response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: <String, String>{'Authorization': 'Bearer $token'},
      );

      setState(() {
        _backendResult =
            'GET $baseUrl/me\n${response.statusCode}\n${prettyResponse(response.body)}';
      });
    } catch (error) {
      setState(() => _error = 'Backend request failed: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthConfig>(
      future: _configFuture,
      builder: (BuildContext context, AsyncSnapshot<AuthConfig> snapshot) {
        final AuthConfig? config = snapshot.data;
        final bool isConfigured = config?.isConfigured ?? false;
        final bool isLoggedIn = _session != null;

        return Scaffold(
          appBar: AppBar(title: const Text('Kulturnatten')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _StatusPanel(
                      isLoggedIn: isLoggedIn,
                      isBusy: _isBusy,
                      configurationError: snapshot.hasError
                          ? snapshot.error.toString()
                          : config?.configurationError,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: !_isBusy && config != null && !isLoggedIn
                              ? () => _signIn(config)
                              : null,
                          icon: const Icon(Icons.login),
                          label: const Text('Sign in'),
                        ),
                        OutlinedButton.icon(
                          onPressed: !_isBusy && isLoggedIn ? _signOut : null,
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign out'),
                        ),
                        OutlinedButton.icon(
                          onPressed: !_isBusy && isLoggedIn && config != null
                              ? () => _callBackend(config)
                              : null,
                          icon: const Icon(Icons.cloud_outlined),
                          label: const Text('Call backend'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_error != null) ...<Widget>[
                      _MessagePanel(
                        title: 'Auth Error',
                        body: _error!,
                        color: const Color(0xFF8A1C1C),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _ConfigPanel(
                      snapshot: snapshot,
                      isConfigured: isConfigured,
                    ),
                    const SizedBox(height: 16),
                    if (_backendResult != null)
                      _MessagePanel(
                        title: 'Backend',
                        body: _backendResult!,
                        color: const Color(0xFF0F766E),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.isLoggedIn,
    required this.isBusy,
    required this.configurationError,
  });

  final bool isLoggedIn;
  final bool isBusy;
  final String? configurationError;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = isLoggedIn
        ? const Color(0xFF0F766E)
        : const Color(0xFF6B7280);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD5DBE1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              isLoggedIn ? 'Logged in' : 'Logged out',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isBusy
                  ? 'Authentication request in progress.'
                  : isLoggedIn
                  ? 'Access token saved to secure storage.'
                  : 'Use browser-delegated sign-in to get an authorization code and exchange it for tokens.',
            ),
            if (configurationError != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                configurationError!,
                style: const TextStyle(color: Color(0xFF8A1C1C)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConfigPanel extends StatelessWidget {
  const _ConfigPanel({required this.snapshot, required this.isConfigured});

  final AsyncSnapshot<AuthConfig> snapshot;
  final bool isConfigured;

  @override
  Widget build(BuildContext context) {
    String body;

    if (snapshot.connectionState != ConnectionState.done) {
      body = 'Loading local auth configuration.';
    } else if (snapshot.hasError) {
      body = 'Unable to read auth configuration.';
    } else if (isConfigured) {
      body =
          'Using auth configuration provided through --dart-define-from-file=env/auth.local.json.';
    } else {
      body =
          'Create env/auth.local.json from env/auth.example.json and run Flutter with --dart-define-from-file=env/auth.local.json before signing in.';
    }

    return _MessagePanel(
      title: 'Configuration',
      body: body,
      color: isConfigured ? const Color(0xFF0F766E) : const Color(0xFF7C5E10),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.title,
    required this.body,
    required this.color,
  });

  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(61)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(body),
          ],
        ),
      ),
    );
  }
}

String prettyResponse(String body) {
  if (body.isEmpty) return '';
  try {
    final Object? decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return const JsonEncoder.withIndent('  ').convert(decoded);
    }
  } catch (_) {
    return body;
  }
  return body;
}
*/