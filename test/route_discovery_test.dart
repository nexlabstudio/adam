// Tests for route discovery functionality
// ignore_for_file: unused_import

import 'package:dart_frog_openapi/dart_frog_openapi.dart';
import 'package:test/test.dart';

// Import mock routes to make them available for reflection
import 'fixtures/routes/index.dart' as root_route;
import 'fixtures/routes/users/index.dart' as users_route;
import 'fixtures/routes/users/[id].dart' as user_by_id_route;
import 'fixtures/routes/posts/[postId]/comments/[commentId].dart' as nested_route;
import 'fixtures/routes/auth/login.dart' as auth_route;
import 'fixtures/routes/_middleware.dart' as middleware;
import 'fixtures/routes/simple.dart' as simple_route;
import 'fixtures/routes/items.dart' as items_route;
import 'fixtures/routes/products/[productId].dart' as product_route;
import 'fixtures/routes/orders/[orderId].dart' as order_route;

void main() {
  // Force imports to be retained for dart:mirrors
  setUpAll(() {
    root_route.onRequest;
    users_route.onRequest;
    user_by_id_route.onRequest;
    nested_route.onRequest;
    auth_route.onRequest;
    middleware.middleware;
    simple_route.onRequest;
    items_route.onRequest;
    product_route.onRequest;
    order_route.onRequest;
  });

  group('discoverRoutes()', () {
    test('discovers routes from loaded libraries', () {
      final routes = discoverRoutes();
      expect(routes, isNotEmpty);
    });

    test('routes have path keys starting with /', () {
      final routes = discoverRoutes();
      for (final path in routes.keys) {
        expect(path.startsWith('/'), isTrue, reason: 'Path $path should start with /');
      }
    });

    test('skips middleware files', () {
      final routes = discoverRoutes();
      final middlewareRoutes = routes.keys.where((k) => k.contains('_middleware'));
      expect(middlewareRoutes, isEmpty);
    });
  });

  group('discoverRoutesWithParams()', () {
    test('works without parameter renaming', () {
      final routes1 = discoverRoutes();
      final routes2 = discoverRoutesWithParams({});
      expect(routes2.length, routes1.length);
    });

    test('works with parameter renaming map', () {
      final routes = discoverRoutesWithParams({'users/[id]': 'userId'});
      expect(routes, isNotEmpty);
    });
  });

  group('Route discovery integration with OpenApiGenerator', () {
    late Map<String, dynamic> spec;

    setUpAll(() {
      final routes = discoverRoutes();
      spec = OpenApiGenerator(title: 'Test API').addBearerAuth().addRoutes(routes).generate();
    });

    test('generates non-empty paths', () {
      expect(spec['paths'], isNotEmpty);
    });

    test('all paths start with /', () {
      final paths = spec['paths'] as Map;
      for (final path in paths.keys) {
        expect(path.toString().startsWith('/'), isTrue);
      }
    });

    test('extracts @Api tag into tags list', () {
      final tags = spec['tags'] as List?;
      expect(tags, isNotNull);
      expect(tags, isNotEmpty);

      final tagNames = tags?.map((t) => t['name']).toList();
      expect(tagNames, anyOf(contains('Users'), contains('Health'), contains('Auth')));
    });

    test('extracts HTTP methods (get, post, put, delete)', () {
      final paths = spec['paths'] as Map;
      final allMethods = <String>{};

      for (final pathItem in paths.values) {
        if (pathItem is Map) {
          allMethods.addAll(
            pathItem.keys.where((k) => ['get', 'post', 'put', 'delete', 'patch'].contains(k)).cast<String>(),
          );
        }
      }

      expect(allMethods, isNotEmpty);
    });

    test('extracts operation summaries', () {
      final paths = spec['paths'] as Map;
      final hasSummary = paths.values.any((pathItem) {
        if (pathItem is Map) {
          return pathItem.values.any((op) => op is Map && op['summary'] != null);
        }
        return false;
      });
      expect(hasSummary, isTrue);
    });

    test('extracts operationId', () {
      final paths = spec['paths'] as Map;
      final hasOperationId = paths.values.any((pathItem) {
        if (pathItem is Map) {
          return pathItem.values.any((op) => op is Map && op['operationId'] != null);
        }
        return false;
      });
      expect(hasOperationId, isTrue);
    });
  });

  group('Path parameter extraction', () {
    late Map<String, dynamic> spec;

    setUpAll(() {
      final routes = discoverRoutes();
      spec = OpenApiGenerator(title: 'Test API').addRoutes(routes).generate();
    });

    test('converts [id] to {id} in path', () {
      final paths = spec['paths'] as Map;
      final pathsWithParams = paths.keys.where((p) => p.toString().contains('{'));
      expect(pathsWithParams, isNotEmpty);

      // Should not contain [id] format
      for (final path in paths.keys) {
        expect(path.toString().contains('['), isFalse);
        expect(path.toString().contains(']'), isFalse);
      }
    });

    test('path params are marked as required', () {
      final paths = spec['paths'] as Map;

      for (final pathItem in paths.values) {
        if (pathItem is Map) {
          for (final operation in pathItem.values) {
            if (operation is Map && operation['parameters'] is List) {
              final params = operation['parameters'] as List;
              for (final param in params) {
                if (param is Map && param['in'] == 'path') {
                  expect(param['required'], isTrue);
                }
              }
            }
          }
        }
      }
    });

    test('extracts @PathParam description', () {
      final paths = spec['paths'] as Map;
      final hasPathParamWithDescription = paths.values.any((pathItem) {
        if (pathItem is Map) {
          return pathItem.values.any((operation) {
            if (operation is Map && operation['parameters'] is List) {
              final params = operation['parameters'] as List;
              return params.any((p) => p is Map && p['in'] == 'path' && p['description'] != null);
            }
            return false;
          });
        }
        return false;
      });
      expect(hasPathParamWithDescription, isTrue);
    });

    test('handles nested path params', () {
      final paths = spec['paths'] as Map;
      // Should have paths like /posts/{postId}/comments/{commentId}
      final nestedPath = paths.keys.firstWhere((p) {
        final path = p.toString();
        final braceCount = '{'.allMatches(path).length;
        return braceCount >= 2;
      }, orElse: () => '');
      expect(nestedPath, isNotEmpty, reason: 'Should have deeply nested path params');
    });
  });

  group('Query parameter extraction', () {
    late Map<String, dynamic> spec;

    setUpAll(() {
      final routes = discoverRoutes();
      spec = OpenApiGenerator(title: 'Test API').addRoutes(routes).generate();
    });

    test('extracts @QueryParam annotations', () {
      final paths = spec['paths'] as Map;
      final hasQueryParam = paths.values.any((pathItem) {
        if (pathItem is Map) {
          return pathItem.values.any((operation) {
            if (operation is Map && operation['parameters'] is List) {
              final params = operation['parameters'] as List;
              return params.any((p) => p is Map && p['in'] == 'query');
            }
            return false;
          });
        }
        return false;
      });
      expect(hasQueryParam, isTrue);
    });

    test('includes enum values in query params', () {
      final paths = spec['paths'] as Map;
      final hasEnumParam = paths.values.any((pathItem) {
        if (pathItem is Map) {
          return pathItem.values.any((operation) {
            if (operation is Map && operation['parameters'] is List) {
              final params = operation['parameters'] as List;
              return params.any((p) {
                if (p is Map && p['in'] == 'query' && p['schema'] is Map) {
                  final schema = p['schema'] as Map;
                  return schema['enum'] != null;
                }
                return false;
              });
            }
            return false;
          });
        }
        return false;
      });
      expect(hasEnumParam, isTrue);
    });

    test('includes default values in query params', () {
      final paths = spec['paths'] as Map;
      final hasDefaultValue = paths.values.any((pathItem) {
        if (pathItem is Map) {
          return pathItem.values.any((operation) {
            if (operation is Map && operation['parameters'] is List) {
              final params = operation['parameters'] as List;
              return params.any((p) {
                if (p is Map && p['in'] == 'query' && p['schema'] is Map) {
                  final schema = p['schema'] as Map;
                  return schema['default'] != null;
                }
                return false;
              });
            }
            return false;
          });
        }
        return false;
      });
      expect(hasDefaultValue, isTrue);
    });

    test('includes examples in query params', () {
      final paths = spec['paths'] as Map;
      final hasExample = paths.values.any((pathItem) {
        if (pathItem is Map) {
          return pathItem.values.any((operation) {
            if (operation is Map && operation['parameters'] is List) {
              final params = operation['parameters'] as List;
              return params.any((p) => p is Map && p['example'] != null);
            }
            return false;
          });
        }
        return false;
      });
      expect(hasExample, isTrue);
    });

    test('query params respect required flag', () {
      final paths = spec['paths'] as Map;
      for (final pathItem in paths.values) {
        if (pathItem is Map) {
          for (final operation in pathItem.values) {
            if (operation is Map && operation['parameters'] is List) {
              final params = operation['parameters'] as List;
              for (final param in params) {
                if (param is Map && param['in'] == 'query') {
                  expect(param.containsKey('required'), isTrue);
                }
              }
            }
          }
        }
      }
    });
  });

  group('Request body extraction', () {
    late Map<String, dynamic> spec;

    setUpAll(() {
      final routes = discoverRoutes();
      spec = OpenApiGenerator(title: 'Test API').addRoutes(routes).generate();
    });

    test('extracts @Body from POST methods', () {
      final paths = spec['paths'] as Map;
      final hasPostWithBody = paths.values.any((pathItem) {
        if (pathItem is Map && pathItem['post'] is Map) {
          final post = pathItem['post'] as Map;
          return post.containsKey('requestBody');
        }
        return false;
      });
      expect(hasPostWithBody, isTrue);
    });

    test('extracts @Body from PUT methods', () {
      final paths = spec['paths'] as Map;
      final hasPutWithBody = paths.values.any((pathItem) {
        if (pathItem is Map && pathItem['put'] is Map) {
          final put = pathItem['put'] as Map;
          return put.containsKey('requestBody');
        }
        return false;
      });
      expect(hasPutWithBody, isTrue);
    });

    test('GET methods do not have requestBody', () {
      final paths = spec['paths'] as Map;
      for (final pathItem in paths.values) {
        if (pathItem is Map && pathItem['get'] is Map) {
          final get = pathItem['get'] as Map;
          expect(get.containsKey('requestBody'), isFalse);
        }
      }
    });

    test('DELETE methods do not have requestBody', () {
      final paths = spec['paths'] as Map;
      for (final pathItem in paths.values) {
        if (pathItem is Map && pathItem['delete'] is Map) {
          final delete = pathItem['delete'] as Map;
          expect(delete.containsKey('requestBody'), isFalse);
        }
      }
    });

    test('request body includes content type', () {
      final paths = spec['paths'] as Map;
      for (final pathItem in paths.values) {
        if (pathItem is Map) {
          for (final operation in pathItem.values) {
            if (operation is Map && operation['requestBody'] is Map) {
              final body = operation['requestBody'] as Map;
              expect(body['content'], isNotNull);
            }
          }
        }
      }
    });

    test('request body includes description when provided', () {
      final paths = spec['paths'] as Map;
      final hasBodyWithDescription = paths.values.any((pathItem) {
        if (pathItem is Map) {
          return pathItem.values.any((operation) {
            if (operation is Map && operation['requestBody'] is Map) {
              final body = operation['requestBody'] as Map;
              return body['description'] != null;
            }
            return false;
          });
        }
        return false;
      });
      expect(hasBodyWithDescription, isTrue);
    });

    test('request body includes example when provided', () {
      final paths = spec['paths'] as Map;
      final hasBodyWithExample = paths.values.any((pathItem) {
        if (pathItem is Map) {
          // Check any HTTP method (get, post, put, delete, patch)
          for (final method in ['get', 'post', 'put', 'delete', 'patch']) {
            final operation = pathItem[method];
            if (operation is Map && operation['requestBody'] is Map) {
              final body = operation['requestBody'] as Map;
              final content = body['content'];
              if (content is Map) {
                if (content.values.any((mediaType) => mediaType is Map && mediaType.containsKey('example'))) {
                  return true;
                }
              }
            }
          }
        }
        return false;
      });
      expect(hasBodyWithExample, isTrue);
    });
  });

  group('Response extraction', () {
    late Map<String, dynamic> spec;

    setUpAll(() {
      final routes = discoverRoutes();
      spec = OpenApiGenerator(title: 'Test API').addRoutes(routes).generate();
    });

    test('extracts @OkResponse (200)', () {
      final paths = spec['paths'] as Map;
      final has200Response = paths.values.any((pathItem) {
        if (pathItem is Map) {
          return pathItem.values.any((operation) {
            if (operation is Map && operation['responses'] is Map) {
              final responses = operation['responses'] as Map;
              return responses.containsKey('200') || responses.containsKey(200);
            }
            return false;
          });
        }
        return false;
      });
      expect(has200Response, isTrue);
    });

    test('extracts @CreatedResponse (201)', () {
      final paths = spec['paths'] as Map;
      final has201Response = paths.values.any((pathItem) {
        if (pathItem is Map) {
          final post = pathItem['post'];
          if (post is Map && post['responses'] is Map) {
            final responses = post['responses'] as Map;
            return responses.containsKey('201') || responses.containsKey(201);
          }
        }
        return false;
      });
      expect(has201Response, isTrue);
    });

    test('extracts @NoContentResponse (204)', () {
      final paths = spec['paths'] as Map;
      final has204Response = paths.values.any((pathItem) {
        if (pathItem is Map) {
          final delete = pathItem['delete'];
          if (delete is Map && delete['responses'] is Map) {
            final responses = delete['responses'] as Map;
            return responses.containsKey('204') || responses.containsKey(204);
          }
        }
        return false;
      });
      expect(has204Response, isTrue);
    });

    test('extracts @BadRequestResponse (400)', () {
      final paths = spec['paths'] as Map;
      final has400Response = paths.values.any((pathItem) {
        if (pathItem is Map) {
          return pathItem.values.any((operation) {
            if (operation is Map && operation['responses'] is Map) {
              final responses = operation['responses'] as Map;
              return responses.containsKey('400') || responses.containsKey(400);
            }
            return false;
          });
        }
        return false;
      });
      expect(has400Response, isTrue);
    });

    test('extracts @UnauthorizedResponse (401)', () {
      final paths = spec['paths'] as Map;
      final has401Response = paths.values.any((pathItem) {
        if (pathItem is Map) {
          return pathItem.values.any((operation) {
            if (operation is Map && operation['responses'] is Map) {
              final responses = operation['responses'] as Map;
              return responses.containsKey('401') || responses.containsKey(401);
            }
            return false;
          });
        }
        return false;
      });
      expect(has401Response, isTrue);
    });

    test('extracts @NotFoundResponse (404)', () {
      final paths = spec['paths'] as Map;
      final has404Response = paths.values.any((pathItem) {
        if (pathItem is Map) {
          return pathItem.values.any((operation) {
            if (operation is Map && operation['responses'] is Map) {
              final responses = operation['responses'] as Map;
              return responses.containsKey('404') || responses.containsKey(404);
            }
            return false;
          });
        }
        return false;
      });
      expect(has404Response, isTrue);
    });

    test('multiple response codes per operation', () {
      final paths = spec['paths'] as Map;
      final hasMultipleResponses = paths.values.any((pathItem) {
        if (pathItem is Map) {
          return pathItem.values.any((operation) {
            if (operation is Map && operation['responses'] is Map) {
              final responses = operation['responses'] as Map;
              return responses.length > 1;
            }
            return false;
          });
        }
        return false;
      });
      expect(hasMultipleResponses, isTrue);
    });

    test('array responses have type: array in schema', () {
      final paths = spec['paths'] as Map;
      final hasArrayResponse = paths.values.any((pathItem) {
        if (pathItem is Map) {
          final get = pathItem['get'];
          if (get is Map && get['responses'] is Map) {
            final responses = get['responses'] as Map;
            return responses.values.any((response) {
              if (response is Map && response['content'] is Map) {
                final content = response['content'] as Map;
                return content.values.any((mediaType) {
                  if (mediaType is Map && mediaType['schema'] is Map) {
                    final schema = mediaType['schema'] as Map;
                    return schema['type'] == 'array';
                  }
                  return false;
                });
              }
              return false;
            });
          }
        }
        return false;
      });
      expect(hasArrayResponse, isTrue);
    });
  });

  group('Security extraction', () {
    late Map<String, dynamic> spec;

    setUpAll(() {
      final routes = discoverRoutes();
      spec = OpenApiGenerator(title: 'Test API').addBearerAuth().addRoutes(routes).generate();
    });

    test('extracts @BearerAuth from methods', () {
      final paths = spec['paths'] as Map;
      final hasSecurityRequirement = paths.values.any((pathItem) {
        if (pathItem is Map) {
          return pathItem.values.any((operation) {
            if (operation is Map && operation['security'] is List) {
              final security = operation['security'] as List;
              return security.any((s) => s is Map && s.containsKey('bearerAuth'));
            }
            return false;
          });
        }
        return false;
      });
      expect(hasSecurityRequirement, isTrue);
    });

    test('@Public methods have empty or no security', () {
      final paths = spec['paths'] as Map;
      // Find auth/login route which has @Public
      dynamic authPathValue;
      for (final entry in paths.entries) {
        final key = entry.key.toString();
        if (key.contains('auth') || key.contains('login')) {
          authPathValue = entry.value;
          break;
        }
      }

      if (authPathValue != null && authPathValue is Map) {
        final post = authPathValue['post'];
        if (post is Map) {
          final security = post['security'];
          // @Public should either have empty security array or no security
          expect(security == null || (security is List && security.isEmpty), isTrue);
        }
      }
    });
  });

  group('Helper method discovery', () {
    test('discovers private helper methods with HTTP annotations', () {
      final routes = discoverRoutes();
      final spec = OpenApiGenerator(title: 'Test API').addRoutes(routes).generate();

      final paths = spec['paths'] as Map;
      // Should have multiple HTTP methods on same path (e.g., GET and POST on /users)
      final hasMultipleMethods = paths.values.any((pathItem) {
        if (pathItem is Map) {
          final methods = pathItem.keys.where((k) => ['get', 'post', 'put', 'delete', 'patch'].contains(k));
          return methods.length > 1;
        }
        return false;
      });
      expect(hasMultipleMethods, isTrue);
    });

    test('does not reset httpMethod on non-HTTP annotations', () {
      // Method with @Get, @QueryParam, @BearerAuth should still be GET
      final routes = discoverRoutes();
      final spec = OpenApiGenerator(title: 'Test API').addBearerAuth().addRoutes(routes).generate();

      final paths = spec['paths'] as Map;
      // Find a GET operation that has query params
      final getWithQueryParams = paths.values.any((pathItem) {
        if (pathItem is Map) {
          final get = pathItem['get'];
          if (get is Map && get['parameters'] is List) {
            final params = get['parameters'] as List;
            return params.any((p) => p is Map && p['in'] == 'query');
          }
        }
        return false;
      });
      expect(getWithQueryParams, isTrue);
    });

    test('discovers methods with multiple annotation types', () {
      final routes = discoverRoutes();
      final spec = OpenApiGenerator(title: 'Test API').addBearerAuth().addRoutes(routes).generate();

      final paths = spec['paths'] as Map;
      // Find operation with params + responses + security
      final hasFullyAnnotatedMethod = paths.values.any((pathItem) {
        if (pathItem is Map) {
          return pathItem.values.any((operation) {
            if (operation is Map) {
              return operation.containsKey('parameters') &&
                  operation.containsKey('responses') &&
                  operation.containsKey('security');
            }
            return false;
          });
        }
        return false;
      });
      expect(hasFullyAnnotatedMethod, isTrue);
    });
  });

  group('Path utilities (tested through discovery)', () {
    test('does not have URL encoded characters in paths', () {
      final routes = discoverRoutes();
      final spec = OpenApiGenerator(title: 'Test API').addRoutes(routes).generate();

      final paths = spec['paths'] as Map;
      for (final path in paths.keys) {
        expect(path.toString().contains('%5B'), isFalse);
        expect(path.toString().contains('%5D'), isFalse);
        expect(path.toString().contains('%7B'), isFalse);
        expect(path.toString().contains('%7D'), isFalse);
      }
    });

    test('converts index.dart files to directory paths', () {
      final routes = discoverRoutes();
      final spec = OpenApiGenerator(title: 'Test API').addRoutes(routes).generate();

      final paths = spec['paths'] as Map;
      // Should have /users not /users/index
      final hasIndexInPath = paths.keys.any((p) => p.toString().contains('index'));
      expect(hasIndexInPath, isFalse);
    });

    test('converts routes/index.dart to root /', () {
      final routes = discoverRoutes();
      final spec = OpenApiGenerator(title: 'Test API').addRoutes(routes).generate();

      final paths = spec['paths'] as Map;
      final hasRootPath = paths.keys.any((p) => p == '/' || p == '');
      expect(hasRootPath, isTrue);
    });
  });

  group('HTTP annotation on onRequest (no helper methods)', () {
    late Map<String, dynamic> spec;

    setUpAll(() {
      final routes = discoverRoutes();
      spec = OpenApiGenerator(title: 'Test API').addRoutes(routes).generate();
    });

    test('discovers routes with HTTP annotation on onRequest', () {
      final paths = spec['paths'] as Map;
      // simple.dart should be discovered as /simple
      final hasSimpleRoute = paths.keys.any((p) => p.toString().contains('simple'));
      expect(hasSimpleRoute, isTrue);
    });

    test('extracts HTTP method from onRequest annotation', () {
      final paths = spec['paths'] as Map;
      String? simpleKey;
      dynamic simpleValue;

      for (final entry in paths.entries) {
        if (entry.key.toString().contains('simple')) {
          simpleKey = entry.key.toString();
          simpleValue = entry.value;
          break;
        }
      }

      if (simpleKey != null && simpleValue is Map) {
        // Should have GET method from @Get annotation on onRequest
        expect(simpleValue.containsKey('get'), isTrue);
      }
    });
  });

  group('Body annotation on method parameters', () {
    late Map<String, dynamic> spec;

    setUpAll(() {
      final routes = discoverRoutes();
      spec = OpenApiGenerator(title: 'Test API').addRoutes(routes).generate();
    });

    test('discovers routes with @Body on parameters', () {
      final paths = spec['paths'] as Map;
      // items.dart should be discovered as /items
      final hasItemsRoute = paths.keys.any((p) => p.toString().contains('items'));
      expect(hasItemsRoute, isTrue);
    });

    test('extracts @Body description from method parameter', () {
      final paths = spec['paths'] as Map;
      String? itemsKey;
      dynamic itemsValue;

      for (final entry in paths.entries) {
        if (entry.key.toString().contains('items')) {
          itemsKey = entry.key.toString();
          itemsValue = entry.value;
          break;
        }
      }

      if (itemsKey != null && itemsValue is Map) {
        if (itemsValue['post'] is Map) {
          final post = itemsValue['post'] as Map;
          if (post['requestBody'] is Map) {
            final body = post['requestBody'] as Map;
            expect(body['description'], 'Item data to create');
          }
        }
      }
    });
  });

  group('PathParam on function parameters', () {
    late Map<String, dynamic> spec;

    setUpAll(() {
      final routes = discoverRoutes();
      spec = OpenApiGenerator(title: 'Test API').addRoutes(routes).generate();
    });

    test('discovers routes with @PathParam on onRequest parameters', () {
      final paths = spec['paths'] as Map;
      // products/[productId].dart should be discovered
      final hasProductRoute = paths.keys.any((p) => p.toString().contains('product'));
      expect(hasProductRoute, isTrue);
    });

    test('extracts @PathParam description from function parameter', () {
      final paths = spec['paths'] as Map;
      dynamic productValue;

      for (final entry in paths.entries) {
        if (entry.key.toString().contains('product')) {
          productValue = entry.value;
          break;
        }
      }

      if (productValue is Map && productValue['get'] is Map) {
        final get = productValue['get'] as Map;
        if (get['parameters'] is List) {
          final params = get['parameters'] as List;
          Map<String, dynamic>? productIdParam;
          for (final p in params) {
            if (p is Map && p['name'] == 'productId') {
              productIdParam = Map<String, dynamic>.from(p);
              break;
            }
          }
          if (productIdParam != null) {
            expect(productIdParam['description'], 'Product identifier');
            expect(productIdParam['schema']['format'], 'uuid');
          }
        }
      }
    });

    test('path parameter from function param is marked required', () {
      final paths = spec['paths'] as Map;
      dynamic productValue;

      for (final entry in paths.entries) {
        if (entry.key.toString().contains('product')) {
          productValue = entry.value;
          break;
        }
      }

      if (productValue is Map && productValue['get'] is Map) {
        final get = productValue['get'] as Map;
        if (get['parameters'] is List) {
          final params = get['parameters'] as List;
          Map<String, dynamic>? productIdParam;
          for (final p in params) {
            if (p is Map && p['name'] == 'productId') {
              productIdParam = Map<String, dynamic>.from(p);
              break;
            }
          }
          if (productIdParam != null) {
            expect(productIdParam['required'], true);
            expect(productIdParam['in'], 'path');
          }
        }
      }
    });

    test('creates default PathParam for unannotated function parameter', () {
      final paths = spec['paths'] as Map;
      // orders/[orderId].dart has orderId param without @PathParam annotation
      final hasOrderRoute = paths.keys.any((p) => p.toString().contains('order'));
      expect(hasOrderRoute, isTrue);

      dynamic orderValue;
      for (final entry in paths.entries) {
        if (entry.key.toString().contains('order')) {
          orderValue = entry.value;
          break;
        }
      }

      if (orderValue is Map && orderValue['get'] is Map) {
        final get = orderValue['get'] as Map;
        if (get['parameters'] is List) {
          final params = get['parameters'] as List;
          Map<String, dynamic>? orderIdParam;
          for (final p in params) {
            if (p is Map && p['name'] == 'orderId') {
              orderIdParam = Map<String, dynamic>.from(p);
              break;
            }
          }
          // Should have created default PathParam with just the name
          expect(orderIdParam, isNotNull);
          expect(orderIdParam!['in'], 'path');
          expect(orderIdParam['required'], true);
        }
      }
    });
  });
}
