import 'package:dart_frog_openapi/dart_frog_openapi.dart';
import 'package:test/test.dart';

void main() {
  group('Security', () {
    test('creates with scheme only', () {
      const security = Security('oauth2');
      expect(security.scheme, 'oauth2');
      expect(security.scopes, isEmpty);
    });

    test('creates with scheme and scopes', () {
      const security = Security('oauth2', scopes: ['read', 'write']);
      expect(security.scheme, 'oauth2');
      expect(security.scopes, ['read', 'write']);
    });

    test('creates with empty scopes list', () {
      const security = Security('custom', scopes: []);
      expect(security.scopes, isEmpty);
    });

    test('creates with single scope', () {
      const security = Security('api', scopes: ['admin']);
      expect(security.scopes, ['admin']);
    });

    test('creates with multiple scopes', () {
      const security = Security('oauth2', scopes: ['read', 'write', 'delete', 'admin']);
      expect(security.scopes.length, 4);
      expect(security.scopes, contains('read'));
      expect(security.scopes, contains('admin'));
    });
  });

  group('BearerAuth', () {
    test('has bearerAuth scheme by default', () {
      const bearer = BearerAuth();
      expect(bearer.scheme, 'bearerAuth');
    });

    test('has empty scopes by default', () {
      const bearer = BearerAuth();
      expect(bearer.scopes, isEmpty);
    });

    test('creates with scopes', () {
      const bearer = BearerAuth(scopes: ['admin']);
      expect(bearer.scheme, 'bearerAuth');
      expect(bearer.scopes, ['admin']);
    });

    test('creates with multiple scopes', () {
      const bearer = BearerAuth(scopes: ['read', 'write', 'admin']);
      expect(bearer.scopes, ['read', 'write', 'admin']);
    });

    test('extends Security', () {
      const bearer = BearerAuth();
      expect(bearer, isA<Security>());
    });
  });

  group('ApiKeyAuth', () {
    test('has apiKey scheme by default', () {
      const apiKey = ApiKeyAuth();
      expect(apiKey.scheme, 'apiKey');
    });

    test('has empty scopes by default', () {
      const apiKey = ApiKeyAuth();
      expect(apiKey.scopes, isEmpty);
    });

    test('creates with custom scheme', () {
      const apiKey = ApiKeyAuth(scheme: 'customApiKey');
      expect(apiKey.scheme, 'customApiKey');
    });

    test('creates with scopes', () {
      const apiKey = ApiKeyAuth(scopes: ['read', 'write']);
      expect(apiKey.scopes, ['read', 'write']);
    });

    test('creates with custom scheme and scopes', () {
      const apiKey = ApiKeyAuth(scheme: 'myApiKey', scopes: ['admin']);
      expect(apiKey.scheme, 'myApiKey');
      expect(apiKey.scopes, ['admin']);
    });

    test('extends Security', () {
      const apiKey = ApiKeyAuth();
      expect(apiKey, isA<Security>());
    });
  });

  group('BasicAuth', () {
    test('has basicAuth scheme', () {
      const basic = BasicAuth();
      expect(basic.scheme, 'basicAuth');
    });

    test('has empty scopes', () {
      const basic = BasicAuth();
      expect(basic.scopes, isEmpty);
    });

    test('extends Security', () {
      const basic = BasicAuth();
      expect(basic, isA<Security>());
    });
  });

  group('Public', () {
    test('is const constructible', () {
      const publicAnnotation = Public();
      expect(publicAnnotation, isA<Public>());
    });

    test('const instance exists', () {
      expect(public_, isA<Public>());
    });
  });
}
