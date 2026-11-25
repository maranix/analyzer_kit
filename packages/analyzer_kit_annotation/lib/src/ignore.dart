/// Class-level codegen annotations supported by `analyzer_kit`.
enum ClassAnnotation {
  /// Excludes the field from generated `copyWith` methods.
  copyWith,

  /// Excludes the field from generated `==` and `hashCode` overrides.
  overrideEquality,

  /// Excludes the field from generated `toString` overrides.
  overrideToString,

  /// Excludes the field from generated serialization methods.
  serialize,

  /// Excludes the field from generated deserialization factories.
  deserialize,
}

/// Marks a field to be ignored by `analyzer_kit` code generation.
///
/// Use `@ignore` or `@Ignore()` on a field declaration (or primary constructor
/// declaring parameter) to exclude it from all generated methods.
///
/// Pass a set of [ClassAnnotation] values to ignore the field only for
/// specific features, e.g. `@Ignore({.serialize, .overrideToString})`.
final class const Ignore([
  /// The class-level annotations for which this field is ignored.
  final Set<ClassAnnotation> annotations = const {
    .copyWith,
    .overrideEquality,
    .overrideToString,
    .serialize,
    .deserialize,
  },
]) {
  /// Creates an [Ignore] annotation for the given [annotations].
  this;
}

/// Convenience constant for `@Ignore()`.
const ignore = Ignore();
