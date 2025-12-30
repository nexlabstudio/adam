import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_openapi/dart_frog_openapi.dart';
import 'package:example/models/user.dart';
import 'package:example/models/common.dart';

@Api(tag: 'Users')
@Get(summary: 'Get user', description: 'Get user by ID')
@PathParam('id', description: 'User UUID', format: 'uuid')
@BearerAuth()
@OkResponse(description: 'User details', schema: User)
@NotFoundResponse(schema: ErrorResponse)
//
@Put(summary: 'Update user')
@PathParam('id', format: 'uuid')
@Body(schema: UpdateUserRequest)
@BearerAuth()
@OkResponse(description: 'Updated user', schema: User)
@NotFoundResponse(schema: ErrorResponse)
//
@Delete(summary: 'Delete user')
@PathParam('id', format: 'uuid')
@BearerAuth()
@NoContentResponse()
@NotFoundResponse(schema: ErrorResponse)
Future<Response> onRequest(RequestContext context, String id) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return Response.json(
        body: {
          'id': id,
          'email': 'john@example.com',
          'name': 'John Doe',
          'role': 'user',
          'createdAt': DateTime.now().toIso8601String(),
          'isActive': true,
        },
      );
    case HttpMethod.put:
      final body = await context.request.json() as Map<String, dynamic>;
      return Response.json(
        body: {
          'id': id,
          'email': 'john@example.com',
          'name': body['name'] ?? 'John Doe',
          'role': 'user',
          'createdAt': DateTime.now().toIso8601String(),
          'isActive': true,
        },
      );
    case HttpMethod.delete:
      return Response(statusCode: 204);
    default:
      return Response(statusCode: 405);
  }
}
