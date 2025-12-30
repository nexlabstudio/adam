import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_openapi/dart_frog_openapi.dart';
import 'package:example/models/common.dart';

@Api(tag: 'Auth', description: 'Authentication')
@Post(summary: 'Login', description: 'Authenticate and get tokens')
@Body(schema: LoginRequest, example: {'email': 'user@example.com', 'password': 'secret'})
@Public()
@OkResponse(description: 'Authentication successful', schema: TokenResponse)
@ApiResponse(401, description: 'Invalid credentials', schema: ErrorResponse)
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  return Response.json(
    body: {
      'accessToken': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.mock',
      'refreshToken': 'mock-refresh-token',
      'expiresIn': 3600,
    },
  );
}
