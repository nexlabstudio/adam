import 'package:dart_frog_openapi/dart_frog_openapi.dart';
import 'package:test/test.dart';

// Test models for schema extraction

@ApiSchema(description: 'Test user model')
class TestUser {
  @UuidProperty()
  final String id;

  @EmailProperty()
  final String email;

  @ApiProperty(description: 'Display name', minLength: 2, maxLength: 100)
  final String name;

  @ApiHidden()
  final String password;

  @ApiReadOnly()
  final DateTime createdAt;

  TestUser({
    required this.id,
    required this.email,
    required this.name,
    required this.password,
    required this.createdAt,
  });
}

@ApiSchema()
class SimpleModel {
  final String name;
  SimpleModel({required this.name});
}

@ApiSchema(name: 'CustomNameModel', description: 'Model with custom name')
class RenamedModel {
  final String value;
  RenamedModel({required this.value});
}

@ApiSchema(description: 'Full model with all property types')
class FullModel {
  @UuidProperty()
  final String id;

  @EmailProperty()
  final String email;

  @ApiProperty(minimum: 0, maximum: 150)
  final int age;

  @ApiHidden()
  final String secret;

  @ApiReadOnly()
  final DateTime created;

  @ApiWriteOnly()
  final String writeOnlyField;

  @ApiProperty(nullable: true, required: false)
  final String? optionalField;

  @ApiProperty(enumValues: ['active', 'inactive', 'pending'])
  final String status;

  @ApiProperty(pattern: r'^\d{3}-\d{4}$')
  final String phoneNumber;

  @ApiProperty(defaultValue: 'default')
  final String defaultField;

  FullModel({
    required this.id,
    required this.email,
    required this.age,
    required this.secret,
    required this.created,
    required this.writeOnlyField,
    this.optionalField,
    required this.status,
    required this.phoneNumber,
    required this.defaultField,
  });
}

@ApiSchema()
class EmptyModel {}

@ApiSchema()
class ModelWithTypes {
  final String stringField;
  final int intField;
  final double doubleField;
  final bool boolField;
  final DateTime dateTimeField;
  final List<String> listField;
  final Map<String, dynamic> mapField;

  ModelWithTypes({
    required this.stringField,
    required this.intField,
    required this.doubleField,
    required this.boolField,
    required this.dateTimeField,
    required this.listField,
    required this.mapField,
  });
}

