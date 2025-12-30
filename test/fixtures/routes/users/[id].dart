// Mock route file for testing route discovery - /users/{id}
// ignore_for_file: unused_element

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_openapi/dart_frog_openapi.dart';

@Api(tag: 'Users')
@PathParam('id', description: 'User ID', type: 'string', format: 'uuid')
Future<Response> onRequest(RequestContext context) async => switch (context.request.method) {
  HttpMethod.get => _get(context),
  HttpMethod.put => _put(context),
  HttpMethod.delete => _delete(context),
  _ => Response.json(statusCode: 405),
};

@Get(summary: 'Get user by ID', operationId: 'getUserById')
@BearerAuth()
@OkResponse(schema: String, description: 'User details')
@NotFoundResponse(description: 'User not found')
Future<Response> _get(RequestContext context) async => Response.json(body: {});

@Put(summary: 'Update user', operationId: 'updateUser')
@Body(schema: String, description: 'Updated user data', example: {'name': 'John'})
@BearerAuth()
@OkResponse(schema: String, description: 'User updated')
@NotFoundResponse(description: 'User not found')
@BadRequestResponse(description: 'Invalid data')
Future<Response> _put(RequestContext context) async => Response.json(body: {});

@Delete(summary: 'Delete user', operationId: 'deleteUser')
@BearerAuth()
@NoContentResponse(description: 'User deleted')
@NotFoundResponse(description: 'User not found')
Future<Response> _delete(RequestContext context) async => Response(statusCode: 204);
