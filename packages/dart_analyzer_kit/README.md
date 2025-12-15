# Dart Analyzer Kit

`dart_analyzer_kit` is a comprehensive Dart Analyzer plugin designed to enhance your development experience by providing custom lint rules and automated quick fixes.

## Features

- **Lint Rules**:
  - `unused_copy_with_annotation`: Warns when a class is annotated with `@CopyWith` but lacks the corresponding `copyWith` method.

- **Quick Fixes**:
  - **Add `copyWith` Method**: Automatically generates a `copyWith` method for classes annotated with `@CopyWith`, including support for all class fields.

## Installation

Add the package to your `pubspec.yaml` as a dev dependency:

```yaml
dev_dependencies:
  dart_analyzer_kit: ^1.0.0
  analyzer_kit_annotation: ^1.0.0
```

Enable the plugin in your `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - dart_analyzer_kit
```

## Usage

Annotate your class with `@CopyWith()` or `@copyWith`. The analyzer will flag the missing method and offer a quick fix to generate it.

```dart
@CopyWith()
class MyModel {
  final String name;
  final int age;

  MyModel({required this.name, required this.age});
  
  // Quick fix will generate copyWith here
}
```
