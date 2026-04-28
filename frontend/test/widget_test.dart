import 'package:flutter_test/flutter_test.dart';
import 'package:kulturnatten/auth_service.dart';

void main() {
  test('auth config identifies placeholder values', () {
    final AuthConfig config = AuthConfig(
      clientId: 'YOUR_CLIENT_ID',
      redirectUri: 'com.kulturnatten.app:/oauthredirect',
      issuerUrl: 'http://10.0.2.2:8081/realms/kulturnatten-dev',
      scopes: const <String>['openid'],
    );

    expect(config.isConfigured, isFalse);
    expect(config.configurationError, isNotNull);
  });
}
