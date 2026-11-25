# Dart Analyzer Kit

A Dart Analyzer plugin that provides warning rules and quick fixes for [analyzer_kit_annotation](https://pub.dev/packages/analyzer_kit_annotation) annotations. Apply an annotation to a class, see a diagnostic when methods are missing or out of sync with fields, and use the IDE quick fix to generate or update the boilerplate — no build runners, no code generation steps.

## Features

| Annotation | Diagnostic Rules | Quick Fixes & Assists |
|---|---|---|
| `CompositeAnnotation` | Triggers all bundled rules | `AddCompositeMethods` / `RegenerateCompositeMethods` — generates, updates, or force-regenerates all bundled methods in one pass |
| `@CopyWith` | `copy_with_annotation` / `copy_with_out_of_sync` | Generates, updates, or force-regenerates `copyWith` method |
| `@OverrideEquality` | `override_equality_annotation` / `override_equality_out_of_sync` | Generates, updates, or force-regenerates `==` operator and `hashCode` getter |
| `@OverrideToString` | `override_to_string_annotation` / `override_to_string_out_of_sync` | Generates, updates, or force-regenerates `toString` override |
| `@Serialize` | `serialize_annotation` / `serialize_out_of_sync` | Generates, updates, or force-regenerates serialization method (`toMap`, `toJson`, or custom) |
| `@Deserialize` | `deserialize_annotation` / `deserialize_out_of_sync` | Generates, updates, or force-regenerates deserialization factory (`fromMap`, `fromJson`, or custom) |

## Installation

Add the annotation package to your `pubspec.yaml`:

```yaml
dependencies:
  analyzer_kit_annotation: ^2.0.0
```

Enable the plugin in your `analysis_options.yaml` (all rules are registered as warning rules and enabled by default):

```yaml
plugins:
  analyzer_kit: ^2.0.0
```

## How It Works

1. **Annotate** a class with any supported annotation or `CompositeAnnotation` bundle.
2. **See the diagnostic** — the analyzer reports an error if required methods are missing or out of sync with the class's generatable fields.
3. **Apply the quick fix** — use your IDE's quick fix action to insert missing methods or replace out-of-sync ones in-place.

```dart
import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

const dataClass = CompositeAnnotation([
  CopyWith(),
  OverrideEquality(),
  OverrideToString(),
  Serialize(),
  Deserialize(),
]);

@dataClass
class User {
  final String name;
  final int age;

  User({required this.name, required this.age});

  // ERROR: Missing or out-of-sync methods for bundled annotations
  // Quick Fix → "Add missing composite annotation methods"
  // Generates: copyWith, toString, hashCode, ==, toMap, fromMap
}
```

### Primary Constructors

Primary constructors (both positional and named parameters, including empty `;` bodies) are supported:

```dart
@dataClass
final class Point(final int x, final int y);
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

By default, generated `==` and `hashCode` use deep recursive equality for collection fields (and automatically import `package:analyzer_kit_annotation/analyzer_kit_annotation.dart` when needed). Opt out per-class:

```dart
@OverrideEquality(deepCollectionEquality: false)
class Inventory {
  final List<String> items;

  Inventory({required this.items});

  // Uses shallow Dart-native comparisons instead of deepEquals/deepHash
}
```

### Nullable-Aware `copyWith`

Enable `@CopyWith(nullable: true)` to wrap nullable fields in `T? Function()?` parameters so callers can explicitly reset them to `null`:

```dart
@CopyWith(nullable: true)
class Profile {
  final String name;
  final String? bio;

  const Profile({required this.name, this.bio});
}

// profile.copyWith(bio: () => null)
```

### Generics, Inheritance, & Rich Serialization

- **Generic classes** (`class Box<T>`) preserve type arguments across `copyWith`, `==`, and `fromMap`.
- **Inherited fields** from non-`dart:core` superclasses and positional/named constructor parameters (including primary constructors) are matched automatically.
- **Rich serialization** (`@Serialize` / `@Deserialize`) handles `DateTime`, `Uri`, `Duration`, `BigInt`, `Enum`, `List`, `Set`, `Iterable`, `Map`, and nested `@Serialize`/`@Deserialize` classes out of the box.

### Ignoring Fields (`@Ignore`)

Exclude specific fields (including primary constructor parameters and inherited fields) using `@ignore`, `@Ignore()`, or `@Ignore({...})`:

```dart
@dataClass
class Account {
  final String id;

  @ignore
  final String? cachedLabel;

  @Ignore({.overrideToString, .serialize})
  final String? token;

  Account({required this.id, this.cachedLabel, this.token});
}
```

## Architecture

The plugin is built on the Dart analysis server plugin API:

- **`AnalyzerKitRule`** — A single-pass `MultiAnalysisRule` that skips `abstract` and unannotated classes, parses `CompositeAnnotation` bundles once per class, and reports `*_annotation` errors when methods are missing or `*_out_of_sync` warnings (including removed fields and signature/type-argument drift) when out of sync.
- **6 quick fixes & 6 force-regenerate assists** — One pair per feature annotation plus `AddCompositeMethods` / `RegenerateCompositeMethods`, inserting missing methods in a single formatted pass, replacing out-of-sync ones in-place, or force-regenerating via IDE assists at any time.
- **Code generation** — Uses [`code_builder`](https://pub.dev/packages/code_builder) for AST construction and [`dart_style`](https://pub.dev/packages/dart_style) for formatting.

## Requirements

- Dart SDK `^3.14.0`
- Depends on `analyzer ^14.7.0`, `analysis_server_plugin ^0.3.26`, `analyzer_plugin ^0.14.20`, `code_builder ^4.13.0`, `dart_style ^3.1.14`
