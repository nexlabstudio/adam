# dart_frog_openapi (Adam)

<p align="center">
  <a href="https://github.com/nexlabstudio/adam/actions/workflows/test.yml"><img src="https://github.com/nexlabstudio/adam/actions/workflows/test.yml/badge.svg" alt="Tests"></a>
  <a href="https://codecov.io/github/nexlabstudio/adam"><img src="https://codecov.io/github/nexlabstudio/adam/graph/badge.svg?token=O4Vo55lvTo" alt="codecov"></a>
</p>

<p align="center">
  <img src="asset/adam.jpg" alt="Adam - Eyes of the Lord" width="400">
</p>

**Volund: Eyes of the Lord** — Sees your code. Mirrors it into OpenAPI. No build_runner needed.

## Why Reflection?

Like Adam from *Record of Ragnarok* with his **Eyes of the Lord** - this package uses `dart:mirrors` to instantly reflect your code structure. No build step. No configuration. It just sees and mirrors.

Unlike Flutter, Dart Frog runs on the server where `dart:mirrors` is available. This means:

- ✅ Auto-discover routes at runtime
- ✅ No build_runner configuration
- ✅ No code generation step
- ✅ No manual route imports
- ✅ Immediate feedback during development

## Installation

```yaml
dependencies:
  dart_frog: ^1.0.0
  dart_frog_openapi: ^0.1.0
```

## Quick Start

### 1. Annotate Your Handlers

Annotations go where they belong - on the actual methods:

```dart
// routes/users/index.dart
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_openapi/dart_frog_openapi.dart';

@Api(tag: 'Users', description: 'User management')
Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _get(context),
    HttpMethod.post => _post(context),
    _ => Response(statusCode: 405),
  };
}

@Get(summary: 'List users')
@QueryParam('page', type: 'integer', example: 1)
@BearerAuth()
@OkResponse(schema: User, isArray: true)
Future<Response> _get(RequestContext context) async {
  // ...
}

@Post(summary: 'Create user')
@CreatedResponse(schema: User)
Future<Response> _post(
  RequestContext context,
  @Body(schema: CreateUserRequest) _,  // Body on parameter
) async {
  final body = await context.request.json();
  // ...
}
```

```dart
// routes/users/[id].dart

@Api(tag: 'Users')
Future<Response> onRequest(
  RequestContext context,
  @PathParam(description: 'User UUID', format: 'uuid') String id,  // PathParam on parameter
) async {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id),
    HttpMethod.put => _put(context, id),
    HttpMethod.delete => _delete(context, id),
    _ => Response(statusCode: 405),
  };
}

@Get(summary: 'Get user')
@OkResponse(schema: User)
@NotFoundResponse(schema: ErrorResponse)
Future<Response> _get(RequestContext context, String id) async {
  // ...
}

@Put(summary: 'Update user')
@OkResponse(schema: User)
Future<Response> _put(
  RequestContext context,
  String id,
  @Body(schema: UpdateUserRequest) _,
) async {
  final body = await context.request.json();
  // ...
}

@Delete(summary: 'Delete user')
@NoContentResponse()
Future<Response> _delete(RequestContext context, String id) async {
  // ...
}
```

### 2. Add Middleware (One Line!)

```dart
// routes/_middleware.dart
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_openapi/dart_frog_openapi.dart';

Handler middleware(Handler handler) {
  return handler.use(
    autoSwagger(title: 'My API', version: '1.0.0'),
  );
}
```

That's it. Routes are auto-discovered, methods are detected, docs are served.

### 3. Access Documentation

- **Swagger UI**: http://localhost:8080/docs
- **OpenAPI JSON**: http://localhost:8080/openapi.json
- **OpenAPI YAML**: http://localhost:8080/openapi.yaml

### 4. (Optional) Annotate Models

