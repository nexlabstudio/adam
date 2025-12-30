/**
 * Schema annotations for documenting data models.
 */

/// Marks a class as an API schema.
class ApiSchema {
  final String? name;
  final String? description;

  const ApiSchema({this.name, this.description});
}

/// Documents a property.
class ApiProperty {
  final String? description;
  final bool required;
  final bool nullable;
  final String? format;
  final dynamic example;
  final dynamic defaultValue;
  final num? minimum;
  final num? maximum;
  final int? minLength;
  final int? maxLength;
  final String? pattern;
  final List<String>? enumValues;

  const ApiProperty({
    this.description,
    this.required = true,
    this.nullable = false,
    this.format,
    this.example,
    this.defaultValue,
    this.minimum,
    this.maximum,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.enumValues,
  });
}

/// Hidden from schema.
class ApiHidden {
  const ApiHidden();
}

const apiHidden = ApiHidden();

/// Read-only property.
class ApiReadOnly {
  const ApiReadOnly();
}

const apiReadOnly = ApiReadOnly();

/// Write-only property.
class ApiWriteOnly {
  const ApiWriteOnly();
}

const apiWriteOnly = ApiWriteOnly();

// Convenience property annotations

class UuidProperty extends ApiProperty {
  const UuidProperty({String? description, bool required = true})
    : super(
        description: description,
        required: required,
        format: 'uuid',
        example: '550e8400-e29b-41d4-a716-446655440000',
      );
}

class EmailProperty extends ApiProperty {
  const EmailProperty({String? description, bool required = true})
    : super(description: description, required: required, format: 'email', example: 'user@example.com');
}

class DateTimeProperty extends ApiProperty {
  const DateTimeProperty({String? description, bool required = true})
    : super(description: description, required: required, format: 'date-time', example: '2024-01-15T09:30:00Z');
}

class DateProperty extends ApiProperty {
  const DateProperty({String? description, bool required = true})
    : super(description: description, required: required, format: 'date', example: '2024-01-15');
}

class UriProperty extends ApiProperty {
  const UriProperty({String? description, bool required = true})
    : super(description: description, required: required, format: 'uri', example: 'https://example.com');
}

class PasswordProperty extends ApiProperty {
  const PasswordProperty({String? description, bool required = true, int? minLength = 8})
    : super(description: description, required: required, format: 'password', minLength: minLength);
}
