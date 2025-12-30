import 'package:dart_frog_openapi/dart_frog_openapi.dart';
import 'package:test/test.dart';

// Test models for integration tests

@ApiSchema(description: 'User account')
class IntegrationUser {
  @UuidProperty(description: 'Unique identifier')
  final String id;

  @EmailProperty()
  final String email;

  @ApiProperty(description: 'Display name', minLength: 2, maxLength: 100)
  final String name;

  @ApiProperty(enumValues: ['admin', 'user', 'guest'])
  final String role;

  @DateTimeProperty(description: 'Account creation date')
  final DateTime createdAt;

  @ApiHidden()
  final String hashedPassword;

  IntegrationUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    required this.hashedPassword,
  });
}

@ApiSchema(description: 'Request to create a new user')
class CreateUserRequest {
  @EmailProperty()
  final String email;

  @ApiProperty(description: 'Display name', minLength: 2, maxLength: 100)
  final String name;

  @PasswordProperty(description: 'User password', minLength: 8)
  final String password;

  CreateUserRequest({required this.email, required this.name, required this.password});
}

@ApiSchema(description: 'Error response')
class ErrorResponse {
  @ApiProperty(description: 'Error code')
  final String code;

  @ApiProperty(description: 'Error message')
  final String message;

  @ApiProperty(description: 'Additional details', required: false, nullable: true)
  final Map<String, dynamic>? details;

  ErrorResponse({required this.code, required this.message, this.details});
}

@ApiSchema(description: 'Authentication token')
class TokenResponse {
  @ApiProperty(description: 'JWT access token')
  final String accessToken;

  @ApiProperty(description: 'Refresh token')
  final String refreshToken;

  @ApiProperty(description: 'Token expiration in seconds')
  final int expiresIn;

  TokenResponse({required this.accessToken, required this.refreshToken, required this.expiresIn});
}

