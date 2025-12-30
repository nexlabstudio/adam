import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_openapi/dart_frog_openapi.dart';
import 'package:test/test.dart';

void main() {
  group('swaggerUI middleware', () {
    final testSpec = {
      'openapi': '3.0.3',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
    };

    test('serves Swagger UI at /docs', () async {
      final middleware = swaggerUI(spec: testSpec, title: 'Test API');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/docs')));
      final response = await handler(context);

      expect(response.statusCode, 200);
      expect(response.headers['Content-Type'], contains('text/html'));

      final body = await response.body();
      expect(body, contains('swagger-ui'));
      expect(body, contains('Test API'));
    });

    test('serves Swagger UI at /docs/', () async {
      final middleware = swaggerUI(spec: testSpec);
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/docs/')));
      final response = await handler(context);

      expect(response.statusCode, 200);
      expect(response.headers['Content-Type'], contains('text/html'));
    });

    test('serves spec at /openapi.json', () async {
      final middleware = swaggerUI(spec: testSpec);
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.json')));
      final response = await handler(context);

      expect(response.statusCode, 200);
      final body = await response.json();
      expect(body['openapi'], '3.0.3');
      expect(body['info']['title'], 'Test API');
    });

    test('serves YAML spec at /openapi.yaml', () async {
      final middleware = swaggerUI(spec: testSpec, specYamlPath: '/openapi.yaml');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.yaml')));
      final response = await handler(context);

      expect(response.statusCode, 200);
      expect(response.headers['Content-Type'], contains('text/yaml'));

      final body = await response.body();
      expect(body, contains('openapi:'));
      expect(body, contains('3.0.3'));
    });

    test('custom docsPath', () async {
      final middleware = swaggerUI(spec: testSpec, docsPath: '/swagger');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/swagger')));
      final response = await handler(context);

      expect(response.statusCode, 200);
      expect(response.headers['Content-Type'], contains('text/html'));
    });

    test('custom specPath', () async {
      final middleware = swaggerUI(spec: testSpec, specPath: '/api/spec.json');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/api/spec.json')));
      final response = await handler(context);

      expect(response.statusCode, 200);
      final body = await response.json();
      expect(body['openapi'], '3.0.3');
    });

    test('passes through non-docs requests', () async {
      final middleware = swaggerUI(spec: testSpec);
      final handler = middleware((_) async => Response.json(body: {'message': 'hello'}));

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/users')));
      final response = await handler(context);

      expect(response.statusCode, 200);
      final body = await response.json();
      expect(body['message'], 'hello');
    });

    test('handles OPTIONS preflight', () async {
      final middleware = swaggerUI(spec: testSpec);
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request('OPTIONS', Uri.parse('http://localhost/users')));
      final response = await handler(context);

      expect(response.statusCode, 204);
      expect(response.headers['Access-Control-Allow-Origin'], '*');
      expect(response.headers['Access-Control-Allow-Methods'], contains('GET'));
    });

    test('adds CORS headers to spec response', () async {
      final middleware = swaggerUI(spec: testSpec);
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.json')));
      final response = await handler(context);

      expect(response.headers['Access-Control-Allow-Origin'], '*');
    });

    test('tryItOutEnabled option', () async {
      final middleware = swaggerUI(spec: testSpec, tryItOutEnabled: false);
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/docs')));
      final response = await handler(context);

      final body = await response.body();
      expect(body, contains('tryItOutEnabled: false'));
    });

    test('displayRequestDuration option', () async {
      final middleware = swaggerUI(spec: testSpec, displayRequestDuration: false);
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/docs')));
      final response = await handler(context);

      final body = await response.body();
      expect(body, contains('displayRequestDuration: false'));
    });

    test('docExpansion option', () async {
      final middleware = swaggerUI(spec: testSpec, docExpansion: 'none');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/docs')));
      final response = await handler(context);

      final body = await response.body();
      expect(body, contains('docExpansion: "none"'));
    });

    test('filter option', () async {
      final middleware = swaggerUI(spec: testSpec, filter: true);
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/docs')));
      final response = await handler(context);

      final body = await response.body();
      expect(body, contains('filter: true'));
    });

    test('null specYamlPath disables YAML endpoint', () async {
      final middleware = swaggerUI(spec: testSpec, specYamlPath: null);
      final handler = middleware((_) async => Response.json(body: {'passthrough': true}));

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.yaml')));
      final response = await handler(context);

      final body = await response.json();
      expect(body['passthrough'], true);
    });
  });

  group('reDoc middleware', () {
    final testSpec = {
      'openapi': '3.0.3',
      'info': {'title': 'ReDoc Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
    };

    test('serves ReDoc UI at /docs', () async {
      final middleware = reDoc(spec: testSpec, title: 'ReDoc Test');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/docs')));
      final response = await handler(context);

      expect(response.statusCode, 200);
      expect(response.headers['Content-Type'], contains('text/html'));

      final body = await response.body();
      expect(body, contains('redoc'));
      expect(body, contains('ReDoc Test'));
    });

    test('serves spec at /openapi.json', () async {
      final middleware = reDoc(spec: testSpec);
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.json')));
      final response = await handler(context);

      expect(response.statusCode, 200);
      final body = await response.json();
      expect(body['info']['title'], 'ReDoc Test');
    });

    test('custom docsPath', () async {
      final middleware = reDoc(spec: testSpec, docsPath: '/redoc');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/redoc')));
      final response = await handler(context);

      expect(response.statusCode, 200);
    });

    test('handles OPTIONS preflight', () async {
      final middleware = reDoc(spec: testSpec);
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request('OPTIONS', Uri.parse('http://localhost/docs')));
      final response = await handler(context);

      expect(response.statusCode, 204);
      expect(response.headers['Access-Control-Allow-Origin'], '*');
    });

    test('adds CORS headers to passthrough responses', () async {
      final middleware = reDoc(spec: testSpec);
      final handler = middleware((_) async => Response.json(body: {'ok': true}));

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/users')));
      final response = await handler(context);

      expect(response.headers['Access-Control-Allow-Origin'], '*');
    });
  });

  group('scalar middleware', () {
    final testSpec = {
      'openapi': '3.0.3',
      'info': {'title': 'Scalar Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
    };

    test('serves Scalar UI at /docs', () async {
      final middleware = scalar(spec: testSpec, title: 'Scalar Test');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/docs')));
      final response = await handler(context);

      expect(response.statusCode, 200);
      expect(response.headers['Content-Type'], contains('text/html'));

      final body = await response.body();
      expect(body, contains('scalar'));
      expect(body, contains('Scalar Test'));
    });

    test('serves spec at /openapi.json', () async {
      final middleware = scalar(spec: testSpec);
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.json')));
      final response = await handler(context);

      expect(response.statusCode, 200);
      final body = await response.json();
      expect(body['info']['title'], 'Scalar Test');
    });

    test('custom docsPath', () async {
      final middleware = scalar(spec: testSpec, docsPath: '/scalar');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/scalar')));
      final response = await handler(context);

      expect(response.statusCode, 200);
    });

    test('handles OPTIONS preflight', () async {
      final middleware = scalar(spec: testSpec);
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request('OPTIONS', Uri.parse('http://localhost/docs')));
      final response = await handler(context);

      expect(response.statusCode, 204);
    });

    test('adds CORS headers to passthrough responses', () async {
      final middleware = scalar(spec: testSpec);
      final handler = middleware((_) async => Response.json(body: {'ok': true}));

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/users')));
      final response = await handler(context);

      expect(response.headers['Access-Control-Allow-Origin'], '*');
    });
  });

  group('YAML generation', () {
    test('converts simple spec to YAML', () async {
      final spec = {
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
      };

      final middleware = swaggerUI(spec: spec, specYamlPath: '/openapi.yaml');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.yaml')));
      final response = await handler(context);

      final yaml = await response.body();
      expect(yaml, contains('openapi: 3.0.3'));
      expect(yaml, contains('title: Test'));
      expect(yaml, contains('version: 1.0.0'));
    });

    test('handles nested objects', () async {
      final spec = {
        'openapi': '3.0.3',
        'info': {
          'title': 'Test',
          'version': '1.0.0',
          'contact': {'name': 'Support', 'email': 'support@example.com'},
        },
        'paths': <String, dynamic>{},
      };

      final middleware = swaggerUI(spec: spec, specYamlPath: '/openapi.yaml');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.yaml')));
      final response = await handler(context);

      final yaml = await response.body();
      expect(yaml, contains('contact:'));
      expect(yaml, contains('name: Support'));
      expect(yaml, contains('email: support@example.com'));
    });

    test('handles arrays', () async {
      final spec = {
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'servers': [
          {'url': 'http://localhost:8080', 'description': 'Dev'},
          {'url': 'https://api.example.com', 'description': 'Prod'},
        ],
        'paths': <String, dynamic>{},
      };

      final middleware = swaggerUI(spec: spec, specYamlPath: '/openapi.yaml');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.yaml')));
      final response = await handler(context);

      final yaml = await response.body();
      expect(yaml, contains('servers:'));
      expect(yaml, contains('"http://localhost:8080"'));
      expect(yaml, contains('description: Dev'));
    });

    test('handles empty objects as {}', () async {
      final spec = {
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
      };

      final middleware = swaggerUI(spec: spec, specYamlPath: '/openapi.yaml');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.yaml')));
      final response = await handler(context);

      final yaml = await response.body();
      expect(yaml, contains('paths: {}'));
    });

    test('handles empty arrays as []', () async {
      final spec = {
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'tags': <String>[],
        'paths': <String, dynamic>{},
      };

      final middleware = swaggerUI(spec: spec, specYamlPath: '/openapi.yaml');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.yaml')));
      final response = await handler(context);

      final yaml = await response.body();
      expect(yaml, contains('tags: []'));
    });

    test('quotes strings with special characters', () async {
      final spec = {
        'openapi': '3.0.3',
        'info': {
          'title': 'Test: API',
          'version': '1.0.0',
          'description': 'API with special chars: # and newlines\nand quotes "test"',
        },
        'paths': <String, dynamic>{},
      };

      final middleware = swaggerUI(spec: spec, specYamlPath: '/openapi.yaml');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.yaml')));
      final response = await handler(context);

      final yaml = await response.body();
      // Strings with : should be quoted
      expect(yaml, contains('"Test: API"'));
    });

    test('handles boolean values', () async {
      final spec = {
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': {
          '/test': {
            'get': {'deprecated': true, 'summary': 'Test endpoint'},
          },
        },
      };

      final middleware = swaggerUI(spec: spec, specYamlPath: '/openapi.yaml');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.yaml')));
      final response = await handler(context);

      final yaml = await response.body();
      expect(yaml, contains('deprecated: true'));
    });

    test('handles numeric values', () async {
      final spec = {
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': {
          '/test': {
            'get': {
              'responses': {
                '200': {'description': 'Success'},
                '404': {'description': 'Not found'},
              },
            },
          },
        },
      };

      final middleware = swaggerUI(spec: spec, specYamlPath: '/openapi.yaml');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.yaml')));
      final response = await handler(context);

      final yaml = await response.body();
      expect(yaml, contains('200:'));
      expect(yaml, contains('404:'));
    });

    test('handles empty string values', () async {
      final spec = {
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0', 'description': ''},
        'paths': <String, dynamic>{},
      };

      final middleware = swaggerUI(spec: spec, specYamlPath: '/openapi.yaml');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.yaml')));
      final response = await handler(context);

      final yaml = await response.body();
      expect(yaml, contains('description: ""'));
    });

    test('skips null values', () async {
      final spec = {
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0', 'description': null},
        'paths': <String, dynamic>{},
      };

      final middleware = swaggerUI(spec: spec, specYamlPath: '/openapi.yaml');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.yaml')));
      final response = await handler(context);

      final yaml = await response.body();
      // null values should be skipped
      expect(yaml, isNot(contains('description: null')));
    });

    test('handles arrays with primitive string values', () async {
      final spec = {
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'tags': ['users', 'posts', 'comments'],
        'paths': <String, dynamic>{},
      };

      final middleware = swaggerUI(spec: spec, specYamlPath: '/openapi.yaml');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.yaml')));
      final response = await handler(context);

      final yaml = await response.body();
      expect(yaml, contains('tags:'));
      expect(yaml, contains('  - users'));
      expect(yaml, contains('  - posts'));
      expect(yaml, contains('  - comments'));
    });

    test('handles arrays with primitive number values', () async {
      final spec = {
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'codes': [200, 201, 404, 500],
        'paths': <String, dynamic>{},
      };

      final middleware = swaggerUI(spec: spec, specYamlPath: '/openapi.yaml');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.yaml')));
      final response = await handler(context);

      final yaml = await response.body();
      expect(yaml, contains('codes:'));
      expect(yaml, contains('  - 200'));
      expect(yaml, contains('  - 404'));
    });

    test('handles arrays with boolean values', () async {
      final spec = {
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'flags': [true, false, true],
        'paths': <String, dynamic>{},
      };

      final middleware = swaggerUI(spec: spec, specYamlPath: '/openapi.yaml');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.yaml')));
      final response = await handler(context);

      final yaml = await response.body();
      expect(yaml, contains('flags:'));
      expect(yaml, contains('  - true'));
      expect(yaml, contains('  - false'));
    });

    test('handles arrays with null values', () async {
      final spec = {
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'values': ['a', null, 'b'],
        'paths': <String, dynamic>{},
      };

      final middleware = swaggerUI(spec: spec, specYamlPath: '/openapi.yaml');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.yaml')));
      final response = await handler(context);

      final yaml = await response.body();
      expect(yaml, contains('values:'));
      expect(yaml, contains('  - a'));
      expect(yaml, contains('  - null'));
      expect(yaml, contains('  - b'));
    });

    test('handles arrays with custom object types using toString', () async {
      final spec = {
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'custom': [_CustomType('test')],
        'paths': <String, dynamic>{},
      };

      final middleware = swaggerUI(spec: spec, specYamlPath: '/openapi.yaml');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.yaml')));
      final response = await handler(context);

      final yaml = await response.body();
      expect(yaml, contains('custom:'));
      expect(yaml, contains('CustomType(test)'));
    });
  });

  group('autoSwagger middleware', () {
    test('creates middleware with required parameters', () {
      final middleware = autoSwagger(title: 'Auto API');
      expect(middleware, isA<Middleware>());
    });

    test('serves Swagger UI at default /docs path', () async {
      final middleware = autoSwagger(title: 'Auto API');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/docs')));
      final response = await handler(context);

      expect(response.statusCode, 200);
      expect(response.headers['Content-Type'], contains('text/html'));

      final body = await response.body();
      expect(body, contains('swagger-ui'));
      expect(body, contains('Auto API'));
    });

    test('serves spec at default /openapi.json path', () async {
      final middleware = autoSwagger(title: 'Auto API', version: '2.0.0');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.json')));
      final response = await handler(context);

      expect(response.statusCode, 200);
      final body = await response.json();
      expect(body['openapi'], '3.0.3');
      expect(body['info']['title'], 'Auto API');
      expect(body['info']['version'], '2.0.0');
    });

    test('serves YAML spec at /openapi.yaml', () async {
      final middleware = autoSwagger(title: 'Auto API');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.yaml')));
      final response = await handler(context);

      expect(response.statusCode, 200);
      expect(response.headers['Content-Type'], contains('text/yaml'));
    });

    test('includes description', () async {
      final middleware = autoSwagger(title: 'Auto API', description: 'API Description');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.json')));
      final response = await handler(context);

      final body = await response.json();
      expect(body['info']['description'], 'API Description');
    });

    test('includes custom servers', () async {
      final middleware = autoSwagger(
        title: 'Auto API',
        servers: [const Server(url: 'https://api.example.com', description: 'Prod')],
      );
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.json')));
      final response = await handler(context);

      final body = await response.json();
      expect(body['servers'][0]['url'], 'https://api.example.com');
    });

    test('includes bearer auth by default', () async {
      final middleware = autoSwagger(title: 'Auto API');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.json')));
      final response = await handler(context);

      final body = await response.json();
      expect(body['components']['securitySchemes']['bearerAuth'], isNotNull);
    });

    test('excludes bearer auth when disabled', () async {
      final middleware = autoSwagger(title: 'Auto API', bearerAuth: false);
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.json')));
      final response = await handler(context);

      final body = await response.json();
      expect(body['components'], isNull);
    });

    test('includes API key auth when enabled', () async {
      final middleware = autoSwagger(
        title: 'Auto API',
        bearerAuth: false,
        apiKeyAuth: true,
        apiKeyHeader: 'X-Custom-Key',
      );
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.json')));
      final response = await handler(context);

      final body = await response.json();
      expect(body['components']['securitySchemes']['apiKey']['name'], 'X-Custom-Key');
    });

    test('custom docsPath', () async {
      final middleware = autoSwagger(title: 'Auto API', docsPath: '/swagger');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/swagger')));
      final response = await handler(context);

      expect(response.statusCode, 200);
    });

    test('custom specPath', () async {
      final middleware = autoSwagger(title: 'Auto API', specPath: '/api/spec');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/api/spec')));
      final response = await handler(context);

      expect(response.statusCode, 200);
      final body = await response.json();
      expect(body['openapi'], '3.0.3');
    });

    test('handles OPTIONS preflight', () async {
      final middleware = autoSwagger(title: 'Auto API');
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request('OPTIONS', Uri.parse('http://localhost/users')));
      final response = await handler(context);

      expect(response.statusCode, 204);
      expect(response.headers['Access-Control-Allow-Origin'], '*');
    });

    test('adds CORS headers to passthrough responses', () async {
      final middleware = autoSwagger(title: 'Auto API');
      final handler = middleware((_) async => Response.json(body: {'ok': true}));

      final context = _MockRequestContext(Request.get(Uri.parse('http://localhost/users')));
      final response = await handler(context);

      expect(response.headers['Access-Control-Allow-Origin'], '*');
    });

    test('caches spec after first request', () async {
      final middleware = autoSwagger(title: 'Cached API');
      final handler = middleware((_) async => Response());

      // First request generates the spec
      final context1 = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.json')));
      final response1 = await handler(context1);
      final body1 = await response1.json();

      // Second request should use cached spec
      final context2 = _MockRequestContext(Request.get(Uri.parse('http://localhost/openapi.json')));
      final response2 = await handler(context2);
      final body2 = await response2.json();

      expect(body1['info']['title'], body2['info']['title']);
    });
  });

  group('CORS headers', () {
    test('includes correct allowed methods', () async {
      final middleware = swaggerUI(spec: {'openapi': '3.0.3', 'info': {}, 'paths': {}});
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request('OPTIONS', Uri.parse('http://localhost/test')));
      final response = await handler(context);

      expect(response.headers['Access-Control-Allow-Methods'], contains('GET'));
      expect(response.headers['Access-Control-Allow-Methods'], contains('POST'));
      expect(response.headers['Access-Control-Allow-Methods'], contains('PUT'));
      expect(response.headers['Access-Control-Allow-Methods'], contains('DELETE'));
      expect(response.headers['Access-Control-Allow-Methods'], contains('PATCH'));
      expect(response.headers['Access-Control-Allow-Methods'], contains('OPTIONS'));
    });

    test('includes correct allowed headers', () async {
      final middleware = swaggerUI(spec: {'openapi': '3.0.3', 'info': {}, 'paths': {}});
      final handler = middleware((_) async => Response());

      final context = _MockRequestContext(Request('OPTIONS', Uri.parse('http://localhost/test')));
      final response = await handler(context);

      expect(response.headers['Access-Control-Allow-Headers'], contains('Origin'));
      expect(response.headers['Access-Control-Allow-Headers'], contains('Content-Type'));
      expect(response.headers['Access-Control-Allow-Headers'], contains('Authorization'));
      expect(response.headers['Access-Control-Allow-Headers'], contains('X-API-Key'));
    });
  });
}

/// Mock RequestContext for testing
class _MockRequestContext implements RequestContext {
  _MockRequestContext(this._request);

  final Request _request;
  final Map<Type, dynamic> _providers = {};

  @override
  Request get request => _request;

  @override
  Map<String, String> get mountedParams => {};

  @override
  T read<T>() {
    final value = _providers[T];
    if (value == null) {
      throw StateError('No provider found for $T');
    }
    return value as T;
  }

  @override
  RequestContext provide<T>(T Function() create) {
    _providers[T] = create();
    return this;
  }
}

/// Custom type for testing toString fallback in YAML generation
class _CustomType {
  _CustomType(this.value);
  final String value;

  @override
  String toString() => 'CustomType($value)';
}