```dart
// lib/models/user.dart
import 'package:dart_frog_openapi/dart_frog_openapi.dart';

@ApiSchema(description: 'User account')
class User {
  @UuidProperty(description: 'Unique identifier')
  final String id;

  @EmailProperty()
  final String email;

  @ApiProperty(description: 'Display name', minLength: 2)
  final String name;

  const User({required this.id, required this.email, required this.name});
}
```

## Annotation Placement

| Annotation | Where it goes |
|------------|---------------|
| `@Api` | On `onRequest` |
| `@Get`, `@Post`, etc. | On `_get`, `_post`, etc. helper methods |
| `@PathParam` | On the parameter in `onRequest` signature |
| `@QueryParam` | On the method that uses it |
| `@Body` | On a parameter in the method signature |
| `@OkResponse`, etc. | On the method |

## Method Discovery

The package auto-discovers HTTP methods by:

1. Scanning all functions in the route file
2. Reading `@Get`, `@Post`, `@Put`, `@Delete`, `@Patch` annotations
3. Falling back to annotations on `onRequest`

Function names don't matter - only the annotation:

```dart
@Get(summary: 'List users')
Future<Response> _listAllUsers(...) async { }  // Works

@Get(summary: 'List users')  
Future<Response> _fetchUsers(...) async { }    // Works

@Get(summary: 'List users')
Future<Response> _xyz(...) async { }           // Also works
```

## How Route Discovery Works

Given this file structure:

```
routes/
├── index.dart              → /
├── users/
│   ├── index.dart          → /users
│   └── [id].dart           → /users/{id}
└── polls/
    ├── index.dart          → /polls
    └── [id]/
        ├── index.dart      → /polls/{id}
        └── choices/
            ├── index.dart  → /polls/{id}/choices
            └── [id].dart   → /polls/{id}/choices/{id}
```

`discoverRoutes()` automatically:
1. Scans all loaded route libraries via `dart:mirrors`
2. Finds `onRequest` functions
3. Converts file paths to OpenAPI paths (`[id]` → `{id}`)
4. Returns a map ready for `addRoutes()`

## Custom Parameter Names

By default, `[id]` becomes `{id}`. For nested IDs, use `discoverRoutesWithParams`:

```dart
final apiSpec = OpenApiGenerator(title: 'My API')
    .addRoutes(discoverRoutesWithParams({
      'polls/[id]': 'pollId',
      'polls/[id]/choices/[id]': 'choiceId',
    }))
    .generate();
```

Results in `/polls/{pollId}/choices/{choiceId}`.

## Annotations

### Route Annotations

| Annotation | Description |
|------------|-------------|
| `@Api(tag: 'Name')` | Groups endpoints under a tag |
| `@Get(summary: '...')` | GET operation |
| `@Post(summary: '...')` | POST operation |
| `@Put(summary: '...')` | PUT operation |
| `@Delete(summary: '...')` | DELETE operation |
| `@Patch(summary: '...')` | PATCH operation |

### Parameter Annotations

| Annotation | Description |
|------------|-------------|
| `@PathParam('id')` | Path parameter |
| `@QueryParam('page')` | Query parameter |
| `@HeaderParam('X-Token')` | Header parameter |
| `@Body(schema: Type)` | Request body |

### Response Annotations

| Annotation | Description |
|------------|-------------|
| `@ApiResponse(200, ...)` | Custom response |
| `@OkResponse(...)` | 200 OK |
| `@CreatedResponse(...)` | 201 Created |
| `@NoContentResponse()` | 204 No Content |
| `@BadRequestResponse(...)` | 400 Bad Request |
| `@UnauthorizedResponse(...)` | 401 Unauthorized |
| `@NotFoundResponse(...)` | 404 Not Found |

### Security Annotations

| Annotation | Description |
|------------|-------------|
| `@BearerAuth()` | JWT bearer token |
| `@ApiKeyAuth()` | API key |
| `@BasicAuth()` | Basic auth |
| `@Public()` | No auth required |

### Schema Annotations

