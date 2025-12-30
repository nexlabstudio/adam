import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_openapi/dart_frog_openapi.dart';
import 'package:example/models/user.dart';
import 'package:example/models/common.dart';

@Api(tag: 'Users', description: 'User management')
Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _listUsers(context);
    case HttpMethod.post:
      final body = await context.request.json() as Map<String, dynamic>?;

      if (body case final body? when body.values.every((element) => element != null)) {
        final user = User(
          id: body['id'],
          email: body['email'],
          name: body['name'],
          role: body['role'],
          createdAt: DateTime.now(),
        );
        return _createUser(user);
      }

      return Response(statusCode: 403);

    default:
      return Response(statusCode: 405);
  }
}

@Get(summary: 'List users', description: 'Get paginated list of users')
@QueryParam('page', type: 'integer', description: 'Page number', example: 1)
@QueryParam('pageSize', type: 'integer', description: 'Items per page', example: 20)
@QueryParam('search', description: 'Search term')
@BearerAuth()
@OkResponse(description: 'List of users', schema: User, isArray: true)
@UnauthorizedResponse(schema: ErrorResponse)
Future<Response> _listUsers(RequestContext context) async => Response.json(body: {
      'data': [
        {
          'id': '550e8400-e29b-41d4-a716-446655440000',
          'email': 'john@example.com',
          'name': 'John Doe',
          'role': 'user',
          'createdAt': DateTime.now().toIso8601String(),
          'isActive': true,
        }
      ],
      'total': 1,
      'page': 1,
      'pageSize': 20,
    });

@Post(summary: 'Create user', description: 'Register a new user')
@Body(schema: CreateUserRequest)
@BearerAuth()
@CreatedResponse(description: 'User created', schema: User)
@BadRequestResponse(schema: ErrorResponse)
Future<Response> _createUser(User user) async => Response.json(
      statusCode: 201,
      body: {
        'id': '550e8400-e29b-41d4-a716-446655440001',
        'email': user.email,
        'name': user.name,
        'role': 'user',
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true,
      },
    );
