/// Server configuration for OpenAPI spec.
class Server {
  /// Server URL (e.g., 'https://api.example.com')
  final String url;

  /// Human-readable description (e.g., 'Production')
  final String? description;

  const Server({required this.url, this.description});

  Map<String, String> toJson() => {'url': url, 'description': ?description};
}

/// Contact information for the API.
class Contact {
  /// Contact name
  final String? name;

  /// Contact email
  final String? email;

  /// Contact URL
  final String? url;

  const Contact({this.name, this.email, this.url});

  bool get isEmpty => name == null && email == null && url == null;

  Map<String, String> toJson() => {'name': ?name, 'email': ?email, 'url': ?url};
}

/// License information for the API.
class License {
  /// License name (e.g., 'MIT', 'Apache 2.0')
  final String name;

  /// License URL
  final String? url;

  const License({required this.name, this.url});

  Map<String, String> toJson() => {'name': name, 'url': ?url};
}
