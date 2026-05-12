import 'dart:convert';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthConfig {
  AuthConfig({
    required this.clientId,
    required this.redirectUri,
    required this.issuerUrl,
    required this.scopes,
    this.userFlow,
  });

  final String clientId;
  final String redirectUri;
  final String issuerUrl;
  final List<String> scopes;
  final String? userFlow;

  static Future<AuthConfig> load() async {
    return AuthConfig.fromEnvironment();
  }

  factory AuthConfig.fromEnvironment() {
    final List<String> scopes =
        const String.fromEnvironment(
              'AUTH_SCOPES',
              defaultValue: 'openid,profile,email,offline_access',
            )
            .split(',')
            .map((String value) => value.trim())
            .where((String value) => value.isNotEmpty)
            .toList();

    return AuthConfig(
      clientId: const String.fromEnvironment(
        'AUTH_CLIENT_ID',
        defaultValue: 'kulturnatten-mobile',
      ).trim(),
      redirectUri: const String.fromEnvironment(
        'AUTH_REDIRECT_URI',
        defaultValue: 'com.kulturnatten.app:/oauthredirect',
      ).trim(),
      issuerUrl: const String.fromEnvironment(
        'AUTH_ISSUER_URL',
        defaultValue: 'http://10.0.2.2:8081/realms/kulturnatten-dev',
      ).trim(),
      userFlow: _trimToNull(const String.fromEnvironment('AUTH_USER_FLOW')),
      scopes: scopes,
    );
  }

  bool get isConfigured => configurationError == null;

  String? get configurationError {
    final Map<String, String> requiredValues = <String, String>{
      'AUTH_CLIENT_ID': clientId,
      'AUTH_REDIRECT_URI': redirectUri,
      'AUTH_ISSUER_URL': issuerUrl,
    };

    for (final MapEntry<String, String> entry in requiredValues.entries) {
      if (entry.value.isEmpty || _looksLikePlaceholder(entry.value)) {
        return 'Set ${entry.key} in env/auth.local.json and start Flutter with --dart-define-from-file=env/auth.local.json.';
      }
    }

    return null;
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
  });

  final String? accessToken;
  final String? idToken;
  final String? refreshToken;
  final DateTime? accessTokenExpirationDateTime;
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const FlutterAppAuth _appAuth = FlutterAppAuth();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _kAccessToken = 'auth_access_token';
  static const String _kIdToken = 'auth_id_token';
  static const String _kRefreshToken = 'auth_refresh_token';
  static const String _kExpiry = 'auth_expiry';

  AuthSession? _session;
  AuthConfig? _config;

  bool get isLoggedIn => _session != null;
  AuthSession? get session => _session;

  Future<AuthSession> signIn(AuthConfig config) async {
    _config = config;

    final AuthorizationTokenResponse result =
        await _appAuth.authorizeAndExchangeCode(
          AuthorizationTokenRequest(
            config.clientId,
            config.redirectUri,
            issuer: config.issuerUrl,
            scopes: config.scopes,
            additionalParameters: config.additionalParameters,
            allowInsecureConnections: true,
          ),
        );

    _session = AuthSession(
      accessToken: result.accessToken,
      idToken: result.idToken,
      refreshToken: result.refreshToken,
      accessTokenExpirationDateTime: result.accessTokenExpirationDateTime,
    );

    await _persist(_session!);
    return _session!;
  }

  Future<AuthSession> signInWithPassword(
    AuthConfig config, {
    required String username,
    required String password,
  }) async {
    _config = config;

    final response = await http.post(
      Uri.parse('${config.issuerUrl}/protocol/openid-connect/token'),
      body: {
        'client_id': config.clientId,
        'grant_type': 'password',
        'username': username,
        'password': password,
        'scope': config.scopes.join(' '),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Inloggning misslyckades');
    }

    final data = jsonDecode(response.body);
    _session = AuthSession(
      accessToken: data['access_token'],
      idToken: data['id_token'],
      refreshToken: data['refresh_token'],
      accessTokenExpirationDateTime:
          DateTime.now().add(Duration(seconds: data['expires_in'] ?? 0)),
    );

    await _persist(_session!);
    return _session!;
  }

  Future<AuthSession?> loadPersistedSession(AuthConfig config) async {
    _config = config;

    final String? accessToken = await _storage.read(key: _kAccessToken);
    if (accessToken == null) return null;

    final String? idToken = await _storage.read(key: _kIdToken);
    final String? refreshToken = await _storage.read(key: _kRefreshToken);
    final String? expiryStr = await _storage.read(key: _kExpiry);
    final DateTime? expiry =
        expiryStr != null ? DateTime.tryParse(expiryStr) : null;

    final bool isExpired =
        expiry != null && expiry.isBefore(DateTime.now());

    if (isExpired) {
      if (refreshToken == null) {
        await _clearStorage();
        return null;
      }
      final AuthSession? refreshed =
          await _refresh(config, refreshToken: refreshToken);
      if (refreshed == null) {
        await _clearStorage();
        return null;
      }
      _session = refreshed;
      return _session;
    }

    _session = AuthSession(
      accessToken: accessToken,
      idToken: idToken,
      refreshToken: refreshToken,
      accessTokenExpirationDateTime: expiry,
    );
    return _session;
  }

  Future<void> signOut() async {
    _session = null;
    await _clearStorage();
  }

  Future<AuthSession?> _refresh(
    AuthConfig config, {
    required String refreshToken,
  }) async {
    try {
      final TokenResponse result = await _appAuth.token(
        TokenRequest(
          config.clientId,
          config.redirectUri,
          issuer: config.issuerUrl,
          refreshToken: refreshToken,
          scopes: config.scopes,
          allowInsecureConnections: true,
        ),
      );

      final AuthSession refreshed = AuthSession(
        accessToken: result.accessToken,
        idToken: result.idToken,
        refreshToken: result.refreshToken ?? refreshToken,
        accessTokenExpirationDateTime: result.accessTokenExpirationDateTime,
      );
      await _persist(refreshed);
      return refreshed;
    } catch (_) {
      return null;
    }
  }

  Future<void> _persist(AuthSession session) async {
    if (session.accessToken != null) {
      await _storage.write(key: _kAccessToken, value: session.accessToken);
    }
    if (session.idToken != null) {
      await _storage.write(key: _kIdToken, value: session.idToken);
    }
    if (session.refreshToken != null) {
      await _storage.write(key: _kRefreshToken, value: session.refreshToken);
    }
    if (session.accessTokenExpirationDateTime != null) {
      await _storage.write(
        key: _kExpiry,
        value: session.accessTokenExpirationDateTime!.toIso8601String(),
      );
    }
  }

  Future<void> _clearStorage() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kIdToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kExpiry);
  }
}
