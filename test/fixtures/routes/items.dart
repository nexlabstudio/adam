import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_openapi/dart_frog_openapi.dart';

/// Route with @Body on method parameter
@Api(tag: 'Items')
Future<Response> onRequest(RequestContext context) async => switch (context.request.method) {
  HttpMethod.get => _getItems(context),
  HttpMethod.post => _createItem(context, null),
  _ => Response(statusCode: 405),
};

@Get(summary: 'List items')
@ApiResponse(200, description: 'Items list')
Future<Response> _getItems(RequestContext context) async => Response.json(body: []);

@Post(summary: 'Create item')
@ApiResponse(201, description: 'Item created')
Future<Response> _createItem(
  RequestContext context,
  @Body(description: 'Item data to create') Map<String, dynamic>? body,
) async => Response.json(body: {'id': 1}, statusCode: 201);
