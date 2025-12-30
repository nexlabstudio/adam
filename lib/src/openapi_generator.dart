import 'dart:mirrors';

import 'annotations.dart';
import 'schema_annotations.dart';
import 'security_annotations.dart';
import 'types.dart';

/// Auto-discovers all route handlers in the application.
///
/// Scans all loaded libraries for Dart Frog route handlers
/// and their helper methods.
///
/// ```dart
/// final apiSpec = OpenApiGenerator(title: 'My API')
///     .addRoutes(discoverRoutes())
///     .generate();
/// ```
Map<String, _DiscoveredRoute> discoverRoutes() {
  final routes = <String, _DiscoveredRoute>{};
  final mirrorSystem = currentMirrorSystem();

  for (final entry in mirrorSystem.libraries.entries) {
    final uri = entry.key;
    final library = entry.value;

    // Skip non-route files
    if (!_isRouteFile(uri)) continue;

    // Look for onRequest function
    final onRequestSymbol = Symbol('onRequest');
    if (!library.declarations.containsKey(onRequestSymbol)) continue;

    final onRequestDecl = library.declarations[onRequestSymbol];
    if (onRequestDecl is! MethodMirror || !onRequestDecl.isTopLevel) continue;

    final apiPath = _uriToApiPath(uri);
    final route = _DiscoveredRoute(path: apiPath, library: library, onRequest: onRequestDecl);

    // Extract @Api and @PathParam from onRequest metadata
    for (final meta in onRequestDecl.metadata) {
      if (meta.reflectee is Api) {
        route.api = meta.reflectee as Api;
      } else if (meta.reflectee is PathParam) {
        final pathParam = meta.reflectee as PathParam;
        route.pathParams[pathParam.name] = pathParam;
      }
    }

    // Extract @PathParam from onRequest parameters
    for (final param in onRequestDecl.parameters) {
      final paramName = MirrorSystem.getName(param.simpleName);
      if (paramName == 'context') continue;

      for (final meta in param.metadata) {
        if (meta.reflectee is PathParam) {
          final pathParam = meta.reflectee as PathParam;
          route.pathParams[paramName] = pathParam;
        }
      }

      if (!route.pathParams.containsKey(paramName)) {
        route.pathParams[paramName] = PathParam(paramName);
      }
    }

    // Scan library for helper methods with HTTP method annotations
    _discoverHelperMethods(library, route);

    routes[apiPath] = route;
  }

  return routes;
}

void _discoverHelperMethods(LibraryMirror library, _DiscoveredRoute route) {
  for (final entry in library.declarations.entries) {
    final name = MirrorSystem.getName(entry.key);
    final decl = entry.value;

    // Skip non-methods and public methods (only scan private helpers and onRequest)
    if (decl is! MethodMirror || !decl.isTopLevel) continue;
    if (name == 'onRequest') continue; // Handle separately

    // Check if method has an HTTP annotation
    String? httpMethod;
    Operation? operationAnnotation;

    for (final meta in decl.metadata) {
      final annotation = meta.reflectee;
      switch (annotation) {
        case Get():
          httpMethod = 'GET';
          operationAnnotation = annotation;
        case Post():
          httpMethod = 'POST';
          operationAnnotation = annotation;
        case Put():
          httpMethod = 'PUT';
          operationAnnotation = annotation;
        case Delete():
          httpMethod = 'DELETE';
          operationAnnotation = annotation;
        case Patch():
          httpMethod = 'PATCH';
          operationAnnotation = annotation;
      }
    }

    // Only add if it has an HTTP method annotation
    if (httpMethod case final method?) {
      route.methods[httpMethod] = _DiscoveredMethod(
        name: name,
        method: method,
        mirror: decl,
        operation: operationAnnotation,
      );
    }
  }

  if (route.methods.isEmpty) {
    for (final meta in route.onRequest.metadata) {
      final annotation = meta.reflectee;

      String? httpMethod = switch (annotation) {
        Get() => 'GET',
        Post() => 'POST',
        Put() => 'PUT',
        Delete() => 'DELETE',
        Patch() => 'PATCH',
        _ => null,
      };

      if (httpMethod case final httpMethod? when !route.methods.containsKey(httpMethod)) {
        route.methods[httpMethod] = _DiscoveredMethod(
          name: 'onRequest',
          method: httpMethod,
          mirror: route.onRequest,
          operation: annotation as Operation,
        );
      }
    }
  }
}

