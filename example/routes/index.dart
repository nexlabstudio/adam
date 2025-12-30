import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_openapi/dart_frog_openapi.dart';

@Api(tag: 'Health')
@Get(summary: 'Health check')
@OkResponse(description: 'OK', example: {'status': 'ok'})
Future<Response> onRequest(RequestContext context) async =>
    Response.json(body: {'status': 'ok', 'timestamp': DateTime.now().toUtc().toIso8601String()});
