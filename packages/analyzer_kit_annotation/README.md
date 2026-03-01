# Analyzer Kit Annotation

Annotations for use with [analyzer_kit](https://pub.dev/packages/analyzer_kit) — a Dart Analyzer plugin that provides lint rules and quick fixes for common boilerplate code generation patterns.

## Getting Started

Add the annotation package to your `dependencies`:

```yaml
dependencies:
  analyzer_kit_annotation: ^1.0.0+1
```

Then enable the plugin in your `analysis_options.yaml`:

```yaml
plugins:
  analyzer_kit: 
    version: ^1.0.0+2
    diagnostics:
      data_class_annotation: true
      copy_with_annotation: true
      override_equality_annotation: true
      override_to_string_annotation: true
      serialize_annotation: true
      deserialize_annotation: true
```

## Annotations

| Annotation | Convenience Constant | Generated Code |
|---|---|---|
| `@DataClass()` | `@dataClass` | `copyWith`, `==`, `hashCode`, `toString`, `toMap`, `fromMap` |
| `@CopyWith()` | `@copyWith` | `copyWith` method |
| `@OverrideEquality()` | `@overrideEquality` | `==` operator and `hashCode` getter |
| `@OverrideToString()` | `@overrideToString` | `toString` method |
| `@Serialize()` | `@serialize` | Serialization method (default: `toMap`) |
| `@Deserialize()` | `@deserialize` | Deserialization factory (default: `fromMap`) |

Every annotation has a convenience `const` for concise usage (e.g., `@dataClass` is equivalent to `@DataClass()`).

## Usage

### `@DataClass` — All-in-One

`@DataClass` is a composite annotation that enables all features by default. Apply it to a class and use the IDE quick fix to generate the missing methods:

```dart
import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

@dataClass
class User {
  final String name;
  final int age;

  User({required this.name, required this.age});

  // IDE quick fix generates: copyWith, ==, hashCode, toString, toMap, fromMap
}
```

You can selectively disable features by passing `false`:

```dart
@DataClass(
  copyWith: true,
  overrideEquality: true,
  overrideToString: true,
  serialize: false,    // no toMap method
  deserialize: false,  // no fromMap factory
)
class Point {
  final double x;
  final double y;

  Point({required this.x, required this.y});
}
```

### `@CopyWith`

Generates a `copyWith` method that creates a new instance with selected fields overridden:

```dart
@copyWith
class Settings {
  final bool darkMode;
  final int fontSize;

  Settings({required this.darkMode, required this.fontSize});

  // Generated:
  // Settings copyWith({bool? darkMode, int? fontSize}) =>
  //     Settings(darkMode: darkMode ?? this.darkMode, fontSize: fontSize ?? this.fontSize);
}
```

### `@OverrideEquality`

Generates `==` operator and `hashCode` overrides based on all generatable fields:

```dart
@overrideEquality
class Coordinate {
  final double lat;
  final double lng;

  Coordinate({required this.lat, required this.lng});

  // Generated: operator == and hashCode using lat, lng
}
```

#### Deep Collection Equality

For classes with collection fields (`List`, `Set`, `Map`), the generated equality uses `deepEquals` and `deepHash` from this package by default, which perform recursive element-wise comparison. You can opt out to use shallow Dart-native comparisons:

```dart
@OverrideEquality(deepCollectionEquality: false)
class Inventory {
  final List<String> items;

  Inventory({required this.items});

  // Generated: uses Object.hashAll/indexed.every instead of deepHash/deepEquals
}
```

### `@OverrideToString`

Generates a `toString` override listing all generatable fields:

```dart
@overrideToString
class Config {
  final String host;
  final int port;

  Config({required this.host, required this.port});

  // Generated:
  // @override
  // String toString() => 'Config(host: $host, port: $port)';
}
```

### `@Serialize`

Generates a serialization method that converts the instance to a `Map<String, dynamic>`:

```dart
// Default: generates toMap()
@serialize
class Event {
  final String title;
  final DateTime date;

  Event({required this.title, required this.date});

  // Generated: Map<String, dynamic> toMap() => {'title': title, 'date': date};
}

// Custom method name
@Serialize(name: .toJson())
class ApiResponse {
  final int status;

  ApiResponse({required this.status});

  // Generated: Map<String, dynamic> toJson() => {'status': status};
}

// Fully custom name
@Serialize(name: .custom('serialize'))
class Document {
  final String content;

  Document({required this.content});

  // Generated: Map<String, dynamic> serialize() => {'content': content};
}
```

### `@Deserialize`

Generates a factory constructor that creates an instance from a `Map<String, dynamic>`:

```dart
// Default: generates fromMap factory
@deserialize
class User {
  final String name;
  final int age;

  User({required this.name, required this.age});

  // Generated:
  // factory User.fromMap(Map<String, dynamic> map) {
  //   return User(name: map['name'] as String, age: map['age'] as int);
  // }
}

// Custom method name
@Deserialize(name: .fromJson())
class ApiPayload {
  final String data;

  ApiPayload({required this.data});

  // Generated: factory ApiPayload.fromJson(Map<String, dynamic> map) { ... }
}
```

## Runtime Helpers

This package also provides two runtime utility functions used by generated equality code:

| Function | Description |
|---|---|
| `deepHash(Object?)` | Computes a hash using deep recursive collection equality |
| `deepEquals(Object?, Object?)` | Compares two objects using deep recursive collection equality |

These functions are powered by `DeepCollectionEquality.unordered()` from [package:collection](https://pub.dev/packages/collection) and handle nested collections (`List<List<int>>`, `Map<String, List<int>>`, etc.) correctly.