void main() {
  group('Integration tests', () {
    test('complete API documentation flow', () {
      final spec =
          OpenApiGenerator(
                title: 'Integration Test API',
                version: '1.0.0',
                description: 'API for integration testing',
                servers: [
                  const Server(url: 'https://api.test.com', description: 'Production'),
                  const Server(url: 'http://localhost:8080', description: 'Development'),
                ],
                contact: const Contact(name: 'API Support', email: 'support@test.com', url: 'https://support.test.com'),
                license: const License(name: 'MIT', url: 'https://mit.edu'),
              )
              .addBearerAuth()
              .addApiKeyAuth(headerName: 'X-API-Key')
              .addBasicAuth()
              .addTag('Users', description: 'User management operations')
              .addTag('Auth', description: 'Authentication endpoints')
              .addSchema<IntegrationUser>()
              .addSchema<CreateUserRequest>()
              .addSchema<ErrorResponse>()
              .addSchema<TokenResponse>()
              .generate();

      // Validate complete structure
      expect(spec['openapi'], '3.0.3');
      expect(spec['info']['title'], 'Integration Test API');
      expect(spec['info']['version'], '1.0.0');
      expect(spec['info']['description'], 'API for integration testing');
      expect(spec['info']['contact']['name'], 'API Support');
      expect(spec['info']['contact']['email'], 'support@test.com');
      expect(spec['info']['license']['name'], 'MIT');

      expect(spec['servers'].length, 2);
      expect(spec['servers'][0]['url'], 'https://api.test.com');

      expect(spec['tags'].length, 2);

      expect(spec['components']['securitySchemes'].length, 3);
      expect(spec['components']['securitySchemes']['bearerAuth'], isNotNull);
      expect(spec['components']['securitySchemes']['apiKey'], isNotNull);
      expect(spec['components']['securitySchemes']['basicAuth'], isNotNull);

      expect(spec['components']['schemas'].length, 4);
      expect(spec['components']['schemas']['IntegrationUser'], isNotNull);
      expect(spec['components']['schemas']['CreateUserRequest'], isNotNull);
      expect(spec['components']['schemas']['ErrorResponse'], isNotNull);
      expect(spec['components']['schemas']['TokenResponse'], isNotNull);
    });

    test('Volund alias works with all features', () {
      final spec = Volund(
        title: 'Volund API',
        version: '2.0.0',
        description: 'Built with Volund',
      ).addBearerAuth(format: 'JWT').addTag('Operations').addSchema<IntegrationUser>().generate();

      expect(spec['info']['title'], 'Volund API');
      expect(spec['components']['securitySchemes']['bearerAuth']['bearerFormat'], 'JWT');
      expect(spec['components']['schemas']['IntegrationUser'], isNotNull);
    });

    test('schema extraction preserves all property metadata', () {
      final spec = OpenApiGenerator(title: 'Test').addSchema<IntegrationUser>().generate();

      final userSchema = spec['components']['schemas']['IntegrationUser'];
      final properties = userSchema['properties'] as Map;

      // Check id property
      expect(properties['id']['type'], 'string');
      expect(properties['id']['format'], 'uuid');
      expect(properties['id']['description'], 'Unique identifier');

      // Check email property
      expect(properties['email']['format'], 'email');

      // Check name property
      expect(properties['name']['description'], 'Display name');
      expect(properties['name']['minLength'], 2);
      expect(properties['name']['maxLength'], 100);

      // Check role property
      expect(properties['role']['enum'], ['admin', 'user', 'guest']);

      // Check createdAt property
      expect(properties['createdAt']['format'], 'date-time');
      expect(properties['createdAt']['description'], 'Account creation date');

      // Check hashedPassword is hidden
      expect(properties.containsKey('hashedPassword'), false);

      // Check required fields
      final required = userSchema['required'] as List;
      expect(required, contains('id'));
      expect(required, contains('email'));
      expect(required, contains('name'));
      expect(required, contains('role'));
      expect(required, contains('createdAt'));
      expect(required, isNot(contains('hashedPassword')));
    });

    test('schema with write-only and nullable properties', () {
      final spec = OpenApiGenerator(title: 'Test').addSchema<CreateUserRequest>().generate();

      final schema = spec['components']['schemas']['CreateUserRequest'];
      final properties = schema['properties'] as Map;

      // Password should be write-only with format
      expect(properties['password']['format'], 'password');
      expect(properties['password']['minLength'], 8);
    });

    test('schema with optional nullable properties', () {
      final spec = OpenApiGenerator(title: 'Test').addSchema<ErrorResponse>().generate();

      final schema = spec['components']['schemas']['ErrorResponse'];
      final properties = schema['properties'] as Map;

      // Details should be nullable and optional
      expect(properties['details']['nullable'], true);

      // Required should not include details
      final required = schema['required'] as List;
      expect(required, isNot(contains('details')));
    });
  });

  group('Edge cases', () {
    test('empty routes map generates valid spec', () {
      final spec = OpenApiGenerator(title: 'Empty API').generate();
      expect(spec['paths'], isEmpty);
      expect(spec['openapi'], '3.0.3');
    });

    test('spec without components when none added', () {
      final spec = OpenApiGenerator(title: 'Minimal API').generate();
      expect(spec.containsKey('components'), false);
    });

    test('spec with only security schemes', () {
      final spec = OpenApiGenerator(title: 'Auth Only').addBearerAuth().generate();

      expect(spec['components']['securitySchemes'], isNotNull);
      expect(spec['components'].containsKey('schemas'), false);
    });

    test('spec with only schemas', () {
      final spec = OpenApiGenerator(title: 'Schema Only').addSchema<IntegrationUser>().generate();

      expect(spec['components']['schemas'], isNotNull);
      expect(spec['components'].containsKey('securitySchemes'), false);
    });

    test('multiple servers configuration', () {
      final spec = OpenApiGenerator(
        title: 'Multi-Server API',
        servers: [
          const Server(url: 'https://api.prod.example.com', description: 'Production'),
          const Server(url: 'https://api.staging.example.com', description: 'Staging'),
          const Server(url: 'https://api.dev.example.com', description: 'Development'),
          const Server(url: 'http://localhost:8080', description: 'Local'),
        ],
      ).generate();

      expect(spec['servers'].length, 4);
      expect(spec['servers'][0]['url'], 'https://api.prod.example.com');
      expect(spec['servers'][3]['description'], 'Local');
    });

    test('server without description', () {
      final spec = OpenApiGenerator(
        title: 'Test',
        servers: [const Server(url: 'https://api.example.com')],
      ).generate();

      expect(spec['servers'][0]['url'], 'https://api.example.com');
      expect(spec['servers'][0].containsKey('description'), false);
    });

    test('contact with only email', () {
      final spec = OpenApiGenerator(
        title: 'Test',
        contact: const Contact(email: 'api@example.com'),
      ).generate();

      expect(spec['info']['contact'], {'email': 'api@example.com'});
    });

    test('license with url', () {
      final spec = OpenApiGenerator(
        title: 'Test',
        license: const License(name: 'Apache 2.0', url: 'https://www.apache.org/licenses/LICENSE-2.0'),
      ).generate();

      expect(spec['info']['license']['name'], 'Apache 2.0');
      expect(spec['info']['license']['url'], 'https://www.apache.org/licenses/LICENSE-2.0');
    });

    test('duplicate tag names are deduplicated', () {
      final spec = OpenApiGenerator(title: 'Test')
          .addTag('Users', description: 'First description')
          .addTag('Users', description: 'Second description')
          .addTag('Users')
          .generate();

      final tags = spec['tags'] as List;
      expect(tags.length, 1);
      expect(tags[0]['name'], 'Users');
    });

    test('API key auth with query location', () {
      final spec = OpenApiGenerator(
        title: 'Test',
      ).addApiKeyAuth(name: 'queryApiKey', headerName: 'api_key', location: 'query').generate();

      final scheme = spec['components']['securitySchemes']['queryApiKey'];
      expect(scheme['in'], 'query');
      expect(scheme['name'], 'api_key');
    });

    test('multiple API key schemes with different names', () {
      final spec = OpenApiGenerator(title: 'Test')
          .addApiKeyAuth(name: 'apiKeyHeader', headerName: 'X-API-Key', location: 'header')
          .addApiKeyAuth(name: 'apiKeyQuery', headerName: 'api_key', location: 'query')
          .generate();

      expect(spec['components']['securitySchemes']['apiKeyHeader'], isNotNull);
      expect(spec['components']['securitySchemes']['apiKeyQuery'], isNotNull);
      expect(spec['components']['securitySchemes'].length, 2);
    });

    test('bearer auth with custom format', () {
      final spec = OpenApiGenerator(title: 'Test').addBearerAuth(format: 'Custom-Token').generate();

      expect(spec['components']['securitySchemes']['bearerAuth']['bearerFormat'], 'Custom-Token');
    });

    test('adding same schema type twice', () {
      final spec = OpenApiGenerator(title: 'Test').addSchema<IntegrationUser>().addSchema<IntegrationUser>().generate();

      // Should still only have one schema
      expect(spec['components']['schemas']['IntegrationUser'], isNotNull);
    });

    test('spec info excludes null description', () {
      final spec = OpenApiGenerator(title: 'No Description').generate();
      expect(spec['info'].containsKey('description'), false);
    });

    test('spec info includes non-null description', () {
      final spec = OpenApiGenerator(title: 'With Description', description: 'API Description').generate();
      expect(spec['info']['description'], 'API Description');
    });

    test('spec with version', () {
      final spec = OpenApiGenerator(title: 'Versioned API', version: '3.2.1').generate();
      expect(spec['info']['version'], '3.2.1');
    });

    test('default version is 1.0.0', () {
      final spec = OpenApiGenerator(title: 'Default Version').generate();
      expect(spec['info']['version'], '1.0.0');
    });
  });

  group('Schema type mappings', () {
    test('all basic Dart types map correctly', () {
      final spec = OpenApiGenerator(title: 'Test').addSchema<TypeMappingModel>().generate();

      final props = spec['components']['schemas']['TypeMappingModel']['properties'] as Map;

      expect(props['stringField']['type'], 'string');
      expect(props['intField']['type'], 'integer');
      expect(props['intField']['format'], 'int64');
      expect(props['doubleField']['type'], 'number');
      expect(props['doubleField']['format'], 'double');
      expect(props['boolField']['type'], 'boolean');
      expect(props['dateTimeField']['type'], 'string');
      expect(props['dateTimeField']['format'], 'date-time');
      expect(props['listField']['type'], 'array');
      expect(props['mapField']['type'], 'object');
    });
  });

  group('Fluent API chaining', () {
    test('all methods return the generator instance', () {
      final gen = OpenApiGenerator(title: 'Chain Test');

      expect(gen.addBearerAuth(), same(gen));
      expect(gen.addApiKeyAuth(), same(gen));
      expect(gen.addBasicAuth(), same(gen));
      expect(gen.addTag('Test'), same(gen));
      expect(gen.addSchema<IntegrationUser>(), same(gen));
      expect(gen.addSchemaType(IntegrationUser), same(gen));
    });

    test('complex chain produces correct spec', () {
      final spec = OpenApiGenerator(title: 'Chained API')
          .addBearerAuth()
          .addApiKeyAuth()
          .addTag('Users')
          .addTag('Auth')
          .addSchema<IntegrationUser>()
          .addSchema<ErrorResponse>()
          .generate();

      expect(spec['components']['securitySchemes'].length, 2);
      expect(spec['tags'].length, 2);
      expect(spec['components']['schemas'].length, 2);
    });
  });
}

// Additional test model for type mapping tests
@ApiSchema()
class TypeMappingModel {
  final String stringField;
  final int intField;
  final double doubleField;
  final bool boolField;
  final DateTime dateTimeField;
  final List<String> listField;
  final Map<String, dynamic> mapField;

  TypeMappingModel({
    required this.stringField,
    required this.intField,
    required this.doubleField,
    required this.boolField,
    required this.dateTimeField,
    required this.listField,
    required this.mapField,
  });
}