void main() {
  group('OpenApiGenerator constructor', () {
    test('creates with required title', () {
      final gen = OpenApiGenerator(title: 'My API');
      expect(gen.title, 'My API');
      expect(gen.version, '1.0.0');
      expect(gen.description, isNull);
    });

    test('creates with all options', () {
      final gen = OpenApiGenerator(
        title: 'My API',
        version: '2.0.0',
        description: 'API Description',
        servers: [const Server(url: 'https://api.example.com')],
        contact: const Contact(name: 'Support'),
        license: const License(name: 'MIT'),
      );
      expect(gen.title, 'My API');
      expect(gen.version, '2.0.0');
      expect(gen.description, 'API Description');
      expect(gen.servers.length, 1);
      expect(gen.servers.first.url, 'https://api.example.com');
      expect(gen.contact?.name, 'Support');
      expect(gen.license?.name, 'MIT');
    });

    test('default server is localhost:8080', () {
      final gen = OpenApiGenerator(title: 'Test');
      expect(gen.servers.first.url, 'http://localhost:8080');
      expect(gen.servers.first.description, 'Development');
    });

    test('creates with multiple servers', () {
      final gen = OpenApiGenerator(
        title: 'Test',
        servers: [
          const Server(url: 'https://api.prod.com', description: 'Production'),
          const Server(url: 'https://api.staging.com', description: 'Staging'),
          const Server(url: 'http://localhost:8080', description: 'Development'),
        ],
      );
      expect(gen.servers.length, 3);
    });
  });

  group('Security methods', () {
    test('addBearerAuth adds bearer scheme', () {
      final gen = OpenApiGenerator(title: 'Test').addBearerAuth();
      final spec = gen.generate();
      expect(spec['components']['securitySchemes']['bearerAuth'], {
        'type': 'http',
        'scheme': 'bearer',
        'bearerFormat': 'JWT',
      });
    });

    test('addBearerAuth with custom format', () {
      final gen = OpenApiGenerator(title: 'Test').addBearerAuth(format: 'Token');
      final spec = gen.generate();
      expect(spec['components']['securitySchemes']['bearerAuth']['bearerFormat'], 'Token');
    });

    test('addApiKeyAuth adds apiKey scheme', () {
      final gen = OpenApiGenerator(title: 'Test').addApiKeyAuth(headerName: 'X-API-Key');
      final spec = gen.generate();
      expect(spec['components']['securitySchemes']['apiKey'], {'type': 'apiKey', 'in': 'header', 'name': 'X-API-Key'});
    });

    test('addApiKeyAuth with custom name', () {
      final gen = OpenApiGenerator(title: 'Test').addApiKeyAuth(name: 'customKey', headerName: 'X-Custom-Key');
      final spec = gen.generate();
      expect(spec['components']['securitySchemes']['customKey'], isNotNull);
      expect(spec['components']['securitySchemes']['customKey']['name'], 'X-Custom-Key');
    });

    test('addApiKeyAuth with query location', () {
      final gen = OpenApiGenerator(
        title: 'Test',
      ).addApiKeyAuth(name: 'queryKey', headerName: 'api_key', location: 'query');
      final spec = gen.generate();
      expect(spec['components']['securitySchemes']['queryKey']['in'], 'query');
    });

    test('addBasicAuth adds basic scheme', () {
      final gen = OpenApiGenerator(title: 'Test').addBasicAuth();
      final spec = gen.generate();
      expect(spec['components']['securitySchemes']['basicAuth'], {'type': 'http', 'scheme': 'basic'});
    });

    test('multiple security schemes', () {
      final gen = OpenApiGenerator(title: 'Test').addBearerAuth().addApiKeyAuth().addBasicAuth();
      final spec = gen.generate();
      expect(spec['components']['securitySchemes'].length, 3);
      expect(spec['components']['securitySchemes']['bearerAuth'], isNotNull);
      expect(spec['components']['securitySchemes']['apiKey'], isNotNull);
      expect(spec['components']['securitySchemes']['basicAuth'], isNotNull);
    });
  });

  group('Tag methods', () {
    test('addTag adds tag', () {
      final gen = OpenApiGenerator(title: 'Test').addTag('Users');
      final spec = gen.generate();
      expect(spec['tags'], [
        {'name': 'Users'},
      ]);
    });

    test('addTag with description', () {
      final gen = OpenApiGenerator(title: 'Test').addTag('Users', description: 'User management');
      final spec = gen.generate();
      expect(spec['tags'], [
        {'name': 'Users', 'description': 'User management'},
      ]);
    });

    test('multiple tags', () {
      final gen = OpenApiGenerator(
        title: 'Test',
      ).addTag('Users').addTag('Posts').addTag('Comments', description: 'Comment operations');
      final spec = gen.generate();
      expect(spec['tags'].length, 3);
    });

    test('duplicate tags are deduplicated', () {
      final gen = OpenApiGenerator(title: 'Test').addTag('Users').addTag('Users');
      final spec = gen.generate();
      expect(spec['tags'].length, 1);
    });
  });

  group('Schema methods', () {
    test('addSchema extracts class properties', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<TestUser>();
      final spec = gen.generate();
      expect(spec['components']['schemas']['TestUser'], isNotNull);
      expect(spec['components']['schemas']['TestUser']['type'], 'object');
    });

    test('addSchema includes description from annotation', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<TestUser>();
      final spec = gen.generate();
      expect(spec['components']['schemas']['TestUser']['description'], 'Test user model');
    });

    test('addSchemaType with Type reference', () {
      final gen = OpenApiGenerator(title: 'Test').addSchemaType(TestUser);
      final spec = gen.generate();
      expect(spec['components']['schemas']['TestUser'], isNotNull);
    });

    test('addSchema for simple model', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<SimpleModel>();
      final spec = gen.generate();
      expect(spec['components']['schemas']['SimpleModel'], isNotNull);
      expect(spec['components']['schemas']['SimpleModel']['properties']['name'], isNotNull);
    });

    test('addSchema respects custom name from annotation', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<RenamedModel>();
      final spec = gen.generate();
      expect(spec['components']['schemas']['CustomNameModel'], isNotNull);
      expect(spec['components']['schemas']['CustomNameModel']['description'], 'Model with custom name');
    });

    test('addSchema excludes @ApiHidden properties', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<TestUser>();
      final spec = gen.generate();
      final properties = spec['components']['schemas']['TestUser']['properties'] as Map;
      expect(properties.containsKey('password'), false);
    });

    test('addSchema marks @ApiReadOnly properties', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<TestUser>();
      final spec = gen.generate();
      final properties = spec['components']['schemas']['TestUser']['properties'] as Map;
      expect(properties['createdAt']['readOnly'], true);
    });

    test('addSchema handles empty model', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<EmptyModel>();
      final spec = gen.generate();
      expect(spec['components']['schemas']['EmptyModel']['type'], 'object');
    });

    test('multiple schemas', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<TestUser>().addSchema<SimpleModel>();
      final spec = gen.generate();
      expect(spec['components']['schemas'].length, 2);
    });
  });

  group('Schema property types', () {
    test('extracts string type', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<ModelWithTypes>();
      final spec = gen.generate();
      final props = spec['components']['schemas']['ModelWithTypes']['properties'] as Map;
      expect(props['stringField']['type'], 'string');
    });

    test('extracts integer type with int64 format', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<ModelWithTypes>();
      final spec = gen.generate();
      final props = spec['components']['schemas']['ModelWithTypes']['properties'] as Map;
      expect(props['intField']['type'], 'integer');
      expect(props['intField']['format'], 'int64');
    });

    test('extracts double type with format', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<ModelWithTypes>();
      final spec = gen.generate();
      final props = spec['components']['schemas']['ModelWithTypes']['properties'] as Map;
      expect(props['doubleField']['type'], 'number');
      expect(props['doubleField']['format'], 'double');
    });

    test('extracts boolean type', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<ModelWithTypes>();
      final spec = gen.generate();
      final props = spec['components']['schemas']['ModelWithTypes']['properties'] as Map;
      expect(props['boolField']['type'], 'boolean');
    });

    test('extracts DateTime as string with date-time format', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<ModelWithTypes>();
      final spec = gen.generate();
      final props = spec['components']['schemas']['ModelWithTypes']['properties'] as Map;
      expect(props['dateTimeField']['type'], 'string');
      expect(props['dateTimeField']['format'], 'date-time');
    });

    test('extracts List as array', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<ModelWithTypes>();
      final spec = gen.generate();
      final props = spec['components']['schemas']['ModelWithTypes']['properties'] as Map;
      expect(props['listField']['type'], 'array');
    });

    test('extracts Map as object', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<ModelWithTypes>();
      final spec = gen.generate();
      final props = spec['components']['schemas']['ModelWithTypes']['properties'] as Map;
      expect(props['mapField']['type'], 'object');
    });
  });

  group('Schema property annotations', () {
    test('extracts UuidProperty format', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<TestUser>();
      final spec = gen.generate();
      final props = spec['components']['schemas']['TestUser']['properties'] as Map;
      expect(props['id']['format'], 'uuid');
    });

    test('extracts EmailProperty format', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<TestUser>();
      final spec = gen.generate();
      final props = spec['components']['schemas']['TestUser']['properties'] as Map;
      expect(props['email']['format'], 'email');
    });

    test('extracts ApiProperty constraints', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<TestUser>();
      final spec = gen.generate();
      final props = spec['components']['schemas']['TestUser']['properties'] as Map;
      expect(props['name']['description'], 'Display name');
      expect(props['name']['minLength'], 2);
      expect(props['name']['maxLength'], 100);
    });

    test('extracts numeric constraints', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<FullModel>();
      final spec = gen.generate();
      final props = spec['components']['schemas']['FullModel']['properties'] as Map;
      expect(props['age']['minimum'], 0);
      expect(props['age']['maximum'], 150);
    });

    test('extracts enum values', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<FullModel>();
      final spec = gen.generate();
      final props = spec['components']['schemas']['FullModel']['properties'] as Map;
      expect(props['status']['enum'], ['active', 'inactive', 'pending']);
    });

    test('extracts pattern', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<FullModel>();
      final spec = gen.generate();
      final props = spec['components']['schemas']['FullModel']['properties'] as Map;
      expect(props['phoneNumber']['pattern'], r'^\d{3}-\d{4}$');
    });

    test('extracts default value', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<FullModel>();
      final spec = gen.generate();
      final props = spec['components']['schemas']['FullModel']['properties'] as Map;
      expect(props['defaultField']['default'], 'default');
    });

    test('extracts nullable property', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<FullModel>();
      final spec = gen.generate();
      final props = spec['components']['schemas']['FullModel']['properties'] as Map;
      expect(props['optionalField']['nullable'], true);
    });

    test('extracts writeOnly property', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<FullModel>();
      final spec = gen.generate();
      final props = spec['components']['schemas']['FullModel']['properties'] as Map;
      expect(props['writeOnlyField']['writeOnly'], true);
    });
  });

  group('Schema required properties', () {
    test('includes required properties list', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<TestUser>();
      final spec = gen.generate();
      final schema = spec['components']['schemas']['TestUser'] as Map;
      expect(schema['required'], isNotNull);
      expect(schema['required'], contains('id'));
      expect(schema['required'], contains('email'));
      expect(schema['required'], contains('name'));
    });

    test('excludes optional properties from required', () {
      final gen = OpenApiGenerator(title: 'Test').addSchema<FullModel>();
      final spec = gen.generate();
      final schema = spec['components']['schemas']['FullModel'] as Map;
      expect(schema['required'], isNot(contains('optionalField')));
    });
  });

  group('generate() method', () {
    test('generates valid OpenAPI 3.0.3 structure', () {
      final spec = OpenApiGenerator(title: 'Test API').generate();
      expect(spec['openapi'], '3.0.3');
      expect(spec['info']['title'], 'Test API');
      expect(spec['info']['version'], '1.0.0');
      expect(spec['paths'], isA<Map>());
    });

    test('includes description when provided', () {
      final spec = OpenApiGenerator(title: 'Test', description: 'API Description').generate();
      expect(spec['info']['description'], 'API Description');
    });

    test('excludes description when null', () {
      final spec = OpenApiGenerator(title: 'Test').generate();
      expect(spec['info'].containsKey('description'), false);
    });

    test('includes contact when provided', () {
      final spec = OpenApiGenerator(
        title: 'Test',
        contact: const Contact(name: 'Support'),
      ).generate();
      expect(spec['info']['contact'], {'name': 'Support'});
    });

    test('excludes empty contact', () {
      final spec = OpenApiGenerator(title: 'Test', contact: const Contact()).generate();
      expect(spec['info'].containsKey('contact'), false);
    });

    test('includes contact with all fields', () {
      final spec = OpenApiGenerator(
        title: 'Test',
        contact: const Contact(name: 'Support', email: 'support@example.com', url: 'https://example.com'),
      ).generate();
      expect(spec['info']['contact'], {
        'name': 'Support',
        'email': 'support@example.com',
        'url': 'https://example.com',
      });
    });

    test('includes license when provided', () {
      final spec = OpenApiGenerator(
        title: 'Test',
        license: const License(name: 'MIT'),
      ).generate();
      expect(spec['info']['license'], {'name': 'MIT'});
    });

    test('includes license with url', () {
      final spec = OpenApiGenerator(
        title: 'Test',
        license: const License(name: 'MIT', url: 'https://mit.edu'),
      ).generate();
      expect(spec['info']['license'], {'name': 'MIT', 'url': 'https://mit.edu'});
    });

    test('includes servers', () {
      final spec = OpenApiGenerator(
        title: 'Test',
        servers: [const Server(url: 'https://api.example.com', description: 'Prod')],
      ).generate();
      expect(spec['servers'], [
        {'url': 'https://api.example.com', 'description': 'Prod'},
      ]);
    });

    test('paths is empty map when no routes', () {
      final spec = OpenApiGenerator(title: 'Test').generate();
      expect(spec['paths'], isEmpty);
    });

    test('components only included when non-empty', () {
      final spec = OpenApiGenerator(title: 'Test').generate();
      expect(spec.containsKey('components'), false);
    });

    test('components included when security schemes added', () {
      final spec = OpenApiGenerator(title: 'Test').addBearerAuth().generate();
      expect(spec.containsKey('components'), true);
      expect(spec['components']['securitySchemes'], isNotNull);
    });

    test('components included when schemas added', () {
      final spec = OpenApiGenerator(title: 'Test').addSchema<SimpleModel>().generate();
      expect(spec.containsKey('components'), true);
      expect(spec['components']['schemas'], isNotNull);
    });
  });

  group('Volund alias', () {
    test('Volund is alias for OpenApiGenerator', () {
      final gen = Volund(title: 'Test');
      expect(gen, isA<OpenApiGenerator>());
    });

    test('Volund works identically to OpenApiGenerator', () {
      final spec = Volund(title: 'Test API').generate();
      expect(spec['info']['title'], 'Test API');
      expect(spec['openapi'], '3.0.3');
    });

    test('Volund supports all builder methods', () {
      final spec = Volund(
        title: 'Volund API',
        version: '1.0.0',
      ).addBearerAuth().addTag('Users').addSchema<SimpleModel>().generate();

      expect(spec['info']['title'], 'Volund API');
      expect(spec['components']['securitySchemes']['bearerAuth'], isNotNull);
      expect(spec['tags'], isNotNull);
      expect(spec['components']['schemas']['SimpleModel'], isNotNull);
    });
  });

  group('Fluent API', () {
    test('methods return generator for chaining', () {
      final gen = OpenApiGenerator(title: 'Test');

      expect(gen.addBearerAuth(), same(gen));
      expect(gen.addApiKeyAuth(), same(gen));
      expect(gen.addBasicAuth(), same(gen));
      expect(gen.addTag('Users'), same(gen));
      expect(gen.addSchema<SimpleModel>(), same(gen));
      expect(gen.addSchemaType(SimpleModel), same(gen));
    });

    test('complex chained configuration', () {
      final spec =
          OpenApiGenerator(
                title: 'Complex API',
                version: '2.0.0',
                description: 'A complex API',
                servers: [const Server(url: 'https://api.example.com', description: 'Production')],
                contact: const Contact(name: 'API Support', email: 'api@example.com'),
                license: const License(name: 'MIT'),
              )
              .addBearerAuth()
              .addApiKeyAuth(headerName: 'X-API-Key')
              .addBasicAuth()
              .addTag('Users', description: 'User operations')
              .addTag('Posts', description: 'Post operations')
              .addSchema<TestUser>()
              .addSchema<SimpleModel>()
              .generate();

      expect(spec['info']['title'], 'Complex API');
      expect(spec['info']['version'], '2.0.0');
      expect(spec['info']['description'], 'A complex API');
      expect(spec['info']['contact']['name'], 'API Support');
      expect(spec['info']['license']['name'], 'MIT');
      expect(spec['servers'].length, 1);
      expect(spec['tags'].length, 2);
      expect(spec['components']['securitySchemes'].length, 3);
      expect(spec['components']['schemas'].length, 2);
    });
  });
}