| Annotation | Description |
|------------|-------------|
| `@ApiSchema()` | Marks class as schema |
| `@ApiProperty()` | Documents property |
| `@UuidProperty()` | UUID format |
| `@EmailProperty()` | Email format |
| `@DateTimeProperty()` | DateTime format |
| `@PasswordProperty()` | Password (write-only) |

## autoSwagger Options

```dart
autoSwagger(
  title: 'My API',              // Required
  version: '1.0.0',             // Default: '1.0.0'
  description: 'API desc',      // Optional
  docsPath: '/docs',            // Default: '/docs'
  specPath: '/openapi.json',    // Default: '/openapi.json'
  bearerAuth: true,             // Default: true
  apiKeyAuth: false,            // Default: false
  apiKeyHeader: 'X-API-Key',    // Default: 'X-API-Key'
  servers: [                    // Optional
    {'url': 'https://api.example.com', 'description': 'Production'},
  ],
  paramNames: {                 // Optional - custom path param names
    'polls/[id]': 'pollId',
    'polls/[id]/choices/[id]': 'choiceId',
  },
)
```

## Advanced: Manual Control

For more control, use `OpenApiGenerator` directly:

```dart
// lib/api_spec.dart
import 'package:dart_frog_openapi/dart_frog_openapi.dart';

final apiSpec = OpenApiGenerator(
  title: 'My API',
  version: '1.0.0',
  description: 'API description',
  servers: [
    {'url': 'http://localhost:8080', 'description': 'Dev'},
  ],
  contact: {'name': 'Support', 'email': 'support@example.com'},
  license: {'name': 'MIT'},
)
    // Security schemes
    .addBearerAuth(format: 'JWT')
    .addApiKeyAuth(headerName: 'X-API-Key')
    .addBasicAuth()

    // Tags (optional - auto-derived from @Api)
    .addTag('Users', description: 'User endpoints')

    // Routes - auto-discover or manual
    .addRoutes(discoverRoutes())  // Auto-discover all
    // or
    .addRoute('/users', usersHandler)  // Manual

    // Schemas (optional - auto-discovered from @Body/@Response)
    .addSchema<User>()
    .addSchema<CreateUserRequest>()

    // Generate OpenAPI spec
    .generate();

// routes/_middleware.dart
Handler middleware(Handler handler) {
  return handler.use(swaggerUI(spec: apiSpec));
}
```

## Alternative UIs

### ReDoc

```dart
handler.use(reDoc(spec: apiSpec, title: 'My API'))
```

### Scalar

```dart
handler.use(scalar(spec: apiSpec, title: 'My API'))
```

### All Three UIs

```dart
Handler middleware(Handler handler) {
  final spec = OpenApiGenerator(
    title: 'My API',
    version: '1.0.0',
  )
      .addRoutes(discoverRoutes())
      .generate();

  return handler
      .use(swaggerUI(spec: spec, docsPath: '/docs'))
      .use(reDoc(spec: spec, docsPath: '/redoc'))
      .use(scalar(spec: spec, docsPath: '/scalar'));
}
```

Then access:
- http://localhost:8080/docs - Swagger UI
- http://localhost:8080/redoc - ReDoc  
- http://localhost:8080/scalar - Scalar
- http://localhost:8080/openapi.json - Raw JSON spec
- http://localhost:8080/openapi.yaml - Raw YAML spec

## How It Works

Just like Adam's **Eyes of the Lord** mirrors divine techniques instantly:

1. Dart Frog loads all route handlers at startup
2. `discoverRoutes()` uses `dart:mirrors` to find them in loaded libraries
3. `OpenApiGenerator` reflects on each handler's annotations
4. OpenAPI spec is built in memory
5. Middleware serves Swagger UI

No code generation, no build step - just reflection. The package sees your code structure and mirrors it into an OpenAPI spec.

## Easter Egg

For fans of *Record of Ragnarok*, there's an alias:

```dart
final spec = Volund(title: 'My API')
    .addRoutes(discoverRoutes())
    .generate();
```

⚔️

## License

MIT