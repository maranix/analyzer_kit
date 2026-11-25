/// Marks a field to be ignored by `analyzer_kit` code generation.
///
/// Use `@ignore` or `@Ignore()` on a field declaration (or primary constructor
/// declaring parameter) to exclude it from all generated methods (`copyWith`,
/// `==`/`hashCode`, `toString`, serialization, and deserialization).
///
/// Set individual flags to `false` to opt specific features back in, or use
/// [Ignore.only] to ignore the field only for selected features.
final class Ignore {
  /// Creates an [Ignore] annotation that ignores all features by default.
  const Ignore({
    this.copyWith = true,
    this.equality = true,
    this.stringify = true,
    this.serialize = true,
    this.deserialize = true,
  });

  /// Creates an [Ignore] annotation that ignores only the selected features.
  const Ignore.only({
    this.copyWith = false,
    this.equality = false,
    this.stringify = false,
    this.serialize = false,
    this.deserialize = false,
  });

  /// Whether to ignore this field in generated `copyWith` methods.
  final bool copyWith;

  /// Whether to ignore this field in generated `==` and `hashCode` overrides.
  final bool equality;

  /// Whether to ignore this field in generated `toString` overrides.
  final bool stringify;

  /// Whether to ignore this field in generated serialization methods.
  final bool serialize;

  /// Whether to ignore this field in generated deserialization factories.
  final bool deserialize;
}

/// Convenience constant for `@Ignore()`.
const ignore = Ignore();
