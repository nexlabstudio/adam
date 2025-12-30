// Mock route file for testing route discovery - /users
// ignore_for_file: unused_element

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_openapi/dart_frog_openapi.dart';

@Api(tag: 'Users', description: 'User management')
Future<Response> onRequest(RequestContext context) async => switch (context.request.method) {
  HttpMethod.get => _get(context),
  HttpMethod.post => _post(context),
  _ => Response.json(statusCode: 405),
};

@Get(summary: 'List users', operationId: 'listUsers')
@QueryParam('page', type: 'integer', defaultValue: 1, example: 1)
@QueryParam('limit', type: 'integer', defaultValue: 10)
@QueryParam('status', enumValues: ['active', 'inactive', 'pending'])
@BearerAuth()
@OkResponse(schema: String, isArray: true, description: 'List of users')
Future<Response> _get(RequestContext context) async => Response.json(body: []);

@Post(summary: 'Create user', operationId: 'createUser')
@Body(schema: String, description: 'User data to create')
@BearerAuth()
@CreatedResponse(schema: String, description: 'User created')
@BadRequestResponse(description: 'Invalid user data')
Future<Response> _post(RequestContext context) async => Response.json(body: {}, statusCode: 201);
