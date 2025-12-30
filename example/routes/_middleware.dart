import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_openapi/dart_frog_openapi.dart';
import 'package:example/api_spec.dart';

Handler middleware(Handler handler) => handler
    .use(requestLogger())
    .use(swaggerUI(spec: apiSpec, docsPath: '/docs'))
    .use(reDoc(spec: apiSpec, docsPath: '/redoc'))
    .use(scalar(spec: apiSpec, docsPath: '/scalar'));
