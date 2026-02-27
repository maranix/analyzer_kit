# Analyzer Kit

A Dart workspace containing packages for annotation-driven code generation through the Dart Analyzer plugin system — no build runners required.

## Packages

| Package | Description | pub.dev |
|---|---|---|
| [analyzer_kit](packages/analyzer_kit) | Dart Analyzer plugin providing lint rules and quick fixes | [![pub](https://img.shields.io/pub/v/analyzer_kit.svg)](https://pub.dev/packages/analyzer_kit) |
| [analyzer_kit_annotation](packages/analyzer_kit_annotation) | Annotations consumed by the plugin | [![pub](https://img.shields.io/pub/v/analyzer_kit_annotation.svg)](https://pub.dev/packages/analyzer_kit_annotation) |

## Quick Start

```yaml
# pubspec.yaml
dependencies:
  analyzer_kit_annotation: ^1.0.0
```

```yaml
# analysis_options.yaml
plugins:
  analyzer_kit: ^1.0.0
    diagnostics:
      data_class_annotation: true
      copy_with_annotation: true
      override_equality_annotation: true
      override_to_string_annotation: true
      serialize_annotation: true
      deserialize_annotation: true
```

```dart
import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

@dataClass
class User {
  final String name;
  final int age;

  User({required this.name, required this.age});

  // Apply IDE quick fix → generates copyWith, ==, hashCode, toString, toMap, fromMap
}
```

## Development

This project is configured as a Dart workspace.

### Getting Started

```bash
# Resolve dependencies for all packages
dart pub get

# Run analyzer_kit_annotation tests
cd packages/analyzer_kit_annotation && dart test

# Run analyzer_kit tests
cd packages/analyzer_kit && dart test
```

## License

See [LICENSE](LICENSE) for details.
