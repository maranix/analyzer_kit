/// Marks a class for `==` operator and `hashCode` override generation.
///
/// Use as `@OverrideEquality()` or `@overrideEquality` on a class declaration.
final class OverrideEquality {
  /// Creates an [OverrideEquality] annotation.
  ///
  /// If [deepCollectionEquality] is set, it overrides the global runtime fallback
  /// [AnalyzerKit.deepCollectionEquality] for this specific class.
  const OverrideEquality({this.deepCollectionEquality});

  /// Whether to use deep recursive equality for collections in this class.
  final bool? deepCollectionEquality;
}

/// Convenience constant for `@OverrideEquality()`.
const overrideEquality = OverrideEquality();
