import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_openapi/dart_frog_openapi.dart';

Handler middleware(Handler handler) {
  final spec = OpenApiGenerator(
    title: 'Example API',
    version: '1.0.0',
    description: 'A sample API with auto-discovered routes',
  ).addBearerAuth().addRoutes(discoverRoutes()).generate();

  return handler
      .use(requestLogger())
      .use(swaggerUI(spec: spec, docsPath: '/docs'))
      .use(reDoc(spec: spec, docsPath: '/redoc'))
      .use(scalar(spec: spec, docsPath: '/scalar'));
}
