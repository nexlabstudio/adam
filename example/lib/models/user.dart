import 'package:dart_frog_openapi/dart_frog_openapi.dart';

@ApiSchema(description: 'User account')
class User {
  @UuidProperty(description: 'Unique identifier')
  final String id;

  @EmailProperty(description: 'Email address')
  final String email;

  @ApiProperty(description: 'Display name', minLength: 2, maxLength: 100)
  final String name;

  @ApiProperty(description: 'Role', enumValues: ['admin', 'user', 'guest'])
  final String role;

  @DateTimeProperty(description: 'Account creation date')
  final DateTime createdAt;

  @ApiProperty(description: 'Whether active')
  final bool isActive;

  @ApiProperty(description: 'Bio', required: false, nullable: true)
  final String? bio;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    this.isActive = true,
    this.bio,
  });
}

@ApiSchema(description: 'Create user request')
class CreateUserRequest {
  @EmailProperty()
  final String email;

  @ApiProperty(minLength: 2, maxLength: 100)
  final String name;

  @PasswordProperty(minLength: 8)
  final String password;

  const CreateUserRequest({required this.email, required this.name, required this.password});
}

@ApiSchema(description: 'Update user request')
class UpdateUserRequest {
  @ApiProperty(required: false, nullable: true)
  final String? name;

  @ApiProperty(required: false, nullable: true)
  final String? bio;

  const UpdateUserRequest({this.name, this.bio});
}
