import 'package:dart_frog/dart_frog.dart';

import 'openapi_generator.dart';
import 'types.dart';

/// All-in-one middleware: discovers routes, generates spec, serves Swagger UI.
///
/// ```dart
/// // routes/_middleware.dart
/// import 'package:dart_frog/dart_frog.dart';
/// import 'package:dart_frog_openapi/dart_frog_openapi.dart';
///
/// Handler middleware(Handler handler) {
///   return handler.use(
///     autoSwagger(title: 'My API', version: '1.0.0'),
///   );
/// }
/// ```
///
Middleware autoSwagger({
  required String title,
  String version = '1.0.0',
  String? description,
  List<Server> servers = const [],
  String docsPath = '/docs',
  String specPath = '/openapi.json',
  bool bearerAuth = true,
  bool apiKeyAuth = false,
  String? apiKeyHeader,
  Map<String, String>? paramNames,
}) {
  Map<String, dynamic>? _cachedSpec;

  Map<String, dynamic> getSpec() {
    if (_cachedSpec case final spec?) return spec;

    final generator = OpenApiGenerator(
      title: title,
      version: version,
      description: description,
      servers: servers.isEmpty ? [Server(url: 'http://localhost:8080', description: 'Development')] : servers,
    );

    if (bearerAuth) generator.addBearerAuth();
    if (apiKeyAuth) generator.addApiKeyAuth(headerName: apiKeyHeader ?? 'X-API-Key');

    final routes = paramNames != null ? discoverRoutesWithParams(paramNames) : discoverRoutes();

    generator.addRoutes(routes);

    return _cachedSpec = generator.generate();
  }

  return (handler) => (context) async {
    final path = context.request.uri.path;

    if (path == specPath) {
      return Response.json(body: getSpec());
    }

    if (path == '$specPath.yaml' || path == '/openapi.yaml') {
      return Response(body: _toYaml(getSpec()), headers: {'Content-Type': 'text/yaml; charset=utf-8'});
    }

    if (path == docsPath || path == '$docsPath/') {
      return Response(
        body: _swaggerHtml(title: title, specUrl: specPath),
        headers: {'Content-Type': 'text/html; charset=utf-8'},
      );
    }

    return handler(context);
  };
}

/// Serves Swagger UI for API documentation.
///
/// ```dart
/// Handler middleware(Handler handler) {
///   return handler.use(swaggerUI(spec: apiSpec));
/// }
/// ```
Middleware swaggerUI({
  required Map<String, dynamic> spec,
  String title = 'API Documentation',
  String docsPath = '/docs',
  String specPath = '/openapi.json',
  String? specYamlPath = '/openapi.yaml',
  bool tryItOutEnabled = true,
  bool displayRequestDuration = true,
  String? docExpansion,
  bool? filter,
}) =>
    (handler) => (context) async {
      final path = context.request.uri.path;

      if (path == specPath) {
        return Response.json(body: spec);
      }

      if (specYamlPath != null && path == specYamlPath) {
        return Response(body: _toYaml(spec), headers: {'Content-Type': 'text/yaml; charset=utf-8'});
      }

      if (path == docsPath || path == '$docsPath/') {
        return Response(
          body: _swaggerHtml(
            title: title,
            specUrl: specPath,
            tryItOutEnabled: tryItOutEnabled,
            displayRequestDuration: displayRequestDuration,
            docExpansion: docExpansion,
            filter: filter,
          ),
          headers: {'Content-Type': 'text/html; charset=utf-8'},
        );
      }

      return handler(context);
    };

/// Serves ReDoc for API documentation.
Middleware reDoc({
  required Map<String, dynamic> spec,
  String title = 'API Documentation',
  String docsPath = '/docs',
  String specPath = '/openapi.json',
}) =>
    (handler) => (context) async {
      final path = context.request.uri.path;

      if (path == specPath) {
        return Response.json(body: spec);
      }

      if (path == docsPath || path == '$docsPath/') {
        return Response(
          body: _redocHtml(title: title, specUrl: specPath),
          headers: {'Content-Type': 'text/html; charset=utf-8'},
        );
      }

      return handler(context);
    };

