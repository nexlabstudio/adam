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

  group('addRoute() method', () {
    test('extracts @Api tag from handler', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/users', _usersHandler);
      final spec = gen.generate();
      expect(spec['tags'], isNotNull);
      expect(spec['tags'].any((t) => t['name'] == 'Users' && t['description'] == 'User management'), true);
    });

    test('extracts @Get operation', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/users', _getUsersHandler);
      final spec = gen.generate();
      expect(spec['paths']['/users']['get'], isNotNull);
      expect(spec['paths']['/users']['get']['summary'], 'List all users');
    });

    test('extracts @Post operation', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/users', _postUsersHandler);
      final spec = gen.generate();
      expect(spec['paths']['/users']['post'], isNotNull);
      expect(spec['paths']['/users']['post']['summary'], 'Create user');
    });

    test('extracts @Put operation', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/users/{id}', _putUserHandler);
      final spec = gen.generate();
      expect(spec['paths']['/users/{id}']['put'], isNotNull);
      expect(spec['paths']['/users/{id}']['put']['summary'], 'Update user');
    });

    test('extracts @Delete operation', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/users/{id}', _deleteUserHandler);
      final spec = gen.generate();
      expect(spec['paths']['/users/{id}']['delete'], isNotNull);
      expect(spec['paths']['/users/{id}']['delete']['summary'], 'Delete user');
    });

    test('extracts @Patch operation', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/users/{id}', _patchUserHandler);
      final spec = gen.generate();
      expect(spec['paths']['/users/{id}']['patch'], isNotNull);
      expect(spec['paths']['/users/{id}']['patch']['summary'], 'Patch user');
    });

    test('extracts operation description and operationId', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/users', _getUsersHandler);
      final spec = gen.generate();
      expect(spec['paths']['/users']['get']['description'], 'Returns a paginated list of users');
      expect(spec['paths']['/users']['get']['operationId'], 'listUsers');
    });

    test('extracts deprecated flag', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/old', _deprecatedHandler);
      final spec = gen.generate();
      expect(spec['paths']['/old']['get']['deprecated'], true);
    });

    test('extracts custom tags from operation', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/mixed', _multiTagHandler);
      final spec = gen.generate();
      expect(spec['paths']['/mixed']['get']['tags'], ['Admin', 'Reports']);
    });

    test('extracts @QueryParam', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/search', _searchHandler);
      final spec = gen.generate();
      final params = spec['paths']['/search']['get']['parameters'] as List;
      final queryParam = params.firstWhere((p) => p['name'] == 'q');
      expect(queryParam['in'], 'query');
      expect(queryParam['description'], 'Search query');
      expect(queryParam['required'], true);
    });

    test('extracts @QueryParam with all options', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/filter', _filterHandler);
      final spec = gen.generate();
      final params = spec['paths']['/filter']['get']['parameters'] as List;
      final pageParam = params.firstWhere((p) => p['name'] == 'page');
      expect(pageParam['schema']['type'], 'integer');
      expect(pageParam['schema']['default'], 1);
      expect(pageParam['example'], 1);
    });

    test('extracts @QueryParam with enum values', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/filter', _filterHandler);
      final spec = gen.generate();
      final params = spec['paths']['/filter']['get']['parameters'] as List;
      final sortParam = params.firstWhere((p) => p['name'] == 'sort');
      expect(sortParam['schema']['enum'], ['asc', 'desc']);
    });

    test('extracts @HeaderParam', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/auth', _authHandler);
      final spec = gen.generate();
      final params = spec['paths']['/auth']['get']['parameters'] as List;
      final headerParam = params.firstWhere((p) => p['name'] == 'X-Request-Id');
      expect(headerParam['in'], 'header');
      expect(headerParam['description'], 'Request tracking ID');
      expect(headerParam['required'], true);
    });

    test('extracts @PathParam', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/users/{id}', _pathParamHandler);
      final spec = gen.generate();
      final params = spec['paths']['/users/{id}']['get']['parameters'] as List;
      final pathParam = params.firstWhere((p) => p['name'] == 'id');
      expect(pathParam['in'], 'path');
      expect(pathParam['required'], true);
      expect(pathParam['description'], 'User ID');
      expect(pathParam['schema']['format'], 'uuid');
    });

    test('extracts @Body annotation', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/users', _bodyHandler);
      final spec = gen.generate();
      final requestBody = spec['paths']['/users']['post']['requestBody'];
      expect(requestBody['required'], true);
      expect(requestBody['description'], 'User data');
      expect(requestBody['content']['application/json']['schema'][r'$ref'], contains('SimpleModel'));
    });

    test('extracts @ApiResponse', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/users', _responseHandler);
      final spec = gen.generate();
      final responses = spec['paths']['/users']['get']['responses'];
      expect(responses['200']['description'], 'Success');
      expect(responses['404']['description'], 'Not found');
    });

    test('extracts response with schema', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/users', _responseWithSchemaHandler);
      final spec = gen.generate();
      final responses = spec['paths']['/users']['get']['responses'];
      expect(responses['200']['content']['application/json']['schema'][r'$ref'], contains('SimpleModel'));
    });

    test('extracts array response', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/users', _arrayResponseHandler);
      final spec = gen.generate();
      final schema = spec['paths']['/users']['get']['responses']['200']['content']['application/json']['schema'];
      expect(schema['type'], 'array');
      expect(schema['items'][r'$ref'], contains('SimpleModel'));
    });

    test('extracts response example', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/example', _responseExampleHandler);
      final spec = gen.generate();
      final content = spec['paths']['/example']['get']['responses']['200']['content']['application/json'];
      expect(content['example'], {'name': 'Test'});
    });

    test('extracts @Security annotation', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/secure', _secureHandler);
      final spec = gen.generate();
      expect(spec['paths']['/secure']['get']['security'], [
        {'bearerAuth': []},
      ]);
    });

    test('extracts @Security with scopes', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/admin', _scopedSecurityHandler);
      final spec = gen.generate();
      expect(spec['paths']['/admin']['get']['security'], [
        {
          'oauth2': ['admin:read', 'admin:write'],
        },
      ]);
    });

    test('extracts @Public annotation', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/public', _publicHandler);
      final spec = gen.generate();
      expect(spec['paths']['/public']['get']['security'], isEmpty);
    });

    test('excludes @ApiExclude handlers', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/excluded', _excludedHandler);
      final spec = gen.generate();
      expect(spec['paths'].containsKey('/excluded'), false);
    });

    test('creates default response when none specified', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/default', _noResponseHandler);
      final spec = gen.generate();
      expect(spec['paths']['/default']['get']['responses']['200']['description'], 'Successful response');
    });

    test('auto-adds schema from response type', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/auto', _autoSchemaHandler);
      final spec = gen.generate();
      expect(spec['components']['schemas']['SimpleModel'], isNotNull);
    });

    test('returns same generator for chaining', () {
      final gen = OpenApiGenerator(title: 'Test');
      expect(gen.addRoute('/test', _getUsersHandler), same(gen));
    });

    test('creates default GET when handler has @ApiResponse but no HTTP method', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/default', _defaultGetHandler);
      final spec = gen.generate();
      expect(spec['paths']['/default']['get'], isNotNull);
      expect(spec['paths']['/default']['get']['responses']['200']['description'], 'Default response');
    });

    test('creates default GET when handler has @QueryParam but no HTTP method', () {
      final gen = OpenApiGenerator(title: 'Test').addRoute('/query', _queryOnlyHandler);
      final spec = gen.generate();
      expect(spec['paths']['/query']['get'], isNotNull);
      final params = spec['paths']['/query']['get']['parameters'] as List;
      expect(params.any((p) => p['name'] == 'search'), true);
    });
  });
}

