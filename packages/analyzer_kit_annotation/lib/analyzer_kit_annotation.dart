/// Annotations for use with [analyzer_kit](https://pub.dev/packages/analyzer_kit).
///
/// This library provides class-level annotations that trigger lint rules and
/// quick fixes in the `analyzer_kit` Dart Analyzer plugin. Annotate a class,
/// see an error diagnostic, and apply the IDE quick fix to generate the
/// corresponding boilerplate — no build runners required.
///
/// ## Annotations
///
/// | Annotation | Convenience Constant | Generated Code |
/// |---|---|---|
/// | [DataClass] | [dataClass] | `copyWith`, `==`, `hashCode`, `toString`, `toMap`, `fromMap` |
/// | [CopyWith] | [copyWith] | `copyWith` method |
/// | [OverrideEquality] | [overrideEquality] | `==` operator and `hashCode` getter |
/// | [OverrideToString] | [overrideToString] | `toString` method |
/// | [Serialize] | [serialize] | Serialization method (configurable via [SerializeMethod]) |
/// | [Deserialize] | [deserialize] | Deserialization factory (configurable via [DeserializeMethod]) |
///
/// ## Usage
///
/// ```dart
/// import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';
///
/// @dataClass
/// class User {
///   final String name;
///   final int age;
///
///   User({required this.name, required this.age});
/// }
/// ```
///
/// ## Runtime Helpers
///
/// This library also exports [deepHash] and [deepEquals] — utility functions
/// used by the generated equality code for deep recursive collection comparison.
library;

export 'src/analyzer_kit.dart';
export 'src/copy_with.dart';
export 'src/data_class.dart';
export 'src/deserialize.dart';
export 'src/override_equality.dart';
export 'src/override_to_string.dart';
export 'src/serialize.dart';