/// Internal class for discovered route info
class _DiscoveredRoute {
  final String path;
  final LibraryMirror library;
  final MethodMirror onRequest;
  Api? api;
  Map<String, PathParam> pathParams = {};
  Map<String, _DiscoveredMethod> methods = {};

  _DiscoveredRoute({required this.path, required this.library, required this.onRequest});
}

/// Internal class for discovered method info
class _DiscoveredMethod {
  final String name;
  final String method;
  final MethodMirror mirror;
  final Operation? operation;

  _DiscoveredMethod({required this.name, required this.method, required this.mirror, this.operation});
}

bool _isRouteFile(Uri uri) {
  var path = Uri.decodeComponent(uri.toString());

  // Match routes in the package
  if (!path.contains('/routes/')) return false;

  // Skip middleware files
  if (path.contains('_middleware.dart')) return false;

  // Must be a Dart file
  if (!path.endsWith('.dart')) return false;

  return true;
}

String _uriToApiPath(Uri uri) {
  var path = uri.toString();

  path = Uri.decodeComponent(path);

  // Extract the routes portion
  final routesIndex = path.indexOf('/routes/');
  if (routesIndex == -1) return '/';

  path = path.substring(routesIndex + 7); // +7 for '/routes'

  // Remove .dart extension
  if (path.endsWith('.dart')) {
    path = path.substring(0, path.length - 5);
  }

  // Remove /index suffix
  if (path.endsWith('/index')) {
    path = path.substring(0, path.length - 6);
  }
  if (path == 'index' || path == '/index') {
    path = '';
  }

  // Convert [param] to {param}
  path = path.replaceAllMapped(RegExp(r'\[(\w+)\]'), (match) => '{${match.group(1)}}');

  // Ensure leading slash
  if (!path.startsWith('/')) {
    path = '/$path';
  }

  // Remove trailing slash (except for root)
  if (path.length > 1 && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }

  return path.isEmpty ? '/' : path;
}

/// Discovers routes with custom path parameter naming.
///
/// By default, `[id]` becomes `{id}`. Use this to customize:
/// ```dart
/// discoverRoutesWithParams({
///   'polls/[id]': 'pollId',
///   'polls/[id]/choices/[id]': 'choiceId',
/// })
/// ```
Map<String, _DiscoveredRoute> discoverRoutesWithParams([Map<String, String>? paramNames]) {
  final routes = discoverRoutes();

  if (paramNames == null || paramNames.isEmpty) {
    return routes;
  }

  final renamed = <String, _DiscoveredRoute>{};

  for (final entry in routes.entries) {
    var path = entry.key;
    final route = entry.value;

    // Apply custom param names
    for (final paramEntry in paramNames.entries) {
      final pattern = paramEntry.key.replaceAllMapped(RegExp(r'\[(\w+)\]'), (m) => '{${m[1]}}');

      if (path.contains(pattern) || path == pattern.replaceAll('[', '{').replaceAll(']', '}')) {
        path = path.replaceFirst(RegExp(r'\{id\}'), '{${paramEntry.value}}');
      }
    }

    renamed[path] = route;
  }

  return renamed;
}

/// Generates OpenAPI spec at runtime using reflection.
///
/// ```dart
/// final spec = OpenApiGenerator(
///   title: 'My API',
///   version: '1.0.0',
/// )
///   .addRoute('/users', usersHandler)
///   .addRoute('/users/{id}', userByIdHandler)
///   .addSchema<User>()
///   .generate();
/// ```
class OpenApiGenerator {
  final String title;
  final String version;
  final String? description;
  final List<Server> servers;
  final Contact? contact;
  final License? license;

  final Map<String, _RouteInfo> _routes = {};
  final Map<String, Map<String, dynamic>> _schemas = {};
  final Map<String, Map<String, dynamic>> _securitySchemes = {};
  final Set<String> _tags = {};
  final Map<String, String> _tagDescriptions = {};

  OpenApiGenerator({
    required this.title,
    this.version = '1.0.0',
    this.description,
    this.servers = const [Server(url: 'http://localhost:8080', description: 'Development')],
    this.contact,
    this.license,
  });

