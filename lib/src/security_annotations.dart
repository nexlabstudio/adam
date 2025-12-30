/**
 * Security annotations for authentication.
 */

/// Generic security requirement.
class Security {
  final String scheme;
  final List<String> scopes;

  const Security(this.scheme, {this.scopes = const []});
}

/// Bearer token authentication.
class BearerAuth extends Security {
  const BearerAuth({List<String> scopes = const []}) : super('bearerAuth', scopes: scopes);
}

/// API key authentication.
class ApiKeyAuth extends Security {
  const ApiKeyAuth({String scheme = 'apiKey', List<String> scopes = const []}) : super(scheme, scopes: scopes);
}

/// Basic authentication.
class BasicAuth extends Security {
  const BasicAuth() : super('basicAuth');
}

/// Marks endpoint as public (no auth).
class Public {
  const Public();
}

const public_ = Public();
