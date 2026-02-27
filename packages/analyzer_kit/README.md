# Dart Analyzer Kit

A Dart Analyzer plugin that provides lint rules and quick fixes for [analyzer_kit_annotation](https://pub.dev/packages/analyzer_kit_annotation) annotations. Apply an annotation to a class, see an error diagnostic, and use the IDE quick fix to generate the boilerplate — no build runners, no code generation steps.

## Features

| Annotation | Lint Rule | Quick Fix |
|---|---|---|
| `@DataClass` | `data_class_annotation` | Generates all enabled methods in one pass |
| `@CopyWith` | `copy_with_annotation` | Generates `copyWith` method |
| `@OverrideEquality` | `override_equality_annotation` | Generates `==` operator and `hashCode` getter |
| `@OverrideToString` | `override_to_string_annotation` | Generates `toString` override |
| `@Serialize` | `serialize_annotation` | Generates serialization method (`toMap`, `toJson`, or custom) |
| `@Deserialize` | `deserialize_annotation` | Generates deserialization factory (`fromMap`, `fromJson`, or custom) |

All rules report at `ERROR` severity and all fixes support `CorrectionApplicability.automatically` (Fix All).

## Installation

Add annotation package to your `pubspec.yaml`:

```yaml
dependencies:
  analyzer_kit_annotation: ^1.0.0
```

Enable the plugin in your `analysis_options.yaml`:

```yaml
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

## How It Works

1. **Annotate** a class with any supported annotation.
2. **See the lint** — the analyzer reports an error if the required methods are missing.
3. **Apply the quick fix** — use your IDE's quick fix action (or "Fix All") to generate the methods.

```dart
import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

@dataClass
class User {
  final String name;
  final int age;

  User({required this.name, required this.age});

  // ERROR: Classes annotated with @DataClass must contain the required methods...
  // Quick Fix → "Add missing DataClass methods"
  // Generates: copyWith, toString, ==, hashCode, toMap, fromMap
}
```

### Selective `@DataClass`

Disable individual features by passing `false`:

```dart
@DataClass(serialize: false, deserialize: false)
class Point {
  final double x;
  final double y;

  Point({required this.x, required this.y});

  // Only generates: copyWith, toString, ==, hashCode
}
```

### Custom Serialization Names

```dart
@Serialize(name: .toJson())
@Deserialize(name: .fromJson())
class ApiModel {
  final String id;

  ApiModel({required this.id});

  // Generates: toJson() and factory ApiModel.fromJson(...)
}
```

### Deep Collection Equality

By default, generated `==` and `hashCode` use deep recursive equality for collection fields. Opt out per-class:

```dart
@OverrideEquality(deepCollectionEquality: false)
class Inventory {
  final List<String> items;

  Inventory({required this.items});

  // Uses shallow Dart-native comparisons instead of deepEquals/deepHash
}
```

## Architecture

The plugin is built on the Dart analysis server plugin API:

- **`BaseAnnotationRule`** — Abstract base for all lint rules, handling visitor registration.
- **`AnnotationRule`** / **`AnnotationVisitor`** — Base classes for rules that detect missing methods on annotated classes.
- **6 concrete rules** — One per annotation, each defining expected method names.
- **6 concrete fixes** — One per annotation, each using code generation utilities to produce formatted Dart code.
- **Code generation** — Uses [`code_builder`](https://pub.dev/packages/code_builder) for AST construction and [`dart_style`](https://pub.dev/packages/dart_style) for formatting.

## Requirements

- Dart SDK `^3.10.4`
- Depends on `analyzer ^9.0.0`, `analysis_server_plugin ^0.3.4`, `code_builder ^4.11.0`, `dart_style ^3.1.3`