  /// Adds a route handler for documentation.
  ///
  /// The [path] should use OpenAPI format: `/users/{id}`
  /// The [handler] is the function that handles the route.
  OpenApiGenerator addRoute(String path, Function handler) {
    final info = _extractRouteInfoLegacy(handler);
    if (info case final info?) {
      _routes[path] = info;

      // Extract tag
      if (info.tag case final tag?) {
        _tags.add(tag);
        if (info.tagDescription case final tagDescription?) {
          _tagDescriptions[tag] = tagDescription;
        }
      }
    }
    return this;
  }

  /// Adds multiple routes at once.
  ///
  /// Use with [discoverRoutes] for automatic route discovery:
  /// ```dart
  /// final spec = OpenApiGenerator(title: 'My API')
  ///     .addRoutes(discoverRoutes())
  ///     .generate();
  /// ```
  OpenApiGenerator addRoutes(Map<String, _DiscoveredRoute> routes) {
    for (final entry in routes.entries) {
      final info = _extractRouteInfoFromDiscovered(entry.key, entry.value);
      if (info case final info?) {
        _routes[entry.key] = info;

        // Extract tag
        if (info.tag case final tag?) {
          _tags.add(tag);
          if (info.tagDescription case final tagDescription?) {
            _tagDescriptions[tag] = tagDescription;
          }
        }
      }
    }
    return this;
  }

  /// Extracts route info from discovered route (new method-based approach).
  _RouteInfo? _extractRouteInfoFromDiscovered(String path, _DiscoveredRoute route) {
    final info = _RouteInfo();

    // Get @Api from onRequest
    if (route.api case final api?) {
      info.tag = api.tag;
      info.tagDescription = api.description;
    }

    // Get path params from onRequest signature
    final pathParamNames = _extractPathParams(path);
    final pathParamInfos = <String, _ParamInfo>{};

    for (final paramName in pathParamNames) {
      final annotation = route.pathParams[paramName];
      pathParamInfos[paramName] = _ParamInfo(
        name: paramName,
        description: annotation?.description,
        type: annotation?.type ?? 'string',
        format: annotation?.format,
        example: annotation?.example,
      );
    }

    // Process each discovered method
    for (final methodEntry in route.methods.entries) {
      final httpMethod = methodEntry.key;
      final discoveredMethod = methodEntry.value;

      final op = _OperationInfo(
        method: httpMethod,
        summary: discoveredMethod.operation?.summary ?? '$httpMethod ${route.path}',
      );

      if (discoveredMethod.operation case final operation?) {
        op.description = operation.description;
        op.operationId = operation.operationId;
        op.tags = operation.tags;
        op.deprecated = operation.deprecated;
      }

      // Add path params
      for (final paramInfo in pathParamInfos.values) {
        op.pathParams.add(paramInfo);
      }

      // Extract other annotations from the method
      _extractOperationDetails(discoveredMethod.mirror.metadata, op);

      // Extract @Body from method parameters
      _extractBodyFromParams(discoveredMethod.mirror, op);

      info.operations.add(op);
    }

    return info.operations.isNotEmpty ? info : null;
  }

  /// Extracts @Body annotation from method parameters.
  void _extractBodyFromParams(MethodMirror method, _OperationInfo op) {
    for (final param in method.parameters) {
      final paramName = MirrorSystem.getName(param.simpleName);
      if (paramName == 'context') continue;

      for (final meta in param.metadata) {
        if (meta.reflectee is Body) {
          final body = meta.reflectee as Body;
          // Get type from parameter if schema not specified
          Type? schemaType = body.schema;
          if (schemaType == null) {
            final paramType = param.type;
            if (paramType is ClassMirror) {
              schemaType = paramType.reflectedType;
            }
          }

          op.body = _BodyInfo(
            schemaType: schemaType,
            schemaName: switch (schemaType) {
              final schemaType? => _getTypeName(schemaType),
              _ => null,
            },
            description: body.description,
            required: body.required,
            contentType: body.contentType,
            example: body.example,
          );
        }
      }
    }
  }

  /// Adds a schema type for documentation.
  OpenApiGenerator addSchema<T>() {
    final schema = _extractSchema(T);
    if (schema case final schema?) {
      _schemas[schema.name] = schema.toJson();
    }
    return this;
  }

  /// Adds a schema type by Type reference.
  OpenApiGenerator addSchemaType(Type type) {
    final schema = _extractSchema(type);
    if (schema case final schema?) {
      _schemas[schema.name] = schema.toJson();
    }
    return this;
  }

