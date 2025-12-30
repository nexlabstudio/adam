// Mock route file for testing nested path params - /posts/{postId}/comments/{commentId}
// ignore_for_file: unused_element

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_openapi/dart_frog_openapi.dart';

@Api(tag: 'Comments')
@PathParam('postId', description: 'Post ID')
@PathParam('commentId', description: 'Comment ID')
Future<Response> onRequest(RequestContext context) async => switch (context.request.method) {
  HttpMethod.delete => _delete(context),
  HttpMethod.get => _get(context),
  _ => Response.json(statusCode: 405),
};

@Get(summary: 'Get comment')
@OkResponse(description: 'Comment details')
Future<Response> _get(RequestContext context) async => Response.json(body: {});

@Delete(summary: 'Delete comment')
@BearerAuth()
@NoContentResponse()
Future<Response> _delete(RequestContext context) async => Response(statusCode: 204);
