/// Marks a class for `==` operator and `hashCode` override generation.
///
/// Use as `@OverrideEquality()` or `@overrideEquality` on a class declaration.
final class OverrideEquality {
  /// Creates an [OverrideEquality] annotation.
  const OverrideEquality();
}

/// Convenience constant for `@OverrideEquality()`.
const overrideEquality = OverrideEquality();
