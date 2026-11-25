/// Class-level codegen annotations supported by `analyzer_kit`.
enum ClassAnnotation {
  /// Applies to generated `copyWith` methods.
  copyWith,

  /// Applies to generated `==` and `hashCode` overrides.
  overrideEquality,

  /// Applies to generated `toString` overrides.
  overrideToString,

  /// Applies to generated serialization methods.
  serialize,

  /// Applies to generated deserialization factories.
  deserialize,
}
