import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_openapi/dart_frog_openapi.dart';

/// Route with @PathParam on onRequest function parameter
@Api(tag: 'Products')
@Get(summary: 'Get product by ID')
@ApiResponse(200, description: 'Product found')
Future<Response> onRequest(
  RequestContext context,
  @PathParam('productId', description: 'Product identifier', format: 'uuid') String productId,
) async => Response.json(body: {'id': productId});