/// Serves Scalar API documentation.
Middleware scalar({
  required Map<String, dynamic> spec,
  String title = 'API Documentation',
  String docsPath = '/docs',
  String specPath = '/openapi.json',
}) =>
    (handler) => (context) async {
      final path = context.request.uri.path;

      if (path == specPath) {
        return Response.json(body: spec);
      }

      if (path == docsPath || path == '$docsPath/') {
        return Response(
          body: _scalarHtml(title: title, specUrl: specPath),
          headers: {'Content-Type': 'text/html; charset=utf-8'},
        );
      }

      return handler(context);
    };

String _swaggerHtml({
  required String title,
  required String specUrl,
  bool tryItOutEnabled = true,
  bool displayRequestDuration = true,
  String? docExpansion,
  bool? filter,
}) =>
    '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$title</title>
  <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css">
  <link rel="icon" type="image/png" href="https://unpkg.com/swagger-ui-dist@5/favicon-32x32.png">
  <style>
    html { box-sizing: border-box; overflow-y: scroll; }
    *, *:before, *:after { box-sizing: inherit; }
    body { margin: 0; background: #fafafa; }
    .swagger-ui .topbar { display: none; }
  </style>
</head>
<body>
  <div id="swagger-ui"></div>
  <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
  <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-standalone-preset.js"></script>
  <script>
    window.onload = () => {
      window.ui = SwaggerUIBundle({
        url: "$specUrl",
        dom_id: "#swagger-ui",
        deepLinking: true,
        displayRequestDuration: $displayRequestDuration,
        tryItOutEnabled: $tryItOutEnabled,
        ${docExpansion != null ? 'docExpansion: "$docExpansion",' : ''}
        ${filter != null ? 'filter: $filter,' : ''}
        presets: [SwaggerUIBundle.presets.apis, SwaggerUIStandalonePreset],
        plugins: [SwaggerUIBundle.plugins.DownloadUrl],
        layout: "StandaloneLayout"
      });
    };
  </script>
</body>
</html>
''';

String _redocHtml({required String title, required String specUrl}) =>
    '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$title</title>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  <style>body { margin: 0; font-family: 'Inter', sans-serif; }</style>
</head>
<body>
  <redoc spec-url="$specUrl"></redoc>
  <script src="https://cdn.redoc.ly/redoc/latest/bundles/redoc.standalone.js"></script>
</body>
</html>
''';

String _scalarHtml({required String title, required String specUrl}) =>
    '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$title</title>
</head>
<body>
  <script id="api-reference" data-url="$specUrl"></script>
  <script src="https://cdn.jsdelivr.net/npm/@scalar/api-reference"></script>
</body>
</html>
''';

String _toYaml(Map<String, dynamic> data, [int indent = 0]) {
  final buffer = StringBuffer();
  final spaces = '  ' * indent;

  for (final entry in data.entries) {
    final key = entry.key;
    final value = entry.value;

    if (value == null) continue;

    if (value is Map<String, dynamic>) {
      if (value.isEmpty) {
        buffer.writeln('$spaces$key: {}');
      } else {
        buffer.writeln('$spaces$key:');
        buffer.write(_toYaml(value, indent + 1));
      }
    } else if (value is List) {
      if (value.isEmpty) {
        buffer.writeln('$spaces$key: []');
      } else {
        buffer.writeln('$spaces$key:');
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            buffer.writeln('$spaces  -');
            buffer.write(_toYaml(item, indent + 2));
          } else {
            buffer.writeln('$spaces  - ${_yamlValue(item)}');
          }
        }
      }
    } else {
      buffer.writeln('$spaces$key: ${_yamlValue(value)}');
    }
  }

  return buffer.toString();
}

String _yamlValue(dynamic value) => switch (value) {
  bool b => '$b',
  num n => '$n',
  String s when s.isEmpty => '""',
  String s when _needsQuotes(s) => '"${s.replaceAll('"', r'\"').replaceAll('\n', r'\n')}"',
  String s => s,
  null => 'null',
  _ => value.toString(),
};

bool _needsQuotes(String s) => ['\n', ':', '#', '"', "'"].any(s.contains) || s.startsWith(' ') || s.endsWith(' ');