  /// Adds Bearer token security scheme.
  OpenApiGenerator addBearerAuth({String format = 'JWT'}) {
    _securitySchemes['bearerAuth'] = {'type': 'http', 'scheme': 'bearer', 'bearerFormat': format};
    return this;
  }

  /// Adds API key security scheme.
  OpenApiGenerator addApiKeyAuth({
    String name = 'apiKey',
    String headerName = 'X-API-Key',
    String location = 'header',
  }) {
    _securitySchemes[name] = {'type': 'apiKey', 'in': location, 'name': headerName};
    return this;
  }

  /// Adds Basic auth security scheme.
  OpenApiGenerator addBasicAuth() {
    _securitySchemes['basicAuth'] = {'type': 'http', 'scheme': 'basic'};
    return this;
  }

  /// Adds a tag with description.
  OpenApiGenerator addTag(String name, {String? description}) {
    _tags.add(name);
    if (description case final description?) {
      _tagDescriptions[name] = description;
    }
    return this;
  }

  /// Generates the OpenAPI specification.
  Map<String, dynamic> generate() {
    final spec = <String, dynamic>{
      'openapi': '3.0.3',
      'info': {
        'title': title,
        'version': version,
        'description': ?description,
        if (contact case final contact? when !contact.isEmpty) 'contact': contact.toJson(),
        'license': ?license?.toJson(),
      },
      'servers': servers.map((s) => s.toJson()).toList(),
    };

    // Tags
    if (_tags.isNotEmpty) {
      spec['tags'] = _tags.map((t) {
        final tag = <String, dynamic>{'name': t};
        if (_tagDescriptions.containsKey(t)) {
          tag['description'] = _tagDescriptions[t];
        }
        return tag;
      }).toList();
    }

    // Paths
    final paths = <String, dynamic>{};
    for (final entry in _routes.entries) {
      paths[entry.key] = _buildPathItem(entry.value, entry.key);
    }
    spec['paths'] = paths;

    // Components
    final components = <String, dynamic>{};
    if (_schemas.isNotEmpty) {
      components['schemas'] = _schemas;
    }
    if (_securitySchemes.isNotEmpty) {
      components['securitySchemes'] = _securitySchemes;
    }
    if (components.isNotEmpty) {
      spec['components'] = components;
    }

    return spec;
  }

  Map<String, dynamic> _buildPathItem(_RouteInfo info, String path) {
    final pathItem = <String, dynamic>{};

    // Extract path parameters from the path
    final pathParams = _extractPathParams(path);

    for (final op in info.operations) {
      final operation = <String, dynamic>{'summary': op.summary};

      if (op.description case final description?) {
        operation['description'] = description;
      }
      if (op.operationId case final operationId?) {
        operation['operationId'] = operationId;
      }

      // Tags
      final tags = op.tags ?? (info.tag != null ? [info.tag!] : null);
      if (tags case final tags? when tags.isNotEmpty) {
        operation['tags'] = tags;
      }

      if (op.deprecated) {
        operation['deprecated'] = true;
      }

      // Parameters
      final parameters = <Map<String, dynamic>>[];

      // Path params
      for (final param in pathParams) {
        final annotated = op.pathParams.firstWhere((p) => p.name == param, orElse: () => _ParamInfo(name: param));
        parameters.add(_buildParameter(annotated, 'path', required: true));
      }

      // Query params
      for (final param in op.queryParams) {
        parameters.add(_buildParameter(param, 'query'));
      }

      // Header params
      for (final param in op.headerParams) {
        parameters.add(_buildParameter(param, 'header'));
      }

      if (parameters.isNotEmpty) {
        operation['parameters'] = parameters;
      }

      // Request body
      if (op.body case final body? when ['POST', 'PUT', 'PATCH'].contains(op.method)) {
        operation['requestBody'] = _buildRequestBody(body);
      }

      // Responses
      operation['responses'] = _buildResponses(op.responses);

      // Security
      if (op.security.isNotEmpty) {
        operation['security'] = op.security.map((s) => {s.scheme: s.scopes}).toList();
      } else if (op.isPublic) {
        operation['security'] = <Map<String, List<String>>>[];
      }

      pathItem[op.method.toLowerCase()] = operation;
    }

    return pathItem;
  }

  List<String> _extractPathParams(String path) {
    final params = <String>[];
    final matches = RegExp(r'\{([^}]+)\}').allMatches(path);
    for (final match in matches) {
      params.add(match.group(1)!);
    }
    return params;
  }

