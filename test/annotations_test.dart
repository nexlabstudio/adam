import 'package:dart_frog_openapi/dart_frog_openapi.dart';
import 'package:test/test.dart';

void main() {
  group('Api annotation', () {
    test('creates with tag only', () {
      const api = Api(tag: 'Users');
      expect(api.tag, 'Users');
      expect(api.description, isNull);
    });

    test('creates with tag and description', () {
      const api = Api(tag: 'Users', description: 'User management');
      expect(api.tag, 'Users');
      expect(api.description, 'User management');
    });
  });

  group('Operation base class', () {
    test('creates with all parameters', () {
      const op = Operation(
        summary: 'Test operation',
        description: 'Test description',
        operationId: 'testOp',
        tags: ['Tag1', 'Tag2'],
        deprecated: true,
      );
      expect(op.summary, 'Test operation');
      expect(op.description, 'Test description');
      expect(op.operationId, 'testOp');
      expect(op.tags, ['Tag1', 'Tag2']);
      expect(op.deprecated, true);
    });

    test('creates with defaults', () {
      const op = Operation(summary: 'Test');
      expect(op.summary, 'Test');
      expect(op.description, isNull);
      expect(op.operationId, isNull);
      expect(op.tags, isNull);
      expect(op.deprecated, false);
    });
  });

  group('HTTP method annotations', () {
    test('Get with all parameters', () {
      const get = Get(
        summary: 'List users',
        description: 'Get all users',
        operationId: 'listUsers',
        tags: ['Users', 'Admin'],
        deprecated: true,
      );
      expect(get.summary, 'List users');
      expect(get.description, 'Get all users');
      expect(get.operationId, 'listUsers');
      expect(get.tags, ['Users', 'Admin']);
      expect(get.deprecated, true);
    });

    test('Get with defaults', () {
      const get = Get(summary: 'List');
      expect(get.summary, 'List');
      expect(get.deprecated, false);
      expect(get.tags, isNull);
      expect(get.description, isNull);
      expect(get.operationId, isNull);
    });

    test('Post with summary', () {
      const post = Post(summary: 'Create user');
      expect(post.summary, 'Create user');
      expect(post.deprecated, false);
    });

    test('Post with all parameters', () {
      const post = Post(
        summary: 'Create user',
        description: 'Create a new user',
        operationId: 'createUser',
        tags: ['Users'],
        deprecated: false,
      );
      expect(post.summary, 'Create user');
      expect(post.description, 'Create a new user');
      expect(post.operationId, 'createUser');
      expect(post.tags, ['Users']);
    });

    test('Put with summary', () {
      const put = Put(summary: 'Update user');
      expect(put.summary, 'Update user');
      expect(put.deprecated, false);
    });

    test('Put with all parameters', () {
      const put = Put(
        summary: 'Update user',
        description: 'Update existing user',
        operationId: 'updateUser',
        deprecated: true,
      );
      expect(put.summary, 'Update user');
      expect(put.description, 'Update existing user');
      expect(put.deprecated, true);
    });

    test('Delete with summary', () {
      const delete = Delete(summary: 'Delete user');
      expect(delete.summary, 'Delete user');
      expect(delete.deprecated, false);
    });

    test('Delete with all parameters', () {
      const delete = Delete(
        summary: 'Delete user',
        description: 'Remove user permanently',
        operationId: 'deleteUser',
        tags: ['Admin'],
      );
      expect(delete.operationId, 'deleteUser');
      expect(delete.tags, ['Admin']);
    });

    test('Patch with summary', () {
      const patch = Patch(summary: 'Patch user');
      expect(patch.summary, 'Patch user');
      expect(patch.deprecated, false);
    });

    test('Patch with all parameters', () {
      const patch = Patch(summary: 'Patch user', description: 'Partially update user', operationId: 'patchUser');
      expect(patch.operationId, 'patchUser');
    });
  });

  group('PathParam', () {
    test('creates with name only', () {
      const param = PathParam('id');
      expect(param.name, 'id');
      expect(param.type, 'string');
      expect(param.description, isNull);
      expect(param.format, isNull);
      expect(param.example, isNull);
    });

    test('creates with all options', () {
      const param = PathParam('id', description: 'User ID', type: 'integer', format: 'int64', example: 123);
      expect(param.name, 'id');
      expect(param.description, 'User ID');
      expect(param.type, 'integer');
      expect(param.format, 'int64');
      expect(param.example, 123);
    });

    test('creates with uuid format', () {
      const param = PathParam(
        'userId',
        description: 'User UUID',
        format: 'uuid',
        example: '550e8400-e29b-41d4-a716-446655440000',
      );
      expect(param.format, 'uuid');
      expect(param.example, '550e8400-e29b-41d4-a716-446655440000');
    });
  });

  group('QueryParam', () {
    test('creates with name only', () {
      const param = QueryParam('page');
      expect(param.name, 'page');
      expect(param.required, false);
      expect(param.type, 'string');
      expect(param.description, isNull);
      expect(param.format, isNull);
      expect(param.defaultValue, isNull);
      expect(param.example, isNull);
      expect(param.enumValues, isNull);
    });

    test('creates with all options', () {
      const param = QueryParam(
        'status',
        description: 'Filter by status',
        required: true,
        type: 'string',
        defaultValue: 'active',
        example: 'active',
        enumValues: ['active', 'inactive', 'pending'],
      );
      expect(param.name, 'status');
      expect(param.description, 'Filter by status');
      expect(param.required, true);
      expect(param.type, 'string');
      expect(param.defaultValue, 'active');
      expect(param.example, 'active');
      expect(param.enumValues, ['active', 'inactive', 'pending']);
    });

    test('creates with integer type', () {
      const param = QueryParam('limit', type: 'integer', defaultValue: 10, example: 20);
      expect(param.type, 'integer');
      expect(param.defaultValue, 10);
      expect(param.example, 20);
    });

    test('creates with format', () {
      const param = QueryParam('date', type: 'string', format: 'date', example: '2024-01-15');
      expect(param.format, 'date');
    });
  });

  group('HeaderParam', () {
    test('creates with name only', () {
      const param = HeaderParam('X-Request-ID');
      expect(param.name, 'X-Request-ID');
      expect(param.required, false);
      expect(param.description, isNull);
      expect(param.example, isNull);
    });

    test('creates with all options', () {
      const param = HeaderParam('X-API-Version', description: 'API version', required: true, example: '2.0');
      expect(param.name, 'X-API-Version');
      expect(param.description, 'API version');
      expect(param.required, true);
      expect(param.example, '2.0');
    });

    test('creates authorization header', () {
      const param = HeaderParam(
        'Authorization',
        description: 'Bearer token',
        required: true,
        example: 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
      );
      expect(param.name, 'Authorization');
      expect(param.required, true);
    });
  });

  group('Body annotation', () {
    test('creates with schema', () {
      const body = Body(schema: String);
      expect(body.schema, String);
      expect(body.required, true);
      expect(body.contentType, 'application/json');
      expect(body.description, isNull);
      expect(body.example, isNull);
    });

    test('creates with all options', () {
      const body = Body(
        schema: Map,
        description: 'User data',
        required: false,
        contentType: 'application/xml',
        example: {'name': 'John'},
      );
      expect(body.schema, Map);
      expect(body.description, 'User data');
      expect(body.required, false);
      expect(body.contentType, 'application/xml');
      expect(body.example, {'name': 'John'});
    });

    test('creates without schema', () {
      const body = Body(description: 'Raw body');
      expect(body.schema, isNull);
      expect(body.description, 'Raw body');
    });

    test('creates with different content types', () {
      const jsonBody = Body(contentType: 'application/json');
      const xmlBody = Body(contentType: 'application/xml');
      const formBody = Body(contentType: 'application/x-www-form-urlencoded');

      expect(jsonBody.contentType, 'application/json');
      expect(xmlBody.contentType, 'application/xml');
      expect(formBody.contentType, 'application/x-www-form-urlencoded');
    });
  });

  group('ApiResponse', () {
    test('creates with status and description', () {
      const response = ApiResponse(200, description: 'Success');
      expect(response.statusCode, 200);
      expect(response.description, 'Success');
      expect(response.schema, isNull);
      expect(response.isArray, false);
      expect(response.contentType, 'application/json');
      expect(response.example, isNull);
    });

    test('creates with schema', () {
      const response = ApiResponse(200, description: 'User retrieved', schema: String);
      expect(response.schema, String);
      expect(response.isArray, false);
    });

    test('creates with schema as array', () {
      const response = ApiResponse(200, description: 'List of users', schema: String, isArray: true);
      expect(response.isArray, true);
    });

    test('creates with example', () {
      const response = ApiResponse(200, description: 'Success', example: {'id': 1, 'name': 'John'});
      expect(response.example, {'id': 1, 'name': 'John'});
    });

    test('creates with custom content type', () {
      const response = ApiResponse(200, description: 'XML response', contentType: 'application/xml');
      expect(response.contentType, 'application/xml');
    });
  });

  group('Convenience response annotations', () {
    test('OkResponse defaults to 200', () {
      const response = OkResponse(description: 'OK');
      expect(response.statusCode, 200);
      expect(response.description, 'OK');
    });

    test('OkResponse with default description', () {
      const response = OkResponse();
      expect(response.statusCode, 200);
      expect(response.description, 'Successful response');
    });

    test('OkResponse with schema', () {
      const response = OkResponse(schema: String);
      expect(response.schema, String);
      expect(response.isArray, false);
    });

    test('OkResponse with array schema', () {
      const response = OkResponse(schema: String, isArray: true);
      expect(response.isArray, true);
    });

    test('OkResponse with example', () {
      const response = OkResponse(example: {'status': 'ok'});
      expect(response.example, {'status': 'ok'});
    });

    test('CreatedResponse defaults to 201', () {
      const response = CreatedResponse(description: 'Created');
      expect(response.statusCode, 201);
      expect(response.description, 'Created');
    });

    test('CreatedResponse with default description', () {
      const response = CreatedResponse();
      expect(response.description, 'Resource created');
    });

    test('CreatedResponse with schema and example', () {
      const response = CreatedResponse(schema: String, example: {'id': 'new-id'});
      expect(response.schema, String);
      expect(response.example, {'id': 'new-id'});
    });

    test('NoContentResponse defaults to 204', () {
      const response = NoContentResponse();
      expect(response.statusCode, 204);
      expect(response.description, 'No content');
      expect(response.contentType, '');
    });

    test('NoContentResponse with custom description', () {
      const response = NoContentResponse(description: 'Deleted successfully');
      expect(response.description, 'Deleted successfully');
    });

    test('BadRequestResponse defaults to 400', () {
      const response = BadRequestResponse(description: 'Bad request');
      expect(response.statusCode, 400);
      expect(response.description, 'Bad request');
    });

    test('BadRequestResponse with default description', () {
      const response = BadRequestResponse();
      expect(response.description, 'Bad request');
    });

    test('BadRequestResponse with schema', () {
      const response = BadRequestResponse(schema: String);
      expect(response.schema, String);
    });

    test('UnauthorizedResponse defaults to 401', () {
      const response = UnauthorizedResponse(description: 'Unauthorized');
      expect(response.statusCode, 401);
      expect(response.description, 'Unauthorized');
    });

    test('UnauthorizedResponse with default description', () {
      const response = UnauthorizedResponse();
      expect(response.description, 'Unauthorized');
    });

    test('NotFoundResponse defaults to 404', () {
      const response = NotFoundResponse(description: 'Not found');
      expect(response.statusCode, 404);
      expect(response.description, 'Not found');
    });

    test('NotFoundResponse with default description', () {
      const response = NotFoundResponse();
      expect(response.description, 'Not found');
    });

    test('NotFoundResponse with schema', () {
      const response = NotFoundResponse(schema: String);
      expect(response.schema, String);
    });

    test('ServerErrorResponse defaults to 500', () {
      const response = ServerErrorResponse(description: 'Server error');
      expect(response.statusCode, 500);
      expect(response.description, 'Server error');
    });

    test('ServerErrorResponse with default description', () {
      const response = ServerErrorResponse();
      expect(response.description, 'Internal server error');
    });
  });

  group('ApiExclude', () {
    test('is const constructible', () {
      const exclude = ApiExclude();
      expect(exclude, isA<ApiExclude>());
    });

    test('const instance exists', () {
      expect(apiExclude, isA<ApiExclude>());
    });
  });
}
