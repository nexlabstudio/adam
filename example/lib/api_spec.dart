import 'package:dart_frog_openapi/dart_frog_openapi.dart';

// Import models for schema registration
import 'package:example/models/user.dart';
import 'package:example/models/common.dart';

/// Generate the OpenAPI spec at runtime using reflection.
///
/// Routes are auto-discovered - no manual imports needed!
final apiSpec = OpenApiGenerator(
  title: 'Example API',
  version: '1.0.0',
  description: '''
A sample API built with Dart Frog demonstrating OpenAPI documentation using reflection.

## Features
- User management
- Authentication
- Auto-discovered routes
''',
  servers: [
    {'url': 'http://localhost:8080', 'description': 'Development'},
    {'url': 'https://api.example.com', 'description': 'Production'},
  ],
)
    // Security schemes
    .addBearerAuth()
    .addApiKeyAuth()

    // Auto-discover all routes - no manual imports!
    .addRoutes(discoverRoutes())

    // Register schemas (optional - auto-discovered from responses/bodies)
    .addSchema<User>()
    .addSchema<CreateUserRequest>()
    .addSchema<UpdateUserRequest>()
    .addSchema<ErrorResponse>()
    .addSchema<TokenResponse>()
    .addSchema<LoginRequest>()

    // Generate the spec
    .generate();
