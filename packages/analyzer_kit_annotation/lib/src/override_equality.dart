/// Marks a class for `==` operator and `hashCode` override generation.
///
/// Use as `@OverrideEquality()` or `@overrideEquality` on a class declaration.
final class OverrideEquality {
  /// Creates an [OverrideEquality] annotation.
  ///
  /// When [deepCollectionEquality] is `null` or `true`, generated equality and
  /// `hashCode` overrides use `deepEquals` and `deepHash`. When `false`,
  /// shallow collection equality is generated instead.
  const OverrideEquality({this.deepCollectionEquality});

  /// Whether to use deep recursive equality for collections in this class.
  final bool? deepCollectionEquality;
}

/// Convenience constant for `@OverrideEquality()`.
const overrideEquality = OverrideEquality();
