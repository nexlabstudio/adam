import 'package:dart_frog_openapi/dart_frog_openapi.dart';

@ApiSchema(description: 'Error response')
class ErrorResponse {
  @ApiProperty(description: 'Error code')
  final String error;

  @ApiProperty(description: 'Error message')
  final String message;

  const ErrorResponse({required this.error, required this.message});
}

@ApiSchema(description: 'Authentication tokens')
class TokenResponse {
  @ApiProperty(description: 'JWT access token')
  final String accessToken;

  @ApiProperty(description: 'Refresh token')
  final String refreshToken;

  @ApiProperty(description: 'Expiry in seconds')
  final int expiresIn;

  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });
}

@ApiSchema(description: 'Login credentials')
class LoginRequest {
  @EmailProperty()
  final String email;

  @PasswordProperty()
  final String password;

  const LoginRequest({required this.email, required this.password});
}
