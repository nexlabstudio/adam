import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_openapi/dart_frog_openapi.dart';

/// A simple route with HTTP annotation directly on onRequest (no helper methods)
@Api(tag: 'Simple')
@Get(summary: 'Simple GET endpoint')
@ApiResponse(200, description: 'Simple response')
Future<Response> onRequest(RequestContext context) async => Response.json(body: {'message': 'ok'});
