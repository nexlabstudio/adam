import 'package:dart_frog_openapi/dart_frog_openapi.dart';
import 'package:test/test.dart';

void main() {
  group('ApiSchema', () {
    test('creates with defaults', () {
      const schema = ApiSchema();
      expect(schema.name, isNull);
      expect(schema.description, isNull);
    });

    test('creates with name only', () {
      const schema = ApiSchema(name: 'UserDTO');
      expect(schema.name, 'UserDTO');
      expect(schema.description, isNull);
    });

    test('creates with description only', () {
      const schema = ApiSchema(description: 'User data transfer object');
      expect(schema.name, isNull);
      expect(schema.description, 'User data transfer object');
    });

    test('creates with name and description', () {
      const schema = ApiSchema(name: 'UserDTO', description: 'User data');
      expect(schema.name, 'UserDTO');
      expect(schema.description, 'User data');
    });
  });

  group('ApiProperty', () {
    test('creates with defaults', () {
      const prop = ApiProperty();
      expect(prop.required, true);
      expect(prop.nullable, false);
      expect(prop.description, isNull);
      expect(prop.format, isNull);
      expect(prop.example, isNull);
      expect(prop.defaultValue, isNull);
      expect(prop.minimum, isNull);
      expect(prop.maximum, isNull);
      expect(prop.minLength, isNull);
      expect(prop.maxLength, isNull);
      expect(prop.pattern, isNull);
      expect(prop.enumValues, isNull);
    });

    test('creates with description', () {
      const prop = ApiProperty(description: 'User name');
      expect(prop.description, 'User name');
    });

    test('creates with required false', () {
      const prop = ApiProperty(required: false);
      expect(prop.required, false);
    });

    test('creates with nullable true', () {
      const prop = ApiProperty(nullable: true);
      expect(prop.nullable, true);
    });

    test('creates with format', () {
      const prop = ApiProperty(format: 'email');
      expect(prop.format, 'email');
    });

    test('creates with example', () {
      const prop = ApiProperty(example: 'john@example.com');
      expect(prop.example, 'john@example.com');
    });

    test('creates with defaultValue', () {
      const prop = ApiProperty(defaultValue: 'default');
      expect(prop.defaultValue, 'default');
    });

    test('creates with numeric constraints', () {
      const prop = ApiProperty(minimum: 0, maximum: 100);
      expect(prop.minimum, 0);
      expect(prop.maximum, 100);
    });

    test('creates with length constraints', () {
      const prop = ApiProperty(minLength: 1, maxLength: 255);
      expect(prop.minLength, 1);
      expect(prop.maxLength, 255);
    });

    test('creates with pattern', () {
      const prop = ApiProperty(pattern: r'^[a-z]+$');
      expect(prop.pattern, r'^[a-z]+$');
    });

    test('creates with enumValues', () {
      const prop = ApiProperty(enumValues: ['a', 'b', 'c']);
      expect(prop.enumValues, ['a', 'b', 'c']);
    });

    test('creates with all options', () {
      const prop = ApiProperty(
        description: 'User name',
        required: false,
        nullable: true,
        format: 'email',
        example: 'john@example.com',
        defaultValue: '',
        minimum: 0,
        maximum: 100,
        minLength: 1,
        maxLength: 255,
        pattern: r'^[a-z]+$',
        enumValues: ['a', 'b'],
      );
      expect(prop.description, 'User name');
      expect(prop.required, false);
      expect(prop.nullable, true);
      expect(prop.format, 'email');
      expect(prop.example, 'john@example.com');
      expect(prop.defaultValue, '');
      expect(prop.minimum, 0);
      expect(prop.maximum, 100);
      expect(prop.minLength, 1);
      expect(prop.maxLength, 255);
      expect(prop.pattern, r'^[a-z]+$');
      expect(prop.enumValues, ['a', 'b']);
    });
  });

  group('ApiHidden', () {
    test('is const constructible', () {
      const hidden = ApiHidden();
      expect(hidden, isA<ApiHidden>());
    });

    test('const instance exists', () {
      expect(apiHidden, isA<ApiHidden>());
    });
  });

  group('ApiReadOnly', () {
    test('is const constructible', () {
      const readOnly = ApiReadOnly();
      expect(readOnly, isA<ApiReadOnly>());
    });

    test('const instance exists', () {
      expect(apiReadOnly, isA<ApiReadOnly>());
    });
  });

  group('ApiWriteOnly', () {
    test('is const constructible', () {
      const writeOnly = ApiWriteOnly();
      expect(writeOnly, isA<ApiWriteOnly>());
    });

    test('const instance exists', () {
      expect(apiWriteOnly, isA<ApiWriteOnly>());
    });
  });

  group('UuidProperty', () {
    test('has uuid format', () {
      const uuid = UuidProperty();
      expect(uuid.format, 'uuid');
    });

    test('has default example', () {
      const uuid = UuidProperty();
      expect(uuid.example, '550e8400-e29b-41d4-a716-446655440000');
    });

    test('creates with description', () {
      const uuid = UuidProperty(description: 'User ID');
      expect(uuid.description, 'User ID');
      expect(uuid.format, 'uuid');
    });

    test('creates with required false', () {
      const uuid = UuidProperty(required: false);
      expect(uuid.required, false);
    });

    test('defaults to required true', () {
      const uuid = UuidProperty();
      expect(uuid.required, true);
    });
  });

  group('EmailProperty', () {
    test('has email format', () {
      const email = EmailProperty();
      expect(email.format, 'email');
    });

    test('has default example', () {
      const email = EmailProperty();
      expect(email.example, 'user@example.com');
    });

    test('creates with description', () {
      const email = EmailProperty(description: 'User email address');
      expect(email.description, 'User email address');
      expect(email.format, 'email');
    });

    test('creates with required false', () {
      const email = EmailProperty(required: false);
      expect(email.required, false);
    });

    test('defaults to required true', () {
      const email = EmailProperty();
      expect(email.required, true);
    });
  });

  group('DateTimeProperty', () {
    test('has date-time format', () {
      const dt = DateTimeProperty();
      expect(dt.format, 'date-time');
    });

    test('has default example', () {
      const dt = DateTimeProperty();
      expect(dt.example, '2024-01-15T09:30:00Z');
    });

    test('creates with description', () {
      const dt = DateTimeProperty(description: 'Creation timestamp');
      expect(dt.description, 'Creation timestamp');
      expect(dt.format, 'date-time');
    });

    test('creates with required false', () {
      const dt = DateTimeProperty(required: false);
      expect(dt.required, false);
    });

    test('defaults to required true', () {
      const dt = DateTimeProperty();
      expect(dt.required, true);
    });
  });

  group('DateProperty', () {
    test('has date format', () {
      const date = DateProperty();
      expect(date.format, 'date');
    });

    test('has default example', () {
      const date = DateProperty();
      expect(date.example, '2024-01-15');
    });

    test('creates with description', () {
      const date = DateProperty(description: 'Birth date');
      expect(date.description, 'Birth date');
      expect(date.format, 'date');
    });

    test('creates with required false', () {
      const date = DateProperty(required: false);
      expect(date.required, false);
    });

    test('defaults to required true', () {
      const date = DateProperty();
      expect(date.required, true);
    });
  });

  group('UriProperty', () {
    test('has uri format', () {
      const uri = UriProperty();
      expect(uri.format, 'uri');
    });

    test('has default example', () {
      const uri = UriProperty();
      expect(uri.example, 'https://example.com');
    });

    test('creates with description', () {
      const uri = UriProperty(description: 'Profile URL');
      expect(uri.description, 'Profile URL');
      expect(uri.format, 'uri');
    });

    test('creates with required false', () {
      const uri = UriProperty(required: false);
      expect(uri.required, false);
    });

    test('defaults to required true', () {
      const uri = UriProperty();
      expect(uri.required, true);
    });
  });

  group('PasswordProperty', () {
    test('has password format', () {
      const password = PasswordProperty();
      expect(password.format, 'password');
    });

    test('has default minLength of 8', () {
      const password = PasswordProperty();
      expect(password.minLength, 8);
    });

    test('creates with description', () {
      const password = PasswordProperty(description: 'User password');
      expect(password.description, 'User password');
      expect(password.format, 'password');
    });

    test('creates with custom minLength', () {
      const password = PasswordProperty(minLength: 12);
      expect(password.minLength, 12);
    });

    test('creates with required false', () {
      const password = PasswordProperty(required: false);
      expect(password.required, false);
    });

    test('defaults to required true', () {
      const password = PasswordProperty();
      expect(password.required, true);
    });

    test('example is null (no password examples)', () {
      const password = PasswordProperty();
      expect(password.example, isNull);
    });
  });
}
