/**
 * Route and operation annotations for OpenAPI documentation.
 * Groups endpoints under a tag.
 */

/// Groups endpoints under a tag.
class Api {
  final String tag;
  final String? description;

  const Api({required this.tag, this.description});
}

/// Documents an API operation.
class Operation {
  final String summary;
  final String? description;
  final String? operationId;
  final List<String>? tags;
  final bool deprecated;

  const Operation({required this.summary, this.description, this.operationId, this.tags, this.deprecated = false});
}

/// GET operation.
class Get extends Operation {
  const Get({required super.summary, super.description, super.operationId, super.tags, super.deprecated});
}

/// POST operation.
class Post extends Operation {
  const Post({required super.summary, super.description, super.operationId, super.tags, super.deprecated});
}

/// PUT operation.
class Put extends Operation {
  const Put({required super.summary, super.description, super.operationId, super.tags, super.deprecated});
}

/// DELETE operation.
class Delete extends Operation {
  const Delete({required super.summary, super.description, super.operationId, super.tags, super.deprecated});
}

/// PATCH operation.
class Patch extends Operation {
  const Patch({required super.summary, super.description, super.operationId, super.tags, super.deprecated});
}

/// Path parameter.
class PathParam {
  final String name;
  final String? description;
  final String type;
  final String? format;
  final dynamic example;

  const PathParam(this.name, {this.description, this.type = 'string', this.format, this.example});
}

/// Query parameter.
class QueryParam {
  final String name;
  final String? description;
  final bool required;
  final String type;
  final String? format;
  final dynamic defaultValue;
  final dynamic example;
  final List<String>? enumValues;

  const QueryParam(
    this.name, {
    this.description,
    this.required = false,
    this.type = 'string',
    this.format,
    this.defaultValue,
    this.example,
    this.enumValues,
  });
}

/// Header parameter.
class HeaderParam {
  final String name;
  final String? description;
  final bool required;
  final dynamic example;

  const HeaderParam(this.name, {this.description, this.required = false, this.example});
}

/// Request body.
class Body {
  final Type? schema;
  final String? description;
  final bool required;
  final String contentType;
  final dynamic example;

  const Body({
    this.schema,
    this.description,
    this.required = true,
    this.contentType = 'application/json',
    this.example,
  });
}

/// API response.
class ApiResponse {
  final int statusCode;
  final String description;
  final Type? schema;
  final bool isArray;
  final String contentType;
  final dynamic example;

  const ApiResponse(
    this.statusCode, {
    required this.description,
    this.schema,
    this.isArray = false,
    this.contentType = 'application/json',
    this.example,
  });
}

// Convenience response annotations
class OkResponse extends ApiResponse {
  const OkResponse({String description = 'Successful response', Type? schema, bool isArray = false, dynamic example})
    : super(200, description: description, schema: schema, isArray: isArray, example: example);
}

class CreatedResponse extends ApiResponse {
  const CreatedResponse({String description = 'Resource created', Type? schema, dynamic example})
    : super(201, description: description, schema: schema, example: example);
}

class NoContentResponse extends ApiResponse {
  const NoContentResponse({String description = 'No content'}) : super(204, description: description, contentType: '');
}

class BadRequestResponse extends ApiResponse {
  const BadRequestResponse({String description = 'Bad request', Type? schema})
    : super(400, description: description, schema: schema);
}

class UnauthorizedResponse extends ApiResponse {
  const UnauthorizedResponse({String description = 'Unauthorized', Type? schema})
    : super(401, description: description, schema: schema);
}

class NotFoundResponse extends ApiResponse {
  const NotFoundResponse({String description = 'Not found', Type? schema})
    : super(404, description: description, schema: schema);
}

class ServerErrorResponse extends ApiResponse {
  const ServerErrorResponse({String description = 'Internal server error', Type? schema})
    : super(500, description: description, schema: schema);
}

/// Excludes from documentation.
class ApiExclude {
  const ApiExclude();
}

const apiExclude = ApiExclude();