  Map<String, dynamic> _buildParameter(_ParamInfo param, String location, {bool required = false}) {
    final result = <String, dynamic>{
      'name': param.name,
      'in': location,
      'required': param.required ?? (location == 'path' || required),
    };

    if (param.description case final description?) {
      result['description'] = description;
    }

    final schema = <String, dynamic>{'type': param.type};
    if (param.format case final format?) {
      schema['format'] = format;
    }
    if (param.enumValues case final enumValues?) {
      schema['enum'] = enumValues;
    }
    if (param.defaultValue case final defaultValue?) {
      schema['default'] = defaultValue;
    }
    result['schema'] = schema;

    if (param.example case final example?) {
      result['example'] = example;
    }

    return result;
  }

  Map<String, dynamic> _buildRequestBody(_BodyInfo body) {
    final result = <String, dynamic>{'required': body.required};

    if (body.description case final description?) {
      result['description'] = description;
    }

    final mediaType = <String, dynamic>{};

    if (body.schemaName != null) {
      mediaType['schema'] = {r'$ref': '#/components/schemas/${body.schemaName}'};

      // Auto-add schema if not already added
      if (body.schemaType case final schemaType? when !_schemas.containsKey(body.schemaName)) {
        final schema = _extractSchema(schemaType);
        if (schema != null) {
          _schemas[schema.name] = schema.toJson();
        }
      }
    }

    if (body.example case final example?) {
      mediaType['example'] = example;
    }

    result['content'] = {body.contentType: mediaType};

    return result;
  }

  Map<String, dynamic> _buildResponses(List<_ResponseInfo> responses) {
    if (responses.isEmpty) {
      return {
        '200': {'description': 'Successful response'},
      };
    }

    final result = <String, dynamic>{};

    for (final response in responses) {
      final responseObj = <String, dynamic>{'description': response.description};

      if (response.schemaName case final schemaName?) {
        var schema = <String, dynamic>{r'$ref': '#/components/schemas/$schemaName'};

        if (response.isArray) {
          schema = {'type': 'array', 'items': schema};
        }

        responseObj['content'] = {
          response.contentType: {'schema': schema, if (response.example case final example?) 'example': example},
        };

        // Auto-add schema
        if (response.schemaType case final schemaType? when !_schemas.containsKey(response.schemaName)) {
          final schemaInfo = _extractSchema(schemaType);
          if (schemaInfo case final schemaInfo?) {
            _schemas[schemaInfo.name] = schemaInfo.toJson();
          }
        }
      }

      result[response.statusCode.toString()] = responseObj;
    }

    return result;
  }

  /// Method for extracting route info from a single function.
  /// Used for manual addRoute() calls.
  _RouteInfo? _extractRouteInfoLegacy(Function handler) {
    final mirror = reflect(handler) as ClosureMirror;
    final methodMirror = mirror.function;

    // Check for @ApiExclude
    for (final meta in methodMirror.metadata) {
      if (meta.reflectee is ApiExclude) {
        return null;
      }
    }

    final info = _RouteInfo();

    // Extract @Api annotation
    for (final meta in methodMirror.metadata) {
      final annotation = meta.reflectee;
      if (annotation is Api) {
        info.tag = annotation.tag;
        info.tagDescription = annotation.description;
      }
    }

    // Extract operations
    for (final meta in methodMirror.metadata) {
      final annotation = meta.reflectee;

      _OperationInfo? op;

      op = switch (annotation) {
        Get() => _OperationInfo(method: 'GET', summary: annotation.summary),
        Post() => _OperationInfo(method: 'POST', summary: annotation.summary),
        Put() => _OperationInfo(method: 'PUT', summary: annotation.summary),
        Delete() => _OperationInfo(method: 'DELETE', summary: annotation.summary),
        Patch() => _OperationInfo(method: 'PATCH', summary: annotation.summary),
        Operation() => _OperationInfo(method: 'GET', summary: annotation.summary),
        _ => null,
      };

      if (op != null) {
        op.description = (annotation as Operation).description;
        op.operationId = annotation.operationId;
        op.tags = annotation.tags;
        op.deprecated = annotation.deprecated;

        // Extract other annotations for this operation
        _extractOperationDetails(methodMirror.metadata, op);

        info.operations.add(op);
      }
    }

    // If no explicit operation, check for method detection in function body
    // (this is limited with mirrors - would need source analysis)
    if (info.operations.isEmpty) {
      // Create a default GET operation
      final op = _OperationInfo(method: 'GET', summary: 'No summary');
      _extractOperationDetails(methodMirror.metadata, op);
      if (op.responses.isNotEmpty || op.queryParams.isNotEmpty) {
        info.operations.add(op);
      }
    }

    return info.operations.isNotEmpty ? info : null;
  }

