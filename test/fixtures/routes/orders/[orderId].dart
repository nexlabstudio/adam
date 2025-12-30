import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_openapi/dart_frog_openapi.dart';

/// Route with path parameter but NO @PathParam annotation (default behavior)
@Api(tag: 'Orders')
@Get(summary: 'Get order by ID')
@ApiResponse(200, description: 'Order found')
Future<Response> onRequest(
  RequestContext context,
  String orderId, // No @PathParam annotation - should use default
) async => Response.json(body: {'id': orderId});
