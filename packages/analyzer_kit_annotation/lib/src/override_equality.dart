/// Marks a class for `==` operator and `hashCode` override generation.
///
/// Use as `@OverrideEquality()` or `@overrideEquality` on a class declaration.
final class const OverrideEquality({
  /// Whether to use deep recursive equality for collections in this class.
  final bool? deepCollectionEquality,
}) {
  /// Creates an [OverrideEquality] annotation.
  ///
  /// When [deepCollectionEquality] is `null` or `true`, generated equality and
  /// `hashCode` overrides use `deepEquals` and `deepHash`. When `false`,
  /// shallow collection equality is generated instead.
  this;
}

/// Convenience constant for `@OverrideEquality()`.
const overrideEquality = OverrideEquality();
