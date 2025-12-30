// Mock route file for testing route discovery
// ignore_for_file: unused_element

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_openapi/dart_frog_openapi.dart';

@Api(tag: 'Health', description: 'Health check endpoints')
Future<Response> onRequest(RequestContext context) async => _get(context);

@Get(summary: 'Health check', description: 'Returns API health status')
@OkResponse(description: 'Health status')
Future<Response> _get(RequestContext context) async => Response.json(body: {'status': 'ok'});