@Api(tag: 'Users', description: 'User management')
@Get(summary: 'List users')
void _usersHandler() {}

@Get(summary: 'List all users', description: 'Returns a paginated list of users', operationId: 'listUsers')
void _getUsersHandler() {}

@Post(summary: 'Create user')
void _postUsersHandler() {}

@Put(summary: 'Update user')
void _putUserHandler() {}

@Delete(summary: 'Delete user')
void _deleteUserHandler() {}

@Patch(summary: 'Patch user')
void _patchUserHandler() {}

@Get(summary: 'Old endpoint', deprecated: true)
void _deprecatedHandler() {}

@Get(summary: 'Multi tag', tags: ['Admin', 'Reports'])
void _multiTagHandler() {}

@Get(summary: 'Search')
@QueryParam('q', description: 'Search query', required: true)
void _searchHandler() {}

@Get(summary: 'Filter')
@QueryParam('page', type: 'integer', defaultValue: 1, example: 1)
@QueryParam('sort', enumValues: ['asc', 'desc'])
void _filterHandler() {}

@Get(summary: 'Auth check')
@HeaderParam('X-Request-Id', description: 'Request tracking ID', required: true)
void _authHandler() {}

@Get(summary: 'Get user')
@PathParam('id', description: 'User ID', format: 'uuid')
void _pathParamHandler() {}

@Post(summary: 'Create user')
@Body(schema: SimpleModel, description: 'User data')
void _bodyHandler() {}

@Get(summary: 'Get users')
@ApiResponse(200, description: 'Success')
@ApiResponse(404, description: 'Not found')
void _responseHandler() {}

@Get(summary: 'Get user')
@ApiResponse(200, description: 'Success', schema: SimpleModel)
void _responseWithSchemaHandler() {}

@Get(summary: 'List users')
@ApiResponse(200, description: 'Success', schema: SimpleModel, isArray: true)
void _arrayResponseHandler() {}

@Get(summary: 'Example')
@ApiResponse(200, description: 'Success', schema: SimpleModel, example: {'name': 'Test'})
void _responseExampleHandler() {}

@Get(summary: 'Secure')
@Security('bearerAuth')
void _secureHandler() {}

@Get(summary: 'Admin')
@Security('oauth2', scopes: ['admin:read', 'admin:write'])
void _scopedSecurityHandler() {}

@Get(summary: 'Public')
@Public()
void _publicHandler() {}

@ApiExclude()
@Get(summary: 'Excluded')
void _excludedHandler() {}

@Get(summary: 'No response defined')
void _noResponseHandler() {}

@Get(summary: 'Auto schema')
@ApiResponse(200, description: 'Success', schema: SimpleModel)
void _autoSchemaHandler() {}

// Handler with only @ApiResponse but no HTTP method annotation (for default GET operation)
@ApiResponse(200, description: 'Default response', schema: SimpleModel)
@QueryParam('filter', description: 'Filter query')
void _defaultGetHandler() {}

// Handler with only @QueryParam but no HTTP method annotation
@QueryParam('search', description: 'Search term', required: true)
void _queryOnlyHandler() {}
