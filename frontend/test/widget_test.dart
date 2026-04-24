import 'package:flutter_test/flutter_test.dart';
import 'package:kulturnatten/main.dart';

void main() {
  test('pretty print returns indented json', () {
    final String rendered = prettyPrintJson(<String, dynamic>{
      'status': 'Logged out',
      'claims': <String, dynamic>{'sub': '123'},
    });

    expect(rendered, contains('"status": "Logged out"'));
    expect(rendered, contains('"sub": "123"'));
  });

  test('auth config identifies placeholder values', () {
    final AuthConfig config = AuthConfig.fromJson(<String, dynamic>{
      'client_id': 'YOUR_CLIENT_ID',
      'redirect_uri': 'msauth://com.kulturnatten.app/redirect',
      'authority_url': 'https://YOUR_TENANT_SUBDOMAIN.ciamlogin.com/tenant-id/',
    });

    expect(config.isConfigured, isFalse);
    expect(config.configurationError, isNotNull);
  });
}
