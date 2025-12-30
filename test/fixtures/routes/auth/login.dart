// Mock route file for testing public endpoints - /auth/login
// ignore_for_file: unused_element

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_openapi/dart_frog_openapi.dart';

@Api(tag: 'Auth', description: 'Authentication endpoints')
Future<Response> onRequest(RequestContext context) async => _post(context);

@Post(summary: 'Login', description: 'Authenticate user and get token')
@Public()
@Body(schema: String, description: 'Login credentials')
@OkResponse(schema: String, description: 'Authentication token')
@UnauthorizedResponse(description: 'Invalid credentials')
Future<Response> _post(RequestContext context) async => Response.json(body: {});