  void _extractOperationDetails(List<InstanceMirror> metadata, _OperationInfo op) {
    for (final meta in metadata) {
      final annotation = meta.reflectee;

      switch (annotation) {
        case PathParam():
          op.pathParams.add(
            _ParamInfo(
              name: annotation.name,
              description: annotation.description,
              type: annotation.type,
              format: annotation.format,
              example: annotation.example,
            ),
          );
        case QueryParam():
          op.queryParams.add(
            _ParamInfo(
              name: annotation.name,
              description: annotation.description,
              required: annotation.required,
              type: annotation.type,
              format: annotation.format,
              defaultValue: annotation.defaultValue,
              example: annotation.example,
              enumValues: annotation.enumValues,
            ),
          );
        case HeaderParam():
          op.headerParams.add(
            _ParamInfo(
              name: annotation.name,
              description: annotation.description,
              required: annotation.required,
              example: annotation.example,
            ),
          );
        case Body():
          op.body = _BodyInfo(
            schemaType: annotation.schema,
            schemaName: switch (annotation.schema) {
              final schema? => _getTypeName(schema),
              _ => null,
            },
            description: annotation.description,
            required: annotation.required,
            contentType: annotation.contentType,
            example: annotation.example,
          );
        case ApiResponse():
          op.responses.add(
            _ResponseInfo(
              statusCode: annotation.statusCode,
              description: annotation.description,
              schemaType: annotation.schema,
              schemaName: switch (annotation.schema) {
                final schema? => _getTypeName(schema),
                _ => null,
              },
              isArray: annotation.isArray,
              contentType: annotation.contentType,
              example: annotation.example,
            ),
          );
        case Security():
          op.security.add(_SecurityInfo(scheme: annotation.scheme, scopes: annotation.scopes));
        case Public():
          op.isPublic = true;
      }
    }
  }

  _SchemaInfo? _extractSchema(Type type) {
    final typeMirror = reflectType(type);
    if (typeMirror is! ClassMirror) return null;

    final classMirror = typeMirror;
    final name = MirrorSystem.getName(classMirror.simpleName);

    final info = _SchemaInfo(name: name);

    // Check for @ApiSchema annotation
    for (final meta in classMirror.metadata) {
      final annotation = meta.reflectee;
      if (annotation is ApiSchema) {
        if (annotation.name case final annotationName?) info.name = annotationName;
        info.description = annotation.description;
      }
    }

    // Extract properties from instance variables
    classMirror.declarations.forEach((symbol, declaration) {
      if (declaration is VariableMirror && !declaration.isStatic && !declaration.isPrivate) {
        final propName = MirrorSystem.getName(symbol);
        final propType = declaration.type;

        // Check for @ApiHidden
        bool hidden = false;
        for (final meta in declaration.metadata) {
          if (meta.reflectee is ApiHidden) {
            hidden = true;
            break;
          }
        }
        if (hidden) return;

        final prop = _PropertyInfo(name: propName);
        prop.type = _dartTypeToJsonType(propType);
        prop.format = _dartTypeToFormat(propType);
        prop.nullable = propType.isNullable;

        // Extract @ApiProperty annotation
        for (final meta in declaration.metadata) {
          final annotation = meta.reflectee;
          switch (annotation) {
            case ApiProperty():
              prop.description = annotation.description;
              prop.required = annotation.required;
              prop.nullable = annotation.nullable;
              prop.format = annotation.format;
              prop.example = annotation.example;
              prop.defaultValue = annotation.defaultValue;
              prop.minimum = annotation.minimum;
              prop.maximum = annotation.maximum;
              prop.minLength = annotation.minLength;
              prop.maxLength = annotation.maxLength;
              prop.pattern = annotation.pattern;
              prop.enumValues = annotation.enumValues;
            case ApiReadOnly():
              prop.readOnly = true;
            case ApiWriteOnly():
              prop.writeOnly = true;
          }
        }

        info.properties.add(prop);
      }
    });

    return info;
  }

  String _getTypeName(Type type) {
    final mirror = reflectType(type);
    return MirrorSystem.getName(mirror.simpleName);
  }

