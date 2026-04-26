import 'dart:convert';
import 'map_test_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const KulturnattenApp());
}

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
      home: const MapTestPage(), //Bytte tillfälligt för att testa map page, byt tillbaka till AuthScreen() sen
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final EntraAuthService _authService = EntraAuthService();
  late final Future<AuthConfig> _configFuture;

  AuthSession? _session;
  bool _isBusy = false;
  String? _error;
  String? _backendResult;

  @override
  void initState() {
    super.initState();
    _configFuture = AuthConfig.load();
  }

  Future<void> _signIn(AuthConfig config) async {
    if (!config.isConfigured) {
      setState(() {
        _error = config.configurationError;
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      final AuthSession session = await _authService.signIn(config);
      setState(() {
        _session = session;
        _backendResult = null;
      });
    } on FlutterAppAuthUserCancelledException {
      setState(() {
        _error = 'Sign-in was cancelled.';
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
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
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _callBackend(AuthConfig config) async {
    final String? token = _session?.accessToken;
    final String? baseUrl = config.backendBaseUrl;

    if (token == null || token.isEmpty) {
      setState(() {
        _error = 'Sign in first.';
      });
      return;
    }

    if (baseUrl == null || baseUrl.isEmpty) {
      setState(() {
        _error = 'Set BACKEND_BASE_URL in env/auth.local.json.';
      });
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
      setState(() {
        _error = 'Backend request failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
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
                          onPressed: !_isBusy && config != null
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
                    if (_backendResult != null) ...<Widget>[
                      _MessagePanel(
                        title: 'Backend',
                        body: _backendResult!,
                        color: const Color(0xFF0F766E),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _DebugPanel(session: _session),
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
                  ? 'Access token is stored in memory for this app session.'
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

class _DebugPanel extends StatelessWidget {
  const _DebugPanel({required this.session});

  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    final String tokenText = session == null
        ? 'No access token in memory.'
        : prettyPrintJson(session!.debugSummary);

    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Debug',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    tokenText,
                    style: const TextStyle(
                      color: Color(0xFFE5E7EB),
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

class AuthConfig {
  AuthConfig({
    required this.clientId,
    required this.redirectUri,
    required this.authorityUrl,
    required this.scopes,
    this.userFlow,
    this.backendBaseUrl,
  });

  final String clientId;
  final String redirectUri;
  final String authorityUrl;
  final List<String> scopes;
  final String? userFlow;
  final String? backendBaseUrl;

  static Future<AuthConfig> load() async {
    return AuthConfig.fromEnvironment();
  }

  factory AuthConfig.fromEnvironment() {
    final List<String> scopes =
        const String.fromEnvironment(
              'AUTH_SCOPES',
              defaultValue: 'openid,profile,offline_access',
            )
            .split(',')
            .map((String value) => value.trim())
            .where((String value) => value.isNotEmpty)
            .toList();

    return AuthConfig(
      clientId: const String.fromEnvironment('AUTH_CLIENT_ID').trim(),
      redirectUri: const String.fromEnvironment('AUTH_REDIRECT_URI').trim(),
      authorityUrl: const String.fromEnvironment('AUTH_AUTHORITY_URL').trim(),
      userFlow: _trimToNull(const String.fromEnvironment('AUTH_USER_FLOW')),
      backendBaseUrl: _trimToNull(
        const String.fromEnvironment('BACKEND_BASE_URL'),
      ),
      scopes: scopes,
    );
  }

  factory AuthConfig.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? rawScopes = json['scopes'] as List<dynamic>?;
    return AuthConfig(
      clientId: (json['client_id'] as String? ?? '').trim(),
      redirectUri: (json['redirect_uri'] as String? ?? '').trim(),
      authorityUrl: (json['authority_url'] as String? ?? '').trim(),
      userFlow: (json['user_flow'] as String?)?.trim(),
      backendBaseUrl: (json['backend_base_url'] as String?)?.trim(),
      scopes: rawScopes == null || rawScopes.isEmpty
          ? <String>['openid', 'profile', 'offline_access']
          : rawScopes.map((dynamic value) => value.toString()).toList(),
    );
  }

  bool get isConfigured => configurationError == null;

  String? get configurationError {
    final Map<String, String> requiredValues = <String, String>{
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'authority_url': authorityUrl,
    };

    for (final MapEntry<String, String> entry in requiredValues.entries) {
      if (entry.value.isEmpty || _looksLikePlaceholder(entry.value)) {
        return 'Set ${entry.key} in env/auth.local.json and start Flutter with --dart-define-from-file=env/auth.local.json.';
      }
    }

    return null;
  }

  String get discoveryUrl {
    final String base = authorityUrl.endsWith('/')
        ? authorityUrl
        : '$authorityUrl/';
    final String suffix = userFlow == null || userFlow!.isEmpty
        ? ''
        : '?p=${Uri.encodeQueryComponent(userFlow!)}';
    return '${base}v2.0/.well-known/openid-configuration$suffix';
  }

  Map<String, String>? get additionalParameters {
    if (userFlow == null ||
        userFlow!.isEmpty ||
        _looksLikePlaceholder(userFlow!)) {
      return null;
    }

    return <String, String>{'p': userFlow!};
  }

  static bool _looksLikePlaceholder(String value) {
    return value.contains('YOUR_') ||
        value.contains('Enter_the_') ||
        value.contains('<') ||
        value.contains('example.com');
  }

  static String? _trimToNull(String value) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class AuthSession {
  AuthSession({
    required this.accessToken,
    required this.idToken,
    required this.refreshToken,
    required this.accessTokenExpirationDateTime,
  }) : claims = _parseClaims(idToken ?? accessToken);

  final String? accessToken;
  final String? idToken;
  final String? refreshToken;
  final DateTime? accessTokenExpirationDateTime;
  final Map<String, dynamic>? claims;

  Map<String, dynamic> get debugSummary => <String, dynamic>{
    'logged_in': accessToken != null,
    'access_token_expires_at': accessTokenExpirationDateTime?.toIso8601String(),
    'access_token_preview': _preview(accessToken),
    'id_token_preview': _preview(idToken),
    'refresh_token_present': refreshToken != null,
    'claims': claims,
  };

  static String? _preview(String? token) {
    if (token == null || token.isEmpty) {
      return null;
    }

    if (token.length <= 32) {
      return token;
    }

    return '${token.substring(0, 16)}...${token.substring(token.length - 16)}';
  }

  static Map<String, dynamic>? _parseClaims(String? token) {
    if (token == null || token.isEmpty) {
      return null;
    }

    final List<String> parts = token.split('.');
    if (parts.length < 2) {
      return null;
    }

    final String normalized = base64Url.normalize(parts[1]);
    final String payload = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(payload) as Map<String, dynamic>;
  }
}

class EntraAuthService {
  static const FlutterAppAuth _appAuth = FlutterAppAuth();

  AuthSession? _session;

  AuthSession? get session => _session;

  Future<AuthSession> signIn(AuthConfig config) async {
    final AuthorizationTokenResponse result = await _appAuth
        .authorizeAndExchangeCode(
          AuthorizationTokenRequest(
            config.clientId,
            config.redirectUri,
            discoveryUrl: config.discoveryUrl,
            scopes: config.scopes,
            additionalParameters: config.additionalParameters,
          ),
        );

    _session = AuthSession(
      accessToken: result.accessToken,
      idToken: result.idToken,
      refreshToken: result.refreshToken,
      accessTokenExpirationDateTime: result.accessTokenExpirationDateTime,
    );

    return _session!;
  }

  Future<void> signOut() async {
    _session = null;
  }
}

String prettyPrintJson(Map<String, dynamic> value) {
  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(value);
}

String prettyResponse(String body) {
  if (body.isEmpty) {
    return '';
  }

  try {
    final Object? decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return prettyPrintJson(decoded);
    }
  } catch (_) {
    return body;
  }

  return body;
}
