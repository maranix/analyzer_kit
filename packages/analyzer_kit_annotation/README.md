# Analyzer Kit Annotation

Annotations for use with [dart_analyzer_kit](https://pub.dev/packages/dart_analyzer_kit).

## Annotations

| Annotation | Generated Code |
|---|---|
| `@CopyWith()` / `@copyWith` | `copyWith` method |
| `@OverrideEquality()` / `@overrideEquality` | `==` operator and `hashCode` override |
| `@OverrideToString()` / `@overrideToString` | `toString` override |

## Installation

```yaml
dependencies:
  analyzer_kit_annotation: ^1.0.0
```

## Usage

```dart
import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

@copyWith
@overrideEquality
@overrideToString
class User {
  final String name;
  final int age;

  User({required this.name, required this.age});

  // Quick fixes will generate copyWith, ==, hashCode, and toString
}
```

The annotations are picked up by `dart_analyzer_kit` which provides lint warnings and quick fixes to generate the corresponding methods.
