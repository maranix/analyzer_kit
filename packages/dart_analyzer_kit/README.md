# Dart Analyzer Kit

A Dart Analyzer plugin that provides custom lint rules and quick fixes for [analyzer_kit_annotation](https://pub.dev/packages/analyzer_kit_annotation) annotations.

## Features

| Annotation | Lint Rule | Quick Fix |
|---|---|---|
| `@DataClass` | Warns for any active shorthand features | Generates `copyWith`, `==`, `hashCode`, `toString` conditionally |
| `@CopyWith` | Warns when `copyWith` method is missing | Generates `copyWith` method |
| `@OverrideEquality` | Warns when `==` or `hashCode` is missing | Generates `==` and `hashCode` |
| `@OverrideToString` | Warns when `toString` is missing | Generates `toString` override |

## Installation

Add both packages to your `pubspec.yaml`:

```yaml
dependencies:
  analyzer_kit_annotation: ^1.0.0

dev_dependencies:
  dart_analyzer_kit: ^1.0.0
```

Enable the plugin in your `analysis_options.yaml`:

```yaml
plugins:
  dart_analyzer_kit:
    diagnostics:
      unused_copy_with_annotation: true
      unused_override_equality_annotation: true
      unused_override_to_string_annotation: true
```

## Usage

```dart
import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

@dataClass
class User {
  final String name;
  final int age;

  User({required this.name, required this.age});

  // Quick fixes generate: copyWith, ==, hashCode, toString
}
```