  String _dartTypeToJsonType(TypeMirror typeMirror) => switch (MirrorSystem.getName(typeMirror.simpleName)) {
    'String' => 'string',
    'int' => 'integer',
    'double' || 'num' => 'number',
    'bool' => 'boolean',
    'DateTime' => 'string',
    'List' => 'array',
    'Map' || _ => 'object',
  };

  String? _dartTypeToFormat(TypeMirror typeMirror) => switch (MirrorSystem.getName(typeMirror.simpleName)) {
    'DateTime' => 'date-time',
    'Uri' => 'uri',
    'int' => 'int64',
    'double' => 'double',
    _ => null,
  };
}

// Internal data classes

class _RouteInfo {
  String? tag;
  String? tagDescription;
  List<_OperationInfo> operations = [];
}

class _OperationInfo {
  String method;
  String summary;
  String? description;
  String? operationId;
  List<String>? tags;
  bool deprecated = false;
  List<_ParamInfo> pathParams = [];
  List<_ParamInfo> queryParams = [];
  List<_ParamInfo> headerParams = [];
  _BodyInfo? body;
  List<_ResponseInfo> responses = [];
  List<_SecurityInfo> security = [];
  bool isPublic = false;

  _OperationInfo({required this.method, required this.summary});
}

class _ParamInfo {
  String name;
  String? description;
  bool? required;
  String type;
  String? format;
  dynamic defaultValue;
  dynamic example;
  List<String>? enumValues;

  _ParamInfo({
    required this.name,
    this.description,
    this.required,
    this.type = 'string',
    this.format,
    this.defaultValue,
    this.example,
    this.enumValues,
  });
}

class _BodyInfo {
  Type? schemaType;
  String? schemaName;
  String? description;
  bool required;
  String contentType;
  dynamic example;

  _BodyInfo({
    this.schemaType,
    this.schemaName,
    this.description,
    this.required = true,
    this.contentType = 'application/json',
    this.example,
  });
}

class _ResponseInfo {
  int statusCode;
  String description;
  Type? schemaType;
  String? schemaName;
  bool isArray;
  String contentType;
  dynamic example;

  _ResponseInfo({
    required this.statusCode,
    required this.description,
    this.schemaType,
    this.schemaName,
    this.isArray = false,
    this.contentType = 'application/json',
    this.example,
  });
}

class _SecurityInfo {
  String scheme;
  List<String> scopes;

  _SecurityInfo({required this.scheme, this.scopes = const []});
}

class _SchemaInfo {
  String name;
  String? description;
  List<_PropertyInfo> properties = [];

  _SchemaInfo({required this.name});

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{'type': 'object'};

    if (description case final description?) {
      result['description'] = description;
    }

    if (properties.isNotEmpty) {
      result['properties'] = {for (final prop in properties) prop.name: prop.toJson()};

      final required = properties.where((p) => p.required && !p.nullable).map((p) => p.name).toList();

      if (required.isNotEmpty) {
        result['required'] = required;
      }
    }

    return result;
  }
}

class _PropertyInfo {
  String name;
  String type = 'string';
  String? format;
  String? description;
  bool required = true;
  bool nullable = false;
  dynamic example;
  dynamic defaultValue;
  num? minimum;
  num? maximum;
  int? minLength;
  int? maxLength;
  String? pattern;
  List<String>? enumValues;
  bool readOnly = false;
  bool writeOnly = false;

  _PropertyInfo({required this.name});

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{'type': type};

    if (format case final format?) result['format'] = format;
    if (description case final description?) result['description'] = description;
    if (nullable) result['nullable'] = true;
    if (example case final example?) result['example'] = example;
    if (defaultValue case final defaultValue?) result['default'] = defaultValue;
    if (minimum case final minimum?) result['minimum'] = minimum;
    if (maximum case final maximum?) result['maximum'] = maximum;
    if (minLength case final minLength?) result['minLength'] = minLength;
    if (maxLength case final maxLength?) result['maxLength'] = maxLength;
    if (pattern case final pattern?) result['pattern'] = pattern;
    if (enumValues case final enumValues?) result['enum'] = enumValues;
    if (readOnly) result['readOnly'] = true;
    if (writeOnly) result['writeOnly'] = true;

    return result;
  }
}

extension on TypeMirror {
  bool get isNullable {
    final name = MirrorSystem.getName(simpleName);
    return name.endsWith('?');
  }
}
