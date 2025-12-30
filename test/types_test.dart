import 'package:dart_frog_openapi/dart_frog_openapi.dart';
import 'package:test/test.dart';

void main() {
  group('Server', () {
    test('creates with url only', () {
      const server = Server(url: 'http://localhost:8080');
      expect(server.url, 'http://localhost:8080');
      expect(server.description, isNull);
    });

    test('creates with url and description', () {
      const server = Server(url: 'https://api.example.com', description: 'Production');
      expect(server.url, 'https://api.example.com');
      expect(server.description, 'Production');
    });

    test('toJson without description', () {
      const server = Server(url: 'http://localhost');
      final json = server.toJson();
      expect(json['url'], 'http://localhost');
      expect(json.containsKey('description'), false);
    });

    test('toJson with description', () {
      const server = Server(url: 'http://localhost', description: 'Dev');
      final json = server.toJson();
      expect(json, {'url': 'http://localhost', 'description': 'Dev'});
    });

    test('handles production URL', () {
      const server = Server(url: 'https://api.production.example.com/v1', description: 'Production API v1');
      expect(server.url, 'https://api.production.example.com/v1');
      expect(server.description, 'Production API v1');
    });

    test('handles staging URL', () {
      const server = Server(url: 'https://api.staging.example.com', description: 'Staging');
      final json = server.toJson();
      expect(json['url'], 'https://api.staging.example.com');
      expect(json['description'], 'Staging');
    });
  });

  group('Contact', () {
    test('creates with defaults (all null)', () {
      const contact = Contact();
      expect(contact.name, isNull);
      expect(contact.email, isNull);
      expect(contact.url, isNull);
    });

    test('isEmpty when all null', () {
      const contact = Contact();
      expect(contact.isEmpty, true);
    });

    test('isEmpty false when name set', () {
      const contact = Contact(name: 'Support');
      expect(contact.isEmpty, false);
    });

    test('isEmpty false when email set', () {
      const contact = Contact(email: 'support@example.com');
      expect(contact.isEmpty, false);
    });

    test('isEmpty false when url set', () {
      const contact = Contact(url: 'https://example.com');
      expect(contact.isEmpty, false);
    });

    test('isEmpty false when all set', () {
      const contact = Contact(name: 'Support', email: 'support@example.com', url: 'https://example.com');
      expect(contact.isEmpty, false);
    });

    test('toJson with name only', () {
      const contact = Contact(name: 'Support');
      final json = contact.toJson();
      expect(json['name'], 'Support');
      expect(json.containsKey('email'), false);
      expect(json.containsKey('url'), false);
    });

    test('toJson with email only', () {
      const contact = Contact(email: 'test@test.com');
      final json = contact.toJson();
      expect(json, {'email': 'test@test.com'});
    });

    test('toJson with url only', () {
      const contact = Contact(url: 'https://support.example.com');
      final json = contact.toJson();
      expect(json, {'url': 'https://support.example.com'});
    });

    test('toJson with all fields', () {
      const contact = Contact(name: 'Support', email: 'support@example.com', url: 'https://example.com');
      final json = contact.toJson();
      expect(json, {'name': 'Support', 'email': 'support@example.com', 'url': 'https://example.com'});
    });

    test('toJson with partial fields (name and email)', () {
      const contact = Contact(name: 'API Support', email: 'api@example.com');
      final json = contact.toJson();
      expect(json['name'], 'API Support');
      expect(json['email'], 'api@example.com');
      expect(json.containsKey('url'), false);
    });

    test('toJson with partial fields (name and url)', () {
      const contact = Contact(name: 'Support Team', url: 'https://support.example.com');
      final json = contact.toJson();
      expect(json['name'], 'Support Team');
      expect(json['url'], 'https://support.example.com');
      expect(json.containsKey('email'), false);
    });
  });

  group('License', () {
    test('creates with name only', () {
      const license = License(name: 'MIT');
      expect(license.name, 'MIT');
      expect(license.url, isNull);
    });

    test('creates with name and url', () {
      const license = License(name: 'Apache 2.0', url: 'https://www.apache.org/licenses/LICENSE-2.0');
      expect(license.name, 'Apache 2.0');
      expect(license.url, 'https://www.apache.org/licenses/LICENSE-2.0');
    });

    test('toJson without url', () {
      const license = License(name: 'MIT');
      final json = license.toJson();
      expect(json, {'name': 'MIT'});
    });

    test('toJson with url', () {
      const license = License(name: 'MIT', url: 'https://mit.edu');
      final json = license.toJson();
      expect(json, {'name': 'MIT', 'url': 'https://mit.edu'});
    });

    test('handles BSD license', () {
      const license = License(name: 'BSD-3-Clause', url: 'https://opensource.org/licenses/BSD-3-Clause');
      final json = license.toJson();
      expect(json['name'], 'BSD-3-Clause');
      expect(json['url'], 'https://opensource.org/licenses/BSD-3-Clause');
    });

    test('handles GPL license', () {
      const license = License(name: 'GPL-3.0', url: 'https://www.gnu.org/licenses/gpl-3.0.html');
      expect(license.name, 'GPL-3.0');
    });

    test('handles proprietary license', () {
      const license = License(name: 'Proprietary');
      final json = license.toJson();
      expect(json, {'name': 'Proprietary'});
    });
  });
}
